" Vim syntax file
" Language: Mycroft
" Maintainer: John Ohno
" Latest Revision: 24 August 2015

if exists("b:current_syntax")
	finish
end

" Keywords
syn keyword mycKeywordCTV YES NO NC
syn keyword mycState det nondet
syn keyword builtin  add addpeer append banner builtins catch concat copying div equal eval exit false forward forwardAll gt gte help lindex lset lt lte mul nc not pprint pputs print printPred printWorld puts runtests set setForwarding sethelp sub throw true

" Matches
syn match atom '[a-z_][a-zA-Z0-9_]*'
syn match pred '[a-z_][a-zA-Z0-9_]* *('
syn match mycCTV1 '< *[0-1]\.[0-9]* *, *[0-1]\.[0-9]* *>'
syn match mycCTV2 '< *[0-1]\.[0-9]* *|'
syn match mycCTV3 '|[0-1]\.[0-9]* *>'
syn match mycCTV4 '< *[0-1] *, *[0-1]\.[0-9]* *>'
syn match mycCTV5 '< *[0-1] *|'
syn match mycCTV6 '| *[0-1] *>'
syn match mycCTV7 '< *[0-1]\.[0-9] *, *[0-1] *>'
syn match mycCTV8 '< *\.[0-9]* *, *\.[0-9]* *>'
syn match mycCTV9 '< *\.[0-9]* *|'
syn match mycCTV10 '|\.[0-9]* *>'
syn match mycCTV11 '< *[0-1]\.[0-9]* *, *\.[0-9]* *>'
syn match mycCTV12 '< *\.[0-9]* *, *[0-1]\.[0-9]* *>'
syn match mycCTV13 '< *[0-1] *, *\.[0-9]* *>'
syn match mycCTV14 '< *\.[0-9]* *, *[0-1] *>'
syn match str '\"[^\"]*\"'
syn match lineSep1 '^?-'
syn match lineSep2 ':-'
syn match lineSep3 '.$'
syn match comment '^#.*$'
syn match leftbanana '('
syn match rightbanana ')'
syn match var '[A-Z][a-zA-Z0-9]*'

let b:current_syntax = "mycroft"

hi def link mycKeywordCTV 	Number
hi def link mycCTV1 		Number
hi def link mycCTV2 		Number
hi def link mycCTV3 		Number
hi def link mycCTV4 		Number
hi def link mycCTV5 		Number
hi def link mycCTV6 		Number
hi def link mycCTV7 		Number
hi def link mycCTV8 		Number
hi def link mycCTV9 		Number
hi def link mycCTV10 		Number
hi def link mycCTV11 		Number
hi def link mycCTV12 		Number
hi def link mycCTV13 		Number
hi def link mycCTV14 		Number
hi def link atom 		String
hi def link str 		String
hi def link mycState 		Keyword
hi def link lineSep1 		Operator
hi def link lineSep2 		Operator
hi def link lineSep3 		Operator
hi def link builtin 		Keyword
hi def link pred 		Function
hi def link comment 		Comment
hi def link leftbanana 		Operator
hi def link rightbanana 	Operator
hi def link var 		Identifier

hi Function ctermfg=cyan
hi Operator ctermfg=green
hi Number ctermfg=yellow
hi Keyword ctermfg=magenta

