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

  test('createOrUpdateBranch', () {
    var initialMasterBranchContent = const {
      'master.md': 'test file',
      'lib/foo.txt': 'lib foo text',
      'lib/bar.txt': 'lib bar text'
    };

    GitDir gitDir;

    schedule(() async {
      gitDir = await _createTempGitDir();
    });

    schedule(() async {
      await _doDescriptorGitCommit(
          gitDir, initialMasterBranchContent, 'master files');
    });

    // get the treeSha for the new lib directory
    schedule(() async {
      var branch = await gitDir.getCurrentBranch();

      Commit commit = await gitDir.getCommit(branch.sha);

      // sha for the new commit
      var newSha = await gitDir.createOrUpdateBranch(
          'test', commit.treeSha, 'copy of master');

      // validate there is one commit on 'test'
      // validate that the one commit has the right treeSha
      // validate it has the right message

      var treeItems = await gitDir.lsTree(newSha);
      expect(treeItems, hasLength(2));

      var libTreeEntry = treeItems.singleWhere((tree) => tree.name == 'lib');
      expect(libTreeEntry.type, 'tree');

      // do another update from the subtree sha
      var nextCommit = await gitDir.createOrUpdateBranch(
          'test', libTreeEntry.sha, 'just the lib content');

      var testCommitCount = await gitDir.getCommitCount('test');
      expect(testCommitCount, 2);

      treeItems = await gitDir.lsTree(nextCommit);
      expect(treeItems, hasLength(2));

      expect(treeItems.map((tree) => tree.name),
          unorderedEquals(['foo.txt', 'bar.txt']));
    });
  });

  group('init', () {
    test('allowContent:false with content fails', () {
      Directory dir;

      schedule(() async {
        var value = await _createTempDir();
        dir = new Directory(value.path);
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
        schedule(() async {
          var value = await _createTempGitDir();
          dir = new Directory(value.path);
        });
      });

      test('isWorkingTreeClean', () {
        schedule(() async {
          var gitDir = await GitDir.fromExisting(dir.path);
          var isClean = await gitDir.isWorkingTreeClean();
          expect(isClean, isTrue);
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

    schedule(() async {
      gitDir = await _createTempGitDir();
    });

    schedule(() async {
      var branches = await gitDir.getBranchNames();
      expect(branches, isEmpty, reason: 'Should start with zero commits');
    });

    Directory tempDir;
    schedule(() async {
      tempDir = await _createTempDir();
      d.defaultRoot = tempDir.path;
    });

    var initialContentMap = {'file1.txt': 'content1', 'file2.txt': 'content2'};

    schedule(() {
      return _doDescriptorPopulate(d.defaultRoot, initialContentMap);
    });

    schedule(() async {
      var paths = initialContentMap.keys.map((String fileName) {
        return p.join(d.defaultRoot, fileName);
      }).toList();

      var hashes = await gitDir.writeObjects(paths);
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

  schedule(() async {
    gitDir = await _createTempGitDir();

    var branches = await gitDir.getBranchNames();
    expect(branches, []);
  });

  schedule(() async {
    for (var commitStr in commitText) {
      final fileMap = <String, String>{};
      fileMap['$commitStr.txt'] = '$commitStr content';

      await _doDescriptorGitCommit(gitDir, fileMap, msgFromText(commitStr));
    }
  });

  schedule(() async {
    var count = await gitDir.getCommitCount();
    expect(count, commitText.length);
  });

  Map<String, Commit> commits;

  schedule(() async {
    commits = await gitDir.getCommits();
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
    GitDir gd, Map<String, String> contents, String commitMsg) async {
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
    String dirPath, Map<String, String> contents) async {
  for (var name in contents.keys) {
    var value = contents[name];

    var fullPath = p.join(dirPath, name);

    var file = new File(fullPath);
    await file.create(recursive: true);
    await file.writeAsString(value);
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

  schedule(() async {
    gd1 = await _createTempGitDir();
  });

  schedule(() async {
    await _doDescriptorGitCommit(
        gd1, initialMasterBranchContent, 'master files');
  });

  schedule(() {
    _testPopulateBranchEmpty(gd1, testBranchName);
  });

  schedule(() async {
    await _testPopulateBranchWithContent(
        gd1, testBranchName, testContent1, 'first commit!');
  });

  schedule(() async {
    await _testPopulateBranchWithContent(
        gd1, testBranchName, testContent2, 'second commit');
  });

  schedule(() async {
    await _testPopulateBranchWithDupeContent(
        gd1, testBranchName, testContent2, 'same content');
  });

  schedule(() async {
    await _testPopulateBranchWithContent(
        gd1, testBranchName, testContent1, '3rd commit, content 1');
  });

  schedule(() {
    _testPopulateBranchEmpty(gd1, testBranchName);
  });
}

void _testPopulateBranchEmpty(GitDir gitDir, String branchName) {
  expect(_testPopulateBranchCore(gitDir, branchName, {}, 'empty?'),
      throwsA(predicate((error) {
    return error.message == 'No files were added';
  })));
}

Future<Tuple<Commit, int>> _testPopulateBranchCore(
    GitDir gitDir,
    String branchName,
    Map<String, String> contents,
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
    Map<String, String> contents, String commitMessage) async {
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
    Map<String, String> contents, String commitMessage) async {
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
