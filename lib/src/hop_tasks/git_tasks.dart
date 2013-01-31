part of hop_tasks;

Future<bool> branchForDir(TaskContext ctx, String sourceBranch, String sourceDir,
    String targetBranch, {String workingDir}) {

  if(workingDir == null) {
    workingDir = new Directory.current().path;
  }

  final gitDir = new GitDir(workingDir);

  List<String> gitArgs;
  String sourceDirTreeSha;

  return gitDir.lsTree(sourceBranch, subTreesOnly: true, path: sourceDir)
      .then((List<TreeEntry> entries) {
        assert(entries.length <= 1);
        if(entries.isEmpty) {
          throw 'Could not find a matching dir on the provided branch';
        }

        final tree = entries.single;

        sourceDirTreeSha = tree.sha;

        gitArgs = ['commit-tree', sourceDirTreeSha];

        return gitDir.getBranchReference(targetBranch);
      })
      .then((BranchReference branchRef) {

        if(branchRef == null) {
          // branch does not exist. New branch!
          return _doCommit(ctx, 'created', gitArgs, sourceBranch, sourceDir,
              targetBranch, gitDir);
        } else {
          // existing branch, need to find the tree info so we can create
          // a valid commit w/ the right parent
          return _withExistingBranch(ctx, branchRef, sourceDirTreeSha, sourceDir,
              gitArgs, sourceBranch, targetBranch, gitDir);
        }
      });
}

Future<bool> _withExistingBranch(TaskContext ctx, BranchReference targetBranchRef, String dirSha,
    String sourceDir, List<String> gitArgs, String sourceBranch, String targetBranch, GitDir gitDir) {

  return gitDir.getCommit(targetBranchRef.sha)
      .then((Commit commitObj) {
        if(commitObj.treeSha == dirSha) {
          ctx.fine('There have been no changes to "$sourceDir" since the last commit');
          return new Future.immediate(true);
        } else {
          gitArgs.addAll(['-p', targetBranchRef.sha]);
          return _doCommit(ctx, 'updated', gitArgs, sourceBranch, sourceDir,
              targetBranch, gitDir);
        }
      });
}

Future<bool> _doCommit(TaskContext ctx, String verb, List<String> gitArgs,
    String sourceBranch, String sourceDir, String targetBranch, GitDir gitDir) {

  return gitDir.getBranchReference(sourceBranch)
      .then((BranchReference branchRef) {

        final masterCommit = branchRef.sha.substring(0, 8);

        gitArgs.addAll(['-m', 'Contents of $sourceDir from commit $masterCommit']);

        return gitDir.runCommand(gitArgs);
      })
      .then((ProcessResult pr) {
        assert(pr.exitCode == 0);

        final newCommitSha = pr.stdout.trim();
        ctx.info('Create new commit: $newCommitSha');

        final branchNameRef = 'refs/heads/$targetBranch';

        return gitDir.runCommand(['update-ref', branchNameRef, newCommitSha]);
      })
      .then((ProcessResult pr) {
        assert(pr.exitCode == 0);
        ctx.info("Branch '$targetBranch' $verb");
        return true;
      });
}
