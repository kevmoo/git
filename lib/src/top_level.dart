library git.top_level;

import 'dart:async';
import 'dart:io';

import 'util.dart';

bool isValidSha(String value) {
  return shaRegEx.hasMatch(value);
}

Future<ProcessResult> runGit(List<String> args,
    {bool throwOnError: true, String processWorkingDir}) {

  return Process.run('git', args, workingDirectory: processWorkingDir)
      .then((ProcessResult pr) {
        if(throwOnError) {
          _throwIfProcessFailed(pr, 'git', args);
        }
        return pr;
      });
}

void _throwIfProcessFailed(ProcessResult pr, String process, List<String> args) {
  assert(pr != null);
  if(pr.exitCode != 0) {

    final message =
'''

stdout:
${pr.stdout}
stderr:
${pr.stderr}''';

    throw new ProcessException('git', args, message, pr.exitCode);
  }
}
