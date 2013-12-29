function generateNetTable( tbl )
	local netTbl = {}
	if isObject( tbl ) then
		netTbl._classname = tbl.class.name
	end
	for k, v in pairs( tbl ) do
		if isObject( tbl ) and k == "class" then
			continue
		end
		if isObject( v ) then
			netTbl[k] = generateNetTable( v )
		elseif istable( v ) then
			netTbl[k] = generateNetTable( v )
		else
			netTbl[k] = v
		end
	end
	return netTbl
end

function stripClassInfo( tbl )
	local netTbl = {}
	if isObject( tbl ) then
		netTbl._classname = tbl.class.name
	end
	for k, v in pairs( tbl ) do
		if isObject( tbl ) and k == "class" then
			continue
		end
		if isObject( v ) then
			netTbl[k] = stripClassInfo( v )
		elseif istable( v ) then
			netTbl[k] = stripClassInfo( v )
		else
			netTbl[k] = v
		end
	end
	return netTbl
end

--Strip all class information and fields, leaving the table with extra stuff on it only
function generateCleanTable( tbl, model, notfirstpass )
	if not notfirstpass then
		tbl = generateNetTable( tbl )
	end
	for k, v in pairs( tbl ) do
		if k == "_classname" then
			tbl[k] = nil
		elseif not notfirstpass and model.fields[k] != nil then --On recursion level 1, remove model fields
			tbl[k] = nil
		elseif istable( v ) then
			tbl[k] = generateCleanTable( v, model, true )
		end
	end	
	return tbl
end

--Debugging/Tracing for when gmod crashes

function sethk( )
	debug.sethook( function(what, arg)
		if(what == "call") then
			local data = debug.getinfo(1)
			log("Calling function:")
			log("\tNameWhat: " .. data.namewhat)
			log("\tWhat: " .. data.what)
			log("\tshort_src: " .. data.short_src)
			log("\tlinedefined: " .. data.linedefined)
			log("\tlastlinedefined: " .. data.lastlinedefined)
			log("\tsource: " .. data.source)
		elseif what == "line" then
			log("Entering line: " .. arg)
		elseif what == "return" then
			log("Returning")
		elseif what == "tailcall" then
			log("Tailcall")
		end
	end, "crl" )
end

function LibK.timeDiffString( timestamp )
	local diff = os.time( ) - timestamp
	if diff < 24 * 60 * 60 then
		local diffTbl = os.date( "*t", diff )
		
		--need to do this because of epoch start
		diffTbl.day = diffTbl.day - 1
		diffTbl.year = diffTbl.year - 1970
		diffTbl.month = diffTbl.month - 1
		diffTbl.hour = diffTbl.hour - 1

		local str = ""
		if diffTbl.day > 0 then
			str = str .. diffTbl.day .. "days"
		elseif diffTbl.hour > 0 then 
			str = str .. diffTbl.hour .. "h"
		elseif diffTbl.min > 0 then 
			str = str .. diffTbl.min .. "m"
		elseif diffTbl.sec > 0 then 
			str = str .. diffTbl.sec .. "s"
		else
			return "just now"
		end
		return str .. " ago"
	else
		return os.date( "%d.%m. %H:%M", timestamp )
	end
end

--Debug prints you can find when you forget them somewhere
function dp( ... )
	local dbginfo = debug.getinfo(2)
	dbginfo.name = dbginfo.name or "Unknown Function"
	print( dbginfo.name .. ":", ... )
end

function dpt( tbl )
	local dbginfo = debug.getinfo(2)
	dbginfo.name = dbginfo.name or "Unknown Function"
	print( "Printing Table from " .. dbginfo.name .. " at " .. dbginfo.short_src .. ":" .. dbginfo.currentline .. " :" )
	PrintTable( tbl )
end