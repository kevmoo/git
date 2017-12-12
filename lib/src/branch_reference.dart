import 'commit_reference.dart';

const _LOCAL_BRANCH_PREFIX = r'refs/heads/';

class BranchReference extends CommitReference {
  final String branchName;

  factory BranchReference(String sha, String reference) {
    assert(reference.startsWith(_LOCAL_BRANCH_PREFIX));

    var branchName = reference.substring(_LOCAL_BRANCH_PREFIX.length);

    return new BranchReference._internal(sha, reference, branchName);
  }

  BranchReference._internal(String sha, String reference, this.branchName)
      : super(sha, reference);

  @override
  String toString() => 'BranchReference: $branchName  $sha  ($reference)';
}
