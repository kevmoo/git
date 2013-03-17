part of hop_tasks;

const _allowDirtyArg = 'allow-dirty';
const _targetBranchArg = 'target-branch';

/**
 * [targetBranch] the Git branch that will contain the generated docs. If the
 * branch doesn't exist, it will be created. Default: `gh-pages`
 *
 * [packageDir] the package directory for the current project. Default: `packages/`
 *
 * [delayedLibraryList] a [List<String>] mapping to paths to libraries or some
 * combinations of [Future] or [Function] values that return a [List<String>].
 *
 * [postBuild] A [Function] to call before content is committed. It has the
 * signature `Future postBuild(TaskLogger logger, String tempDocPath)`. Use this
 * if you want to modify the doc output.
 */
Task createDartDocTask(dynamic delayedLibraryList, {
  String targetBranch: 'gh-pages',
  String packageDir: 'packages/',
  Iterable<String> excludeLibs,
  bool linkApi: false,
  Func2<TaskContext, String, Future> postBuild
  }) {
  requireArgumentNotNull(targetBranch, 'targetBranch');
  requireArgumentNotNull(packageDir, 'packageDir');

  return new Task.async((ctx) {
    targetBranch = ctx.arguments[_targetBranchArg];

    return _compileDocs(ctx, targetBranch, delayedLibraryList, packageDir,
        excludeLibs, linkApi, postBuild);
  },
  description: 'Generate documentation for the provided libraries.',
  config: (parser) => _dartDocParserConfig(parser, targetBranch));
}

/**
 * This method is deprecated. Use [createDartDocTask] instead.
 */
@deprecated
Task getCompileDocsFunc(String targetBranch, String packageDir,
                        dynamic delayedLibraryList,
                        {Iterable<String> excludeLibs, bool linkApi: false}) {
  return createDartDocTask(delayedLibraryList,
      targetBranch: targetBranch,
      packageDir: packageDir,
      excludeLibs:excludeLibs,
      linkApi:linkApi);
}

/**
 * This method is deprecated. Use [createDartDocTask] instead.
 */
@deprecated
Future<bool> compileDocs(TaskContext ctx, String targetBranch,
    dynamic delayedLibraryList, String packageDir,
    {Iterable<String> excludeLibs, bool linkApi: false}) {
  return _compileDocs(ctx, targetBranch, delayedLibraryList, packageDir,
      excludeLibs, linkApi, null);
}

Future<bool> _compileDocs(TaskContext ctx, String targetBranch,
    dynamic delayedLibraryList, String packageDir,
    Iterable<String> excludeLibs, bool linkApi, Func2<TaskContext, String, Future> postBuild) {

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
          ctx.fail('Working tree is dirty. Cannot generate docs.\n'
              'Try using the --${_allowDirtyArg} flag.');
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
            (TempDir td) => _doDocsPopulate(ctx, td, libs, packageDir, excludeList, linkApi, postBuild),
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

void _dartDocParserConfig(ArgParser parser, String targetBranch) {
  parser.addFlag(_allowDirtyArg, abbr: 'd', help: 'Allow a dirty tree to run', defaultsTo: false);
  parser.addOption(_targetBranchArg, abbr: 'b', help: 'The git branch which gets the doc output', defaultsTo: targetBranch);
}

Future<String> _getCommitMessageFuture(GitDir gitDir, bool isClean) {
  return gitDir.getCurrentBranch()
    .then((BranchReference currentBranchRef) {

      final abbrevSha = currentBranchRef.sha.substring(0, 7);

      var msg = "Docs generated for ${currentBranchRef.branchName} at ${abbrevSha}";

      if(!isClean) {
        msg = msg + ' (dirty)';
      }

      return msg;
    });
}

Future _doDocsPopulate(TaskContext ctx, TempDir dir, Collection<String> libs,
                       String packageDir, List<String> excludeList,
                       bool linkApi, Func2<TaskContext, String, Future> postBuild) {
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

  return startProcess(sublogger, _getPlatformBin('dartdoc'), args)
      .then((bool dartDocSuccess) {
        if(!dartDocSuccess) {
          ctx.fail('The dartdoc process failed.');
        }

        // yeah, silly. ctx.fail should blow up. Should not get heer
        assert(dartDocSuccess);

        if(postBuild != null) {
          // TODO: this should be platfrom specific...pathos?
          return postBuild(ctx.getSubLogger('post-build'), dir.path);
        }
      });
}
