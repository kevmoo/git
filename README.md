![BOT!](https://raw.github.com/kevmoo/bot.dart/master/resource/logo.png)
# The Dart Bag-of-Tricks
## A collection of (mostly) general libraries to make working with [Dart](http://www.dartlang.org/) more productive.

Starting by porting bits of the [PL javascript library](https://github.com/thinkpixellab/pl) and Google's [Closure javascript library](https://developers.google.com/closure/library/) to enable some interesting scenarios.

[![](https://drone.io/kevmoo/bot.dart/status.png)](https://drone.io/kevmoo/bot.dart/latest)

# Projects using BOT

* [chrome.dart](https://github.com/dart-gde/chrome.dart) - Dart interop with chrome.* APIs for Chrome Packaged Apps
* [Pop, Pop, Win!](https://github.com/dart-lang/pop-pop-win) - Minesweeper with balloons
* [qr.dart](https://github.com/kevmoo/qr.dart) - Generate QR codes
* [vote.dart](https://github.com/kevmoo/vote.dart) - Simulate, run, and calculate elections with different election methods
* [Dart Widgets](https://github.com/kevmoo/widget.dart) - Reusable Web Components

# Try It Now

The __Dart Bag-of-Tricks__ (__BOT__) is hosted on [pub.dartlang.org](http://pub.dartlang.org/packages/bot).
Add the __BOT__ package to your `pubspec.yaml` file, selecting a version range that works with your version of the SDK. For example:

```yaml
dependencies:
  bot: ">=0.11.3"    # works with SDK v0.3.2.0 r17657
```

_Always check the [BOT page](http://pub.dartlang.org/packages/bot) on pub to find the latest release._

Versions change within the range when we release small bug fixes, but it changes outside of the range on any breaking change. See the [changelog](https://github.com/kevmoo/bot.dart/blob/master/changelog.md) to find the version that works best for you.

If you'd like to track bleeding edge developments, you can reference the the [GitHub repository](https://github.com/kevmoo/bot.dart) directly:
```yaml
dependencies:
  bot:
    git: https://github.com/kevmoo/bot.dart.git
```

# Versioning

* We follow [Semantic Versioning](http://semver.org/).
* We are not planning a V1 for __BOT__ until Dart releases V1.
	* In the mean time, the version will remain `0.Y.Z`.
	* Changes to the _minor_ version - Y - will indicate breaking changes.
	* Changes to the _patch_ version - Z - indicate non-breaking changes.

# Dart SDK dependency

* We're going to try to keep __BOT__ in line with the [latest integration build](https://gsdview.appspot.com/dart-editor-archive-integration/latest/) of the Dart SDK and Editor.
* At this point, each SDK release tends to introduce breaking changes, which usually require breaking changes in __BOT__.
* Keep an eye on the [changelog](https://github.com/kevmoo/bot.dart/blob/master/changelog.md) to see how __BOT__ aligns with each SDK release. 

# The libraries

The Bag-of-Tricks is two sets of libraries: __bot__ and __hop__.

# bot

## bot -- default library

 * No dependencies on 3rd-party libraries.
 * Usable for browser-based projects and non-browser projects.

### attached
 * A general model for supporting extensible, runtime-defined events and
   properties on supported objects.
 * This functionality is inspired by the Dependency Object/Property model
   in WPF/Silverlight.

### collection
 * `Array2d`
 * `Grouping` of collections
 * `ReadOnlyCollection`

### color
 * `RgbColor`, `HslColor` with associated conversions back and forth
 * `RgbColor` supports to/from hex


### events
 * Easily raise and subscribe to events with custom, type-safe event objects.

### math
 * Mostly classes related to 2D geometry and graphicsgeometry-related classes
 * `Coordinate`, `Box`, `Size`, `Vector`, `AffineTransfrom`

## bot_async
  * `FutureValue`: an abstract model for async conversions via `Future<T>`
  * `SendPortValue`: an implementation of `FutureValue` using isolates.

## bot_retained
  * A library for creating interactive content using HTML5 Canvas.
  
# hop

## hop - core task runtime
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

# Authors
 * [Kevin Moore](https://github.com/kevmoo) ([@kevmoo](http://twitter.com/kevmoo))
 * [Andreas Köberle](https://github.com/eskimoblood) ([@eskimobloood](https://twitter.com/eskimobloood))
 * [Adam Singer](https://github.com/financeCoding) ([+Adam Singer](https://plus.google.com/104569492481999771226))
 * _You? File bugs. Fork and Fix bugs. Let's build this community._
