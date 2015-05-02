local self = {}
GLib.Net.Layer2.ChannelStateNetworker = GLib.MakeConstructor (self)

function self:ctor ()
	self.ChannelOpenChannel = GLib.Net.Layer2.Channel ("glib_channel_open",
		function (sourceId, inBuffer)
			if sourceId ~= GLib.GetServerId () then return end
			
			local channelName = inBuffer:String ()
			local channel = GLib.Net.Layer2.Channels [channelName] or GLib.Net.Layer2.Channel (channelName)
			channel:SetOpen (true)
		end
	)
	
	self.ChannelsOpenChannel = GLib.Net.Layer2.Channel ("glib_channels_open",
		function (sourceId, inBuffer)
			if sourceId ~= GLib.GetServerId () then return end
			
			local channelName = inBuffer:String ()
			while channelName ~= "" do
				local channel = GLib.Net.Layer2.Channels [channelName] or GLib.Net.Layer2.Channel (channelName)
				channel:SetOpen (true)
				
				channelName = inBuffer:String ()
			end
		end
	)

	self.ChannelClosedChannel = GLib.Net.Layer2.Channel ("glib_channel_closed",
		function (sourceId, inBuffer)
			if sourceId ~= GLib.GetServerId () then return end
			
			local channelName = inBuffer:String ()
			local channel = GLib.Net.Layer2.Channels [channelName]
			if channel then
				channel:SetOpen (false)
			end
		end
	)

	self.ChannelsClosedChannel = GLib.Net.Layer2.Channel ("glib_channels_closed",
		function (sourceId, inBuffer)
			if sourceId ~= GLib.GetServerId () then return end
			
			local channelName = inBuffer:String ()
			while channelName ~= "" do
				local channel = GLib.Net.Layer2.Channels [channelName]
				if channel then
					channel:SetOpen (false)
				end
				
				channelName = inBuffer:String ()
			end
		end
	)

	if SERVER then
		GLib.Net.Layer2:AddEventListener ("ChannelRegistered",
			function (_, channel)
				self:SendChannelOpenNotification (channel:GetName ())
			end
		)
		
		GLib.Net.Layer2:AddEventListener ("ChannelUnregistered",
			function (_, channel)
				self:SendChannelClosedNotification (channel:GetName ())
			end
		)
		
		GLib.PlayerMonitor:AddEventListener ("PlayerConnected", "GLib.Net.Layer2.ChannelStateNetworker",
			function (_, ply, userId)
				self:SendOpenChannelList (userId)
			end
		)
		
		concommand.Add ("glib_request_channels",
			function (ply, _, _)
				if not ply or not ply:IsValid () then return end
				
				self:SendOpenChannelList (GLib.GetPlayerId (ply))
			end
		)
	elseif CLIENT then
		GLib.WaitForLocalPlayer (
			function ()
				RunConsoleCommand ("glib_request_channels")
			end
		)
	end
end

function self:dtor ()
	GLib.PlayerMonitor:RemoveEventListener ("PlayerConnected", "GLib.Net.Layer2.ChannelStateNetworker")
end

function self:SendChannelOpenNotification (channelName)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String (channelName)
	outBuffer:String ("")
	
	self.ChannelsOpenChannel:DispatchPacket (GLib.GetEveryoneId (), outBuffer)
end

function self:SendChannelClosedNotification (channelName)
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:String (channelName)
	outBuffer:String ("")
	
	self.ChannelsClosedChannel:DispatchPacket (GLib.GetEveryoneId (), outBuffer)
end

function self:SendOpenChannelList (userId)
	local outBuffer = GLib.Net.OutBuffer ()
	
	for channelName, channel in pairs (GLib.Net.Layer2.Channels) do
		if channel:IsOpen () then
			outBuffer:String (channelName)
		end
	end
	outBuffer:String ("")
	
	self.ChannelsOpenChannel:DispatchPacket (userId, outBuffer)
end

GLib.Net.Layer2.ChannelStateNetworker = GLib.Net.Layer2.ChannelStateNetworker ()