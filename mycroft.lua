#!/usr/bin/env lua

paranoid=false
verbose=false
version=0.01
banner=[[
   __  ___                  _____ 
  /  |/  /_ _____________  / _/ /_ Composite
 / /|_/ / // / __/ __/ _ \/ _/ __/     Logic
/_/  /_/\_, /\__/_/  \___/_/ \__/   Language
       /___/  v. ]]..tostring(version).."\n"

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
help=[[For syntax help, use help("syntax").
For help with a builtin, use help(builtin/arity).
To list builtins, use builtins().
To print the definitions of all defined predicates, use printWorld().\nFor version information, use help("version").
For information about licensing, use help("copying").]] 
syntaxHelp=[[Mycroft syntax

Mycroft has a prolog-like syntax, consisting of predicate definitions and queries.
A predicate definition is of the form:
	det predicateName(Arg1, Arg2...) :- predicateBody.
where predicateBody consists of a list of references to other predicates and truth values.

A predicate that is marked 'det' is determinate -- if it ever evaluates to a different value than it has cached, an error is thrown. An indeterminate predicate can be marked 'nondet' instead, meaning that its return value can change and so results from it will not be memoized.

A predicate body is of the form:
	item1, item2... ; itemA, itemB...
where each item is either a reference to a predicate or a truth value. Sections separated by ';' are ORed together, while items separated by ',' are ANDed together.

A reference to a predicate is of the form predicateName(Arg1, Arg2...)

A truth value (or composite truth value, or CTV) is of the form
	<Truth, Confidence>
where both Truth and Confidence are floating point values between 0 and 1. <X| is syntactic sugar for <X,1.0>; |X> is syntactic sugar for <1.0,X>; YES is syntactic sugar for <1.0, 1.0>; NO is syntactic sugar for <0.0, 1.0>; and, NC is syntactic sugar for <X,0.0> regardless of the value of X.

A query is of the form:
	?- predicateBody.
The result of a query will be printed to standard output.
]]

anonPredCount=0

MYCERR=0
MYCERR_STR=""
MYC_ERR_NOERR=0
MYC_ERR_DETNONDET=1
MYC_ERR_UNDEFWORLD=2

NC={truth=0, confidence=0}
YES={truth=1, confidence=1}
NO={truth=0, confidence=1}

builtins={}
helpText={}
builtins["true/0"]=function(world) return YES end
builtins["false/0"]=function(world) return NO end
builtins["nc/0"]=function(world) return NC end
helpText["true/0"]=[[true/0, false/0, nc/0 - return YES, NO, or NC, respectively]]
helpText["false/0"]=helpText["true/0"]
helpText["nc/0"]=helpText["true/0"]
builtins["set/2"]=function(world, x, y) unificationSetItem(world, x, unificationGetItem(world, y)) return builtins["equal/2"](world, x, y) end
helpText["set/2"]="set(X, Y) forces unification of X with Y, if possible."
builtins["print/1"]=function(world, c) print(serialize(c)) return YES end
helpText["print/1"]=[[print(X) will print the value of X to stdout, followed by a newline]]
builtins["puts/1"]=function(world,c) io.write(serialize(c)) return YES end
helpText["puts/1"]=[[print(X) will print the value of X to stdout]]
builtins["printWorld/0"]=function(world) printWorld(world) return YES end
helpText["printWorld/0"]=[[printWorld() will print the definitions of all defined predicates]]
builtins["printPred/1"]=function(world, p) if(nil==world[serialize(p)]) then return NO end print(strDef(world, serialize(p))) return YES end
helpText["printPred/1"]=[[printPred(X) will print the definition of the predicate X to stdout, if X is defined]]
builtins["throw/1"]=function(world, c) throw(c) return YES end
helpText["throw/1"]=[[throw(X) will throw the error represented by the error code X
Available error codes include:
MYC_ERR_NOERR	]]..tostring(MYC_ERR_NOERR)..[[	no error
MYC_ERR_UNDEFWORLD	]]..tostring(MYC_ERR_UNDEFWORLD)..[[	world undefined
MYC_ERR_DETNONDET	]]..tostring(MYC_ERR_DETNONDET)..[[	determinacy conflict: predicate marked det is not determinate, or a predicate marked nondet is having a fact assigned to it]]
builtins["catch/1"]=function(world, c) if(MYCERR==c) then MYCERR=MYC_ERR_NOERR MYCERR_STR="" return YES end if(MYCERR==MYC_ERR_NOERR) then return YES end return NO end
helpText["catch/1"]=[[catch(X) will catch the error represented by the error code X and return YES. If there is an error but it is not X, it will return NO.
Available error codes include:
MYC_ERR_NOERR	]]..tostring(MYC_ERR_NOERR)..[[	no error
MYC_ERR_UNDEFWORLD	]]..tostring(MYC_ERR_UNDEFWORLD)..[[	world undefined
MYC_ERR_DETNONDET	]]..tostring(MYC_ERR_DETNONDET)..[[	determinacy conflict: predicate marked det is not determinate, or a predicate marked nondet is having a fact assigned to it]]
builtins["exit/0"]=function(world) os.exit() end
helpText["exit/0"]="exit/0\texit interpreter with no error\nexit(X)\texit with error code X"
builtins["exit/1"]=function(world, c) os.exit(c) end
helpText["exit/1"]=helpText["exit/0"]
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
if(not paranoid) then
	function constructOpeners() -- for handling chunking of multiline code. Not reliable!
		closers={}
		closers["end"]=true
		openers={}
		openers["do"]=true
		openers["if"]=true
		openers["function"]=true
	end
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
						debugPrint("source filename: "..filename)
						debugPrint("source file line number: "..tostring(info.linedefined))
						local f=io.open(filename)
						if(nil~=f and nil~=info.linedefined) then
							local i, l, unclosed
							i=1
							l=f:read("*l")
							while(i<info.linedefined and l~=nil) do
								i=i+1
								l=f:read("*l")
							end
							if(i==info.linedefined) then
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
					else
						if(info.source~="=stdin") then
							ret=string.gsub(tostring(info.source), "local func\nfunc=(.+) return func", function(c) return c end)
						end
					end
				end
			end
			unificationSetItem(world, y, ret)
			return(builtins["equal/2"](world, y, ret))			
		else
			return NO
		end
	end
