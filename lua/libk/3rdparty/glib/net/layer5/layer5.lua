local channels = GLib_Net_Layer5_GetChannels and GLib_Net_Layer5_GetChannels () or {}
GLib.Net.Layer5.Channels = channels

function GLib_Net_Layer5_GetChannels ()
	return channels
end

--[[
	Events:
		ChannelRegistered (Channel channel)
			Fired when a channel has been registered.
		ChannelUnregistered (Channel channel)
			Fired when a channel has been unregistered.
]]

GLib.EventProvider (GLib.Net.Layer5)

function GLib.Net.Layer5.DispatchPacket (destinationId, channelName, packet)
	local channel = GLib.Net.Layer5.GetChannel (channelName)
	if not channel then
		GLib.Error ("GLib.Net.Layer5.DispatchPacket : Channel " .. channelName .. " doesn't exist.")
		return
	end
	
	return channel:DispatchPacket (destinationId, packet)
end

function GLib.Net.Layer5.GetChannel (channelName)
	return GLib.Net.Layer5.Channels [channelName]
end

function GLib.Net.Layer5.Listen (channelName, handler, innerChannel)
	return GLib.Net.Layer5.RegisterConnectionChannel (channelName, handler, innerChannel)
end

function GLib.Net.Layer5.RegisterConnectionChannel (channelName, handler, innerChannel)
	local channel = GLib.Net.Layer5.ConnectionChannel (channelName, handler, innerChannel)
	return GLib.Net.Layer5.RegisterChannel (channel)
end

function GLib.Net.Layer5.RegisterLayer3Channel (channelName, handler, innerChannel)
	local channel = GLib.Net.Layer5.Layer3Channel (channelName, handler, innerChannel)
	return GLib.Net.Layer5.RegisterChannel (channel)
end

function GLib.Net.Layer5.RegisterOrderedChannel (channelName, handler, innerChannel)
	local channel = GLib.Net.Layer5.OrderedChannel (channelName, handler, innerChannel)
	return GLib.Net.Layer5.RegisterChannel (channel)
end

function GLib.Net.Layer5.RegisterChannel (channel, ...)
	if type (channel) == "string" then
		return GLib.Net.Layer5.RegisterOrderedChannel (channel, ...)
	end
	
	local channelName = channel:GetName ()
	
	if GLib.Net.Layer5.Channels [channelName] == channel then return channel end
	
	if GLib.Net.Layer5.Channels [channelName] then
		channel:SetOpen (GLib.Net.Layer5.Channels [channelName]:IsOpen ())
		GLib.Net.Layer5.Channels [channelName]:dtor ()
	end
	
	GLib.Net.Layer5.Channels [channelName] = channel
	
	if SERVER then
		channel:SetOpen (true)
	end
	
	GLib.Net.Layer5:DispatchEvent ("ChannelRegistered", channel)
	
	return channel
end

function GLib.Net.Layer5.UnregisterChannel (channelOrChannelName)
	if type (channelOrChannelName) ~= "string" then
		channelOrChannelName = channelOrChannelName:GetName ()
	end
	
	return GLib.Net.Layer5.UnregisterChannelByName (channelOrChannelName)
end

function GLib.Net.Layer5.UnregisterChannelByName (channelName)
	if not GLib.Net.Layer5.Channels [channelName] then return end
	
	local channel = GLib.Net.Layer5.Channels [channelName]
	GLib.Net.Layer5.Channels [channelName] = nil
	channel:dtor ()
	
	GLib.Net.Layer5:DispatchEvent ("ChannelUnregistered", channel)
end

function GLib.Net.Layer5.IsChannelOpen (channelName)
	if not GLib.Net.Layer5.Channels [channelName] then return false end
	
	return GLib.Net.Layer5.Channels [channelName]:IsOpen ()
end