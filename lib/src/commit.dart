library git.commit;

import 'package:bot/bot.dart';

import 'util.dart';

class Commit {
  final String treeSha;
  final String author;
  final String committer;
  final String message;
  final String content;
  final ReadOnlyCollection<String> parents;

  Commit._internal(this.treeSha, this.author, this.committer, this.message,
      this.content, Iterable<String> parents) :
      this.parents = new ReadOnlyCollection<String>(parents) {

    requireArgumentValidSha1(this.treeSha, 'treeSha');
    for(final parent in parents) {
      requireArgumentValidSha1(parent, 'parents');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    final slr = new StringLineReader(content);
    final tuple = _parse(slr, false);
    assert(tuple.item1 == null);
    return tuple.item2;
  }

  static Map<String, Commit> parseRawRevList(String content) {
    final slr = new StringLineReader(content);

    Map<String, Commit> commits = new Map<String, Commit>();

    while(slr.position != null && slr.position < content.length) {
      final tuple = _parse(slr, true);
      commits[tuple.item1] = tuple.item2;
    }

    return commits;
  }

  static Tuple<String, Commit> _parse(StringLineReader slr, bool isRevParse) {
    assert(slr != null);
    assert(slr.position != null);

    final headers = new Map<String, List<String>>();

    final int startSpot = slr.position;
    String lastLine = slr.readNextLine();

    while(!lastLine.isEmpty) {
      final match = headerRegExp.allMatches(lastLine).single;
      assert(match.groupCount == 2);
      final header = match.group(1);
      final value = match.group(2);

      final list = headers.putIfAbsent(header, () => new List<String>());
      list.add(value);

      lastLine = slr.readNextLine();
    }

    assert(lastLine.isEmpty);

    String message;

    if(isRevParse) {
      final msgLines = new List<String>();
      lastLine = slr.readNextLine();

      const revParseMessagePrefix = '    ';
      while(lastLine != null && lastLine.startsWith(revParseMessagePrefix)) {
        msgLines.add(lastLine.substring(revParseMessagePrefix.length));
        lastLine = slr.readNextLine();
      }

      message = msgLines.join('\n');
    } else {
      message = slr.readToEnd();
      assert(message.endsWith('\n'));
      final originalMessageLength = message.length;
      message = message.trim();
      // message should be trimmed by git, so the only diff after trim
      // should be 1 character - the removed new line
      assert(message.length + 1 == originalMessageLength);
    }

    final treeSha = headers['tree'].single;
    final author = headers['author'].single;
    final committer = headers['committer'].single;
    final commitSha = headers.containsKey('commit') ? headers['commit'].single : null;

    var parents = headers['parent'];
    if(parents == null) {
      parents = [];
    }

    final int endSpot = slr.position;

    final content = slr.source.substring(startSpot, endSpot);

    return new Tuple(commitSha, new Commit._internal(treeSha, author, committer, message, content, parents));
  }
}
