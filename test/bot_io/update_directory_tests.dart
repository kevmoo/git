library test.bot_io.update_directory;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as pathos;
import 'package:bot_io/bot_io.dart';

void main() {

  var m1 = {
            'foo':'foo',
            'bar':'foo',
            'sub': 'not a dir'
  };

  var m2 = {
            'bar': 'bar',
            'baz': 'baz',
            'sub': { 'sub':'sub'}
  };

  var m3 = {
            'foo': 'foo',
            'bar': 'bar',
            'baz': 'baz',
            'sub': {'sub':'sub' }
  };

  test("merge map internal", () {
    expect(m1, isNot(equals(m2)));
    expect(m1, isNot(equals(m3)));
    expect(m2, isNot(equals(m3)));

    var merge = _mergeMaps(m1, m2);

    expect(merge, equals(m3));

  });

  test('updateDirectory', () {
    return _testUpdateDirectory(m1, m2, m3);
  });
}

Future _testUpdateDirectory(dynamic originalContent, dynamic updateContent,
                            dynamic verifyContent) {

  TempDir tempDir;

  return TempDir.create()
      .then((TempDir value) {
        tempDir = value;

        return EntityPopulater.populate(tempDir.path, originalContent,
            overwriteExisting: true);
      })
      .then((_) {
        return tempDir.verifyContents(originalContent);
      })
      .then((bool isMatch) {
        expect(isMatch, isTrue);

        var nonPath = pathos.join(tempDir.path, 'no_here');

        return EntityPopulater.updateDirectory(nonPath, updateContent);
      })
      .catchError((error) {
        expect(error is EntityPopulatorException, isTrue,
            reason: 'should throw error for non existant dir');
      })
      .then((_) {

        return EntityPopulater.updateDirectory(tempDir.path, updateContent);
      })
      .then((_) {

        return tempDir.verifyContents(verifyContent);
      })
      .then((bool isMatch) {
        expect(isMatch, isTrue);
      })
      .whenComplete(() {
        if(tempDir != null) {
          return tempDir.dispose();
        }
      });
}

/**
 * Contents in [m2] 'win' over contents of [m1]
 */
Map _mergeMaps(Map m1, [Map m2 = null]) {
  assert(m1 != null);

  var m1Keys = new Set.from(m1.keys);
  var m2Keys = m2 == null ? new Set() : new Set.from(m2.keys);

  var map = {};

  var m1onlyKeys = m1Keys.difference(m2Keys);
  for(var k in m1onlyKeys) {
    var v = m1[k];
    if(v is Map) {
      v = _mergeMaps(v);
    }
    map[k] = v;
  }

  for(var k in m2Keys) {
    var v = m2[k];
    if(v is Map) {
      v = _mergeMaps(v);
    }
    map[k] = v;
  }

  assert(map.values.every((v) => v != null));

  return map;
}
