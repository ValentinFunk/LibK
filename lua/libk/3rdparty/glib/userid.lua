local singleplayerId = nil

function GLib.GetEveryoneId ()
	return "Everyone"
end

if SERVER then
	function GLib.GetLocalId ()
		return "Server"
	end
elseif CLIENT then
	function GLib.GetLocalId ()
		if not LocalPlayer or not LocalPlayer ().SteamID then
			return "STEAM_0:0:0"
		end
		return LocalPlayer ():SteamID ()
	end
end

function GLib.GetPlayerId (ply)
	if not ply then return nil end
	if not ply:IsValid () then return nil end
	if type (ply.SteamID) ~= "function" then return nil end
	
	local steamId = ply:SteamID ()
	
	if SERVER and game.SinglePlayer () and ply == ents.GetByIndex (1) then
		steamId = singleplayerId
	end
	
	if steamId == "NULL" then
		steamId = "BOT"
	end
	
	return steamId
end

function GLib.GetServerId ()
	return "Server"
end

function GLib.GetSystemId ()
	return "System"
end

if game.SinglePlayer () then
	if SERVER then
		concommand.Add ("glib_singleplayerid",
			function (_, _, args)
				singleplayerId = args [1]
			end
		)
		
		umsg.Start ("glib_request_singleplayerid")
		umsg.End ()
	elseif CLIENT then
		local function sendSinglePlayerId ()
			GLib.WaitForLocalPlayer (
				function ()
					RunConsoleCommand ("glib_singleplayerid", GLib.GetLocalId ())
				end
			)
		end
		
		usermessage.Hook ("glib_request_singleplayerid", sendSinglePlayerId)
		sendSinglePlayerId ()
	end
end