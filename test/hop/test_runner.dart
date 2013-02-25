part of test_hop;

class TestRunner extends Runner {

  TestRunner(HopConfig state, List<String> arguments) :
    super(state, arguments);

  @protected
  RootTaskContext getContext() {
    return new TestTaskContext();
  }
}

class TestTaskContext extends RootTaskContext {

  TestTaskContext() : super();

  @protected
  @override
  void printCore(String msg) {
    (new Logger('hop_test_context')).info(msg);
  }
}
