import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test_descriptor/test_descriptor.dart' as d;

Future<GitDir> createTempGitDir({String? branchName}) =>
    GitDir.init(d.sandbox, initialBranch: branchName);

Future<void> doDescriptorGitCommit(
  GitDir gd,
  Map<String, String> contents,
  String commitMsg,
) async {
  await doDescriptorPopulate(gd.path, contents);

  // now add this new file
  await gd.runCommand(['add', '--all']);

  // now commit these silly files
  final args = [
    'commit',
    '--cleanup=verbatim',
    '--no-edit',
    '--allow-empty-message',
  ];
  if (commitMsg.isNotEmpty) {
    args.addAll(['-m', commitMsg]);
  }

  await gd.runCommand(args);
}

Future<void> doDescriptorPopulate(
  String dirPath,
  Map<String, String> contents,
) async {
  for (var name in contents.keys) {
    final value = contents[name]!;

    final fullPath = p.join(dirPath, name);

    final file = File(fullPath);
    await file.create(recursive: true);
    await file.writeAsString(value);
  }
}
