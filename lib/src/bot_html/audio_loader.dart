part of bot_html;

class AudioLoader extends ResourceLoader<AudioBuffer> {
  final AudioContext context;

  AudioLoader(this.context, Iterable<String> urlList) :
    super(urlList);

  @override
  Future<AudioBuffer> _doLoad(String blobUrl) {
    return HttpRequest.request(blobUrl, responseType: 'arraybuffer')
        .then((HttpRequest request) {
          return _decode(request.response);
        });
  }

  Future<AudioBuffer> _decode(ArrayBuffer audioData) {
    final completer = new Completer<AudioBuffer>();

    context.decodeAudioData(audioData,
        (buffer) => completer.complete(buffer),
        (buffer) => completer.completeError('There was an error decoding the audio'));

    return completer.future;
  }
}
