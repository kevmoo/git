import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'bot.dart';
import 'branch_reference.dart';
import 'commit.dart';
import 'commit_reference.dart';
import 'git_error.dart';
import 'tag.dart';
import 'top_level.dart';
import 'tree_entry.dart';
import 'util.dart';

class GitDir {
  static const _workTreeArg = '--work-tree=';
  static const _gitDirArg = '--git-dir=';
  static final RegExp _shaRegExp = new RegExp(r'^[a-f0-9]{40}$');

  final String _path;
  final String _gitWorkTree;

  GitDir._raw(this._path, [this._gitWorkTree]) {
    assert(p.isAbsolute(this._path));
    assert(_gitWorkTree == null || p.isAbsolute(this._gitWorkTree));
  }

  String get path => _path;

  Future<int> getCommitCount([String branchName = 'HEAD']) async {
    var pr = await runCommand(['rev-list', '--count', branchName]);
    return int.parse(pr.stdout as String);
  }

  /// [rev] should probably be a sha1 to a commit.
  /// But GIT lets you do other things.
  /// See http://git-scm.com/docs/gitrevisions.html
  Future<Commit> getCommit(String rev) async {
    var pr = await runCommand(['cat-file', '-p', rev]);
    return Commit.parse(pr.stdout as String);
  }

  Future<Map<String, Commit>> getCommits([String branchName = 'HEAD']) async {
    var pr = await runCommand(['rev-list', '--format=raw', branchName]);
    return Commit.parseRawRevList(pr.stdout as String);
  }

  Future<List<String>> getBranchNames() async {
    var list = await getBranchReferences();
    return list.map((br) => br.branchName).toList();
  }

  Future<BranchReference> getBranchReference(String branchName) async {
    var list = await getBranchReferences();
    final matches = list.where((b) => b.branchName == branchName).toList();

    assert(matches.length <= 1);
    if (matches.isEmpty) {
      return null;
    } else {
      return matches.single;
    }
  }

  Future<List<BranchReference>> getBranchReferences() async {
    var refs = await showRef(heads: true);
    return refs.map((cr) => cr.toBranchReference()).toList();
  }

  // TODO: Test this! No tags. Many tags. Etc.
  Future<List<Tag>> getTags() {
    return showRef(tags: true).then((List<CommitReference> refs) {
      final futures = refs.map((ref) {
        return runCommand(['cat-file', '-p', ref.sha]).then((ProcessResult pr) {
          return Tag.parseCatFile(pr.stdout as String);
        });
      });

      return Future.wait(futures);
    });
  }

  Future<List<CommitReference>> showRef(
      {bool heads: false, bool tags: false}) async {
    final args = ['show-ref'];

    if (heads) {
      args.add('--heads');
    }

    if (tags) {
      args.add('--tags');
    }

    var pr = await runCommand(args, false);
    if (pr.exitCode == 1) {
      // no heads present, return empty collection
      return [];
    }

    // otherwise, it should have worked fine...
    assert(pr.exitCode == 0);

    return CommitReference.fromShowRefOutput(pr.stdout as String);
  }

  Future<BranchReference> getCurrentBranch() async {
    var pr = await runCommand(
        const ['rev-parse', '--verify', '--symbolic-full-name', 'HEAD']);

    pr = await runCommand(
        ['show-ref', '--verify', (pr.stdout as String).trim()]);

    return CommitReference
        .fromShowRefOutput(pr.stdout as String)
        .single
        .toBranchReference();
  }

  Future<List<TreeEntry>> lsTree(String treeish,
      {bool subTreesOnly: false, String path}) async {
    assert(treeish != null);
    final args = ['ls-tree'];

    if (subTreesOnly == true) {
      args.add('-d');
    }

    args.add(treeish);

    if (path != null) {
      args.add(path);
    }

    var pr = await runCommand(args);
    return TreeEntry.fromLsTreeOutput(pr.stdout as String);
  }

