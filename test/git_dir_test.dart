library git.git_dir_test;

import 'dart:async';
import 'dart:io';

import 'package:bot/bot.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:git/git.dart';

void main() {
  test('populateBranch', _testPopulateBranch);

  test('getCommits', _testGetCommits);

  group('init', () {
    test('allowContent:false with content fails', () {
      Directory dir;

      schedule(() {
        return _createTempDir().then((value) {
          dir = new Directory(value.path);
        });
      });

      schedule(() {
        var file = new File(p.join(dir.path, 'testfile.txt'));
        file.writeAsStringSync('test content');
      });

      schedule(() {
        expect(GitDir.init(dir, allowContent: false), throwsArgumentError);
      });
    });

    group('existing git dir', () {
      Directory dir;

      setUp(() {
        schedule(() {
          return _createTempGitDir().then((value) {
            dir = new Directory(value.path);
          });
        });
      });

      test('isGitDir is true', () {
        schedule(() async {
          var isGitDir = await GitDir.isGitDir(dir.path);
          expect(isGitDir, isTrue);
        });
      });

      test('with allowContent:false fails', () {
        schedule(() {
          expect(GitDir.init(dir, allowContent: false), throwsArgumentError);
        });
      });

      test('with allowContent:true fails', () {
        schedule(() {
          expect(GitDir.init(dir, allowContent: true), throwsArgumentError);
        });
      });
    });
  });

  test('writeObjects', () {
    GitDir gitDir;

    schedule(() {
      return _createTempGitDir().then((value) {
        gitDir = value;
      });
    });

    schedule(() {
      expect(gitDir.getBranchNames(), completion([]),
          reason: 'Should start with zero commits');
    });

    Directory tempDir;
    schedule(() {
      return _createTempDir().then((dir) {
        tempDir = dir;
        d.defaultRoot = tempDir.path;
      });
    });

    var initialContentMap = {'file1.txt': 'content1', 'file2.txt': 'content2'};

    schedule(() {
      return _doDescriptorPopulate(d.defaultRoot, initialContentMap);
    });

    schedule(() {
      var paths = initialContentMap.keys.map((String fileName) {
        return p.join(d.defaultRoot, fileName);
      }).toList();

      return gitDir.writeObjects(paths).then((hashes) {
        expect(hashes.length, equals(initialContentMap.length));
        expect(hashes.keys, unorderedEquals(paths));

        expect(paths[0], endsWith('file1.txt'));
        expect(hashes,
            containsPair(paths[0], 'dd954e7a4e1a62ff90c5a0709dce5928716535c1'));

        expect(paths[1], endsWith('file2.txt'));
        expect(hashes,
            containsPair(paths[1], 'db00fd65b218578127ea51f3dffac701f12f486a'));
      });
    });
  });
}

void _testGetCommits() {
  var commitText = const [
    '',
    ' \t leading white space is okay, too',
    'first',
    'second',
    'third',
    'forth'
  ];

  var msgFromText = (String txt) {
    if (!txt.isEmpty && txt.trim() == txt) {
      return 'Commit for $txt\n\nnice\n\nhuh?';
    } else {
      return txt;
    }
  };

  GitDir gitDir;

  schedule(() {
    return _createTempGitDir().then((value) {
      gitDir = value;

      return gitDir.getBranchNames();
    }).then((branches) {
      expect(branches, []);
    });
  });

  schedule(() {
    return Future.forEach(commitText, (String commitStr) {
      final fileMap = {};
      fileMap['$commitStr.txt'] = '$commitStr content';

      return _doDescriptorGitCommit(gitDir, fileMap, msgFromText(commitStr));
    });
  });

  schedule(() {
    expect(gitDir.getCommitCount(), completion(commitText.length));
  });

  Map<String, Commit> commits;

  schedule(() {
    return gitDir.getCommits().then((value) {
      commits = value;
    });
  });

  schedule(() {
    expect(commits, hasLength(commitText.length));

    var commitMessages = commitText.map(msgFromText).toList();

    var indexMap = <int, Tuple<String, Commit>>{};

    commits.forEach((commitSha, Commit commit) {
      // index into the text for the message of this commit
      int commitMessageIndex = null;
      for (var i = 0; i < commitMessages.length; i++) {
        if (commitMessages[i] == commit.message) {
          commitMessageIndex = i;
          break;
        }
      }

      expect(commitMessageIndex, isNotNull,
          reason: 'a matching message should be found');

      expect(indexMap.containsKey(commitMessageIndex), isFalse);
      indexMap[commitMessageIndex] = new Tuple(commitSha, commit);
    });

    indexMap.forEach((int index, Tuple<String, Commit> shaCommitTuple) {
      if (index > 0) {
        expect(shaCommitTuple.item2.parents,
            unorderedEquals([indexMap[index - 1].item1]));
      } else {
        expect(shaCommitTuple.item2.parents, hasLength(0));
      }
    });
  });
}

Future _doDescriptorGitCommit(
    GitDir gd, Map<String, dynamic> contents, String commitMsg) async {
  await _doDescriptorPopulate(gd.path, contents);

  // now add this new file
  await gd.runCommand(['add', '--all']);

  // now commit these silly files
  final args = [
    'commit',
    '--cleanup=verbatim',
    '--no-edit',
    '--allow-empty-message'
  ];
  if (!commitMsg.isEmpty) {
    args.addAll(['-m', commitMsg]);
  }

  return gd.runCommand(args);
}

