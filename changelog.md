# Changelog - Dart Bag of Tricks

## 0.12.0 - (SDK 0.3.4.0 r18115)

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
    * __BREAKING__ a tiny change to how dirty state is tracked to allow thingss to effectively request animation in `drawOverride`.
	* __BREAKING__ Eliminated 'cacheEnabled' ctor argument.
	* __BREAKING__ Removed `clip` property. It wasn't doing anything. 
* __BREAKING__ `ShapeThing` constructor now uses named arguments.
* __NEW__ `NavLayer` -- copied from the Javascript library. Pretty fun.
* __NEW__ `HorizontalAlignment` and `VerticalAlignment`
* __NEW__ `RetainedUtil` learned `getOffsetVector`
* __NEW__ `SubCanvasThing` -- similiar to `ImageThing`, but for drawing contents of a canvas.
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
* An attempt to create a process management system similiar to [Rake](http://rake.rubyforge.org/) in the Ruby world or [Cake](http://coffeescript.org/#cake) in the CoffeeScript world.
* Moved `test`, `dart2js`, and `docs` to this new system.
* Naming: A play off frog. Which is a play off dart. As in "dart frog" and "frog hop". Yeah a stretch, but it's short.

### retained - *Breaking Changes*
* `PElement.draw` renamed to `_stageDraw`
* `PElement.updated` event removed
* Renamed `ElementParentImpl` to `ParentElement`
* Moved logic for handling children from `PElement` to `ParentElement`

## 0.1.0 - 16 October 2012 (SDK r13679)

* Aligned with M1 build of Dart r13679
