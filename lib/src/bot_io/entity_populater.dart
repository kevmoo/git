part of bot_io;

abstract class EntityPopulater {

  static Future<FileSystemEntity> populate(String path, dynamic source,
      {bool createParentDirectories: false, bool overwriteExisting: false}) {

    if(source is String) {
      var stringStream = new Stream.fromIterable([source]);
      var encoder = new StringEncoder();
      source = encoder.bind(stringStream);
    } else if(source is File) {
      source = source.openRead();
    }

    if(source is Stream) {
      return _ensurePath(path, createParentDirectories: createParentDirectories,
          overwriteExisting: overwriteExisting)
          .then((_) => _populateFileWithStream(path, source));
    }

    throw "Don't know how to populate from '$source'...yet?";
  }

  Future<FileSystemEntity> populatePath(String path,
      {bool createParentDirectories: false, bool overwriteExisting: false});

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

  static Future _ensurePath(String path,
      {bool createParentDirectories: false, bool overwriteExisting: false}) {

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
                    final dir = new Directory(path);
                    return dir.delete(recursive: true);
                  case FileSystemEntityType.LINK:
                    final link = new Link(path);
                    return link.delete();
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

// TOOD: create new EntityPopulatorException
