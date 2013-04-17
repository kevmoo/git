part of bot_io;

class IoHelpers {

  static Future<bool> verifyContents(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(content != null);
    return dir.exists()
        .then((bool doesExist) {
          if(!doesExist) {
            return new Future.value(false);
          } else {
            return EntityValidator.validateDirectoryFromMap(dir, content)
                .isEmpty;
          }
        });
  }

  static Future<bool> isEmpty(Directory dir) {
    assert(dir != null);
    return verifyContents(dir, {});
  }
}
