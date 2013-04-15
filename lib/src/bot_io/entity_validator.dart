part of bot_io;

class EntityValidator {

  static Stream<String> validateFileStringContent(File entity,
      String targetContent) =>
          validateFileContentSha(entity, _getStringSha1(targetContent));

  static Stream<String> validateFileContentSha(File entity, String targetSha) {
    if(entity is! File) {
      return new Stream.fromIterable(['entity is not a File']);
    }
    assert(targetSha != null);
    assert(targetSha.length == 40);

    var future = _getSha1String(entity)
        .then((String sha1) {
          if(sha1 == targetSha) {
            return [];
          } else {
            return ['content does not match: $entity'];
          }
        });

    return _streamFromIterableFuture(future);
  }

  static Stream<String> validateDirectoryFromMap(Directory entity,
      Map<String, dynamic> map) {
    if(entity is! Directory) {
      return new Stream.fromIterable(['entity is not a Directory']);
    }

    final expectedItems = new Set.from(map.keys);

    return expandStream(entity.list(), (FileSystemEntity item) {

      final relative = pathos.relative(item.path,
          from: entity.path);

      final expected = expectedItems.remove(relative);
      if(expected) {
        return validate(item, map[relative]);
      } else {
        return new Stream.fromIterable(['Not expected: $item']);
      }

    }, onDone: () {
      return new Stream.fromIterable(expectedItems.map((item) {
          return 'Missing item $item';
        }));
    });
  }

  static Stream<String> validate(FileSystemEntity entity, dynamic target) {
    if(target is String) {
      return validateFileStringContent(entity, target);
    } else if(target is Map) {
      return validateDirectoryFromMap(entity, target);
    } else {
      throw "Don't know how to deal with $target";
    }
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
