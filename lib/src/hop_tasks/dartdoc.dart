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

  final currentWorkingDir = new Directory.current().path;

  GitDir gitDir;
  List<String> libs;

  return GitDir.fromExisting(currentWorkingDir)
      .then((GitDir value) {
        gitDir = value;

        return gitDir.isWorkingTreeClean();
      })
      .then((bool isClean) {
        if(!allowDirty && !isClean) {
          ctx.fail('Working tree is dirty. Cannot generate docs.');
        }

        return libGetter();
      })
      .then((List<String> value) {
        assert(value != null);
        libs = value;

        return _getCommitMessageFuture(gitDir);
      })
      .then((String commitMessage) {

        return gitDir.populateBranch(targetBranch,
            (TempDir td) => _doDocsPopulate(ctx, td, libs, packageDir),
            commitMessage);
      })
      .then((Commit value) {
        if(value == null) {
          ctx.info('No commit. Nothing changed.');
        } else {
          ctx.info('New commit created at branch $targetBranch');
          ctx.info('Message: ${value.message}');
        }

        return true;
      });
}

Future _doDocsPopulate(TaskContext ctx, TempDir dir, Collection<String> libs, String packageDir) {
  return _dartDoc(ctx, dir, libs, packageDir)
      .then((bool dartDocSuccess) {
        if(!dartDocSuccess) {
          ctx.fail('The dartdoc process failed.');
        }

        // yeah, silly. ctx.fail should blow up. Should not get heer
        assert(dartDocSuccess);
      });
}

ArgParser _getDartDocParser() {
  final parser = new ArgParser();

  // TODO: put help in a const
  parser.addFlag('allow-dirty', abbr: 'd', help: 'Allow a dirty tree to run', defaultsTo: false);

  return parser;
}

Future<String> _getCommitMessageFuture(GitDir gitDir) {
  return gitDir.getCurrentBranch()
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

  final sublogger = ctx.getSubLogger('dartdoc');

  return startProcess(sublogger, "dartdoc", args);
}
