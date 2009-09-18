QLColorCode
===========
<http://code.google.com/p/qlcolorcode/>

===============================================================================
IMPORTANT NOTE FOR XCODE 3.2 (SHIPPED WITH SNOW LEOPARD) USERS:
If you are running Xcode 3.2 or higher you will probably not see QLColorCode's 
output unless you disable Xcode's built-in source code qlgenerator.  
See the end of this file for details.
===============================================================================

This is a Quick Look plugin that renders source code with syntax highlighting,
using the Highlight library: <http://www.andre-simon.de/index.html>

To install the plugin, just drag it to /Library/QuickLook or ~/Library/QuickLook.
You may need to create that folder if it doesn't already exist.

If you want to configure QLColorCode, there are several "defaults" commands 
that could be useful:

Setting the text encoding (default is UTF-8).  Two settings are required.  The
first sets Highlight's encoding, the second sets Webkit's:
    defaults write org.n8gray.QLColorCode textEncoding UTF-16
    defaults write org.n8gray.QLColorCode webkitTextEncoding UTF-16
    
Setting the font:
    defaults write org.n8gray.QLColorCode font Monaco
    
the font size:
    defaults write org.n8gray.QLColorCode fontSizePoints 9
    
the color style (see http://www.andre-simon.de/dokuwiki/doku.php?id=theme_examples
or try slateGreen to see how I roll):
    defaults write org.n8gray.QLColorCode hlTheme ide-xcode
    
any extra command-line flags for Highlight (see below):
    defaults write org.n8gray.QLColorCode extraHLFlags '-l -W'
    
the maximum size (in bytes) for previewed files:
    defaults write org.n8gray.QLColorCode maxFileSize 1000000

Here are some useful 'highlight' command-line flags (from the man page):
       -F, --reformat=<style>
              reformat output in given style.   <style>=[ansi,  gnu,  kr,
              java, linux]

       -J, --line-length=<num>
              line length before wrapping (see -W, -V)

       -j, --line-number-length=<num>
              line number length incl. left padding

       -l, --linenumbers
              print line numbers in output file

       -t  --replace-tabs=<num>
              replace tabs by num spaces

       -V, --wrap-simple
              wrap long lines without indenting function  parameters  and
              statements

       -W, --wrap
              wrap long lines

       -z, --zeroes
              fill leading space of line numbers with zeroes

       --kw-case=<upper|lower|capitalize>
              control case of case insensitive keywords

Highlight can handle lots and lots of languages, but this plugin will only be 
invoked for file types that the OS knows are type "source-code".  Since the OS
only knows about a limited number of languages, I've added Universal Type 
Identifier (UTI) declarations for several "interesting" languages.  If I've 
missed your favorite language, take a look at the Info.plist file inside the
plugin bundle and look for the UTImportedTypeDeclarations section.  I
haven't added all the languages that Highlight can handle because it's rumored
that having two conflicting UTI declarations for the same file extension can
cause problems.  Note that if you do edit the Info.plist file you need to 
nudge the system to tell it something has changed.  Moving the plugin to the
desktop then back to its installed location should do the trick.

To build from source, you need the Highlight library.  Download the source and 
uncompress it somewhere, then make a symbolic link to that location from 
./highlight

As an aside, by changing colorize.sh you can use this plugin to render any file
type that you can convert to HTML.  Have fun, and let me know if you do anything
cool!

====================================================================
Important information on using QLColorCode with Xcode v3.2 and later
====================================================================

The most up-to-date copy of this info will be found here:
  http://code.google.com/p/qlcolorcode/wiki/ImportantNoteForXcodeUsers

Xcode 3.2 (the version shipped with Snow Leopard) includes a Quick Look plugin 
that highlights source code. It only highlights a few languages, so you probably
still want to use QLColorCode. However, the Quick Look server tends to pick the
Xcode plugin over QLCC. This means that for any source code file aside from .c,
.m, and the other languages that Xcode understands you'll see a plain text
preview with no highlighting. To get QLCC to work properly you'll need to 
disable the Xcode plugin.

Details
-------

The Xcode plugin is installed at:

/Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator
The simplest way to disable it is to open Terminal.app and run these commands:

  f=/Developer/Applications/Xcode.app/Contents/Library/QuickLook/SourceCode.qlgenerator
  sudo mv $f $f.disabled

This will rename the plugin to SourceCode.qlgenerator.disabled, which will 
prevent it from being loaded by quicklookd.

A Note on Code Signing
----------------------

The Xcode application is cryptographically signed. Disabling the 
SourceCode.qlgenerator plugin will NOT invalidate the signature. You can 
confirm this by using the codesign command after disabling the plugin:

  [n8gray@golux]% codesign -vv /Developer/Applications/Xcode.app
  /Developer/Applications/Xcode.app: valid on disk
  /Developer/Applications/Xcode.app: satisfies its Designated Requirement

Cheers,
-n8
n8gray /at/ n8gray \dot\ org
