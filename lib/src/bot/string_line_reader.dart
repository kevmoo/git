part of bot;

class StringLineReader {
  final String source;

  int _position = 0;

  StringLineReader(this.source) {
    requireArgumentNotNull(source, 'source');
  }

  int get position => _position;

  bool get eof => _position == null;

  String readNextLine() => _peekOrReadNextLine(true);

  String peekNextLine() => _peekOrReadNextLine(false);

  String readToEnd() {
    if(_position == null) {
      return null;
    }
    final value = source.substring(position, source.length);
    _position = null;
    return value;
  }

  String _peekOrReadNextLine(bool updatePosition) {
    if(_position == null) {
      return null;
    }
    final nextLF = source.indexOf('\n', _position);

    if(nextLF < 0) {
      // no more new lines, return what's left and set postion = null
      final value = source.substring(position, source.length);
      if(updatePosition) {
        _position = null;
      }
      return value;
    }

    // to handle Windows newlines, see if the value before nextLF is a Carriage return
    final isWinNL = nextLF > 0 && source.substring(nextLF-1,nextLF) == '\r';

    final value = isWinNL ? source.substring(_position, nextLF-1) :
      source.substring(_position, nextLF);

    if(updatePosition) {
      _position = nextLF + 1;
    }

    return value;
  }
}

class _StringLineIterator extends Iterator<String> {
  final StringLineReader _reader;

  String _current;

  _StringLineIterator(String source) : _reader = new StringLineReader(source);

  String get current => _current;

  bool moveNext() {
    _current = _reader.readNextLine();
    return _current != null;
  }
}
