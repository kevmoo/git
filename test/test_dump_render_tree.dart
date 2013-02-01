library test_dump_render_tree;

import 'dart:io';
import 'package:unittest/unittest.dart';

void main() {
  final browserTests = ['test/harness_browser.html'];

  group('DumpRenderTree', () {
    browserTests.forEach((file) {
      test(file, () {
        _runDrt(file);
      });
    });
  });
}

void _runDrt(String htmlFile) {
  final allPassedRegExp = new RegExp('All \\d+ tests passed');

  final future = Process.run('DumpRenderTree', [htmlFile])
    .then((ProcessResult pr) {
      expect(pr.exitCode, 0);
      expect(pr.stdout, matches(allPassedRegExp));
    });

  expect(future, completes);
}
