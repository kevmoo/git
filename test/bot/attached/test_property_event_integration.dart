part of test_bot;

class TestPropertyEventIntegration extends AttachableObject {
  static final Property<String> _nameProperty = new Property<String>("name");
  static final Property<int> _ageProperty = new Property<int>("age", 0);

  final EventHandle<EventArgs> _nameChangedEventHandle = new EventHandle<EventArgs>();
  final EventHandle<EventArgs> _ageChangedEventHandle = new EventHandle<EventArgs>();

  TestPropertyEventIntegration() {

    _nameProperty.getStream(this).listen((args) {
      _nameChangedEventHandle.add(EventArgs.empty);
    });

    _ageProperty.getStream(this).listen((args) {
      _ageChangedEventHandle.add(EventArgs.empty);
    });
  }

  //
  // Name property
  //
  String get name => _nameProperty.get(this);

  void set name(String value){
    _nameProperty.set(this, value);
  }

  async.Stream<EventArgs> get nameChanged => _nameChangedEventHandle.stream;

  //
  // Age property
  //
  int get age => _ageProperty.get(this);

  void set age(int value){
    _ageProperty.set(this, value);
  }

  async.Stream<EventArgs> get ageChanged =>_ageChangedEventHandle.stream;

  void reset(){
    _nameProperty.clear(this);
    _ageProperty.clear(this);
  }

  static void run(){
    test('PropertyObject, EventHandle', doTest);
  }

  static void doTest(){
    var nh = new EventWatcher<EventArgs>();

    var ah = new EventWatcher<EventArgs>();

    var obj = new TestPropertyEventIntegration();
    obj.nameChanged.listen(nh.handler);
    obj.ageChanged.listen(ah.handler);

    //
    // Initial checks
    //
    expect(obj.name, isNull);
    expect(obj.age, equals(0));
    expect(nh.eventCount, equals(0));
    expect(ah.eventCount, equals(0));

    obj.name = "Bob";

    //
    // Checks
    //
    expect(obj.name, equals('Bob'));
    expect(obj.age, equals(0));
    expect(nh.eventCount, equals(1));
    expect(ah.eventCount, equals(0));

    // NOTE: no checks for setting the same value twice
    obj.name = "Bob";

    //
    // Checks
    //
    expect(obj.name, equals('Bob'));
    expect(obj.age, equals(0));
    expect(nh.eventCount, equals(2));
    expect(ah.eventCount, equals(0));

    obj.age = 19;

    //
    // Checks
    //
    expect(obj.name, equals('Bob'));
    expect(obj.age, equals(19));
    expect(nh.eventCount, equals(2));
    expect(ah.eventCount, equals(1));

    // reset properties
    obj.reset();

    //
    // Initial checks
    //
    expect(obj.name, isNull);
    expect(obj.age, equals(0));
    expect(nh.eventCount, equals(3));
    expect(ah.eventCount, equals(2));

    obj.dispose();
  }
}
