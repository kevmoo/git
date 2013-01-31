part of hop_tasks;

// TODO: add post-build options to pretty-up the docs

Task getCompileDocsFunc(String targetBranch, String packageDir,
                        Func<Future<List<String>>> libGetter) {
  return new Task.async((ctx) => compileDocs(ctx, targetBranch, libGetter, packageDir),
      'Generate documentation for the provided libraries.');
}

Future<bool> compileDocs(TaskContext ctx, String targetBranch,
    Func<Future<List<String>>> libGetter, String packageDir) {

  final parser = _getDartDocParser();
  final parseResult = _helpfulParseArgs(ctx, parser, ctx.arguments);
  final bool allowDirty = parseResult['allow-dirty'];

  final tempDocsDirFuture = TempDir.create();
  final tempGitDirFuture = TempDir.create()
      .then((TempDir dir) => _doGitCheckout(ctx, '.', dir, targetBranch));
  final getLibsFuture = libGetter();
  final commitMessageFuture = _getCommitMessageFuture(ctx, allowDirty);

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

ArgParser _getDartDocParser() {
  final parser = new ArgParser();

  // TODO: put help in a const
  parser.addFlag('allow-dirty', abbr: 'd', help: 'Allow a dirty tree to run', defaultsTo: false);

  return parser;
}

Future<bool> _compileDocs(TaskContext ctx, TempDir gitDir, TempDir outputDir,
    String targetBranch, String commitMessage, List<String> libs, String packageDir) {

  return _ensureProperBranch(ctx, gitDir, outputDir, targetBranch)
      .then((_) => _dartDoc(ctx, outputDir, libs, packageDir))
      .then((bool dartDocSuccess) {
        if(!dartDocSuccess) {
          ctx.fail('The dartdoc process failed.');
        }

        // yeah, silly. ctx.fail should blow up. Should not get heer
        assert(dartDocSuccess);

        return _doCommitComplex(ctx, outputDir, gitDir, commitMessage);
      })
      .then((_) => _doPush(ctx, outputDir, gitDir, targetBranch))
      .then((_) {
        return true;
      }).whenComplete(() {
        gitDir.dispose();
        outputDir.dispose();
      });
}

Future<String> _getCommitMessageFuture(TaskContext ctx, bool allowDirty) {
  final gitDir = new GitDir('');

  return gitDir.isWorkingTreeClean()
      .then((bool isClean) {
        if(!isClean && !allowDirty) {
          ctx.fail('Working tree is dirty. Cannot generate docs.');
        }

        return gitDir.getCurrentBranch();
      })
      .then((BranchReference currentBranchRef) {

        final abbrevSha = currentBranchRef.sha.substring(0, 7);

        return "Docs generated for ${currentBranchRef.branchName} at ${abbrevSha}";
      });
}

Future<bool> _dartDoc(TaskContext ctx, TempDir outputDir, Collection<String> libs,
    String packageDir) {
  final args = ['--pkg', packageDir, '--omit-generation-time', '--out', outputDir.path, '--verbose'];

  args.addAll(libs);
  ctx.fine("Generating docs into: $outputDir");
  return startProcess(ctx, "dartdoc", args);
}

Future<String> _doGitCheckout(TaskContext ctx, String sourceGitPath,
    TempDir targetGitPath, String sourceGitBranch) {

  return _gitRemoteHasHead(sourceGitPath, 'refs/heads/$sourceGitBranch')
      .then((bool branchExists) => _doGitClone(ctx, sourceGitPath,
          targetGitPath, sourceGitBranch, branchExists))
      .then((obj) => targetGitPath);
}

Future _doGitClone(TaskContext ctx, String sourceGitPath,
    TempDir targetGitPath, String sourceGitBranch, bool doCheckout) {
  final args = ['clone', '--bare', '--shared', sourceGitPath, targetGitPath.path];
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

Future _ensureProperBranch(TaskContext ctx, TempDir gitDir, TempDir workTree,
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

Future _checkoutBare(TaskContext ctx, TempDir gitDir, TempDir workTree,
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

Future _doCommitComplex(TaskContext ctx, TempDir workTree, TempDir gitDir,
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

Future _doPush(TaskContext ctx, TempDir workTree, TempDir gitDir, String branchName) {
  final args = _getGitArgs(gitDir, workTree, ['push', 'origin', branchName]);
  return Process.run('git', args)
      .then((ProcessResult pr) {
        _throwIfProcessFailed(ctx, pr);
        return null;
      });
}

List<String> _getGitArgs(TempDir gitDir, TempDir workTree,
    Collection<String> rest) {
  final args = ['--git-dir=${gitDir.path}', '--work-tree=${workTree.path}'];
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
