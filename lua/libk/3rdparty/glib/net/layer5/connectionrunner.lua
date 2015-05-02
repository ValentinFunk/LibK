local self = {}
GLib.Net.Layer5.ConnectionRunner = GLib.MakeConstructor (self, GLib.Net.ConnectionRunner)

function self:ctor ()
	for _, channel in pairs (GLib.Net.Layer5.Channels) do
		self:RegisterChannel (channel)
	end
	
	GLib.Net.Layer5:AddEventListener ("ChannelRegistered", "GLib.Net.Layer5.ConnectionRunner",
		function (_, channel)
			self:RegisterChannel (channel)
		end
	)
	
	GLib.Net.Layer5:AddEventListener ("ChannelUnregistered", "GLib.Net.Layer5.ConnectionRunner",
		function (_, channel)
			self:UnregisterChannel (channel)
		end
	)
end

function self:dtor ()
	GLib.Net.Layer5:RemoveEventListener ("ChannelRegistered",   "GLib.Net.Layer5.ConnectionRunner")
	GLib.Net.Layer5:RemoveEventListener ("ChannelUnregistered", "GLib.Net.Layer5.ConnectionRunner")
end

GLib.Net.Layer5.ConnectionRunner = GLib.Net.Layer5.ConnectionRunner ()