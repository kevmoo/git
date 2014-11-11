library hop_runner;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart' hide createUnitTestTask;
import 'package:hop_docgen/hop_docgen.dart';
import 'package:hop_unittest/hop_unittest.dart';

import '../test/harness_console.dart' as test_console;

void main(List<String> args) {
  addTask('test', createUnitTestTask(test_console.main));

  addTask('docs', createDocGenTask('../compiled_dartdoc_viewer'));

  addTask('analyze_libs', createAnalyzerTask(_getLibs));

  addTask('analyze_test_libs', createAnalyzerTask([
    'test/harness_console.dart'
  ]));

  runHop(args);
}

Future<List<String>> _getLibs() => new Directory('lib')
    .list()
    .where((FileSystemEntity fse) => fse is File)
    .map((File file) => file.path)
    .toList();
