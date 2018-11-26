import 'dart:collection';

import 'bot.dart';
import 'util.dart';

class Commit {
  final String treeSha;
  final String author;
  final String committer;
  final String message;
  final String content;
  final List<String> parents;

  Commit._(this.treeSha, this.author, this.committer, this.message,
      this.content, List<String> parents)
      : parents = UnmodifiableListView<String>(parents) {
    requireArgumentValidSha1(treeSha, 'treeSha');
    for (final parent in parents) {
      requireArgumentValidSha1(parent, 'parents');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    var stringLineReader = StringLineReader(content);
    var tuple = _parse(stringLineReader, false);
    assert(tuple.item1 == null);
    return tuple.item2;
  }

  static Map<String, Commit> parseRawRevList(String content) {
    final slr = StringLineReader(content);

    var commits = <String, Commit>{};

    while (slr.position != null && slr.position < content.length) {
      final tuple = _parse(slr, true);
      commits[tuple.item1] = tuple.item2;
    }

    return commits;
  }

  static Tuple<String, Commit> _parse(StringLineReader slr, bool isRevParse) {
    assert(slr != null);
    assert(slr.position != null);

    var headers = <String, List<String>>{};

    var startSpot = slr.position;
    var lastLine = slr.readNextLine();

    while (lastLine.isNotEmpty) {
      var match = headerRegExp.allMatches(lastLine).single;
      assert(match.groupCount == 2);
      var header = match.group(1);
      var value = match.group(2);

      var list = headers.putIfAbsent(header, () => <String>[]);
      list.add(value);

      lastLine = slr.readNextLine();
    }

    assert(lastLine.isEmpty);

    String message;

    if (isRevParse) {
      final msgLines = <String>[];
      lastLine = slr.readNextLine();

      const revParseMessagePrefix = '    ';
      while (lastLine != null && lastLine.startsWith(revParseMessagePrefix)) {
        msgLines.add(lastLine.substring(revParseMessagePrefix.length));
        lastLine = slr.readNextLine();
      }

      message = msgLines.join('\n');
    } else {
      message = slr.readToEnd();
      assert(message.endsWith('\n'));
      var originalMessageLength = message.length;
      message = message.trim();
      // message should be trimmed by git, so the only diff after trim
      // should be 1 character - the removed new line
      assert(message.length + 1 == originalMessageLength);
    }

    var treeSha = headers['tree'].single;
    var author = headers['author'].single;
    var committer = headers['committer'].single;
    var commitSha =
        headers.containsKey('commit') ? headers['commit'].single : null;

    var parents = headers['parent'] ?? [];

    var endSpot = slr.position;

    var content = slr.source.substring(startSpot, endSpot);

    return Tuple(commitSha,
        Commit._(treeSha, author, committer, message, content, parents));
  }
}
