part of test_hop;

class TestRunner extends Runner {

  TestRunner(BaseConfig state, List<String> arguments) :
    super(state, Runner.parseArgs(arguments));

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
