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

    test('parse show-ref output', () {

      final parsed = CommitReference.fromShowRefOutput(_showRefOutput);

      expect(parsed.length, 6);
      parsed.forEach((t) {
        expect(t.sha, hasLength(40));
        expect(t.reference.length, isNot(isEmpty));
      });
    });

    test('TreeEntry.parse', () {
      final result = TreeEntry.fromLsTreeOutput(_lsTreeOutput);
      expect(result, hasLength(13));
      expect(result.first.name, '.gitignore');
      result.forEach((v) {
        expect(v, isNotNull);
      });
    });
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

      // verify the new _gitDir has no branches
      return gitDir.getBranchNames();
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

      return gitDir.writeObjects(paths);
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

  expect(future, completes);

  // create another temp dir, populate it w/ stuff

  // do a createOrUpdate branch dance w/ the temp dir

  // verify branch exists

  // dispose of both...er something
}

Future<Tuple<TempDir, GitDir>> _getTempGit() {
  TempDir _tempGitDir;
  GitDir gitDir;

  return TempDir.create()
    .then((TempDir tempDir) {
      expect(_tempGitDir , isNull);
      _tempGitDir = tempDir;

      // is not git dir
      return GitDir.isGitDir(_tempGitDir.path);
    })
    .then((bool isGitDir) {
      expect(isGitDir, false);

      // initialize a new git dir
      return GitDir.init(_tempGitDir.dir);
    })
    .then((GitDir gd) {
      expect(gd, isNotNull);
      gitDir = gd;

      // is a git dir now
      return GitDir.isGitDir(_tempGitDir.path);
    })
    .then((bool isGitDir) {
      expect(isGitDir, true);

      // is clean
      return gitDir.isWorkingTreeClean();
    })
    .then((bool isWorkingTreeClean) {
      expect(isWorkingTreeClean, true);

      return new Tuple<TempDir, GitDir>(_tempGitDir, gitDir);
    });
}

const _showRefOutput = '''ff1c31c454c4128a98dcd610d203820eeeb91923 HEAD
b430c0d6dffb95a0c90ca9eb2c13bf02cbc724ce refs/heads/fluid_demo
35d56f63bead3019f13e7a8c48cb55f5fb88feb8 refs/remotes/origin/husl
6dc275e3a498c0364d510b16f46fe9660eb554b0 refs/remotes/origin/master
eecbbc64a5a23275ad7c3e6a8585df662f193b70 refs/tags/v0.1.0
9f8592560f357a4d371bd3e77147e9f8369237c5 refs/tags/v0.1.0^{}
''';

const _lsTreeOutput = '''100644 blob bcd1284d805951a16e765cea5b2273a464ee2d86\t.gitignore
100644 blob 406ca1bc6e6fa26433413a38e2ef30059c6ae3fa\t.project
100644 blob b784bd239d7c69237cb206664be975392825dc48\tLICENSE
100644 blob d9df26a686f48d565bea5d4c23174f02f3a1ca1c\tREADME.md
040000 tree f84ba94d1d6fcbafd487af152b32704895a1c3a2\tbin
100644 blob 5c2546968c45cb50675e9454197636d39c3338a9\tchangelog.md
040000 tree 7438c0af953841ca4618fbae2b8d6dc49786704e\texample
040000 tree b9f7a7826a1e48e1abf7b3c19905a0992a3a68d3\tlib
100644 blob 54cdff8794a28f9d331c8944519371449f01cf93\tpubspec.yaml
040000 tree fed23544bafae9040ee3e62ae386dfcbf04ca230\tresource
040000 tree 0add0c665fdb565e96f8d8ad6435b34a167c6d30\ttest
040000 tree b9d43d2978c41ae098d13aff04b4ae4abb04b928\ttool
040000 tree b6c0f048b48f3bfb3bb1f8b1a560f9d3c50d2ad0\tvendor
''';
