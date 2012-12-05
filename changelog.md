# Changelog - Dart Bag of Tricks

## 0.8.0 - *unreleased* - (SDK r15699)

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
* __NEW__ `NavLayer` -- copied from the Javascript library. Pretty fun.
* __NEW__ `HorizontalAlignment` and `VerticalAlignment`
* __NEW__ `RetainedUtil` learned `getOffsetVector`
* __BREAKING__ `ShapeThing` had its constructor shaken up to support `cacheEnabled`
* __NEW__ `SubCanvasThing` -- similiar to `ImageThing`, but for drawing contents of a canvas.
* __NEW__ `TextThing` An element to display text. Lot's of work to do, but a good start.
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
