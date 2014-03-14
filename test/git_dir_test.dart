library git.git_dir_test;

import 'dart:async';
import 'dart:io';

import 'package:bot/bot.dart';
import 'package:bot_io/bot_io.dart';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:git/git.dart';

void main() {
  test('populateBranch', _testPopulateBranch);
  test('getCommits', _testGetCommits);
  test('writeObjects', () {

    GitDir gitDir;

    schedule(() {
      return _getGitTemp().then((value) {
        gitDir = value;
      });
    });

    currentSchedule.onComplete.schedule(() {
      var dir = new Directory(gitDir.path);
      return dir.delete(recursive: true);
    });

    schedule(() {
      expect(gitDir.getBranchNames(), completion([]),
          reason: 'Should start with zero commits');
    });

    Directory tempDir;
    schedule(() {
      return Directory.systemTemp
          .createTemp('hop_docgen-test-')
          .then((dir) {
        tempDir = dir;
        d.defaultRoot = tempDir.path;
      });
    });

    currentSchedule.onComplete.schedule(() {
      d.defaultRoot = null;
      return tempDir.delete(recursive: true);
    });

    var initialContentMap = {
      'file1.txt': 'content1',
      'file2.txt': 'content2'
    };

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
  var commitText = const ['', ' \t leading white space is okay, too', 'first',
      'second', 'third', 'forth'];

  var msgFromText = (String txt) {
    if (!txt.isEmpty && txt.trim() == txt) {
      return 'Commit for $txt\n\nnice\n\nhuh?';
    } else {
      return txt;
    }
  };

  GitDir gitDir;

  schedule(() {
    return _getGitTemp().then((value) {
      gitDir = value;

      return gitDir.getBranchNames();
    }).then((branches) {
      expect(branches, []);
    });
  });

  currentSchedule.onComplete.schedule(() {
    var dir = new Directory(gitDir.path);
    return dir.delete(recursive: true);
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
      for(var i = 0; i < commitMessages.length; i++) {
        if(commitMessages[i] == commit.message) {
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
      if(index > 0) {
        expect(shaCommitTuple.item2.parents,
            unorderedEquals([indexMap[index-1].item1]));
      } else {
        expect(shaCommitTuple.item2.parents, hasLength(0));
      }
    });

  });
}

Future _doDescriptorGitCommit(GitDir gd, Map<String, dynamic> contents, String commitMsg) {
  return _doDescriptorPopulate(gd.path, contents)
      .then((_) {
        // now add this new file
        return gd.runCommand(['add', '--all']);
      })
      .then((ProcessResult pr) {
        // now commit these silly files
        final args = ['commit', '--cleanup=verbatim', '--no-edit', '--allow-empty-message'];
        if(!commitMsg.isEmpty) {
          args.addAll(['-m', commitMsg]);
        }

        return gd.runCommand(args);
      });
}

Future _doDescriptorPopulate(String dirPath, Map<String, dynamic> contents) {
  return Future.forEach(contents.keys, (String name) {
    var value = contents[name];

    if (value is String) {
      return d.file(name, value).create(dirPath);
    } else {
      throw new UnsupportedError('We cannot party with $value');
    }
  });
}

void _testPopulateBranch() {
  var initialMasterBranchContent = const {
    'master.md': 'test file'
  };

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
    return _getGitTemp().then((value) {
      gd1 = value;
    });
  });

  currentSchedule.onComplete.schedule(() {
    var dir = new Directory(gd1.path);
    return dir.delete(recursive: true);
  });

  schedule(() {
    return _doDescriptorGitCommit(gd1, initialMasterBranchContent, 'master files');
  });

  schedule(() {
    _testPopulateBranchEmpty(gd1, testBranchName);
  });

  schedule(() {
    return _testPopulateBranchWithContent(gd1, testBranchName, testContent1, 'first commit!');
  });

  schedule(() {
    return _testPopulateBranchWithContent(gd1, testBranchName, testContent2, 'second commit');
  });

  schedule(() {
    return _testPopulateBranchWithDupeContent(gd1, testBranchName, testContent2, 'same content');
  });

  schedule(() {
    return _testPopulateBranchWithContent(gd1, testBranchName, testContent1, '3rd commit, content 1');
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

Future<Tuple<Commit, int>> _testPopulateBranchCore(GitDir gitDir,
    String branchName, Map<String, dynamic> contents, String commitMessage) {
  int originalCommitCount;

  Directory tempDir;

  // figure out how many commits exist for the provided branch
  return gitDir.getBranchReference(branchName)
      .then((BranchReference branchRef) {
        if(branchRef == null) {
          return 0;
        } else {
          return gitDir.getCommitCount(branchRef.reference);
        }
      })
      .then((int value) {
        originalCommitCount = value;

        return gitDir.populateBranch(branchName, (TempDir td) {
          // strictly speaking, users of this API should not hold on to the TempDir
          // but this is for testing
          tempDir = td.dir;

          return _doDescriptorPopulate(tempDir.path, contents);
        }, commitMessage);
      })
    .then((Commit commit) {
      return new Tuple(commit, originalCommitCount);
    })
    .whenComplete(() {
      if(tempDir != null) {
        expect(tempDir.existsSync(), false);
      }
    });
}

Future _testPopulateBranchWithContent(GitDir gitDir, String branchName,
    Map<String, dynamic> contents, String commitMessage) {

  int originalCommitCount;

  BranchReference branchRef;
  Commit returnedCommit;

  // figure out how many commits exist for the provided branch
  return _testPopulateBranchCore(gitDir, branchName, contents, commitMessage)
    .then((Tuple<Commit, int> pair) {
      returnedCommit = pair.item1;
      originalCommitCount = pair.item2;

      if(originalCommitCount == 0) {
        expect(returnedCommit.parents, isEmpty, reason: 'This should be the first commit');
      } else {
        expect(returnedCommit.parents, hasLength(1));
      }

      expect(returnedCommit, isNotNull, reason: 'Commit should not be null');
      expect(returnedCommit.message, commitMessage);

      // new check to see if things are updated it gd1
      return gitDir.getBranchReference(branchName);
    })
    .then((BranchReference br) {
      expect(br, isNotNull);
      branchRef = br;

      return gitDir.getCommit(br.reference);
    })
    .then((Commit commit) {

      expect(commit.content, returnedCommit.content,
          reason: 'content of queried commit should what was returned');

      return gitDir.lsTree(commit.treeSha);
    })
    .then((List<TreeEntry> entries) {
      expect(entries.map((te) => te.name), unorderedEquals(contents.keys));

      return gitDir.getCommitCount(branchRef.reference);
    })
    .then((int newCommitCount) {
      expect(newCommitCount, originalCommitCount+1);
    });
}

Future _testPopulateBranchWithDupeContent(GitDir gitDir, String branchName,
    Map<String, dynamic> contents, String commitMessage) {

  int originalCommitCount;

  // figure out how many commits exist for the provided branch
  return _testPopulateBranchCore(gitDir, branchName, contents, commitMessage)
    .then((Tuple<Commit, int> pair) {
      var returnedCommit = pair.item1;
      originalCommitCount = pair.item2;

      expect(returnedCommit, isNull);
      expect(originalCommitCount > 0, true, reason: 'must have had some original content');

      // new check to see if things are updated it gd1
      return gitDir.getBranchReference(branchName);
    })
    .then((BranchReference br) {
      expect(br, isNotNull);

      return gitDir.getCommitCount(br.reference);
    })
    .then((int newCommitCount) {
      expect(newCommitCount, originalCommitCount, reason: 'no change in commit count');
    });
}

Future<GitDir> _getGitTemp() {
  return Directory.systemTemp.createTemp('git_test-')
      .then((dir) {
    return GitDir.init(dir);
  });
}
