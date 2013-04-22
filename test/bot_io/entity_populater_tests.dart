part of test_bot_io;

const _entityTypes = const [null, FileSystemEntityType.FILE,
                            FileSystemEntityType.DIRECTORY,
                            FileSystemEntityType.LINK];

void _registerEntityPopulaterTests() {

  group('file from String content', () {

    [true, false].forEach((bool parentDirExists) {
      _entityTypes.forEach((FileSystemEntityType existingEntity) {
        [true, false].forEach((bool createParent) {
          [true, false].forEach((bool overwriteExisting) {

            final success = (createParent || parentDirExists) &&
                (overwriteExisting || existingEntity == null);

            final resultStr = success ? 'succeed' : 'fail';

            if(!parentDirExists) {
              if(existingEntity == null) {
                // ignore existingEntity
                test('no parent dir; create parent: $createParent; '
                    'overwrite existing: $overwriteExisting; will $resultStr', () {
                  return _testFileFromString(createParent, overwriteExisting,
                      parentDirExists, existingEntity, success);
                });
              }
            } else {
              var existingString = (existingEntity == null) ?
                  'no existing entity' : 'existing $existingEntity';
              test('parent exists; $existingString; create parent: $createParent; '
                  'overwrite existing: $overwriteExisting; will $resultStr', () {
                return _testFileFromString(createParent, overwriteExisting,
                    parentDirExists, existingEntity, success);
              });
            }
          });
        });
      });
    });
  });
}

Future _testFileFromString(bool createParent, bool overwriteExisting,
                         bool parentDirExists,
                         FileSystemEntityType existingEntity,
                         bool success) {

  const _fileName = 'file.txt';
  const _fileContent = 'file contents';

  assert(parentDirExists == true || existingEntity == null);

  final fileRelativePath = parentDirExists ?
      _fileName : pathos.join('parentDir', _fileName);


  TempDir tmpDir;
  String absolutePath;

  return TempDir.create()
      .then((TempDir value) {
        tmpDir = value;

        absolutePath = pathos.join(tmpDir.path, fileRelativePath);

        if(existingEntity != null) {
          switch(existingEntity) {
            case FileSystemEntityType.FILE:
              var existing = new File(absolutePath);
              return existing.writeAsString('existing content');
            case FileSystemEntityType.DIRECTORY:
              var existing = new Directory(absolutePath);
              return existing.create();
            case FileSystemEntityType.LINK:
              var linkToFilePath = absolutePath + '.content';
              var linkToFile = new File(linkToFilePath);
              return linkToFile.writeAsString('link to file content')
                  .then((File ltf) {
                    var link = new Link(absolutePath);
                    return link.create(linkToFilePath);
                  });
            default:
              throw 'not impled yet: existing entity $existingEntity';
          }
        }
      })
      .then((_) {
        return EntityPopulater.populate(absolutePath, _fileContent,
            createParentDirectories: createParent,
            overwriteExisting: overwriteExisting);
      })
      .then((File file) {
        expect(file.path, equals(absolutePath));
        expect(FileSystemEntity.typeSync(file.path, followLinks: false),
            FileSystemEntityType.FILE);

        // TODO: actually check to see if the file is really a file
        // ... and not a sym link

        return EntityValidator.validateFileStringContent(file, _fileContent)
            .isEmpty;
      })
      .catchError((error) {
        assert(error is EntityPopulatorException);
        return false;
      }, test: (error) {
        return error is EntityPopulatorException;
      })
      .then((bool isSuccess) {
        expect(isSuccess, success);
      })
      .whenComplete(() {
        if(tmpDir != null) {
          tmpDir.dispose();
        }
      });
}


