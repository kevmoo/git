part of test_bot_io;

Future _testTempDirPopulate() {
  final map = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
               },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
  };


  final mapFewer = {'file1.txt': 'content',
               'empty dir': {
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  final mapMore = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
                 'file3.txt': 'content3'
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  final mapDiff = {'file1.txt': 'content_',
               'file2.txt': 'content2',
               'empty dir': {
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  final mapEmpty = {};

  final badMatchMaps = [mapFewer, mapMore, mapDiff, mapEmpty];


  TempDir tempDir = null;


  return TempDir.create()
      .then((TempDir td) {
        assert(tempDir == null);
        tempDir = td;


        final populater = new MapDirectoryPopulater(map);
        return tempDir.populate(populater);
      })
      .then((TempDir value) {
        expect(value, equals(tempDir));
        return tempDir.verifyContents(map);
      })
      .then((bool expectTrue) {
        expect(expectTrue, isTrue, reason: 'should match the provided map');

        return Future.forEach(badMatchMaps, (m) {
          return tempDir.verifyContents(m)
              .then((bool isMatch) {
                expect(isMatch, isFalse);
              });
        });
      })
      .then((_) {

        tempDir.dispose();
        expect(tempDir.dir.existsSync(), isFalse, reason: 'Temp dir should be deleted');
        tempDir = null;
      });
}
