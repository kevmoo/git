library tool.tasks.dartdoc;

import 'dart:async';
import 'dart:io';
import 'package:bot/hop.dart';
import 'package:pathos/path.dart' as path;
import 'package:html5lib/dom.dart';

import 'shared.dart';

const _sourceTitle = 'Dart Documentation';
const _outputTitle = 'BOT Documentation';

Future postBuild(TaskLogger logger, String tempDocDir) {
  logger.info('Group the main toc');

  final indexPath = path.join(tempDocDir, 'index.html');
  logger.fine('index file: $indexPath');

  return transformHtml(indexPath, _updateIndex)
      .then((_) {
        return _updateTitles(tempDocDir);
      });
}

Future _updateTitles(String tempDocDir) {
  final dir = new Directory(tempDocDir);
  return dir.list(recursive:true)
      .where((FileSystemEntity fse) => fse is File)
      .map((File f) => f.name)
      .where((String path) => path.endsWith('.html'))
      .toList()
      .then((List<String> files) {
        return Future.forEach(files, (String filePath) {
          return transformFile(filePath, _updateTitle);
        });
      });
}

Future<String> _updateTitle(String source) {
  final weirdDoubleTitle = '$_sourceTitle / $_sourceTitle';
  source = source.replaceAll(weirdDoubleTitle, _sourceTitle);

  source = source.replaceAll(_sourceTitle, _outputTitle);
  return new Future<String>.immediate(source);
}

Future<Document> _updateIndex(Document source) {
  final contentDiv = source.queryAll('div')
      .singleMatching((Element div) => div.attributes['class'] == 'content');

  // should only have h3 and h4 elements
  final botHeaders = new List<Element>();
  final hopHeaders = new List<Element>();
  final otherHeaders = new List<Element>();

  for(final child in contentDiv.children) {
    assert(child.tagName == 'h2' || child.tagName == 'h3' || child.tagName == 'h4');

    if(child.tagName == 'h4') {
      assert(child.children.length == 1);

      final anchor = child.children[0];
      assert(anchor.tagName == 'a');

      final libName = anchor.innerHtml;

      if(libName.startsWith('bot')) {
        botHeaders.add(child);
      } else if(libName.startsWith('hop')) {
        hopHeaders.add(child);
      } else {
        otherHeaders.add(child);
      }
    }
  }

  contentDiv.children.clear();

  contentDiv.children.add(new Element.tag('h2')
    ..innerHtml = 'Dart Bag of Tricks');

  final doSection = (String name, List<Element> sectionContent) {
    if(!sectionContent.isEmpty) {
      contentDiv.children.add(new Element.tag('h3')
        ..innerHtml = name);

      contentDiv.children.addAll(sectionContent);
    }

  };

  doSection('Dart Bag of Tricks', botHeaders);
  doSection('Hop task system', hopHeaders);
  doSection('Dependencies', otherHeaders);

  return new Future<Document>.immediate(source);
}
