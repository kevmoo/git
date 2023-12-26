
import 'package:git/git.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {

  test('Parse lightweight tag', () async {
    final testDir = await createTempGitDir();

    final contents = <String, String>{
      'something': 'value'
    };

    await doDescriptorGitCommit(testDir, contents, 'Something');
    final branchRef = await testDir.currentBranch();

    await runGit(['tag', 'newTag', branchRef.sha],
        processWorkingDir: testDir.path,);

    final tagsFound = await testDir.tags().length;
    expect(tagsFound, equals(1));
  });

  test('Parse annotated tag', () async {
    final testDir = await createTempGitDir();

    final contents = <String, String>{
      'something': 'value'
    };

    await doDescriptorGitCommit(testDir, contents, 'Something');
    final branchRef = await testDir.currentBranch();

    await runGit(['tag', '--annotate', '--message', 'First tag', 'newTag',
      branchRef.sha],
        processWorkingDir: testDir.path,);

    await runGit(['tag', '--annotate', '--message', 'First tag', 'anotherTag',
      branchRef.sha],
        processWorkingDir: testDir.path,);

    final tagsFound = await testDir.tags().length;
    expect(tagsFound, equals(2));
  });
}