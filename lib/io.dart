library bot_io;

import 'dart:io';
import 'bot.dart';

part 'src/io/ansi_color.dart';

void prnt(obj, [AnsiColor color = null]) {
  String value;
  if(obj == null) {
    value = '';
  } else {
    value = obj.toString();
  }
  if(color != null) {
    value = color.wrap(value);
  }
  stdout.writeString(value);
}

void prntLine(obj, [AnsiColor color = null]) {
  prnt("$obj\n", color);
}
