-- Parsing functions (WIP)

--definition semantics (WIP)
function parseAnd(world, line) -- parse and handle the AND portion of a fact in definition semantics
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

function parseOr(world, line) -- parse and handle the OR portion of a fact in definition semantics
	local t
	t={}
	string.gsub(line, "([^;]+)", function (l) table.insert(t, parseAnd(world, l)) return "" end )
	return t
end

function genCorrespondences(x, y) -- given a pair of arg lists, produce correspondences between them
	local ret, i, j, k, l
	ret={{}, {}, {}}
	local max=#x
	if(#y>max) then max=#y end
	for i=1,max do
		if(i<=#x) then ret[1][i]=i end
		if(i<=#y) then ret[2][i]=i end
		ret[3][i]=nil
	end
	for i,j in ipairs(y) do
		local matched=false
		for k,l in ipairs(x) do
			if(j==l) then 
				matched=true
				debugPrint({"x[",i,"]=",j,"<==>",l,"=y[",k,"]"})
				debugPrint({"ret[1][",i,"]=",k})
				debugPrint({"ret[2][",k,"]=",i})
				if(k<=#y) then ret[1][i]=k end
				if(i<=#x) then ret[2][k]=i end
				debugPrint({"ret", ret}) 
				debugPrint({"ret[1]", ret[1]}) 
				debugPrint({"ret[2]", ret[2]}) 
				debugPrint({"ret[3]", ret[3]}) 
			end
		end
		if(not matched) then
			ret[3][i]=j
		end
	end
	debugPrint({"correspondences between", x, "and", y, "determined to be", ret})
	return ret
end


function parsePred(world, det, pname, pargs, pdef) -- parse a predicate definition (definition semantics)
	local args, pred, pdeps, isDet
	if(det~="det" and det~="nondet") then 
		print ("Parse error: neither det nor nondet!\n >>"..det.."<< "..pname..pargs.." :- "..pdef..".")
		os.exit(1)
	end
	if(det=="det") then isDet=true else isDet=false end
	args=parseArgs(world, pargs)
	pred=createPredID(pname, #args)
	local orTBL={}
	string.gsub(pdef, "([^;]+)", 
		function(orComponent) return parseOrComponent(world, orComponent, orTBL, true, args, pname, isDet) end)
	orTBL=evertPredTbl(orTBL, world)
	local head=createDef(world, pred, orTBL.preds, orTBL.convs, "or", isDet)
	return ""
end

function parseBodyComponents(world, body, defSem, argList) 
	local items={}
	debugPrint("parseBodyComponents defSem="..tostring(defSem).." body="..body)
	string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(body, " *(%w+) *(%b()) *", 
		function (pname, pargs) 
			if(defSem) then
				debugPrint("defining against "..pname..pargs)
				local parsedArgs=parseArgs(world, pargs, defSem, argList)
				table.insert(items, {pred=createPredID(pname, #parsedArgs), conv=genCorrespondences(argList, parsedArgs)})
			else
				table.insert(items, executePredicateNA(world, pname, parseArgs(world, pargs, defSem, argList)))
			end
			return ""
		end), "(%b<>)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			table.insert(items, x)
		end), "(%b<|)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			table.insert(items, x)
		end), "(%b|>)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			table.insert(items, x)
		end), "([^,]+)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			table.insert(items, x)
		end)
	return items
end


-- Interpreter semantics
function parseTruth(x, defSem, argList) -- handle the various representations of composite truth values
	local tr
	string.gsub(string.gsub(string.gsub(string.gsub(x, 
		" *< *(%d*%.?%d+) *[,"..string.char(127).."] *(%d*%.?%d+) *> *", function (t, c) 
			tr={truth=tonumber(t), confidence=tonumber(c)} 
			return "" 
		end ),
		" *< *(%d*%.?%d+) *| *", function(t) 
			tr={truth=tonumber(t), confidence=1} 
			return "" 
		end),
		" *| *(%d*%.?%d+) *> *", function(c) 
			tr={truth=1, confidence=tonumber(t)} 
			return "" 
		end ),
		" *(%w+) *", function (c)
			if (c=="YES") then tr={truth=1, confidence=1} 
			elseif (c=="NO") then tr={truth=0, confidence=1} 
			elseif (c=="NC") then tr={truth=0, confidence=0} 
			else return c end 
			return "" 
		end)
	if(nil==tr) then return x end
	return tr
end

function escapeStrings(world, pargs)
	local ret=string.gsub(pargs, "^%(", "")
	ret=string.gsub(ret, "%)$", "")
	ret=string.gsub(ret, "%b\"\"", 
		function(c) 
			local ret2=string.gsub(c, ",", string.char(127))
			ret2=string.gsub(ret2,"%(", string.char(128))
			ret2=string.gsub(ret2, "%)", string.char(129))
			ret2=string.gsub(ret2, "<", string.char(130))
			ret2=string.gsub(ret2, ">", string.char(131))
			return string.gsub(ret2, "(%w+)", function(q) 
				if("YES"==q) then 
					return "\\Y\\E\\S" 
				elseif("NO"==q) then 
					return "\\N\\O" 
				elseif("NC"==q) then 
					return "\\N\\C" 
				else 
					return q 
				end 
			end) 
		end )
	ret=string.gsub(ret, "%b<>", function(c) return string.gsub(c, ",", string.char(127)) end )
	return ret
end
function parseArgs(world, pargs, defSem, argList) -- parse all sorts of lists
	local args
	if(nil==pargs) then return {} end
	args={}
	debugPrint(pargs)
	pargs=string.gsub(
			string.gsub(
				string.gsub(escapeStrings(world, pargs)," *(%w+) *(%b()) *", function(pname, pargs) 
					debugPrint("embedded call: "..pname..pargs) 
					local x=parsePredCall(world, pname, pargs, defSem, argList) 
					if(defSem) then
						return({pred=x[1], conv=genCorrespondences(argList, x[1])})
					else
						return serialize(executePredicatePA(world, x[1], x[2])) 
					end
				end), 
				" *([^,]+) *", function (c) 
					table.insert(args, parseItem(world, c, defSem, argList)) 
			end ), 
		string.char(127), ",")

	for i,j in ipairs(args) do if(type(args)=="string") then args[i]=string.gsub(j, string.char(127), ",") end end
	debugPrint("ARGS: "..serialize(args))
	return args
end

function parseStr(i, defSem, argList) -- handle parsing strings
	if(type(i)=="table") then return i end
	local ret=string.gsub(i, "%b\"\"", function (c) return string.gsub(string.gsub(c, "^\"", ""), "\"$", "") end )
	return ret
end

function parseItem(world, i, defSem, argList) -- parse list items into whatever they're supposed to be
	local ret
	if(not defSem) then
		ret=unificationGetItem(world, parseTruth(i))
	else
		ret=parseTruth(i, defSem, argList)
	end
	ret=parseStr(ret, defsem, argList)
	return ret
end

function parsePredCall(world, pname, pargs, defSem, argList) 
	local args
	debugPrint("Predicate name: "..serialize(pname))
	args=parseArgs(world, pargs, defSem, argList)
	return {createPredID(pname, #args), args}
end

function parseAndComponent(world, andComponent, andTBL, defSem, arglist) -- Parse and handle the AND component of a predicate, interpreter semantics
	for i,v in ipairs(parseBodyComponents(world, andComponent, defSem, arglist)) do
		table.insert(andTBL, v)
	end
	return ""
end

function evertPredTbl(t, world)
	local ret={}
	ret.preds={}
	ret.convs={}
	local i, item
	debugPrint("table to be everted: "..serialize(t))
	for _,i in ipairs(t) do
		if(i.pred) then table.insert(ret.preds, i.pred) end
		if(i.conv) then table.insert(ret.convs, i.conv) end
		if(i.preds) then for _,item in i.preds do table.insert(ret.preds, item) end end
		if(i.convs) then for _,item in i.convs do table.insert(ret.convs, item) end end
		if(not (i.pred or i.conv or i.preds or i.convs)) then 
			local tmp=inflatePredID(i)
			if(tmp.name~=nil and tmp.arity~=nil) then
				table.insert(ret.preds, tmp)
				local tmp3={}
				for item=1,tmp.arity do
					table.insert(tmp3, item)
				end
				table.insert(ret.convs, genCorrespondences(tmp3, tmp3))
			else
				debugPrint({"Non-pred value: ", i})
				local tr=NC
				if(i.truth~=nil and i.confidence~=nil) then
					tr=i
				end
				table.insert(ret.preds, createAnonFact(world, 0, "()", tr))
				table.insert(ret.convs, genCorrespondences({}, {}))
			end
		end
	end
	return ret
end

function parseOrComponent(world, orComponent, orTBL, defSem, arglist, pred, det) -- Parse and handle the OR component of a predicate, interpreter semantics
	local andTBL={}
	string.gsub(string.gsub(string.gsub(
		string.gsub(orComponent, "(.*)%) *,", 
			function(andComponent) return parseAndComponent(world, andComponent..")", andTBL, defSem, arglist) end
			), " *(%w+) *(%b()) *", function(pfx,sfx) return parseAndComponent(world, pfx..sfx, andTBL, defSem, arglist) end
			), " *([<|][0-9., ]+[>|]) *", function(andComponent) return parseAndComponent(world, andComponent, andTBL, defSem, arglist) end
		),  "([^,]+),?",
			function(andComponent) return parseAndComponent(world, andComponent, andTBL, defSem, arglist) end)
	local head=NO
	debugPrint("parseOrComponent")
	if(#andTBL>0) then
		if(defSem) then
			local predTbl=evertPredTbl(andTBL, world)
			debugPrint({"Everted pred tbl: ", predTbl})
			head=createAnonDef(world, #arglist, predTbl.preds, predTbl.convs, "and", det)
		else
			head=andTBL[1]
			table.remove(andTBL, 1)
			for i,v in ipairs(andTBL) do
				head=performPLBoolean(head, v, "and")
			end
		end
	end
	table.insert(orTBL, head)
	return ""
end



function parseLine(world, line) -- Hand a line off to the interpreter
	clearSymbolSpace(world)
	debugPrint("LINE: "..tostring(line))
	if(nil==line) then return line end
	if(""==line) then return line end
	if("#"==line[0]) then return "" end
	return serialize(string.gsub(
		string.gsub(line, "^(%l%w+)  *(%l%w+) *(%b()) *:%- *([^.]+). *$", 
			function (det, pname, pargs, pdef) 
				debugPrint("fact: "..pname..pargs..":-"..pdef)
				mycnet.forwardFact(world, line)
				return serialize(parsePred(world, det, pname, pargs, pdef))
			end),
		"^%?%- *(.+) *%.$", 
		function (body)
			debugPrint("query: "..body) 
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
