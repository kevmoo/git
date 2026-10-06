import 'dart:collection';

import 'package:string_scanner/string_scanner.dart';

import 'top_level.dart';
import 'util.dart';

/// Represents a Git commit object.
class Commit {
  final String treeSha;
  final String author;
  final String committer;
  final String message;
  final String content;
  final List<String> parents;

  Commit._(
    this.treeSha,
    this.author,
    this.committer,
    this.message,
    this.content,
    List<String> parents,
  ) : parents = UnmodifiableListView<String>(parents) {
    requireArgumentValidSha1(treeSha, 'treeSha');
    for (final parent in parents) {
      requireArgumentValidSha1(parent, 'parents');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    final scanner = StringScanner(content);
    final tuple = _parse(scanner, false);
    assert(tuple.sha == null);
    return tuple.commit;
  }

  static Map<String, Commit> parseRawRevList(String content) {
    final scanner = StringScanner(content);

    final commits = <String, Commit>{};

    while (!scanner.isDone) {
      if (scanner.scan(RegExp(r'\r?\n'))) {
        continue;
      }
      final tuple = _parse(scanner, true);
      commits[tuple.sha!] = tuple.commit;
    }

    return commits;
  }

  static ({String? sha, Commit commit}) _parse(
    StringScanner scanner,
    bool isRevParse,
  ) {
    final headers = <String, List<String>>{};

    final startSpot = scanner.position;

    while (scanner.scan(headerRegExp)) {
      final match = scanner.lastMatch!;
      final header = match.group(1)!;
      final value = match.group(2)!;

      headers.putIfAbsent(header, () => <String>[]).add(value);
    }

    // consume the blank line but it might not exist if the commit has no body
    // at all, or might be empty.
    scanner.scan(RegExp(r'\r?\n'));

    String? commitSha;
    String message;

    if (isRevParse) {
      commitSha = _singleHeader(headers, 'commit', scanner, requireSha: true);
      final msgLines = <String>[];

      while (scanner.scan(RegExp(r'    ([^\r\n]*)(?:\r?\n|$)'))) {
        msgLines.add(scanner.lastMatch!.group(1)!);
        if (!scanner.lastMatch!.group(0)!.endsWith('\n')) {
          break;
        }
      }

      message = msgLines.join('\n');
    } else {
      if (headers.containsKey('commit')) {
        scanner.error('Unexpected "commit" header.');
      }
      final rest = scanner.rest;
      scanner.position = scanner.string.length;
      if (!rest.endsWith('\n')) {
        scanner.error('Commit message must end with a newline.');
      }
      message = rest.replaceFirst(RegExp(r'\r?\n$'), '');
    }

    final treeSha = _singleHeader(headers, 'tree', scanner, requireSha: true);
    final author = _singleHeader(headers, 'author', scanner);
    final committer = _singleHeader(headers, 'committer', scanner);

    final parents = headers['parent'] ?? [];
    if (!parents.every(isValidSha)) {
      scanner.error('Invalid SHA1 value in "parent" header.');
    }

    final endSpot = scanner.position;

    final content = scanner.string.substring(startSpot, endSpot);

    return (
      sha: commitSha,
      commit: Commit._(treeSha, author, committer, message, content, parents),
    );
  }

  static String _singleHeader(
    Map<String, List<String>> headers,
    String name,
    StringScanner scanner, {
    bool requireSha = false,
  }) {
    final values = headers[name];
    if (values == null || values.isEmpty) {
      scanner.error('Missing required "$name" header.');
    }
    if (values.length > 1) {
      scanner.error('Duplicate "$name" header.');
    }
    final value = values.single;
    if (requireSha && !isValidSha(value)) {
      scanner.error('Invalid SHA1 value in "$name" header: "$value".');
    }
    return value;
  }
}
