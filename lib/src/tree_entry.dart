import 'dart:convert';

import 'package:bot/bot.dart';
import 'util.dart';

class TreeEntry {
  static final _lsTreeLine =
      r'^([0-9]{6}) (blob|tree) (' + SHA_REGEX_PATTERN + ')\t(\\S.*\\S)\$';

  static final _lsTreeRegEx = new RegExp(_lsTreeLine);

  /// All numbers.
  ///
  /// See this this [post on stackoverflow](http://stackoverflow.com/questions/737673/how-to-read-the-mode-field-of-git-ls-trees-output)
  final String mode;

  // TODO: enum for type?
  final String type;
  final String sha;
  final String name;

  TreeEntry(this.mode, this.type, this.sha, this.name) {
    // TODO: enum or whitelist here
    requireArgumentContainsPattern(new RegExp(r'^[0-9]{6}$'), mode, 'mode');

    // TODO: enum or whitelist here
    requireArgumentContainsPattern(new RegExp(r'^[a-z]+$'), type, 'type');
    requireArgumentValidSha1(sha, 'sha');

    // TODO: how can we be more careful here? no paths? hmm...
    requireArgumentNotNullOrEmpty(name, 'name');
  }

  factory TreeEntry.fromLsTree(String value) {
    // TODO: should catch and re-throw a descriptive error
    final match = _lsTreeRegEx.allMatches(value).single;

    return new TreeEntry(match[1], match[2], match[3], match[4]);
  }

  @override
  String toString() => "$mode $type $sha\t$name";

  static List<TreeEntry> fromLsTreeOutput(String output) {
    var lines = const LineSplitter().convert(output);

    return lines
        .sublist(0, lines.length)
        .map((line) => new TreeEntry.fromLsTree(line))
        .toList();
  }
}
