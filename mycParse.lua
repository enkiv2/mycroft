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
