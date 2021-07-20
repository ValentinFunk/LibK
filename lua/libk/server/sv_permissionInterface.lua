--TODO: Evolve
function PermissionInterface.banPlayer( ply, time, reason, admin )
	if exsto then
	elseif ulx then
		ulx.ban( admin, ply, time, reason )
	elseif sam then
		sam.player.ban( ply, time, reason, IsValid(admin) and admin:SteamID() )
	end
end

function PermissionInterface.banId( steam, time, reason, admin )
	if exsto then
	elseif ulx then
		ulx.banid( admin, steam, time, reason )
	elseif sam then
		sam.player.ban_id( ply, time, reason, IsValid(admin) and admin:SteamID() )
	end
end


function PermissionInterface.kickPlayer( ply, reason, admin )
	if exsto then
		exsto.RunCommand( admin, "kick", { reason, ply:SteamID( ) } )
	elseif ulx then
		ulx.kick( admin, ply, reason )
	else
		ply:Kick(reason)
	end
end

function PermissionInterface.slayPlayer( ply, admin )
	if ulx then
		ulx.slay( admin, { ply } )
	elseif sam then
		RunConsoleCommand( "sam", "slay", "#" .. ply:EntIndex() )
	end
end

function PermissionInterface.slayPlayerNr( ply, rounds, reason, admin )
	markPlayerForSlay( ply, rounds, reason, admin ) --Urg
end

function PermissionInterface.printIfPermission( permission, fmtstring, ... )
	local message = string.format( fmtstring, ... )
	for k, v in pairs( player.GetAll( ) ) do
		if PermissionInterface.query( permission, v ) then
			v:PrintMessage( HUD_PRINTTALK, message )
		end
	end
end