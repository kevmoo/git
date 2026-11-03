import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('WorktreeEntry.fromPorcelain', () {
    test('parses main, linked, detached, locked, and bare entries', () {
      const porcelain = '''
worktree /repo
HEAD bcd1284d805951a16e765cea5b2273a464ee2d86
branch refs/heads/main

worktree /repo-feature
HEAD 0123456789abcdef0123456789abcdef01234567
branch refs/heads/feature/x
locked busy on usb drive

worktree /repo-detached
HEAD fedcba9876543210fedcba9876543210fedcba98
detached
locked

worktree /bare.git
bare
''';
      final entries = WorktreeEntry.fromPorcelain(porcelain);
      check(entries).length.equals(4);

      check(entries[0])
        ..has((e) => e.path, 'path').equals('/repo')
        ..has((e) => e.branch, 'branch').equals('main')
        ..has((e) => e.isLocked, 'isLocked').isFalse();

      check(entries[1])
        ..has((e) => e.branch, 'branch').equals('feature/x')
        ..has((e) => e.isLocked, 'isLocked').isTrue()
        ..has((e) => e.lockReason, 'lockReason').equals('busy on usb drive');

      check(entries[2])
        ..has((e) => e.isDetached, 'isDetached').isTrue()
        ..has((e) => e.branch, 'branch').equals('')
        ..has((e) => e.isLocked, 'isLocked').isTrue()
        ..has((e) => e.lockReason, 'lockReason').isNull();

      check(entries[3])
        ..has((e) => e.isBare, 'isBare').isTrue()
        ..has((e) => e.sha, 'sha').isNull();
    });

    test('handles CRLF and missing trailing blank line', () {
      final entries = WorktreeEntry.fromPorcelain(
        'worktree /a\r\nHEAD abc\r\nbranch refs/heads/main',
      );
      check(entries).length.equals(1);
      check(entries.single.branch).equals('main');
    });

    test('returns empty list for empty output', () {
      check(WorktreeEntry.fromPorcelain('')).isEmpty();
    });
  });

  group('BranchTracking.fromForEachRefOutput', () {
    test('parses tracked, gone, and untracked branches', () {
      const output =
          'main\trefs/remotes/origin/main\t\tabc1234\n'
          'old\trefs/remotes/origin/old\t[gone]\tdef5678\n'
          'local\t\t\t0123abc\n';
      final branches = BranchTracking.fromForEachRefOutput(output);
      check(branches).length.equals(3);
      check(branches[0])
        ..has((b) => b.branchName, 'branchName').equals('main')
        ..has((b) => b.isUpstreamGone, 'isUpstreamGone').isFalse();
      check(branches[1].isUpstreamGone).isTrue();
      check(branches[2].upstream).equals('');
    });
  });
}
