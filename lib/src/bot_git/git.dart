part of bot_git;

class Git {
  static Future<ProcessResult> runGit(List<String> args, [bool throwOnError = true]) {
    return Process.run('git', args)
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
