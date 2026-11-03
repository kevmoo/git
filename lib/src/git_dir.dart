import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bot.dart';
import 'branch_reference.dart';
import 'branch_tracking.dart';
import 'commit.dart';
import 'commit_reference.dart';
import 'git_error.dart';
import 'tag.dart';
import 'top_level.dart';
import 'tree_entry.dart';
import 'util.dart';
import 'worktree_entry.dart';

/// Represents a local directory
class GitDir {
  static const _workTreeArg = '--work-tree';
  static const _gitDirArg = '--git-dir';

  final String path;
  final String? _gitWorkTree;

  GitDir._raw(this.path, {String? gitWorkTree})
    : assert(p.isAbsolute(path)),
      assert(gitWorkTree == null || p.isAbsolute(gitWorkTree)),
      _gitWorkTree = gitWorkTree;

  Future<int> commitCount([String branchName = 'HEAD']) async {
    final pr = await runCommand(['rev-list', '--count', branchName]);
    return int.parse(pr.stdout as String);
  }

  /// [revision] should probably be a sha1 to a commit.
  /// But GIT lets you do other things.
  /// See http://git-scm.com/docs/gitrevisions.html
  Future<Commit> commitFromRevision(String revision) async {
    final pr = await runCommand(['cat-file', '-p', revision]);
    return Commit.parse(pr.stdout as String);
  }

  Future<Map<String, Commit>> commits([String branchName = 'HEAD']) async {
    final pr = await runCommand(['rev-list', '--format=raw', branchName]);
    return Commit.parseRawRevList(pr.stdout as String);
  }

  Future<BranchReference?> branchReference(String branchName) async {
    final list = await branches();
    final matches = list.where((b) => b.branchName == branchName).toList();

    assert(matches.length <= 1);
    if (matches.isEmpty) {
      return null;
    } else {
      return matches.single;
    }
  }

  Future<List<BranchReference>> branches() async {
    final refs = await showRef(heads: true);
    return refs.map((cr) => cr.toBranchReference()).toList();
  }

  // TODO: Test this! No tags. Many tags. Etc.
  Stream<Tag> tags() async* {
    final refs = await showRef(tags: true);

    for (var ref in refs) {
      final pr = await runCommand(['cat-file', '-p', ref.sha]);
      yield Tag.parseCatFile(pr.stdout as String, ref);
    }
  }

  Future<List<CommitReference>> showRef({
    bool heads = false,
    bool tags = false,
  }) async {
    final args = ['show-ref'];

    if (heads) {
      args.add('--heads');
    }

    if (tags) {
      args.add('--tags');
    }

    final pr = await runCommand(args, throwOnError: false);
    if (pr.exitCode == 1) {
      // no heads present, return empty collection
      return [];
    }

    if (pr.exitCode != 0) {
      throw ProcessException('git', args, pr.stderr as String, pr.exitCode);
    }

    return CommitReference.fromShowRefOutput(pr.stdout as String);
  }

  Future<BranchReference> currentBranch() async {
    var pr = await runCommand(const [
      'rev-parse',
      '--verify',
      '--symbolic-full-name',
      'HEAD',
    ]);

    pr = await runCommand([
      'show-ref',
      '--verify',
      (pr.stdout as String).trim(),
    ]);

    return CommitReference.fromShowRefOutput(
      pr.stdout as String,
    ).single.toBranchReference();
  }

  Future<List<TreeEntry>> lsTree(
    String treeish, {
    bool subTreesOnly = false,
    String? path,
  }) async {
    final args = ['ls-tree'];

    if (subTreesOnly == true) {
      args.add('-d');
    }

    args.add(treeish);

    if (path != null) {
      args.add(path);
    }

    final pr = await runCommand(args);
    return TreeEntry.fromLsTreeOutput(pr.stdout as String);
  }

  /// Returns the SHA for the new commit if one is created.
  ///
  /// `null` if the branch is not updated.
  Future<String?> createOrUpdateBranch(
    String branchName,
    String treeSha,
    String commitMessage,
  ) async {
    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentValidSha1(treeSha, 'treeSha');

    final targetBranchRef = await branchReference(branchName);

    String? newCommitSha;

    if (targetBranchRef == null) {
      newCommitSha = await commitTree(treeSha, commitMessage);
    } else {
      newCommitSha = await _updateBranch(
        targetBranchRef.sha,
        treeSha,
        commitMessage,
      );
    }

    if (newCommitSha == null) {
      return null;
    }

    assert(isValidSha(newCommitSha));

    final branchRef = 'refs/heads/$branchName';

    // TODO: if update-ref fails should we leave the new commit dangling?
    // or at least log so the user can go clean up?
    await runCommand(['update-ref', branchRef, newCommitSha]);
    return newCommitSha;
  }

