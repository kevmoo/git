part of bot_io;

/**
 * [More details](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
 */
class AnsiColor {
  static const AnsiColor BLACK = const AnsiColor._internal(0, 'black');
  static const AnsiColor RED = const AnsiColor._internal(1, 'red');
  static const AnsiColor GREEN = const AnsiColor._internal(2, 'green');
  static const AnsiColor YELLOW = const AnsiColor._internal(3, 'yellow');
  static const AnsiColor BLUE = const AnsiColor._internal(4, 'blue');
  static const AnsiColor MAGENTA = const AnsiColor._internal(5, 'magenta');
  static const AnsiColor CYAN = const AnsiColor._internal(6, 'cyan');
  static const AnsiColor GRAY = const AnsiColor._internal(7, 'gray');
  static const AnsiColor LIGHT_RED = const AnsiColor._internal(91, 'light red');
  static const AnsiColor BOLD = const AnsiColor._internal(null, 'bold', srg: 1);
  static const AnsiColor RESET = const AnsiColor._internal(null, 'reset');

  final int foregroundId;
  final String name;
  final int _srg;

  bool get isBold => _srg == 1;

  const AnsiColor._internal(this.foregroundId, this.name, {int srg: 0}) :
    this._srg = srg;

  AnsiColor asBold() {
    if(isBold) {
      return this;
    } else {
      return new AnsiColor._internal(foregroundId, name, srg: 1);
    }
  }

  String toString() {
    final value = 'AnsiColor: $name';

    if(isBold) {
      return value + ' (BOLD)';
    } else {
      return value;
    }
  }

  // TODO: maybe no-op here if 'this' is RESET?
  String wrap(String input) {
    assert(input != null);
    return "${shellValue}$input${RESET.shellValue}";
  }

  String get shellValue {
    final items = new List<String>();

    items.add(_srg.toString());

    if(foregroundId != null) {
      items.add('3$foregroundId');
    }

    return '\u001b[${items.join(";")}m';
  }
}
