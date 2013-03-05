part of bot_io;

class IoHelpers {
  static final Object _dirPlaceHolder = new Object();

  static Future<bool> verifyContents(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(content != null);
    return dir.exists()
        .then((bool doesExist) {
          if(!doesExist) {
            return new Future.immediate(false);
          } else {
            return _verifyContents(dir, content);
          }
        });
  }

  static Future<bool> isEmpty(Directory dir) {
    assert(dir != null);
    return verifyContents(dir, {});
  }

  static Future<Map> _mapContents(Directory dir) {

    return dir.list()
        .toList()
        .then((List<FileSystemEntity> entities) {
          final map = new Map<String, dynamic>();
          for(final e in entities) {
            final name = new Path(e.path).filename;
            if(e is File) {
              final file = e as File;
              map[name] = file.readAsStringSync();
            } else {
              assert(e is Directory);
              map[name] = _dirPlaceHolder;
            }
          }

          return map;
        });
  }

  static Future<bool> _verifyContents(Directory dir, Map<String, dynamic> content) {
    return _mapContents(dir)
        .then((Map<String, dynamic> map) {
          if(map.length != content.length) {
            return false;
          }

          final missing = new Set<String>.from(content.keys);
          final extra = new Set<String>();
          for(final item in map.keys) {
            if(!missing.remove(item)) {
              extra.add(item);
            }
          }

          if(!missing.isEmpty) {
            // items is missing were not found! sad!
            print('missing: $missing');
            return false;
          } else if(!extra.isEmpty) {
            // too many items!
            print('extra: $extra');
            return false;
          }

          final futures = content.keys.map((name) {
            return _verifyChildContent(dir, name, content[name], map[name]);
          });

          return Future.wait(futures)
              .then((List<bool> results){
                return results.every((v) => v);
              });
        });
  }


  static Future<bool> _verifyChildContent(Directory parentDir, String name,
      dynamic expectedContent, dynamic foundContent) {
    assert(parentDir != null);
    assert(parentDir.existsSync());
    if(expectedContent is String) {
      return new Future.immediate(expectedContent == foundContent);
    } else if(expectedContent is Map) {
      final subDirPath = new Path(parentDir.path).append(name);
      final subDir = new Directory.fromPath(subDirPath);

      assert(foundContent == _dirPlaceHolder);

      return _verifyContents(subDir, expectedContent);
    } else {
      throw 'no clue what to do w/ that';
    }
  }
}
