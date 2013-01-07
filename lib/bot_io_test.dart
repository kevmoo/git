library bot_io_test;

import 'dart:io';
import 'package:bot/bot.dart';

// helpers for testing code that modifies the file system

// verify directory structure

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

abstract class DirectoryPopulater {
  Future populate(Directory dir);
}

class MapDirectoryPopulater extends DirectoryPopulater {
  final Map<String, dynamic> _contents;

  MapDirectoryPopulater(this._contents);

  Future populate(Directory dir) {
    assert(dir != null);
    return IoHelpers.isEmpty(dir)
        .chain((bool isEmpty) {
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

    return Futures.forEach(content.keys, (String key) {
      final v = content[key];

      if(v is Map) {
        return _createDirAndPopulate(dir, key, v);
      } else if(v is String) {
        return _createFile(dir, key, v);
      } else {
        throw 'value for $key was $v - expected Map or String';
      }
    });
  }

  static Future<File> _createFile(Directory parent, String name, String content) {
    final filePath = new Path(parent.path).append(name);
    final file = new File.fromPath(filePath);
    assert(!file.existsSync());
    return file.writeAsString(content);
  }

  static Future _createDirAndPopulate(Directory parent, String name, Map<String, dynamic> content) {
    final subDirPath = new Path(parent.path).append(name);
    final subDir = new Directory.fromPath(subDirPath);
    assert(!subDir.existsSync());
    return subDir.create()
        .chain((theNewDir) {
          assert(theNewDir == subDir);
          return _populate(theNewDir, content);
        });
  }
}
