library hop_runner;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:bot/tasks.dart';
import '../test/harness_console.dart' as test_console;

part 'dartdoc.dart';

void main() {
  _assertKnownPath();

  addAsyncTask('test', createUnitTestTask(test_console.testCore));
  addAsyncTask('docs', _compileDocs);

  //
  // Dart2js
  //
  final paths = $(['click', 'drag', 'fract', 'spin'])
      .map((d) => "example/$d/${d}_demo.dart")
      .toList();
  paths.add('test/harness_browser.dart');

  addAsyncTask('dart2js', createDart2JsTask(paths));

  addTask('about', _about);
  runHopCore();
}

void _assertKnownPath() {
  // since there is no way to determine the path of 'this' file
  // assume that Directory.current() is the root of the project.
  // So check for existance of /bin/hop_runner.dart
  final thisFile = new File('tool/hop_runner.dart');
  assert(thisFile.existsSync());
}

bool _about(TaskContext context) {
  context.fine('Welcome to HOP!');
  return true;
}
