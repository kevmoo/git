library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/hop.dart';
import 'package:bot/hop_tasks.dart';
import '../test/harness_console.dart' as test_console;

import 'tasks/update_example_html.dart' as html_tasks;

void main() {
  // Easy to enable hop-wide logging
  // enableScriptLogListener();
  _assertKnownPath();

  addTask('test', createUnitTestTask(test_console.testCore));

  addTask('docs', getCompileDocsFunc('gh-pages', 'packages/', _getLibs,
      linkApi: true));

  //
  // Analyzer
  //
  addTask('analyze_libs', createDartAnalyzerTask(_getLibs));

  addTask('analyze_test_libs', createDartAnalyzerTask(['test/harness_browser.dart',
                                                       'test/test_console.dart',
                                                       'test/harness_console.dart',
                                                       'test/test_dump_render_tree.dart',
                                                       'test/test_browser.dart',
                                                       'test/test_shared.dart']));

  //
  // Dart2js
  //
  final paths = ['click', 'drag', 'fract', 'frames', 'nav', 'spin']
      .map((d) => "example/bot_retained/$d/${d}_demo.dart")
      .toList();
  paths.add('test/harness_browser.dart');

  addTask('dart2js', createDart2JsTask(paths,
      liveTypeAnalysis: true, rejectDeprecatedFeatures: true));

  addTask('bench', createBenchTask());

  addTask('help', getHelpTask());

  addTask('update-html', html_tasks.getUpdateExampleHtmlTask());

  runHopCore();
}

void _assertKnownPath() {
  // since there is no way to determine the path of 'this' file
  // assume that Directory.current() is the root of the project.
  // So check for existance of /bin/hop_runner.dart
  final thisFile = new File('tool/hop_runner.dart');
  assert(thisFile.existsSync());
}

Future<List<String>> _getLibs() {
  final completer = new Completer<List<String>>();

  final lister = new Directory('lib').list();
  final libs = new List<String>();

  lister.onFile = (String file) {
    // DARTBUG: http://code.google.com/p/dart/issues/detail?id=8335
    // excluding html_enhanced_config
    final forbidden = ['html_enhanced_config'].map((n) => '$n.dart');
    if(file.endsWith('.dart') && forbidden.every((f) => !file.endsWith(f))) {
      libs.add(file);
    }
  };

  lister.onDone = (bool done) {
    if(done) {
      completer.complete(libs);
    } else {
      completer.completeError('did not finish');
    }
  };

  lister.onError = (error) {
    completer.completeError(error);
  };

  return completer.future;
}
