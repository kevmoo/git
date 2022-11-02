import 'dart:async';
import 'dart:io';

import 'util.dart';

// ignore: prefer_interpolation_to_compose_strings
final _shaRegEx = RegExp('^' + shaRegexPattern + r'$');

bool isValidSha(String value) => _shaRegEx.hasMatch(value);

/// Run `git` with the provided [arguments].
///
/// If [echoOutput] is `true`, the output of the `git` command will be echoed.
/// Note: [echoOutput] `true` will also cause the returned [ProcessResult] to
/// have `null` values for [ProcessResult.stdout] and [ProcessResult.stderr].
Future<ProcessResult> runGit(
  List<String> arguments, {
  bool throwOnError = true,
  bool echoOutput = false,
  String? processWorkingDir,
}) async {
  final pr = await Process.start(
    'git',
    arguments,
    workingDirectory: processWorkingDir,
    runInShell: true,
    mode: echoOutput ? ProcessStartMode.inheritStdio : ProcessStartMode.normal,
  );

  final results = await Future.wait([
    pr.exitCode,
    if (!echoOutput) pr.stdout.transform(const SystemEncoding().decoder).join(),
    if (!echoOutput) pr.stderr.transform(const SystemEncoding().decoder).join(),
  ]);

  final result = ProcessResult(
    pr.pid,
    results[0] as int,
    echoOutput ? null : results[1] as String,
    echoOutput ? null : results[2] as String,
  );

  if (throwOnError) {
    _throwIfProcessFailed(result, 'git', arguments);
  }
  return result;
}

void _throwIfProcessFailed(
  ProcessResult pr,
  String process,
  List<String> args,
) {
  if (pr.exitCode != 0) {
    final values = {
      if (pr.stdout != null) 'Standard out': pr.stdout.toString().trim(),
      if (pr.stderr != null) 'Standard error': pr.stderr.toString().trim()
    }..removeWhere((k, v) => v.isEmpty);

    String message;
    if (values.isEmpty) {
      message = 'Unknown error';
    } else if (values.length == 1) {
      message = values.values.single;
    } else {
      message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
    }

    throw ProcessException(process, args, message, pr.exitCode);
  }
}
