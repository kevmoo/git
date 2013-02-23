#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

const _templateName = 'command-completion.sh.template';
const _binNameReplacement = '{{binName}}';
const _funcNameReplacement = '{{funcName}}';
const _scriptDetailsReplacement = '{{details}}';

/*
 * Must be at least one char.
 * Must start with a letter or number
 * Can contain letters, numbers, '_', '-', '.'
 * Must end with letter or number
 */
final _binNameMatch = new RegExp(r'^[a-zA-Z0-9]((\w|-|\.)*[a-zA-Z0-9])?$');

/*
 * Format for unified bash and zsh completion script:
 * https://npmjs.org/
 * https://github.com/isaacs/npm/blob/master/lib/utils/completion.sh
 *
 * Inspiration for auto-generating completion scripts:
 * https://github.com/mklabs/node-tabtab
 * https://github.com/mklabs/node-tabtab/blob/master/lib/completion.sh
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

      var funcName = binName.replaceAll('.', '_');
      funcName = '__${funcName}_completion';
      templateContents = templateContents.replaceAll(_funcNameReplacement, funcName);

      final detailLines = ['Generated ${new DateTime.now().toUtc()}', 'By ${options.script}'];

      final details = detailLines.map((l) => '## $l').join('\n');
      templateContents = templateContents.replaceAll(_scriptDetailsReplacement, details);

      print(templateContents);
    })
    .catchError((AsyncError error) {
      print(error.error);
      exit(1);
    });
}

