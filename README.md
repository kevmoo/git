[![Pub Package](https://img.shields.io/pub/v/git.svg)](https://pub.dev/packages/git)
[![CI](https://github.com/kevmoo/git/actions/workflows/ci.yml/badge.svg)](https://github.com/kevmoo/git/actions/workflows/ci.yml)

Exposes a Git directory abstraction that makes it easy to inspect and manipulate
a local Git repository.

```dart
import 'package:git/git.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  print('Current directory: ${p.current}');

  if (await GitDir.isGitDir(p.current)) {
    final gitDir = await GitDir.fromExisting(p.current);
    final commitCount = await gitDir.commitCount();
    print('Git commit count: $commitCount');
  } else {
    print('Not a Git directory');
  }
}
```
