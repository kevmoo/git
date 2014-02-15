library git.commit_reference;

import 'package:bot/bot.dart';

import 'branch_reference.dart';
import 'util.dart';

/**
 * Represents the output from `git show-ref`
 */
class CommitReference {
  static final RegExp _lsRemoteRegExp = new RegExp('^($SHA_REGEX_PATTERN) (.+)\$');

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
