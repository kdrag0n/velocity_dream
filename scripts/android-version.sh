#!/bin/sh

ver="8.0.0"

MAJOR=$(echo $ver | cut -d '.' -f 1)
MINOR=$(echo $ver | cut -d '.' -f 2)
PATCH=$(echo $ver | cut -d '.' -f 3)
if [ "x$PATCH" != "x" ] ; then
  printf "%d%02d%02d\\n" $MAJOR $MINOR $PATCH
else
  printf "%d%02d00\\n" $MAJOR $MINOR
fi
