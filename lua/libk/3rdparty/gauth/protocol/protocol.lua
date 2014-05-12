GAuth.Protocol.PermissionBlock = {}
GAuth.Protocol.ResponseTable = {}
GAuth.Protocol.StringTable = GAuth.StringTable ()

function GAuth.Protocol.Register (packetType, class)
	GAuth.Protocol.StringTable:Add (packetType)
	class.Type = packetType
	class.TypeId = GAuth.Protocol.StringTable:HashFromString (packetType)
end

function GAuth.Protocol.RegisterNotification (packetType, ctor)
	GAuth.Protocol.StringTable:Add (packetType)
	GAuth.Protocol.ResponseTable [packetType] = ctor
	local class = GAuth.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = GAuth.Protocol.StringTable:HashFromString (packetType)
end

function GAuth.Protocol.RegisterResponse (packetType, ctor)
	GAuth.Protocol.StringTable:Add (packetType)
	GAuth.Protocol.ResponseTable [packetType] = ctor
	local class = GAuth.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = GAuth.Protocol.StringTable:HashFromString (packetType)
end

GAuth.Net.RegisterChannel ("gauth_new_session",
	function (remoteId, inBuffer)
		local remoteEndPoint = GAuth.EndPointManager:GetEndPoint (remoteId)
		local requestId = inBuffer:UInt32 ()
		local typeId = inBuffer:UInt32 ()
		local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = GAuth.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("gauth_new_session : No handler for " .. tostring (packetType) .. " is registered!\n")
			return
		end
		local session = ctor ()
		session:SetRemoteEndPoint (remoteEndPoint)
		session:SetId (requestId)
		remoteEndPoint:HandleIncomingSession (session, inBuffer)
	end
)

GAuth.Net.RegisterChannel ("gauth_session_data",
	function (remoteId, inBuffer)
		local remoteEndPoint = GAuth.EndPointManager:GetEndPoint (remoteId)
		remoteEndPoint:HandleIncomingPacket (inBuffer:UInt32 (), inBuffer)
	end
)

GAuth.Net.RegisterChannel ("gauth_notification",
	function (remoteId, inBuffer)
		local remoteEndPoint = GAuth.EndPointManager:GetEndPoint (remoteId)
		local typeId = inBuffer:UInt32 ()
		local packetType = GAuth.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = GAuth.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("gauth_notification : No handler for " .. tostring (packetType) .. " is registered!\n")
			return
		end
		local session = ctor ()
		session:SetRemoteEndPoint (remoteEndPoint)
		remoteEndPoint:HandleIncomingNotification (session, inBuffer)
	end
)