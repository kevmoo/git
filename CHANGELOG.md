## v0.4.4+2

* Internal refactoring.

## v0.4.4+1

* Run `git` in the shell – trying to address issues on Windows.

## v0.4.4

* Use `which` package to try harder to find `git` executable.

## v0.4.3

* `GitDir` added `updateBranchWithDirectoryContents`.

## v0.4.2

* Migrated code to Dart 1.9 `async`.

* Improved testing.

## v0.4.1+2

* Updated max version of `bot` dependency.

## v0.4.1+1

* Updated `hop` and added `hop_unittest` dev dependencies.

## v0.4.1 - 2014-05-06

 * Tweaks to `Commit` to stop using deperecated APIs from `bot`.
 * Updated constraint on `bot` package.

## v0.4.0 - 2014-04-12
 * Made fields on `TreeEntry` final.
 * A lot of source clean up.

## v0.3.0 - 2014-03-17
 * **BREAKING** `PopulateTempDir` typedef.
 * **BREAKING** `GitDir.populateBranch` - moving away from `TempDir` from `bot_io`
 * Removed a number of package dependencies

## v0.2.1+1 - 2014-03-16
 * Moved `scheduled_test` dependency to `dev_dependencies`

## v0.2.1 - 2014-03-16
 * **Deprecated** `PopulateTempDir` typedef.
 * **Deprecated** `GitDir.populateBranch` - moving away from `TempDir` from `bot_io`
 * **NEW!** `GitDir.updateBranch` like `populateBranch`, but exposes a `Directory`

## v0.2.0 - 2014-03-04
 * Supporting next release of `bot_io`
 * Fixed `hop_runner`
 * Removed deprecated `Git` class.

## v0.1.0 - 2014-02-15
 * First release
 * Maintains 100% compatibility with the `bot_git` library from the `bot_io`
   package as of release `0.25.1+2`.
