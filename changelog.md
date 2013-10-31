# Changelog - Dart Bag of Tricks - IO

## 0.24.0 2013-10-31 (SDK 0.8.9 r29656)

* Updates for latest SDK
* **BREAKING** changes to `tryCompletion` and the completion generator due to removal of `Options` from `dart:io`.

## 0.23.3 2013-10-24 (SDK 0.8.6 r29156)

* Updates for latest SDK

## 0.23.2 2013-08-26 (SDK 0.6.21.2 r26619)

* Updates for latest SDK

## 0.23.1 2013-07-26 (SDK 0.6.9.2 r25388)

* **NEW!** `TempDir.then` - for those times when you just want a directory.
* Tiny updates to dependencies, refactoring in `bot_git`

## 0.23.0 2013-07-24 (SDK 0.6.9.2 r25388)

* Latest SDK
* **BREAKING** Moved `completion` into its own library.

## 0.22.0 2013-07-18 (0.6.5.0 r25017)

* Updated min SDK to 0.6.5
* Moved from 'pathos' to 'path' package
* **DEPRECATED** `DirectoryPopulater` and `MapDirectoryPopulater`
* **BREAKING** `TempDir.populate` now takes the same inputs as `EntityPopulater.populate`

## 0.21.3 2013-07-11 (SDK 0.6.3.3 r24898)

* Work-around for https://code.google.com/p/dart/issues/detail?id=10163
* Other tiny tweaks

## 0.21.2 2013-06-04 (SDK 0.5.13.1 r23552)

* Fixes for SDK 0.5.13.1
* Crypto moved to a pub package

## 0.21.1 2013-05-28 (SDK 0.5.11.1 r23200)

* Fixes for SDK 0.5.11.1

## 0.21.0+2 2013-04-29 (SDK 0.5.1.0 r22072)

## bot_io

* Another oops in `AnsiColor`
* Un-deprecated `DirectoryPopulater` and `MapDirecotryPopulater`
    * `EntityPopulator` isn't there yet...

## 0.21.0+1 2013-04-29 (SDK 0.5.1.0 r22072)

## bot_io

* Oops in `AnsiColor`

## 0.21.0 2013-04-29 (SDK 0.5.1.0 r22072)

## bot_io

* **BREAKING** `TempDir.dispose` is now async -- returns a `Future`
* **DEPRECATED** `DirectoryPopulater` and `MapDirecotryPopulater`
* **NEW!** `EntityPopulater`

## 0.20.2 2013-04-20 (SDK 0.4.7+5 r21658)

### bot_io

* __NEW!__ `fileContentsMatch`
* __NEW!__ `fileSha1Hex`

## 0.20.1 2013-04-19 (SDK 0.4.7+5 r21658)

* TODO...

## 0.20.0 2013-04-17 (SDK 0.4.7+3 r21604)

* The grand split from [BOT](https://github.com/kevmoo/bot.dart) begins.
* See the [BOT Changelog](https://github.com/kevmoo/bot.dart/blob/master/changelog.md) for work leading up to the split.
