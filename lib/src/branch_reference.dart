library git.branch_reference;

import 'commit_reference.dart';

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
