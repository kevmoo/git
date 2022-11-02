import 'dart:io';

import 'package:git/git.dart';
import 'package:test/test.dart';

void main() {
  test('bad git command', () async {
    await expectLater(
      runGit(['not-a-command']),
      throwsA(
        isA<ProcessException>()
            .having(
              (pe) => pe.message,
              'message',
              contains("'not-a-command' is not a git command."),
            )
            .having((pe) => pe.errorCode, 'errorCode', 1),
      ),
    );
  });

  test('bad git command - echoOutput true', () async {
    await expectLater(
      runGit(['not-a-command'], echoOutput: true),
      throwsA(
        isA<ProcessException>()
            .having(
              (pe) => pe.message,
              'message',
              'Unknown error',
            )
            .having((pe) => pe.errorCode, 'errorCode', 1),
      ),
    );
  });
}
