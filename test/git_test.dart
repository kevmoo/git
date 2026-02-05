import 'dart:io';

import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('bad git command', () async {
    await check(runGit(['not-a-command'])).throws<ProcessException>(
      (it) => it
        ..has(
          (pe) => pe.message,
          'message',
        ).contains("'not-a-command' is not a git command.")
        ..has((pe) => pe.errorCode, 'errorCode').equals(1),
    );
  });

  test('bad git command - echoOutput true', () async {
    await check(
      runGit(['not-a-command'], echoOutput: true),
    ).throws<ProcessException>(
      (it) => it
        ..has((pe) => pe.message, 'message').contains('Unknown error')
        ..has((pe) => pe.errorCode, 'errorCode').equals(1),
    );
  });
}
