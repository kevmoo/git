library test_bot_io;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/bot_test.dart';

void register() {
  group('bot_io', () {
    test('temp dir populate', _testTempDirPopulate);
  });
}

void _testTempDirPopulate() {
  final map = {'file1.txt': 'content',
               'file2.txt': 'content2',
               'empty dir': {
               },
               'dir1': {
                 'dir1_file1.txt': 'and content some more'
               }
  };

  final future = TempDir.create().then((TempDir td) {
    assert(_tempDir == null);
    _tempDir = td;


    final populater = new MapDirectoryPopulater(map);
    return _tempDir.populate(populater);
  });

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
  final futures = maps.mappedBy(_tempDir.verifyContents);

  // every one should return false
  final aggregateFuture = Future.wait(futures).then((list) => list.every((match) => !match));

  expectFutureComplete(aggregateFuture, (val) => _testTempDirPopulate4(val, fileMap));
}

void _testTempDirPopulate4(bool expectTrue, Map fileMap) {
  expect(expectTrue, isTrue);

  _tempDir.dispose();
  expect(_tempDir.dir.existsSync(), isFalse, reason: 'Temp dir should be deleted');
  _tempDir = null;
}

TempDir _tempDir;
