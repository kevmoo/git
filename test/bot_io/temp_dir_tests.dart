part of test_bot_io;

class TempDirTests {

  static final _map = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
               },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
  };

  static final mapFewer = {'file1.txt': 'content',
               'empty dir': {
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  static final mapMore = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
                 'file3.txt': 'content3'
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  static final mapDiff = {'file1.txt': 'content_',
               'file2.txt': 'content2',
               'empty dir': {
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  static void register() {
    test('good match', () => _testTempDirPopulate(_map, _map, true));
    test('too few', () => _testTempDirPopulate(_map, mapFewer, false));
    test('too many', () => _testTempDirPopulate(_map, mapMore, false));
    test('different', () => _testTempDirPopulate(_map, mapDiff, false));
    test('empty', () => _testTempDirPopulate(_map, {}, false));
  }
}

Future _testTempDirPopulate(Map source, Map target, bool shouldWork) {

  TempDir tempDir = null;


  return TempDir.create()
      .then((TempDir td) {
        assert(tempDir == null);
        tempDir = td;


        final populater = new MapDirectoryPopulater(source);
        return tempDir.populate(populater);
      })
      .then((TempDir value) {
        expect(value, equals(tempDir));
        return tempDir.verifyContents(target);
      })
      .then((bool expectTrue) {
        expect(expectTrue, shouldWork, reason: 'should match the provided map');
      })
      .then((_) {
        tempDir.dispose();
        expect(tempDir.dir.existsSync(), isFalse, reason: 'Temp dir should be deleted');
        tempDir = null;
      });
}
