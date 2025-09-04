import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
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
    expect(treeItems, hasLength(2));

    final libTreeEntry = treeItems.singleWhere((tree) => tree.name == 'lib');
    expect(libTreeEntry.type, 'tree');

    // do another update from the subtree sha
    final nextCommit = await gitDir.createOrUpdateBranch(
      'test',
      libTreeEntry.sha,
      'just the lib content',
    );

    final testCommitCount = await gitDir.commitCount('test');
    expect(testCommitCount, 2);

    treeItems = await gitDir.lsTree(nextCommit!);
    expect(treeItems, hasLength(2));

    expect(
      treeItems.map((tree) => tree.name),
      unorderedEquals(['foo.txt', 'bar.txt']),
    );
  });

  group('init', () {
    test('allowContent:false with content fails', () async {
      File(p.join(d.sandbox, 'testfile.txt')).writeAsStringSync('test content');

      expect(GitDir.init(d.sandbox), throwsArgumentError);
    });

    group('existing git dir', () {
      setUp(() async {
        await createTempGitDir();
      });

      test('isWorkingTreeClean', () async {
        final gitDir = await GitDir.fromExisting(tempRepoPath);
        final isClean = await gitDir.isWorkingTreeClean();
        expect(isClean, isTrue);
      });

      test('isGitDir is true', () async {
        final isGitDir = await GitDir.isGitDir(tempRepoPath);
        expect(isGitDir, isTrue);
      });

      test('with allowContent:false fails', () {
        expect(GitDir.init(tempRepoPath), throwsArgumentError);
      });

      test('with allowContent:true fails', () {
        expect(
          GitDir.init(tempRepoPath, allowContent: true),
          throwsArgumentError,
        );
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
      expect(
        p.canonicalize(gitDir.path),
        p.canonicalize(tempRepoPath),
        reason: 'The created `GitDir` will point to the root.',
      );
    });

    test('succeeds for symlink to root directory', () async {
      final linkToRepoDir =
          await Link(p.join(d.sandbox, 'link-to-repo')).create(tempRepoPath);
      final gitDir = await GitDir.fromExisting(linkToRepoDir.path);
      expect(
        p.canonicalize(gitDir.path),
        p.canonicalize(tempRepoPath),
        reason: 'The `GitDir` will point to the canonical resolved root.',
      );
    });

    test('fails for sub directories', () async {
      expect(
        () => GitDir.fromExisting(subDirPath),
        throwsArgumentError,
      );
    });

    test('succeeds for sub directories with `allowSubdirectory`', () async {
      final gitDir = await GitDir.fromExisting(
        subDirPath,
        allowSubdirectory: true,
      );

      expect(
        p.canonicalize(gitDir.path),
        p.canonicalize(tempRepoPath),
        reason: 'The created `GitDir` will point to the root.',
      );
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
        expect(
          p.canonicalize(submodule.path),
          p.canonicalize(submoduleMountPathAbs),
          reason:
              'The created `GitDir` will point to the root of the submodule.',
        );
        expect(
          p.isWithin(
            p.canonicalize(tempRepoPath),
            p.canonicalize(submodule.path),
          ),
          true,
          reason: 'the submodule should always be inside the parent worktree',
        );
      });
    });
  });

  test('writeObjects', () async {
    final gitDir = await createTempGitDir();

    final branches = await gitDir.branches();
    expect(branches, isEmpty, reason: 'Should start with zero commits');

    final initialContentMap = {
      'file1.txt': 'content1',
      'file2.txt': 'content2',
    };

    await doDescriptorPopulate(tempRepoPath, initialContentMap);

    final paths = initialContentMap.keys
        .map((fileName) => p.join(tempRepoPath, fileName))
        .toList();

    final hashes = await gitDir.writeObjects(paths);
    expect(hashes, hasLength(initialContentMap.length));
    expect(hashes.keys, unorderedEquals(paths));

    expect(paths[0], endsWith('file1.txt'));
    expect(
      hashes,
      containsPair(paths[0], 'dd954e7a4e1a62ff90c5a0709dce5928716535c1'),
    );

    expect(paths[1], endsWith('file2.txt'));
    expect(
      hashes,
      containsPair(paths[1], 'db00fd65b218578127ea51f3dffac701f12f486a'),
    );
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
      expect(branch.isHead, isFalse);
      expect(branch.branchName, 'master');
      expect(branch.reference, 'refs/heads/master');

      await gitDir.runCommand(
        ['checkout', '--detach'],
      );

      final detached = await gitDir.currentBranch();
      expect(detached.isHead, isTrue);
      expect(detached.branchName, 'HEAD');
      expect(detached.reference, 'HEAD');
      expect(detached.sha, branch.sha);
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
  expect(branches, isEmpty);

  for (var commitStr in commitText) {
    final fileMap = <String, String>{};
    fileMap['$commitStr.txt'] = '$commitStr content';

    await doDescriptorGitCommit(gitDir, fileMap, msgFromText(commitStr));
  }

  final count = await gitDir.commitCount();
  expect(count, commitText.length);

  final commits = await gitDir.commits();

  expect(commits, hasLength(commitText.length));

  final commitMessages = commitText.map(msgFromText).toList();

  final indexMap = <int, MapEntry<String, Commit>>{};

  for (var entry in commits.entries) {
    // index into the text for the message of this commit
    final commitMessageIndex =
        commitMessages.indexWhere((element) => element == entry.value.message);

    expect(
      commitMessageIndex,
      greaterThanOrEqualTo(0),
      reason: 'a matching message should be found',
    );

    expect(indexMap, isNot(contains(commitMessageIndex)));
    indexMap[commitMessageIndex] = entry;
  }

  for (var entry in indexMap.entries) {
    if (entry.key > 0) {
      expect(
        entry.value.value.parents,
        unorderedEquals([indexMap[entry.key - 1]!.key]),
      );
    } else {
      expect(entry.value.value.parents, hasLength(0));
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

  _testPopulateBranchEmpty(gd1, testBranchName);

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

  await _testPopulateBranchWithContent(
    gd1,
    testBranchName,
    testContent1,
    '''
3rd commit, content 1

With some new lines
and more messages''',
  );

  _testPopulateBranchEmpty(gd1, testBranchName);
}

void _testPopulateBranchEmpty(GitDir gitDir, String branchName) {
  expect(
    _testPopulateBranchCore(gitDir, branchName, {}, 'empty?'),
    throwsA(
      isA<GitError>()
          .having((ge) => ge.message, 'message', 'No files were added'),
    ),
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
      expect(tempDir!.existsSync(), false);
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
    expect(
      returnedCommit.parents,
      isEmpty,
      reason: 'This should be the first commit',
    );
  } else {
    expect(returnedCommit.parents, hasLength(1));
  }

  expect(returnedCommit, isNotNull, reason: 'Commit should not be null');
  expect(returnedCommit.message, commitMessage);

  // new check to see if things are updated it gd1
  final branchRef = (await gitDir.branchReference(branchName))!;

  final commit = await gitDir.commitFromRevision(branchRef.reference);

  expect(
    commit.content,
    returnedCommit.content,
    reason: 'content of queried commit should what was returned',
  );

  final entries = await gitDir.lsTree(commit.treeSha);

  expect(entries.map((te) => te.name), unorderedEquals(contents.keys));

  final newCommitCount = await gitDir.commitCount(branchRef.reference);
  expect(newCommitCount, originalCommitCount + 1);
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

  expect(returnedCommit, isNull);
  expect(
    originalCommitCount,
    greaterThan(0),
    reason: 'must have had some original content',
  );

  // new check to see if things are updated it gd1
  final br = (await gitDir.branchReference(branchName))!;

  final newCommitCount = await gitDir.commitCount(br.reference);

  expect(
    newCommitCount,
    originalCommitCount,
    reason: 'no change in commit count',
  );
}
