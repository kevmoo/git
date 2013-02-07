part of bot_git;

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
    return runCommand(['rev-list', '--count', branchName])
        .then((ProcessResult pr) {
          return int.parse(pr.stdout);
        });
  }

  Future<List<String>> getBranchNames() {
    return getBranchReferences()
        .then((list) {
          return list
              .map((br) => br.branchName)
              .toList();
        });
  }

  Future<BranchReference> getBranchReference(String branchName) {
    return getBranchReferences()
        .then((list) {
          final matches = list.where((b) => b.branchName == branchName)
              .toList();

          assert(matches.length <= 1);
          if(matches.isEmpty) {
            return null;
          } else {
            return matches.single;
          }
        });
  }

  Future<List<BranchReference>> getBranchReferences() {
    return runCommand(['show-ref', '--heads'], false)
        .then((ProcessResult pr) {
          if(pr.exitCode == 1) {
            // no heads present, return empty collection
            return [];
          }

          // otherwise, it should have worked fine...
          assert(pr.exitCode == 0);

          return CommitReference.fromShowRefOutput(pr.stdout)
              .map((gr) => gr.toBranchReference())
              .toList();
        });
  }

  Future<BranchReference> getCurrentBranch() {
    return runCommand(['rev-parse', '--verify', '--symbolic-full-name', 'HEAD'])
        .then((ProcessResult pr) {
          return runCommand(['show-ref', '--verify', pr.stdout.trim()]);
        })
        .then((ProcessResult pr) {
          return CommitReference.fromShowRefOutput(pr.stdout).single.toBranchReference();
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

  /**
   * Given a list of [paths], write those files to the object store
   * and return a [Map] where the key is the input path and the value is
   * the SHA of the newly written object.
   */
  Future<Map<String, String>> writeObjects(List<String> paths) {
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

  /**
   * [rev] should probably be a sha1 to a commit.
   * But GIT lets you do other things.
   * See http://git-scm.com/docs/gitrevisions.html
   */
  Future<Commit> getCommit(String rev) {
    return runCommand(['cat-file', '-p', rev])
        .then((ProcessResult pr) {
          return Commit.parse(pr.stdout);
        });
  }

  Future<ProcessResult> runCommand(List<String> args, [bool throwOnError = true]) {
    return Git.runGit(args, throwOnError: throwOnError, processWorkingDir: _workingDir);
  }

  Future<bool> isWorkingTreeClean() {
    return runCommand(['status', '--porcelain'])
        .then((ProcessResult pr) => pr.stdout.isEmpty);
  }

  String get _workingDir => _path.toString();

  static Future<bool> isGitDir(String path) {
    final dir = new Directory(path);
    return dir.exists()
        .then((bool exists) {
          if(exists) {
            return _isGitDir(dir);
          } else {
            return false;
          }
        });
  }

  /**
   * [allowContent] if true, doesn't check to see if the directory is empty
   *
   * Will fail if the source is a git directory (either at the root or a sub directory)
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
    return _isGitDir(source)
        .then((bool isGitDir) {
          if(isGitDir) {
            throw 'Cannot init a directory that is already a git directory';
          }

          return Git.runGit(['init', source.path]);
        })
        .then((ProcessResult pr) {
          return new GitDir(source.path);
        });
  }

  static Future<bool> _isGitDir(Directory dir) {
    assert(dir.existsSync());

    // using rev-parse because it will fail in many scenarios
    // including if the directory provided is a bare repository
    return Git.runGit(['rev-parse'],
        throwOnError: false, processWorkingDir: dir.path)
        .then((ProcessResult pr) {
          // if exitCode is 0, status worked...which means this is a git dir
          return pr.exitCode == 0;
        });
  }
}
