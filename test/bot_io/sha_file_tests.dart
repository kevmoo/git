library test.bot_io.sha_file;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as pathos;
import 'package:bot_io/bot_io.dart';


void main() {
  test('file sha comparison', _sha1Fun);
}

const _fileSha = 'fd892cd21587480cfe85147e04e29a7d774bc968';
const _fileContents = 'my pretty wife Shanna';

Future _sha1Fun() {
  TempDir tempDir = null;

  File file1;

  final map = new Map<String, String>();
  map['file1'] = _fileContents;
  map['file2'] = _fileContents + 'yay!';
  map['file3'] = _fileContents;

  return TempDir.create()
      .then((TempDir val) {
        tempDir = val;

        return tempDir.populate(map);
      })
      .then((TempDir val) {
        assert(val == tempDir);

        file1 = new File(pathos.join(tempDir.path, 'file1'));

        return fileSha1Hex(file1);
      })
      .then((String sha) {
        expect(sha, _fileSha);

        return fileContentsMatch(file1, file1);
      })
      .then((bool shouldMatch) {
        expect(shouldMatch, isTrue);

        var file2 = new File(pathos.join(tempDir.path, 'file2'));

        return fileContentsMatch(file1, file2);
      })
      .then((bool shouldNotMatch) {
        expect(shouldNotMatch, isFalse);

        var file3 = new File(pathos.join(tempDir.path, 'file3'));
        return fileContentsMatch(file1, file3);
      })
      .then((bool shouldMatch) {
        expect(shouldMatch, isTrue);
      })
      .then((_) {
        return tempDir.dispose();
      })
      .then((_) {
        expect(tempDir.dir.existsSync(), isFalse, reason: 'Temp dir should be deleted');
        tempDir = null;
      });
}
