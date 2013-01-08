library bot_git;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';

class GitDir {
  static final RegExp _shaRegExp = new RegExp(r'^[a-f0-9]{40}$');

  final Path _path;

  factory GitDir(String path) {
    return new GitDir.fromPath(new Path(path));
  }

  GitDir.fromPath(Path path) :
    this._path = path.canonicalize() {
    assert(new Directory.fromPath(_path).existsSync());
  }

  Path get path => _path;

  Future<List<String>> getBranches() {
    return _runGit(['ls-remote', _path.toNativePath()])
        .transform((ProcessResult pr) {
      assert(pr.exitCode == 0);
      return [];
    });
  }

  Future<Map<String, String>> writeObject(List<String> paths) {
    final args = ['hash-object', '-t', 'blob', '-w', '--no-filters', '--'];
    args.addAll(paths);
    return _doGit(args)
        .transform((ProcessResult pr) {
          final val = pr.stdout.trim();
          final shas = val.split(new RegExp(r'\s+'));
          assert(shas.length == paths.length);
          assert(shas.every((sha) => _shaRegExp.hasMatch(sha)));
          final map = new Map<String, String>();
          for(var i = 0; i < shas.length; i++) {
            map[paths[i]] = shas[i];
          }
          return map;
        });
  }

  Future<ProcessResult> _doGit(List<String> args, [bool throwOnError = true]) {
    var allArgs = ['--git-dir', _gitDirPath]
      ..addAll(args);
    return _runGit(allArgs, throwOnError);
  }

  String get _gitDirPath => _path.append('.git').toNativePath();

  static Future<GitDir> init(Directory source) {
    assert(source.existsSync());

    // first, verify it's empty
    return IoHelpers.isEmpty(source)
        .chain((bool isEmpty) {
          if(!isEmpty) {
            throw 'source Directory is not empty';
          }
          return _init(source);
        });
  }

  static Future<GitDir> _init(Directory source) {
    return _runGit(['init', source.path])
        .transform((ProcessResult pr) {
          return new GitDir(source.path);
        });
  }

  static Future<ProcessResult> _runGit(List<String> args, [bool throwOnError = true]) {
    return Process.run('git', args)
        .transform((ProcessResult pr) {
          if(throwOnError) {
            _throwIfProcessFailed(pr, 'git', args);
          }
          return pr;
        });
  }

  static void _throwIfProcessFailed(ProcessResult pr, String process, List<String> args) {
    assert(pr != null);
    if(pr.exitCode != 0) {
      throw new ProcessException('git', ['unknown'], pr.stderr.trim(), pr.exitCode);
    }
  }

}
