part of bot_io;

class TempDir extends DisposableImpl {
  final Directory _dir;

  factory TempDir() {

    final startDir = new Directory('');
    return new TempDir._internal(startDir.createTempSync());
  }

  TempDir._internal(this._dir);

  String get path => _dir.path;

  Future populate(DirectoryPopulater populater) {
    return populater.populate(_dir);
  }

  Future<bool> verifyContents(Map<String, dynamic> content) {
    return IoHelpers.verifyContents(_dir, content);
  }

  Future<bool> isEmpty() {
    return IoHelpers.isEmpty(_dir);
  }

  String toString() => "TempDir: $path";

  @protected
  void disposeInternal() {
    assert(_dir.existsSync());
    _dir.deleteSync(recursive: true);
    assert(!_dir.existsSync());
  }
}
