/// Represents a worktree parsed from `git worktree list --porcelain`.
class WorktreeEntry {
  final String path;
  final String? sha;
  final String branch;
  final bool isBare;
  final bool isDetached;

  const WorktreeEntry({
    required this.path,
    required this.sha,
    required this.branch,
    required this.isBare,
    required this.isDetached,
  });

  static List<WorktreeEntry> fromPorcelain(String porcelain) {
    final worktrees = <WorktreeEntry>[];
    String? currentPath;
    String? currentSha;
    var currentBranch = '';
    var currentBare = false;
    var currentDetached = false;

    for (final line in porcelain.split('\n')) {
      if (line.isEmpty) {
        if (currentPath != null) {
          worktrees.add(
            WorktreeEntry(
              path: currentPath,
              sha: currentSha,
              branch: currentBranch,
              isBare: currentBare,
              isDetached: currentDetached,
            ),
          );
        }
        currentPath = null;
        currentSha = null;
        currentBranch = '';
        currentBare = false;
        currentDetached = false;
        continue;
      }

      if (line.startsWith('worktree ')) {
        currentPath = line.substring(9).trim();
      } else if (line.startsWith('HEAD ')) {
        currentSha = line.substring(5).trim();
      } else if (line.startsWith('branch ')) {
        currentBranch = line.substring(7).trim();
      } else if (line == 'bare') {
        currentBare = true;
      } else if (line == 'detached') {
        currentDetached = true;
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
        ),
      );
    }
    return worktrees;
  }
}
