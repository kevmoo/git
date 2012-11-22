part of hop_tasks;

TaskDefinition getCompileDocsFunc(String targetBranch,
                             Func<Future<SequenceCollection<String>>> libGetter) {
  return (ctx) => compileDocs(ctx, targetBranch, libGetter);
}

Future<bool> compileDocs(TaskContext ctx, String targetBranch,
    Func<Future<SequenceCollection<String>>> libGetter) {

  final dir = new Directory('');
  final tempDocsDirFuture = dir.createTemp()
      .transform((Directory dir) => dir.path);
  final tempGitDirFuture = dir.createTemp()
      .chain((Directory dir) => _doGitCheckout(ctx, '.', dir.path, targetBranch));
  final getLibsFuture = libGetter();

  return Futures.wait([tempDocsDirFuture, getLibsFuture, tempGitDirFuture])
      .chain((values) {
        final outputDir = values[0];
        final libs = values[1];
        final gitDir = values[2];
        return _ensureProperBranch(ctx, gitDir, outputDir, targetBranch)
            .chain((obj) => _dartDoc(ctx, outputDir, libs))
            .chain((bool dartDocSuccess) {
              if(dartDocSuccess) {
                return _doCommitComplex(ctx, outputDir, gitDir);
              } else {
                throw 'boo! docs failed...clean up';
              }
            })
            .chain((obj) => _doPush(ctx, outputDir, gitDir, targetBranch))
            .chain((obj) => _deleteTempDirs([outputDir, gitDir]))
            .transform((obj) => true);
  });
}

Future _deleteTempDirs(Collection<String> dirPaths) {
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

Future<bool> _dartDoc(TaskContext ctx, String outputDir, Collection<String> libs) {
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
  final args = _getGitArgs(gitDir, workTree, ['rev-parse', '--abbrev-ref', 'HEAD']);

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
  final args = _getGitArgs(gitDir, workTree, ['checkout', '--orphan', desiredBranch]);
  return Process.run('git', args)
      .chain((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        final args = _getGitArgs(gitDir, workTree, ['rm', '-rf', '.']);
        return Process.run('git', args);
      })
      .transform((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
      });
}

Future _doCommitComplex(TaskContext ctx, String workTree, String gitDir) {
  final args = _getGitArgs(gitDir, workTree, ['add', '--all']);
  return Process.run('git', args)
      .chain((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);

        // TODO: need more info for commit message
        final args = _getGitArgs(gitDir, workTree, ['commit', '-m', 'new goodness', '.']);

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
  final args = _getGitArgs(gitDir, workTree, ['push', 'origin', branchName]);
  return Process.run('git', args)
      .transform((ProcessResult pr) {
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

Future<bool> _cleanUpTemp(String tempDir, bool dartDocSuccess) {
  final dir = new Directory(tempDir);
  return dir.delete(recursive: true)
      .transform((d) => dartDocSuccess);
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
