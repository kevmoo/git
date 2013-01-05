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
     * `Grouping` of collections
     * `ReadOnlyCollection`
 * __color__
     * `RgbColor`, `HslColor` with associated conversions back and forth
     * `RgbColor` supports to/from hex
 * __events__
 	 * Easily raise and subscribe to events with custom, type-safe event objects.
 * __math__
     * Mostly classes related to 2D geometry and graphicsgeometry-related classes
     * `Coordinate`, `Box`, `Size`, `Vector`, `AffineTransfrom`

## async
  * `FutureValue`: an abstract model for async conversions via `Future<T>`
  * `SendPortValue`: an implementation of `FutureValue` using isolates.

## hop
  * An object-oriented framework creating and reusing scripts in Dart.
  * Easy to create command-line scripts.
  * Define functionality in libraries. Add and update them with `pub`.
  * Nice touches for free: bash command completion, help, helpful exit codes

## hop_tasks
  * A collection of tasks and task helpers.
  * Unit tests
  * dart2js
  * dartdoc
  * git

## retained
  * A library for creating interactive content using HTML5 Canvas.

# Projects using BOT

* [chrome.dart](https://github.com/dart-gde/chrome.dart) - Dart interop with chrome.* APIs for Chrome Packaged Apps
* [Pop, Pop, Win!](https://github.com/dart-lang/pop-pop-win) - Minesweeper with balloons in Dart
* [qr.dart](https://github.com/kevmoo/qr.dart) - Generate QR codes in Dart
* [vote.dart](https://github.com/kevmoo/vote.dart) - Simulate, run, and calculate elections with different election methods
* [Dart Widgets](https://github.com/kevmoo/widget.dart) - Reusable Web Components for Dart applications

# Versioning

Our goal is to follow [Semantic Versioning](http://semver.org/).

_Note: we have not released v1 (yet)._

# Authors
 * [Kevin Moore](https://github.com/kevmoo) ([@kevmoo](http://twitter.com/kevmoo))
 * [Andreas Köberle](https://github.com/eskimoblood) ([@eskimobloood](https://twitter.com/eskimobloood))
 * _You? File bugs. Fork and Fix bugs. Let's build this community._
