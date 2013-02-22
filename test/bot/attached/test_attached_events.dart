part of test_bot;

class TestAttachedEvents extends AttachableObject {
  static final AttachedEvent<EventArgs> _testEvent1 =
      new AttachedEvent<EventArgs>('testEvent1');

  static final AttachedEvent<EventArgs> _testEvent2 =
      new AttachedEvent<EventArgs>('testEvent2');

  static void run() {
    group('AttachableEvent', () {
      test('whole deal', _testWholeDeal);
      test('removeHandler', _testRemove);
    });
  }

  static void _testRemove() {
    final obj = new TestAttachedEvents();
    final watcher1 = new EventWatcher<EventArgs>();

    expect(_testEvent1.hasSubscribers(obj), false);
    final h1 = _testEvent1.getStream(obj).listen(watcher1.handler);

    expect(_testEvent1.hasSubscribers(obj), true);

    h1.cancel();
    expect(_testEvent1.hasSubscribers(obj), false);
  }

  static void _testWholeDeal() {
    final watcher1 = new EventWatcher<EventArgs>();
    final watcher2 = new EventWatcher<EventArgs>();

    final obj = new TestAttachedEvents();
    final h1 = _testEvent1.getStream(obj).listen(watcher1.handler);
    final h2 = _testEvent2.getStream(obj).listen(watcher2.handler);

    _testEvent1.fireEvent(obj, EventArgs.empty);
    expect(watcher1.eventCount, equals(1));
    expect(watcher2.eventCount, equals(0));

    _testEvent2.fireEvent(obj, EventArgs.empty);
    expect(watcher1.eventCount, equals(1));
    expect(watcher2.eventCount, equals(1));

    final h3 = _testEvent1.getStream(obj).listen(watcher2.handler);

    h1.cancel();
    // h3 is still subscribed
    expect(_testEvent1.hasSubscribers(obj), isTrue);

    _testEvent1.fireEvent(obj, EventArgs.empty);
    expect(watcher1.eventCount, equals(1));
    expect(watcher2.eventCount, equals(2));

    // true first time
    expect(_testEvent2.hasSubscribers(obj), isTrue);
    h2.cancel();
    expect(_testEvent2.hasSubscribers(obj), isFalse);

    // true first time
    expect(_testEvent1.hasSubscribers(obj), isTrue);
    h3.cancel();
    expect(_testEvent1.hasSubscribers(obj), isFalse);
  }
}
