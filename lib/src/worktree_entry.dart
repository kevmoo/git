/// Represents a worktree parsed from `git worktree list --porcelain`.
class WorktreeEntry {
  final String path;
  final String? sha;
  final String branch;
  final bool isBare;
  final bool isDetached;
  final bool isLocked;
  final String? lockReason;

  const WorktreeEntry({
    required this.path,
    required this.sha,
    required this.branch,
    required this.isBare,
    required this.isDetached,
    this.isLocked = false,
    this.lockReason,
  });

  static List<WorktreeEntry> fromPorcelain(String porcelain) {
    final worktrees = <WorktreeEntry>[];
    String? currentPath;
    String? currentSha;
    var currentBranch = '';
    var currentBare = false;
    var currentDetached = false;
    var currentLocked = false;
    String? currentLockReason;

    for (final line in porcelain.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        if (currentPath != null) {
          worktrees.add(
            WorktreeEntry(
              path: currentPath,
              sha: currentSha,
              branch: currentBranch,
              isBare: currentBare,
              isDetached: currentDetached,
              isLocked: currentLocked,
              lockReason: currentLockReason,
            ),
          );
        }
        currentPath = null;
        currentSha = null;
        currentBranch = '';
        currentBare = false;
        currentDetached = false;
        currentLocked = false;
        currentLockReason = null;
        continue;
      }

      if (trimmed.startsWith('worktree ')) {
        currentPath = trimmed.substring(9).trim();
      } else if (trimmed.startsWith('HEAD ')) {
        currentSha = trimmed.substring(5).trim();
      } else if (trimmed.startsWith('branch ')) {
        var branch = trimmed.substring(7).trim();
        if (branch.startsWith('refs/heads/')) {
          branch = branch.substring('refs/heads/'.length);
        }
        currentBranch = branch;
      } else if (trimmed == 'bare') {
        currentBare = true;
      } else if (trimmed == 'detached') {
        currentDetached = true;
      } else if (trimmed == 'locked') {
        currentLocked = true;
        currentLockReason = null;
      } else if (trimmed.startsWith('locked ')) {
        currentLocked = true;
        currentLockReason = trimmed.substring(7).trim();
      }
    }

    if (currentPath != null) {
      worktrees.add(
        WorktreeEntry(
          path: currentPath,
          sha: currentSha,
          branch: currentBranch,
          isBare: currentBare,
          isDetached: currentDetached,
          isLocked: currentLocked,
          lockReason: currentLockReason,
        ),
      );
    }
    return worktrees;
  }
}
