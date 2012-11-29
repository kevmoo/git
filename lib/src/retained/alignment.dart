part of bot_retained;

class HorizontalAlignment extends _RetainedEnum {
  static const HorizontalAlignment LEFT =
      const HorizontalAlignment._internal('left');

  static const HorizontalAlignment RIGHT =
      const HorizontalAlignment._internal('right');

  static const HorizontalAlignment CENTER =
      const HorizontalAlignment._internal('center');

  const HorizontalAlignment._internal(String name) : super(name);
}

class VerticalAlignment extends _RetainedEnum {
  static const VerticalAlignment TOP =
      const VerticalAlignment._internal('top');

  static const VerticalAlignment BOTTOM =
      const VerticalAlignment._internal('bottom');

  static const VerticalAlignment MIDDLE =
      const VerticalAlignment._internal('middle');

  const VerticalAlignment._internal(String name) : super(name);
}
