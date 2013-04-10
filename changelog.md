# Changelog - Dart Bag of Tricks

## 0.20.0-dev *pre-release*

* The big [HOP](https://github.com/kevmoo/hop.dart) migration.

## 0.16.3+1 2013-04-09 (SDK 0.4.5+1 r21094)

* [Changes Since v0.16.2](https://github.com/kevmoo/bot.dart/compare/v0.16.2...v0.16.3.1)

* Tiny cleanup. Moved to latest SDK rev.

## 0.16.2 2013-04-03 (SDK 0.4.4+4 r20810)

* [Changes Since v0.16.1](https://github.com/kevmoo/bot.dart/compare/v0.16.1...v0.16.2)

### bot
* `Sequence` learned `itemsEqual`
* `StringLineReader` learned `bool get eof` and `String peekNextLine()`

## 0.16.1 2013-03-25 (SDK 0.4.3+1 r20444)

* [Changes Since v0.16.0](https://github.com/kevmoo/bot.dart/compare/v0.16.0...v0.16.1)
* Tiny tweaks to support changes in Canvas

## 0.16.0 2013-03-19 (SDK 0.4.2.5 r20193)

* [Changes Since v0.15.0.2](https://github.com/kevmoo/bot.dart/compare/v0.15.0.2...v0.16.0)
* Fixes for changes in `String`, `Iterable` and `dart:html`.

### bot

* __BREAKING__ Removed a number of deprecated APIs from `Enumerable`.
* __BREAKING__ Replaced `ListBase` with `Sequence`. Sequence does not implement `List`,
but it does have an get indexer `[int index]`.

### hop_tasks

* The unit test task logs a few more things.

## 0.15.0+2 2013-03-12 (SDK 0.4.1.0 r19425)

### hop_tasks

* Fixed `dart2js` and `dart_analyzer` task on Windows

## 0.15.0+1 2013-03-11 (SDK 0.4.1.0 r19425)

### hop_tasks

* Fixed `dartdoc` task on Windows

## 0.15.0 2013-03-06 (SDK 0.4.1.0 r19425)

* [Changes Since v0.14.2](https://github.com/kevmoo/bot.dart/compare/v0.14.2...v0.15.0)

### bot

* Many changes related to using `Stream` for events
    * `AttachedEvent`
        * __BREAKING__ `addHandler` -> `getStream`
        * Learned `bool hasSubscribers`
    * `EventHandle`
        * Now extends `StreamController` from `dart:async`
        * __BREAKING__ removed `fireEvent`, `add`, `remove`
    * __BREAKING__ `EventRoot` removed.
    * __BREAKING__ `GlobalId` removed.
    * `Property`
        * __BREAKING__ `addhandler` -> `getStream`
        * __BREAKING__ `removeHandler` removed
        * __BREAKING__ Change events are now of __NEW!__ type `PropertyChangedEventArgs`

### bot_async

* `FutureValue`
    * __BREAKING__ `outputChanged`, `inputChanged`, `error` are all now `Stream`

### bot_html

* `Dragger`
    * __BREAKING__ `dragStart` and `dragDelta` are now `Stream`
* `ResourceLoader`
    * __BREAKING__ `progress` and `loaded` are now `Stream`

### bot_io

* `AnsiColor`
    * __NEW!__ Supports bold text
    * __NEW!__ `BOLD` and `RESET` consts
    * __NEW!__ `instance.asBold()` method

* `Console`
    * __NEW!__ `static bool get supportsColor`: An initial attempt to let console apps know if the host console supports color output via a call to `String format(bool useColor)`

* __NEW!__ `ShellString`
    * A `String`-like value that stores a value and an `AnsiColor`.
    * Allows centralized creation of text to be sent to the shell with the option to output with our without ANSI escape codes.

### bot_retained

* `MouseManager`
    * expose `cursorProperty`
    * __BREAKING__ All events are now `Stream`-based
    * __BREAKING__ cursor logic no longer sets the `cursor` style on the target `CanvasElement`.
* __BREAKING__ `Thing`, `ThingParent` and `Stage` `invalidated` now `Stream`

### bot_texture

* `TextureAnimationRequest.started` is now `Stream`

### hop

* __BREAKING__ `getHelpTask` has been removed. Now a config option on `runHop`
* `RootTaskContext`
    * __BREAKING__ constructor now has a mandatory argument `Printer`
    * __BREAKING__ `log` changed signature to take an `Object` instead of `String`. `color` argument removed.
    * __BREAKING__ `printCore` removed
* __BREAKING__ `Runner` is now completely static. All state is stored and passed in via new `HopConfig` class.
* `TaskLogger` learned `finest`, `finer`, and `config` log levels.
* __BREAKING__ `HopConfig` was renamed `TaskRegistry`. A lot of members were hidden.

### hop_tasks

* __dartdoc__
    * __NEW!__ `createDartDocTask` method that returns a `Task`. Supports `postBuild` option. Smart defaults.
    * __DEPRECATED__ `getCompileDocsFunc` and `compileDocs`

## 0.14.2 - 25 Feb 2013 (SDK 0.4.0.0 r18915)

* [Changes Since v0.14.1](https://github.com/kevmoo/bot.dart/compare/v0.14.1...v0.14.2)
* Bumped minimum Dart SDK version to __0.4.0.0 r18915__
* Updated core dart packages to `>= 0.4.0+0`

### hop

* Renamed `BaseConfig` to `HopConfig`. `BaseConfig` is new deprecated.
* `HopConfig` learned `doPrint`. Unifying all printing within hop to allow better redirection.

### hop_tasks

* The unit test task logic has a new, cleaner `Configuration` class.

## 0.14.1 - 23 Feb 2013 (SDK 0.3.7.6 r18717)

* [Changes Since v0.14.0](https://github.com/kevmoo/bot.dart/compare/v0.14.0...v0.14.1)

### bot

* Added `requiresArgumentContainsPattern`, which deprecates `requiresArgumentMatches`.

### hop

* Support task names that contain (but don't start with) '-'

### hop_tasks

* `bench` - Output all final results as Duration. Include Standard Error.
* `dart2js` - Added `createDart2JsTask` method.

### Shell Completion Script

* added symlink `bin/shell-completion-generator` that points to `bin/shell_completion_generator.dart`
* Removed export of `COMP_WORDBREAKS` in completion script. No need to mess with these values.
* Generates script for multiple command names

## 0.14.0 - 20 Feb 2013 (SDK 0.3.7.6 r18717)

* [Changes Since v0.13.1](https://github.com/kevmoo/bot.dart/compare/v0.13.1...v0.14.0)
* Bumped minimum Dart SDK version to __0.3.7.6 r18717__
* Updated core dart packages to `>= 0.3.7+6`
* Removed `vendor/dart.js`. Using version from `browser` package
* Moved examples into library-specific directories.
* __NEW!__ `bin/shell_completion_generator.dart` for creating shell completion scripts compatible with completion logic in `bot_io`

### bot

* `Enumerable` learned `expand` and deprecated `selectMany`. Better alignment with `Iterable`
* __NEW!__ `requireArgumentMatches` - match an argument against a `Pattern` (`String` or `RegExp`)

### bot_async

* __NEW!__ `getDelayedResult`. See the docs. It's fun.

### bot_git

* __NEW!__ `requireArgumentValidSha1` - lot's of SHA1 hashes flying around. Nice helper.
* __NEW!__ `Tag` class. Represents info in a Git tag object.
* `GitDir`
    * __NEW!__ `getCommits`, `getTags`, `showRef`, `showOrUpdateBranch`,
    `commitTree`

### bot_html

* __DEPRECATED__ and fixed `getTimeoutFuture`

### bot_io

* __NEW!__ `enableScriptLogListener` - an easy way to write all log output to disk.
* __NEW!__ A whole set of new features around shell command completion.
    * See example in `example/bot_io/completion/`

### hop

* __BREAKING__ Renamed all completion scripts to extension `.sh`. Breaks folks who may be sourcing `tool/hop-completion.bash`
* `Task`
    * __BREAKING__ `description` argument to `Task` constructors is now named (not positional) 
    * __NEW!__ Easy to wire up `ArgParser` to allow completion of task flags.
    * __NEW!__ Can provide `List<TaskArgument> extendedArgs` to fully document command line usage.
* __BREAKING!__ `ConsoleContext` ctor now takes ArgResults and a Task.
* __DEPRECATED__ `TaskFailError`. Use `TaskContext.fail` instead
* __NEW!__ Added `getHelpTask()` which allows `hop help <command name>`
* Updated `bin/hop` shell script to pass quoted params fully and accurately to `hop_runner.dart`
* Exposed `Runner.runTask`.
* `RunResult` now has a descriptive `toString`
* Moved core hop command completion logic to new `bot_io` completion helpers.

### hop_tasks

* __All__ - using new `Task` features to document flags and arguments
* __dartdoc Task__ - added optional `excludeLibs` and `linkApi` flags.
* __Git Tasks__ - added `getBranchForDirTask` method
* __Unit test Tasks__ - added `--list` flag to show all filtered tests, without running them.

## 0.13.1 - 9 Feb 2013 (SDK 0.3.5.1 r18300)

* Cleaned up all deprecations.
* __NO__ Breaking changes. Should still work great with SDK 0.3.4.0 r18115.

### bot

* Removed references to `dart:collection-dev`

### hop_tasks

* `createDart2JsTask` arg `liveTypeAnalysis` defaults to `true` - matches `dart2js' impl change

## 0.13.0 - 8 Feb 2013 (SDK 0.3.4.0 r18115)

### bot

* `CollectionUtil`: `toHashMap` and `toHashSet` deprecated.
* `CollectionUtil`: added `toMap`
* __BREAKING__ `Enumerable` now uses `join` from `Iterable` so the default separator is now empty string
instead of `, `
* `Enumerable`: `toHashMap` and `toHashSet` deprecated.
* `Enumerable`: added `toMap`
* __NEW!__ `StringLineReader` - Lazily read lines from a `String`. Supports Windows line breaks, too.
* __BREAKING__ `Util.splitLines` returns `Iterable<String>` instead of `List<String>`
* `Util` learned `padLeft`

### bot_git

* `Commit` parses out a lot more information now.
* `Git.runGit` argument `processWorkingDir` is converted to a native path.
Works on Windows now.
* __BREAKING__ `GitDir` can only be created via "safe", async methods: `init` and __NEW!__ `fromExisting`
* __NEW!__ `GitDir` learned `populateBranch`

### bot_test

* Added `Matcher` `finishes` and `finishesWith`. These correspond to `completes`
and `completion` in `dart:matcher` __except__ instances of `ExpectException` are 
thrown directly without being wrapped

### hop

* __NEW!__ `ConsoleContext` makes it easy to run hop tasks directly from a console app.
* __BREAKING__ many log methods had their args switched around so `LogLevel` comes before `message`.
More consistent with `logging`

### hop_tasks

* `compileDocs` now uses new fancy `GitDir.populateBranch`.

## 0.12.1 - 5 Feb 2013 (SDK 0.3.4.0 r18115)

### bot_html

* `getImmediateFuture` added

### hop

* Fixed `hop-completion.bash` when hop is run outside of a "hop" directory

### hop_tasks

* __NEW!__ `createBenchTask` added

## 0.12.0 - 5 Feb 2013 (SDK 0.3.4.0 r18115)

* Now testing `harness_browser.html` via `DumpRenderTree`

### bot_git

* `GitDir` learned `getCurrentBranch`

### hop

* __BREAKING__ ctor for `Runner` now takes param of `ArgResults`
* `Runner` exposes helpers for parsing defaults args and getting usage.
* `runHopcore` prints out nice error info and exits cleanly with bad default args
* __NEW!__ added `TaskContext.getSubLogger`

### hop_tasks

* `compileDocs` provides useful error info if used with bad args
* __NEW!__ `createDartAnalyzerTask` - thanks, [Adam](https://github.com/financeCoding)!
* Exposed `pipeProcess` method for logging `Process` output in real time

## 0.11.4 - 31 Jan 2013 (SDK 0.3.2.0 r17657)

### bot_git

* A lot of updates and additions
* __NEW!__ `CommitReference`, `BranchReference`, `Commit`, `TreeEntry`
* __NEW!__ `GitDir` learned `getCommitCount`, `getBranchNames`, `getBranchReferences`, `getCommit`, `lsTree`
* __BREAKING__ `GitDir.writeObject` renamed to `writeObjects`

### hop_tasks

* `branchForDir` added an optional `workingDir` argument

## 0.11.3 - 29 Jan 2013 (SDK 0.3.2.0 r17657)

* Bumped `logging` dependency to `>=v0.3.2`

### bot

* More tests for colors. Tiny tweak to improve error report for bad ctor values in `HslColor`
* Better exceptions when `DetailedArgumentError` is used incorrectly
* `requireArgument` uses `DetailedArgumentError` correctly

## 0.11.2 - 28 Jan 2013 (SDK 0.3.2.0 r17657)

* A number of changes to support SDK 0.3.2.0. Although no breaking changes directly
affecting users.

### hop

* Cleanly handle the case where an async task throws an exception before returning a future.

## 0.11.1 - 24 Jan 2013 (SDK 0.3.1.2 r17463)

### hop

* __NEW!__ Extra arguments after the task name are passed to the Task via
an `arguments` property on `TaskContext`

### hop_tasks

* `createUnitTestTask` now uses extra arguments to filter the set of tests that are run

## 0.11.0 - 22 Jan 2013 (SDK 0.3.1.1 r17328)

_No features were knowingly added, removed, or changed but a lot of code was churned to support the
updated SDK._

## 0.10.0 - 09 Jan 2013 (SDK 0.2.10.1 r16761)

* __BREAKING__ Import file names have been updated to include the `bot_` prefix.
    * `import 'package:bot/bot_retained.dart';` instead of `import 'package:bot/retained.dart';`

### bot

* __BREAKING__ `Vector.getAngle` reports a valid value
* `Array2d` can now be zero width, and non-zero height

### bot_html

* __NEW!__ `getTimeoutFuture` helper. Wraps `window.setTimeout` with nice `Future` semantics.

### bot_io

* __NEW!__ `TempDir`
* __NEW!__ `IoHelper`

### bot_retained

* `MouseManager`
    * __BREAKING__ Renamed from `ClickManager`
    * Learned how to set cursor for individual `Thing` instances
    * Learned drag events for `Thing` instances
* `CanvasThing` now correctly invalidates child draw when transform changes

### bot_test

* __NEW!__ test methods: `expectFutureComplete` and `expectFutureFail`
* __NEW!__ `throwsAssertionError` matcher

### hop

* __FIX__ having zero tasks does not cause a exceptions

### hop_tasks

* __BREAKING__ Renamed `createStartProcessTask` to `createProcessTask`
    * Changed the return type to `Task`
    * Made `args` argument optional
    * Added optional `description` argument
* `createDart2JsTask` added named params `liveTypeAnalysis` and `rejectDeprecatedFeatures`

## 0.9.0 - 18 Dec 2012 (SDK M2 0.2.9.7 r16251)

### hop_tasks

* __BREAKING__ `dartdoc` now requires `packageDir` param. With recent SDK updates, 
one can now generate docs for libraries that use external packages.
* dart2js: added optional packageRoot, output, allowUnsafeEval args

## 0.8.0 - 11 Dec 2012 (SDK r15948)

__BREAKING__ Moved dependencies on SDK libraries to versions on pub.dartlang.org.

### bot

* __NEW__ Added `lerp` to top-level math functions.
* `AffineTransform` 
    * __NEW__ learned a new constructor - `fromTranslate`
    * __NEW__ learned `lerpTx` function

### bot_retained

* __BREAKING__ Massive rename. Element is way to overloaded, hence names like 'PElement'. Going with 'Thing'. Not ideal, but not overloaded.
* `Thing`
    * __NEW__ learned `alpha` -- or at least uses it now
    * __BREAKING__ a tiny change to how dirty state is tracked to allow things to effectively request animation in `drawOverride`.
	* __BREAKING__ Eliminated 'cacheEnabled' ctor argument.
	* __BREAKING__ Removed `clip` property. It wasn't doing anything. 
* __BREAKING__ `ShapeThing` constructor now uses named arguments.
* __NEW__ `NavLayer` -- copied from the Javascript library. Pretty fun.
* __NEW__ `HorizontalAlignment` and `VerticalAlignment`
* __NEW__ `RetainedUtil` learned `getOffsetVector`
* __NEW__ `SubCanvasThing` -- similar to `ImageThing`, but for drawing contents of a canvas.
* __NEW__ `TextThing` An element to display text. Lot's of work to do, but a good start.
* __NEW__ `StageWrapper` - handles requesting frames and drawing them when the stage updates.
* Added nifty `_RetainedEnum` as a relatively safe, private subclass for other enum types. 

## 0.7.0 - 27 Nov 2012 (SDK r15355)

### bot

* __BREAKING__ Renamed exception classes to align with Dart naming conventions.
* __BREAKING__ Slight changes to `requires` methods, `DetailedArgumentException`

### hop

* __BREAKING__ Almost everything has changed.
* Multi-line output is indented correctly.

### io

* __BREAKING__ `io.Color` is now `io.AnsiColor`
* __BREAKING__ Removed `prnt` and `prntLine`. A bit silly, no?

### html

* `CanvasUtil` learned `setTransform`

### retained

* __BREAKING__ Moved `CanvasUtil` to `bot_html` lib

## 0.6.0 - 19 Nov 2012 (SDK r15042)

* __BREAKING__ Merged `hop` back in. Circular dependencies just make no sense.
* __BREAKING__ Moved `qr` into its [own repository](https://github.com/kevmoo/qr.dart).
* A bunch of fixes to support more recent Dart release.

## 0.5.0 -- 6 Nov 2012 (SDK r14554)

* __BREAKING__ Changes to align with Dart r14554.

## 0.4.0 -- 25 October 2012  (SDK r13851)

### bot

* __BREAKING__ Changes to align with new Sequence types

## 0.3.0 -- 24 October 2012 (SDK r13851)

* __BREAKING__ Changes to align with Dart integration build v13851 

## 0.2.1 -- 22 October 2012  (SDK r13679, M1)

* Moved `hop` files into `tool` dir. These are for devs working with `bot.dart` not end users.

## 0.2.0 -- 21 October 2012 (SDK r13679, M1)

### bot
* `DetailedIllegalArgumentException` ctor is now `const`
* Removed private `_SimpleSet`. Not used.

### hop - *New*
* An attempt to create a process management system similar to [Rake](http://rake.rubyforge.org/) in the Ruby world or [Cake](http://coffeescript.org/#cake) in the CoffeeScript world.
* Moved `test`, `dart2js`, and `docs` to this new system.
* Naming: A play off frog. Which is a play off dart. As in "dart frog" and "frog hop". Yeah a stretch, but it's short.

### retained - *Breaking Changes*
* `PElement.draw` renamed to `_stageDraw`
* `PElement.updated` event removed
* Renamed `ElementParentImpl` to `ParentElement`
* Moved logic for handling children from `PElement` to `ParentElement`

## 0.1.0 - 16 October 2012 (SDK r13679)

* Aligned with M1 build of Dart r13679
