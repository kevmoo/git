library test_bot_io;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as pathos;
import 'package:bot_io/bot_io.dart';

part 'temp_dir_tests.dart';
part 'sha_file_tests.dart';
part 'entity_populater_tests.dart';
part 'update_directory_tests.dart';

void main() {
  group('bot_io', () {
    group('temp dir and validate', () {
      TempDirTests.register();
    });

    group('sha1 file tests', () {
      ShaFileTests.register();
    });

    group('EntityPopulator', () {
      _registerEntityPopulaterTests();
      _registerUpdateDirectoryTests();

      test('expandStream', () {
        var inputs = [7, 11, 13, 17, 19];

        return expandStream(_slowFromList(inputs), _fromNumber, onDone: _final)
            .toList()
            .then((List<int> items) {
              expect(items, orderedEquals(
                  [7, 14, 11, 22, 13, 26, 17, 34, 19, 38, 0, 1, 2, 3]));
            });
      });
    });
  });
}

Stream<int> _fromNumber(int input) =>
    _slowFromList([input, input * 2]);

Stream<int> _final() =>
    _slowFromList([0,1,2,3]);

Stream _slowFromList(List items) {
  var controller = new StreamController();

  Future.forEach(items, (item) {
    return new Future.delayed(new Duration(milliseconds: 2))
      .then((_) {
        controller.add(item);
      });
  }).whenComplete(controller.close);

  return controller.stream;
}
