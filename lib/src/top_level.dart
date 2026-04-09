import 'dart:async';
import 'dart:io';

import 'util.dart';

final _shaRegEx = RegExp('^$shaRegexPattern\$');

/// Returns `true` if [value] represents a valid SHA1 [String].
bool isValidSha(String value) => _shaRegEx.hasMatch(value);

/// Run `git` with the provided [arguments].
///
/// If [echoOutput] is `true`, the output of the `git` command will be echoed.
/// Note: [echoOutput] `true` will also cause the returned [ProcessResult] to
/// have `null` values for [ProcessResult.stdout] and [ProcessResult.stderr].
///
/// Use [processWorkingDir] to set the working directory for the created Git
/// process. If omitted or `null`, the default ([Directory.current]) is used.
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

  final stdoutFuture = echoOutput
      ? Future<String?>.value()
      : pr.stdout.transform(const SystemEncoding().decoder).join();
  final stderrFuture = echoOutput
      ? Future<String?>.value()
      : pr.stderr.transform(const SystemEncoding().decoder).join();

  final result = ProcessResult(
    pr.pid,
    await pr.exitCode,
    await stdoutFuture,
    await stderrFuture,
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
    final stdout = pr.stdout?.toString().trim() ?? '';
    final stderr = pr.stderr?.toString().trim() ?? '';

    final values = {
      if (stdout.isNotEmpty) 'Standard out': stdout,
      if (stderr.isNotEmpty) 'Standard error': stderr,
    };

    final message = switch (values.length) {
      0 => 'Unknown error',
      1 => values.values.single,
      _ => values.entries.map((e) => '${e.key}\n${e.value}').join('\n'),
    };

    throw ProcessException(process, args, message, pr.exitCode);
  }
}
