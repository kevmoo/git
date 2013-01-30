part of bot_git;

class Git {
  static final RegExp _lsRemoteRegExp = new RegExp(r'^([a-f0-9]{40})\s(.+)$');

  static List<Tuple<String, String>> parseLsRemoteOutput(String input) {
    assert(input != null);
    final lines = Util.splitLines(input);

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.getRange(0, lines.length-1)
        .mappedBy((line) {
          final match = _lsRemoteRegExp.allMatches(line).single;
          assert(match.groupCount == 2);

          return new Tuple<String, String>(match[1], match[2]);

        }).toList();
  }

  static Future<ProcessResult> runGit(List<String> args,
      {bool throwOnError: true, String processWorkingDir}) {

    final processOptions = new ProcessOptions();
    if(processWorkingDir != null) {
      processOptions.workingDirectory = processWorkingDir;
    }

    return Process.run('git', args, processOptions)
        .then((ProcessResult pr) {
          if(throwOnError) {
            _throwIfProcessFailed(pr, 'git', args);
          }
          return pr;
        });
  }

  static void _throwIfProcessFailed(ProcessResult pr, String process, List<String> args) {
    assert(pr != null);
    if(pr.exitCode != 0) {
      throw new ProcessException('git', ['unknown'], pr.stderr.trim(), pr.exitCode);
    }
  }
}
