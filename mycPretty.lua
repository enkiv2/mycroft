
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

