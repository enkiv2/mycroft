-- internal error reporting system
MYCERR=0
MYCERR_STR=""
MYC_ERR_NOERR=0
MYC_ERR_DETNONDET=1
MYC_ERR_UNDEFWORLD=2
MYC_ERR_USER=3

function construct_traceback(world, p, hash) -- add a line to the traceback
	local ppid, pname
	if(type(p)=="table") then
		ppid=prettyPredID(p)
		pname=p.name
	else
		ppid=p
		pname=p
	end
	if(world.MYCERR_STR==nil or world.MYC_ERR_STR=="") then
		world.MYCERR_STR=error_string(world.MYCERR)
	end
	world.MYCERR_STR=world.MYCERR_STR.." at "..ppid.." "..pname..hash.."\n"
end

function error_string(code) -- convert an error code to an error message
	if(code==MYC_ERR_NOERR) then return "No error." 
	elseif(code==MYC_ERR_DETNONDET) then return "Predicate marked determinate has indeterminate results."
	elseif(code==MYC_ERR_UNDEFWORLD) then return "World undefined -- no predicates found."
	elseif(code==MYC_ERR_USER) then return "User-level exception (details follow)."
	else return "FIXME unknown/undocumented error "..tostring(code).."." end
end

function throw(world, code, pred, hash, msg) -- throw an error, with a position in the code as pred(hash) and an error message
	world.MYCERR=code
	if(tonumber(code)) then world.MYCERR=tonumber(code) end
	construct_traceback(world, serialize(pred), serialize(hash)..": "..serialize(msg))
	print(pretty(world.MYCERR_STR))
end
