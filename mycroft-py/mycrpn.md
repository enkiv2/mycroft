# Myc-RPN - alternate reverse-polish syntax for Mycroft

## Purpose

The normal (prolog-inspired) Mycroft syntax is difficult to parse because of certain characters that perform very different tasks at different levels & thus are potentially ambiguous. A FORTH-style space-tokenized RPN format eliminates infix operators and makes tokenization clear, and so is worthwhile as an intermediate format.

## Syntax

`num := [0-9]*(.[0-9]*)?`

`fractnum := 0|1|0\.[0-9][0-9]*`

`CTV := \<<fractnum>,<fractnum>\>`

`var := [A-Z_][A-Za-z0-9_]*`

`str := \"[^"]*\"`

`atom := ([a-z][A-Za-z0-9_]*)|<str>`

`arity := [0-9][0-9]*`

`predName := <atom>/<arity>`

`operator := ,|;|!`

`term := <num>|<CTV>|<var>|<atom>|<predName>|<operator>`


`predDef := ("det "|"nondet ")?":- "<predName>" "(<term>" ")+"."`

`predQuery := "?- "(<term>" ")*"."`


`line := <predDef>|<predQuery><EOL>`


## Behavior

Outside of the context of `predDef`, `predName`s are always interpreted as being applied to the last `arity` terms, in reverse order.

The `,` and `;` operators apply to all previous terms, indicating that, after the stack has been consumed by preds, the remaining values should be combined into one value using 'and' or 'or' operations respectively.

The `predDef` operation is similar to ':' in FORTH -- in other words, the first arg after `:-` is considered to be the pred we are defining, and the remainder of the items should be interpreted as though they were in a predQuery, with `arity` items pushed onto the stack. If not otherwise specified, if multiple items remain on the stack after being consumed, we should apply the 'and' operation to them. `det` and `nondet` are optional -- we will default to `det` if all preds called are det, otherwise nondet.
