import 'package:collection/collection.dart';

import 'diff_hunk.dart';

class FileDiff {
  final String? pathBase;
  final String? pathRef;
  final List<DiffHunk> hunks;

  FileDiff({
    required this.hunks,
    this.pathBase,
    this.pathRef,
  });

  bool get isNew => pathBase == null && pathRef != null;
  bool get isRemoved => pathBase != null && pathRef == null;
  bool get isRenamed =>
      pathBase != pathRef && pathBase != null && pathRef != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileDiff &&
          runtimeType == other.runtimeType &&
          pathBase == other.pathBase &&
          pathRef == other.pathRef &&
          const DeepCollectionEquality().equals(
            hunks,
            other.hunks,
          );

  @override
  int get hashCode => Object.hash(
        pathBase,
        pathRef,
        const DeepCollectionEquality().hash(hunks),
      );

  @override
  String toString() => '$FileDiff(pathBase: $pathBase, pathRef: $pathRef, '
      'hunks: $hunks)';
}
