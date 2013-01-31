#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the LICENSE file
# for details. All rights reserved. Use of this source code is governed by a
# MIT-style license that can be found in the LICENSE file.

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
