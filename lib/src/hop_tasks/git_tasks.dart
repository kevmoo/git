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
  final branchNameRef = 'refs/heads/$targetBranch';

  return gitDir.getBranchReference(targetBranch)
      .then((BranchReference branchRef) {

        if(branchRef == null) {
          // branch does not exist. New branch!
          return _getMasterCommit(ctx, 'created', gitArgs, sourceBranch,
              sourceDir, branchNameRef, targetBranch, gitDir);
        } else {
          // existing branch
          return _withExistingBranch(ctx, branchRef, sha, sourceDir, gitArgs,
              sourceBranch, branchNameRef, targetBranch, gitDir);
        }
      });
}

Future<bool> _withExistingBranch(TaskContext ctx, BranchReference targetBranchRef, String dirSha,
    String sourceDir, List<String> gitArgs, String sourceBranch,
    String branchNameRef, String targetBranch, GitDir gitDir) {

  final lastCommitSha = targetBranchRef.sha;

  return gitDir.getCommit(lastCommitSha)
      .then((Commit commitObj) =>
          _continueWithExistingBranch(ctx, lastCommitSha, commitObj.treeSha, dirSha, sourceDir,
              gitArgs, sourceBranch, branchNameRef, targetBranch, gitDir));
}

Future<bool> _continueWithExistingBranch(TaskContext ctx,
    String parent, String parentTree, String dirSha, String sourceDir,
    List<String> gitArgs, String sourceBranch, String branchNameRef,
    String targetBranch, GitDir gitDir) {
  if(parentTree == dirSha) {
    ctx.fine('There have been no changes to "$sourceDir" since the last commit');
    return new Future.immediate(true);
  } else {
    gitArgs.addAll(['-p', parent]);
    return _getMasterCommit(ctx, 'updated', gitArgs, sourceBranch, sourceDir,
        branchNameRef, targetBranch, gitDir);
  }
}

Future<bool> _getMasterCommit(TaskContext ctx, String verb, List<String> gitArgs,
    String sourceBranch, String sourceDir, String branchNameRef, String targetBranch,
    GitDir gitDir) {

  final workingDir = gitDir.path.toString();

  return gitDir.getBranchReference(sourceBranch)
      .then((BranchReference branchRef) =>
          _doCommitSimple(ctx, verb, gitArgs, sourceDir, branchRef.sha, branchNameRef, targetBranch, workingDir));
}

Future<bool> _doCommitSimple(TaskContext ctx, String verb, List<String> gitArgs,
    String sourceDir, String masterCommit, String branchNameRef,
    String targetBranch, String workingDir) {

  masterCommit = masterCommit.substring(0, 8);

  gitArgs.addAll(['-m', 'Contents of $sourceDir from commit $masterCommit']);

  return _runGit(gitArgs, workingDir)
      .then((ProcessResult pr) {
        require(pr.exitCode == 0, pr.stderr);

        final newCommitSha = pr.stdout.trim();
        ctx.info('Create new commit: $newCommitSha');

        return _runGit(['update-ref', branchNameRef, newCommitSha], workingDir)
            .then((ProcessResult updateRefPr) {
              require(updateRefPr.exitCode == 0);
              ctx.info("Branch '$targetBranch' $verb");
              return true;
              });
      });
}

Future<ProcessResult> _runGit(List<String> args, String workingDir) {
  final options = new ProcessOptions();
  if(workingDir != null) {
    options.workingDirectory = workingDir;
  }

  return Process.run('git', args, options);
}

final _whiteSpaceExp = new RegExp(r'\s+', multiLine: true);
