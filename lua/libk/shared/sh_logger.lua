function KLog( intLogLevel, strMessage, ... )
	/*
	1: Error
	2: Warning
	3: Important messages
	4: Debug messages
	*/
	if LibK.Debug then
		local colors = {
			Color( 255, 0, 0 ),
			Color( 255, 175, 0 ),
			Color( 255, 255, 0 ),
			Color( 150, 150, 150 ),
		}
		if SERVER then
			MsgN( strMessage )
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
				MsgC( Color( 255, 0, 0 ), strMessage )
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
	KLog( intLogLevel, string.format( strMessage, unpack( args ) ) )
end