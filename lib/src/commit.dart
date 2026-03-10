import 'dart:collection';

import 'package:string_scanner/string_scanner.dart';

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

    var message = '';

    if (isRevParse) {
      final msgLines = <String>[];

      while (scanner.scan(RegExp(r'    ([^\r\n]*)(?:\r?\n|$)'))) {
        msgLines.add(scanner.lastMatch!.group(1)!);
        if (!scanner.lastMatch!.group(0)!.endsWith('\n')) {
          break;
        }
      }

      if (msgLines.isNotEmpty) {
        message = msgLines.join('\n');
      }
    } else {
      message = scanner.rest;
      scanner.position = scanner.string.length;
      assert(message.endsWith('\n'));
      final originalMessageLength = message.length;
      message = message.trim();
      // message should be trimmed by git, so the only diff after trim
      // should be 1 character - the removed new line
      assert(message.length + 1 == originalMessageLength);
    }

    final treeSha = headers['tree']!.single;
    final author = headers['author']!.single;
    final committer = headers['committer']!.single;
    final commitSha = headers.containsKey('commit')
        ? headers['commit']!.single
        : null;

    final parents = headers['parent'] ?? [];

    final endSpot = scanner.position;

    final content = scanner.string.substring(startSpot, endSpot);

    return (
      sha: commitSha,
      commit: Commit._(treeSha, author, committer, message, content, parents),
    );
  }
}