  /// Returns the SHA for the new commit if one is created.
  ///
  /// `null` if the branch is not updated.
  Future<String?> _updateBranch(
    String targetBranchSha,
    String treeSha,
    String commitMessage,
  ) async {
    final commitObj = await commitFromRevision(targetBranchSha);
    if (commitObj.treeSha == treeSha) {
      return null;
    }

    return commitTree(
      treeSha,
      commitMessage,
      parentCommitShas: [targetBranchSha],
    );
  }

  /// Returns the `SHA1` for the new commit.
  ///
  /// See [git-commit-tree](http://git-scm.com/docs/git-commit-tree)
  Future<String> commitTree(
    String treeSha,
    String commitMessage, {
    List<String>? parentCommitShas,
  }) async {
    requireArgumentValidSha1(treeSha, 'treeSha');

    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');
    requireArgument(
      commitMessage.trim() == commitMessage,
      'commitMessage',
      'Value cannot start or end with whitespace.',
    );

    parentCommitShas ??= [];

    final args = ['commit-tree', treeSha, '-m', commitMessage];

    for (final parentSha in parentCommitShas) {
      requireArgumentValidSha1(parentSha, 'parentCommitShas');
      args.addAll(['-p', parentSha]);
    }

    final pr = await runCommand(args);
    final sha = (pr.stdout as String).trim();
    assert(isValidSha(sha));
    return sha;
  }

  // TODO: should be renamed writeBlob?
  /// Given a list of [paths], write those files to the object store
  /// and return a [Map] where the key is the input path and the value is
  /// the SHA of the newly written object.
  Future<Map<String, String>> writeObjects(List<String> paths) async {
    final args = [
      'hash-object',
      '-t',
      'blob',
      '-w',
      '--no-filters',
      '--',
      ...paths,
    ];

    final pr = await runCommand(args);
    final val = (pr.stdout as String).trim();
    final shas = val.split(RegExp(r'\s+'));
    assert(shas.length == paths.length);
    assert(shas.every(isValidSha));
    final map = <String, String>{};
    for (var i = 0; i < shas.length; i++) {
      map[paths[i]] = shas[i];
    }
    return map;
  }

  /// If [echoOutput] is `true`, the output of the `git` command will be echoed.
  /// Note: [echoOutput] `true` will also cause the returned [ProcessResult] to
  /// have `null` values for [ProcessResult.stdout] and [ProcessResult.stderr].
  Future<ProcessResult> runCommand(
    Iterable<String> args, {
    bool throwOnError = true,
    bool echoOutput = false,
  }) {
    final list = args.toList();

    for (final arg in list) {
      requireArgumentNotNullOrEmpty(arg, 'args');
      requireArgument(
        !arg.contains(_workTreeArg),
        'args',
        'Cannot contain $_workTreeArg',
      );
      requireArgument(
        !arg.contains(_gitDirArg),
        'args',
        'Cannot contain $_gitDirArg',
      );
    }

    return runGit(
      [
        if (_gitWorkTree != null) ...[
          _gitDirArg,
          path,
          _workTreeArg,
          _gitWorkTree,
        ],
        ...list,
      ],
      throwOnError: throwOnError,
      processWorkingDir: path,
      echoOutput: echoOutput,
    );
  }

  /// Returns `true` if `git status --porcelain` reports no changes.
  ///
  /// If [includeUntracked] is `false`, untracked files are ignored and only
  /// modified or staged tracked files count as changes.
  Future<bool> isWorkingTreeClean({bool includeUntracked = true}) => runCommand(
    ['status', '--porcelain', if (!includeUntracked) '--untracked-files=no'],
  ).then((pr) => (pr.stdout as String).isEmpty);

  // TODO: TEST: someone puts a git dir when populated
  // TODO: TEST: someone puts in no content at all

  /// Updates the named branch with the content add by calling [populater].
  ///
  /// [populater] is called with a temporary [Directory] instance that should
  /// be populated with the desired content.
  ///
  /// If the content provided matches the content in the specificed
  /// [branchName], then no [Commit] is created and `null` is returned.
  ///
  /// If no content is added to the directory, an error is thrown.
  Future<Commit?> updateBranch(
    String branchName,
    Future<void> Function(Directory td) populater,
    String commitMessage,
  ) async {
    // TODO: ponder restricting branch names
    // see http://stackoverflow.com/questions/12093748/how-do-i-check-for-valid-git-branch-names/12093994#12093994

    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');

    final tempContentRoot = await _createTempDir();

    try {
      await populater(tempContentRoot);
      final commit = await updateBranchWithDirectoryContents(
        branchName,
        tempContentRoot.path,
        commitMessage,
      );
      return commit;
    } finally {
      await tempContentRoot.delete(recursive: true);
    }
  }

