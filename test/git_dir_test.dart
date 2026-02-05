import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test/scaffolding.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'test_utils.dart';

void main() {
  test('populateBranch', _testPopulateBranch);

  test('getCommits', _testGetCommits, onPlatform: const {'windows': Skip()});

  test('createOrUpdateBranch', () async {
    const initialMasterBranchContent = {
      'master.md': 'test file',
      'lib/foo.txt': 'lib foo text',
      'lib/bar.txt': 'lib bar text',
    };

    final gitDir = await createTempGitDir();

    await doDescriptorGitCommit(
      gitDir,
      initialMasterBranchContent,
      'master files',
    );

    // get the treeSha for the new lib directory
    final branch = await gitDir.currentBranch();

    final commit = await gitDir.commitFromRevision(branch.sha);

    // sha for the new commit
    final newSha = await gitDir.createOrUpdateBranch(
      'test',
      commit.treeSha,
      'copy of master',
    );

    // validate there is one commit on 'test'
    // validate that the one commit has the right treeSha
    // validate it has the right message

    var treeItems = await gitDir.lsTree(newSha!);
    check(treeItems).length.equals(2);

    final libTreeEntry = treeItems.singleWhere((tree) => tree.name == 'lib');
    check(libTreeEntry.type).equals('tree');

    // do another update from the subtree sha
    final nextCommit = await gitDir.createOrUpdateBranch(
      'test',
      libTreeEntry.sha,
      'just the lib content',
    );

    final testCommitCount = await gitDir.commitCount('test');
    check(testCommitCount).equals(2);

    treeItems = await gitDir.lsTree(nextCommit!);
    check(treeItems).length.equals(2);

    check(
      treeItems.map((tree) => tree.name),
    ).unorderedEquals(['foo.txt', 'bar.txt']);
  });

  group('init', () {
    test('allowContent:false with content fails', () async {
      File(p.join(d.sandbox, 'testfile.txt')).writeAsStringSync('test content');

      await check(GitDir.init(d.sandbox)).throws<ArgumentError>();
    });

    group('existing git dir', () {
      setUp(() async {
        await createTempGitDir();
      });

      test('isWorkingTreeClean', () async {
        final gitDir = await GitDir.fromExisting(tempRepoPath);
        final isClean = await gitDir.isWorkingTreeClean();
        check(isClean).isTrue();
      });

      test('isGitDir is true', () async {
        final isGitDir = await GitDir.isGitDir(tempRepoPath);
        check(isGitDir).isTrue();
      });

      test('with allowContent:false fails', () {
        check(GitDir.init(tempRepoPath)).throws<ArgumentError>();
      });

      test('with allowContent:true fails', () {
        check(
          GitDir.init(tempRepoPath, allowContent: true),
        ).throws<ArgumentError>();
      });
    });
  });

  group('GitDir.fromExisting', () {
    late String subDirPath;

    setUp(() async {
      final gitDir = await createTempGitDir();
      subDirPath = p.join(gitDir.path, 'sub-dir');
      await Directory(subDirPath).create();
    });

    test('succeeds for root directory', () async {
      final gitDir = await GitDir.fromExisting(tempRepoPath);
      check(
        p.canonicalize(gitDir.path),
        because: 'The created `GitDir` will point to the root.',
      ).equals(p.canonicalize(tempRepoPath));
    });

    test('succeeds for symlink to root directory', () async {
      final linkToRepoDir = await Link(
        p.join(d.sandbox, 'link-to-repo'),
      ).create(tempRepoPath);
      final gitDir = await GitDir.fromExisting(linkToRepoDir.path);
      check(
        p.canonicalize(gitDir.path),
        because:
            'The created `GitDir` will point to the canonical resolved root.',
      ).equals(p.canonicalize(tempRepoPath));
    });

    test('fails for sub directories', () async {
      await check(GitDir.fromExisting(subDirPath)).throws<ArgumentError>();
    });

    test('succeeds for sub directories with `allowSubdirectory`', () async {
      final gitDir = await GitDir.fromExisting(
        subDirPath,
        allowSubdirectory: true,
      );

      check(
        p.canonicalize(gitDir.path),
        because: 'The created `GitDir` will point to the root.',
      ).equals(p.canonicalize(tempRepoPath));
    });

    group('with git submodule', () {
      late String tempRepo2Path;
      late String submoduleMountPathAbs;
      const submoduleMountPathRel = 'third-party/repo2_sub';

      setUp(() async {
        // these have to be redefined un setUp() each time because d.sandbox
        // changes with each test run.
        tempRepo2Path = d.path('repo2');
        submoduleMountPathAbs = p.join(tempRepoPath, submoduleMountPathRel);

        final parent = await GitDir.fromExisting(tempRepoPath);

        await Directory(tempRepo2Path).create(recursive: true);
        final child = await GitDir.init(tempRepo2Path);

        // the child repo must have something in it in order to add it
        // as a submodule
        await doDescriptorGitCommit(
          child,
          {'README.md': 'hello'},
          'initial commit',
        );

        // normally git doesn't allow us to create a submodule with a
        // "file://" remote. Setting "protocol.file.allow=always" allows
        // this temporarily, so our test can run without network dependencies.
        await parent.runCommand([
          '-c',
          'protocol.file.allow=always',
          'submodule',
          'add',
          child.path,
          submoduleMountPathRel,
        ]);
      });

      test('succeeds on valid submodule dir', () async {
        final submodule = await GitDir.fromExisting(submoduleMountPathAbs);
        check(
          p.canonicalize(submodule.path),
          because:
              'The created `GitDir` will point to the root of the submodule.',
        ).equals(p.canonicalize(submoduleMountPathAbs));

        check(
          p.isWithin(
            p.canonicalize(tempRepoPath),
            p.canonicalize(submodule.path),
          ),
          because: 'the submodule should always be inside the parent worktree',
        ).isTrue();
      });
    });
  });

  test('writeObjects', () async {
    final gitDir = await createTempGitDir();

    final branches = await gitDir.branches();
    check(branches, because: 'Should start with zero commits').isEmpty();

    final initialContentMap = {
      'file1.txt': 'content1',
      'file2.txt': 'content2',
    };

    await doDescriptorPopulate(tempRepoPath, initialContentMap);

    final paths = initialContentMap.keys
        .map((fileName) => p.join(tempRepoPath, fileName))
        .toList();

    final hashes = await gitDir.writeObjects(paths);
    check(hashes).deepEquals({
      paths[0]: 'dd954e7a4e1a62ff90c5a0709dce5928716535c1',
      paths[1]: 'db00fd65b218578127ea51f3dffac701f12f486a',
    });
  });

  group('BranchReference', () {
    test('isHead', () async {
      const initialMasterBranchContent = {
        'master.md': 'test file',
        'lib/foo.txt': 'lib foo text',
        'lib/bar.txt': 'lib bar text',
      };

      final gitDir = await createTempGitDir(branchName: 'master');

      await doDescriptorGitCommit(
        gitDir,
        initialMasterBranchContent,
        'master files',
      );

      final branch = await gitDir.currentBranch();
      check(branch.isHead).isFalse();
      check(branch.branchName).equals('master');
      check(branch.reference).equals('refs/heads/master');

      await gitDir.runCommand(['checkout', '--detach']);

      final detached = await gitDir.currentBranch();
      check(detached.isHead).isTrue();
      check(detached.branchName).equals('HEAD');
      check(detached.reference).equals('HEAD');
      check(detached.sha).equals(branch.sha);
    });
  });
}

