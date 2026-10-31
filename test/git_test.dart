import 'dart:io';

import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:test/scaffolding.dart';

import 'test_utils.dart';

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

  test('sets GIT_TERMINAL_PROMPT=0', () async {
    final pr = await runGit([
      '-c',
      r'alias.prompt=!echo $GIT_TERMINAL_PROMPT',
      'prompt',
    ]);
    check((pr.stdout as String).trim()).equals('0');
  });

  test(
    'preserves shell metacharacters and multi-line arguments on POSIX',
    () async {
      final gitDir = await createTempGitDir(branchName: 'main');
      const trickyMessage =
          'Subject with \$HOME `echo nope` \'single\' "double" * %(refname)\n\n'
          'Body line 2';
      await doDescriptorGitCommit(gitDir, const {
        'file.txt': 'hello',
      }, trickyMessage);

      final commit = await gitDir.commitFromRevision('HEAD');
      check(commit.message).equals(trickyMessage);

      final refsPr = await gitDir.runCommand(const [
        'for-each-ref',
        '--format=%(refname:short)',
        'refs/heads/',
      ]);
      check((refsPr.stdout as String).trim()).equals('main');
    },
    onPlatform: const {'windows': Skip('Windows uses cmd.exe via runInShell')},
  );
}
