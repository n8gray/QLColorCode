#!/usr/bin/osascript

on run
	do shell script "if test \\! -d /Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator.disabled; then echo 'I could not locate the disabled XCode plugin.  Have you already restored it?'; exit 1; fi"
	do shell script "if test -e /Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator; then echo 'There is already a plugin named /Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator\\n\\nI will not overwrite it.'; exit 1; fi"
	do shell script "x=/Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator; sudo mv $x.disabled $x" with administrator privileges
	do shell script "qlmanage -r"
	display dialog "The XCode plugin has been restored" buttons {"OK"} default button 1
	
end run
