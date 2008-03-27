#!/bin/zsh

# This code is licensed under the GPL v2.  See LICENSE.txt for details.
  
# colorize.sh
# QLColorCode
#
# Created by Nathaniel Gray on 11/27/07.
# Copyright 2007 Nathaniel Gray.

# Expects   $1 = path to resources dir of bundle
#           $2 = name of file to colorize
#           $3 = 1 if you want enough for a thumbnail, 0 for the full file
#
# Produces HTML on stdout with exit code 0 on success

###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

rsrcDir=$1
target=$2
thumb=$3

hlDir=$rsrcDir/highlight
cmd=$hlDir/bin/highlight
cmdOpts=(-I --font $font --quiet --add-data-dir $rsrcDir/override \
         --data-dir $rsrcDir/highlight/share/highlight --style $hlTheme \
         --font-size $fontSizePoints ${=extraHLFlags})

#for o in $cmdOpts; do echo $o\<br/\>; done 

reader=(cat $target)

case $target in
    *.graffle )
        # some omnigraffle files are XML and get passed to us.  Ignore them.
        exit 1
        ;;
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

go4it () {
    if [ $thumb = "1" ]; then
        $reader | head -n 100 | head -c 20000 | $cmd --syntax $lang $cmdOpts && exit 0
    elif [ -n "$maxFileSize" ]; then
        $reader | head -c $maxFileSize | $cmd --syntax $lang $cmdOpts && exit 0
    else
        $reader | $cmd --syntax $lang $cmdOpts && exit 0
    fi
}

setopt no_err_exit
go4it
# Uh-oh, it didn't work.  Fall back to rendering the file as plain
lang=txt
go4it
