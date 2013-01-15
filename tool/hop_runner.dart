library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:bot/hop_tasks.dart';
import '../test/harness_console.dart' as test_console;

void main() {
  _assertKnownPath();

  addSyncTask('hello', (ctx) {
    ctx.fine('Welcome to HOP!');
    return true;
  });

  addTask('test', createUnitTestTask(test_console.testCore));
  addTask('docs', getCompileDocsFunc('gh-pages', 'packages/', _getLibs));

  //
  // Dart2js
  //
  final paths = ['click', 'drag', 'fract', 'frames', 'nav', 'spin']
      .mappedBy((d) => "example/$d/${d}_demo.dart")
      .toList();
  paths.add('test/harness_browser.dart');

  addTask('dart2js', createDart2JsTask(paths,
      liveTypeAnalysis: true, rejectDeprecatedFeatures: true));

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
    if(file.endsWith('.dart')) {
      // DARTBUG: http://code.google.com/p/dart/issues/detail?id=7389
      // still an issue with hop_tasks.
      final forbidden = ['hop_tasks'].mappedBy((n) => '$n.dart');
      if(forbidden.every((f) => !file.endsWith(f))) {
        libs.add(file);
      }
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
