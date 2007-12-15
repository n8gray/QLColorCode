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

# You can customize the appearance by changing these parameters:
# Installed themes: acid, bipolar, blacknblue, bright, contrast, darkblue, 
#   darkness, desert, easter, emacs, golden, greenlcd, ide-anjuta, 
#   ide-codewarrior, ide-devcpp, ide-eclipse, ide-kdev, ide-msvcpp, ide-xcode, 
#   kwrite, lucretia, matlab, moe, navy, nedit, neon, night, orion, pablo, 
#   peachpuff, print, rand01, seashell, the, typical, vampire, vim-dark, vim, 
#   whitengrey, zellner
theme=ide-xcode
font=Monaco
fontSizePoints=9
#theme=slateGreen
#font=fixed
# For some reason 10 points gives me Fixed at 13 points.
#fontSizePoints=10

###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

rsrcDir=$1
target=$2
thumb=$3

hlDir=$rsrcDir/highlight
cmd=$hlDir/bin/highlight
cmdOpts=(-I --font $font --quiet --add-data-dir $rsrcDir/override \
         --data-dir $rsrcDir/highlight/share/highlight --style $theme \
         --font-size $fontSizePoints)

reader=(cat $target)
if [ $thumb = "1" ]; then
    filter=(head -n 100)
else
    filter=cat
fi

case $target in
    *.plist )
        lang=xml
        reader=(/usr/bin/plutil -convert xml1 -o - $target)
        ;;
    *.h )
        if grep -q "@interface" $target &> /dev/null; then
            lang=objc
        else
            lang=h
        fi
        ;;
    *.m )
        # look for a matlab-style comment in the first 10 lines, otherwise
        # assume objective-c.  If you never use matlab or never use objc,
        # you might want to hardwire this one way or the other
        if head -n 10 $target | grep -q "^ *%" &> /dev/null; then
            lang=m
        else
            lang=objc
        fi
        ;;
    * ) 
        lang=${target##*.}
    ;;
esac

setopt no_err_exit
$reader | $filter | $cmd --syntax $lang $cmdOpts && exit 0
# Uh-oh, it didn't work.  Fall back to rendering the file as plain
lang=txt
$reader | $filter | $cmd --syntax $lang $cmdOpts && exit 0
