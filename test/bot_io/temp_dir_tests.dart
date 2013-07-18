part of test_bot_io;

class TempDirTests {

  static final _map = {
                       'file1.txt': 'content',
                       'file2.txt': 'content2',
                       'empty dir': { },
                       'dir1': {'dir1_file1.txt': 'and content some more'} };

  static final _mapFewer = {
                           'file1.txt': 'content',
                           'empty dir': { },
                           'dir1': {'dir1_file1.txt': 'and content some more'}
                           };

  static final _mapMore = {
                          'file1.txt': 'content',
                          'file2.txt': 'content2',
                          'empty dir': { 'file3.txt': 'content3' },
                           'dir1': { 'dir1_file1.txt': 'and content some more'}
                          };

  static final _mapDiff = {
                          'file1.txt': 'content_',
                          'file2.txt': 'content2',
                          'empty dir': { },
                          'dir1': { 'dir1_file1.txt': 'and content some more'}
                          };

  static void register() {
    test('good match', () => _testTempDirPopulate(_map, _map, true));
    test('too few', () => _testTempDirPopulate(_map, _mapFewer, false));
    test('too many', () => _testTempDirPopulate(_map, _mapMore, false));
    test('different', () => _testTempDirPopulate(_map, _mapDiff, false));
    test('empty', () => _testTempDirPopulate(_map, {}, false));

    test('empty to empty', () => _testTempDirPopulate({}, {}, true));

    test('one file to one file', () => _testTempDirPopulate(
        {'a.txt': 'a'}, {'a.txt': 'a'}, true));

    test('same name, different content', () => _testTempDirPopulate(
        {'a.txt': 'a'}, {'a.txt': 'b'}, false));

    test('diff name, same content', () => _testTempDirPopulate(
        {'a.txt': 'a'}, {'b.txt': 'a'}, false));

    group('entity exists', () {

      // TODO: test links

      final dummyValues = new Map<FileSystemEntityType, dynamic>();
      dummyValues[FileSystemEntityType.FILE] = 'file contents';
      dummyValues[FileSystemEntityType.DIRECTORY] = {'dirfile.txt': 'txt'};

      const entityTypes = const [FileSystemEntityType.DIRECTORY,
                                 FileSystemEntityType.FILE,
                                 FileSystemEntityType.LINK,
                                 null];

      dummyValues.forEach((type, value) {
        entityTypes.forEach((testType) {

          String testTypeStr = testType == null ? 'entity' : testType.toString();

          test('$type is $testTypeStr', () {
            final createMap = new Map();
            createMap['entity'] = value;

            final testMap = new Map();
            testMap['entity'] = new EntityExistsValidator(testType);

            return _testTempDirPopulate(createMap, testMap,
                testType == null || testType == type);
          });

        });

      });

    });
  }
}

Future _testTempDirPopulate(Map source, Map target, bool shouldWork) {

  TempDir tempDir = null;


  return TempDir.create()
      .then((TempDir td) {
        assert(tempDir == null);
        tempDir = td;

        return tempDir.populate(source);
      })
      .then((TempDir value) {
        expect(value, equals(tempDir));
        return tempDir.verifyContents(target);
      })
      .then((bool expectTrue) {
        expect(expectTrue, shouldWork, reason: 'should match the provided map');
      })
      .then((_) {
        return tempDir.dispose();
      })
      .then((_) {
        expect(tempDir.dir.existsSync(), isFalse, reason: 'Temp dir should be deleted');
        tempDir = null;
      });
}
