library tool.tasks.update_example_html;

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/parser.dart';
import 'package:html5lib/dom_parsing.dart';

const _startPath = r'example/bot_retained/';
const _demoFinder = r'**/*_demo.html';
final _exampleFile = _startPath.concat('index.html');

Task getUpdateExampleHtmlTask() {
  return new Task.async((ctx) {
    return _getExampleFiles()
        .then((List<String> demos) {
          ctx.info(demos.join('\n'));

          return _transform(demos);
        })
        .then((bool updated) {
          final String msg = updated ? '$_exampleFile updated!' : 'No changes to $_exampleFile';
          ctx.info(msg);
          return true;
        });
  });
}

Future<bool> _transform(List<String> samples) {
  final file = new File(_exampleFile);
  assert(file.existsSync());
  return file.readAsString()
      .then((String contents) {
        var parser = new HtmlParser(contents, generateSpans: true);
        var document = parser.parse();
        _tweakDocument(document, samples);
        return _updateIfChanged(_exampleFile, document.outerHtml);
      });
}

void _tweakDocument(Document doc, List<String> samples) {

  final sampleList = doc.queryAll('ul')
      .where((Element e) => e.id == 'demo-list')
      .single;

  print(sampleList.outerHtml);

  sampleList.children.clear();

  for(final example in samples) {
    final anchor = new Element.tag('a')
      ..attributes['href'] = '$example/${example}_demo.html'
      ..attributes['target'] = 'demo'
      ..innerHtml = example;

    final li = new Element.tag('li')
      ..children.add(anchor);
    sampleList.children.add(li);
  }

}

Future<bool> _updateIfChanged(String filePath, String newContent) {
  final file = new File(filePath);
  return file.exists()
      .then((bool exists) {
        if(exists) {
          return file.readAsString()
              .then((String content) => content != newContent);
        } else {
          return true;
        }
      }).then((bool shouldUpdate) {
        if(shouldUpdate) {
          return file.writeAsString(newContent)
            .then((_) => true);
        } else {
          return false;
        }
      });
}

Future<List<String>> _getExampleFiles() {
  final findStr = _startPath.concat(_demoFinder);
  return Process.run('bash', ['-c', 'find $findStr'])
      .then((ProcessResult pr) {
        return Util.splitLines(pr.stdout.trim())
            .map((path) {
              assert(path.startsWith(_startPath));
              final lastSlash = path.lastIndexOf('/');
              final name = path.substring(_startPath.length, lastSlash);
              // this could be a lot prettier...but...eh
              assert(path == "$_startPath$name/${name}_demo.html");
              return name;
            })
            .toList();
      });
}
