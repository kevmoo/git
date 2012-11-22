part of test_hop;

class TestRunner extends Runner {

  TestRunner(BaseConfig state, List<String> arguments) :
    super(state, arguments);


  @protected
  RootTaskContext getContext() {
    return new TestTaskContext();
  }
}

class TestTaskContext extends RootTaskContext {

  TestTaskContext() : super();

  @protected
  void printCore(String msg, [AnsiColor color = null, String taskName = null]) {
    // at the moment, just swallowing all print output
  }
}
