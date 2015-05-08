# Mycroft syntax

Mycroft has a prolog-like syntax, consisting of predicate definitions and 
queries.

A predicate definition is of the form:

    det predicateName(Arg1, Arg2...) :- predicateBody.

where predicateBody consists of a list of references to other predicates and 
truth values.

A predicate that is marked 'det' is determinate -- if it ever evaluates to a 
different value than it has cached, an error is thrown. An indeterminate 
predicate can be marked 'nondet' instead, meaning that its return value can 
change and so results from it will not be memoized.

A predicate body is of the form:

    item1, item2... ; itemA, itemB...

where each item is either a reference to a predicate or a truth value. Sections 
separated by ';' are ORed together, while items separated by ',' are ANDed 
together.

A reference to a predicate is of the form predicateName(Arg1, Arg2...)

A truth value (or composite truth value, or CTV) is of the form

    <Truth, Confidence>

where both Truth and Confidence are floating point values between 0 and 1. 
<X| is syntactic sugar for <X,1.0>; |X> is syntactic sugar for <1.0,X>; 
YES is syntactic sugar for <1.0, 1.0>; NO is syntactic sugar for <0.0, 1.0>; 
and, NC is syntactic sugar for <X,0.0> regardless of the value of X.

A query is of the form:

    ?- predicateBody.

The result of a query will be printed to standard output.

Comments begin with a hash mark:

    # This is a "comment".

Variables begin with a capital letter, and are immutable:

    ?- set(X, "Hello"), print(X). 		# prints "Hello"
    ?- set(X, "Hello"), set(X, "Goodbye"). 	# fails
    ?- set(x, "Hello"). 			# also fails

Strings are surrounded by double quotes, however, words containing only 
letters, numbers, and underscores that do not begin with an uppercase letter 
will be evaluated as strings. Unbound variables will also evaluate as the 
string value of their names:

    ?- equal(hello, "hello"). 		# true
    ?- equal(X, "X"). 			# also true
