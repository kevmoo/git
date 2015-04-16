library git.top_level;

import 'dart:async';
import 'dart:io';

import 'package:which/which.dart';

import 'util.dart';

String _gitCache;

Future<String> _getGit() async {
  if (_gitCache == null) {
    _gitCache = await which(gitBinName);
  }
  return _gitCache;
}

bool isValidSha(String value) => shaRegEx.hasMatch(value);

Future<ProcessResult> runGit(List<String> args,
    {bool throwOnError: true, String processWorkingDir}) async {
  var git = await _getGit();

  var pr = await Process.run(git, args,
      workingDirectory: processWorkingDir, runInShell: true);

  if (throwOnError) {
    _throwIfProcessFailed(pr, git, args);
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
