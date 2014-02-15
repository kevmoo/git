library util;

import 'package:bot/bot.dart';

import 'top_level.dart';

const SHA_REGEX_PATTERN = '[a-f0-9]{40}';
final shaRegEx = new RegExp(r'^' + SHA_REGEX_PATTERN + r'$');

final headerRegExp = new RegExp(r'^([a-z]+) (.+)$');

void requireArgumentValidSha1(String value, String argName) {
  _metaRequireArgumentNotNullOrEmpty(argName);
  requireArgumentNotNullOrEmpty(value, argName);

  if(!isValidSha(value)) {
    final message = 'Not a valid SHA1 value: $value';
    throw new DetailedArgumentError(argName, message);
  }
}

void _metaRequireArgumentNotNullOrEmpty(String argName) {
  if(argName == null || argName.length == 0) {
    throw new InvalidOperationError("That's just sad. Give me a good argName");
  }
}
