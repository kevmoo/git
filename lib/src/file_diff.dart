class FileDiff {
  final String? pathBase;
  final String? pathRef;
  final String diff;

  FileDiff({
    required this.diff,
    this.pathBase,
    this.pathRef,
  });

  bool get isNew => pathBase == null && pathRef != null;
  bool get isRemoved => pathBase != null && pathRef == null;
  bool get isRenamed =>
      pathBase != pathRef && pathBase != null && pathRef != null;
}

class SourceDiff {}
