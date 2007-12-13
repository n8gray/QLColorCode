QLColorCode
===========
<http://code.google.com/p/qlcolorcode/>

This is a Quick Look plugin that renders source code with syntax highlighting,
using the Highlight library: <http://www.andre-simon.de/index.html>

To install the plugin, just drag it to /Library/QuickLook or ~/Library/QuickLook.
You may need to create that folder if it doesn't already exist.

If you want to change the style of the syntax highlighting, take a look at 
colorize.sh in the bundle's Resources folder.

Highlight can handle lots and lots of languages, but this plugin will only be 
invoked for file types that the OS knows are type "source-code".  Since the OS
only knows about a limited number of languages, I've added Universal Type 
Identifier (UTI) declarations for several "interesting" languages.  If I've 
missed your favorite language, take a look at the Info.plist file inside the
plugin bundle and look for the UTImportedTypeDeclarations section.  I
haven't added all the languages that Highlight can handle because it's rumored
that having two conflicting UTI declarations for the same file extension can
cause problems.

To build from source, you need the Highlight library.  Download the source and 
uncompress it somewhere, then make a symbolic link to that location from 
./highlight

You'll also need to apply the highlight-2.6.6-getConfDir.diff patch. 
After that you should be able to build as usual from Xcode.

As an aside, by changing colorize.sh you can use this plugin to render any file
type that you can convert to HTML.  Have fun, and let me know if you do anything
cool!

Cheers,
-n8
n8gray /at/ n8gray \dot\ org
