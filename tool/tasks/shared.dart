library tool.tasks.shared;

import 'dart:async';
import 'dart:io';

import 'package:html5lib/dom.dart' as dom;
import 'package:html5lib/parser.dart';

import 'package:bot/bot.dart';

Future<bool> transformHtml(String filePath,
    Func1<dom.Document, Future<dom.Document>> transformer) {

  return transformFile(filePath, (String content) {
    var parser = new HtmlParser(content, generateSpans: true);
    var document = parser.parse();

    return transformer(document)
        .then((dom.Document newDoc) {
          return newDoc.outerHtml;
        });
  });
}

Future<bool> transformFile(String filePath,
    Func1<String, Future<String>> transformer) {

  final file = new File(filePath);
  assert(file.existsSync());

  String oldContent;

  return file.readAsString()
      .then((String value) {
        oldContent = value;
        return transformer(oldContent);
      })
      .then((String newContent) {
        // we're assuming file hasn't changed since we started
        if(newContent == oldContent) {
          // nothing changed
          return false;
        } else {
          return file.writeAsString(newContent, mode: FileMode.WRITE)
              .then((_) => true);
        }
      });
}
