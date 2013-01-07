part of bot_io;

class TempDir extends DisposableImpl {
  final Directory dir;

  static Future<TempDir> create() {
    final startDir = new Directory('');
    return startDir.createTemp()
        .transform((newDir) => new TempDir._internal(newDir));
  }

  TempDir._internal(this.dir) {
    assert(this.dir != null);
    assert(this.dir.existsSync());
  }

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
