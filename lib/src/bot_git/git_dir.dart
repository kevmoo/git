part of bot_git;

class GitDir {
  static const _workTreeArg = '--work-tree=';
  static const _gitDirArg = '--git-dir=';
  static final RegExp _shaRegExp = new RegExp(r'^[a-f0-9]{40}$');

  final String _path;
  final String _gitWorkTree;

  GitDir._raw(this._path, [this._gitWorkTree = null]) {
    assert(pathos.isAbsolute(this._path));
    assert(_gitWorkTree == null || pathos.isAbsolute(this._gitWorkTree));
  }

  String get path => _path;

  Future<int> getCommitCount([String branchName = 'HEAD']) {
    return runCommand(['rev-list', '--count', branchName])
        .then((ProcessResult pr) {
          return int.parse(pr.stdout);
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

  Future<Map<String, Commit>> getCommits([String branchName = 'HEAD']) {
    return runCommand(['rev-list', '--format=raw', branchName])
        .then((ProcessResult pr) => Commit.parseRawRevList(pr.stdout));
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
    return showRef(heads: true)
        .then((List<CommitReference> refs) {
          return refs.map((cr) => cr.toBranchReference()).toList();
        });
  }

  /*
   * TODO: Test this! No tags. Many tags. Etc.
   */
  Future<List<Tag>> getTags() {
    return showRef(tags: true)
        .then((List<CommitReference> refs) {

          final futures = refs.map((ref) {
            return runCommand(['cat-file', '-p', ref.sha])
                .then((ProcessResult pr) {
                  return Tag.parseCatFile(pr.stdout);
                });
          });

          return Future.wait(futures);
        });
  }

  Future<List<CommitReference>> showRef({bool heads:false, bool tags:false}) {
    final args = ['show-ref'];

    if(heads) {
      args.add('--heads');
    }

    if(tags) {
      args.add('--tags');
    }

    return runCommand(args, false)
        .then((ProcessResult pr) {
          if(pr.exitCode == 1) {
            // no heads present, return empty collection
            return [];
          }

          // otherwise, it should have worked fine...
          assert(pr.exitCode == 0);

          return CommitReference.fromShowRefOutput(pr.stdout);
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
   * Returns the SHA for the new commit if one is created. `null` if the branch is not updated.
   */
  Future<String> createOrUpdateBranch(String branchName, String treeSha,
                              String commitMessage) {
    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentValidSha1(treeSha, 'treeSha');

    return getBranchReference(branchName)
        .then((BranchReference targetBranchRef) {
          if(targetBranchRef == null) {
            return commitTree(treeSha, commitMessage);
          } else {
            return _updateBranch(targetBranchRef.sha, treeSha, commitMessage);
          }
        })
        .then((String newCommitSha) {
          if(newCommitSha == null) {
            return null;
          }

          assert(Git.isValidSha(newCommitSha));

          final targetBranchRef = 'refs/heads/$branchName';

          // TODO: if update-ref fails should we leave the new commit dangling?
          // or at least log so the user can go clean up?
          return runCommand(['update-ref', targetBranchRef, newCommitSha])
              .then((ProcessResult pr) => newCommitSha);
        });
  }

  /**
   * Returns the SHA for the new commit if one is created. `null` if the branch is not updated.
   */
  Future<String> _updateBranch(String targetBranchSha, String treeSha, String commitMessage) {
    return getCommit(targetBranchSha)
        .then((Commit commitObj) {
          if(commitObj.treeSha == treeSha) {
            return null;
          }

          return commitTree(treeSha, commitMessage, parentCommitShas: [targetBranchSha]);
        });
  }

  /**
   * Returns the `SHA1` for the new commit.
   *
   * See [git-commit-tree](http://git-scm.com/docs/git-commit-tree)
   */
  Future<String> commitTree(String treeSha, String commitMessage, {List<String> parentCommitShas}) {
    requireArgumentValidSha1(treeSha, 'treeSha');

    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');
    requireArgument(commitMessage.trim() == commitMessage, 'commitMessage', 'Value cannot start or end with whitespace.');

    if(parentCommitShas == null) {
      parentCommitShas = [];
    }

    final args = ['commit-tree', treeSha, '-m', commitMessage];

    for(final parentSha in parentCommitShas) {
      requireArgumentValidSha1(parentSha, 'parentCommitShas');
      args.addAll(['-p', parentSha]);
    }

    return runCommand(args)
        .then((ProcessResult pr) {
          final sha = pr.stdout.trim();
          assert(Git.isValidSha(sha));
          return sha;
        });
  }

  // TODO: should be renamed writeBlob?
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

  Future<ProcessResult> runCommand(Iterable<String> args, [bool throwOnError = true]) {
    requireArgumentNotNull(args, 'args');

    final list = args.toList();

    for(final arg in list) {
      requireArgumentNotNullOrEmpty(arg, 'args');
      requireArgument(!arg.contains(_workTreeArg), 'args', 'Cannot contain $_workTreeArg');
      requireArgument(!arg.contains(_gitDirArg), 'args', 'Cannot contain $_gitDirArg');
    }

    if(_gitWorkTree != null) {
      list.insert(0, '$_workTreeArg${_gitWorkTree}');
    }

    return Git.runGit(list, throwOnError: throwOnError, processWorkingDir: _processWorkingDir);
  }

  Future<bool> isWorkingTreeClean() {
    return runCommand(['status', '--porcelain'])
        .then((ProcessResult pr) => pr.stdout.isEmpty);
  }

  // TODO: TEST: someone puts a git dir when populated
  // TODO: TEST: someone puts in no content at all

  /**
   * If the content provided matches the content in the specificed [branchName], then
   * `null` is returned.
   *
   * If no content is added to the directory, an [Error] is thrown.
   */
  Future<Commit> populateBranch(String branchName, PopulateTempDir populator, String commitMessage) {
    // TODO: ponder restricting branch names
    // see http://stackoverflow.com/questions/12093748/how-do-i-check-for-valid-git-branch-names/12093994#12093994

    requireArgumentNotNullOrEmpty(branchName, 'branchName');
    requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');

    _TempDirs tempDirs;

    return getBranchReference(branchName)
        .then((BranchReference value) {

          if(value == null) {
            return _getTempDirPairForNewBranch(branchName);
          } else {
            return _getTempDirPair(branchName);
          }
        })
        .then((_TempDirs value) {
          tempDirs = value;

          return populator(tempDirs.gitWorkTreeDir);
        })
        .then((_) {

          // make sure there is something in the working three
          return tempDirs.gitDir.runCommand(['ls-files', '--others']);
        })
        .then((ProcessResult pr) {
          if(pr.stdout.isEmpty) {
            throw new GitError('No files were added');
          }
          // add new files to index

          // --verbose is not strictly needed, but nice for debugging
          return tempDirs.gitDir.runCommand(['add', '--all', '--verbose']);
        })
        .then((ProcessResult pr) {
          // now to see if we have any changes here
          return tempDirs.gitDir.runCommand(['status', '--porcelain']);
        })
        .then((ProcessResult pr) {
          if(pr.stdout.isEmpty) {
            // no change in files! we should return a null result
            return null;
          }

          // Time to commit.
          return tempDirs.gitDir.runCommand(['commit', '--verbose', '-m', commitMessage])
              .then((ProcessResult pr) {
                // --verbose is not strictly needed, but nice for debugging
                return tempDirs.gitDir.runCommand(['push', '--verbose', '--progress', path, branchName]);
              })
              .then((ProcessResult pr) {
                // pr.stderr will have all of the info

                // so we have this wonderful new commit, right?
                // need to crack out the commit and return the value
                return getCommit('refs/heads/$branchName');
              });
        })
        .whenComplete(() {
          if(tempDirs != null) {
            return tempDirs.dispose();
          }
        });
  }

  // if branch does not exist, do simple clone, then checkout
  Future<_TempDirs> _getTempDirPairForNewBranch(String newBranchName) {
    _TempDirs td;

    return _TempDirs.create()
        .then((_TempDirs val) {

          td = val;

          // time for crazy clone tricks
          final args = ['clone', '--shared', '--no-checkout', '--bare', path, '.'];

          return Git.runGit(args, processWorkingDir: td.gitHostDir.path);
      })
      .then((ProcessResult _) {
        return td.gitDir.runCommand(['checkout', '--orphan', newBranchName]);
      })
      .then((ProcessResult _) {

        // since we're checked out, need to clear out local content
        return td.gitDir.runCommand(['rm', '-r', '-f', '.']);
      })
      .then((ProcessResult _) => td);
  }

  // if branch exists, then clone to that branch, clear it out
  Future<_TempDirs> _getTempDirPair(String existingBranchName) {
    _TempDirs td;

    return _TempDirs.create()
        .then((_TempDirs val) {

          td = val;

          // time for crazy clone tricks
          final args = ['clone', '--shared', '--branch', existingBranchName, '--bare', path, '.'];

          return Git.runGit(args, processWorkingDir: td.gitHostDir.path);
      })
      .then((ProcessResult _) {
        return td.gitDir.runCommand(['checkout']);
      })
      .then((ProcessResult _) {

        // since we're checked out, need to clear out local content
        return td.gitDir.runCommand(['rm', '-r', '.']);
      })
      .then((ProcessResult _) => td);
  }

  String get _processWorkingDir => _path.toString();

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
            throw new ArgumentError('source Directory is not empty - $source');
          }
          return _init(source);
        });
  }

  static Future<GitDir> fromExisting(String gitDirRoot) {
    final path = pathos.absolute(gitDirRoot);

    return Git.runGit(['rev-parse', '--git-dir'], processWorkingDir: path.toString())
        .then((ProcessResult pr) {
          if(pr.stdout.trim() == '.git') {
            return new GitDir._raw(path);
          } else {
            throw new ArgumentError('The provided value "$gitDirRoot" is not the root of a git directory');
          }
        });
  }

  static Future<GitDir> _init(Directory source) {
    return _isGitDir(source)
        .then((bool isGitDir) {
          if(isGitDir) {
            throw new ArgumentError('Cannot init a directory that is already a git directory');
          }

          return Git.runGit(['init', source.path]);
        })
        .then((ProcessResult pr) {

          // does a bit more work than strictly nessesary
          // but at least it ensures consistency
          return fromExisting(source.path);
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

class _TempDirs {
  final GitDir gitDir;
  final TempDir gitHostDir;
  final TempDir gitWorkTreeDir;

  static Future<_TempDirs> create() {
    TempDir host, work;

    return TempDir.create()
        .then((TempDir val) {
          host = val;

          return TempDir.create();
        })
        .then((TempDir val) {
          work = val;

          var gd = new GitDir._raw(host.path, work.path);
          return new _TempDirs(gd, host, work);
        });
  }

  _TempDirs(this.gitDir, this.gitHostDir, this.gitWorkTreeDir);

  String toString() => [gitHostDir, gitWorkTreeDir].toString();

  Future dispose() {
    return Future.forEach([gitHostDir, gitWorkTreeDir], (td) => td.dispose());
  }
}

/**
 * A method that populates a [TempDir] asynchronously.
 */
typedef Future PopulateTempDir(TempDir dir);
