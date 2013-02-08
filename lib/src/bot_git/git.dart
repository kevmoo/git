part of bot_git;

class Git {
  static const _shaRegexPattern = '[a-f0-9]{40}';
  static final _shaRegEx = new RegExp(r'^'.concat(_shaRegexPattern).concat(r'$'));

  static bool isValidSha(String value) {
    return _shaRegEx.hasMatch(value);
  }

  static Future<ProcessResult> runGit(List<String> args,
      {bool throwOnError: true, String processWorkingDir}) {

    final processOptions = new ProcessOptions();
    if(processWorkingDir != null) {
      final nativeDir = new Path(processWorkingDir).toNativePath();
      processOptions.workingDirectory = nativeDir;
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
'''

stdout:
${pr.stdout}
stderr:
${pr.stderr}''';

      throw new ProcessException('git', args, message, pr.exitCode);
    }
  }
}

/**
 * Represents the output from `git show-ref`
 */
class CommitReference {
  static final RegExp _lsRemoteRegExp = new RegExp('^(${Git._shaRegexPattern}) (.+)\$');

  final String sha;
  final String reference;

  CommitReference(this.sha, this.reference) {
    assert(Git.isValidSha(sha));

    assert(reference != null);
    // TODO: probably a better way to verify...but this is fine for now
    assert(reference.startsWith(r'refs/') || reference == 'HEAD');
  }

  static List<CommitReference> fromShowRefOutput(String input) {
    assert(input != null);
    final lines = Util.splitLines(input).toList();

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.getRange(0, lines.length-1)
        .map((line) {
          final match = _lsRemoteRegExp.allMatches(line).single;
          assert(match.groupCount == 2);

          return new CommitReference(match[1], match[2]);

        }).toList();
  }

  BranchReference toBranchReference() =>
      new BranchReference(this.sha, this.reference);

  String toString() =>
      'GitReference: $reference  $sha';
}

class BranchReference extends CommitReference {
  static const _localBranchPrefix = r'refs/heads/';

  final String branchName;

  factory BranchReference(String sha, String reference) {
    assert(reference.startsWith(_localBranchPrefix));

    final branchName = reference.substring(_localBranchPrefix.length);

    return new BranchReference._internal(sha, reference, branchName);
  }

  BranchReference._internal(String sha, String reference, this.branchName) :
    super(sha, reference);

  String toString() =>
      'BranchReference: $branchName  $sha  ($reference)';
}

class Commit {
  static final _headerRegExp = new RegExp(r'^([a-z]+) (.+)$');

  final String treeSha;
  final String author;
  final String committer;
  final String message;
  final String content;
  final ReadOnlyCollection<String> parents;

  Commit._internal(this.treeSha, this.author, this.committer, this.message,
      this.content, Iterable<String> parents) :
      this.parents = new ReadOnlyCollection<String>(parents) {

    requireArgument(Git.isValidSha(this.treeSha), 'treeSha');
    for(final parent in parents) {
      requireArgument(Git.isValidSha(parent), 'parents', 'Every entry must be a valid sha');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    final slr = new StringLineReader(content);

    String lastLine = slr.readNextLine();

    final headers = new Map<String, List<String>>();
    while(!lastLine.isEmpty) {
      final match = _headerRegExp.allMatches(lastLine).single;
      assert(match.groupCount == 2);
      final header = match.group(1);
      final value = match.group(2);

      final list = headers.putIfAbsent(header, () => new List<String>());
      list.add(value);

      lastLine = slr.readNextLine();
    }

    var message = slr.readToEnd();
    assert(message.endsWith('\n'));
    final originalMessageLength = message.length;
    message = message.trim();
    // message should be trimmed by git, so the only diff after trim
    // should be 1 character - the removed new line
    assert(message.length + 1 == originalMessageLength);

    final treeSha = headers['tree'].single;
    final author = headers['author'].single;
    final committer = headers['committer'].single;

    var parents = headers['parent'];
    if(parents == null) {
      parents = [];
    }

    return new Commit._internal(treeSha, author, committer, message, content, parents);
  }
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

  String toString() => "$mode $type $sha\t$name";

  static List<TreeEntry> fromLsTreeOutput(String output) {
    final lines = Util.splitLines(output).toList();

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.getRange(0, lines.length-1)
        .map((line) => new TreeEntry.fromLsTree(line))
        .toList();
  }
}
