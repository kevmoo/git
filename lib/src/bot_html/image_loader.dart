part of bot_html;

class ImageLoader extends ResourceLoader<ImageElement> {
  ImageLoader(Iterable<String> urls) : super(urls);

  @override
  Future<ImageElement> _doLoad(String blobUrl) {
    final img = new ImageElement(src: blobUrl);
    assert(!img.complete);

    final completer = new Completer<ImageElement>();

    img.onLoad.listen((args) {
      assert(args.type == 'load');
      completer.complete(img);
    });

    return completer.future;

  }
}
