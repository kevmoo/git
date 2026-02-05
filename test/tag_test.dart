import 'package:checks/checks.dart';
import 'package:git/git.dart';
import 'package:test/scaffolding.dart';

import 'test_utils.dart';

void main() {
  test('Parse lightweight tag', () async {
    final testDir = await createTempGitDir();
    final contents = <String, String>{'something': 'value'};
    const givenTagName = 'newTag';

    await doDescriptorGitCommit(testDir, contents, 'Something');
    final branchRef = await testDir.currentBranch();

    await runGit([
      'tag',
      givenTagName,
      branchRef.sha,
    ], processWorkingDir: testDir.path);

    final foundTag = (await testDir.tags().toList()).single;
    check(foundTag.tag).equals(givenTagName);
  });

  test('Parse annotated tag', () async {
    final testDir = await createTempGitDir();
    final contents = <String, String>{'something': 'value'};
    const newTagName = 'newTag';
    const anotherTagName = 'anotherTag';

    await doDescriptorGitCommit(testDir, contents, 'Something');
    final branchRef = await testDir.currentBranch();

    await runGit([
      'tag',
      '--annotate',
      '--message',
      'First tag',
      newTagName,
      branchRef.sha,
    ], processWorkingDir: testDir.path);

    await runGit([
      'tag',
      '--annotate',
      '--message',
      'Second tag',
      anotherTagName,
      branchRef.sha,
    ], processWorkingDir: testDir.path);

    final tagsFound = await testDir.tags().toList();
    check(tagsFound).length.equals(2);

    final alphabeticallyFirstTag = tagsFound.first;
    check(alphabeticallyFirstTag)
      ..has((t) => t.tag, 'tag').equals(anotherTagName)
      ..has((t) => t.objectSha, 'objectSha').equals(branchRef.sha)
      ..has((t) => t.type, 'type').equals('commit');
  });
}
