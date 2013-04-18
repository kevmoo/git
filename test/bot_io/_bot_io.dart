library test_bot_io;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:bot_io/bot_io.dart';
import 'package:bot/bot_test.dart';
import 'completion_tests_args.dart';

part 'completion_tests.dart';
part 'temp_dir_tests.dart';

void main() {
  group('bot_io', () {
    group('temp dir and validate', () {
      TempDirTests.register();
    });

    _registerCompletionTests();
  });
}
