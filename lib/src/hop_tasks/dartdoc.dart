part of hop_tasks;

// TODO: add post-build options to pretty-up the docs

Task getCompileDocsFunc(String targetBranch, String packageDir,
                        Func<Future<List<String>>> libGetter) {
  return new Task.async((ctx) => compileDocs(ctx, targetBranch, libGetter, packageDir),
      'Generate documentation for the provided libraries.');
}

Future<bool> compileDocs(TaskContext ctx, String targetBranch,
    Func<Future<List<String>>> libGetter, String packageDir) {

  final dir = new Directory('');
  final tempDocsDirFuture = dir.createTemp()
      .then((Directory dir) => dir.path);
  final tempGitDirFuture = dir.createTemp()
      .then((Directory dir) => _doGitCheckout(ctx, '.', dir.path, targetBranch));
  final getLibsFuture = libGetter();
  final commitMessageFuture = _getCommitMessageFuture(ctx);

  return Future.wait([tempDocsDirFuture, getLibsFuture, tempGitDirFuture,
                       commitMessageFuture])
      .then((values) {
        final outputDir = values[0];
        final libs = values[1];
        final gitDir = values[2];
        final commitMessage = values[3];
        return _compileDocs(ctx, gitDir, outputDir, targetBranch, commitMessage,
            libs, packageDir);
      });
}

Future<bool> _compileDocs(TaskContext ctx, String gitDir, String outputDir,
    String targetBranch, String commitMessage, List<String> libs, String packageDir) {

  return _ensureProperBranch(ctx, gitDir, outputDir, targetBranch)
      .then((_) => _dartDoc(ctx, outputDir, libs, packageDir))
      .then((bool dartDocSuccess) {
        if(dartDocSuccess) {
          return _doCommitComplex(ctx, outputDir, gitDir, commitMessage);
        } else {
          throw 'boo! docs failed...clean up';
        }
      })
      .then((_) => _doPush(ctx, outputDir, gitDir, targetBranch))
      .then((_) => _deleteTempDirs([outputDir, gitDir]))
      .then((_) => true);
}

Future<String> _getCommitMessageFuture(TaskContext ctx) {
  return _verifyCurrentWorkingTreeClean(ctx)
      .then((_) => _getCurrentBranchName(ctx))
      .then((String refName) => _getCommitMessageFromRefName(ctx, refName));
}

Future<String> _getCommitMessageFromRefName(TaskContext ctx, String refName) {
  return Process.run('git', ['show-ref', '--abbrev', refName])
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        var split = new List<String>.from(
            pr.stdout.split(' ').mappedBy((e) => e.trim()));
        assert(split.length == 2);
        assert(split[1] == refName);

        final sha = split[0];

        return "Docs generated for $refName at $sha";
      });
}

Future _verifyCurrentWorkingTreeClean(TaskContext ctx) {
  return Process.run('git', ['status', '--porcelain'])
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        if(pr.stdout.length > 0) {
          ctx.fail('Working tree is dirty. Cannot generate docs.');
        }

        // not really needed, but nice
        return null;
      });
}

Future<String> _getCurrentBranchName(TaskContext ctx) {
  return Process.run('git', ['rev-parse', '--verify',
                                   '--symbolic-full-name', 'HEAD'])
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);

        final refParseRegEx = new RegExp(r'^refs\/heads\/(.+)$', multiLine: true);
        final match = refParseRegEx.firstMatch(pr.stdout.trim());

        if(match == null) {
          throw 'Could not determine current branch: ${pr.stdout}';
        }

        assert(match.groupCount == 1);

        final branchName = match[0];
        return branchName;
      });
}

Future _deleteTempDirs(Collection<String> dirPaths) {
  final tmpDirPrefix = 'temp_dir';
  final delDirs = dirPaths
      .mappedBy((p) => new Path(p));

  delDirs.forEach((Path p) {
    if(!p.segments().last.startsWith(tmpDirPrefix)) {
      throw 'not a safe temp path!';
    }
  });

  final delDirFutures = delDirs
      .mappedBy((Path p) => new Directory.fromPath(p))
      .mappedBy((dir) => dir.delete(recursive: true));

  return Future.wait(new List.from(delDirFutures));
}

