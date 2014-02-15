library git.tag;

import 'package:bot/bot.dart';

import 'util.dart';

class Tag {
  final String objectSha;
  final String type;
  final String tag;
  final String tagger;

  Tag._internal(this.objectSha, this.type, this.tag, this.tagger) {
    requireArgumentValidSha1(objectSha, 'objectSha');
    requireArgumentNotNullOrEmpty(type, 'type');
    requireArgumentNotNullOrEmpty(tag, 'tag');
    requireArgumentNotNullOrEmpty(tagger, 'tagger');
  }

  static Tag parseCatFile(String content) {
    final headers = new Map<String, List<String>>();

    final slr = new StringLineReader(content);

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

    final objectSha = headers['object'].single;
    final type = headers['type'].single;
    final tag = headers['tag'].single;
    final tagger = headers['tagger'].single;

    return new Tag._internal(objectSha, type, tag, tagger);
  }
}
