library test_bot_git;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/bot_git.dart';
import 'package:bot/bot_test.dart';

void main() {
  group('bot_git', () {
    test('first git test', _testGit);

    test('valid sha', () {
      final good = 'bcd1284d805951a16e765cea5b2273a464ee2d86';
      expect(Git.isValidSha(good), true);

      expect(() => Git.isValidSha(null), throwsArgumentError);

      final bad = ['', ' ', '',
                   ' bcd1284d805951a16e765cea5b2273a464ee2d86',
                   'bbcd1284d805951a16e765cea5b2273a464ee2d86',
                   'bbcd1284d8059 1a16e765cea5b2273a464ee2d86',
                   'bbcd1284d8059z1a16e765cea5b2273a464ee2d86',
                   'cd1284d805951a16e765cea5b2273a464ee2d86',
                   // newline after
                   '''bcd1284d805951a16e765cea5b2273a464ee2d86
''',

// newline before
'''

bcd1284d805951a16e765cea5b2273a464ee2d86'''];

      bad.forEach((v) {
        expect(Git.isValidSha(v), isFalse, reason: "'$v' should be bad");
      });
    });

    test('parseLsRemoteOutput', () {

      final parsed = Git.parseLsRemoteOutput(_lsRemoteOutput);

      expect(parsed.length, 6);
      parsed.forEach((t) {
        expect(t.sha, hasLength(40));
        expect(t.reference.length, isNot(isEmpty));
      });
    });
  });
}

Future<Tuple<TempDir, GitDir>> _getTempGit() {
  TempDir _tempGitDir;

  return TempDir.create()
    .then((TempDir tempDir) {
      expect(_tempGitDir , isNull);
      _tempGitDir = tempDir;

      // initialize a new git dir
      return GitDir.init(_tempGitDir.dir);
    })
    .then((GitDir gitDir) {
      expect(gitDir, isNotNull);

      return new Tuple<TempDir, GitDir>(_tempGitDir, gitDir);
    });
}

void _testGit() {
  final file1Name = 'file1.txt';
  final file2Name = 'file2.txt';

  final Map<String, dynamic> _initialContentMap = new Map<String, dynamic>();
  _initialContentMap[file1Name] = 'content1';
  _initialContentMap[file2Name] = 'content2';

  final Map<String, String> fileHashes = new Map<String, String>();

  TempDir tempContent;

  GitDir gitDir;
  TempDir tempGitDir;

  final future = _getTempGit()
    .then((Tuple items) {

      tempGitDir = items.item1;
      gitDir = items.item2;

      // remove me
      //logMessage('git dir at ${gitDir.path}');

      // verify the new _gitDir has no branches
      return gitDir.getBranches();
    })
    .then((List<String> branches) {

      // branches should be an empty list
      expect(branches, isNotNull);
      expect(branches, isEmpty);

      // now create a new temp for the file contents
      return TempDir.create();
    }).then((TempDir td) {
      expect(tempContent, isNull);
      expect(td, isNotNull);
      tempContent = td;

      //logMessage('temp dir for content: $td');
      final populater = new MapDirectoryPopulater(_initialContentMap);
      return tempContent.populate(populater);
    }).then((TempDir dir) {
      expect(dir, equals(tempContent));

      // now we'll write files to the object store
      final paths = _initialContentMap.keys.mappedBy((String fileName) {
        return new Path(tempContent.path).append(fileName).toNativePath();
      }).toList();

      return gitDir.writeObject(paths);
    }).then((Map<String, String> hashes) {

      // the returned hash should be cool
      expect(hashes.length, equals(_initialContentMap.length));

      // TODO: capture the file paths and verify they all exist
      // TODO: test adding the same file twice
      // TODO: test for failure when adding a file that doesn't exist
      // TODO: test for failure w/ a dir?

      tempGitDir.dispose();
      tempContent.dispose();

    });

  expectFutureComplete(future);

  // create another temp dir, populate it w/ stuff

  // do a createOrUpdate branch dance w/ the temp dir

  // verify branch exists

  // dispose of both...er something
}

const _lsRemoteOutput = '''ff1c31c454c4128a98dcd610d203820eeeb91923 HEAD
b430c0d6dffb95a0c90ca9eb2c13bf02cbc724ce  refs/heads/fluid_demo
35d56f63bead3019f13e7a8c48cb55f5fb88feb8  refs/remotes/origin/husl
6dc275e3a498c0364d510b16f46fe9660eb554b0  refs/remotes/origin/master
eecbbc64a5a23275ad7c3e6a8585df662f193b70  refs/tags/v0.1.0
9f8592560f357a4d371bd3e77147e9f8369237c5  refs/tags/v0.1.0^{}
''';
