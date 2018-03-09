import 'dart:async';
import 'dart:io';

import 'util.dart';

final _shaRegEx = new RegExp(r'^' + shaRegexPattern + r'$');

bool isValidSha(String value) => _shaRegEx.hasMatch(value);

Future<ProcessResult> runGit(List<String> args,
    {bool throwOnError: true, String processWorkingDir}) async {
  var pr = await Process.run('git', args,
      workingDirectory: processWorkingDir, runInShell: true);

  if (throwOnError) {
    _throwIfProcessFailed(pr, 'git', args);
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

    throw new ProcessException(process, args, message, pr.exitCode);
  }
}
