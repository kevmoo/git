part of test_hop_tasks;

class GitTests {

  static const _masterBranch = 'master';
  static const _testBranch = 'targetBranch';

  static void register() {

    group('git', () {

      test('create branch from dir', () {

        final sourceDirMap = const {
          'file.txt' : 'file contents',
          'docs_dir' : const {
            'doc.txt' : 'the doc'
          }
        };

        final testContent2 = const {
          'file2.txt': 'file 2 contents',
          'file3.txt': 'file 3 contents'
        };

        final testContent3 = const {
          'file4.txt': 'file 4 contents',
          'file5.txt': 'file 5 contents',
          'docs_dir' : const {
            'doc2.txt' : 'the other doc'
          },
          'foo-dir': const {
            'foo_file.txt': 'full of foo'
          }
        };

        TempDir tempDir;
        GitDir gitDir;

        final future = TempDir.create()
            .then((TempDir value) {
              tempDir = value;

              // populate the temp dir.
              final populater = new MapDirectoryPopulater(sourceDirMap);
              return tempDir.populate(populater);
            })
            .then((TempDir value) {
              assert(value == tempDir);

              // new we're populated.
              // now make this a git dir
              return GitDir.init(tempDir.dir, allowContent: true);
            })
            .then((GitDir value) {
              gitDir = value;

              // running now should still fail...no branch created
              final task = _createBranchTask(gitDir.path.toString());
              return _runTask(task);
            })
            .then((RunResult rr) {
              // yup, running here should cause an exception
              expect(rr, RunResult.EXCEPTION);

              // local branch count should be 0
              return gitDir.getBranches();
            })
            .then((List<String> branches) {
              expect(branches, isEmpty);

              // now add all files to staging
              return gitDir.runCommand(['add', '.', '--verbose']);
            })
            .then((_) {
              // now commit 'em!
              return gitDir.runCommand(['commit', '--verbose', '-am', 'first commit!']);
            })
            .then((ProcessResult pr) {
              // local branch count should be 1
              return gitDir.getBranches();
            })
            .then((List<String> branches) {
              expect(branches, hasLength(1));
              expect(branches, unorderedEquals([_masterBranch]));

              // now, create branch should work great
              // running now should still fail...no branch created
              final task = _createBranchTask(gitDir.path.toString());
              return _runTask(task);
            })
            .then((RunResult rr) {
              // yup, running here should work great
              expect(rr, RunResult.SUCCESS);

              // local branch count should be 2
              return gitDir.getBranches();
            })
            .then((List<String> branches) {
              expect(branches, hasLength(2));
              expect(branches, unorderedEquals([_masterBranch, _testBranch]));

              // each branch should have 1 commit now
              return Future.wait([
                                  gitDir.getCommitCount(_masterBranch),
                                  gitDir.getCommitCount(_testBranch)
                                  ]);

            })
            .then((List<int> counts) {
              expect(counts, hasLength(2));
              expect(counts[0], 1);
              expect(counts[1], 1);

              // populate the temp dir.
              final populater = new MapDirectoryPopulater(testContent2, checkEmpty: false);
              return tempDir.populate(populater);
            })
            .then((_) {
              // now add all files to staging
              return gitDir.runCommand(['add', '.', '--verbose']);
            })
            .then((_) {
              // now commit 'em!
              return gitDir.runCommand(['commit', '--verbose', '-am', '2nd commit!']);
            })
            .then((_) {

              // now, create branch should work great
              // running now should still fail...no branch created
              final task = _createBranchTask(gitDir.path.toString());
              return _runTask(task);
            })
            .then((RunResult rr) {
              // yup, running here should work great
              expect(rr, RunResult.SUCCESS);


              // each branch should have 2 and 1 commits now
              return Future.wait([
                                  gitDir.getCommitCount(_masterBranch),
                                  gitDir.getCommitCount(_testBranch)
                                  ]);

            })
            .then((List<int> counts) {
              expect(counts, hasLength(2));
              expect(counts[0], 2);
              expect(counts[1], 1, reason: 'should only have 1 commit here still');
            })
            .then((_) {
              // populate the temp dir.
              final populater = new MapDirectoryPopulater(testContent3, checkEmpty: false);
              return tempDir.populate(populater);
            })
            .then((_) {
              // now add all files to staging
              return gitDir.runCommand(['add', '.', '--verbose']);
            })
            .then((_) {
              // now commit 'em!
              return gitDir.runCommand(['commit', '--verbose', '-am', '3rd commit!']);
            })
            .then((_) {

              // now, create branch should work great
              // running now should still fail...no branch created
              final task = _createBranchTask(gitDir.path.toString());
              return _runTask(task);
            })
            .then((RunResult rr) {
              // yup, running here should work great
              expect(rr, RunResult.SUCCESS);

              // each branch should have 3 and 1 commits now
              return Future.wait([
                                  gitDir.getCommitCount(_masterBranch),
                                  gitDir.getCommitCount(_testBranch)
                                  ]);

            })
            .then((List<int> counts) {
              expect(counts, hasLength(2));
              expect(counts[0], 3);
              expect(counts[1], 2, reason: 'content in docs changed. We have 2 commits now');
            });

        expectFutureComplete(future);

      });

    });

  }

  static Task _createBranchTask(String workingDir) {
    return new Task.async((ctx) =>
        branchForDir(ctx, _masterBranch, 'docs_dir', _testBranch,
            workingDir: workingDir));
  }
}

Future _debugPrintDir(String dir) {
  return _debugPrintShellCommand('tree', [], dir)
      .then((_) => _debugPrintShellCommand('pwd', [], dir));
}

Future _debugPrintShellCommand(String command, List<String> args, String workingDir) {
  return Process.run(command, args, new ProcessOptions()..workingDirectory = workingDir)
      .then((pr) => print(pr.stdout));
}

