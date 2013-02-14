#!/bin/bash

# Inspired by
# https://github.com/isaacs/npm/blob/master/lib/utils/completion.sh

###-begin-hop-completion-###
#
# hop command completion script
#
# Installation:
#   'source' tool/hop-completion.bash into your environment
#

COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
COMP_WORDBREAKS=${COMP_WORDBREAKS/@/}
export COMP_WORDBREAKS

if type complete &>/dev/null; then
  _hop_completion () {
    local si="$IFS"
    IFS=$'\n' COMPREPLY=($(COMP_CWORD="$COMP_CWORD" \
                           COMP_LINE="$COMP_LINE" \
                           COMP_POINT="$COMP_POINT" \
                           hop completion -- "${COMP_WORDS[@]}" \
                           2>/dev/null)) || return $?
    IFS="$si"
  }
  complete -F _hop_completion hop
fi
###-end-hop-completion-###