end
builtins["builtins/0"]=function(world) for k,v in pairs(builtins) do print(tostring(k)) end return YES end
helpText["builtins/0"]="builtins/0\tprint all built-in predicates"
builtins["help/0"]=function(world) print(help) return YES end
helpText["help/0"]="print general help message"
helpText["help/1"]="help(X)\tprint help with topic X. See help/0 for details."
helpText[""]=help
helpText["copying"]=copying
helpText["syntax"]=syntaxHelp
helpText["version"]=tostring(version)
builtins["help/1"]=function(world,c) 
	c=serialize(c)
	if(nil~=helpText[c]) then print(helpText[c])
	else 
		print("No help available for "..serialize(c)) 
		return NO
	end 
return YES end
builtins["copying/0"]=function(world) print(builtins["copying"]) end
helpText["copying/0"]=helpText["copying"]
helpText["banner"]=banner
helpText["banner/0"]=helpText["banner"]
builtins["banner/0"]=function(world) print(helpText["banner"]) return YES end
helpText["welcome/0"]=helpText["banner"].."\nType help(). for help, and copying(). for copying information.\n"
builtins["welcome/0"]=function(world) print(helpText["welcome/0"]) return YES end
builtins["addpeer/2"]=function(world, address, port) table.insert(mycnet.peers, {address, tonumber(port)}) return YES end
if(paranoid) then 
	builtins["setport/1"]=function(world, port) return NO end -- paranoid version
else
	builtins["setport/1"]=function(world, port) mycnet.port=port return YES end -- security issue, but we trust the network
end
helpText["setport/1"]="setport(Port)\tset the listening port for peers to connect to"
helpText["addpeer/2"]="addpeer(Address,Port)\tadd a peer with the specified info"

mycnet={}
function setupNetworkingNMCU()
	debugPrint("detected NodeMCU; setting up.")
	setupNetworkingCommon()
	setupNetworkingDummy() --XXX
end
function setupNetworkingLJIT()
	debugPrint("detected luajit; setting up.")
	setupNetworkingCommon()
	setupNetworkingDummy() --XXX
end
function setupNetworkingLSOCK()
	debugPrint("detected luasocket; setting up.")
	setupNetworkingCommon()
	if(pcall(require, "socket")) then
		socket=require("socket")
	end
	if(nil==socket) then
		debugPrint("luasocket failed to load; falling back to dummy")
		return setupNetworkingDummy()
	end
	mycnet.server=socket.bind("*", mycnet.port, mycnet.backlog)
	if(nil==mycnet.server) then return setupNetworkingDummy() end
	mycnet.server:settimeout(0.1, 't')
	mycnet.forwardRequest=function(world, c) 
		local firstPeer=mycnet.getCurrentPeer(world)
		local peer=mycnet.getNextPeer(world)
		if(nil==peer) then return nil end
		local client=socket.connect(unpack(peer))
		while(nil==client and peer~=firstPeer) do
			debugPrint("attempting to send "..c.." to peer "..serialize(peer))
			peer=mycnet.getNextPeer(world)
			if(nil==peer) then return nil end
			client=socket.connect(unpack(peer))
		end
		if(peer==firstPeer) then return nil end
		client:send(c)
		local ret=client:recieve()
		return ret
	end -- send a line of code to next peer
	mycnet.checkMailbox=function(world) 
		local client=mycnet.server:accept()
		if(nil==client) then return mycnet.mailbox end
		client:settimeout(10)
		local line,err=client:recieve()
		if(nil~=line) then
			debugPrint("got line [["..tostring(line).."]] from peer "..serialize(client:getpeername()))
			if(string.find(line, '^ *%?%-')~=nil) then
				debugPrint("line is query; executing immediately")
				client:send(serialize(parseLine(world, line)))
			else
				table.insert(mycnet.mailbox, {line, client:getpeername()})
				debugPrint("contents of mailbox: "..serialize(mycnet.mailbox))
			end
		end
		client:close()
	end -- get a list of requests from peers
