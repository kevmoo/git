library bot_retained;

import 'dart:async';
import 'dart:html';
import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_html.dart';

part 'src/bot_retained/alignment.dart';
part 'src/bot_retained/mouse_manager.dart';
part 'src/bot_retained/thing_mouse_event_args.dart';
part 'src/bot_retained/thing_parent.dart';
part 'src/bot_retained/image_thing.dart';
part 'src/bot_retained/mouse.dart';
part 'src/bot_retained/nav_thing.dart';
part 'src/bot_retained/panel_thing.dart';
part 'src/bot_retained/parent_thing.dart';
part 'src/bot_retained/canvas_thing.dart';
part 'src/bot_retained/thing.dart';
part 'src/bot_retained/retained_debug.dart';
part 'src/bot_retained/retained_util.dart';
part 'src/bot_retained/shape_thing.dart';
part 'src/bot_retained/shape_type.dart';
part 'src/bot_retained/sprite_thing.dart';
part 'src/bot_retained/stage.dart';
part 'src/bot_retained/stage_wrapper.dart';
part 'src/bot_retained/sub_canvas_thing.dart';
part 'src/bot_retained/text_thing.dart';
part 'src/bot_retained/_retained_enum.dart';

Coordinate _p2c(Point p) => new Coordinate(p.x, p.y);
Point _c2p(Coordinate c) => new Point(c.x, c.y);
