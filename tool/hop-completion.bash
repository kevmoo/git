#!bash
#
# bash completion script for Dart 'hop'
# Part of the Dart Bag of Tricks
# https://github.com/kevmoo/bot.dart
#
# This script assumes [bot.dart root]/bin/hop is in your path
#

_hop() 
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  # capture both stdout and stderr
  opts=`hop print_raw_task_list 2>&1`

  # if exit code for `hop` is not 0, then return an error
  # probably not in a directory with tool/hop_runner.dart
  if [ $? -ne 0 ] ; then 
    return 1
  fi

  if [[ ${cur} == -* || ${COMP_CWORD} -eq 1 ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
  fi
}
complete -F _hop hop
