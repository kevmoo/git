#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';

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

  final binNames = new List<String>();
  File templateFile;

  new Future.immediate(options.script)
    .then((String scriptPath) {
      if(scriptPath.isEmpty) {
        throw 'no script path provided';
      }

      if(options.arguments.isEmpty) {
        throw 'Provide the of at least of one command';
      }

      for(final binName in options.arguments) {
        if(!_binNameMatch.hasMatch(binName)) {
          final msg = 'The provided name - "$binName" - is invalid\n'
              'It must match regex: ${_binNameMatch.pattern}';
          throw msg;
        }
      }

      binNames.addAll(options.arguments);

      final prefix = Util.splitLines(_prefix)
          .map((l) => '# $l'.trim())
          .join('\n');
      print(prefix);

      // empty line
      print('');

      for(final binName in binNames) {
        _printBinName(binName);
      }

      final detailLines = ['Generated ${new DateTime.now().toUtc()}', 'By ${options.script}'];

      final details = detailLines.map((l) => '## $l').join('\n');
      print(details);

      // and a final newline
      print('');
    })
    .catchError((AsyncError error) {
      print(error.error);
      exit(1);
    });
}

void _printBinName(String binName) {
  var templateContents = _template.replaceAll(_binNameReplacement, binName);

  var funcName = binName.replaceAll('.', '_');
  funcName = '__${funcName}_completion';
  templateContents = templateContents.replaceAll(_funcNameReplacement, funcName);

  print(templateContents);
}

const _prefix = '''

Installation:

Via shell config file  ~/.bashrc  (or ~/.zshrc)

  Append the contents to config file
  'source' the file in the config file

You may also have a directory on your system that is configured
   for completion files, such as:

   /usr/local/etc/bash_completion.d/
''';

const _template = r'''
###-begin-{{binName}}-completion-###

if type complete &>/dev/null; then
  {{funcName}}() {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           {{binName}} completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F {{funcName}} {{binName}}
elif type compdef &>/dev/null; then
  {{funcName}}() {
    si=$IFS
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                 COMP_LINE=$BUFFER \
                 COMP_POINT=0 \
                 {{binName}} completion -- "${words[@]}" \
                 2>/dev/null)
    IFS=$si
  }
  compdef {{funcName}} {{binName}}
elif type compctl &>/dev/null; then
  {{funcName}}() {
    local cword line point words si
    read -Ac words
    read -cn cword
    let cword-=1
    read -l line
    read -ln point
    si="$IFS"
    IFS=$'\n' reply=($(COMP_CWORD="$cword" \
                       COMP_LINE="$line" \
                       COMP_POINT="$point" \
                       {{binName}} completion -- "${words[@]}" \
                       2>/dev/null)) || return $?
    IFS="$si"
  }
  compctl -K {{funcName}} {{binName}}
fi

###-end-{{binName}}-completion-###
''';