  Future<Commit?> updateBranchWithDirectoryContents(
    String branchName,
    String sourceDirectoryPath,
    String commitMessage,
  ) async {
    final tempGitRoot = await _createTempDir();

    final tempGitDir = GitDir._raw(
      tempGitRoot.path,
      gitWorkTree: sourceDirectoryPath,
    );

    // time for crazy clone tricks
    final args = ['clone', '--shared', '--bare', path, '.'];

    await runGit(args, processWorkingDir: tempGitDir.path);

    await tempGitDir.runCommand([
      'symbolic-ref',
      'HEAD',
      'refs/heads/$branchName',
    ]);

    try {
      // make sure there is something in the working three
      var pr = await tempGitDir.runCommand(['ls-files', '--others']);

      if ((pr.stdout as String).isEmpty) {
        throw GitError('No files were added');
      }
      // add new files to index

      // --verbose is not strictly needed, but nice for debugging
      pr = await tempGitDir.runCommand(['add', '--all', '--verbose']);

      // now to see if we have any changes here
      pr = await tempGitDir.runCommand(['status', '--porcelain']);

      if ((pr.stdout as String).isEmpty) {
        // no change in files! we should return a null result
        return null;
      }

      final args = ['commit', '--verbose'];

      Directory? tmpDir;

      if (LineSplitter.split(commitMessage).length > 1 && Platform.isWindows) {
        tmpDir = Directory.systemTemp.createTempSync('pkg_git_');

        final fileName = p.join(tmpDir.path, 'commit_message.txt');
        File(fileName).writeAsStringSync(
          commitMessage,
          mode: FileMode.writeOnly,
          flush: true,
        );

        args.addAll(['--file', fileName]);
      } else {
        args.addAll(['-m', commitMessage]);
      }

      try {
        // Time to commit.
        await tempGitDir.runCommand(args);
      } finally {
        tmpDir?.deleteSync(recursive: true);
      }

      // --verbose is not strictly needed, but nice for debugging
      await tempGitDir.runCommand([
        'push',
        '--verbose',
        '--progress',
        path,
        branchName,
      ]);

      // pr.stderr will have all of the info

      // so we have this wonderful new commit, right?
      // need to crack out the commit and return the value
      return await commitFromRevision('refs/heads/$branchName');
    } finally {
      await tempGitRoot.delete(recursive: true);
    }
  }

  static Future<bool> isGitDir(String path) async {
    final dir = Directory(path);

    if (dir.existsSync()) {
      return _isGitDir(dir);
    } else {
      return false;
    }
  }

  /// [allowContent] if `true`, doesn't check to see if the directory is empty
  ///
  /// [initialBranch] if provided, specifies the initial branch name.
  /// If not provided, the default for git CLI is used.
  ///
  /// Will fail if the source is a git directory
  /// (either at the root or a sub directory).
  static Future<GitDir> init(
    String path, {
    bool allowContent = false,
    String? initialBranch,
  }) async {
    final source = Directory(path);
    assert(source.existsSync());

    if (allowContent == true) {
      return _init(source, branchName: initialBranch);
    }

    // else, verify it's empty
    final isEmpty = await source.list().isEmpty;
    if (!isEmpty) {
      throw ArgumentError('source Directory is not empty - $source');
    }
    return _init(source, branchName: initialBranch);
  }

  /// If [allowSubdirectory] is true, a [GitDir] may be returned if [gitDirRoot]
  /// is a subdirectory within a Git repository.
  static Future<GitDir> fromExisting(
    String gitDirRoot, {
    bool allowSubdirectory = false,
    bool allowBare = false,
  }) async {
    final path = await Directory(gitDirRoot).absolute.resolveSymbolicLinks();

    final pr = await runGit(
      [
        'rev-parse',
        '--is-inside-git-dir',
        '--is-bare-repository',
        '--show-toplevel',
      ],
      processWorkingDir: path,
      throwOnError: false,
    );

    if (pr.exitCode != 0) {
      throw ArgumentError(
        'The provided value "$gitDirRoot" is not a git directory',
      );
    }

    final output = (pr.stdout as String).trim();
    final lines = output.split('\n');

    final isBare = lines[1] == 'true';

    if (isBare) {
      if (allowBare) {
        return GitDir._raw(path);
      }
      throw ArgumentError(
        'The provided value "$gitDirRoot" is a bare git directory, '
        'which is not allowed',
      );
    }

    if (lines.length < 3) {
      throw ArgumentError('Failed to determine top-level directory');
    }

    final topLevel = lines[2].trim();

    final returnedPath = await Directory(topLevel).resolveSymbolicLinks();

    if (p.equals(returnedPath, path) ||
        (allowSubdirectory && p.isWithin(returnedPath, path))) {
      return GitDir._raw(returnedPath);
    }

    throw ArgumentError(
      'The provided value "$gitDirRoot" is not '
      'the root of a git directory',
    );
  }

