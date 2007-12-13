#!/usr/bin/env python
#
#  colorize.py
#  QLColorCode
#
#  Created by Nathaniel Gray on 12/10/07.
#  Copyright (c) 2007 Nathaniel Gray. All rights reserved.
#

import os, sys
rsrcDir = sys.argv[1]
#os.chdir( rsrcDir + "/pygments")
#sys.path += '.'

import fnmatch
import pygments
from pygments.lexers import get_lexer_for_filename, get_lexer_by_name
from pygments.formatters import HtmlFormatter
from pygments import highlight

# If you want a different style change this to a string with one of these (e.g. "trac")
# Styles: manni, perldoc, borland, colorful, default, murphy, trac, fruity, autumn,
#         emacs, pastie, friendly, native
#style = "autumn"
from nautumn import NautumnStyle
style = NautumnStyle

overrides = (
    # pattern, pre-filter, lexer
    ('*.plist', '/usr/bin/plutil -convert xml1 -o - "%s"', 'xml'),
    ('*.mm', None, 'objc'),
    ('*.c[cp]', None, 'c++'),
    ('*.hh', None, 'c++'),
    ('*.command', None, 'sh')
    )

target = sys.argv[2]
thumb = sys.argv[3]

thumbBytes = 1024*4     # Only read this many bytes for thumbnail generation

if thumb == "1":
    limit = thumbBytes
else:
    limit = -1

# Use a custom formatter to add style info for the 'pre' tag
class customHtmlFormatter(HtmlFormatter):
    def wrap(self, source, outfile):
        return self._wrap_code(source)

    def _wrap_code(self, source):
        yield 0, '<div class="highlight"><pre style="font-family: Monaco; font-size: small">'
        for i, t in source:
            #if i == 1:
                # it's a line of formatted code
                #t += '\n'
            yield i, t
        yield 0, '</pre></div>'

# Find a matching lexer
match = None
for pattern, filter, lexer in overrides:
    if fnmatch.fnmatch(target, pattern):
        match = (filter % (target), get_lexer_by_name(lexer))
if match == None:
    try:
        match = (None, get_lexer_for_filename(target))
    except ClassNotFound:
        match = (None, get_lexer_for_filename("foo.txt"))

# Create the formatter
formatter = customHtmlFormatter(outencoding="UTF-8", full=True, style=style)

# Ok, everything is set up.  Read the file, possibly filtering it
if match[0] == None:
    inFile = open(target, "rt")
else:
    (childIn, inFile) = os.popen4(match[0])
    childIn.close()

contents = inFile.read(limit)
inFile.close()
highlight(contents, match[1], formatter, sys.stdout)
