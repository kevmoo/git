/// A worktree parsed from `git worktree list --porcelain`.
class WorktreeEntry {
  /// The absolute path of the worktree.
  final String path;

  /// The SHA of the worktree's `HEAD`, or `null` for bare entries.
  final String? sha;

  /// The checked-out branch name without the `refs/heads/` prefix, or an empty
  /// string when the worktree is bare or detached.
  final String branch;

  /// Whether this entry is the bare repository root.
  final bool isBare;

  /// Whether the worktree has a detached `HEAD`.
  final bool isDetached;

  /// Whether the worktree is locked (`git worktree lock`).
  final bool isLocked;

  /// The reason given when the worktree was locked, if any.
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

  /// Parses the output of `git worktree list --porcelain`.
  static List<WorktreeEntry> fromPorcelain(String porcelain) => [
    for (final block in _blocks(porcelain))
      if (_parseBlock(block) case final entry?) entry,
  ];

  static Iterable<List<String>> _blocks(String porcelain) sync* {
    var current = <String>[];
    for (final line in porcelain.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isNotEmpty) {
        current.add(trimmed);
      } else if (current.isNotEmpty) {
        yield current;
        current = <String>[];
      }
    }
    if (current.isNotEmpty) yield current;
  }

  static WorktreeEntry? _parseBlock(List<String> lines) {
    String? path;
    String? sha;
    var branch = '';
    var isBare = false;
    var isDetached = false;
    var isLocked = false;
    String? lockReason;

    for (final line in lines) {
      final (key, value) = _split(line);
      switch (key) {
        case 'worktree':
          path = value;
        case 'HEAD':
          sha = value;
        case 'branch':
          branch = _stripHeads(value ?? '');
        case 'bare':
          isBare = true;
        case 'detached':
          isDetached = true;
        case 'locked':
          isLocked = true;
          lockReason = value;
      }
    }

    if (path == null) return null;
    return WorktreeEntry(
      path: path,
      sha: sha,
      branch: branch,
      isBare: isBare,
      isDetached: isDetached,
      isLocked: isLocked,
      lockReason: lockReason,
    );
  }

  static (String, String?) _split(String line) {
    final space = line.indexOf(' ');
    if (space < 0) return (line, null);
    final value = line.substring(space + 1).trim();
    return (line.substring(0, space), value.isEmpty ? null : value);
  }

  static String _stripHeads(String ref) {
    const prefix = 'refs/heads/';
    return ref.startsWith(prefix) ? ref.substring(prefix.length) : ref;
  }
}
