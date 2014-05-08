local self = {}
GLib.Protocol.Channel = GLib.MakeConstructor (self)

function self:ctor (channelName, handlerFunction)
	self.ChannelName = channelName
	self.StringTable = GLib.StringTable ()
	self.PacketHandlers = {}
	self.HandlerFunction = handlerFunction or self.DefaultHandlerFunction
	GLib.EventProvider (self)

	GLib.Net.RegisterChannel (self.ChannelName,
		function (senderId, inBuffer)
			self:HandlerFunction (senderId, inBuffer)
		end
	)
end

function self:CreatePacketHandler (packetTypeOrTypeId)
	if type (packetTypeOrTypeId) == "number" then
		packetTypeOrTypeId = self.StringTable:StringFromHash (packetTypeOrTypeId)
	end
	
	local ctor = self.PacketHandlers [packetType]
end

function self:DefaultHandlerFunction (senderId, inBuffer)
end

function self:GetChannelName ()
	return self.ChannelName
end

function self:GetStringTable ()
	return self.StringTable
end

function self:Register (packetType, class)
	self.StringTable:Add (packetType)
	class.Type = packetType
	class.TypeId = self.StringTable:HashFromString (packetType)
end

function self:RegisterResponse (packetType, ctor)
	self.StringTable:Add (packetType)
	self.PacketHandlers [packetType] = ctor
	local class = GLib.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = self.StringTable:HashFromString (packetType)
end

GLib.Net.RegisterChannel ("glib_new_request",
	function (senderId, inBuffer)
		local client = GLib.NetServer:GetEndPoint (senderId)
		local requestId = inBuffer:UInt32 ()
		local typeId = inBuffer:UInt32 ()
		local packetType = GLib.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = GLib.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("glib_new_request : No handler for " .. tostring (packetType) .. " is registered!")
			return
		end
		local response = ctor ()
		response:SetRemoteEndPoint (client)
		response:SetId (requestId)
		client:HandleIncomingSession (response, inBuffer)
	end
)

GLib.Net.RegisterChannel ("glib_request_data",
	function (senderId, inBuffer)
		local client = GLib.NetServer:GetEndPoint (senderId)
	end
)

GLib.Net.RegisterChannel ("glib_response_data",
	function (senderId, inBuffer)
		local client = GLib.EndPointManager:GetEndPoint (senderId)
		client:HandleIncomingPacket (inBuffer:UInt32 (), inBuffer)
	end
)

GLib.Net.RegisterChannel ("glib_notification",
	function (senderId, inBuffer)
		local client = GLib.EndPointManager:GetEndPoint (senderId)
	end
)