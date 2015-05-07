
NC={truth=0, confidence=0}
YES={truth=1, confidence=1}
NO={truth=0, confidence=1}

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

