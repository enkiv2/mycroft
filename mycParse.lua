-- Parsing functions (WIP)
lastChunkSize={}
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
			if(j==l and j~=nil and l~=nil) then 
				matched=true
				if(k<=#y) then ret[1][i]=k end
				if(i<=#x) then ret[2][k]=i end
			end
		end
		if(not matched) then
			ret[3][i]=j
		end
	end
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
	orTBL=evertPredTbl(orTBL, world, true)
	local head=createDef(world, pred, orTBL.preds, orTBL.convs, "or", isDet)
	return ""
end

function parseBodyComponents(world, body, defSem, argList, offset) 
	local items={}
	local leftOff
	table.insert(lastChunkSize,#body)
	if(string.find(body, "^ *$")~=nil) then return "" end
	body=string.gsub(body, "(%b\"\")", function(c)
			return escapeStrings(world, c)
		end)
	leftOff=1
	body=string.gsub(body, "!", 
		function(c) 
			leftOff=string.find(body, c)
			table.insert(items,leftOff+offset,"!")
			return string.rep(" ", #c)
		end)
	leftOff=1
	body=string.gsub(body, "(%w+)( *)(%b())", function (pname, spc, pargs) 
			leftOff=string.find(body, pname.." *%b()", leftOff)
			local pos=leftOff+offset
			while(items[pos]) do
				pos=pos+1
			end
			if(defSem) then
				local parsedArgs=parseArgs(world, pargs, defSem, argList)
				table.insert(items,pos,{pred=createPredID(pname, #parsedArgs), conv=genCorrespondences(argList, parsedArgs)})
			else
				table.insert(items,pos,function() return executePredicateNA(world, pname, parseArgs(world, pargs, defSem, argList)) end)
			end
			return string.rep(" ", #body)
		end)
	leftOff=1
	body=string.gsub(body, "(%b<>)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			leftOff=string.find(body, c)
			local pos=leftOff+offset
			while(items[pos]) do
				pos=pos+1
			end
			table.insert(items,pos,x)
			return string.rep(" ", #c)
		end)
	leftOff=1
	body=string.gsub(body, "(%b<|)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			leftOff=string.find(body, c)
			local pos=leftOff+offset
			while(items[pos]) do
				pos=pos+1
			end
			table.insert(items,pos,x)
			return string.rep(" ", #c)
		end)
	leftOff=1
	body=string.gsub(body, "(%b|>)", function(c) 
			local x=parseItem(world, c, defSem, argList) 
			leftOff=string.find(body, c)
			local pos=leftOff+offset
			while(items[pos]) do
				pos=pos+1
			end
			table.insert(items,pos,x)
			return string.rep(" ", #c)
		end)
	leftOff=1
	body=string.gsub(body, "( *)([^, ]+)( *)", function(a, c, b) 
			local x=parseItem(world, c, defSem, argList) 
			leftOff=string.find(body, c)
			local pos=leftOff+offset
			while(items[pos]) do
				pos=pos+1
			end
			table.insert(items, pos, x)
			return string.rep(" ", #c+#a+#b)
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
			ret2=string.gsub(ret2, "!", string.char(132))
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
	args=parseArgs(world, pargs, defSem, argList)
	return {createPredID(pname, #args), args}
end

function parseAndComponent(world, andComponent, andTBL, defSem, arglist, offset) -- Parse and handle the AND component of a predicate, interpreter semantics
	for i,v in pairs(parseBodyComponents(world, andComponent, defSem, arglist, offset)) do
		if(type(v)=="string") then
			if(string.find(v, "^ *$")==nil) then 
				v=string.gsub(string.gsub(v, "^ +", ""), " +$", "")
				if("!"==v) then debugPrint("found cut") table.insert(andTBL, offset+i,  v) return "" end
			end
		end
		table.insert(andTBL, offset+i, v)
	end
	local ret=string.rep(" ", lastChunkSize[1])
	return ret
end

function evertPredTbl(t, world, defSem)
	local ret={}
	ret.preds={}
	ret.convs={}
	local i, item
	local j,k
	local keys={}
	for j,_ in pairs(t) do
		table.insert(keys, j)
	end
	table.sort(keys)
	for _,j in ipairs(keys) do
		i=t[j]
		if(type(i)=="function") then
			i=i()
		end
		if(type(i)=="string") then
			if("!"==i) then 
				table.insert(ret, "!")
				return ret
			end
		end
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
				local tr=NC
				if(i.truth~=nil and i.confidence~=nil) then
					tr=i
				end
				if(detSem) then 
					if(cmpTruth(tr, YES)) then
						table.insert(ret.preds, createPredID("true", 0))
						table.insert(ret.convs, genCorrespondences({}, {}))
					elseif(cmpTruth(tr, NO)) then
						table.insert(ret.preds, createPredID("false", 0))
						table.insert(ret.convs, genCorrespondences({}, {}))
					elseif(cmpTruth(tr, NC)) then
						table.insert(ret.preds, createPredID("nc", 0))
						table.insert(ret.convs, genCorrespondences({}, {}))
					else
						table.insert(ret.preds, createAnonFact(world, 0, "()", tr))
						table.insert(ret.convs, genCorrespondences({}, {}))
					end
				else
					table.insert(ret, tr)
				end
			end
		end
	end
	return ret
end

function parseOrComponent(world, orComponent, orTBL, defSem, arglist, pred, det) -- Parse and handle the OR component of a predicate, interpreter semantics
	local andTBL={}
	local offFix=#orComponent
	orComponent=string.gsub(orComponent, "(.*)%)( *),", 
			function(andComponent, x) 
				local offset=string.find(orComponent, "(.*)%) *,")
				parseAndComponent(world, andComponent..")", andTBL, defSem, arglist, offset)
				return string.rep(" ", #andComponent+#x)
			end)
	if(#orComponent<offFix) then
		orComponent=string.rep(" ", (offFix-#orComponent))..orComponent
	end
	orComponent=string.gsub(orComponent, "(%w+ *%b())", 
			function(c) 
				local offset=string.find(orComponent, "(%w+) *%b()")
				parseAndComponent(world, c, andTBL, defSem, arglist, offset)
				return string.rep(" ", #c)
			end)
	if(#orComponent<offFix) then
		orComponent=string.rep(" ", (offFix-#orComponent))..orComponent
	end
	orComponent=string.gsub(orComponent, "([<|][0-9., ]+[>|])", 
			function(andComponent) 
				local offset=string.find(orComponent, "[<|][0-9., ]+[>|]") 
				parseAndComponent(world, andComponent, andTBL, defSem, arglist, offset) 
				return string.rep(" ", #andComponent)
			end)
	if(#orComponent<offFix) then
		orComponent=string.rep(" ", (offFix-#orComponent))..orComponent
	end
	orComponent=string.gsub(orComponent,  "([^,]+),?",
			function(andComponent) 
				if(string.find(andComponent, "^ *$")==nil and #andComponent>0) then 
					local offset=string.find(orComponent, "([^,]+),?")
					parseAndComponent(world, andComponent, andTBL, defSem, arglist, offset) 
					return string.rep(" ", #andComponent)
				end
				return andComponent
			end)
	local head=NO
	andTBL=evertPredTbl(andTBL, world, defSem)
	local count=0
	for _,_ in pairs(andTBL) do
		count=count+1
	end
	debugPrint({"andTBL", andTBL})
	if(count>0) then
		if(defSem) then
			local predTbl=andTBL
			head=createAnonDef(world, #arglist, predTbl.preds, predTbl.convs, "and", det)
		else
			head=andTBL[1]
			table.remove(andTBL, 1)
			for i,v in pairs(andTBL) do
				if("!"==v) then debugPrint("found cut") table.insert(orTBL, head) table.insert(orTBL, "!") return "" end
				if(i~="preds" and i~="convs") then
					head=performPLBoolean(head, v, "and")
				end
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
	local rets=serialize(string.gsub(
		string.gsub(line, "^(%l%w+)  *(%l%w+) *(%b()) *:%- *(.+). *$", 
			function (det, pname, pargs, pdef) 
				debugPrint("fact: "..pname..pargs..":-"..pdef)
				pcall(mycnet.forwardFact, world, line)
				return serialize(parsePred(world, det, pname, pargs, pdef))
			end),
		"^%?%- *(.+) *%.$", 
		function (body)
			debugPrint("query: "..body) 
			local orTBL={}
			string.gsub(body, "([^;]+)", 
				function(orComponent) return parseOrComponent(world, orComponent, orTBL, false, {}) end)
			local head=NC
			local count=0
			for _,_ in pairs(orTBL) do
				count=count+1
			end
			debugPrint({"orTBL", orTBL})
			if(count>0) then
				head=orTBL[1]
				table.remove(orTBL,1)
			end
			debugPrint({"count", count, "head", head})
			for i,v in pairs(orTBL) do
				debugPrint({"v", v, "head", head})
				if("!"==v) then
					local oldhead=head
					if(not cmpTruth(head, NO)) then
						if(not cmpTruth(head, NC)) then
							return serialize(head)
						end
					end
					head=orTBL[i+1]
					if(not head) then head=oldhead return serialize(oldhead)  end
				else
					head=performPLBoolean(head,v,"or")
				end
			end 
			return serialize(head)
		end
	))
	pcall(coroutine.yield)
	return rets
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
function parseLines(world, str)
	local l
	for _,l in ipairs(string.split(str, "[\r\n]")) do
		parseLine(world, l)
	end
end
