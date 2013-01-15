part of hop_tasks;

Task createDart2JsTask(List<String> inputs, {String output: null,
  String packageRoot: null, bool minify: false, bool allowUnsafeEval: true,
  bool liveTypeAnalysis: false, rejectDeprecatedFeatures: false}) {
  return new Task.async((context) {
    final futureFuncs = inputs
        .mappedBy((p) => () => _dart2js(context, p,
            output: output,
            minify: minify,
            allowUnsafeEval: allowUnsafeEval,
            packageRoot: packageRoot,
            liveTypeAnalysis: liveTypeAnalysis,
            rejectDeprecatedFeatures: rejectDeprecatedFeatures))
        .toList();
    return _chainTasks(futureFuncs);
  }, 'Run Dart-to-Javascript compiler');
}

Future<bool> _dart2js(TaskContext ctx, String file, {String output: null,
  String packageRoot: null, bool minify: false, bool allowUnsafeEval: true,
  bool liveTypeAnalysis: false, rejectDeprecatedFeatures: false}) {

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

  if(liveTypeAnalysis) {
    args.add('--enable-native-live-type-analysis');
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

  return startProcess(ctx, 'dart2js', args);
}

Future<bool> _chainTasks(List<Func<Future<bool>>> futures, [int index=0]) {
  assert(index >= 0);
  assert(index <= futures.length);
  if(futures.length == 0) {
    throw new TaskFailError("No source files provided.");
  }
  if(index == futures.length) {
    return new Future.immediate(true);
  }
  final func = futures[index];
  final future = func();
  return future.then((bool status) {
    if(status) {
      return _chainTasks(futures, index+1);
    } else {
      return new Future.immediate(false);
    }
  });
}
