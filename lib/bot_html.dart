library bot_html;

import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:web_audio';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:bot/bot.dart';

part 'src/bot_html/_resource_entry.dart';
part 'src/bot_html/audio_loader.dart';
part 'src/bot_html/canvas_util.dart';
part 'src/bot_html/dragger.dart';
part 'src/bot_html/top_level.dart';
part 'src/bot_html/html_view.dart';
part 'src/bot_html/image_loader.dart';
part 'src/bot_html/resource_loader.dart';

final _libLogger = new Logger('bot_html');

Coordinate _p2c(Point p) => new Coordinate(p.x, p.y);
Point _c2p(Coordinate c) => new Point(c.x, c.y);
