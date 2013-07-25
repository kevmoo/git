part of test_bot_io;

const _entityTypes = const [null, FileSystemEntityType.FILE,
                            FileSystemEntityType.DIRECTORY,
                            FileSystemEntityType.LINK];

const _dirMap = const {
  'file.txt': 'content text',
  'file2.txt': 'content 2 text',
  'dir1' : const {
    'subfile': 'subFileContent',
    'emptySubSubDir': const {}
  },
  'emptySubDir': const {}
};

void _registerEntityPopulaterTests() {
  _registerEntityPopulaterTestsImpl(FileSystemEntityType.FILE,
      'String', 'test string content');

  _registerEntityPopulaterTestsImpl(FileSystemEntityType.DIRECTORY,
      'Map', _dirMap);
}

void _registerEntityPopulaterTestsImpl(FileSystemEntityType type,
                                       String contentDescription,
                                       dynamic testContent) {

  group('$type from $contentDescription', () {

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
                    'overwrite existing: $overwriteExisting; '
                    'will $resultStr', () {
                  return _testEntityPopulator(type, testContent,
                      createParent, overwriteExisting,
                      parentDirExists, existingEntity, success);
                });
              }
            } else {
              var existingString = (existingEntity == null) ?
                  'no existing entity' : 'existing $existingEntity';
              test('parent exists; $existingString; '
                  'create parent: $createParent; '
                  'overwrite existing: $overwriteExisting; '
                  'will $resultStr', () {
                return _testEntityPopulator(type, testContent,
                    createParent, overwriteExisting,
                    parentDirExists, existingEntity, success);
              });
            }
          });
        });
      });
    });
  });
}

Future _testEntityPopulator(FileSystemEntityType entityType,
                            dynamic entityContent, bool createParent,
                            bool overwriteExisting, bool parentDirExists,
                            FileSystemEntityType existingEntityType,
                            bool expectedSuccess) {

  const entityName = 'targetEntityName';

  assert(parentDirExists == true || existingEntityType == null);

  final entityRelativePath = parentDirExists ?
      entityName : pathos.join('parentDir', entityName);

  return TempDir.then((dir) {
    var absolutePath = pathos.join(dir.path, entityRelativePath);

    return new Future(() {
      if(existingEntityType != null) {
        switch(existingEntityType) {
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
            throw 'not impled yet: existing entity $existingEntityType';
        }
      }
    })
    .then((_) {
      return EntityPopulater.populate(absolutePath, entityContent,
          createParentDirectories: createParent,
          overwriteExisting: overwriteExisting);
    })
    .then((FileSystemEntity entity) {
      expect(entity.path, equals(absolutePath));
      expect(FileSystemEntity.typeSync(entity.path, followLinks: false),
          entityType);

      return EntityValidator.validate(entity, entityContent)
          .isEmpty;
    })
    .catchError((error) {
      assert(error is EntityPopulatorException);
      return false;
    }, test: (error) {
      return error is EntityPopulatorException;
    })
    .then((bool isSuccess) {
      expect(isSuccess, expectedSuccess);
    });
  });
}
