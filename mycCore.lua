anonPredCount=0

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
	if(nil~=world) then
		if(nil~=builtins[ppid]) then return builtins[ppid](world, unpack(args)) end
		if(nil~=world.aliases[ppid]) then 
			ppid=world.aliases[ppid]
			p=inflatePredID(ppid)
			if(nil~=builtins[ppid]) then return builtins[ppid](world, unpack(args)) end
		end
		r=factExists(world, p, hash)
		if(nil~=r) then return r end
		if(forwardQueries) then
			ret=mycnet.forwardRequest(world, "?- "..p.name..hash..".")
			if(ret~=nil) then ret=canonicalizeCTV(parseTruth(ret)) end
			if(ret~=nil and not cmpTruth(ret, NC)) then return ret end
		end
		r=world[ppid]
		if(nil==r) then return NC end
		det=r.det
		ret=r.def
		if(nil==ret) then return NC end
		if(nil==ret["children"]) then return NC end
		if(nil==ret.children[1]) then return NC end
		if(nil==ret.children[2] and nil~=ret.children[1]) then 
			ret=executePredicatePA(world, ret.children[1], translateArgList(args, ret.correspondences[1], ret.literals[1])) 
		else
			if(nil==ret.op) then return NC end
			ret=performPLBoolean(
				executePredicatePA(world, ret.children[1], translateArgList(args, ret.correspondences[1], ret.literals[1])), 
				executePredicatePA(world, ret.children[2], translateArgList(args, ret.correspondences[2], ret.literals[2])), ret.op)
		end
		if(world.MYCERR~=MYC_ERR_NOERR) then
			ret=NC
			construct_traceback(world, p, hash)
		end
		if(det) then
			if(ret~=NC) then
				createFact(world, ppid, hash, ret)
			end
		end
		return ret
	else
		throw(world, MYC_ERR_UNDEFWORLD, p, hash, "")
		return NC
	end
end
function executePredicateNIA(world, pname, arity, args) -- execute pname/arity with the given arglist
	return (executePredicatePA(world, createPredID(pname, arity), args))
