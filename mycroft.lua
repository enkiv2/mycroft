#!/usr/bin/env lua

anonPredCount=0

MYCERR=""
MYCERR_STR=""
MYC_ERR_NOERR=0
MYC_ERR_DETNONDET=1
MYC_ERR_UNDEFWORLD=2

NC={truth=0, confidence=0}
YES={truth=1, confidence=1}
NO={truth=0, confidence=1}

function translateArgList(list, arity)
	local l, i, j
	l={}
	if(arity==nil) then return l end
	for i,j in ipairs(arity[1]) do 
		l[arity[2][i]]=list[arity[1][i]]
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
	local r
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
	local ret, sep
	if(type(args)~="table") then
		return tostring(args)
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

function prettyPredID(p)
	return p.name.."/"..p.arity
end

function factExists(world, p, hash)
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
	local ret, det, r, hash, ppid
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
				if(not cmpTruth(world[pred].facts[hash], truth)) then
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

function createDef(world, pred, preds, convs, op, det)
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
			table.remove(preds, 0)
			convs_head=convs[1]
			table.remove(convs, 0)
			spred=createPredID("__ANONPRED"..tostring(anonPredCount), pred.arity)
			anonPredCount=anonPredCount+1
			sconv={}
			sconv[1]={}
			sconv[2]={}
			for i=0,pred.arity do
				sconv[1][i]=i
				sconv[2][i]=i
			end
			createDef(world, spred, preds, convs, op, det)
			return createDef(world, pred, {spred, preds_head}, {sconv, convs_head}, op, det)
		end
	else
		world[p].def.children[1]=preds
		world[p].def.correspondences[1]=convs
	end 
end

function printWorld(world)
	print(strWorld(world))
end

function strWorld(world) 
	local k, v, hash, val, argCount, i, ret
	ret=""
	for k,v in pairs(world) do
		det=v.det
		if(nil==v.det or v.det) then det="det" else det="nondet" end
		if(nil~=v.facts) then
			for hash,val in pairs(v.facts) do
				ret=ret..det.." "..string.gsub(tostring(k), "/%d+$", "")..serialize(hash).." :- "..serialize(val)..".\n"
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
					if(nil~=v.def.children[2]) then
						if(v.def.op=="or") then
							ret=ret..det.." "..string.gsub(tostring(k), "/%d+$", "")..serialize(args).." :- "..v.def.children[1].name..serialize(translateArgList(args, v.def.correspondences[1])).."; "..v.def.children[2].name..serialize(translateArgList(args, v.def.correspondences[2]))..".\n"
						else
							ret=ret..det.." "..string.gsub(tostring(k), "/%d+$", "")..serialize(args).." :- "..v.def.children[1].name..serialize(translateArgList(args, v.def.correspondences[1]))..", "..v.def.children[2].name..serialize(translateArgList(args, v.def.correspondences[2]))..".\n"
						end
					else
						ret=ret..det.." "..tostring(k)..serialize(args).." :- "..v.def.children[1].name..serialize(translateArgList(args, v.def.correspondences[1]))..".\n"
					end
				end
			end
		end
	end
	return "# State of the world\n"..ret
end

function parseTruth(x)
	local tr
	string.gsub(
		string.gsub(
			string.gsub(
				string.gsub(x, " *< *(%d+) *, *(%d+) *> *", function (t, c) tr={truth=tonumber(t), confidence=tonumber(c)} return "" end ),
				" *< *(%d+) *| *", function(t) tr={truth=tonumber(t), confidence=1} return "" end),
			" *| *(%d+) *> *", function(c) tr={truth=1, confidence=tonumber(t)} return "" end ),
		"(%w+)", function (c) if (c=="YES") then tr={truth=1, confidence=1} elseif (c=="NO") then tr={truth=0, confidence=1} elseif (c=="NC") then tr={truth=0, confidence=0} else return c end return "" end)
	return tr
end

function parseArgs(pargs)
	local args
	args={}
	pargs=string.gsub(string.gsub(string.gsub(pargs, "^%(", ""), "%)$", ""), "([^, ]+)", function (c) table.insert(args, parseItem(c)) end )
	return args
end

function parseItem(i)
	return parseTruth(string.gsub(i, "  *", ""))
end

function parsePredCall(pname, pargs)
	local args
	args=parseargs(pargs)
	return {createPredID(pname, #args), args}
end

function parseAnd(line)
	local t
	t={}
	string.gsub(string.gsub(line, "(%w+) *%b()", function (p, a) table.insert(t, parsePredCall(p, a)) return "" end), "([^,]+)", function (l) table.insert(t, parseItem(l)) return "" end)
	return t
end

function parseOr(line)
	local t
	t={}
	string.gsub(line, "([^;]+)", function (l) table.insert(t, parseAnd(l)) return "" end )
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
	args=parseArgs(pargs)
	pred=createPredID(pname, #args)
	ast=parseOr(pdef)
	if(#ast>1) then handleOrs(world, isDet, pred, args, ast) else
		handleAnds(world, isDet, pred, args, ast[1])
	fi
	return ""
end

function parseLine(world, line)
	string.gsub(line, "^(%l%w+)  *(%l%w+) *(%b()) *:%- *([^.]+). *$", function (det, pname, pargs, pdef) return parsePred(world, det, pname, pargs, pdef) end)
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
	truePred=createPredID("true", 0)
	falsePred=createPredID("false", 0)
	ncPred=createPredID("noConfidence", 0)
	synPred1=createPredID("synthetic", 1)
	synPred2=createPredID("synthetic", 2)
	synPred3=createPredID("synthetic", 3)
	synPred4=createPredID("synthetic", 4)
	synPred5=createPredID("synthetic", 5)
	synPred6=createPredID("synthetic", 6)
	createFact(world, truePred, "()", YES)
	createFact(world, falsePred, "()", NO)
	createFact(world, ncPred, "()", NC)
	createDef(world, synPred1, {truePred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred2, {truePred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred3, {truePred, ncPred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred4, {truePred, ncPred}, {{{},{}}, {{},{}}}, "or", true)
	createDef(world, synPred5, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "and", true)
	createDef(world, synPred6, {ncPred, falsePred}, {{{},{}}, {{},{}}}, "or", true)
	printWorld(world)
	print("true/0 -> "..serialize(executePredicateNA(world, "true", {})))
	print("false/0 -> "..serialize(executePredicateNA(world, "false", {})))
	print("noConfidence/0 ->"..serialize(executePredicateNA(world, "noConfidence", {})))
	print("synthetic/1 -> "..serialize(executePredicateNA(world, "synthetic", {1})))
	print("synthetic/2 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2})))
	print("synthetic/3 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3})))
	print("synthetic/4 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4})))
	print("synthetic/5 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5})))
	print("synthetic/6 -> "..serialize(executePredicateNA(world, "synthetic", {1, 2, 3, 4, 5, 6})))
	print(MYCERR_STR)
	parseLine({}, "det true(x, y, z) :- YES.")
end
test()
