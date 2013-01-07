part of bot_io;

class IoHelpers {
  static Future<bool> verifyContents(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(content != null);
    return dir.exists()
        .chain((bool doesExist) {
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
    final completer = new Completer<Map>();
    final map = new Map<String, dynamic>();


    final lister = dir.list();
    lister.onDir = (String dirPath) {
      final name = new Path(dirPath).filename;
      assert(!map.containsKey(name));
      map[name] = {};
    };

    lister.onDone = (bool completed) {
      if(completed) {
        completer.complete(map);
      } else {
        completer.completeException('done, but not completed...weird...');
      }
    };

    lister.onError = (e) {
      completer.completeException(e);
    };

    lister.onFile = (String filePath) {
      final path = new Path(filePath);
      final name = path.filename;
      final file = new File.fromPath(path);
      map[name] = file.readAsStringSync();
    };

    return completer.future;
  }

  static Future<bool> _verifyContents(Directory dir, Map<String, dynamic> content) {
    return _mapContents(dir)
        .chain((Map<String, dynamic> map) {
          if(map.length != content.length) {
            return new Future.immediate(false);
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
            return new Future.immediate(false);
          } else if(!extra.isEmpty) {
            // too many items!
            print('extra: $extra');
            return new Future.immediate(false);
          }

          final futures = content.keys.map((name) {
            return _verifyChildContent(dir, name, content[name], map[name]);
          });

          return Futures.wait(futures)
              .transform((List<bool> results){
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

      final Map<String, dynamic> foundMap = foundContent;
      assert(foundMap.isEmpty);

      return _verifyContents(subDir, expectedContent);
    } else {
      throw 'no clue what to do w/ that';
    }
  }
}
