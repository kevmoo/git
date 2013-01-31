part of hop_tasks;

Future<bool> branchForDir(TaskContext ctx, String sourceBranch, String sourceDir,
    String targetBranch, {String workingDir}) {

  if(workingDir == null) {
    workingDir = new Directory.current().path;
  }

  final gitDir = new GitDir(workingDir);

  return gitDir.lsTree(sourceBranch, subTreesOnly: true, path: sourceDir)
      .then((List<TreeEntry> entries) {
        assert(entries.length <= 1);
        if(entries.isEmpty) {
          throw 'Could not find a matching dir on the provided branch';
        }
        return _fromSourceDirTree(ctx, entries.single, targetBranch, sourceDir, sourceBranch, gitDir);
      });
}

Future<bool> _fromSourceDirTree(TaskContext ctx, TreeEntry tree,
    String targetBranch, String sourceDir, String sourceBranch, GitDir gitDir) {
  final sha = tree.sha;

  final gitArgs = new List<String>.from(['commit-tree', sha]);

  return gitDir.getBranchReference(targetBranch)
      .then((BranchReference branchRef) {

        if(branchRef == null) {
          // branch does not exist. New branch!
          return _goCommit(ctx, 'created', gitArgs, sourceBranch,
              sourceDir, targetBranch, gitDir);
        } else {
          // existing branch
          return _withExistingBranch(ctx, branchRef, sha, sourceDir, gitArgs,
              sourceBranch, targetBranch, gitDir);
        }
      });
}

Future<bool> _withExistingBranch(TaskContext ctx, BranchReference targetBranchRef, String dirSha,
    String sourceDir, List<String> gitArgs, String sourceBranch, String targetBranch, GitDir gitDir) {

  final lastCommitSha = targetBranchRef.sha;

  return gitDir.getCommit(lastCommitSha)
      .then((Commit commitObj) =>
          _continueWithExistingBranch(ctx, lastCommitSha, commitObj.treeSha, dirSha, sourceDir,
              gitArgs, sourceBranch, targetBranch, gitDir));
}

Future<bool> _continueWithExistingBranch(TaskContext ctx,
    String parent, String parentTree, String dirSha, String sourceDir,
    List<String> gitArgs, String sourceBranch, String targetBranch, GitDir gitDir) {
  if(parentTree == dirSha) {
    ctx.fine('There have been no changes to "$sourceDir" since the last commit');
    return new Future.immediate(true);
  } else {
    gitArgs.addAll(['-p', parent]);
    return _goCommit(ctx, 'updated', gitArgs, sourceBranch, sourceDir,
        targetBranch, gitDir);
  }
}

Future<bool> _goCommit(TaskContext ctx, String verb, List<String> gitArgs,
    String sourceBranch, String sourceDir, String targetBranch, GitDir gitDir) {

  final branchNameRef = 'refs/heads/$targetBranch';

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

        return gitDir.runCommand(['update-ref', branchNameRef, newCommitSha]);
      })
      .then((ProcessResult pr) {
        assert(pr.exitCode == 0);
        ctx.info("Branch '$targetBranch' $verb");
        return true;
      });
}
