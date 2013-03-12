part of hop_tasks;

/**
 * [delayedRootList] a [List<String>] mapping to paths to libraries or some
 * combinations of [Future] or [Function] values that return a [List<String>].
 */
Task createDart2JsTask(dynamic delayedRootList, {String output: null,
  String packageRoot: null, bool minify: false, bool allowUnsafeEval: true,
  bool liveTypeAnalysis: true, bool rejectDeprecatedFeatures: false}) {

  return new Task.async((context) {
    bool errors = false;

    return getDelayedResult(delayedRootList)
        .then((List<String> inputs) {

          return Future.forEach(inputs, (path) {
            if(errors) {
              context.warning('Compile errors. Skipping $path');
              return new Future.immediate(null);
            }

            return _dart2js(context, path,
                output: output,
                minify: minify,
                allowUnsafeEval: allowUnsafeEval,
                packageRoot: packageRoot,
                liveTypeAnalysis: liveTypeAnalysis,
                rejectDeprecatedFeatures: rejectDeprecatedFeatures)
                .then((bool success) {
                  // should not have been run if we had pending errors
                  assert(errors == false);
                  errors = !success;
                });
          });
        })
        .then((_) {
          return !errors;
        });
  }, description: 'Run Dart-to-Javascript compiler');
}

Future<bool> _dart2js(TaskContext ctx, String file, {String output: null,
  String packageRoot: null, bool minify: false, bool allowUnsafeEval: true,
  bool liveTypeAnalysis: true, bool rejectDeprecatedFeatures: false}) {

  if(output == null) {
    output = "${file}.js";
  }

  final packageDir = new Directory('packages');
  assert(packageDir.existsSync());

  final args = ["--package-root=${packageDir.path}",
                '--throw-on-error',
                '-v',
                "--out=$output",
                file];

  if(liveTypeAnalysis == false) {
    args.add('--disable-native-live-type-analysis');
  }

  if(rejectDeprecatedFeatures) {
    args.add('--reject-deprecated-language-features');
  }

  if(minify) {
    args.add('--minify');
  }

  if(!allowUnsafeEval) {
    args.add('--disallow-unsafe-eval');
  }

  if(packageRoot != null) {
    args.add('--package-root=$packageRoot');
  }

  return startProcess(ctx, _getPlatformBin('dart2js'), args);
}
