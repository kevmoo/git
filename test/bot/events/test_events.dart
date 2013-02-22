part of test_bot;

class TestEvents {
  final EventHandle<String> _testEventHandle;

  TestEvents(): _testEventHandle = new EventHandle<String>();

  async.Stream<String> get testEvent => _testEventHandle.stream;

  void fireTestEvent(String value){
    _testEventHandle.add(value);
  }

  static void run(){
    test('Event, EventHandle', () {

      var target = new TestEvents();

      var watcher = new EventWatcher<String>();

      expect(watcher.lastArgs, isNull);

      // before an event is registered, the value should still be null
      target.fireTestEvent('bar');
      expect(watcher.lastArgs, isNull);

      var eventId = target.testEvent.listen(watcher.handler);

      // after registration, event should change value
      target.fireTestEvent('bar');
      expect(watcher.lastArgs, equals('bar'));

      // dispatching another event shouldn't change value
      target.fireTestEvent('foo');
      expect(watcher.lastArgs, equals('foo'));

      expect(target._testEventHandle.hasSubscribers, isTrue);
      eventId.cancel();
      expect(target._testEventHandle.hasSubscribers, isFalse);

      // after removing, event should not change value
      target.fireTestEvent('bar');
      expect(watcher.lastArgs, equals('foo'));
    });

  }
}
