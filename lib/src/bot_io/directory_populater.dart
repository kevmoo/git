part of bot_io;

@deprecated
abstract class DirectoryPopulater {
  Future<Directory> populate(Directory dir);
}

@deprecated
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
              throw new ArgumentError('target directory must be empty');
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

      final newItemPath = pathos.join(dir.path, key);

      if(v is Map) {
        return _createDirAndPopulate(newItemPath, v);
      } else if(v is String) {
        return EntityPopulater.populate(newItemPath, v,
            createParentDirectories: false, overwriteExisting: false);
      } else {
        throw new ArgumentError('value for $key was $v - expected Map or String');
      }
    }).then((_) {
      return dir;
    });
  }

  // TODO: should pass in a flag to check for directory existing...and what to do
  static Future<Directory> _createDirAndPopulate(String newItemPath, Map<String, dynamic> content) {
    final subDir = new Directory(newItemPath);
    return subDir.create()
        .then((theNewDir) {
          assert(theNewDir == subDir);
          return _populate(theNewDir, content);
        });
  }
}
