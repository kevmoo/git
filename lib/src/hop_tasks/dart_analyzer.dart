part of hop_tasks;

// TODO(adam): document methods and class
// TODO(adam?): optional out directory param. Used so that repeat runs
//              are faster

const _verboseArgName = 'verbose';
const _enableTypeChecksArgName = 'enable-type-checks';
const _formatMachineArgName = 'format-machine';

/**
 * [delayedFileList] a [List<String>] mapping to paths to dart files or some
 * combinations of [Future] or [Function] values that return a [List<String>].
 */
Task createDartAnalyzerTask(dynamic delayedFileList) {
  return new Task.async((context) {
    final parseResult = context.arguments;

    final bool enableTypeChecks = parseResult[_enableTypeChecksArgName];
    final bool verbose = parseResult[_verboseArgName];
    final bool formatMachine = parseResult[_formatMachineArgName];

    return getDelayedResult(delayedFileList)
        .then((List<String> files) {
          final fileList = files.map((f) => new Path(f)).toList();
          return _processAnalyzerFile(context, fileList, enableTypeChecks,
              verbose, formatMachine);
        });
  },
  description: 'Run "dart_analyzer" for the provided dart files.',
  config: _analyzerParserConfig);
}

void _analyzerParserConfig(ArgParser parser) {
  parser
    ..addFlag(_enableTypeChecksArgName, abbr: 't', defaultsTo: false,
        help: 'Generate runtime type checks')
    ..addFlag(_verboseArgName, abbr: 'v', defaultsTo: false,
        help: 'verbose output of all errors')
    ..addFlag(_formatMachineArgName, abbr: 'm', defaultsTo: false,
        help: 'Print errors in a format suitable for parsing');
}

Future<bool> _processAnalyzerFile(TaskContext context, List<Path> analyzerFilePaths,
    bool enableTypeChecks, bool verbose, bool formatMachine) {

  int errorsCount = 0;
  int passedCount = 0;
  int warningCount = 0;

  return Future.forEach(analyzerFilePaths, (Path path) {
    final logger = context.getSubLogger(path.toString());
    return _analyzer(logger, path, enableTypeChecks, verbose, formatMachine)
        .then((int exitCode) {

          String prefix;

          switch(exitCode) {
            case 0:
              prefix = "PASSED";
              passedCount++;
              break;
            case 1:
              prefix = "WARNING";
              warningCount++;
              break;
            case 2:
              prefix =  "ERROR";
              errorsCount++;
              break;
            default:
              prefix = "Unknown exit code $exitCode";
              errorsCount++;
              break;
          }

          context.info("$prefix - $path");
        });
    })
    .then((_) {
      context.info("PASSED: ${passedCount}, WARNING: ${warningCount}, ERROR: ${errorsCount}");
      return errorsCount == 0;
    });
}

Future<int> _analyzer(TaskLogger logger, Path filePath, bool enableTypeChecks,
    bool verbose, bool formatMachine) {
  TempDir tmpDir;

  return TempDir.create()
      .then((TempDir td) {
        tmpDir = td;

        var processArgs = ['--extended-exit-code', '--work', tmpDir.dir.path];

        if (enableTypeChecks) {
          processArgs.add('--enable_type_checks');
        }

        if(formatMachine) {
          processArgs.add('--machine');
        }

        processArgs.addAll([filePath.toNativePath()]);

        return Process.start(_getPlatformBin('dart_analyzer'), processArgs);
      })
      .then((process) {
        if(verbose) {
          return pipeProcess(process,
              stdOutWriter: logger.fine,
              stdErrWriter: logger.severe);
        } else {
          return pipeProcess(process);
        }
      })
      .whenComplete(() {
        if(tmpDir != null) {
          tmpDir.dispose();
        }
      });
}