end
function executePredicateNA(world, pname, args) -- execute pname/#args with the given arglist
	return (executePredicateNIA(world, pname, #args, args))
end


-- functions for constructing our internal predicate structure

function createFact(world, pred, hash, truth) -- det pred(hash) :- truth.
	debugPrint({"createFact", "world", pred, hash, truth})
	if(type(pred)=="table") then
		pred=serialize(pred)
	end
	if(nil==world) then 
		return throw(world, MYC_ERR_UNDEFWORLD, pred, hash, " :- "..serialize(truth))
	else
		if(nil==world[pred]) then
			world[pred]={}
			world[pred].det=true
		end
		if(world[pred].det ~= true) then
			return throw(world, MYC_ERR_DETNONDET, pred, hash, " :- "..serialize(truth).."\t"..prettyPredID(pred).." is nondet")
		else
			if(nil==world[pred].facts) then
				world[pred].facts={}
			end
			if(nil~=world[pred].facts[hash]) then
				if(not cmpTruth(world[pred].facts[hash], truth)) then
					return throw(world, MYC_ERR_DETNONDET, pred, hash, " :- "..serialize(truth).."\told value is "..serialize(world[pred].facts[hash]))
				end
			else
				world[pred].facts[hash]=truth
			end		
		end
	end
	return inflatePredID(pred)
end

function createDef(world, pred, preds, convs, op, det, literals) -- define a predicate as a combination of given preds
	debugPrint({"createDef", "world", pred, preds, convs, op, det})
	pred=inflatePredID(pred)
	local p
	if(nil==world) then return throw(world, MYC_ERR_UNDEFWORLD, pred, {}, " :- "..serialize({op, preds, conv})) end
	if (nil==world.aliases) then world.aliases={} end
	p=serialize(pred)
	if(nil==world[p]) then
		world[p]={}
	end
	if(nil==literals) then literals={} end
	if(nil~=world[p].det and det~=world[p].det) then
		return throw(world, MYC_ERR_DETNONDET, pred, {}, " :- "..serialize({op, preds, conv})) 
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
	if(nil==world[p].def.literals) then
		world[p].def.literals={}
	end
	world[p].def.op=op
	world[p].arity=pred.arity
	if(type(preds)=="string") then
		preds=inflatePredID(preds)
	end
	if(type(preds)=="table" and nil==preds.name) then
		if(#preds==1) then 
			local i,j,same
			same=true
			for i,j in ipairs(convs[1][2]) do
				if(convs[1][1][i]~=j or convs[1][3][i] or literals[i]) then
					same=false
				end
			end
			if(same) then 
				world.aliases[p]=serialize(preds[1]) 
				return inflatePredID(world.aliases[p])
			else
				return createDef(world, pred, preds[1], convs[1], op, det) 
			end
		end
		if(#preds==2) then
			local i,j,same
			same=nil
			for i,j in pairs(world) do
				if(not same and type(j)=="table" and i~="symbols" and i~=aliases and i~=p) then 
					if(j.def) then
						if(op==j.def.op) then
							if(serialize(j.def.children)==serialize(preds)) then
								if(serialize(j.def.correspondences)==serialize(convs)) then
									if(serialize(j.def.literals)==serialize(literals)) then
										same=i
									end
								end
							end
						end
					end
				end
			end
			if(same) then
				world.aliases[p]=same
				world[p]=nil
				return inflatePredID(same)
			else
				preds[1]=inflatePredID(preds[1])
				preds[2]=inflatePredID(preds[2])
				world[p].def.children[1]=preds[1]
				world[p].def.children[2]=preds[2]
				world[p].def.correspondences[1]=convs[1]
				world[p].def.correspondences[2]=convs[2]
				world[p].def.literals[1]=literals[1]
				world[p].def.literals[2]=literals[2]
				world[p].def.op=op
			end
		else
			local preds_head=preds[#preds]
			table.remove(preds, #preds)
			local convs_head=convs[#convs]
			table.remove(convs, #convs)
			local literals_head=literals[#literals]
			table.remove(literals, #literals)
			local sconv={}
			sconv[1]={}
			sconv[2]={}
			for i=0,pred.arity do
				sconv[1][i]=i
				sconv[2][i]=i
			end
			local spred=createAnonDef(world, pred.arity, preds, convs, op, det, literals_head)
			return createDef(world, pred, {spred, preds_head}, {sconv, convs_head}, op, det, literals)
		end
	else
		world[p].def.children[1]=preds
		world[p].def.correspondences[1]=convs
	end 
	return inflatePredID(pred)
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
	return createFact(world, anonPredID(arity), hash, truth)
end

-- interactive interpreter main loop
require("mycPretty")
ps1="?- "
ps2="...\t"
if(ansi) then
	ps1=colorCode("black", "green", 1)..ps1..colorCode("black", "white", 1)
	ps2=colorCode("black", "green", 1)..ps2..colorCode("black", "white", 1)
end
prompt=ps1
lineContinuation=""
getline=function(prompt) 
	io.write(prompt)
	return io.read("*l")
end
function mainLoop(world)
	local success,line=pcall(getline,prompt)
	if(not success) then return false end
	if(nil==line) then return false end
	if(""==line) then return true end
	if(nil==string.find(line, "^ *#") and nil==string.find(line, "%. *$") and nil==string.find(line, "%. *#")) then
		lineContinuation=lineContinuation..line
		prompt=ps2
	else
		line=lineContinuation..line
		lineContinuation=""
		prompt=ps1
		if(nil==string.find(line, ":%-")) then line="?- "..line end
		debugPrint("LINE: "..line)
		ret=parseLine(world, line)
		--if(not s) then print(ret) print (debug.traceback()) return false end
		ret=serialize(ret)
		--if(not s) then print(ret) print(debug.traceback()) return false end
		print(ret)
		if(world.MYCERR~=MYC_ERR_NOERR) then
			construct_traceback(world, "mainloop", "()")
			print(pretty(world.MYCERR_STR))
			return false
		end
	end
	return true
end

function initMycroft(world)
	package.path=package.path..";/usr/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?.lua"
	package.cpath=package.cpath..";/usr/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/?.so"
	local s,e = pcall(require, "hash")
	if(not s) then print e end
	require("mycBuiltins")
	initBuiltins()
	require("mycTests")
	require("mycParse")
	require("mycPretty")
	require("mycErr")
	world.MYCERR=MYC_ERR_NOERR
	world.MYCERR_STR=""
	world.aliases={}
	require("mycNet")
	setupNetworking()
	require("mycType")
	local s,e = pcall(require, "readline")
	if(s) then
		debugPrint("Found readline; enabling")
		readline=require("readline")
		readline.set_options({histfile="~/.mycroft_history", keeplines=1000})
		getline=function(prompt)
			readline.save_history()
			if(not prompt) then return nil end
			return readline.readline(prompt)
		end
	else
		debugPrint("Could not find readline: "..tostring(e))
	end
end

function exitClean(c)
	if(jobCount) then
		if(jobs) then
			for _,j in ipairs(jobs) do
				mycnet.forwardRequest({}, '?- print("Master process closing; killing slave jobs.").')
				mycnet.forwardRequest({}, '?- exit().')
			end
		end
	end
	print(colorCode().."\n"..string.char(27).."[0J") -- unset the color and clear the screen from the cursor on down
	os.exit(c)
end
