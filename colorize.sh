#!/bin/zsh

# This code is licensed under the GPL v2.  See LICENSE.txt for details.
  
# colorize.sh
# QLColorCode
#
# Created by Nathaniel Gray on 11/27/07.
# Copyright 2007 Nathaniel Gray. All rights reserved.

# Expects   $1 = path to resources dir of bundle
#           $2 = name of file to colorize
#           $3 = 1 if you want enough for a thumbnail, 0 for the full file
#
# Produces HTML on stdout with exit code 0 on success

# Fail immediately on failure of sub-command
setopt err_exit

rsrcDir=$1
target=$2
thumb=$3

thumblines=50
font=Monaco

hlDir=$rsrcDir/highlight
cmd=$hlDir/bin/highlight
cmdOpts=(-I --font $font --quiet --add-data-dir $rsrcDir/override \
         --data-dir $rsrcDir/highlight/share/highlight)

reader=(cat $target)
if [ $thumb = "1" ]; then
    filter=(head -n $thumblines)
else
    filter=cat
fi

case $target in
    *.plist )
        lang=xml
        reader=(/usr/bin/plutil -convert xml1 -o - $target)
        ;;
    * )         lang=${target##*.}
    ;;
esac

$reader | $filter | $cmd --syntax $lang $cmdOpts