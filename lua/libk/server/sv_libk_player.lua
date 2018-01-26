--Give player their db id or create entry if they don't have one
function LibK.playerInitialSpawn( ply )
	LibK.Player.findByPlayer( ply )
	:Then( function( dbPlayer )
		if not IsValid( ply ) then
			-- Player disconnected during join, do nothing
			return
		end

		if dbPlayer then
			dbPlayer.name = ply:Nick( ) 
			dbPlayer.steam64 = ply:SteamID64( )
			return dbPlayer:save( )
		else
			local dbPlayer = LibK.Player:new( )
			dbPlayer.name = ply:Nick( )
			dbPlayer.player = ply
			dbPlayer.steam64 = ply:SteamID64( )
			dbPlayer.uid = ply:UniqueID( )
			return dbPlayer:save( )
		end
	end )
	:Then( function( dbPlayer )
		if not IsValid( ply ) then
			-- Player disconnected during join, do nothing
			return
		end

		KLogf( 4, "[LibK] Player %s(id %i)", ply:Nick( ), dbPlayer.id )
		ply.libk_originalNick = ply:Nick( )
		ply.dbPlayer = dbPlayer
		ply.kPlayerId = dbPlayer.id
		ply:SetNWInt( "KPlayerId", dbPlayer.id )
		hook.Call( "LibK_PlayerInitialSpawn", GAMEMODE, ply, dbPlayer )
	end, function( errid, err )
		KLogf( 2, "[LibK] Error initializing player %s(%i: %s )", ply:Nick( ), errid, err )
	end )
end
hook.Add( "PlayerInitialSpawn", "LibKJoinPlayer", LibK.playerInitialSpawn )

function LibK.monitorNameChanges( )
	for k, v in pairs( player.GetAll( ) ) do
		if v:Nick( ) != v.libk_originalNick and v.dbPlayer then
			KLogf( 4, "[LibK] Player %s changed name to %s", v.libk_originalNick, v:Nick( ) )
			v.dbPlayer.name = v:Nick( )
			v.dbPlayer:save( )
			:Fail( function( errid, err )
				KLogf( 3, "[LibK] Error saving rename for %s(%i: %s)", v.libk_originalNick, errid, err )
			end )
			v.libk_originalNick = v:Nick( )
		end
	end
end
hook.Add( "Think", "LibKMonitorNameChange", LibK.monitorNameChanges )
