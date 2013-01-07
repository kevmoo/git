library bot_io_test;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';

// helpers for testing code that modifies the file system

// verify directory structure
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
  Future<Directory> populate(Directory dir);
}

class MapDirectoryPopulater extends DirectoryPopulater {
  final Map<String, dynamic> _contents;

  MapDirectoryPopulater(this._contents);

  Future<Directory> populate(Directory dir) {
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

  static Future<Directory> _createDirAndPopulate(Directory parent, String name, Map<String, dynamic> content) {
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
