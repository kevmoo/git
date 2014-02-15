part of bot_git;

void requireArgumentValidSha1(String value, String argName) {
  _metaRequireArgumentNotNullOrEmpty(argName);
  requireArgumentNotNullOrEmpty(value, argName);

  if(!Git.isValidSha(value)) {
    final message = 'Not a valid SHA1 value: $value';
    throw new DetailedArgumentError(argName, message);
  }
}

void _metaRequireArgumentNotNullOrEmpty(String argName) {
  if(argName == null || argName.length == 0) {
    throw new InvalidOperationError("That's just sad. Give me a good argName");
  }
}

class GitError extends Error {
  final String message;

  GitError(this.message);

  String toString() => message;
}

class Git {
  static const _SHA_REGEX_PATTERN = '[a-f0-9]{40}';
  static final _shaRegEx = new RegExp(r'^' + _SHA_REGEX_PATTERN + r'$');

  static bool isValidSha(String value) {
    return _shaRegEx.hasMatch(value);
  }

  static Future<ProcessResult> runGit(List<String> args,
      {bool throwOnError: true, String processWorkingDir}) {

    return Process.run('git', args, workingDirectory: processWorkingDir)
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

class Tag {
  final String objectSha;
  final String type;
  final String tag;
  final String tagger;

  Tag._internal(this.objectSha, this.type, this.tag, this.tagger) {
    requireArgumentValidSha1(objectSha, 'objectSha');
    requireArgumentNotNullOrEmpty(type, 'type');
    requireArgumentNotNullOrEmpty(tag, 'tag');
    requireArgumentNotNullOrEmpty(tagger, 'tagger');
  }

  static Tag parseCatFile(String content) {
    final headers = new Map<String, List<String>>();

    final slr = new StringLineReader(content);

    String lastLine = slr.readNextLine();

    while(!lastLine.isEmpty) {
      final match = Commit._headerRegExp.allMatches(lastLine).single;
      assert(match.groupCount == 2);
      final header = match.group(1);
      final value = match.group(2);

      final list = headers.putIfAbsent(header, () => new List<String>());
      list.add(value);

      lastLine = slr.readNextLine();
    }

    final objectSha = headers['object'].single;
    final type = headers['type'].single;
    final tag = headers['tag'].single;
    final tagger = headers['tagger'].single;

    return new Tag._internal(objectSha, type, tag, tagger);
  }
}

/**
 * Represents the output from `git show-ref`
 */
class CommitReference {
  static final RegExp _lsRemoteRegExp = new RegExp('^(${Git._SHA_REGEX_PATTERN}) (.+)\$');

  final String sha;
  final String reference;

  CommitReference(this.sha, this.reference) {
    requireArgumentValidSha1(this.sha, 'sha');

    assert(reference != null);
    // TODO: probably a better way to verify...but this is fine for now
    assert(reference.startsWith(r'refs/') || reference == 'HEAD');
  }

  static List<CommitReference> fromShowRefOutput(String input) {
    assert(input != null);
    final lines = Util.splitLines(input).toList();

    // last line should be empty
    assert(lines.last.length == 0);

    return lines.sublist(0, lines.length-1)
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

    requireArgumentValidSha1(this.treeSha, 'treeSha');
    for(final parent in parents) {
      requireArgumentValidSha1(parent, 'parents');
    }

    // null checks on many things
    // unique checks on parents
  }

  static Commit parse(String content) {
    final slr = new StringLineReader(content);
    final tuple = _parse(slr, false);
    assert(tuple.item1 == null);
    return tuple.item2;
  }

  static Map<String, Commit> parseRawRevList(String content) {
    final slr = new StringLineReader(content);

    Map<String, Commit> commits = new Map<String, Commit>();

    while(slr.position != null && slr.position < content.length) {
      final tuple = _parse(slr, true);
      commits[tuple.item1] = tuple.item2;
    }

    return commits;
  }

  static Tuple<String, Commit> _parse(StringLineReader slr, bool isRevParse) {
    assert(slr != null);
    assert(slr.position != null);

    final headers = new Map<String, List<String>>();

    final int startSpot = slr.position;
    String lastLine = slr.readNextLine();

    while(!lastLine.isEmpty) {
      final match = _headerRegExp.allMatches(lastLine).single;
      assert(match.groupCount == 2);
      final header = match.group(1);
      final value = match.group(2);

      final list = headers.putIfAbsent(header, () => new List<String>());
      list.add(value);

      lastLine = slr.readNextLine();
    }

    assert(lastLine.isEmpty);

    String message;

    if(isRevParse) {
      final msgLines = new List<String>();
      lastLine = slr.readNextLine();

      const revParseMessagePrefix = '    ';
      while(lastLine != null && lastLine.startsWith(revParseMessagePrefix)) {
        msgLines.add(lastLine.substring(revParseMessagePrefix.length));
        lastLine = slr.readNextLine();
      }

      message = msgLines.join('\n');
    } else {
      message = slr.readToEnd();
      assert(message.endsWith('\n'));
      final originalMessageLength = message.length;
      message = message.trim();
      // message should be trimmed by git, so the only diff after trim
      // should be 1 character - the removed new line
      assert(message.length + 1 == originalMessageLength);
    }

    final treeSha = headers['tree'].single;
    final author = headers['author'].single;
    final committer = headers['committer'].single;
    final commitSha = headers.containsKey('commit') ? headers['commit'].single : null;

    var parents = headers['parent'];
    if(parents == null) {
      parents = [];
    }

    final int endSpot = slr.position;

    final content = slr.source.substring(startSpot, endSpot);

    return new Tuple(commitSha, new Commit._internal(treeSha, author, committer, message, content, parents));
  }
}

class TreeEntry {
  static final _lsTreeLine = r'^([0-9]{6}) (blob|tree) ('
      + Git._SHA_REGEX_PATTERN
      + ')\t(\\S.*\\S)\$';

  static final _lsTreeRegEx = new RegExp(_lsTreeLine);

  /**
   * All numbers.
   *
   * See this this [post on stackoverflow](http://stackoverflow.com/questions/737673/how-to-read-the-mode-field-of-git-ls-trees-output)
   */
  String mode;

  // TODO: enum for type?
  String type;
  String sha;
  String name;

  TreeEntry(this.mode, this.type, this.sha, this.name) {
    // TODO: enum or whitelist here
    requireArgumentContainsPattern(new RegExp(r'^[0-9]{6}$'), mode, 'mode');

    // TODO: enum or whitelist here
    requireArgumentContainsPattern(new RegExp(r'^[a-z]+$'), type, 'type');
    requireArgumentValidSha1(sha, 'sha');

    // TODO: how can we be more careful here? no paths? hmm...
    requireArgumentNotNullOrEmpty(name, 'name');
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

    return lines.sublist(0, lines.length-1)
        .map((line) => new TreeEntry.fromLsTree(line))
        .toList();
  }
}
