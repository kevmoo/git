class DiffHeader {
  final String? baseFile;
  final String? refFile;

  DiffHeader({
    required this.baseFile,
    required this.refFile,
  });

  bool get isNew => baseFile == null && refFile != null;
  bool get isRemoved => baseFile != null && refFile == null;
  bool get isRenamed =>
      baseFile != refFile && baseFile != null && refFile != null;
}
