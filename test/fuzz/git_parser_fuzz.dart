import 'dart:convert';
import 'dart:typed_data';

import 'package:git/git.dart';

void fuzzTarget(Uint8List bytes) {
  final input = utf8.decode(bytes, allowMalformed: true);

  try {
    Commit.parse(input);
  } on FormatException {
    // Expected on malformed commit object.
  }

  try {
    Commit.parseRawRevList(input);
  } on FormatException {
    // Expected on malformed rev-list output.
  }

  try {
    TreeEntry.fromLsTree(input);
  } on FormatException {
    // Expected on malformed ls-tree line.
  }

  try {
    TreeEntry.fromLsTreeOutput(input);
  } on FormatException {
    // Expected on malformed ls-tree output.
  }
}
