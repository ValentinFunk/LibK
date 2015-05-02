local channels = GLib_Net_Layer2_GetChannels and GLib_Net_Layer2_GetChannels () or {}
GLib.Net.Layer2.Channels = channels

function GLib_Net_Layer2_GetChannels ()
	return channels
end

--[[
	Events:
		ChannelRegistered (Channel channel)
			Fired when a channel has been registered.
		ChannelUnregistered (Channel channel)
			Fired when a channel has been unregistered.
]]

GLib.EventProvider (GLib.Net.Layer2)

function GLib.Net.Layer2.DispatchPacket (destinationId, channelName, packet)
	local channel = GLib.Net.Layer2.GetChannel (channelName)
	if not channel then
		GLib.Error ("GLib.Net.Layer2.DispatchPacket : Channel " .. channelName .. " doesn't exist.")
		return
	end
	
	return channel:DispatchPacket (destinationId, packet)
end

function GLib.Net.Layer2.GetChannel (channelName)
	return GLib.Net.Layer2.Channels [channelName]
end

function GLib.Net.Layer2.RegisterChannel (channel, ...)
	if type (channel) == "string" then
		return GLib.Net.Layer2.RegisterChannelByName (channel, ...)
	end
	
	local channelName = channel:GetName ()
	
	if GLib.Net.Layer2.Channels [channelName] == channel then return channel end
	
	if GLib.Net.Layer2.Channels [channelName] then
		channel:SetOpen (GLib.Net.Layer2.Channels [channelName]:IsOpen ())
		GLib.Net.Layer2.Channels [channelName]:dtor ()
	end
	
	GLib.Net.Layer2.Channels [channelName] = channel
	
	if SERVER then
		channel:SetOpen (true)
	end
	
	GLib.Net.Layer2:DispatchEvent ("ChannelRegistered", channel)
	
	return channel
end

function GLib.Net.Layer2.RegisterChannelByName (channelName, handler)
	local channel = GLib.Net.Layer2.GetChannel (channelName)
	if channel then
		channel:SetHandler (handler)
		return channel
	end
	
	channel = GLib.Net.Layer2.Channel (channelName, handler)
	return GLib.Net.Layer2.RegisterChannel (channel)
end

function GLib.Net.Layer2.UnregisterChannel (channelOrChannelName)
	if type (channelOrChannelName) ~= "string" then
		channelOrChannelName = channelOrChannelName:GetName ()
	end
	
	return GLib.Net.Layer2.UnregisterChannelByName (channelOrChannelName)
end

function GLib.Net.Layer2.UnregisterChannelByName (channelName)
	if not GLib.Net.Layer2.Channels [channelName] then return end
	
	local channel = GLib.Net.Layer2.Channels [channelName]
	GLib.Net.Layer2.Channels [channelName] = nil
	channel:dtor ()
	
	GLib.Net.Layer2:DispatchEvent ("ChannelUnregistered", channel)
end

function GLib.Net.Layer2.IsChannelOpen (channelName)
	if not GLib.Net.Layer2.Channels [channelName] then return false end
	
	return GLib.Net.Layer2.Channels [channelName]:IsOpen ()
end