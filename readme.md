![BOT!](https://raw.github.com/kevmoo/bot.dart/master/resource/logo.png)
# The Dart Bag-of-Tricks
## A collection of (mostly) general libraries to make working with [Dart](http://www.dartlang.org/) more productive.

Starting by porting bits of the [PL javascript library](https://github.com/thinkpixellab/pl) and Google's [Closure javascript library](https://developers.google.com/closure/library/) to enable some interesting scenarios.

[![](https://drone.io/kevmoo/bot.dart/status.png)](https://drone.io/kevmoo/bot.dart/latest)

# Highlights

## bot -- default library
 * __attached__
     * A general model for supporting extensible, runtime-defined events and
       properties on supported objects.
     * This functionality is inspired by the Dependency Object/Property model
       in WPF/Silverlight.
 * __collection__
     * `Array2d`
     * `CollectionUtil`
     * `Grouping`
     * `IndexIterator`
     * `ListBase`
     * `NumberEnumerable`
     * `ReadOnlyCollection`
 * __color__
     * `RgbColor`, `HslColor` with associated conversions back and forth
     * `RgbColor` supports to/from hex
 * __events__
 * __math__
     * Mostly classes related to 2D geometry and graphicsgeometry-related classes
     * `Coordinate`, `Box`, `Size`, `Vector`, `AffineTransfrom`

## async
  * `FutureValue`: an abstract model for async conversions via `Future<T>`
  * `SendPortValue`: an implementation of `FutureValue` using isolates.

## html

## hop

## hop_tasks

## retained

## test

# Versioning

Our goal is to follow [Semantic Versioning](http://semver.org/).

_Note: we have not released v1 (yet)._

# Authors
 * [Kevin Moore](https://github.com/kevmoo) ([@kevmoo](http://twitter.com/kevmoo))
 * [Andreas Köberle](https://github.com/eskimoblood) ([@eskimobloood](https://twitter.com/eskimobloood))
 * _You? File bugs. Fork and Fix bugs. Let's build this community._
