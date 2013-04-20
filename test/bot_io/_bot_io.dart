library test_bot_io;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:pathos/path.dart' as pathos;
import 'package:bot_io/bot_io.dart';
import 'package:bot/bot_test.dart';
import 'completion_tests_args.dart';

part 'completion_tests.dart';
part 'temp_dir_tests.dart';
part 'sha_file_tests.dart';

void main() {
  group('bot_io', () {
    group('temp dir and validate', () {
      TempDirTests.register();
    });

    _registerCompletionTests();

    group('sha1 file tests', () {
      ShaFileTests.register();
    });
  });
}
