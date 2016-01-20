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

function LibK.copyModelFields( destination, source, model )
	for k, v in pairs( source ) do
		if model.fields[k] then
			destination[k] = v
		end
	end	
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
	local diff = timestamp - os.time( )
	if diff < 30 * 24 * 60 * 60 then
		local diffTbl = os.date( "*t", diff )
		
		--need to do this because of epoch start
		diffTbl.day = diffTbl.day - 1
		diffTbl.year = diffTbl.year - 1970
		diffTbl.month = diffTbl.month - 1
		diffTbl.hour = diffTbl.hour - 1

		local str = ""
		if diffTbl.day > 0 then
			str = str .. diffTbl.day .. "  days"
		elseif diffTbl.hour > 0 then 
			str = str .. diffTbl.hour .. " hours"
		elseif diffTbl.min > 0 then 
			str = str .. diffTbl.min .. " minutes"
		elseif diffTbl.sec > 0 then 
			str = str .. diffTbl.sec .. " seconds"
		else
			return "just now"
		end
		return str
	else
		return os.date( "%d.%m. %H:%M", timestamp )
	end
end



local intervals={
  {"seconds", 1}, --the "1" should never really get used but
  {"minutes", 60},
  {"hours", 60},
  {"days", 24},
  {"weeks", 7}
}

-- From http://lua-users.org/wiki/UnitConversion
local positions={}
for i=1,5 do
  positions[intervals[i][1]]=i
end

function LibK.ConvertTimeUnits(value, sourceunits, targetunits)

  local sourcei, targeti = positions[sourceunits], positions[targetunits]
  assert(sourcei and targeti)

  if sourcei<targeti then

    local base=1
    for i=sourcei+1,targeti do
      base=base*intervals[i][2]
    end

    return value/base

  elseif sourcei>targeti then

    local base=1
    for i=targeti+1,sourcei do
      base=base*intervals[i][2]
    end

    return value*base

  else return value end
end

LibK.TimeUnitMap = {
	seconds = 1,
	minutes = 60,
	hours = 60 * 60,
	days = 60 * 60 * 24,
	weeks = 60 * 60 * 24 * 7
}

function LibK.getDurationInfo( durationInSeconds )
	local seconds = durationInSeconds
	if seconds < 60 then
		if math.floor( seconds ) != 1 then
			return seconds, "seconds", "seconds"
		else
			return seconds, "seconds", "second"
		end
	end
	
	local minutes = LibK.ConvertTimeUnits(durationInSeconds,"seconds","minutes")
	if minutes < 60 then
		if math.floor( minutes ) != 1 then
			return minutes, "minutes", "minutes"
		else
			return minutes, "minutes", "minute"
		end
	end
	
	local hours = LibK.ConvertTimeUnits(durationInSeconds,"seconds","hours")
	if hours < 24 then
		if math.floor( hours ) != 1 then
			return hours, "hours", "hours"
		else
			return hours, "hours", "hour"
		end
	end
	
	local days = LibK.ConvertTimeUnits(durationInSeconds,"seconds","days")
	if days < 7 then
		if math.floor( days ) != 1 then
			return days, "days", "days"
		else
			return days, "days", "day"
		end
	end
	
	local weeks = LibK.ConvertTimeUnits(durationInSeconds,"seconds","weeks")
	if math.floor( weeks ) != 1 then
		return weeks, "weeks", "weeks"
	else
		return weeks, "weeks", "week"
	end
end

--
function LibK.getDurationInfo2( seconds )
	local result = {}
	
	repeat
		local amount, unit, str = LibK.getDurationInfo( seconds )
		seconds = seconds - math.floor( amount ) * LibK.TimeUnitMap[unit]
		table.insert( result, { amount = math.floor( amount ), unit = unit, string = str } )
	until seconds <= 0
	
	return result
end

function LibK.formatDuration( seconds, short, limit )
	local durationInfo = LibK.getDurationInfo2( seconds )
	limit = limit or #durationInfo 
	
	local str = ""
	for k, v in ipairs( durationInfo ) do
		if k > limit then
			break
		end
		
		str = str .. v.amount .. ( short and v.string[1] or " " .. v.string )
		if k < limit then
			str = str .. " "
		end
	end
	return str
end

function LibK.getSmallestUnitToRepresent( seconds )
	local durationInfo = LibK.getDurationInfo2( seconds )
	return durationInfo[#durationInfo].unit
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

function LibK.consoleHeader( width, fillSymbol, text )
	local spaceToFill = width - #text
	spaceToFill = spaceToFill > 0 and spaceToFill or 0

	local filler = string.rep( fillSymbol, math.floor( ( spaceToFill - 2 ) / 2 ) )
	
	local result = filler
	if spaceToFill % 2 != 0 then
		result = result .. " " .. text .. "  "
	else
		result = result .. " " .. text .. " "
	end
	result = result .. filler
	
	return result
end

--Split table tbl into segments of size num
function LibK.splitTable( tbl, num )
	local seps = math.ceil(#tbl / num)
	local ret = {}
	for i = 0, seps - 1 do
		ret[i + 1] = {}
		for k = i * num + 1, math.min(i * num + num, #tbl) do
			table.insert(ret[i + 1], tbl[k])
		end
	end
	return ret
end

function LibK.isnan( x ) 
	return x ~= x 
end

function LibK.isinf( x )
	return x == math.huge 
end

function LibK.isProperNumber( x )
	x = tonumber( x )
	return x and not LibK.isnan( x ) and not LibK.isinf( x )
end

-- @FGRibreau - Francois-Guillaume Ribreau
-- @Redsmin - A full-feature client for Redis http://redsmin.com
function table.filter(t, filterIter)
  local out = {}

  for k, v in pairs(t) do
    if filterIter(v, k, t) then out[k] = v end
  end

  return out
end