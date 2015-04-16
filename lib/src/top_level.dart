library git.top_level;

import 'dart:async';
import 'dart:io';

import 'util.dart';

bool isValidSha(String value) => shaRegEx.hasMatch(value);

Future<ProcessResult> runGit(List<String> args,
    {bool throwOnError: true, String processWorkingDir}) async {
  var pr =
      await Process.run(gitBinName, args, workingDirectory: processWorkingDir);
  if (throwOnError) {
    _throwIfProcessFailed(pr, gitBinName, args);
  }
  return pr;
}

void _throwIfProcessFailed(
    ProcessResult pr, String process, List<String> args) {
  assert(pr != null);
  if (pr.exitCode != 0) {
    var message = '''
stdout:
${pr.stdout}
stderr:
${pr.stderr}''';

    throw new ProcessException(gitBinName, args, message, pr.exitCode);
  }
}
