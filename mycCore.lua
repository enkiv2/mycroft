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

-- interactive interpreter main loop
require("mycPretty")
prompt="?- "
if(ansi) then
	prompt=colorCode("black", "green", 1)..prompt..colorCode("black", "white", 1)
end
function mainLoop(world)
	io.write(prompt)
	line=io.read("*l")
	if(nil==line) then return false end
	if(nil==string.find(line, ":%-")) then line="?- "..line end
	debugPrint("LINE: "..line)
	print(pretty(serialize(parseLine(world, line))))
	if(MYCERR~=MYC_ERR_NOERR) then
		construct_traceback(MYCERR, "mainloop", {})
		print(MYCERR_STR)
		return false
	end
	return true
end

function initMycroft()
	require("mycBuiltins")
	initBuiltins()
	require("mycTests")
	require("mycParse")
	require("mycPretty")
	require("mycErr")
	require("mycNet")
	setupNetworking()
	require("mycType")
end