end
function setupNetworkingCommon()
	debugPrint("setting up common networking features")
	mycnet.port=1960 -- hardcode default for now
	mycnet.backlog=512
	mycnet.peers={}
	mycnet.mailbox={}
	mycnet.pptr=1
	mycnet.forwardedLines={}
	mycnet.getPeers=function(world) return mycnet.peers end -- get a list of peers
	mycnet.getCurrentPeer=function(world) return mycnet.peers[mycnet.pttr] end 
	mycnet.getNextPeer=function(world) 
		mycnet.pptr=mycnet.pptr+1 
		if(mycnet.pptr>#mycnet.peers) then mycnet.pptr=1 end
		return mycnet.getCurrentPeer(world)
	end -- round robin
	mycnet.yield=function(world)
		mycnet.checkMailbox(world)
		if(#mycnet.mailbox>0) then
			local item=mycnet.mailbox[1]
			table.remove(mycnet.mailbox, 1)
			local line=item[1]
			ret=parseLine(world, line)
			return nil
		end
	end -- process one step of somebody else's request
	mycnet.forwardFact=function(world, l)
		debugPrint("forwarding fact [["..l.."]]")
		if(mycnet.forwardedLines[l]) then return nil end
		mycnet.forwardedLines[l]=true
		local start=mycnet.getCurrentPeer(world)
		if(nil==start) then return nil end
		mycnet.forwardRequest(world, line)
		while(start~=mycnet.getCurrentPeer()) do
			mycnet.forwardRequest(world, line)
		end
		return nil
	end
	debugPrint("listen port="..tostring(mycnet.port)..",backlog="..tostring(mycnet.backlog))
end
function setupNetworkingDummy()
	debugPrint("setting up dummy networking functions")
	mycnet.getPeers=function() return {} end -- get a list of peers
	mycnet.getCurrentPeer=function() return nil end 
	mycnet.getNextPeer=function() return nil end -- round robin
	mycnet.forwardRequest=function(c) return nil end -- send a line of code to next peer
	mycnet.forwardFact=function(c) return nil end -- send a line of code to next peer
	mycnet.checkMailbox=function() return {} end -- get a list of requests from peers
	mycnet.yield=function() return nil end -- process one step of somebody else's request
end
function setupNetworking()
	if(nil~=node) then
		if(nil~=node.chipid) then
			if(nil~=node.chipid()) then
				return setupNetworkingNMCU()
			end
		end
	end
	if(jit~=nil) then
		return setupNetworkingLJIT()
	end
	return setupNetworkingLSOCK()
end


function translateArgList(list, conv) -- given an arglist and a conversion map, produce a new arglist with the order transformed
	local l, i, j
	l={}
	if(conv==nil) then return l end
	for i,j in ipairs(conv[1]) do 
		l[conv[2][i]]=list[conv[1][i]]
	end
	return l
end

function cmpTruth(p, q)
	p=canonicalizeCTV(p)
	q=canonicalizeCTV(q)
	if (p.truth==q.truth and q.confidence==q.confidence) then
		return true
	end
	return false
end

function canonicalizeCTV(r) -- snap to [0,1] and convert all zero-confidence CTVs to <0,0>
	if(type(r)~="table") then return NC end
	if(r.truth==nil or r.confidence==nil) then return NC end
	if(r.confidence<0) then r.confidence=0 end
	if(r.confidence==0) then return NC end
	if(r.truth<0) then r.truth=0 end
	if(r.truth>1) then r.truth=1 end
	if(r.confidence>1) then r.confidence=1 end
	return r
end

function performPLBoolean(p, q, op) -- compose truth values by boolean combination (PLN-like)
	local r
	p=canonicalizeCTV(p)
	q=canonicalizeCTV(q)
	r={}
	if(op=='and') then
		r.truth=p.truth*q.truth
		r.confidence=p.confidence*q.confidence
	else
		r.truth=(p.truth*p.confidence)+(q.truth*q.confidence)-(p.truth*q.truth)
		if (p.confidence>q.confidence) then
			r.confidence=q.confidence;
		else
			r.confidence=p.confidence;
		end
	end
	return canonicalizeCTV(r)
end

function createPredID(pname, parity)
	return {name=pname, arity=parity}
end

function unificationGetItem(world, itemName)
	if(nil==world.symbols) then world.symbols={} end
	if(type(itemName) ~= "string") then 
		debugPrint(serialize(itemName).."=\""..serialize(itemName).."\"")
		return itemName 
	end
	if(#itemName>0) then
		if(string.find(itemName, '^%u')~=nil) then
			if(world.symbols[itemName]==nil) then 
				debugPrint(serialize(itemName).."=\""..serialize(itemName).."\"")
				return itemName 
			end
			debugPrint(serialize(itemName).."=\""..serialize(world.symbols[itemName]).."\"")
			return world.symbols[itemName]
		else 
			debugPrint(serialize(itemName).."=\""..serialize(itemName).."\"")
			return itemName 
		end
	end
	debugPrint(serialize(itemName).."=\""..serialize(itemName).."\"")
	return itemName
end
function unificationSetItem(world, itemName, value)
	if(nil==world.symbols) then world.symbols={} end
	if(type(itemName) ~= "string") then return itemName end
	if(#itemName>0) then
		if(string.find(itemName, '^%u')~=nil) then
			if(world.symbols[itemName]==nil) then
				world.symbols[itemName]=value
				debugPrint(serialize(itemName)..":=\""..serialize(world.symbols[itemName]).."\"")
				return value
			elseif(world.symbols[itemName]~=value) then
				throw(MYC_ERR_UNIF, "set/2", {itemName, value}, "\tCurrent value of "..serialize(itemName).." is "..serialize(world.symbols[itemName]))
				return world.symbols[itemName]
			end
		else return itemName end
	end
	return itemName
end
function clearSymbolSpace(world)
	world.symbols={}
end

-- pretty-printing functions
function debugPrint(msg)
	if(verbose) then print("debug: "..serialize(msg)) end
end
function serialize(args) -- serialize in Mycroft syntax
	local ret, sep
	if(type(args)~="table") then
		ret=string.gsub(string.gsub(string.gsub(string.gsub(tostring(args), string.char(127), ","), string.char(126), "("), string.char(125), ")"), "([^ ]+)", function(q) if ("\\Y\\E\\S"==q) then return "YES" elseif("\\N\\O"==q) then return "NO" elseif("\\N\\C"==q) then return "NC" else return q end end)
		return ret
	end
	if(args.truth~=nil and args.confidence~=nil) then
		if(1==args.confidence) then
			if(1==args.truth) then
				return "YES"
			elseif (0==args.truth) then
				return "NO"
			else
				return "<"..tostring(args.truth).."|"
			end
		elseif(1==args.truth) then
			return "|"..args.confidence..">"
		elseif(0==args.truth and 0==args.confidence) then
			return "NC"
		else 
			return "<"..tostring(args.truth)..","..tostring(args.confidence)..">" 
		end
	elseif(nil~=args.name and nil~=args.arity) then
		return prettyPredID(args)
	end
	ret="("
	sep=""
	for k,v in ipairs(args) do
		ret=ret..sep
		if(type(v)=="table") then
			ret=ret..serialize(v)
		elseif(type(v)=="string") then
			ret=ret.."\""..v.."\""
		else
			ret=ret..tostring(v)
		end
		sep=","
	end
	for k,v in pairs(args) do
		if(type(k)~="number") then
			ret=ret..sep..tostring(k).."="
			if(type(v)=="table") then
				ret=ret..serialize(v)
			elseif(type(v)=="string") then
				ret=ret.."\""..v.."\""
			else
				ret=ret..tostring(v)
			end
			sep=","
		end
	end
	return ret..")"
end

function prettyPredID(p) -- serialize a predicate name, prolog-style
	return p.name.."/"..p.arity
end

-- pretty-printing routines for predicate definition

function printWorld(world) -- print all preds
	print(strWorld(world))
end

function strWorld(world) -- return the code for all predicates as a string
	local k, v
	ret=""
	for k,v in pairs(world) do
		ret=ret..strDef(world, k)
	end
	return "# State of the world\n"..ret
end

function strDef(world, k) -- return the definition of the predicate k as a string
	local ret, argCount, args, hash, val, i, v, sep, pfx
	ret=""
	v=world[k]
	if(nil==v) then return ret end
	det=v.det
	if(nil==v.det or v.det) then det="det" else det="nondet" end
	pfx=det.." "..string.gsub(tostring(k), "/%d*$", "")
	if(nil~=v.facts) then
		for hash,val in pairs(v.facts) do
			ret=ret..pfx..serialize(hash).." :- "..serialize(val)..".\n"
		end
	end
	if(nil~=v.def) then
		argCount=0
		args={}
		for i=1,v.arity do
			args[i]="Arg"..tostring(i)
		end
		if(nil~=v.def.children) then
			if(nil~=v.def.children[1]) then
				ret=ret..pfx..serialize(args).." :- "..v.def.children[1].name..serialize(translateArgList(args, v.def.correspondences[1]))
				if(nil==v.def.children[2]) then
					sep=", "
					if(v.def.op=="or") then
						sep="; "
					end
					ret=ret..sep..v.def.children[2].name..serialize(translateArgList(args, v.def.correspondences[2]))
				end
				ret=ret..".\n"
			end
		end
	end
	return ret
end


-- functions for code execution

function factExists(world, p, hash) -- return a fact for the given pred/arglist pair if it exists, otherwise nil
	local r,s
	s=nil
	r=world[prettyPredID(p)]
	if(r~=nil) then
		r=r.facts
		if(r~=nil) then
			r=r[hash]
		end
	end
	return r
end 

function executePredicatePA(world, p, args) -- execute p with the given arglist
	local ret, det, r, hash, ppid
	hash=serialize(args)
	ppid=prettyPredID(p)
	debugPrint("Executing predicate: "..ppid..hash)
	if(nil~=builtins[ppid]) then return builtins[ppid](world, unpack(args)) end
	if(nil~=world) then
		r=factExists(world, p, hash)
		if(nil~=r) then return r end
		r=world[ppid]
		if(nil==r) then return NC end
		det=r.det
		ret=r.def
		if(nil==ret) then return NC end
		if(nil==ret["children"]) then return NC end
		if(nil==ret.children[1]) then return NC end
		if(nil==ret.children[2] and nil~=ret.children[1]) then 
			ret=executePredicatePA(world, ret.children[1], translateArgList(args, ret.correspondences[1])) 
		else
			if(nil==ret.op) then return NC end
			ret=performPLBoolean(
				executePredicatePA(world, ret.children[1], translateArgList(args, ret.correspondences[1])), 
				executePredicatePA(world, ret.children[2], translateArgList(args, ret.correspondences[2])), ret.op)
		end
		if(MYCERR~=MYC_ERR_NOERR) then
			ret=NC
			construct_traceback(p, hash)
		end
		if(det) then
			if(ret~=NC) then
				createFact(world, ppid, hash, ret)
			end
		end
		return ret
	else
		throw(MYC_ERR_UNDEFWORLD, p, hash, "")
		return NC
	end
end
function executePredicateNIA(world, pname, arity, args) -- execute pname/arity with the given arglist
	return (executePredicatePA(world, createPredID(pname, arity), args))
end
function executePredicateNA(world, pname, args) -- execute pname/#args with the given arglist
	return (executePredicateNIA(world, pname, #args, args))
end

-- internal error reporting system

function construct_traceback(p, hash) -- add a line to the traceback
	if(type(p)=="table") then
		ppid=prettyPredID(p)
		pname=p.name
	else
		ppid=p
		pname=p
	end
	if(MYCERR_STR=="") then
		MYCERR_STR=error_string(MYCERR)
	end
	MYCERR_STR=MYCERR_STR.." at "..ppid.." "..pname..hash.."\n"
end

function error_string(code) -- convert an error code to an error message
	if(code==MYC_ERR_NOERR) then return "No error." 
	elseif(code==MYC_ERR_DETNONDET) then return "Predicate marked determinate has indeterminate results."
	elseif(code==MYC_ERR_UNDEFWORLD) then return "World undefined -- no predicates found."
	else return "FIXME unknown/undocumented error "..tostring(code).."." end
end

function throw(code, pred, hash, msg) -- throw an error, with a position in the code as pred(hash) and an error message
	MYCERR=code
	construct_traceback(serialize(pred), serialize(hash)..serialize(msg))
	print(MYCERR_STR)
end


-- functions for constructing our internal predicate structure

function createFact(world, pred, hash, truth) -- det pred(hash) :- truth.
	if(type(pred)=="table") then
		pred=serialize(pred)
	end
	if(nil==world) then 
		return throw(MYC_ERR_UNDEFWORLD, pred, hash, " :- "..serialize(truth))
	else
		if(nil==world[pred]) then
			world[pred]={}
			world[pred].det=true
		end
		if(world[pred].det ~= true) then
			return throw(MYC_ERR_DETNONDET, pred, hash, " :- "..serialize(truth).."\t"..prettyPredID(pred).." is nondet")
		else
			if(nil==world[pred].facts) then
				world[pred].facts={}
			end
			if(nil~=world[pred].facts[hash]) then
				if(not cmpTruth(world[pred].facts[hash], truth)) then
					return throw(MYC_ERR_DETNONDET, pred, hash, " :- "..serialize(truth).."\told value is "..serialize(world[pred].facts[hash]))
				end
			else
				world[pred].facts[hash]=truth
			end		
		end
	end
end

function createDef(world, pred, preds, convs, op, det) -- define a predicate as a combination of given preds
	local p
	if(nil==world) then return throw(MYC_ERR_UNDEFWORLD, pred, {}, " :- "..serialize({op, preds, conv})) end
	p=serialize(pred)
	if(nil==world[p]) then
		world[p]={}
	end
	if(nil~=world[p].det and det~=world[p].det) then
		return throw(MYC_ERR_DETNONDET, pred, {}, " :- "..serialize({op, preds, conv})) 
	else
		world[p].det=det
	end
	if(nil==world[p].def) then
		world[p].def={}
	end
	if(nil==world[p].def.children) then
		world[p].def.children={}
	end
	if(nil==world[p].def.correspondences) then
		world[p].def.correspondences={}
	end
	world[p].def.op=op
	world[p].arity=pred.arity
	if(type(preds)=="table" and nil==preds.name) then
		if(#preds==1) then return createDef(world, pred, preds[1], convs[1], op, det) end
		if(#preds==2) then 
			world[p].def.children[1]=preds[1]
			world[p].def.children[2]=preds[2]
			world[p].def.correspondences[1]=convs[1]
			world[p].def.correspondences[2]=convs[2]
			world[p].def.op=op
		else
			preds_head=preds[1]
			table.remove(preds, 1)
			convs_head=convs[1]
			table.remove(convs, 1)
			sconv={}
			sconv[1]={}
			sconv[2]={}
			for i=0,pred.arity do
				sconv[1][i]=i
				sconv[2][i]=i
			end
			spred=createAnonDef(world, pred.arity, preds, convs, op, det)
			return createDef(world, pred, {spred, preds_head}, {sconv, convs_head}, op, det)
		end
	else
		world[p].def.children[1]=preds
		world[p].def.correspondences[1]=convs
	end 
	return pred
end

-- functions for creating anonymous predicates
function anonPredID(arity) -- produce a synthetic predID for an anonymous predicate
	local spred
	spred=createPredID("__ANONPRED"..tostring(anonPredCount), arity)
	anonPredCount=anonPredCount+1
	return spred
end
function createAnonDef(world, arity, preds, convs, op, det) -- define an anonymous predicate
	return createDef(world, anonPredID(arity), preds, convs, op, det)
end
function createAnonFact(world, arity, hash, truth) -- create an anonymous fact
	return createDef(world, anonPredID(arity), hash, truth)
end



-- parsing functions (WIP)

function parseTruth(x)
	local tr
	string.gsub(
		string.gsub(
			string.gsub(
				string.gsub(x, " *< *(%d*%.?%d+) *[,"..string.char(127).."] *(%d*%.?%d+) *> *", function (t, c) tr={truth=tonumber(t), confidence=tonumber(c)} return "" end ),
				" *< *(%d*%.?%d+) *| *", function(t) tr={truth=tonumber(t), confidence=1} return "" end),
			" *| *(%d*%.?%d+) *> *", function(c) tr={truth=1, confidence=tonumber(t)} return "" end ),
		" *(%w+) *", 
		function (c)
			if (c=="YES") then tr={truth=1, confidence=1} 
			elseif (c=="NO") then tr={truth=0, confidence=1} 
			elseif (c=="NC") then tr={truth=0, confidence=0} 
			else return c end 
			return "" 
		end)
	if(nil==tr) then return x end
	return tr
end

function parseArgs(world, pargs)
	local args
	if(nil==pargs) then return {} end
	args={}
	debugPrint(pargs)
	pargs=string.gsub(
			string.gsub(string.gsub(
				string.gsub(string.gsub(
					string.gsub(string.gsub(pargs, "^%(", ""), "%)$", ""), 
				"%b\"\"", function(c)   return string.gsub(string.gsub(string.gsub(string.gsub(c, ",", string.char(127)),"%(", string.char(126)), "%)", string.char(125)), "(%w+)", function(q) if("YES"==q) then return "\\Y\\E\\S" elseif("NO"==q) then return "\\N\\O" elseif("NC"==q) then return "\\N\\C" else return q end end) end ), "%b<>", function(c) return string.gsub(c, ",", string.char(127)) end ),
			" *(%w+) *(%b()) *", function(pname, pargs) debugPrint("embedded call: "..pname..pargs) local x=parsePredCall(world, pname, pargs) return serialize(executePredicatePA(world, x[1], x[2])) end), 
			" *([^,]+) *", function (c) table.insert(args, parseItem(world, c)) end ), 
		string.char(127), ",")
	for i,j in ipairs(args) do if(type(args)=="string") then args[i]=string.gsub(j, string.char(127), ",") end end
	debugPrint("ARGS: "..serialize(args))
	return args
end

function parseStr(i)
	if(type(i)=="table") then return i end
	local ret=string.gsub(i, "%b\"\"", function (c) return string.gsub(string.gsub(c, "^\"", ""), "\"$", "") end )
	return ret
end

function parseItem(world, i)
	local ret=unificationGetItem(world, parseTruth(i))
	ret=parseStr(ret)
	return ret
end

function parsePredCall(world, pname, pargs)
	local args
	debugPrint("Predicate name: "..serialize(pname))
	args=parseArgs(world, pargs)
	return {createPredID(pname, #args), args}
end

function parseAnd(world, line)
	local t
	t={}
	print(line)
	string.gsub(
		string.gsub(line, "(%w+) *%b()", 
			function (p, a) 
				local s=parsePredCall(world, p, a) 
				table.insert(t, s) 
				return "" 
			end), "([^,]+)", 
		function (l) 
			local s=parseItem(world, l)
			table.insert(t, s)
			return "" 
		end)
	return t
end

function parseOr(world, line)
	local t
	t={}
	string.gsub(line, "([^;]+)", function (l) table.insert(t, parseAnd(world, l)) return "" end )
	return t
end

function genCorrespondences(x, y)
	local ret, i, j, k, l
	ret={{}, {}}
	for i,j in ipairs(x) do
		for k,l in ipairs(y) do
			if(j==l) then ret[1][i]=k ret[2][k]=i end
		end
	end
	return ret
end

function handleAnds(world, det, pred, args, ast)
	local head, tail
end
function handleOrs(world, det, pred, args, ast)
	local head, tail, remainder
	head=args[1]
	tail=args
	table.remove(tail, 1)
	if(#tail == 1) then
		if(#(tail[1])==2 and tail[1][1]["name"]~= nil) then
			remainder={tail[1][1], genCorrespondences(args, tail[1][2])}
		else
		--XXX
		end
	end
	if(#head == 2 and head[1]["name"]~=nil) then
	end
end

function parsePred(world, det, pname, pargs, pdef)
	local args, pred, pdeps, ast, isDet
	if(det~="det" and det~="nondet") then 
		print ("Parse error: neither det nor nondet!\n >>"..det.."<< "..pname..pargs.." :- "..pdef..".")
		os.exit(1)
	end
	if(det=="det") then isDet=true else isDet=false end
	args=parseArgs(world, pargs)
	pred=createPredID(pname, #args)
	ast=parseOr(world, pdef)
	if(#ast>1) then handleOrs(world, isDet, pred, args, ast) else
		handleAnds(world, isDet, pred, args, ast[1])
	end
	return ""
end
function parseBodyComponents(world, body) 
	local items={}
	string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(body, " *(%w+) *(%b()) *", 
		function (pname, pargs) 
			table.insert(items, executePredicateNA(world, pname, parseArgs(world, pargs)))
			return "" 
		end), "(%b<>)", function(c) 
			local x=parseItem(world, c) 
			table.insert(items, x)
		end), "(%b<|)", function(c) 
			local x=parseItem(world, c) 
			table.insert(items, x)
		end), "(%b|>)", function(c) 
			local x=parseItem(world, c) 
			table.insert(items, x)
		end), "(.+)", function(c) 
			local x=parseItem(world, c) 
			table.insert(items, x)
		end)
	return items
end

function parseAndComponent(world, andComponent, andTBL)
	for i,v in ipairs(parseBodyComponents(world, andComponent)) do
		table.insert(andTBL, v)
	end
	return ""
end
function parseOrComponent(world, orComponent, orTBL)
	local andTBL={}
	string.gsub(string.gsub(string.gsub(
		string.gsub(orComponent, "(.*)%) *,", 
			function(andComponent) return parseAndComponent(world, andComponent..")", andTBL) end
			), " *(%w+) *(%b()) *", function(pfx,sfx) return parseAndComponent(world, pfx..sfx, andTBL) end
			), " *([<|][^>|]+[>|]) *", function(andComponent) return parseAndComponent(world, andComponent, andTBL) end
		),  "([^,]+)",
			function(andComponent) return parseAndComponent(world, andComponent, andTBL) end)
	local head=NO
	if(#andTBL>0) then
		head=andTBL[1]
		table.remove(andTBL, 1)
		for i,v in ipairs(andTBL) do
			head=performPLBoolean(head, v, "and")
		end
	end
	table.insert(orTBL, head)
	return ""
end

function parseLine(world, line)
	clearSymbolSpace(world)
	debugPrint("LINE: "..tostring(line))
	if(nil==line) then return line end
	if(""==line) then return line end
	if("#"==line[0]) then return "" end
	return serialize(string.gsub(
		string.gsub(line, "^(%l%w+)  *(%l%w+) *(%b()) *:%- *([^.]+). *$", 
			function (det, pname, pargs, pdef) 
				mycnet.forwardFact(world, line)
				return serialize(parsePred(world, det, pname, pargs, pdef))
			end),
		"^%?%- *(.+) *%.$", 
		function (body) 
			local ret=mycnet.forwardRequest("?- "..body..".")
			if(ret~=nil) then ret=canonicalizeCTV(parseTruth(ret)) end
			if(ret~=nil and not cmpTruth(ret, NC)) then return ret end
			local orTBL={}
			string.gsub(body, "([^;]+)", 
				function(orComponent) return parseOrComponent(world, orComponent, orTBL) end)
			local head=NC
			if(#orTBL>0) then
				head=orTBL[1]
				table.remove(orTBL,1)
			end
			for i,v in ipairs(orTBL) do
				head=performPLBoolean(head,v,"or")
			end 
			return serialize(head)
		end
	))
end 

function parseFile(world, file)
	local line, ret
	line=file:read("*l")
	while(nil~=line) do
		ret=parseLine(world, line)
		debugPrint("=> "..serialize(ret))
		line=file:read("*l")
	end
end

-- interactive interpreter main loop
function mainLoop(world)
	io.write("?- ")
	line=io.read("*l")
	if(nil==line) then os.exit() end
	if(nil==string.find(line, ":%-")) then line="?- "..line end
	debugPrint("LINE: "..line)
	print(serialize(parseLine(world, line)))
	if(MYCERR~=MYC_ERR_NOERR) then
		construct_traceback(MYCERR, "mainloop", {})
		print(MYCERR_STR)
		os.exit(1)
	end
end

function main(argv)
	local world, interactive, i, arg, f
	setupNetworking()
	world={}
	interactive=true
	forceInteractive=false
	if(#argv==0) then
		interactive=true
	else
		for i,arg in ipairs(argv) do
			if("-h"==arg or "-help"==arg or "--help"==arg or "-?"==arg) then
				print("Usage:\n\tmycroft\nmycroft [-h|-?|--help|-help]\n\tmycroft [file1 file2...] [-i] [-p] [-v]\n\tmycroft -t")
				print("Options:\n\t-h|-?|-help|--help\t\tPrint this help\n\t-i\t\t\tInteractive mode\n\t-t\t\t\tRun test suite\n\t-p\t\t\tParanoid mode (disable some potentially insecure network-related features\n\t-v\t\t\tVerbose")
			elseif("-t"==arg) then test() os.exit()
			elseif("-p"==arg) then paranoid=true
			elseif("-v"==arg) then verbose=true
			elseif("-i"==arg) then interactive=true forceInteractive=true
			else 
				if(not forceInteractive) then interactive=false end
				f, err=io.open(arg)
				if(nil==f) then
					print("Could not open file "..arg.." for reading: "..tostring(err).."\nTry mycroft -h for help")
					os.exit(1)
				end
				parseFile(world, f)
			end
		end
	end
	if(interactive) then
		print(serialize(executePredicateNA(world, "welcome", {})))
		while (true) do mainLoop(world) end
	end
end


-- test suite
function testSerialize()
	print("Testing serialization...")
	print("YES -> "..serialize(YES))
	print("NO -> "..serialize(NO))
	print("NC -> "..serialize(NC))
	print("<0.5| -> "..serialize({truth=0.5, confidence=1}))
	print("|.05> -> "..serialize({truth=1, confidence=0.5}))
	print("<0.5,0.5> -> "..serialize({truth=0.5, confidence=0.5}))
	print()
	print("test/0 -> "..serialize(createPredID("test", 0)))
	print("(test/0,YES,NO,NC) ->"..serialize({createPredID("test", 0), YES, NO, NC}))
	print()
end
function testErr()
	print("Testing error reporting...")
	print("MYC_ERR_NOERR -> "..error_string(MYC_ERR_NOERR))
	print("MYC_ERR_DETNONDET -> "..error_string(MYC_ERR_DETNONDET))
	print("MYC_ERR_UNDEFWORLD -> "..error_string(MYC_ERR_UNDEFWORLD))
	print("error_string(\"woah\") -> "..error_string("woah"))
	print("failure/0 in nil world -> "..serialize(executePredicateNA(nil, "failure", {})))
	print(MYCERR_STR)
	MYCERR_STR=""
	MYCERR=MYC_ERR_NOERR
end
function testBool()
	print("Testing booleans...")
	print("YES and NO = "..serialize(performPLBoolean(YES, NO, "and")))
	print("YES or NO = "..serialize(performPLBoolean(YES, NO, "or")))
	print("YES and NC = "..serialize(performPLBoolean(YES, NC, "and")))
	print("YES or NC = "..serialize(performPLBoolean(YES, NC, "or")))
	print("NC and NO = "..serialize(performPLBoolean(NC, NO, "and")))
	print("NC or NO = "..serialize(performPLBoolean(NC, NO, "or")))
	print()
	print("YES and <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "and")))
	print("YES or <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "or")))
	print("NO and <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "and")))
	print("NO or <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "or")))
	print("NC and <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "and")))
	print("NC or <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "or")))
	print()
	print("YES and <0.5| = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=1}, "and")))
	print("YES or <0.5| = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=1}, "or")))
	print("NO and <0.5| = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=1}, "and")))
	print("NO or <0.5| = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=1}, "or")))
	print("NC and <0.5| = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=1}, "and")))
	print("NC or <0.5| = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=1}, "or")))
	print("YES and |0.5> = "..serialize(performPLBoolean(YES, {truth=1, confidence=0.5}, "and")))
	print("YES or |0.5> = "..serialize(performPLBoolean(YES, {truth=1, confidence=0.5}, "or")))
	print("NO and |0.5> = "..serialize(performPLBoolean(NO, {truth=1, confidence=0.5}, "and")))
	print("NO or |0.5> = "..serialize(performPLBoolean(NO, {truth=1, confidence=0.5}, "or")))
	print("NC and |0.5> = "..serialize(performPLBoolean(NC, {truth=1, confidence=0.5}, "and")))
	print("NC or |0.5> = "..serialize(performPLBoolean(NC, {truth=1, confidence=0.5}, "or")))
	print()
end
function testBuiltins()
	print("Testing builtins...")
	print("builtins/0 -> "..serialize(executePredicateNA(world, "builtins", {})))
	print()
	print("equal/2(1,1) -> "..serialize(executePredicateNA(world, "equal", {1, 1})))
	print("equal/2(1,2) -> "..serialize(executePredicateNA(world, "equal", {1, 2})))
	print("gt/2(1,1) -> "..serialize(executePredicateNA(world, "gt", {1, 1})))
	print("gt/2(1,2) -> "..serialize(executePredicateNA(world, "gt", {1, 2})))
	print("lt/2(1,1) -> "..serialize(executePredicateNA(world, "lt", {1, 1})))
	print("lt/2(1,2) -> "..serialize(executePredicateNA(world, "lt", {1, 2})))
	print("gte/2(1,1) -> "..serialize(executePredicateNA(world, "gte", {1, 1})))
	print("gte/2(1,2) -> "..serialize(executePredicateNA(world, "gte", {1, 2})))
	print("lte/2(1,1) -> "..serialize(executePredicateNA(world, "lte", {1, 1})))
	print("lte/2(1,2) -> "..serialize(executePredicateNA(world, "lte", {1, 2})))
	print("equal/2(YES,YES) -> "..serialize(executePredicateNA(world, "equal", {YES, YES})))
	print("equal/2(YES,2) -> "..serialize(executePredicateNA(world, "equal", {YES, 2})))
	print("gt/2(YES,YES) -> "..serialize(executePredicateNA(world, "gt", {YES, YES})))
	print("gt/2(YES,2) -> "..serialize(executePredicateNA(world, "gt", {YES, 2})))
	print("lt/2(YES,YES) -> "..serialize(executePredicateNA(world, "lt", {YES, YES})))
	print("lt/2(YES,2) -> "..serialize(executePredicateNA(world, "lt", {YES, 2})))
	print("gte/2(YES,YES) -> "..serialize(executePredicateNA(world, "gte", {YES, YES})))
	print("gte/2(YES,2) -> "..serialize(executePredicateNA(world, "gte", {YES, 2})))
	print("lte/2(YES,YES) -> "..serialize(executePredicateNA(world, "lte", {YES, YES})))
	print("lte/2(YES,2) -> "..serialize(executePredicateNA(world, "lte", {YES, 2})))
	print("equal/2(NO,NO) -> "..serialize(executePredicateNA(world, "equal", {NO, NO})))
	print("equal/2(NO,2) -> "..serialize(executePredicateNA(world, "equal", {NO, 2})))
	print("gt/2(NO,NO) -> "..serialize(executePredicateNA(world, "gt", {NO, NO})))
	print("gt/2(NO,2) -> "..serialize(executePredicateNA(world, "gt", {NO, 2})))
	print("lt/2(NO,NO) -> "..serialize(executePredicateNA(world, "lt", {NO, NO})))
	print("lt/2(NO,2) -> "..serialize(executePredicateNA(world, "lt", {NO, 2})))
	print("gte/2(NO,NO) -> "..serialize(executePredicateNA(world, "gte", {NO, NO})))
	print("gte/2(NO,2) -> "..serialize(executePredicateNA(world, "gte", {NO, 2})))
	print("lte/2(NO,NO) -> "..serialize(executePredicateNA(world, "lte", {NO, NO})))
	print("lte/2(NO,2) -> "..serialize(executePredicateNA(world, "lte", {NO, 2})))
	print()
	print("print/1(\"Hello, world!\") -> "..serialize(executePredicateNA(world, "print", {"Hello, world!"})))
	print()
end
function testCore()
	print("Testing core...")
	world={}
	truePred=createPredID("true", 0)
	falsePred=createPredID("false", 0)
	ncPred=createPredID("noConfidence", 0)
	synPred1=createPredID("synthetic", 1)
	synPred2=createPredID("synthetic", 2)
	synPred3=createPredID("synthetic", 3)
	synPred4=createPredID("synthetic", 4)
	synPred5=createPredID("synthetic", 5)
	synPred6=createPredID("synthetic", 6)
	synPred7=createPredID("synthetic", 7)
	createFact(world, truePred, "()", YES)
	createFact(world, falsePred, "()", NO)
	createFact(world, ncPred, "()", NC)
	createDef(world, synPred1, {truePred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred2, {truePred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred3, {truePred, ncPred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred4, {truePred, ncPred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred5, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred6, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred7, {truePred, falsePred, truePred}, {{{},{}}, {{},{}}, {{}, {}}}, "or", true)
	print()
	printWorld(world)
	print()
	print("true/0 -> "..serialize(executePredicateNA(world, "true", {})))
	print("false/0 -> "..serialize(executePredicateNA(world, "false", {})))
	print("noConfidence/0 ->"..serialize(executePredicateNA(world, "noConfidence", {})))
	print()
	print("synthetic/1 -> "..serialize(executePredicateNA(world, "synthetic", {1})))
	print("synthetic/2 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2})))
	print("synthetic/3 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3})))
	print("synthetic/4 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4})))
	print("synthetic/5 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5})))
	print("synthetic/6 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5, 6})))
	print("synthetic/7 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5, 6, 7})))
	print()
	print("printPred/1(true/0) -> "..serialize(executePredicateNA(world, "printPred", {truePred})))
	print("printWorld/0 -> "..serialize(executePredicateNA(world, "printWorld", {})))
	print(MYCERR_STR)
	print()
end
function testParse()
	print("Testing parse...")
	print(parseLine({}, "det true(x, y, z) :- YES."))
end
function testHelp()
	print("Testing online help...")
	print("help/0 -> "..serialize(executePredicateNA({}, "help", {})))
	print("help/1(\"banner\") -> "..serialize(executePredicateNA({}, "help", {"banner"})))
	print("help/1(\"syntax\") -> "..serialize(executePredicateNA({}, "help", {"syntax"})))
	print("help/1(\"version\") -> "..serialize(executePredicateNA({}, "help", {"version"})))
	print("help/1(\"copying\") -> "..serialize(executePredicateNA({}, "help", {"copying"})))
	print()
	for k,v in pairs(builtins) do
		print("help/1("..serialize(k)..") -> "..serialize(executePredicateNA({}, "help", {k})))
	end
end
function testFile()
	main({"test.myc"})
end
function test()
	testSerialize()
	testErr()
	testBool()
	testCore()
	testBuiltins()
	testParse()
	testHelp()
	testFile()
end

main(arg)
