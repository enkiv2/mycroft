# Prototype preprocessor for converting Mycroft syntax into Mycroft-RPN syntax
canonicalize() { # NB: strings aren't pre-chunked, so this will mangle them.
	sed 's/<\([0-9\.][0-9\.]*\)|/<\1,1>/g;s/|\([0-9\.][0-9\.]*\)>/<1,\1>/g'| # normalize bra-ket CTVs into canonical forms
	sed 's/\([^A-Za-z0-9_]\)YES\([^A-Za-z0-9_]\)/\1<1,1>\2/g;
		s/\([^A-Za-z0-9_]\)NO\([^A-Za-z0-9_]\)/\1<0,1>\2/g;
		s/\([^A-Za-z0-9_]\)NC\([^A-Za-z0-9_]\)/\1<0,0>\2/g' | 	# normalize named CTVs into canonical forms
	sed 's/^[ \t]*//;s/[ \t]*$//' | # trim lines
	sed 's/\t/ /g' | # tabs aren't meaningful
	tr -d '\r' | tr '\n' '\r' | sed 's/\([^\.]\)\r/\1 /g' | tr '\r' '\n' |	# get one statement per line
	sed 's/,/ , /g;s/\;/ \; /g' | # inject spaces around separators
	sed 's/<[ \t]*\([0-9\.][0-9.]*\)[ \t]*,[ \t]*\([0-9\.][0-9\.]*\)[ \t]*>/<\1,\2>/g' | # remove whitespace inside of CTVs
	sed 's/  */ /g' # collapse spaces
}
predEvert() {
	sed 's/\([a-z][A-Za-z0-9_]*\)()/\1\/0/g' | # foo() is foo/0
	sed 's/\([a-z][A-Za-z0-9_]*\)(\([^),]*\))/\2 \1\/1/g' | # foo(bar) is bar foo/1
	cat # TODO: general case for arity>1
}
canonicalize | predEvert
