function KLog( intLogLevel, strMessage, ... )
	/*
	1: Error
	2: Warning
	3: Important messages
	4: Debug messages
	*/
	if LibK.Debug or intLogLevel <= 2 then
		local colors = {
			Color( 255, 0, 0 ),
			Color( 255, 175, 0 ),
			Color( 255, 255, 0 ),
			Color( 150, 150, 150 ),
		}
		if SERVER then
			--Server can only do red:
			if intLogLevel <= 3 then
				MsgC( colors[1], strMessage .. "\n" )
			else
				MsgN( strMessage )
			end
		else
			MsgC( colors[intLogLevel], strMessage .. "\n" )
		end
	end
	if( intLogLevel <= LibK.LogLevel ) then
		if SERVER then
			strMessage = strMessage .. table.concat( {...} , ", " )
			if LibK.Debug then
				file.Append( "LibK_Debug.txt", os.date() .. " - " .. strMessage .. "\n" )
			end
			if intLogLevel <= 3 then
				file.Append( "LibK_Error.txt", os.date() .. " - " .. strMessage .. "\n" )
			end
		end
	end
end

function KLogf( intLogLevel, strMessage, ... )
	local args = { ... }
	--If function is called without a number, assume debug
	if type( intLogLevel ) == "string" then
		table.insert( args, 1, strMessage )
		strMessage = intLogLevel
		intLogLevel = 4
	end
	local result, msg = pcall( string.format, strMessage, unpack( args ) )
	if result then
		KLog( intLogLevel, msg )
	else
		error( msg, 2 )
	end
end