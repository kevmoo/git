part of bot;

/**
 * An annotation used to mark a field, getter, setter, or method, as one that
 * should only be accessed by subclasses.
 * DARTBUG http://code.google.com/p/dart/issues/detail?id=6119
 */
const protected = const _Protected();

class _Protected {
  const _Protected();
}
