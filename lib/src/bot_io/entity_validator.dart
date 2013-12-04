part of bot_io;

abstract class EntityValidator {

  static Stream<String> validateFileStringContent(File entity,
      String targetContent) {
    return validateFileContentSha(entity, _getStringSha1(targetContent));
  }

  static Stream<String> validateFileContentSha(FileSystemEntity entity,
      String targetSha) {
    if(entity is! File) {
      return new Stream.fromIterable(['entity is not a File']);
    }
    assert(targetSha != null);
    assert(targetSha.length == 40);

    var future = fileSha1Hex(entity)
        .then((String sha1) {
          if(sha1 == targetSha) {
            return null;
          } else {
            return 'content does not match: $entity';
          }
        });

    return _oneOrNoneOnNull(future);
  }

  static Stream<String> validateDirectoryFromMap(FileSystemEntity entity,
      Map<String, dynamic> map) {
    if(entity is! Directory) {
      return new Stream.fromIterable(['entity is not a Directory']);
    }

    Directory dir = entity;

    final expectedItems = new Set.from(map.keys);

    return _expandStream(dir.list(), (FileSystemEntity item) {

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
    if(target is EntityValidator) {
      return target.validateEntity(entity);
    } else if(target is String) {
      return validateFileStringContent(entity, target);
    } else if(target is Map) {
      return validateDirectoryFromMap(entity, target);
    } else {
      throw new ArgumentError("Don't know how to deal with $target");
    }
  }

  Stream<String> validateEntity(FileSystemEntity entity);
}

class EntityExistsValidator implements EntityValidator {
  final FileSystemEntityType entityType;

  EntityExistsValidator([this.entityType]) {
    assert(entityType != FileSystemEntityType.NOT_FOUND);
  }

  @override
  Stream<String> validateEntity(FileSystemEntity entity) {
    assert(entity != null);
    return _oneOrNoneOnNull(_getValidation(entity));
  }

  Future<String> _getValidation(FileSystemEntity entity) {
    assert(entity != null);

    final entType = _getType(entity);
    if(entityType == null || entityType == entType) {
      return _exists(entity)
          .then((bool exists) {
            if(exists) {
              return null;
            }
            return "$entity does not exist on disk";
          });
    }

    return new Future.value(
        "Expected $entity to be $entityType, but it is $entType");
  }

  static Future<bool> _exists(FileSystemEntity entity) {
    if(entity is Directory) {
      return entity.exists();
    } else if(entity is File) {
      return entity.exists();
    } else if(entity is Link) {
      return entity.exists();
    }
    throw new ArgumentError('entity $entity is not supported');
  }

  static FileSystemEntityType _getType(FileSystemEntity entity) {
    assert(entity != null);
    if(entity is File) {
      return FileSystemEntityType.FILE;
    } else if(entity is Directory) {
      return FileSystemEntityType.DIRECTORY;
    } else {
      assert(entity is Link);
      return FileSystemEntityType.LINK;
    }
  }
}

// TODO: move to bot?
// TODO: test more, especially failure cases
/**
 * **DEPRECATED**. This should not be a top-level method. Will be removed.
 */
@deprecated
Stream expandStream(Stream source, Stream convert(input), {Stream onDone()}) =>
    _expandStream(source, convert, onDone: onDone);

Stream _expandStream(Stream source, Stream convert(input), {Stream onDone()}) {

  var expander = new _StreamExpander(source, convert, onDone);
  return expander.stream;
}

class _StreamExpander<T, S> {
  final Func1<T, Stream<S>> _converter;
  final Func<Stream<S>> _onDone;
  final StreamIterator<T> _iterator;

  final StreamController<S> _controller = new StreamController();

  _StreamExpander(Stream<T> source, this._converter, [this._onDone]) :
    this._iterator = new StreamIterator(source) {
    _moveNext();
  }

  Stream<S> get stream => _controller.stream;

  void _moveNext() {
    // TODO: handle case where moveNext yields an error
    _iterator.moveNext().then((bool hasNext) {
      if(!hasNext) {
        _finish();
        return;
      }

      // TODO: handle case where convert throws
      var subStream = _converter(_iterator.current);

      _controller.addStream(subStream)
        .then((_) => _moveNext());
    });
  }

  void _finish() {
    if(_onDone != null) {
      // TODO: handle case where onDone throws
      _controller.addStream(_onDone())
        .whenComplete(_close);
    } else {
      _close();
    }
  }

  void _close() {
    _controller.close();
  }

}

// TODO: move to bot?
Future _pipeStreamToController(StreamController controller, Stream input) {
  final completer = new Completer();

  input.listen((data) {
    print('got stream item ${input.hashCode}');
    controller.add(data);
  }, onDone: () {
    completer.complete();
  });

  return completer.future;
}

Stream _oneOrNoneOnNull(Future future) => new Stream.fromFuture(future)
    .where((e) => e != null);

String _getStringSha1(String content) {
  final bytes = UTF8.encode(content);
  final sha = new crypto.SHA1();
  sha.add(bytes);
  final sha1Bytes = sha.close();
  return crypto.CryptoUtils.bytesToHex(sha1Bytes);
}
