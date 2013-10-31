library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import '../test/harness_console.dart' as test_console;

import 'package:hop/src/hop_tasks_experimental.dart' as dartdoc;

void main(List<String> args) {
  // Easy to enable hop-wide logging
  // enableScriptLogListener();

  addTask('test', createUnitTestTask(test_console.testCore));

  addTask('docs', createDartDocTask(_getLibs, linkApi: true, postBuild: dartdoc.createPostBuild(_cfg)));

  //
  // Analyzer
  //
  addTask('analyze_libs', createAnalyzerTask(_getLibs));

  addTask('analyze_test_libs', createAnalyzerTask(
      ['test/harness_console.dart']));

  runHop(args);
}

Future<List<String>> _getLibs() {
  return new Directory('lib').list()
      .where((FileSystemEntity fse) => fse is File)
      .map((File file) => file.path)
      .toList();
}

const _libs = const ['bot_io', 'bot_git'];

final _cfg = new dartdoc.DocsConfig('bot_io', 'https://github.com/kevmoo/bot_io.dart',
    'logo.png', 333, 250, _libs.contains);
