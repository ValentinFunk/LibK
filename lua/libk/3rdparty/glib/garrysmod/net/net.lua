function GLib.Net.DispatchPacket (destinationId, channelName, packet)
	local channel = GLib.Net.GetChannel (channelName)
	if not channel then return end
	
	return GLib.Net.GetChannel (channelName):DispatchPacket (destinationId, packet)
end

function GLib.Net.GetChannel (channelName)
	return GLib.Net.Layer5.GetChannel (channelName) or
	       GLib.Net.Layer3.GetChannel (channelName) or
		   GLib.Net.Layer2.GetChannel (channelName)
end

function GLib.Net.RegisterChannel (channelName, handler)
	return GLib.Net.Layer5.RegisterChannel (channelName, handler)
end

function GLib.Net.UnregisterChannel (channelName)
	return GLib.Net.Layer5.UnregisterChannel (channelName)
end

function GLib.Net.IsChannelOpen (channelName)
	local channel = GLib.Net.GetChannel (channelName)
	if not channel then return false end
	
	return channel:IsOpen ()
end