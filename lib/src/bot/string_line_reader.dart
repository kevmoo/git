part of bot;

class StringLineReader {
  final String source;

  int _position = 0;

  StringLineReader(this.source) {
    requireArgumentNotNull(source, 'source');
  }

  int get position => _position;

  String readNextLine() {
    if(_position == null) {
      return null;
    }
    final nextLF = source.indexOf('\n', _position);

    if(nextLF < 0) {
      // no more new lines, return what's left and set postion = null
      final value = source.substring(position, source.length);
      _position = null;
      return value;
    }

    // to handle Windows newlines, see if the value before nextLF is a Carriage return
    final isWinNL = nextLF > 0 && source.substring(nextLF-1,nextLF) == '\r';

    final value = isWinNL ? source.substring(_position, nextLF-1) :
      source.substring(_position, nextLF);

    _position = nextLF + 1;

    return value;
  }

  String readToEnd() {
    if(_position == null) {
      return null;
    }
    final value = source.substring(position, source.length);
    _position = null;
    return value;
  }
}
