part of hop_runner;

Future<bool> _compileDocs(TaskContext ctx) {
  final targetBranch = 'gh-pages';

  _assertKnownPath();
  final dir = new Directory('');
  final tempDocsDirFuture = dir.createTemp()
      .transform((Directory dir) => dir.path);
  final tempGitDirFuture = dir.createTemp()
      .chain((Directory dir) => _doGitCheckout(ctx, '.', dir.path, targetBranch));
  final getLibsFuture = _getLibs();

  return Futures.wait([tempDocsDirFuture, getLibsFuture, tempGitDirFuture])
      .chain((values) {
        final outputDir = values[0];
        final libs = values[1];
        final gitDir = values[2];
        return _ensureProperBranch(ctx, gitDir, outputDir, targetBranch)
            .chain((obj) => _dartDoc(ctx, outputDir, libs))
            .chain((bool dartDocSuccess) {
              if(dartDocSuccess) {
                return _doCommit(ctx, outputDir, gitDir);
              } else {
                throw 'boo! docs failed...clean up';
              }
            })
            .chain((obj) => _doPush(ctx, outputDir, gitDir, targetBranch))
            .chain((obj) => _deleteTempDirs([outputDir, gitDir]))
            .transform((obj) => true);
  });
}

Future _deleteTempDirs(List<String> dirPaths) {
  final tmpDirPrefix = 'temp_dir';
  final delDirs = dirPaths
      .map((p) => new Path(p));

  delDirs.forEach((Path p) {
    if(!p.segments().last.startsWith(tmpDirPrefix)) {
      throw 'not a safe temp path!';
    }
  });

  final delDirFutures = delDirs
      .map((Path p) => new Directory.fromPath(p))
      .map((dir) => dir.delete(recursive: true));

  return Futures.wait(new List.from(delDirFutures));
}

Future<bool> _dartDoc(TaskContext ctx, String outputDir, List<String> libs) {
  final args = ['--omit-generation-time', '--out', outputDir, '--verbose'];
  args.addAll(libs);
  ctx.fine("Generating docs into: $outputDir");
  return startProcess(ctx, "dartdoc", args);
}

Future<String> _doGitCheckout(TaskContext ctx, String sourceGitPath,
    String targetGitPath, String sourceGitBranch) {

  return _gitRemoteHasHead(sourceGitPath, 'refs/heads/$sourceGitBranch')
      .chain((bool branchExists) => _doGitClone(ctx, sourceGitPath,
          targetGitPath, sourceGitBranch, branchExists))
      .transform((obj) => targetGitPath);
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
      .transform((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        ctx.success("Created temp git repo at $targetGitPath");
      });
}

Future _ensureProperBranch(TaskContext ctx, String gitDir, String workTree,
                           String desiredBranch) {
  final args = _getGitArgs(gitDir, workTree);
  args.addAll(['rev-parse', '--abbrev-ref', 'HEAD']);

  return Process.run('git', args)
      .transform((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        return pr.stdout.trim();
      })
      .chain((String currentBranch) {
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
  final args = _getGitArgs(gitDir, workTree);
  args.addAll(['checkout', '--orphan', desiredBranch]);
  return Process.run('git', args)
      .chain((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        final args = _getGitArgs(gitDir, workTree);
        args.addAll(['rm', '-rf', '.']);
        return Process.run('git', args);
      })
      .transform((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
      });
}

Future _doCommit(TaskContext ctx, String workTree, String gitDir) {
  final args = _getGitArgs(gitDir, workTree);
  // TODO: need more info for commit message
  args.addAll(['add', '--all']);
  return Process.run('git', args)
      .chain((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        final args = _getGitArgs(gitDir, workTree);
        // TODO: need more info for commit message
        args.addAll(['commit', '-m', 'new goodness', '.']);

        return Process.run('git', args);
      })
      .transform((ProcessResult pr) {
        if(pr.exitCode == 1) {
          // could be okay if nothing to commit. should check
          if(pr.stdout.contains("nothing to commit, working directory clean")) {
            // all good
            ctx.success("Nothing seems to have changed");
            return null;
          }
        }
        _throwIfProcessFailed(ctx, pr);
        return null;
      });
}

Future _doPush(TaskContext ctx, String workTree, String gitDir, String branchName) {
  final args = _getGitArgs(gitDir, workTree);
  args.addAll(['push', 'origin', branchName]);
  return Process.run('git', args)
      .transform((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        return null;
      });
}

List<String> _getGitArgs(String gitDir, String workTree) =>
    ['--git-dir=$gitDir', '--work-tree=$workTree'];

Future<bool> _cleanUpTemp(String tempDir, bool dartDocSuccess) {
  final dir = new Directory(tempDir);
  return dir.delete(recursive: true)
      .transform((d) => dartDocSuccess);
}

Future<List<String>> _getLibs() {
  final completer = new Completer<List<String>>();

  final lister = new Directory('lib').list();
  final libs = new List<String>();

  lister.onFile = (String file) {
    if(file.endsWith('.dart')) {
      // DARTBUG: http://code.google.com/p/dart/issues/detail?id=5460
      // exclude libs because of issues with dartdoc and sdk libs
      // in this case: unittest and args
      final forbidden = ['test', 'hop', 'tasks'].map((n) => '$n.dart');
      if(forbidden.every((f) => !file.endsWith(f))) {
        libs.add(file);
      }
    }
  };

  lister.onDone = (bool done) {
    if(done) {
      completer.complete(libs);
    } else {
      completer.completeException('did not finish');
    }
  };

  lister.onError = (error) {
    completer.completeException(error);
  };

  return completer.future;
}

// See http://git-scm.com/docs/git-ls-remote
Future<bool> _gitRemoteHasHead(String remote, String head) {
  requireArgumentNotNull(remote, 'remote');
  requireArgumentNotNull(head, 'head');
  final args = ['ls-remote', '--exit-code', '--heads', remote, head];
  return Process.run('git', args)
      .transform((ProcessResult pr) {
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
    ctx.error('Process returned a non-zero exit code');
    ctx.fine(pr.stdout.trim());
    ctx.error(pr.stderr.trim());
    ctx.error('Exit code: ${pr.exitCode}');
    throw 'Task failed';
  }
}
