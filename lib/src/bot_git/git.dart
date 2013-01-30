part of bot_git;

class Git {
  static const _shaRegexPattern = '[a-f0-9]{40}';
  static final _shaRegEx = new RegExp(r'^'.concat(_shaRegexPattern).concat(r'$'));

  static final RegExp _lsRemoteRegExp = new RegExp('^($_shaRegexPattern)\t(.+)\$');

  static bool isValidSha(String value) {
    return _shaRegEx.hasMatch(value);
  }

  static List<GitReference> parseLsRemoteOutput(String input) {
    assert(input != null);
    final lines = Util.splitLines(input);

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.getRange(0, lines.length-1)
        .mappedBy((line) {
          final match = _lsRemoteRegExp.allMatches(line).single;
          assert(match.groupCount == 2);

          return new GitReference(match[1], match[2]);

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

      final message =
'''stdout:
${pr.stdout}

stderr:
${pr.stderr}''';

      throw new ProcessException('git', args, message, pr.exitCode);
    }
  }
}

/**
 * Represents the output from `git ls-remote`
 */
class GitReference {
  final String sha;
  final String reference;

  GitReference(this.sha, this.reference) {
    assert(Git.isValidSha(sha));

    assert(reference != null);
    // TODO: probably a better way to verify...but this is fine for now
    assert(reference.startsWith(r'refs/') || reference == 'HEAD');
  }

  BranchReference toBranchReference() =>
      new BranchReference(this.sha, this.reference);
}

class BranchReference extends GitReference {
  static const _localBranchPrefix = r'refs/heads/';

  final String branchName;

  factory BranchReference(String sha, String reference) {
    assert(reference.startsWith(_localBranchPrefix));

    final branchName = reference.substring(_localBranchPrefix.length);

    return new BranchReference._internal(sha, reference, branchName);
  }

  BranchReference._internal(String sha, String reference, this.branchName) :
    super(sha, reference);
}

class TreeEntry {
  static final _lsTreeLine = r'^([0-9]{6}) (blob|tree) ('
      .concat(Git._shaRegexPattern)
      .concat(')\t(\\S.*\\S)\$');

  static final _lsTreeRegEx = new RegExp(_lsTreeLine);

  String mode;

  // TODO: enum for type?
  String type;
  String sha;
  String name;

  TreeEntry(this.mode, this.type, this.sha, this.name) {
    // TODO: asserts!
  }

  factory TreeEntry.fromLsTree(String value) {
    // TODO: should catch and re-throw a descriptive error
    final match = _lsTreeRegEx.allMatches(value).single;

    return new TreeEntry(match[1], match[2], match[3], match[4]);
  }

  static List<TreeEntry> fromLsTreeOutput(String output) {
    final lines = Util.splitLines(output);

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.getRange(0, lines.length-1)
        .mappedBy((line) => new TreeEntry.fromLsTree(line))
        .toList();
  }
}
