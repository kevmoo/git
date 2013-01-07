part of bot_io;

class TempDir extends DisposableImpl {
  final Directory dir;

  factory TempDir() {

    final startDir = new Directory('');
    return new TempDir._internal(startDir.createTempSync());
  }

  TempDir._internal(this.dir);

  String get path => dir.path;

  Future populate(DirectoryPopulater populater) {
    return populater.populate(dir);
  }

  Future<bool> verifyContents(Map<String, dynamic> content) {
    return IoHelpers.verifyContents(dir, content);
  }

  Future<bool> isEmpty() {
    return IoHelpers.isEmpty(dir);
  }

  String toString() => "TempDir: $path";

  @protected
  void disposeInternal() {
    assert(dir.existsSync());
    dir.deleteSync(recursive: true);
    assert(!dir.existsSync());
  }
}
