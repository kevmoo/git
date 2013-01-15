part of hop;

// TODO: add some names and descriptions so these are more easily
// understood at runtime

class RunResult {
  // See http://tldp.org/LDP/abs/html/exitcodes.html
  // Accessed 2012-11-07

  /// Ran successfully
  static final RunResult SUCCESS = const RunResult._internal(0);

  /// C/C++ standard for bad usage. Hop was called incorrectly
  static final RunResult BAD_USAGE = const RunResult._internal(64);

  /// Task was was started and failed gracefully
  static final RunResult FAIL = const RunResult._internal(80);

  /// Task was was started, but threw an exception
  static final RunResult EXCEPTION = const RunResult._internal(81);

  /// Task misbehaved. Returned null, used TaskContext incorrectly, etc.
  static final RunResult ERROR = const RunResult._internal(82);

  final int exitCode;

  const RunResult._internal(this.exitCode);

  bool get success => exitCode == SUCCESS.exitCode;

  String toString() => 'RunResult - $exitCode';
}
