#!/usr/bin/env lua

MYCERR=""
MYCERR_STR=""
MYC_ERR_NOERR=0
MYC_ERR_DETNONDET=1
MYC_ERR_UNDEFWORLD=2

NC={truth=0, confidence=0}
YES={truth=1, confidence=1}
NO={truth=0, confidence=1}

function translateArgList(list, arity)
	l={}
	for i in arity do 
		l[arity[1][i]]=list[arity[0][i]]
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

function canonicalizeCTV(r)
	if(r.confidence<0) then r.confidence=0 end
	if(r.confidence==0) then return NC end
	if(r.truth<0) then r.truth=0 end
	if(r.truth>1) then r.truth=1 end
	if(r.confidence>1) then r.confidence=1 end
	return r
end

function performPLBoolean(p, q, op)
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

function serialize(args)
	if(type(args)~="table") then
		if(type(args)=="string") then
			return "\""..args.."\""
		else
			return tostring(args)
		end
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
	return ret..")"
end

function prettyPredID(p)
	return p.name.."/"..p.arity
end

function factExists(world, p, hash)
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

function construct_traceback(p, hash)
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

function executePredicatePA(world, p, args)
	hash=serialize(args)
	ppid=prettyPredID(p)
	if(nil~=world) then
		r=factExists(world, p, hash)
		if(nil~=r) then return r end
		r=world[ppid]
		if(nil==r) then return NC end
		det=r.det
		ret=r.def
		if(nil==ret) then return NC end
		if(nil==ret.children[1] and nil~=ret.children[0]) then 
			ret=executePredicatePA(world, ret.children[0], translateArgs(args, ret.correspondences[0])) 
		else
			ret=performPLBoolean(
				executePredicatePA(world, ret.children[0], translateArgs(args, ret.correspondences[0])), 
				executePredicatePA(world, ret.children[1], translateArgs(args, ret.correspondences[1])))
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
function executePredicateNIA(world, pname, arity, args)
	return (executePredicatePA(world, createPredID(pname, arity), args))
end
function executePredicateNA(world, pname, args)
	return (executePredicateNIA(world, pname, #args, args))
end
function error_string(code) 
	if(code==MYC_ERR_NOERR) then return "No error." 
	elseif(code==MYC_ERR_DETNONDET) then return "Predicate marked determinate has indeterminate results."
	elseif(code==MYC_ERR_UNDEFWORLD) then return "World undefined -- no predicates found."
	else return "FIXME unknown/undocumented error." end
end

function createFact(world, pred, hash, truth)
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
				if(world[pred].facts[hash]~=truth) then
					return throw(MYC_ERR_DETNONDET, pred, hash, " :- "..serialize(truth).."\told value is "..serialize(world[pred].facts[hash]))
				end
			else
				world[pred].facts[hash]=truth
			end		
		end
	end
end

function throw(code, pred, hash, msg)
	MYCERR=code
	construct_traceback(serialize(pred), serialize(hash)..serialize(msg))
	print(MYCERR_STR)
end

function createDef(world, pred, preds, convs, op)	
	if(nil==world) then return throw(MYC_ERR_UNDEFWORLD, pred, hash, " :- "..serialize({op, preds, conv})) end
end

function test()
	print(serialize(YES))
	print(serialize(NO))
	print(serialize(NC))
	print(serialize({truth=0.5, confidence=1}))
	print(serialize({truth=1, confidence=0.5}))
	print(serialize({truth=0.5, confidence=0.5}))
	print(serialize(createPredID("test", 0)))
	print(serialize({createPredID("test", 0), YES, NO, NC}))
	print(error_string(MYC_ERR_NOERR))
	print(error_string(MYC_ERR_DETNONDET))
	print(error_string(MYC_ERR_UNDEFWORLD))
	print(error_string("woah"))
	print(serialize(executePredicateNA(nil, "failure", {})))
	print(MYCERR_STR)
	MYCERR_STR=""
	MYCERR=MYC_ERR_NOERR
	print("YES and NO = "..serialize(performPLBoolean(YES, NO, "and")))
	print("YES or NO = "..serialize(performPLBoolean(YES, NO, "or")))
	print("YES and NC = "..serialize(performPLBoolean(YES, NC, "and")))
	print("YES or NC = "..serialize(performPLBoolean(YES, NC, "or")))
	print("NC and NO = "..serialize(performPLBoolean(NC, NO, "and")))
	print("NC or NO = "..serialize(performPLBoolean(NC, NO, "or")))
	print("YES and <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "and")))
	print("YES or <0.5, 0.5> = "..serialize(performPLBoolean(YES, {truth=0.5, confidence=0.5}, "or")))
	print("NO and <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "and")))
	print("NO or <0.5, 0.5> = "..serialize(performPLBoolean(NO, {truth=0.5, confidence=0.5}, "or")))
	print("NC and <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "and")))
	print("NC or <0.5, 0.5> = "..serialize(performPLBoolean(NC, {truth=0.5, confidence=0.5}, "or")))
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
	world={}
	truePred=createPredID("true", "0")
	falsePred=createPredID("false", "0")
	ncPred=createPredID("noConfidence", "0")
	createFact(world, truePred, "()", YES)
	createFact(world, falsePred, "()", NO)
	createFact(world, ncPred, "()", NC)
	print(serialize(world))
	print(serialize(executePredicateNA(world, "true", {})))
	print(serialize(executePredicateNA(world, "false", {})))
	print(serialize(executePredicateNA(world, "noConfidence", {})))
	print(MYCERR_STR)
end
test()
