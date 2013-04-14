part of bot_io;

class IoHelpers {

  static Future<bool> verifyContents(Directory dir, Map<String, dynamic> content) {
    assert(dir != null);
    assert(content != null);
    return dir.exists()
        .then((bool doesExist) {
          if(!doesExist) {
            return new Future.immediate(false);
          } else {
            final validator = new DirectoryValidator(content);
            return validator.validate(dir);
          }
        });
  }

  static Future<bool> isEmpty(Directory dir) {
    assert(dir != null);
    return verifyContents(dir, {});
  }
}
