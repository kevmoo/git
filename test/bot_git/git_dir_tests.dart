part of test_bot_git;

void registerGitDirTests() {
  group('GitDir', () {
    test('populateBranch', _testPopulateBranch);
    test('writeObjects', _testWriteObjects);
  });
}

Future _doPopulate(GitDir gd, TempDir td, Map<String, dynamic> contents, String commitMsg) {
  return td.populate(new MapDirectoryPopulater(contents))
      .then((_) {
        // now add this new file
        return gd.runCommand(['add', '--all']);
      })
      .then((ProcessResult pr) {
        // now commit these silly files
        return gd.runCommand(['commit', '-m', commitMsg]);
      });
}

void _testPopulateBranch() {

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

  final future = _getTempGit()
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
          td1.dispose();
        }
      });

  expect(future, finishes);
}

Future _testPopulateBranchEmpty(GitDir gitDir, String branchName) {
  return _testPopulateBranchCore(gitDir, branchName, {}, 'empty?')
      .then((value) {
        fail('empty content should fail!');
      }, onError: (AsyncError error) {
        expect(error.error, 'No files were added');
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

          final populater = new MapDirectoryPopulater(contents);

          return td.populate(populater);
        }, commitMessage);
      })
    .then((Commit commit) {
      return new Tuple(commit, originalCommitCount);
    })
    .whenComplete(() {
      if(implTempDir != null) {
        expect(implTempDir.isDisposed, true);
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

void _testWriteObjects() {
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
      final paths = _initialContentMap.keys.map((String fileName) {
        return new Path(tempContent.path).append(fileName).toNativePath();
      }).toList();

      return gitDir.writeObjects(paths);
    }).then((Map<String, String> hashes) {

      // the returned hash should be cool
      expect(hashes.length, equals(_initialContentMap.length));


    }).whenComplete(() {
      if(tempGitDir != null) {
        tempGitDir.dispose();
      }
      if(tempContent != null) {
        tempContent.dispose();
      }
    });

  expect(future, finishes);
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