Future<void> _testGetCommits() async {
  final commitText = [
    '',
    ' \t leading white space is okay, too',
    'first',
    'second',
    'third',
    'forth',
  ];

  String msgFromText(String txt) {
    if (txt.isNotEmpty && txt.trim() == txt) {
      return 'Commit for $txt\n\nnice\n\nhuh?';
    } else {
      return txt;
    }
  }

  final gitDir = await createTempGitDir();

  final branches = await gitDir.branches();
  check(branches).isEmpty();

  for (var commitStr in commitText) {
    final fileMap = <String, String>{};
    fileMap['$commitStr.txt'] = '$commitStr content';

    await doDescriptorGitCommit(gitDir, fileMap, msgFromText(commitStr));
  }

  final count = await gitDir.commitCount();
  check(count).equals(commitText.length);

  final commits = await gitDir.commits();

  check(commits).length.equals(commitText.length);

  final commitMessages = commitText.map(msgFromText).toList();

  final indexMap = <int, MapEntry<String, Commit>>{};

  for (var entry in commits.entries) {
    // index into the text for the message of this commit
    final commitMessageIndex = commitMessages.indexWhere(
      (element) => element == entry.value.message,
    );

    check(
      commitMessageIndex,
      because: 'a matching message should be found',
    ).isGreaterOrEqual(0);

    check(indexMap.keys).not((it) => it.contains(commitMessageIndex));
    indexMap[commitMessageIndex] = entry;
  }

  for (var entry in indexMap.entries) {
    if (entry.key > 0) {
      check(
        entry.value.value.parents,
      ).unorderedEquals([indexMap[entry.key - 1]!.key]);
    } else {
      check(entry.value.value.parents).isEmpty();
    }
  }
}

