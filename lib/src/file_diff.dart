import 'diff_hunk.dart';

class FileDiff {
  final String? pathBase;
  final String? pathRef;
  final String diff;
  final List<DiffHunk> hunks;

  FileDiff({
    required this.diff,
    required this.hunks,
    this.pathBase,
    this.pathRef,
  });

  bool get isNew => pathBase == null && pathRef != null;
  bool get isRemoved => pathBase != null && pathRef == null;
  bool get isRenamed =>
      pathBase != pathRef && pathBase != null && pathRef != null;
}

class SourceDiff {}
