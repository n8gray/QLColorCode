#!/usr/bin/osascript

on run
	do shell script "if test \\! -d /Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator; then echo 'I could not locate the XCode plugin.  Have you already disabled it?'; exit 1; fi"
	do shell script "x=/Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator; sudo rm -rf $x.disabled; sudo mv $x $x.disabled" with administrator privileges
	do shell script "qlmanage -r"
	display dialog "The XCode plugin has been disabled" buttons {"OK"} default button 1
end run
