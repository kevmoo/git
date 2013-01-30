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

