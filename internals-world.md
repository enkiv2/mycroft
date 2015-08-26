# Mycroft internals: the world

The world is an object containing all meaningful information about the interpreter's internal state.

The world has the following attributes:

	world.MYCERR -- see [Error Internals](internals-err.md)
	world.MYCERR_STR -- see [Error Internals](internals-err.md)
	world.aliases -- a list of aliases between identical predicates in the form of an associative array
	world.symbols -- an associative array keyed by symbol name, for variables

Furthermore, world contains a set of keys that are predicate IDs. The values for each of these keys have the form:

	world["name/arity"].det -- if true or nil, predicate is determinate
	world["name/arity"].facts -- an associative array keyed on a serialized set of args, with each value a CTV
	world["name/arity"].def -- a structure containing:
	world["name/arity"].def.children -- a list of predicate objects of the form {name=predname, arity=arity}
	world["name/arity"].def.correspondences -- a list of mappings (see [Parsing Internals](internals-parsing.md)) forming a parallel array with children
	world["name/arity"].def.literals -- a list of lists of literals forming a parallel array with children. When an element in one of these lists is not nil, the literal is substituted
	world["name/arity"].def.op -- either "and" or "or"
	
	 
