#!/usr/bin/sh

echo ".TH mycroft 1 `date +%Y-%m-%d`"
./mycroft.lua -h | 
	tail -n +2 | 
	sed '
		s/$/\n/g;
		s/^\t\t*//;
		s/^Usage:/.SH SYNOPSIS/;
		s/mycroft/.B mycroft\n/g;
		s/^Options:/.SH DESCRIPTION\n.B mycroft\nis a prolog-like logic language with distribution and memoization.\n.SH OPTIONS/;
		s/^\([-+][a-z?][a-z?]*\)/.TP\n.BR \1/g;
		s/\t\t*/\n/g'
echo ".SH ENVIRONMENT"
echo "HOME"
echo 
echo ".SH FILES" 
echo 
echo -e "~/.mycroftrc\n/etc/.mycroftrc\n.RS\nA script in the Mycroft language that runs at startup. ~/.mycroftrc overrides /etc/.mycroftrc. If neither exists, the default configuration will be used.\n.RE\n"
echo -e "~/.mycrofthistory\n.RS\nAll lines executed in the interactive interpreter. (Requires readline support and the lua readline library.)\n.RE\n"
echo ".SH COPYING"
./mycroft.lua -ansi -e "?- help(copying)." | sed 's/^$/\n/g;s/[@-~]//g;s/\[0.//g'
echo ".SH SYNTAX"
./mycroft.lua -ansi -e "?- help(syntax)." | sed 's/^$/\n/g;s/[@-~]//g;s/\[0.//g;s/^\t\(.*\)$/.RS\n\1\n.RE\n/g'
echo ".SH BUILTINS"
./mycroft.lua -ansi -e "?- builtins()." | grep . | while read x ; do echo -e ".B $x\n.RS" ; ./mycroft.lua -ansi -e "?- help($x)." | sed 's/$/\n/g;s/^\t\(.*\)$/.RS\n\1\n.RE/g'; echo '.RE' ; done | sed 's/[@-~]//g;s/\[0.//g'
echo ".SH SEE ALSO"
echo "http://github.com/enkiv2/mycroft/"

