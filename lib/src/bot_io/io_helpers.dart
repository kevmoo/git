part of bot_io;

class IoHelpers {

  static Future<bool> verifyContents(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(content != null);
    return dir.exists()
        .then((bool doesExist) {
          if(!doesExist) {
            return false;
          } else {
            // Would rather be using .isEmpty here, but we have a
            // DARTBUG
            // https://code.google.com/p/dart/issues/detail?id=10163
            return EntityValidator.validateDirectoryFromMap(dir, content)
                .length.then((length) => length == 0);
          }
        });
  }

  static Future<bool> isEmpty(Directory dir) {
    assert(dir != null);
    return verifyContents(dir, {});
  }
}
