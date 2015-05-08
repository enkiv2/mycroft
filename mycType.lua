-- Definitions and helper functions for special types in mycroft

NC={truth=0, confidence=0}
YES={truth=1, confidence=1}
NO={truth=0, confidence=1}

function translateArgList(list, conv, literals) -- given an arglist and a conversion map, produce a new arglist with the order transformed
	local l, i, j
	if(nil==literals) then literals={} end
	l={}
	if(conv==nil) then return l end
	if(conv[1]==nil) then return l end
	if(conv[2]==nil) then return l end
	if(conv[3]==nil) then conv[3]={} end
	for i,j in ipairs(conv[1]) do
		if(i and j) then
			if(conv[2][i]) then l[conv[2][i]]=list[conv[1][i]] end
			if(literals[i]) then l[i]=literals[i] end
		end
	end
	for i,j in ipairs(conv[2]) do
		if(i and j) then
			if(conv[1][i]) then l[conv[2][i]]=list[conv[1][i]] end
			if(conv[3][i]) then l[conv[2][i]]=conv[3][i] end
			if(literals[i]) then l[i]=literals[i] end
		end
	end
	for i,j in ipairs(conv[3]) do
		l[i]=conv[3][i]
	end
	for i,j in ipairs(literals) do
		l[i]=literals[i]
	end
	for i,j in ipairs(l) do
		if(i>#conv[2]) then l[i]=nil end
	end
	debugPrint({"translation of", list, "by", conv, "is", l})
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

function inflatePredID(p)
	local t=nil
	if(type(p)=="table") then return p end
	string.gsub(p, "(%w+)/(%d+)", function(pname, parity) debugPrint("pname: "..pname..", arity: "..parity) t={name=pname, arity=tonumber(parity)} end )
	if(t) then return t end
	return p
end

-- Helper functions for unification support
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

