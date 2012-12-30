library test_bot_retained;

import 'dart:html';
import 'package:bot/bot.dart';
import 'package:bot/retained.dart';
import 'package:unittest/unittest.dart';

void runRetainedTests() {
  group('bot_retained', () {
    test('test double click manager', _testDoudbleClickManager);
    test('test add/remove from Panel', _testAddRemoveFromPanel);
    test('Thing remove transform', _testRemoveTransform);
    test('Thing parent', _testThingParent);
  });
}

void _testThingParent() {
  final child = new ShapeThing(10, 10);
  expect(child.parent, isNull);
  expect(() => child.registerParent(null), throwsArgumentError);
  expect(() => child.unregisterParent(null), throwsArgumentError);

  final parentThing = new _TestParentThing();

  // registerParent works
  child.registerParent(parentThing);

  expect(child.parent, isNotNull);

  // register same parent 2nd time doesn't work
  expect(() => child.registerParent(parentThing), throws);

  // unregister works
  child.unregisterParent(parentThing);

  // unregister 2nd time doesn't work
  expect(() => child.unregisterParent(parentThing), throwsArgumentError);

  expect(child.parent, isNull);
}

void _testRemoveTransform() {
  // null param throws
  final thing = new ShapeThing(10, 10);
  expect(() => thing.removeTransform(null), throwsArgumentError);

  final tx = thing.addTransform();
  // valid param returns true
  expect(thing.removeTransform(tx), isTrue);

  // calling remove a second time returns false
  expect(thing.removeTransform(tx), isFalse);
}

void _testDoudbleClickManager() {
  final canvas = new CanvasElement();

  final thing = new ShapeThing(100, 100, fillStyle: 'blue');

  final stage = new Stage(canvas, thing);

  final cm = new MouseManager(stage);
  final cm2 = new MouseManager(stage);

  expect(cm2, same(cm));
}

void _testAddRemoveFromPanel() {
  final panel = new CanvasThing(100, 100);
  expect(() => panel.add(null), throwsArgumentError);

  expect(panel.visualChildCount, 0);

  final shape = new ShapeThing(10, 10);

  expect(shape.parent, isNull);

  panel.add(shape);

  expect(panel.visualChildCount, 1);
  expect(shape.parent, isNotNull);

  // cannot add the same thing twice
  expect(() => panel.add(shape), throwsArgumentError);

  // cannot remove 'null'
  expect(() => panel.remove(null), throwsArgumentError);

  expect(panel.remove(shape), isTrue);
  expect(panel.visualChildCount, 0);
  expect(shape.parent, isNull);

  // cannot add a thing that already has a parent
  final panel2 = new CanvasThing(10, 10);
  panel2.add(shape);

  expect(() => panel.add(shape), throwsArgumentError);
}

class _TestParentThing extends ParentThing {
  _TestParentThing() : super(10, 10);

  int get visualChildCount => 0;

  Thing getVisualChild(int index) {
    throw 'foo';
  }
}
