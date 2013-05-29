part of bot_io;

abstract class EntityPopulater {

  static Future<FileSystemEntity> populate(String path, dynamic source,
      {bool createParentDirectories: false, bool overwriteExisting: false,
    bool leaveExistingDirs: false}) {

    if(source is String) {
      var stringStream = new Stream.fromIterable([source]);
      var encoder = new StringEncoder();
      source = encoder.bind(stringStream);
    } else if(source is File) {
      source = source.openRead();
    }

    if(source is Stream) {
      return _ensurePath(path, createParentDirectories: createParentDirectories,
          overwriteExisting: overwriteExisting,
          leaveExistingDir: leaveExistingDirs)
          .then((_) => _populateFileWithStream(path, source));
    } else if(source is Map) {
      return _ensurePath(path, createParentDirectories: createParentDirectories,
          overwriteExisting: overwriteExisting,
          leaveExistingDir: leaveExistingDirs)
          .then((_) => _populateDirWithMap(path, source, overwriteExisting,
              leaveExistingDirs));
    }

    throw "Don't know how to populate from '$source'...yet?";
  }

  static Future<Directory> updateDirectory(String path,
      Map<String, dynamic> source) {
    assert(path != null);
    assert(source != null);

    var existingDir = new Directory(path);

    return existingDir.exists()
        .then((bool exists) {
          if(!exists) {
            throw new EntityPopulatorException._internal('Expected directory to'
                ' exist at $path', path);
          }

          return _populateDirWithMap(path, source, true, true);
        });
  }

  /**
   * We assume [_ensurePath] has been called first.
   */
  static Future<File> _populateFileWithStream(String path,
      Stream<List<int>> content) {

    var file = new File(path);
    return file.openWrite()
        .addStream(content)
        .then((_) {
          return file;
        });
  }

  /**
   * We assume [_ensurePath] has been called first.
   */
  static Future<Directory> _populateDirWithMap(String path,
      Map<String, dynamic> content, bool overwriteExisting,
      bool leaveExistingDir) {

    var dir = new Directory(path);

    // calling _ensurePath *should* ensure the parent dir is created
    return dir.create(recursive: false)
        .then((_) {
          return Future.forEach(content.keys, (String entityName) {
            // TODO: assert entityName has no path characters, right?

            var entityPath = pathos.join(path, entityName);
            return populate(entityPath, content[entityName],
                overwriteExisting: overwriteExisting,
                leaveExistingDirs: leaveExistingDir);

          });
        })
        .then((_) => dir);
  }

  static Future _ensurePath(String path,
      {bool createParentDirectories: false, bool overwriteExisting: false,
    bool leaveExistingDir: false}) {

    final dirName = pathos.dirname(path);
    var parentDir = new Directory(dirName);
    return parentDir.exists()
        .then((bool parentDirExists) {
          if(!parentDirExists && !createParentDirectories) {
            throw new EntityPopulatorException._internal(
                'Parent directory does not exist', path);
          } else if(parentDirExists) {

            // shouldn't there be an async version of this?
            var existingType =
                FileSystemEntity.typeSync(path, followLinks: false);

            if(existingType != FileSystemEntityType.NOT_FOUND) {

              if(overwriteExisting) {
                switch(existingType) {
                  case FileSystemEntityType.DIRECTORY:
                    if(leaveExistingDir) {
                      return;
                    } else {
                      final dir = new Directory(path);
                      return dir.delete(recursive: true);
                    }
                    // DARTBUG: http://dartbug.com/6563
                    break;
                  case FileSystemEntityType.LINK:
                    final link = new Link(path);
                    return link.delete();
                  case FileSystemEntityType.FILE:
                    final file = new File(path);
                    return file.delete();
                }

              } else {
                throw new EntityPopulatorException._internal(
                    'Existing entity.', path);
              }
            }

          }

          if(!parentDirExists && createParentDirectories) {
            return parentDir.create(recursive: true);
          }
        });
  }
}

class EntityPopulatorException implements Exception {
  final String message;
  final String targetPath;

  EntityPopulatorException._internal(this.message, this.targetPath) {
    assert(message != null);
    assert(targetPath != null);
  }

  @override
  String toString() => 'EntityPopulatorException: $message\t$targetPath';
}