  /// Returns the SHA for the new commit if one is created. `null` if the branch
  /// is not updated.
  Future<String> createOrUpdateBranch(
      String branchName, String treeSha, String commitMessage) async {
    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentValidSha1(treeSha, 'treeSha');

    var targetBranchRef = await getBranchReference(branchName);

    String newCommitSha;

    if (targetBranchRef == null) {
      newCommitSha = await commitTree(treeSha, commitMessage);
    } else {
      newCommitSha =
          await _updateBranch(targetBranchRef.sha, treeSha, commitMessage);
    }

    if (newCommitSha == null) {
      return null;
    }

    assert(isValidSha(newCommitSha));

    var branchRef = 'refs/heads/$branchName';

    // TODO: if update-ref fails should we leave the new commit dangling?
    // or at least log so the user can go clean up?
    await runCommand(['update-ref', branchRef, newCommitSha]);
    return newCommitSha;
  }

  /// Returns the SHA for the new commit if one is created. `null` if the branch
  /// is not updated.
  Future<String> _updateBranch(
      String targetBranchSha, String treeSha, String commitMessage) async {
    var commitObj = await getCommit(targetBranchSha);
    if (commitObj.treeSha == treeSha) {
      return null;
    }

    return commitTree(treeSha, commitMessage,
        parentCommitShas: [targetBranchSha]);
  }

  /// Returns the `SHA1` for the new commit.
  ///
  /// See [git-commit-tree](http://git-scm.com/docs/git-commit-tree)
  Future<String> commitTree(String treeSha, String commitMessage,
      {List<String> parentCommitShas}) async {
    requireArgumentValidSha1(treeSha, 'treeSha');

    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');
    requireArgument(commitMessage.trim() == commitMessage, 'commitMessage',
        'Value cannot start or end with whitespace.');

    parentCommitShas ??= [];

    final args = ['commit-tree', treeSha, '-m', commitMessage];

    for (final parentSha in parentCommitShas) {
      requireArgumentValidSha1(parentSha, 'parentCommitShas');
      args.addAll(['-p', parentSha]);
    }

    var pr = await runCommand(args);
    final sha = (pr.stdout as String).trim();
    assert(isValidSha(sha));
    return sha;
  }

  // TODO: should be renamed writeBlob?
  /// Given a list of [paths], write those files to the object store
  /// and return a [Map] where the key is the input path and the value is
  /// the SHA of the newly written object.
  Future<Map<String, String>> writeObjects(List<String> paths) async {
    var args = ['hash-object', '-t', 'blob', '-w', '--no-filters', '--']
      ..addAll(paths);

    var pr = await runCommand(args);
    var val = (pr.stdout as String).trim();
    var shas = val.split(new RegExp(r'\s+'));
    assert(shas.length == paths.length);
    assert(shas.every(_shaRegExp.hasMatch));
    var map = new Map<String, String>();
    for (var i = 0; i < shas.length; i++) {
      map[paths[i]] = shas[i];
    }
    return map;
  }

  Future<ProcessResult> runCommand(Iterable<String> args,
      [bool throwOnError = true]) {
    requireArgumentNotNull(args, 'args');

    final list = args.toList();

    for (final arg in list) {
      requireArgumentNotNullOrEmpty(arg, 'args');
      requireArgument(
          !arg.contains(_workTreeArg), 'args', 'Cannot contain $_workTreeArg');
      requireArgument(
          !arg.contains(_gitDirArg), 'args', 'Cannot contain $_gitDirArg');
    }

    if (_gitWorkTree != null) {
      list.insert(0, '$_workTreeArg$_gitWorkTree');
    }

    return runGit(list,
        throwOnError: throwOnError, processWorkingDir: _processWorkingDir);
  }

  Future<bool> isWorkingTreeClean() {
    return runCommand(['status', '--porcelain'])
        .then((ProcessResult pr) => (pr.stdout as String).isEmpty);
  }

  // TODO: TEST: someone puts a git dir when populated
  // TODO: TEST: someone puts in no content at all

