library test_bot_io;

import 'package:unittest/unittest.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/bot_test.dart';

void register() {
  group('bot_io', () {
    test('temp dir populate', _testTempDirPopulate);
  });
}

void _testTempDirPopulate() {
  assert(_tempDir == null);
  _tempDir = new TempDir();

  final map = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
                 },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
               };

  final populater = new MapDirectoryPopulater(map);
  final future = _tempDir.populate(populater);

  expectFutureComplete(future, (value) => _testTempDirPopulate2(value, map));
}

void _testTempDirPopulate2(value, Map fileMap) {
  expectFutureComplete(_tempDir.verifyContents(fileMap),
      (bool matches) => _testTempDirPopulate3(matches, fileMap));
}

void _testTempDirPopulate3(bool expectTrue, Map fileMap) {
  expect(expectTrue, isTrue, reason: 'should match the provided map');

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

  final maps = [mapFewer, mapMore, mapDiff, mapEmpty];
  final futures = maps.map(_tempDir.verifyContents);

  // every one should return false
  final aggregateFuture = Futures.wait(futures).transform((list) => list.every((match) => !match));

  expectFutureComplete(aggregateFuture, (val) => _testTempDirPopulate4(val, fileMap));
}

void _testTempDirPopulate4(bool expectTrue, Map fileMap) {
  expect(expectTrue, isTrue);

  _tempDir.dispose();
}

TempDir _tempDir;
