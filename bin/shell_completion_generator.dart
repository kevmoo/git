#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

const _templateName = 'command-completion.sh.template';
const _binNameReplacement = '{{binName}}';
const _funcNameReplacement = '{{funcName}}';
const _scriptDetailsReplacement = '{{details}}';

final _binNameMatch = new RegExp(r'^[a-zA-Z]((\w|-|\.)*[a-zA-Z0-9])?$');

/*
 * Inspiration:
 * https://github.com/isaacs/{{binName}}/blob/master/lib/utils/completion.sh
 */

void main() {
  final options = new Options();

  String binName;
  File templateFile;

  new Future.immediate(options.script)
    .then((String scriptPath) {
      if(scriptPath.isEmpty) {
        throw 'no script path provided';
      }

      if(options.arguments.isEmpty) {
        throw 'Provide the name of the command';
      }

      if(options.arguments.length > 1) {
        throw 'Provide only one argument';
      }

      binName = options.arguments.single;

      if(!_binNameMatch.hasMatch(binName)) {
        final msg = 'The provided name - "$binName" - is invalid\n'
            .concat('It must match regex: ${_binNameMatch.pattern}');
        throw msg;
      }

      // TODO: should probably validae the output binName, right?

      final scriptFile = new File(scriptPath);
      return scriptFile.directory();
    })
    .then((Directory dir) {
      final dirPath = new Path(dir.path);

      final templatePath = dirPath.append(_templateName);
      templateFile = new File.fromPath(templatePath);

      return templateFile.exists();
    })
    .then((bool exists) {
      if(!exists) {
        throw 'The template file - $templateFile - does not exist';
      }

      return templateFile.readAsString();
    })
    .then((String templateContents) {
      templateContents = templateContents.replaceAll(_binNameReplacement, binName);

      final funcName = binName.replaceAll('.', '_');
      templateContents = templateContents.replaceAll(_funcNameReplacement, funcName);

      final details = 'Generated on ${new DateTime.now()}';
      templateContents = templateContents.replaceAll(_scriptDetailsReplacement, details);

      print(templateContents);
    })
    .catchError((AsyncError error) {
      print(error.error);
      exit(1);
    });
}

