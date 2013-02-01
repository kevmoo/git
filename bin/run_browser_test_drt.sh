#!/bin/bash

# bail on error
set -e

DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

BROWSER_TEST_FILE=$DIR/../test/harness_browser.html

echo DumpRenderTree must be in your path for this to work
echo Running against test file at: 
echo $BROWSER_TEST_FILE

DUMP=$(DumpRenderTree $BROWSER_TEST_FILE)
echo "$DUMP"

REGEX="All [0-9]+ tests pass"

if [[ $DUMP =~ $REGEX ]]
then
  echo Success!
  exit 0
else
  echo Fail!
  exit 1
fi
