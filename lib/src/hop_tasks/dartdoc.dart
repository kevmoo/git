part of hop_tasks;

// TODO: add post-build options to pretty-up the docs

const _allowDirtyArg = 'allow-dirty';

/**
 * [delayedLibraryList] a [List<String>] mapping to paths to libraries or some
 * combinations of [Future] or [Function] values that return a [List<String>].
 */
Task getCompileDocsFunc(String targetBranch, String packageDir,
                        dynamic delayedLibraryList,
                        {Iterable<String> excludeLibs, bool linkApi: false}) {
  return new Task.async((ctx) => compileDocs(ctx, targetBranch, delayedLibraryList,
      packageDir, excludeLibs: excludeLibs, linkApi: linkApi),
      description: 'Generate documentation for the provided libraries.',
      config: _dartDocParserConfig);
}

/**
 * [delayedLibraryList] a [List<String>] mapping to paths to libraries or some
 * combinations of [Future] or [Function] values that return a [List<String>].
 */
Future<bool> compileDocs(TaskContext ctx, String targetBranch,
    dynamic delayedLibraryList, String packageDir,
    {Iterable<String> excludeLibs, bool linkApi: false}) {

  final excludeList = excludeLibs == null ? [] : excludeLibs.toList();

  final parseResult = ctx.arguments;
  final bool allowDirty = parseResult[_allowDirtyArg];

  final currentWorkingDir = new Directory.current().path;

  GitDir gitDir;
  List<String> libs;
  bool isClean;

  return GitDir.fromExisting(currentWorkingDir)
      .then((GitDir value) {
        gitDir = value;

        return gitDir.isWorkingTreeClean();
      })
      .then((bool value) {
        isClean = value;
        if(!allowDirty && !isClean) {
          ctx.fail('Working tree is dirty. Cannot generate docs.');
        }

        return getDelayedResult(delayedLibraryList);
      })
      .then((List<String> value) {
        assert(value != null);
        libs = value;

        return _getCommitMessageFuture(gitDir, isClean);
      })
      .then((String commitMessage) {

        return gitDir.populateBranch(targetBranch,
            (TempDir td) => _doDocsPopulate(ctx, td, libs, packageDir, excludeList, linkApi),
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

void _dartDocParserConfig(ArgParser parser) {
  parser.addFlag(_allowDirtyArg, abbr: 'd', help: 'Allow a dirty tree to run', defaultsTo: false);
}

Future<String> _getCommitMessageFuture(GitDir gitDir, bool isClean) {
  return gitDir.getCurrentBranch()
    .then((BranchReference currentBranchRef) {

      final abbrevSha = currentBranchRef.sha.substring(0, 7);

      var msg = "Docs generated for ${currentBranchRef.branchName} at ${abbrevSha}";

      if(!isClean) {
        msg = msg.concat(' (dirty)');
      }

      return msg;
    });
}

Future _doDocsPopulate(TaskContext ctx, TempDir dir, Collection<String> libs,
                       String packageDir, List<String> excludeList, bool linkApi) {
  final args = ['--pkg', packageDir, '--omit-generation-time', '--out', dir.path, '--verbose'];

  if(linkApi) {
    args.add('--link-api');
  }

  if(!excludeList.isEmpty) {
    args.add('--exclude-lib');
    args.add(excludeList.join(','));
  }

  args.addAll(libs);
  ctx.fine("Generating docs into: $dir");

  final sublogger = ctx.getSubLogger('dartdoc');

  return startProcess(sublogger, "dartdoc", args)
      .then((bool dartDocSuccess) {
        if(!dartDocSuccess) {
          ctx.fail('The dartdoc process failed.');
        }

        // yeah, silly. ctx.fail should blow up. Should not get heer
        assert(dartDocSuccess);
      });
}
