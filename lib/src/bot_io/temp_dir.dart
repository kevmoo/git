part of bot_io;

class TempDir {
  final Directory dir;

  bool _disposed = false;

  static Future<TempDir> create() {
    final startDir = new Directory('');
    return startDir.createTemp()
        .then((newDir) => new TempDir._internal(newDir));
  }

  TempDir._internal(this.dir) {
    assert(this.dir != null);
    assert(this.dir.existsSync());
  }

  String get path => dir.path;

  bool get isDisposed => _disposed;

  Future<TempDir> populate(DirectoryPopulater populater) {
    return populater.populate(dir)
        .then((Directory outputDir) {
          assert(dir == outputDir);
          return this;
        });
  }

  Future<bool> verifyContents(Map<String, dynamic> content) {
    return IoHelpers.verifyContents(dir, content);
  }

  Future<bool> isEmpty() {
    return IoHelpers.isEmpty(dir);
  }

  String toString() => "TempDir: $path";

  Future dispose() {
    require(_disposed == false, 'Already disposed ore in the process of being'
        ' disposed.');
    _disposed = null;
    return dir.delete(recursive: true)
        .then((_) {
          _disposed = true;
          return null;
        });
  }
}
