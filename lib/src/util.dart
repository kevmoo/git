import 'bot.dart';
import 'top_level.dart';

const SHA_REGEX_PATTERN = '[a-f0-9]{40}';

const gitBinName = 'git';

final shaRegEx = new RegExp(r'^' + SHA_REGEX_PATTERN + r'$');

final headerRegExp = new RegExp(r'^([a-z]+) (.+)$');

void requireArgumentValidSha1(String value, String argName) {
  metaRequireArgumentNotNullOrEmpty(argName);
  requireArgumentNotNullOrEmpty(value, argName);

  if (!isValidSha(value)) {
    final message = 'Not a valid SHA1 value: $value';
    throw new ArgumentError.value(value, argName, message);
  }
}
