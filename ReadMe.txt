QLColorCode
===========
<http://code.google.com/p/qlcolorcode/>

This is a Quick Look plugin that renders source code with syntax highlighting,
using the Highlight library: <http://www.andre-simon.de/index.html>

To install the plugin, just drag it to /Library/QuickLook or ~/Library/QuickLook.
You may need to create that folder if it doesn't already exist.

If you want to configure QLColorCode, there are several "defaults" commands 
that could be useful:

Setting the text encoding (default is UTF-8):
    defaults write org.n8gray.QLColorCode textEncoding UTF-16
    defaults write org.n8gray.QLColorCode webkitTextEncoding UTF-16
Setting the font:
    defaults write org.n8gray.QLColorCode font Monaco
the font size:
    defaults write org.n8gray.QLColorCode fontSizePoints 9
the color style (see below):
    defaults write org.n8gray.QLColorCode hlTheme ide-xcode
any extra command-line flags for Highlight (see below):
    defaults write org.n8gray.QLColorCode extraHLFlags '-l -W'
the maximum size (in bytes) for previewed files:
    defaults write org.n8gray.QLColorCode maxFileSize 1000000

The following color styles are included with QLColorCode:
   acid, bipolar, blacknblue, bright, contrast, darkblue, 
   darkness, desert, easter, emacs, golden, greenlcd, ide-anjuta, 
   ide-codewarrior, ide-devcpp, ide-eclipse, ide-kdev, ide-msvcpp, ide-xcode, 
   kwrite, lucretia, matlab, moe, navy, nedit, neon, night, orion, pablo, 
   peachpuff, print, rand01, seashell, slateGreen, the, typical, vampire, 
   vim-dark, vim, whitengrey, zellner

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
              wrap long lines (use with caution)

       -z, --zeroes
              fill leading space of line numbers with zeroes

       --kw-case=<upper|lower>
              output  all keywords in upper/lower case if language is not
              case sensitive

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

You'll also need to apply the relevant patch-highlight-*.diff patches. 
After that you should be able to build as usual from Xcode.

As an aside, by changing colorize.sh you can use this plugin to render any file
type that you can convert to HTML.  Have fun, and let me know if you do anything
cool!

Cheers,
-n8
n8gray /at/ n8gray \dot\ org
