builtins={}
helpText={}
internalsHelp={}
banner=[[
   __  ___                  _____ 
  /  |/  /_ _____________  / _/ /_ Composite
 / /|_/ / // / __/ __/ _ \/ _/ __/     Logic
/_/  /_/\_, /\__/_/  \___/_/ \__/   Language
       /___/  v. ]]..tostring(version).."\n"
require("mycPretty")
ansibanner=(
colorCode("black", "red")..
[[   __  ___                  _____            ]].."\n"..
[[  /  |/  /_ _____________  / _/ /_ ]]..colorCode("black", "white").."Composite \n"..colorCode("black", "yellow")..
[[ / /|_/ / // / __/ __/ _ \/ _/ __/]]..colorCode("black", "white").."     Logic \n"..colorCode("black", "green")..
[[/_/  /_/\_, /\__/_/  \___/_/ \__/]]..colorCode("black", "white").."   Language \n"..colorCode("black", "cyan")..
[[       /___/  v. ]]..tostring(version)..string.rep(" ", 44-16-#tostring(version))..colorCode("black", "white").."\n")

copying=[[Mycroft (c) 2015, John Ohno.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(License text: BSD-3)
]]
help=[[
() For syntax help, use help("syntax").
() For help with a builtin, use help(builtin/arity).
() To list builtins, use builtins().
() To print the definitions of all defined predicates, use printWorld().
() To list available help topics relating to mycroft language internals, use help("internals")
() For version information, use help("version").
() For information about licensing, use help("copying").]] 
syntaxHelp=[[Mycroft syntax

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
]]

-- internals
internalsHelp["CTV"]=[[# Mycroft internals: composite truth value manipulation and canonicalization

Malformed truth values are canonicalized to NC. Truth values with zero confidence are canonicalized to NC. Truth values have their components clipped to the range from 0 to 1 inclusive. 

CTV boolean arithmetic operates as follows:

	<A,B> AND <C,D> => <A*C,B*D>
	<A,B> OR <C,D> => <A*B+C*D-A*C,min(B,D)>
]]
internalsHelp["err"]=[[# Mycroft internals: error handling

Each 'world' contains an integer variable MYCERR and a string variable MYCERR_STR. MYCERR is set to 0 if no error has occurred. MYCERR_STR is set to the traceback of the last error that occurred (along with human-readable error name and error message, the predicate in which it occurred, and the signature of each predicate up the stack that doesn't catch it). If caught, MYCERR is set to 0 and MYCERR_STR is set to empty string.
]]
internalsHelp["net"]=[[# Mycroft internals: networking and message passing

Mycroft polyfills a table called mycnet with the following settings:

	mycnet.port=1960
	mycnet.directedMode=true
	mycnet.backlog=512

The following values:

	mycnet.peers={} -- each element is an array consisting of a hostname followed by a port
	mycnet.peerHashed={} -- an associative array of the elements of the peers table keyed by the sha256 hash of the serialized elements
	mycnet.mailbox={} -- a set of requests we have recieved from our peers
	mycnet.pptr=1 -- the index into the peers table pointing to the 'current' selected peer
	mycnet.forwardedLines={} -- a list of facts we've already forwarded, to prevent infinite loops

And, the following methods:

	mycnet.getPeers(world) -- get a list of peers
	mycnet.getCurrentPeer(world) 
	mycnet.getNextPeer(world) -- increment mycnet.pptr and return getCurrentPeer
	mycnet.forwardRequest(world, c) -- send a line of code to next peer
	mycnet.forwardFact(world, c) -- send a line of code to all peers, if it has not already been sent
	mycnet.checkMailbox(world) -- get a list of requests from peers
	mycnet.yield(world) -- process a request from the mailbox, if one exists
	mycnet.restartServer()
	mycnet.hashPeers(world, force) -- hash the list of peers. If 'force' is set, then rehash all peers; otherwise, hash only if the number of peers has changed


If directedMode is set to false, a request will be sent to the next peer in the peers table, in round-robin fashion.


If directedMode is set to true, then for any given request, the order in which it is sent will be defined by the comparison of some consistent hash (in this case sha256) of the signature of the first predicate with the hash of the entire serialized representation of the peer -- we send to the peer with the most similar hash first, and send to all others in order of more or less decreasing similarity. This method of routing is similar to Chord's DHT routing.

On NodeMCU (i.e., on an ESP8622), a device *should* determine whether or not an AP exists with some special name and connect to it if it does, but switch into AP mode and create it if it does not. This is not yet impemented.

Depending upon whether or not a node is in daemon mode (along with other circumstances), timeouts are changed in order to ensure reliability. Currently, the default timeout for daemon mode for server listen in 300 seconds and the current default timeout outside of daemon mode is one tenth of a second. Timeouts on connections to other peers during request forwarding are set to one tenth of a second. This is hard-coded but subject to future tuning. 
]]
internalsHelp["parsing"]=[[# Mycroft internals: parsing

We have two divergent implementations of parsing: compiler semantics (for predicate definitions) and interpreter semantics (for evaluating complex queries). The primary way in which they differ is that in compiler semantics each pair of ANDed-together predicates is given its own auto-named function, while in interpreter semantics we merely keep track of the results of each pair of ANDed-together predicates. Work is in progress to eliminate as much of interpreter semantics-specific code as possible and use compiler semantics in most cases.

We have multi-level parsing, in part because of limitations of lua regex.

At the top level, we handle lines (and support extending lines within the interactive interpreter by keeping track of incomplete lines). A valid line begins with '?-' and ends with '.'. Any line fitting that criterion will be passed to the second level.

At the second level, we determine whether we are defining a predicate or performing a query. If we have exactly one predicate signature preceeded by 'det' or 'nondet' and followed by ':-', we are defining a predicate; otherwise we are performing a query.

In the case of a predicate definition, we cache the 'det' setting, determine the predicate ID (i.e., the name and arity of the predicate), and pass off the rest of the line to another stage.

In the next stage, we split along ';'. In compiler semantics, we take the results of the following stage (in the form of a list of predicates) and form a new function that performs OR on each pair; in interpreter semantics, we OR each pair of results (in the form of composite truth values) directly and return the result.

The following stage is similar, but we split along ',' and perform ANDs.

Finally, we parse individual elements, determining whether they are predicate signatures, composite truth values, or some other type. Types (such as lists and strings) other than CTVs and predicates are evaluated as NC. In compiler semantics, CTVs are turned into synthetic predicates that return those CTVs (including elements that have been evaluated as NC); in interpreter semantics, predicates are evaluated in order to turn them into CTVs. It's also at this stage that the order of arguments to each predicate has its mapping defined, in the case of compiler semantics. In interpreter semantics, the evaluation of identifiers is performed during the evaluation of each predicate, using the unificationGetValue function.

Arglist mappings are stored in the form of three lists. The first list contains a number for each arg, representing the position in the arglist for the predicate being translated to for each arg being translated from (usually the predicate being defined is the predicate being translated from, while each predicate it is being defined in terms of is a translated-to predicate). The second list is the inversion -- for each element, it contains the index of the element in the arglist for the predicate being defined. The third list is a set of literals to be substituted into the arglist being translated to.
]]
internalsHelp["world"]=[[# Mycroft internals: the world

The world is an object containing all meaningful information about the interpreter's internal state.

The world has the following attributes:

* world.MYCERR -- see [Error Internals](internals-err.md)
* world.MYCERR_STR -- see [Error Internals](internals-err.md)
* world.aliases -- a list of aliases between identical predicates in the form of an associative array
* world.symbols -- an associative array keyed by symbol name, for variables

Furthermore, world contains a set of keys that are predicate IDs. The values for each of these keys have the form:

* world["name/arity"].det -- if true or nil, predicate is determinate
* world["name/arity"].facts -- an associative array keyed on a serialized set of args, with each value a CTV
* world["name/arity"].def -- a structure containing:
* world["name/arity"].def.children -- a list of predicate objects of the form {name=predname, arity=arity}
* world["name/arity"].def.correspondences -- a list of mappings (see [Parsing Internals](internals-parsing.md)) forming a parallel array with children
* world["name/arity"].def.literals -- a list of lists of literals forming a parallel array with children. When an element in one of these lists is not nil, the literal is substituted
* world["name/arity"].def.op -- either "and" or "or"
]]

helpText["internals"]=[[# Mycroft internals: table of contents


* Mycroft Internals: composite truth values: 			help("internals/CTV")
* Mycroft Internals: error handling: 				help("internals/err")
* Mycroft Internals: networking and message passing: 		help("internals/net")
* Mycroft Internals: parsing: 					help("internals/parsing")
* Mycroft Internals: the world object: 				help("internals/world")
]]

for k,v in pairs(internalsHelp) do
	helpText["internals/"..k]=v
end

-- simple functions
builtins["true/0"]=function(world) return YES end
builtins["false/0"]=function(world) return NO end
builtins["nc/0"]=function(world) return NC end
helpText["true/0"]=[[true/0, false/0, nc/0 - return YES, NO, or NC, respectively]]
helpText["false/0"]=helpText["true/0"]
helpText["nc/0"]=helpText["true/0"]
builtins["set/2"]=function(world, x, y) unificationSetItem(world, x, unificationGetItem(world, y)) return builtins["equal/2"](world, x, y) end
helpText["set/2"]="set(X, Y) forces unification of X with Y, if possible."
builtins["eval/1"]=function(world, x) x=unificationGetItem(world, x) return parseLine(world, x) end
helpText["eval/1"]="eval(Line) evaluates the line of code Line"
builtins["print/1"]=function(world, c) print(serialize(c)) return YES end
helpText["print/1"]=[[print(X) will print the value of X to stdout, followed by a newline]]
builtins["puts/1"]=function(world,c) io.write(serialize(c)) return YES end
helpText["puts/1"]=[[print(X) will print the value of X to stdout]]
builtins["pprint/1"]=function(world, c) print(pretty(serialize(c))) return YES end
helpText["pprint/1"]=[[pprint(X) will print the syntax-highlighted value of X to stdout, followed by a newline]]
builtins["pputs/1"]=function(world,c) io.write(pretty(serialize(c))) return YES end
helpText["pputs/1"]=[[pprint(X) will print the syntax-highlighted value of X to stdout]]
builtins["exit/0"]=function(world) exitClean(0) end
helpText["exit/0"]="exit/0\texit interpreter with no error\nexit(X)\texit with error code X"
builtins["exit/1"]=function(world, c) exitClean(c) end
helpText["exit/1"]=helpText["exit/0"]

-- pretty-printing/introspection functions
builtins["printWorld/0"]=function(world) printWorld(world) return YES end
helpText["printWorld/0"]=[[printWorld() will print the definitions of all defined predicates]]
builtins["printPred/1"]=function(world, p) if(nil==world[serialize(p)]) then return NO end print(pretty(strDef(world, serialize(p)))) return YES end
helpText["printPred/1"]=[[printPred(X) will print the definition of the predicate X to stdout, if X is defined]]

-- error-related functions
require("mycErr")
builtins["throw/2"]=function(world, c, m) throw(world, c, "throw/2", serialize({c,m}), m) return YES end
builtins["throw/1"]=function(world, c) throw(world, c, "throw/2", serialize({c}), "") return YES end
helpText["throw/1"]=[[throw(X) and throw(X,Msg) will throw the error represented by the error code X
Available error codes include:
MYC_ERR_NOERR		]]..tostring(MYC_ERR_NOERR)..[[	no error
MYC_ERR_UNDEFWORLD	]]..tostring(MYC_ERR_UNDEFWORLD)..[[	world undefined
MYC_ERR_DETNONDET	]]..tostring(MYC_ERR_DETNONDET)..[[	determinacy conflict: predicate marked det is not determinate, or a predicate marked nondet is having a fact assigned to it
MYC_ERR_USER		]]..tostring(MYC_ERR_USER)..[[		user-defined error.]]
helpText["throw/2"]=helpText["throw/1"]
builtins["catch/1"]=function(world, c) if(world.MYCERR==c) then world.MYCERR=MYC_ERR_NOERR world.MYCERR_STR="" return YES end if(world.MYCERR==MYC_ERR_NOERR) then return YES end return NO end
helpText["catch/1"]=[[catch(X) will catch the error represented by the error code X and return YES. If there is an error but it is not X, it will return NO.
Available error codes include:
MYC_ERR_NOERR		]]..tostring(MYC_ERR_NOERR)..[[	no error
MYC_ERR_UNDEFWORLD	]]..tostring(MYC_ERR_UNDEFWORLD)..[[	world undefined
MYC_ERR_DETNONDET	]]..tostring(MYC_ERR_DETNONDET)..[[	determinacy conflict: predicate marked det is not determinate, or a predicate marked nondet is having a fact assigned to it]]

-- comparison functions
builtins["equal/2"]=function(world, a, b)
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	if(a==b) then return YES end 
	if(serialize(a)==serialize(b)) then return YES end
	return NO
end
helpText["equal/2"]="equal(X, Y)\treturn YES if X equals Y, otherwise return NO\ngt/2, lt/2, gte/2, and lte/2 work the same way as equal/2, except that values that are neither strings nor numbers are not valid and will return NC"
helpText["gt/2"]=helpText["equal/2"]
helpText["lt/2"]=helpText["equal/2"]
helpText["gte/2"]=helpText["equal/2"]
helpText["lte/2"]=helpText["equal/2"]
builtins["gt/2"]=function(world, a, b) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	if(type(a)=="table" or type(b)=="table") then return NC end
	if(a>b) then return YES end
	return NO
end
builtins["lt/2"]=function(world, a, b) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	if(type(a)=="table" or type(b)=="table") then return NC end
	if(a<b) then return YES end
	return NO
end
builtins["gte/2"]=function(world, a, b) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	if(type(a)=="table" or type(b)=="table") then return NC end
	if(a>=b) then return YES end
	return NO
end
builtins["lte/2"]=function(world, a, b) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	if(type(a)=="table" or type(b)=="table") then return NC end
	if(a<=b) then return YES end
	return NO
end
builtins["not/1"]=function(world, a) 
	local ret={truth=a.truth, confidence=a.confidence}
	ret.truth=1.0-ret.truth
	if(ret.truth<0) then ret.truth=ret.truth*-1 end
	return canonicalizeCTV(ret)
end
helpText["not/1"]="Invert the truth component of a truth value"

-- composition functions
builtins["add/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	a=tonumber(a)
	b=tonumber(b)
	if(nil==a or nil==b) then return NO end
	unificationSetItem(world, r, a+b)
	return builtins["equal/2"](world, r, a+b)
end
builtins["sub/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	a=tonumber(a)
	b=tonumber(b)
	if(nil==a or nil==b) then return NO end
	unificationSetItem(world, r, a-b)
	return builtins["equal/2"](world, r, a-b)
end
builtins["mul/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	a=tonumber(a)
	b=tonumber(b)
	if(nil==a or nil==b) then return NO end
	unificationSetItem(world, r, a*b)
	return builtins["equal/2"](world, r, a*b)
end
builtins["div/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	a=tonumber(a)
	b=tonumber(b)
	if(nil==a or nil==b) then return NO end
	unificationSetItem(world, r, a/b)
	return builtins["equal/2"](world, r, a/b)
end
builtins["concat/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	a=serialize(a)
	b=serialize(b)
	if(nil==a or nil==b) then return NO end
	unificationSetItem(world, r, a..b)
	return builtins["equal/2"](world, r, a..b)
end
builtins["append/3"]=function(world, a, b, r) 
	a=unificationGetItem(world, a)
	b=unificationGetItem(world, b)
	local ret
	if(type(a)~="table") then 
		ret={a}
	else
		local i,j
		ret={}
		for i,j in ipairs(a) do
			ret[i]=j
		end
		for i,j in pairs(a) do
			ret[i]=j
		end
	end
	table.append(ret, b)
	unificationSetItem(world, r, ret)
	return builtins["equal/2"](world, r, ret)
end
helpText["add/3"]=[[add(A,B,X), sub(A,B,X), mul(A,B,X),div(A,B,X)\tSet X=A+B, A-B, A*B, or A/B, respectively]]
helpText["sub/3"]=helpText["add/3"]
helpText["mul/3"]=helpText["add/3"]
helpText["div/3"]=helpText["add/3"]
helpText["concat/3"]="concat(A,B,X)\tSet X to the string concatenation of A and B"
helpText["append/3"]="append(A,B,X)\tSet X to a list consisting of the item B appended to the end of the list A. If A is not a list, set X to a list consisting of items A and B."

-- list functions
builtins['lindex/3']=function(world, l, i, x)
	l=unificationGetItem(world, l)
	i=unificationGetItem(world, i)
	if(type(l)=="table") then
		return unificationSetItem(world, x, l[i])
	elseif(type(l)=="function") then
		local val, n, count
		val,n=l()
		count=i-1
		while(count>0 and n~=nil) do
			val,n = n()
		end
		return unificationSetItem(world, x, val)
	end
	return NC
end
builtins['lset/3']=function(world, l, i, x)
	l=unificationGetItem(world, l)
	i=unificationGetItem(world, i)
	x=unificationGetItem(world, x)
	if(type(l)=="table") then
		l[i]=x
		return YES
	end
	return NC
end
helpText["lindex/3"]="lindex(List, Index, X) sets the value of X to the value of the item at index Index of List\nlset(List, Index,X) sets the value if List[Index] to X"
helpText["lset/3"]=helpText["lindex/3"]


function initBuiltins()
	if(not paranoid) then -- define unsafe builtin functions 
		-- Anything that would be a security risk if untrusted nodes could submit it should be defined *here*

		function constructOpeners() -- for handling chunking of multiline code, needed by getBuiltin/2. Not reliable! 
			closers={}
			closers["end"]=true
			openers={}
			openers["do"]=true
			openers["if"]=true
			openers["function"]=true
		end
		function getChunk(filename, linedefined) -- Given a filename and a line number for the start of a lua function, return the complete function by counting chunk grouping symbols
			local ret
			debugPrint("source filename: "..filename)
			debugPrint("source file line number: "..tostring(linedefined))
			local f=io.open(filename)
			if(nil~=f and nil~=linedefined) then
				local i, l, unclosed
				i=1
				l=f:read("*l")
				while(i<linedefined and l~=nil) do
					i=i+1
					l=f:read("*l")
				end
				if(i==linedefined) then
					if(openers==nil) then
						constructOpeners()
					end
					ret=string.gsub(tostring(l), "builtins.+= *(function *.+)$", function(c) return c end)
					unclosed=0
					string.gsub(ret, "(%w+)", function(c) 
						if(closers[c]) then unclosed=unclosed-1
						elseif(openers[c]) then unclosed=unclosed+1
						end
					end)
					while (unclosed>0 and l~=nil) do
						l=f:read("*l")
						if(l~=nil) then
							ret=ret.."\n"..l
							string.gsub(l, "(%w+)", function(c) 
								if(closers[c]) then unclosed=unclosed-1
								elseif(openers[c]) then unclosed=unclosed+1
								end
							end)
						end
					end
				end
				f:close()
			end
			return ret
		end

		helpText["interact/0"]=[[Go into interactive interpreter mode]]
		builtins["interact/0"]=function(world) local x=mainLoop(world) while(x) do mainLoop(world) end return YES end

		helpText["setParanoia/1"]=[[setParanoia(YES) will turn on paranoid mode]]
		builtins["setParanoia/1"]=function(world, x) 
			if(cmpTruth(unificationGetItem(world, x), YES)) then 
				paranoia=true 
				return YES 
			end 
			return NO 
		end

		helpText["setBuiltin/2"]="setBuiltin(Name,LuaSource) will set the builtin with the signature Name to the function defined by LuaSource. If LuaSource is not valid lua source code, NO will be returned, otherwise YES. Please note that the signature must be of the form name/arity, or else it will not be executable from mycroft!"
		builtins["setBuiltin/2"]=function(world, x, y)
			local completeString="local func\nfunc="..serialize(unificationGetItem(world, y)).." return func"
			local compiled,err=loadstring(completeString)
			debugPrint(err)
			local xname=unificationGetItem(world, x)
			debugPrint("Trying to set builtin "..serialize(xname).." to lua code [["..completeString.."]]")
			if(nil~=compiled) then
				debugPrint("Set builtin "..serialize(xname).." to compiled lua code [["..completeString.."]]")
				builtins[xname]=compiled()
				return YES
			end
			return NO
		end
		helpText["getBuiltin/2"]="getBuiltin(Name, X) will set X to the string containing the Lua source code of the builtin whose signature is Name, if possible, otherwise representing it as a Lua function identifier"
		builtins["getBuiltin/2"]=function(world, x, y) 
			local info, xname, ret
			xname=serialize(unificationGetItem(world, x))
			if(nil~=builtins[xname]) then 
				info=debug.getinfo(builtins[xname], 'Sf')
				if(nil==info) then return NO end
				ret=tostring(info.func)
				debugPrint("source: "..tostring(info.source))
				if("Lua"==info.what) then 
					if(#info.source>0) then
						if(string.find(info.source, '^%@')~=nil) then
							local filename=string.gsub(info.source, '^%@(.+)$', function(c) return c end)
							local src=getChunk(filename, info.linedefined)
							if(nil~=src) then ret=src end
						else
							if(info.source~="=stdin") then
								ret=string.gsub(tostring(info.source), "local func\nfunc=(.+) return func", function(c) return c end)
							end
						end
					end
				end
				unificationSetItem(world, y, ret)
				return(builtins["equal/2"](world, y, ret))	
			end
			return NO
		end
		
		helpText['setansi/1']="setansi(X) enables ANSI colors if X=YES, otherwise it disables them"
		helpText['getansi/0']="getansi() returns YES if ANSI colors are enabled; otherwise it returns NO"
		builtins['setansi/1']=function(world, a) if(cmpTruth(unificationGetItem(world, a), YES)) then ansi=true else ansi=false end return YES end
		builtins['getansi/0']=function(world) if(ansi) then return YES end return NO end
	
		-- file manipulation
		helpText['open/3']="open(Filename, Mode, X) opens Filename with Mode (a c-style mode) and sets X to the file handle. In case of error, MYC_ERR_USERERR is thrown, and NO is returned."
		builtins['open/3']=function(world, fname, mode, ret) 
			fname=unificationGetItem(world, fname)
			mode=unificationGetItem(world, mode)
			local f, err=io.open(fname, mode)
			if (nil==f) then
				throw(world, MYC_ERR_USERERR, "open", serialize({fname, mode, ret}), tostring(err))
				return NO
			end
			unificationSetItem(world, ret, f)
			return YES
		end
		helpText['close/1']="close(F) closes the file handle F. In case of error, MYC_ERR_USERERR is thrown, and NO is returned."
		builtins['close/1']=function(world, f)
			f=unificationGetItem(world, f)
			if(nil==f) then return NO end
			local ret,err = pcall(io.close, f)
			if(ret) then
				return YES
			else
				throw(world, MYC_ERR_USERERR, "close", serialize({f}), tostring(err))
				return NO
			end
		end
		helpText['fgets/2']="fgets(F, X) reads a line from the file handle F (produced by open/3) and puts the line in X. In case of error, MYC_ERR_USERERR is thrown, and NO is returned."
		builtins['fgets/2']=function(world, f, ret)
			f=unificationGetItem(world, f)
			local s,l = pcall(io.read, f, "*l")
			if(s) then
				unificationSetItem(world, ret, l)
				return YES
			else
				throw(world, MYC_ERR_USERERR, "fgets", serialize({f, ret}), tostring(l))
				return NO
			end
		end
		helpText['fputs/2']="fputs(F,X) prints the string X to the file handle F. In case of error, MYC_ERR_USERERR is thrown, and NO is returned."
		builtins['fputs/2']=function(world, f, m)
			f=unificationGetItem(world, f)
			m=unificationGetItem(world, m)
			local s,e = pcall(io.write, m)
			if(s) then
				return YES
			else
				throw(world, MYC_ERR_USERERR, 'fputs', serialize({f, m}), tostring(e))
				return NO
			end
		end
		
		-- load/save state of the world
		helpText['saveWorld/1']="saveWorld(FName) saves the state of the world to the file represented by FName."
		builtins['saveWorld/1']=function(world, fname)
			fname=unificationGetItem(world, fname)
			local s,f = pcall(io.open, fname, 'w')
			if(s) then
				local e
				s, e=pcall(io.write, f, strWorld(world))
				if(s) then
					s, e = pcall(io.close, f)
					if(s) then
						return YES
					end
				end
				throw(world, MYC_ERR_USERERR, 'saveWorld', serialize({fname}), tostring(e))
			else
				throw(world, MYC_ERR_USERERR, 'saveWorld', serialize({fname}), tostring(f))
			end
			return NO
		end
		helpText['doFile/1']="doFile(FName) runs the predicates in the file represented by FName."
		builtins['doFile/1']=function(world, fname)
			fname=unificationGetItem(world, fname)
			local s,f = pcall(io.open, fname, 'r')
			if(s) then
				parseFile(world, f)
				io.close(f)
			end
			throw(world, MYC_ERR_USERERR, 'doFile', serialize({fname}), tostring(f))
			return NO
		end
		
		-- manipulation of help text
		helpText['setHelp/2']="setHelp(Topic, Text) sets the help text for Topic to Text"
		builtins['setHelp/2']=function(world, topic, text)
			topic=unificationGetItem(world, topic)
			text=unificationGetItem(world, text)
			helpText[topic]=text
		end
	end

	if(paranoid) then 
		builtins["setport/1"]=function(world, port) return NO end -- paranoid version
	else
		builtins["setport/1"]=function(world, port) mycnet.port=port return YES end -- security issue, but we trust the network
	end
end
builtins["builtins/0"]=function(world) for k,v in pairs(builtins) do print(tostring(k)) end return YES end
helpText["builtins/0"]="builtins/0\tprint all built-in predicates"
builtins["help/0"]=function(world) print(pretty(help)) return YES end
helpText["help/0"]="print general help message"
helpText["help/1"]="help(X)\tprint help with topic X. See help/0 for details."
helpText[""]=help
helpText["sethelp/2"]="help(Topic, Message) sets the help information for Topic to Message"
helpText["copying"]=copying
helpText["syntax"]=syntaxHelp
helpText["version"]=tostring(version)
builtins["help/1"]=function(world,c) 
	c=serialize(unificationGetItem(world, c))
	if(nil~=helpText[c]) then print(pretty(helpText[c]))
	else 
		print(pretty("No help available for "..serialize(c)))
		return NO
	end 
return YES end
builtins["sethelp/2"]=function(world, x, y) 
	x=serialize(unificationGetItem(world, x))
	y=serialize(unificationGetItem(world, y))
	helpText[x]=y
	return YES
end
builtins["copying/0"]=function(world) print(helpText["copying"]) end
helpText["copying/0"]=helpText["copying"]
helpText["banner"]=banner
helpText["ansibanner"]=ansibanner
if(ansi) then
	helpText["banner"]=ansibanner
end
helpText["banner/0"]=helpText["banner"]
builtins["banner/0"]=function(world) print(helpText["banner"]) return YES end
builtins["runtests/0"]=function(world) test() return YES end
helpText["runtests/0"]="Run the test suite"

-- forwarding-related
builtins["addpeer/2"]=function(world, address, port) table.insert(mycnet.peers, {address, tonumber(port)}) return YES end
helpText["setport/1"]="setport(Port)\tset the listening port for peers to connect to"
helpText["addpeer/2"]="addpeer(Address,Port)\tadd a peer with the specified info"
helpText["setForwarding/1"]="set query forwarding"
builtins["setForwarding/1"]=function(world, x) x=unificationGetItem(world, x) if(cmpTruth(x, YES)) then forwardQueries=true return YES end forwardQueries=NO return YES end
helpText["forward/1"]="forward(Line) forwards the code in Line to the current peer\nforwardAll(Line) forwards the code in Line to all peers"
helpText["forwardAll/1"]=helpText["forward/1"]
builtins["forward/1"]=function(world, l) l=unificationGetItem(world, l) return parseItem(mycnet.forwardRequest(world, l)) end
builtins["forwardAll/1"]=function(world, l) l=unificationGetItem(world, l) mycnet.forwardFact(world, l) return YES end

defaultConfig=[[
nondet open(FName, X) :- open(FName, r, X).
nondet err(Msg) :- throw(3, Msg).
nondet welcome() :- banner(), print(""), pprint("Type 'help().' for help, and 'copying().' for copying information."), print("").
]]
