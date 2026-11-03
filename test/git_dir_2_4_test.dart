import 'dart:io';

import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test/scaffolding.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_utils.dart';

Future<GitDir> _repoWithCommit() async {
  final gitDir = await createTempGitDir(branchName: 'main');
  await gitDir.runCommand(['config', 'user.email', 'test@example.com']);
  await gitDir.runCommand(['config', 'user.name', 'Test']);
  await doDescriptorGitCommit(gitDir, {'a.txt': 'a'}, 'initial');
  return gitDir;
}

void main() {
  group('isWorkingTreeClean', () {
    test('includeUntracked controls untracked-file handling', () async {
      final gitDir = await _repoWithCommit();
      check(await gitDir.isWorkingTreeClean()).isTrue();

      await File(p.join(gitDir.path, 'untracked.txt')).writeAsString('u');
      check(await gitDir.isWorkingTreeClean()).isFalse();
      check(await gitDir.isWorkingTreeClean(includeUntracked: false)).isTrue();

      await File(p.join(gitDir.path, 'a.txt')).writeAsString('changed');
      check(await gitDir.isWorkingTreeClean(includeUntracked: false)).isFalse();
    });
  });

  test('isAncestor, commitsAheadBehind, deleteBranch', () async {
    final gitDir = await _repoWithCommit();
    await gitDir.runCommand(['checkout', '-q', '-b', 'feature']);
    await doDescriptorGitCommit(gitDir, {'b.txt': 'b'}, 'feature commit');

    check(await gitDir.isAncestor('main', 'feature')).isTrue();
    check(await gitDir.isAncestor('feature', 'main')).isFalse();

    final counts = await gitDir.commitsAheadBehind('feature', 'main');
    check(counts.ahead).equals(1);
    check(counts.behind).equals(0);

    await gitDir.runCommand(['checkout', '-q', 'main']);
    await gitDir.deleteBranch('feature', force: true);
    check(await gitDir.branchReference('feature')).isNull();
  });

  test('upstreamBranch, branchTracking, remoteDefaultBranch, fetch', () async {
    final origin = await _repoWithCommit();
    final clonePath = d.path('clone');
    await runGit(['clone', '-q', origin.path, clonePath]);
    final clone = await GitDir.fromExisting(clonePath);

    check(await clone.upstreamBranch('main')).equals('origin/main');
    check(await clone.remoteDefaultBranch()).equals('main');

    final tracking = await clone.branchTracking();
    check(tracking.single)
      ..has((b) => b.branchName, 'branchName').equals('main')
      ..has((b) => b.upstream, 'upstream').equals('refs/remotes/origin/main')
      ..has((b) => b.isUpstreamGone, 'isUpstreamGone').isFalse();

    await doDescriptorGitCommit(origin, {'c.txt': 'c'}, 'second');
    await clone.fetch();
    final counts = await clone.commitsAheadBehind('main');
    check(counts.behind).equals(1);
  });

  test('worktrees, isSecondaryWorktree, removeWorktree', () async {
    final gitDir = await _repoWithCommit();
    final wtPath = d.path('wt');
    await gitDir.runCommand(['worktree', 'add', '-q', '-b', 'wt', wtPath]);

    final entries = await gitDir.worktrees();
    check(entries).length.equals(2);
    check(entries.last.branch).equals('wt');

    check(await gitDir.isSecondaryWorktree()).isFalse();
    final wtGitDir = await GitDir.fromExisting(wtPath);
    check(await wtGitDir.isSecondaryWorktree()).isTrue();

    await gitDir.removeWorktree(wtPath);
    check(await gitDir.worktrees()).length.equals(1);
  });

  group('GitDir.fromExisting allowBare', () {
    test('rejects bare repos by default and accepts with allowBare', () async {
      final barePath = d.path('bare.git');
      await runGit(['init', '-q', '--bare', barePath]);

      await check(GitDir.fromExisting(barePath)).throws<ArgumentError>();
      final bare = await GitDir.fromExisting(barePath, allowBare: true);
      check(p.canonicalize(bare.path)).equals(
        p.canonicalize(await Directory(barePath).resolveSymbolicLinks()),
      );
    });
  });
}
