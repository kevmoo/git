import 'package:string_scanner/string_scanner.dart';

import 'bot.dart';
import 'top_level.dart';

const shaRegexPattern = '[a-f0-9]{40}';

final headerRegExp = RegExp(r'^([a-z]+) (.+)$');

void requireArgumentValidSha1(String value, String argName) {
  metaRequireArgumentNotNullOrEmpty(argName);
  requireArgumentNotNullOrEmpty(value, argName);

  if (!isValidSha(value)) {
    final message = 'Not a valid SHA1 value: $value';
    throw ArgumentError.value(value, argName, message);
  }
}

extension StringScannerX on StringScanner {
  String? readNextLine() {
    if (isDone) return null;
    if (scan(_lineRegexp)) {
      return lastMatch![1];
    }
    final restStr = rest;
    position = string.length;
    return restStr;
  }
}

final _lineRegexp = RegExp(r'([^\r\n]*)\r?\n');
