library tool.tasks.dartdoc;

import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:pathos/path.dart' as path;
import 'package:html5lib/dom.dart';

import 'shared.dart';

const _sourceTitle = 'Dart Documentation';
const _outputTitle = 'BOT Documentation';

Future postBuild(TaskLogger logger, String tempDocDir) {

  final indexPath = path.join(tempDocDir, 'index.html');

  logger.info('Updating main page');
  return transformHtml(indexPath, _updateIndex)
      .then((_) {
        logger.info('Fixing titles');
        return _updateTitles(tempDocDir);
      })
      .then((_) {
        logger.info('Copying resources');
        return Process.run('bash', ['-c', 'cp resource/* $tempDocDir']);
      })
      .then((ProcessResult pr) {
        assert(pr.exitCode == 0);
      });
}

Future _updateTitles(String tempDocDir) {
  final dir = new Directory(tempDocDir);
  return dir.list(recursive:true)
      .where((FileSystemEntity fse) => fse is File)
      .map((File f) => f.path)
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
  return new Future<String>.value(source);
}

Future<Document> _updateIndex(Document source) {
  final contentDiv = source.queryAll('div')
      .singleWhere((Element div) => div.attributes['class'] == 'content');

  // should only have h3 and h4 elements
  final botHeaders = new List<Element>();
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
      } else {
        otherHeaders.add(child);
      }
    }
  }

  contentDiv.children.clear();

  contentDiv.children.add(new Element.tag('h2')
    ..innerHtml = 'Dart Bag of Tricks');

  contentDiv.children.add(_getAboutElement());

  final doSection = (String name, List<Element> sectionContent) {
    if(!sectionContent.isEmpty) {
      contentDiv.children.add(new Element.tag('h3')
        ..innerHtml = name);

      contentDiv.children.addAll(sectionContent);
    }

  };

  doSection('Dart Bag of Tricks', botHeaders);
  doSection('Dependencies', otherHeaders);

  return new Future<Document>.value(source);
}

Element _getAboutElement() {
  final logo = new Element.tag('img')
    ..attributes['src'] = 'logo.png'
    ..attributes['width'] = '333'
    ..attributes['height'] = '250'
    ..attributes['title'] = 'Dart Bag of Tricks';

  final logoLink = new Element.tag('a')
    ..attributes['href'] = 'https://github.com/kevmoo/bot.dart'
    ..children.add(logo);

  final ghLink = new Element.tag('a')
  ..attributes['href'] = 'https://github.com/kevmoo/bot.dart'
  ..innerHtml = 'github.com/kevmoo/bot.dart';


  return new Element.tag('div')
    ..attributes['class'] = 'about'
    ..children.add(logoLink)
    ..children.add(new Element.tag('br'))
    ..children.add(ghLink);
}
