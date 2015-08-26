# Mycroft internals: parsing

We have two divergent implementations of parsing: compiler semantics (for predicate definitions) and interpreter semantics (for evaluating complex queries). The primary way in which they differ is that in compiler semantics each pair of ANDed-together predicates is given its own auto-named function, while in interpreter semantics we merely keep track of the results of each pair of ANDed-together predicates. Work is in progress to eliminate as much of interpreter semantics-specific code as possible and use compiler semantics in most cases.

We have multi-level parsing, in part because of limitations of lua regex.

At the top level, we handle lines (and support extending lines within the interactive interpreter by keeping track of incomplete lines). A valid line begins with '?-' and ends with '.'. Any line fitting that criterion will be passed to the second level.

At the second level, we determine whether we are defining a predicate or performing a query. If we have exactly one predicate signature preceeded by 'det' or 'nondet' and followed by ':-', we are defining a predicate; otherwise we are performing a query.

In the case of a predicate definition, we cache the 'det' setting, determine the predicate ID (i.e., the name and arity of the predicate), and pass off the rest of the line to another stage.

In the next stage, we split along ';'. In compiler semantics, we take the results of the following stage (in the form of a list of predicates) and form a new function that performs OR on each pair; in interpreter semantics, we OR each pair of results (in the form of composite truth values) directly and return the result.

The following stage is similar, but we split along ',' and perform ANDs.

Finally, we parse individual elements, determining whether they are predicate signatures, composite truth values, or some other type. Types (such as lists and strings) other than CTVs and predicates are evaluated as NC. In compiler semantics, CTVs are turned into synthetic predicates that return those CTVs (including elements that have been evaluated as NC); in interpreter semantics, predicates are evaluated in order to turn them into CTVs. It's also at this stage that the order of arguments to each predicate has its mapping defined, in the case of compiler semantics. In interpreter semantics, the evaluation of identifiers is performed during the evaluation of each predicate, using the unificationGetValue function.

Arglist mappings are stored in the form of three lists. The first list contains a number for each arg, representing the position in the arglist for the predicate being translated to for each arg being translated from (usually the predicate being defined is the predicate being translated from, while each predicate it is being defined in terms of is a translated-to predicate). The second list is the inversion -- for each element, it contains the index of the element in the arglist for the predicate being defined. The third list is a set of literals to be substituted into the arglist being translated to.
