part of bot_io;

abstract class EntityValidator {
  Stream<String> getValidationErrors(FileSystemEntity entity);

  Future<bool> validate(FileSystemEntity entity) =>
      getValidationErrors(entity).isEmpty;
}

EntityValidator convertToValidator(dynamic value) {
  if(value is EntityValidator) {
    return value;
  } else if(value is Map) {
    return new DirectoryValidator(value);
  } else if(value is String) {
    return new FileValidator.stringContents(value);
  } else {
    throw 'Could not turn "$value" into an EntityValidator';
  }
}

abstract class FileValidator extends EntityValidator {

  factory FileValidator.stringContents(String content) {
    return new _FileShaValidator(_getStringSha1(content));
  }

  factory FileValidator.contentSha1(String sha1) {
    return new _FileShaValidator(sha1);
  }
}

class _FileShaValidator extends EntityValidator implements FileValidator {
  final String _sha1;
  _FileShaValidator(this._sha1) {
    assert(_sha1 != null);
    assert(_sha1.length == 40);
    // should assert this is a well formatted sha...but whatevs
  }

  @override
  Stream<String> getValidationErrors(FileSystemEntity entity) {
    if(entity is! File) {
      return new Stream.fromIterable(['Not a file: $entity']);
    }

    var future = _getSha1String(entity)
        .then((String sha1) {
          if(sha1 == _sha1) {
            return [];
          } else {
            return ['content does not match: $entity'];
          }
        });

    return _streamFromIterableFuture(future);
  }
}

class DirectoryValidator extends EntityValidator {
  final Map<String, dynamic> _sourceMap;

  DirectoryValidator(Map<String, dynamic> validators) :
    _sourceMap = validators {
    assert(validators != null);

    // TODO: all keys are not null or empty
    // TODO: all values are not null
  }

  @override
  Stream<String> getValidationErrors(FileSystemEntity entity) {
    if(entity is! Directory) {
      return new Stream.fromIterable(['Not a dir!']);
    }

    final expectedItems = new Set.from(_sourceMap.keys);

    return expandStream(entity.list(), (FileSystemEntity item) {

      final relative = pathos.relative(item.path,
          from: entity.path);

      final expected = expectedItems.remove(relative);
      if(expected) {
        final subValidator = convertToValidator(_sourceMap[relative]);

        return subValidator.getValidationErrors(item);
      } else {
        return new Stream.fromIterable(['Not expected: $item']);
      }

    }, onDone: () {
      return new Stream.fromIterable(expectedItems.map((item) {
          return 'Missing item $item';
        }));
    });
  }
}

Stream expandStream(Stream source, Stream convert(input), {Stream onDone()}) {
  final controller = new StreamController();

  Future itemFuture;

  source.listen((sourceItem) {
    Stream subStream = convert(sourceItem);
    Future next = _pipeStreamToController(controller, subStream);
    if(itemFuture == null) {
      itemFuture = next;
    } else {
      itemFuture = itemFuture.then((_) => next);
    }
  }, onDone: () {
    Future next = _pipeStreamToController(controller, onDone());
    if(itemFuture == null) {
      itemFuture = next;
    } else {
      itemFuture = itemFuture.then((_) => next);
    }
    itemFuture.whenComplete(() {
      controller.close();
    });
  });

  return controller.stream;
}

Future _pipeStreamToController(StreamController controller, Stream input) {
  final completer = new Completer();

  input.listen((data) {
    controller.add(data);
  }, onDone: () {
    completer.complete();
  });

  return completer.future;
}

Stream _streamFromIterableFuture(Future<Iterable> future) {
  final controller = new StreamController();

  future
    .then((Iterable values) {
      for(var value in values) {
        controller.add(value);
      }
    })
    .catchError((AsyncError error) {
      controller.addError(error.error, error.stackTrace);
    })
    .whenComplete(() {
      controller.close();
    });

  return controller.stream;

}

String _getStringSha1(String content) {
  final bytes = utf.encodeUtf8(content);
  final sha = new crypto.SHA1();
  sha.add(bytes);
  final sha1Bytes = sha.close();
  return crypto.CryptoUtils.bytesToHex(sha1Bytes);
}

Future<List<int>> _getFileSha1(File source) {
  final completer = new Completer<List<int>>();

  final sha1 = new crypto.SHA1();

  source.openRead()
    .listen((List<int> data) {
      sha1.add(data);
    },
    onDone: () {
      completer.complete(sha1.close());
    });

  return completer.future;
}

Future<String> _getSha1String(File source) =>
  _getFileSha1(source).then(crypto.CryptoUtils.bytesToHex);