Future<void> _testPopulateBranch() async {
  const initialMasterBranchContent = {'master.md': 'test file'};

  const testContent1 = {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents',
    'file3.txt': 'not around very long',
  };

  const testContent2 = {
    'file1.txt': 'file 1 contents',
    'file2.txt': 'file 2 contents changed',
    'file4.txt': 'sorry, file3',
  };

  const testBranchName = 'the_test_branch';

  final gd1 = await createTempGitDir();

  await doDescriptorGitCommit(gd1, initialMasterBranchContent, 'master files');

  await _testPopulateBranchEmpty(gd1, testBranchName);

  await _testPopulateBranchWithContent(
    gd1,
    testBranchName,
    testContent1,
    'first commit!',
  );

  await _testPopulateBranchWithContent(
    gd1,
    testBranchName,
    testContent2,
    'second commit\n\nThis is some other content\nDoes this work?',
  );

  await _testPopulateBranchWithDupeContent(
    gd1,
    testBranchName,
    testContent2,
    'same content',
  );

  await _testPopulateBranchWithContent(gd1, testBranchName, testContent1, '''
3rd commit, content 1

With some new lines
and more messages''');

  await _testPopulateBranchEmpty(gd1, testBranchName);
}

Future<void> _testPopulateBranchEmpty(GitDir gitDir, String branchName) async {
  await check(
    _testPopulateBranchCore(gitDir, branchName, {}, 'empty?'),
  ).throws<GitError>(
    (it) => it.has((e) => e.message, 'message').equals('No files were added'),
  );
}

Future<MapEntry<Commit?, int>> _testPopulateBranchCore(
  GitDir gitDir,
  String branchName,
  Map<String, String> contents,
  String commitMessage,
) async {
  // figure out how many commits exist for the provided branch
  final branchRef = await gitDir.branchReference(branchName);

  int originalCommitCount;
  if (branchRef == null) {
    originalCommitCount = 0;
  } else {
    originalCommitCount = await gitDir.commitCount(branchRef.reference);
  }

  Directory? tempDir;
  try {
    final commit = await gitDir.updateBranch(
      branchName,
      (td) {
        // strictly speaking, users of this API should not hold on to TempDir
        // but this is for testing
        tempDir = td;

        return doDescriptorPopulate(tempDir!.path, contents);
      },
      commitMessage,
    );

    return MapEntry(commit, originalCommitCount);
  } finally {
    if (tempDir != null) {
      check(tempDir!.existsSync()).isFalse();
    }
  }
}

Future<void> _testPopulateBranchWithContent(
  GitDir gitDir,
  String branchName,
  Map<String, String> contents,
  String commitMessage,
) async {
  // figure out how many commits exist for the provided branch
  final pair = await _testPopulateBranchCore(
    gitDir,
    branchName,
    contents,
    commitMessage,
  );

  final returnedCommit = pair.key!;
  final originalCommitCount = pair.value;

  if (originalCommitCount == 0) {
    check(
      returnedCommit.parents,
      because: 'This should be the first commit',
    ).isEmpty();
  } else {
    check(returnedCommit.parents).length.equals(1);
  }

  check(returnedCommit, because: 'Commit should not be null').isNotNull();
  check(returnedCommit.message).equals(commitMessage);

  // new check to see if things are updated it gd1
  final branchRef = (await gitDir.branchReference(branchName))!;

  final commit = await gitDir.commitFromRevision(branchRef.reference);

  check(
    commit.content,
    because: 'content of queried commit should what was returned',
  ).equals(returnedCommit.content);

  final entries = await gitDir.lsTree(commit.treeSha);

  check(entries.map((te) => te.name)).unorderedEquals(contents.keys);

  final newCommitCount = await gitDir.commitCount(branchRef.reference);
  check(newCommitCount).equals(originalCommitCount + 1);
}

Future<void> _testPopulateBranchWithDupeContent(
  GitDir gitDir,
  String branchName,
  Map<String, String> contents,
  String commitMessage,
) async {
  // figure out how many commits exist for the provided branch
  final pair = await _testPopulateBranchCore(
    gitDir,
    branchName,
    contents,
    commitMessage,
  );

  final returnedCommit = pair.key;
  final originalCommitCount = pair.value;

  check(returnedCommit).isNull();
  check(
    originalCommitCount,
    because: 'must have had some original content',
  ).isGreaterThan(0);

  // new check to see if things are updated it gd1
  final br = (await gitDir.branchReference(branchName))!;

  final newCommitCount = await gitDir.commitCount(br.reference);

  check(
    newCommitCount,
    because: 'no change in commit count',
  ).equals(originalCommitCount);
}