Future<bool> _dartDoc(TaskContext ctx, String outputDir, Collection<String> libs,
    String packageDir) {
  final args = ['--pkg', packageDir, '--omit-generation-time', '--out', outputDir, '--verbose'];

  args.addAll(libs);
  ctx.fine("Generating docs into: $outputDir");
  return startProcess(ctx, "dartdoc", args);
}

Future<String> _doGitCheckout(TaskContext ctx, String sourceGitPath,
    String targetGitPath, String sourceGitBranch) {

  return _gitRemoteHasHead(sourceGitPath, 'refs/heads/$sourceGitBranch')
      .then((bool branchExists) => _doGitClone(ctx, sourceGitPath,
          targetGitPath, sourceGitBranch, branchExists))
      .then((obj) => targetGitPath);
}

Future _doGitClone(TaskContext ctx, String sourceGitPath,
    String targetGitPath, String sourceGitBranch, bool doCheckout) {
  final args = ['clone', '--bare', '--shared', sourceGitPath, targetGitPath];
  if(doCheckout) {
    args.addAll(['--single-branch', '--branch', sourceGitBranch]);
  } else {
    args.addAll(['--no-checkout']);
  }
  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        ctx.info("Created temp git repo at $targetGitPath");
      });
}

Future _ensureProperBranch(TaskContext ctx, String gitDir, String workTree,
                           String desiredBranch) {
  final args = _getGitArgs(gitDir, workTree, ['rev-parse', '--abbrev-ref', 'HEAD']);

  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        return pr.stdout.trim();
      })
      .then((String currentBranch) {
        if(currentBranch == desiredBranch) {
          // we have the right branch, cool
          return new Future.immediate(null);
        } else {
          // do the actual checkout
          return _checkoutBare(ctx, gitDir, workTree, desiredBranch);
        }
      });
}

Future _checkoutBare(TaskContext ctx, String gitDir, String workTree,
                     String desiredBranch) {
  final args = _getGitArgs(gitDir, workTree, ['checkout', '--orphan', desiredBranch]);
  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        final args = _getGitArgs(gitDir, workTree, ['rm', '-rf', '.']);
        return Process.run('git', args);
      })
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
      });
}

Future _doCommitComplex(TaskContext ctx, String workTree, String gitDir,
                        String commitMessage) {
  requireArgumentNotNullOrEmpty(commitMessage, 'commitMessage');

  final args = _getGitArgs(gitDir, workTree, ['add', '--all']);
  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);

        // TODO: need more info for commit message
        final args = _getGitArgs(gitDir, workTree,
            ['commit', '-m', commitMessage, '.']);

        return Process.run('git', args);
      })
      .then((ProcessResult pr) {
        if(pr.exitCode == 1) {
          // could be okay if nothing to commit. should check
          if(pr.stdout.contains("nothing to commit, working directory clean")) {
            // all good
            ctx.info("Nothing seems to have changed");
            return null;
          }
        }
        _throwIfProcessFailed(ctx, pr);
        return null;
      });
}

Future _doPush(TaskContext ctx, String workTree, String gitDir, String branchName) {
  final args = _getGitArgs(gitDir, workTree, ['push', 'origin', branchName]);
  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        return null;
      });
}

List<String> _getGitArgs(String gitDir, String workTree,
    Collection<String> rest) {
  final args = ['--git-dir=$gitDir', '--work-tree=$workTree'];
  args.addAll(rest);
  return args;
}

// See http://git-scm.com/docs/git-ls-remote
Future<bool> _gitRemoteHasHead(String remote, String head) {
  requireArgumentNotNull(remote, 'remote');
  requireArgumentNotNull(head, 'head');
  final args = ['ls-remote', '--exit-code', '--heads', remote, head];
  return Process.run('git', args)
      .then((ProcessResult pr) {
        if(pr.exitCode == 0) {
          return true;
        } else if(pr.exitCode == 2) {
          // per --exit-code, this implies head does not exist
          return false;
        } else {
          throw "git command error. Exit code: ${pr.exitCode}, Error: ${pr.stderr}";
        }
      });
}

void _throwIfProcessFailed(TaskContext ctx, ProcessResult pr) {
  assert(pr != null);
  if(pr.exitCode != 0) {
    ctx.severe('Process returned a non-zero exit code');
    ctx.fine(pr.stdout.trim());
    ctx.severe(pr.stderr.trim());
    ctx.severe('Exit code: ${pr.exitCode}');
    throw 'Task failed';
  }
}