  /// Updates the named branch with the content add by calling [populater].
  ///
  /// [populater] is called with a temporary [Directory] instance that should
  /// be populated with the desired content.
  ///
  /// If the content provided matches the content in the specificed [branchName],
  /// then no [Commit] is created and `null` is returned.
  ///
  /// If no content is added to the directory, an error is thrown.
  Future<Commit> updateBranch(String branchName, Future populater(Directory td),
      String commitMessage) async {
    // TODO: ponder restricting branch names
    // see http://stackoverflow.com/questions/12093748/how-do-i-check-for-valid-git-branch-names/12093994#12093994

    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');

    Directory tempContentRoot = await _createTempDir();

    try {
      await populater(tempContentRoot);
      var commit = await updateBranchWithDirectoryContents(
          branchName, tempContentRoot.path, commitMessage);
      return commit;
    } finally {
      await tempContentRoot.delete(recursive: true);
    }
  }

  Future<Commit> updateBranchWithDirectoryContents(String branchName,
      String sourceDirectoryPath, String commitMessage) async {
    Directory tempGitRoot = await _createTempDir();

    GitDir tempGitDir = new GitDir._raw(tempGitRoot.path, sourceDirectoryPath);

    // time for crazy clone tricks
    var args = ['clone', '--shared', '--bare', path, '.'];

    await runGit(args, processWorkingDir: tempGitDir.path);

    await tempGitDir
        .runCommand(['symbolic-ref', 'HEAD', 'refs/heads/$branchName']);

    try {
      // make sure there is something in the working three
      var pr = await tempGitDir.runCommand(['ls-files', '--others']);

      if ((pr.stdout as String).isEmpty) {
        throw new GitError('No files were added');
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

      // Time to commit.
      await tempGitDir.runCommand(['commit', '--verbose', '-m', commitMessage]);

      // --verbose is not strictly needed, but nice for debugging
      await tempGitDir
          .runCommand(['push', '--verbose', '--progress', path, branchName]);

      // pr.stderr will have all of the info

      // so we have this wonderful new commit, right?
      // need to crack out the commit and return the value
      return getCommit('refs/heads/$branchName');
    } finally {
      await tempGitRoot.delete(recursive: true);
    }
  }

  String get _processWorkingDir => _path.toString();

  static Future<bool> isGitDir(String path) async {
    final dir = new Directory(path);

    var exists = await dir.exists();
    if (exists) {
      return _isGitDir(dir);
    } else {
      return false;
    }
  }

  /// [allowContent] if true, doesn't check to see if the directory is empty
  ///
  /// Will fail if the source is a git directory (either at the root or a sub directory)
  static Future<GitDir> init(Directory source,
      {bool allowContent: false}) async {
    assert(source.existsSync());

    if (allowContent == true) {
      return _init(source);
    }

    // else, verify it's empty
    var isEmpty = await source.list().isEmpty;
    if (!isEmpty) {
      throw new ArgumentError('source Directory is not empty - $source');
    }
    return _init(source);
  }

  static Future<GitDir> fromExisting(String gitDirRoot) async {
    var path = p.absolute(gitDirRoot);

    var pr = await runGit(['rev-parse', '--git-dir'],
        processWorkingDir: path.toString());
    if (pr.stdout.trim() == '.git') {
      return new GitDir._raw(path);
    } else {
      throw new ArgumentError('The provided value "$gitDirRoot" is not '
          'the root of a git directory');
    }
  }

  static Future<GitDir> _init(Directory source) async {
    var isGitDir = await _isGitDir(source);
    if (isGitDir) {
      throw new ArgumentError('Cannot init a directory that is already a '
          'git directory');
    }

    await runGit(['init', source.path]);

    // does a bit more work than strictly nessesary
    // but at least it ensures consistency
    return fromExisting(source.path);
  }

  static Future<bool> _isGitDir(Directory dir) async {
    assert(dir.existsSync());

    // using rev-parse because it will fail in many scenarios
    // including if the directory provided is a bare repository
    var pr = await runGit(['rev-parse'],
        throwOnError: false, processWorkingDir: dir.path);

    return pr.exitCode == 0;
  }
}

Future<Directory> _createTempDir() =>
    Directory.systemTemp.createTemp('git.GitDir.');
