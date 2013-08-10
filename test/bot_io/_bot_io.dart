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
    });
  });
}
