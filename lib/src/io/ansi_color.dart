part of bot_io;

/**
 * [More details](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
 */
class AnsiColor {
  const String _NO_COLOR = '\u001b[0m';
  static const BLACK = const AnsiColor._internal(0, 'black');
  static const RED = const AnsiColor._internal(1, 'red');
  static const GREEN = const AnsiColor._internal(2, 'green');
  static const YELLOW = const AnsiColor._internal(3, 'yellow');
  static const BLUE = const AnsiColor._internal(4, 'blue');

  final int id;
  final String name;

  const AnsiColor._internal(this.id, this.name);

  String toString() => "$name ($id)";

  String wrap(String input) {
    assert(input != null);
    return "${shellValue}$input${_NO_COLOR}";
  }

  String get shellValue => '\u001b[3${id}m';
}
