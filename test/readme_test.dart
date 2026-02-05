import 'dart:io';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('readme example contents', () {
    final readmeContent = File('README.md').readAsStringSync();
    final exampleContent = File('example/example.dart').readAsStringSync();

    check(readmeContent).contains(exampleContent);
  });
}
