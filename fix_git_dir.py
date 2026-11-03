import re

with open('lib/src/git_dir.dart', 'r') as f:
    c = f.read()

imports = "import 'branch_tracking.dart';\nimport 'worktree_entry.dart';\n"
c = re.sub(r"(import 'util\.dart';)", r"\1\n" + imports, c)

o_fromExisting = """  static Future<GitDir> fromExisting(
    String gitDirRoot, {
    bool allowSubdirectory = false,
  }) async {"""
n_fromExisting = """  static Future<GitDir> fromExisting(
    String gitDirRoot, {
    bool allowSubdirectory = false,
    bool allowBare = false,
  }) async {"""
c = c.replace(o_fromExisting, n_fromExisting)

c = re.sub(r"final pr = await runGit\(\[\n\s+'rev-parse',\n\s+'--show-toplevel',\n\s+\], processWorkingDir: path\);",
r"""final pr = await runGit([
      'rev-parse',
      '--is-inside-git-dir',
      '--is-bare-repository',
      '--show-toplevel',
    ], processWorkingDir: path, throwOnError: false);

    if (pr.exitCode != 0) {
      throw ArgumentError('The provided value "$gitDirRoot" is not a git directory');
    }

    final output = (pr.stdout as String).trim();
    final lines = output.split('\\n');
    
    final isBare = lines[1] == 'true';

    if (isBare) {
      if (allowBare) {
        return GitDir._raw(path);
      }
      throw ArgumentError('The provided value "$gitDirRoot" is a bare git directory, which is not allowed');
    }

    if (lines.length < 3) {
      throw ArgumentError('Failed to determine top-level directory');
    }
    
    final topLevel = lines[2].trim();

    final returnedPath = await Directory(topLevel).resolveSymbolicLinks();
    
    // Skip old returnedPath
    if (false)""", c)

c = c.replace("""    final returnedPath = await Directory(
      (pr.stdout as String).trim(),
    ).resolveSymbolicLinks();

    // Skip old returnedPath
    if (false)""", "")

o_isDirty = """  Future<bool> isWorkingTreeClean() async {
    final pr = await runCommand(['status', '--porcelain']);
    return (pr.stdout as String).isEmpty;
  }"""
n_isDirty = """  Future<bool> isWorkingTreeClean({bool includeUntracked = true}) async {
    final args = ['status', '--porcelain'];
    if (!includeUntracked) args.add('-uno');
    
    final pr = await runGit(args, processWorkingDir: path, environment: const {'GIT_OPTIONAL_LOCKS': '0'});
    return (pr.stdout as String).trim().isEmpty;
  }"""
c = c.replace(o_isDirty, n_isDirty)

new_methods = """
  /// Retrieves active worktrees in the repository.
  Future<List<WorktreeEntry>> worktrees() async {
    final result = await runCommand(['worktree', 'list', '--porcelain'], throwOnError: false);
    if (result.exitCode != 0) return [];
    return WorktreeEntry.fromPorcelain(result.stdout as String);
  }

  /// Checks whether this [GitDir] represents a secondary (linked) worktree
  /// rather than the primary/main repository root.
  Future<bool> isSecondaryWorktree() async {
    final out = await runCommand(['rev-parse', '--git-dir', '--git-common-dir'], throwOnError: false);
    if (out.exitCode != 0) return false;
    
    final lines = (out.stdout as String).trim().split('\\n');
    if (lines.length < 2) return false;

    final gitDir = lines[0].trim();
    final gitCommonDir = lines[1].trim();

    final canonicalGitDir = p.canonicalize(p.isAbsolute(gitDir) ? gitDir : p.join(path, gitDir));
    final canonicalGitCommonDir = p.canonicalize(p.isAbsolute(gitCommonDir) ? gitCommonDir : p.join(path, gitCommonDir));

    if (canonicalGitDir == canonicalGitCommonDir) return false;

    final expectedWorktreePrefix = p.join(canonicalGitCommonDir, 'worktrees');
    return p.isWithin(expectedWorktreePrefix, canonicalGitDir);
  }

  /// Removes a worktree given its path.
  Future<void> removeWorktree(String worktreePath, {bool force = false}) async {
    final args = ['worktree', 'remove'];
    if (force) args.add('--force');
    args.add(worktreePath);
    await runCommand(args);
  }

  /// Gets all local branches along with their upstream tracking status.
  Future<List<BranchTracking>> branchTracking() async {
    const format = '--format=%(refname:short)\\t%(upstream)\\t%(upstream:track)\\t%(objectname:short)';
    final result = await runCommand(['for-each-ref', format, 'refs/heads']);
    return BranchTracking.fromForEachRefOutput(result.stdout as String);
  }

  /// Returns the number of commits ahead and behind [leftRef] is relative to [rightRef].
  Future<({int ahead, int behind})> commitsAheadBehind(String leftRef, [String rightRef = '@{u}']) async {
    final result = await runCommand(['rev-list', '--left-right', '--count', '$leftRef...$rightRef']);
    final parts = (result.stdout as String).trim().split(RegExp(r'\\s+'));
    if (parts.length == 2) {
      return (ahead: int.parse(parts[0]), behind: int.parse(parts[1]));
    }
    throw StateError('Unexpected output from git rev-list: ${result.stdout}');
  }

  /// Gets the upstream of a branch. Returns null if no upstream is configured.
  Future<String?> upstreamBranch([String? branchName]) async {
    final result = await runCommand(['rev-parse', '--abbrev-ref', '${branchName ?? 'HEAD'}@{u}'], throwOnError: false);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }

  /// Determines the default branch by checking origin/HEAD or sniffing fallback candidates.
  Future<String?> remoteDefaultBranch({
    String remote = 'origin',
    List<String> fallbackCandidates = const ['main', 'master'],
  }) async {
    final revParseResult = await runCommand(['rev-parse', '--abbrev-ref', '$remote/HEAD'], throwOnError: false);

    if (revParseResult.exitCode == 0) {
      final out = (revParseResult.stdout as String).trim();
      if (out.startsWith('$remote/')) {
        return out.substring(remote.length + 1);
      }
      return out;
    }

    for (final branch in fallbackCandidates) {
      final result = await runCommand(['show-ref', '--verify', '--quiet', 'refs/remotes/$remote/$branch'], throwOnError: false);
      if (result.exitCode == 0) return branch;
    }
    return null;
  }

  /// Checks if [ancestorRef] is an ancestor of [descendantRef].
  Future<bool> isAncestor(String ancestorRef, String descendantRef) async {
    final result = await runCommand(['merge-base', '--is-ancestor', ancestorRef, descendantRef], throwOnError: false);
    return result.exitCode == 0;
  }

  /// Fetches from remote.
  Future<void> fetch({String? remote, bool all = false, bool prune = false}) async {
    final args = ['fetch'];
    if (all) args.add('--all');
    if (prune) args.add('--prune');
    if (remote != null) args.add(remote);
    await runCommand(args);
  }

  /// Deletes a local branch.
  Future<void> deleteBranch(String branchName, {bool force = false}) async {
    final args = ['branch', force ? '-D' : '-d', branchName];
    await runCommand(args);
  }
"""

match = re.search(r'^}\s*$', c, re.MULTILINE)
if match:
    idx = match.start()
    c = c[:idx] + new_methods + "\n}\n"
else:
    print("Could not find end of class")
    exit(1)

with open('lib/src/git_dir.dart', 'w') as f:
    f.write(c)
