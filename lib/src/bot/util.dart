part of bot;

class Util {
  static int getHashCode(Iterable source) {
    requireArgumentNotNull(source, 'source');

    int hash = 0;
    for (final h in source) {
      int next = h == null ? 0 : h.hashCode;
      hash = 0x1fffffff & (hash + next);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  // TODO: handles windows new lines? Should test...
  static Iterable<String> splitLines(String input) {
    requireArgumentNotNull(input, 'input');

    return new _FuncEnumerable(input, (v) => new _StringLineIterator(v));
  }

  /**
   * Returns a [String] with a length that is at least [minWidth].
   * If [text] has a length less than [minWidth], the return value
   * will be a string with spaces inserted before [text].
   */
  static String padLeft(String text, int minWidth) {
    requireArgumentNotNull(text, 'text');
    while(text.length < minWidth) {
      text = ' ' + text;
    }
    return text;
  }
}
