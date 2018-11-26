import 'commit_reference.dart';

const _localBranchPrefix = r'refs/heads/';

class BranchReference extends CommitReference {
  final String branchName;

  factory BranchReference(String sha, String reference) {
    assert(reference.startsWith(_localBranchPrefix));

    var branchName = reference.substring(_localBranchPrefix.length);

    return BranchReference._internal(sha, reference, branchName);
  }

  BranchReference._internal(String sha, String reference, this.branchName)
      : super(sha, reference);

  @override
  String toString() => 'BranchReference: $branchName  $sha  ($reference)';
}
