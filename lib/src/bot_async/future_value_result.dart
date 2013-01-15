part of bot_async;

class FutureValueResult<TOutput> {
  static const String _valueKey = 'value';
  static const String _errorKey = 'error';
  static const String _stackTraceKey = 'stackTrace';

  final TOutput value;
  final error;
  final stackTrace;
  final Func1<dynamic, TOutput> _outputSerializer;

  FutureValueResult(this.value, [this._outputSerializer]) :
    error = null, stackTrace = null;

  FutureValueResult.fromException(this.error, this.stackTrace)
  : value = null, _outputSerializer = null {
    requireArgumentNotNull(error, 'error');
  }

  factory FutureValueResult.fromMap(Map value) {
    requireArgumentNotNull(value, 'value');
    requireArgument(isMyMap(value), 'value');

    final ex = value[_errorKey];
    if(ex != null) {
      final stack = value[_stackTraceKey];
      return new FutureValueResult.fromException(ex, stack);
    } else {
      return new FutureValueResult(value[_valueKey]);
    }
  }

  bool get isException => error != null;

  Map toMap() {
    // would love to use consts here, but the analyzer doesn't like it
    // DARTBUG: http://code.google.com/p/dart/issues/detail?id=4207
    final rawValue = _serialize(value);
    return { 'value' : rawValue, 'error' : error, 'stackTrace' : stackTrace };
  }

  static bool isMyMap(Map value) {
    return value != null && value.length == 3 &&
        value.containsKey(_valueKey) &&
        value.containsKey(_errorKey) &&
        value.containsKey(_stackTraceKey);
  }

  bool operator ==(FutureValueResult other) {
    return other != null &&
        other.value == value &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  dynamic _serialize(TOutput output) {
    if(_outputSerializer == null) {
      return output;
    } else {
      return _outputSerializer(output);
    }
  }
}
