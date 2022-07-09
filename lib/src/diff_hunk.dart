class DiffHunkRange {
  const DiffHunkRange({
    required this.startLine,
    required this.numberOfLines,
  });

  final int startLine;
  final int numberOfLines;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiffHunkRange &&
          runtimeType == other.runtimeType &&
          startLine == other.startLine &&
          numberOfLines == other.numberOfLines;

  @override
  int get hashCode => Object.hash(
        startLine,
        numberOfLines,
      );

  @override
  String toString() =>
      '$DiffHunkRange(startLine: $startLine, numberOfLines: $numberOfLines)';
}

class DiffHunk {
  const DiffHunk({
    required this.baseRange,
    required this.refRange,
    required this.content,
  });

  final DiffHunkRange baseRange;
  final DiffHunkRange refRange;
  final String content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiffHunk &&
          runtimeType == other.runtimeType &&
          baseRange == other.baseRange &&
          refRange == other.refRange &&
          content == other.content;

  @override
  int get hashCode => Object.hash(
        baseRange,
        refRange,
        content,
      );

  @override
  String toString() => '$DiffHunk(baseRange: $baseRange, refRange: $refRange, '
      'content: $content)';
}