  static Future<GitDir> _init(Directory source, {String? branchName}) async {
    final isGitDir = await _isGitDir(source);
    if (isGitDir) {
      throw ArgumentError(
        'Cannot init a directory that is already a '
        'git directory',
      );
    }

    await runGit([
      'init',
      source.path,
      if (branchName != null) '--initial-branch=$branchName',
    ]);

    // does a bit more work than strictly necessary
    // but at least it ensures consistency
    return fromExisting(source.path);
  }

  static Future<bool> _isGitDir(Directory dir) async {
    assert(dir.existsSync());

    // using rev-parse because it will fail in many scenarios
    // including if the directory provided is a bare repository
    final pr = await runGit(
      ['rev-parse'],
      throwOnError: false,
      processWorkingDir: dir.path,
    );

    return pr.exitCode == 0;
  }

  /// Retrieves active worktrees in the repository.
  Future<List<WorktreeEntry>> worktrees() async {
    final result = await runCommand([
      'worktree',
      'list',
      '--porcelain',
    ], throwOnError: false);
    if (result.exitCode != 0) return [];
    return WorktreeEntry.fromPorcelain(result.stdout as String);
  }

  /// Checks whether this [GitDir] represents a secondary (linked) worktree
  /// rather than the primary/main repository root.
  Future<bool> isSecondaryWorktree() async {
    final out = await runGit(
      ['rev-parse', '--git-dir', '--git-common-dir'],
      processWorkingDir: path,
      throwOnError: false,
    );
    if (out.exitCode != 0) return false;

    final lines = (out.stdout as String).trim().split('\n');
    if (lines.length < 2) return false;

    final gitDir = lines[0].trim();
    final gitCommonDir = lines[1].trim();

    final canonicalGitDir = p.canonicalize(
      p.isAbsolute(gitDir) ? gitDir : p.join(path, gitDir),
    );
    final canonicalGitCommonDir = p.canonicalize(
      p.isAbsolute(gitCommonDir) ? gitCommonDir : p.join(path, gitCommonDir),
    );

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
    const format =
        '--format=%(refname:short)\t%(upstream)\t'
        '%(upstream:track)\t%(objectname:short)';
    final result = await runCommand(['for-each-ref', format, 'refs/heads']);
    return BranchTracking.fromForEachRefOutput(result.stdout as String);
  }

  /// Returns the number of commits ahead and behind [leftRef] is relative to
  /// [rightRef].
  Future<({int ahead, int behind})> commitsAheadBehind(
    String leftRef, [
    String rightRef = '@{u}',
  ]) async {
    final result = await runCommand([
      'rev-list',
      '--left-right',
      '--count',
      '$leftRef...$rightRef',
    ]);
    final parts = (result.stdout as String).trim().split(RegExp(r'\s+'));
    if (parts.length == 2) {
      return (ahead: int.parse(parts[0]), behind: int.parse(parts[1]));
    }
    throw StateError('Unexpected output from git rev-list: ${result.stdout}');
  }

  /// Gets the upstream of a branch. Returns null if no upstream is configured.
  Future<String?> upstreamBranch([String? branchName]) async {
    final result = await runCommand([
      'rev-parse',
      '--abbrev-ref',
      '${branchName ?? 'HEAD'}@{u}',
    ], throwOnError: false);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim();
  }

  /// Determines the default branch by checking origin/HEAD or sniffing fallback candidates.
  Future<String?> remoteDefaultBranch({
    String remote = 'origin',
    List<String> fallbackCandidates = const ['main', 'master'],
  }) async {
    final revParseResult = await runCommand([
      'rev-parse',
      '--abbrev-ref',
      '$remote/HEAD',
    ], throwOnError: false);

    if (revParseResult.exitCode == 0) {
      final out = (revParseResult.stdout as String).trim();
      if (out.startsWith('$remote/')) {
        return out.substring(remote.length + 1);
      }
      return out;
    }

    for (final branch in fallbackCandidates) {
      final result = await runCommand([
        'show-ref',
        '--verify',
        '--quiet',
        'refs/remotes/$remote/$branch',
      ], throwOnError: false);
      if (result.exitCode == 0) return branch;
    }
    return null;
  }

  /// Checks if [ancestorRef] is an ancestor of [descendantRef].
  Future<bool> isAncestor(String ancestorRef, String descendantRef) async {
    final result = await runCommand([
      'merge-base',
      '--is-ancestor',
      ancestorRef,
      descendantRef,
    ], throwOnError: false);
    return result.exitCode == 0;
  }

  /// Fetches from remote.
  Future<void> fetch({
    String? remote,
    bool all = false,
    bool prune = false,
  }) async {
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
}

Future<Directory> _createTempDir() =>
    Directory.systemTemp.createTemp('git.GitDir.');
