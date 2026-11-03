/// Represents the tracking status of a branch parsed from `git for-each-ref`.
class BranchTracking {
  final String branchName;
  final String sha;
  final String upstream;
  final bool isUpstreamGone;

  const BranchTracking({
    required this.branchName,
    required this.sha,
    required this.upstream,
    required this.isUpstreamGone,
  });

  static List<BranchTracking> fromForEachRefOutput(String output) {
    final status = <BranchTracking>[];
    if (output.trim().isEmpty) return status;

    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('\t');
      if (parts.length >= 4) {
        final branchName = parts[0];
        final upstream = parts[1];
        final track = parts[2];
        final sha = parts[3];

        status.add(
          BranchTracking(
            branchName: branchName,
            sha: sha,
            upstream: upstream,
            isUpstreamGone: track == '[gone]',
          ),
        );
      }
    }
    return status;
  }
}