Future _doDescriptorPopulate(
    String dirPath, Map<String, dynamic> contents) async {
  for (var name in contents.keys) {
    var value = contents[name];

    if (value is String) {
      await d.file(name, value).create(dirPath);
    } else {
      throw new UnsupportedError('We cannot party with $value');
    }
  }
}

void _testPopulateBranch() {
  var initialMasterBranchContent = const {'master.md': 'test file'};

  var testContent1 = const {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents',
    'file3.txt': 'not around very long'
  };

  var testContent2 = const {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents changed',
    'file4.txt': 'sorry, file3'
  };

  var testBranchName = 'the_test_branch';

  GitDir gd1;

  schedule(() {
    return _createTempGitDir().then((value) {
      gd1 = value;
    });
  });

  schedule(() {
    return _doDescriptorGitCommit(
        gd1, initialMasterBranchContent, 'master files');
  });

  schedule(() {
    _testPopulateBranchEmpty(gd1, testBranchName);
  });

  schedule(() {
    return _testPopulateBranchWithContent(
        gd1, testBranchName, testContent1, 'first commit!');
  });

  schedule(() {
    return _testPopulateBranchWithContent(
        gd1, testBranchName, testContent2, 'second commit');
  });

  schedule(() {
    return _testPopulateBranchWithDupeContent(
        gd1, testBranchName, testContent2, 'same content');
  });

  schedule(() {
    return _testPopulateBranchWithContent(
        gd1, testBranchName, testContent1, '3rd commit, content 1');
  });

  schedule(() {
    _testPopulateBranchEmpty(gd1, testBranchName);
  });
}

void _testPopulateBranchEmpty(GitDir gitDir, String branchName) {
  expect(_testPopulateBranchCore(gitDir, branchName, {}, 'empty?'), throwsA(
      predicate((error) {
    return error.message == 'No files were added';
  })));
}

Future<Tuple<Commit, int>> _testPopulateBranchCore(GitDir gitDir,
    String branchName, Map<String, dynamic> contents,
    String commitMessage) async {

  // figure out how many commits exist for the provided branch
  var branchRef = await gitDir.getBranchReference(branchName);

  int originalCommitCount;
  if (branchRef == null) {
    originalCommitCount = 0;
  } else {
    originalCommitCount = await gitDir.getCommitCount(branchRef.reference);
  }

  Directory tempDir;
  try {
    var commit = await gitDir.updateBranch(branchName, (Directory td) {
      // strictly speaking, users of this API should not hold on to the TempDir
      // but this is for testing
      tempDir = td;

      return _doDescriptorPopulate(tempDir.path, contents);
    }, commitMessage);

    return new Tuple(commit, originalCommitCount);
  } finally {
    if (tempDir != null) {
      expect(tempDir.existsSync(), false);
    }
  }
}

Future _testPopulateBranchWithContent(GitDir gitDir, String branchName,
    Map<String, dynamic> contents, String commitMessage) async {

  // figure out how many commits exist for the provided branch
  var pair = await _testPopulateBranchCore(
      gitDir, branchName, contents, commitMessage);

  var returnedCommit = pair.item1;
  var originalCommitCount = pair.item2;

  if (originalCommitCount == 0) {
    expect(returnedCommit.parents, isEmpty,
        reason: 'This should be the first commit');
  } else {
    expect(returnedCommit.parents, hasLength(1));
  }

  expect(returnedCommit, isNotNull, reason: 'Commit should not be null');
  expect(returnedCommit.message, commitMessage);

  // new check to see if things are updated it gd1
  var branchRef = await gitDir.getBranchReference(branchName);
  expect(branchRef, isNotNull);

  var commit = await gitDir.getCommit(branchRef.reference);

  expect(commit.content, returnedCommit.content,
      reason: 'content of queried commit should what was returned');

  var entries = await gitDir.lsTree(commit.treeSha);

  expect(entries.map((te) => te.name), unorderedEquals(contents.keys));

  var newCommitCount = await gitDir.getCommitCount(branchRef.reference);
  expect(newCommitCount, originalCommitCount + 1);
}

Future _testPopulateBranchWithDupeContent(GitDir gitDir, String branchName,
    Map<String, dynamic> contents, String commitMessage) async {
  // figure out how many commits exist for the provided branch
  var pair = await _testPopulateBranchCore(
      gitDir, branchName, contents, commitMessage);

  var returnedCommit = pair.item1;
  var originalCommitCount = pair.item2;

  expect(returnedCommit, isNull);
  expect(originalCommitCount > 0, true,
      reason: 'must have had some original content');

  // new check to see if things are updated it gd1
  var br = await gitDir.getBranchReference(branchName);

  expect(br, isNotNull);

  var newCommitCount = await gitDir.getCommitCount(br.reference);

  expect(newCommitCount, originalCommitCount,
      reason: 'no change in commit count');
}

Future<Directory> _createTempDir([bool scheduleDelete = true]) async {
  var ticks = new DateTime.now().toUtc().millisecondsSinceEpoch;

  var dir = await Directory.systemTemp.createTemp('git.test.$ticks.');

  currentSchedule.onComplete.schedule(() {
    if (scheduleDelete) {
      return dir.delete(recursive: true);
    } else {
      print('Not deleting $dir');
    }
  });

  return dir;
}

Future<GitDir> _createTempGitDir([bool scheduleDelete = true]) async {
  var dir = await _createTempDir(scheduleDelete);
  return GitDir.init(dir);
}
