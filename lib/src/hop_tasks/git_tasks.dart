part of hop_tasks;

// TODO: create a nice getTask version of this method call.

Future<bool> branchForDir(TaskContext ctx, String sourceBranch, String sourceDir,
    String targetBranch, {String workingDir}) {

  if(workingDir == null) {
    workingDir = new Directory.current().path;
  }

  GitDir gitDir;

  String sourceDirTreeSha;

  return GitDir.fromExisting(workingDir)
      .then((GitDir value) {
        gitDir = value;

        return gitDir.lsTree(sourceBranch, subTreesOnly: true, path: sourceDir);
      })
      .then((List<TreeEntry> entries) {
        assert(entries.length <= 1);
        if(entries.isEmpty) {
          throw 'Could not find a matching dir on the provided branch';
        }

        final tree = entries.single;

        sourceDirTreeSha = tree.sha;

        return gitDir.getBranchReference(targetBranch);
      })
      .then((BranchReference branchRef) {

        if(branchRef == null) {
          // branch does not exist. New branch!
          return _doCommit(ctx, 'created', sourceDirTreeSha, null, sourceBranch, sourceDir,
              targetBranch, gitDir);
        } else {
          // existing branch, need to find the tree info so we can create
          // a valid commit w/ the right parent
          return _withExistingBranch(ctx, branchRef, sourceDirTreeSha, sourceDir,
              sourceDirTreeSha, sourceBranch, targetBranch, gitDir);
        }
      });
}

Future<bool> _withExistingBranch(TaskContext ctx, BranchReference targetBranchRef, String dirSha,
    String sourceDir, String treeSha, String sourceBranch, String targetBranch, GitDir gitDir) {

  return gitDir.getCommit(targetBranchRef.sha)
      .then((Commit commitObj) {
        if(commitObj.treeSha == dirSha) {
          ctx.fine('There have been no changes to "$sourceDir" since the last commit');
          return new Future.immediate(true);
        } else {
          return _doCommit(ctx, 'updated', treeSha, targetBranchRef.sha, sourceBranch,
              sourceDir, targetBranch, gitDir);
        }
      });
}

Future<bool> _doCommit(TaskContext ctx, String verb, String treeSha, String parentCommitSha,
    String sourceBranch, String sourceDir, String targetBranch, GitDir gitDir) {

  return gitDir.getBranchReference(sourceBranch)
      .then((BranchReference branchRef) {

        final masterCommit = branchRef.sha.substring(0, 8);
        final message = 'Contents of $sourceDir from commit $masterCommit';

        final parentCommitShas = [];
        if(parentCommitSha != null) {
          parentCommitShas.add(parentCommitSha);
        }

        return gitDir.commitTree(treeSha, message, parentCommitShas: parentCommitShas);
      })
      .then((String newCommitSha) {
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
