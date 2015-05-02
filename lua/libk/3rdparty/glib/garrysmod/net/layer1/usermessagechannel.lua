local self = {}
GLib.Net.Layer1.UsermessageChannel = GLib.MakeConstructor (self, GLib.Net.Layer1.Channel)

local function PlayerFromUserId (userId)
	if type (userId) == "table" then
		-- Assume it's a SubscriberSet
		return userId:GetRecipientFilter ()
	end
	
	if CLIENT and userId == GLib.GetServerId () then return nil end
	if userId == GLib.GetEveryoneId () then
		local recipientFilter = RecipientFilter ()
		recipientFilter:AddAllPlayers ()
		return recipientFilter
	end
	
	local ply = GLib.PlayerMonitor:GetUserEntity (userId)
	if not ply then return nil end
	
	return ply
end

function self:ctor (channelName, handler)
	self.Open = false
	
	if SERVER then	
		self:SetOpen (true)
		util.AddNetworkString (self:GetName ())
	else
		usermessage.Hook (self:GetName (),
			function (umsg)
				self:GetHandler () (GLib.GetServerId (), GLib.Net.Layer1.UsermessageInBuffer (umsg))
			end
		)
	end
end

-- Packets
function self:DispatchPacket (destinationId, packet)
	if not self:IsOpen () then
		GLib.Error ("UsermessageChannel:DispatchPacket : Channel isn't open! (" .. tostring (destinationId) .. "." .. self:GetName () .. ")")
	end
	if packet:GetSize () > self:GetMTU () then
		GLib.Error ("UsermessageChannel:DispatchPacket : Packet for " .. tostring (destinationId) .. "." .. self:GetName () .. " exceeds MTU (" .. (packet:GetSize ()) .. ")!")
	end
	
	destinationId = PlayerFromUserId (destinationId)
	if not destinationId then return end -- Drop packet
	
	GLib.Net.Layer1.UsermessageDispatcher:Dispatch (destinationId, self:GetName (), packet)
end

function self:GetMTU ()
	if CLIENT then return -1 end
	
	return 256 - #self:GetName () - 2
end

function self:IsDestinationRoutable (destinationId)
	if destinationId == GLib.GetEveryoneId () then return true end
	
	if CLIENT then return destinationId == GLib.GetServerId () end
	if SERVER then return GLib.PlayerMonitor:GetUserEntity (destinationId) ~= nil end
	
	return false
end