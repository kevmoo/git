library test_bot_io;

import 'dart:async';
import 'package:unittest/unittest.dart';

import 'temp_dir_tests.dart' as temp_dir;
import 'update_directory_tests.dart' as update_directory;

import 'sha_file_tests.dart' as sha;
import 'entity_populater_tests.dart' as entity_populater;

void main() {
  group('bot_io', () {
    group('temp dir and validate', temp_dir.main);

    group('sha1 file tests', sha.main);

    group('EntityPopulator', () {
      entity_populater.main();
      update_directory.main();
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
