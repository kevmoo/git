part of bot_git;

// TODO: Future<bool> isGitDir

class GitDir {
  static final RegExp _shaRegExp = new RegExp(r'^[a-f0-9]{40}$');

  final Path _path;

  factory GitDir(String path) {
    return new GitDir.fromPath(new Path(path));
  }

  GitDir.fromPath(Path path) :
    this._path = path.canonicalize() {
    assert(new Directory.fromPath(_path).existsSync());
  }

  Path get path => _path;

  Future<int> getCommitCount([String branchName = 'HEAD']) {
    return Git.runGit(['rev-list', '--count', branchName], processWorkingDir: _workingDir)
        .then((ProcessResult pr) {
          return int.parse(pr.stdout);
        });
  }

  Future<List<String>> getBranchNames() {
    return Git.runGit(['ls-remote', '--heads', _path.toNativePath()])
        .then((ProcessResult pr) {
          assert(pr.exitCode == 0);

          return Git.parseLsRemoteOutput(pr.stdout)
              .mappedBy((gr) => gr.toBranchReference())
              .mappedBy((br) => br.branchName)
              .toList();
        });
  }

  Future<List<TreeEntry>> lsTree(String treeish,
      {bool subTreesOnly: false, String path: null}) {
    assert(treeish != null);
    final args = ['ls-tree'];

    if(subTreesOnly == true) {
      args.add('-d');
    }

    args.add(treeish);

    if(path != null) {
      args.add(path);
    }

    return runCommand(args)
        .then((ProcessResult pr) {
          return TreeEntry.fromLsTreeOutput(pr.stdout);
        });
  }

  Future<Map<String, String>> writeObject(List<String> paths) {
    final args = ['hash-object', '-t', 'blob', '-w', '--no-filters', '--'];
    args.addAll(paths);
    return runCommand(args)
        .then((ProcessResult pr) {
          final val = pr.stdout.trim();
          final shas = val.split(new RegExp(r'\s+'));
          assert(shas.length == paths.length);
          assert(shas.every((sha) => _shaRegExp.hasMatch(sha)));
          final map = new Map<String, String>();
          for(var i = 0; i < shas.length; i++) {
            map[paths[i]] = shas[i];
          }
          return map;
        });
  }

  Future<ProcessResult> runCommand(List<String> args, [bool throwOnError = true]) {
    return Git.runGit(args, throwOnError: throwOnError, processWorkingDir: _workingDir);
  }

  String get _workingDir => _path.toString();

  /**
   * [allowContent] if true, doesn't check to see if the directory is empty
   * init will still succeed, even if the directory already has a git repository.
   */
  static Future<GitDir> init(Directory source, {bool allowContent: false}) {
    assert(source.existsSync());

    if(allowContent == true) {
      return _init(source);
    }

    // else, verify it's empty
    return IoHelpers.isEmpty(source)
        .then((bool isEmpty) {
          if(!isEmpty) {
            throw 'source Directory is not empty';
          }
          return _init(source);
        });
  }

  static Future<GitDir> _init(Directory source) {
    return Git.runGit(['init', source.path])
        .then((ProcessResult pr) {
          return new GitDir(source.path);
        });
  }
}
