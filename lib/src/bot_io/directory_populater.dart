part of bot_io;

abstract class DirectoryPopulater {
  Future<Directory> populate(Directory dir);
}

class MapDirectoryPopulater extends DirectoryPopulater {
  final Map<String, dynamic> _contents;

  MapDirectoryPopulater(this._contents);

  Future<Directory> populate(Directory dir) {
    assert(dir != null);
    return IoHelpers.isEmpty(dir)
        .then((bool isEmpty) {
          if(!isEmpty) {
            throw 'target directory must be empty';
          }
          return _populate(dir, _contents);
        });
  }

  static Future<Directory> _populate(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(dir.existsSync());
    assert(content != null);

    final completer = new Completer();

    return Future.forEach(content.keys, (String key) {
      final v = content[key];

      if(v is Map) {
        return _createDirAndPopulate(dir, key, v);
      } else if(v is String) {
        return _createFile(dir, key, v);
      } else {
        throw 'value for $key was $v - expected Map or String';
      }
    }).then((obj) {
      return dir;
    });
  }

  static Future<File> _createFile(Directory parent, String name, String content) {
    final filePath = new Path(parent.path).append(name);
    final file = new File.fromPath(filePath);
    assert(!file.existsSync());
    return file.writeAsString(content);
  }

  static Future<Directory> _createDirAndPopulate(Directory parent, String name, Map<String, dynamic> content) {
    final subDirPath = new Path(parent.path).append(name);
    final subDir = new Directory.fromPath(subDirPath);
    assert(!subDir.existsSync());
    return subDir.create()
        .then((theNewDir) {
          assert(theNewDir == subDir);
          return _populate(theNewDir, content);
        });
  }
}
