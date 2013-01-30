part of bot_io;

abstract class DirectoryPopulater {
  Future<Directory> populate(Directory dir);
}

class MapDirectoryPopulater extends DirectoryPopulater {
  final bool checkEmpty;
  final Map<String, dynamic> _contents;

  MapDirectoryPopulater(this._contents, {this.checkEmpty: false});

  Future<Directory> populate(Directory dir) {
    assert(dir != null);

    if(checkEmpty) {
      return IoHelpers.isEmpty(dir)
          .then((bool isEmpty) {
            if(!isEmpty && !checkEmpty) {
              throw 'target directory must be empty';
            }
            return _populate(dir, _contents);
          });
    } else {
      return _populate(dir, _contents);
    }
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

  // TODO: should pass in a flag to check for directory existing...and what to do
  static Future<Directory> _createDirAndPopulate(Directory parent, String name, Map<String, dynamic> content) {
    final subDirPath = new Path(parent.path).append(name);
    final subDir = new Directory.fromPath(subDirPath);
    return subDir.create()
        .then((theNewDir) {
          assert(theNewDir == subDir);
          return _populate(theNewDir, content);
        });
  }
}
