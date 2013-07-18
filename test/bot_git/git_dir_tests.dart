part of test_bot_git;

void registerGitDirTests() {
  group('GitDir', () {
    test('populateBranch', _testPopulateBranch);
    test('writeObjects', _testWriteObjects);
    test('getCommits', _testGetCommits);
  });
}

Future _testGetCommits() {
  TempDir td;
  GitDir gd;

  final commitText = const ['', ' \t leading white space is okay, too', 'first', 'second', 'third', 'forth'];

  final msgFromText = (String txt) {
    if(!txt.isEmpty && txt.trim() == txt) {
      return 'Commit for $txt\n\nnice\n\nhuh?';
    } else {
      return txt;
    }
  };

  return _getTempGit()
      .then((tuple) {
        td = tuple.item1;
        gd = tuple.item2;


        return Future.forEach(commitText, (String commitStr) {
          final fileMap = {};
          fileMap['$commitStr.txt'] = '$commitStr content';

          return _doPopulate(gd, td, fileMap, msgFromText(commitStr));
        });
      })
      .then((_) {

        return gd.getCommitCount();
      })
      .then((int commitCount) {
        expect(commitCount, commitText.length);

        return gd.getCommits();
      })
      .then((Map<String, Commit> commits) {
        expect(commits, hasLength(commitText.length));

        final commitMessages = commitText.map(msgFromText).toList();

        final indexMap = new Map<int, Tuple<String, Commit>>();

        commits.forEach((commitSha, Commit commit) {
          // index into the text for the message of this commit
          int commitMessageIndex = null;
          for(var i = 0; i < commitMessages.length; i++) {
            if(commitMessages[i] == commit.message) {
              commitMessageIndex = i;
              break;
            }
          }

          expect(commitMessageIndex, isNotNull, reason: 'a matching message should be found');

          expect(indexMap.containsKey(commitMessageIndex), isFalse);
          indexMap[commitMessageIndex] = new Tuple(commitSha, commit);
        });

        indexMap.forEach((int index, Tuple<String, Commit> shaCommitTuple) {

          if(index > 0) {
            expect(shaCommitTuple.item2.parents, unorderedEquals([indexMap[index-1].item1]));
          } else {
            expect(shaCommitTuple.item2.parents, hasLength(0));
          }
        });

      })
      .whenComplete((){
        if(td != null) {
          td.dispose();
        }
      });
}

Future _doPopulate(GitDir gd, TempDir td, Map<String, dynamic> contents, String commitMsg) {
  return td.populate(contents)
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

Future _testPopulateBranch() {

  TempDir td1;
  GitDir gd1;

  TempDir implTempDir;

  final sillyMasterBanchContent = const {
    'master.md':'test file'
  };

  final testContent1 = const {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents',
    'file3.txt': 'not around very long'
  };

  final testContent2 = const {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents changed',
    'file4.txt': 'sorry, file3'
  };

  final testBranchName = 'the_test_branch';

  Commit returnedCommit;

  return _getTempGit()
      .then((tuple) {
        td1 = tuple.item1;
        gd1 = tuple.item2;

        // let's commit some stuff into this new git dir in the master branch
        // just to be safe
        return _doPopulate(gd1, td1, sillyMasterBanchContent, 'master files');
      })
      .then((_) {
        // no branches or files
        return _testPopulateBranchEmpty(gd1, testBranchName);
      })
      .then((_) {
        return _testPopulateBranchWithContent(gd1, testBranchName, testContent1, 'first commit!');
      })
      .then((_) {
        return _testPopulateBranchWithContent(gd1, testBranchName, testContent2, 'second commit');
      })
      .then((_) {
        return _testPopulateBranchWithDupeContent(gd1, testBranchName, testContent2, 'same content');
      })
      .then((_) {
        return _testPopulateBranchWithContent(gd1, testBranchName, testContent1, '3rd commit, content 1');
      })
      .then((_) {
        return _testPopulateBranchEmpty(gd1, testBranchName);
      })
      .whenComplete(() {
        if(td1 != null) {
          return td1.dispose();
        }
      });
}

Future _testPopulateBranchEmpty(GitDir gitDir, String branchName) {
  return _testPopulateBranchCore(gitDir, branchName, {}, 'empty?')
      .then((value) {
        fail('empty content should fail!');
      }, onError: (error) {
        expect(error, 'No files were added');
        // no return - null - is okay
      });
}

Future<Tuple<Commit, int>> _testPopulateBranchCore(GitDir gitDir, String branchName,
                               Map<String, dynamic> contents, String commitMessage) {
  int originalCommitCount;
  TempDir implTempDir;

  BranchReference branchRef;

  // figure out how many commits exist for the provided branch
  return gitDir.getBranchReference(branchName)
      .then((BranchReference value) {
        branchRef = value;
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
          implTempDir = td;

          return td.populate(contents);
        }, commitMessage);
      })
    .then((Commit commit) {
      return new Tuple(commit, originalCommitCount);
    })
    .whenComplete(() {
      if(implTempDir != null) {
        expect(implTempDir.isDisposed, true, reason: 'The temp dir $implTempDir should be disposed');
        expect(implTempDir.dir.existsSync(), false);
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

Future _testWriteObjects() {
  final file1Name = 'file1.txt';
  final file2Name = 'file2.txt';

  final Map<String, dynamic> _initialContentMap = new Map<String, dynamic>();
  _initialContentMap[file1Name] = 'content1';
  _initialContentMap[file2Name] = 'content2';

  final Map<String, String> fileHashes = new Map<String, String>();

  TempDir tempContent;

  GitDir gitDir;
  TempDir tempGitDir;

  return _getTempGit()
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
      return tempContent.populate(_initialContentMap);
    }).then((TempDir dir) {
      expect(dir, equals(tempContent));

      // now we'll write files to the object store
      final paths = _initialContentMap.keys.map((String fileName) {
        return new Path(tempContent.path).append(fileName).toNativePath();
      }).toList();

      return gitDir.writeObjects(paths);
    }).then((Map<String, String> hashes) {

      // the returned hash should be cool
      expect(hashes.length, equals(_initialContentMap.length));


    })
    .whenComplete(() {
      if(tempGitDir != null) {
        return tempGitDir.dispose();
      }
    })
    .whenComplete(() {
      if(tempContent != null) {
        tempContent.dispose();
      }
    });
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
