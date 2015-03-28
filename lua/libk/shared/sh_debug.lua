LibK.reloadInitFiles = {
	"autorun/_libk_loader.lua",
}

function LibK.addReloadFile( file )
	if not table.HasValue( LibK.reloadInitFiles, file ) then
		table.insert( LibK.reloadInitFiles, file )
	end	
end


local function reloadLibKAddons( )
	for k, file in pairs( LibK.reloadInitFiles ) do
		local func = CompileFile( file )
		if func then
			func( )
		else
			KLogf( 3, "[WARN] Couldn't reload file %s", file )
		end
	end
end


if SERVER then
	util.AddNetworkString( "KRELOAD" )
	concommand.Add( "libk_reload", function( ply, cmd, args )
		if not LibK.Debug or ( ply:IsValid( ) and not ply:IsAdmin( ) ) then
			return
		end
		reloadLibKAddons( )
		net.Start( "KRELOAD" )
		net.Send( ply )
		timer.Simple( 1, function( )
			--Delayed, give the client a chance to reload first
			hook.Call( "OnReloaded", GAMEMODE )
		end )
	end )
end

if CLIENT then
	net.Receive( "KRELOAD", function( )
		reloadLibKAddons( )
		hook.Call( "OnReloaded", GAMEMODE )
	end )
end