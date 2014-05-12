VFS.Protocol.ResponseTable = {}
VFS.Protocol.StringTable = VFS.StringTable ()

function VFS.Protocol.Register (packetType, class)
	VFS.Protocol.StringTable:Add (packetType)
	class.Type = packetType
	class.TypeId = VFS.Protocol.StringTable:HashFromString (packetType)
end

function VFS.Protocol.RegisterNotification (packetType, ctor)
	VFS.Protocol.StringTable:Add (packetType)
	VFS.Protocol.ResponseTable [packetType] = ctor
	local class = VFS.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = VFS.Protocol.StringTable:HashFromString (packetType)
end

function VFS.Protocol.RegisterResponse (packetType, ctor)
	VFS.Protocol.StringTable:Add (packetType)
	VFS.Protocol.ResponseTable [packetType] = ctor
	local class = VFS.GetMetaTable (ctor)
	class.Type = packetType
	class.TypeId = VFS.Protocol.StringTable:HashFromString (packetType)
end

VFS.Net.RegisterChannel ("vfs_new_session",
	function (remoteId, inBuffer)
		local remoteEndPoint = VFS.EndPointManager:GetEndPoint (remoteId)
		local requestId = inBuffer:UInt32 ()
		local typeId = inBuffer:UInt32 ()
		local packetType = VFS.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = VFS.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("vfs_new_session : No handler for " .. tostring (packetType) .. " is registered!")
			return
		end
		local response = ctor ()
		response:SetRemoteEndPoint (remoteEndPoint)
		response:SetId (requestId)
		remoteEndPoint:HandleIncomingSession (response, inBuffer)
	end
)

VFS.Net.RegisterChannel ("vfs_session_data",
	function (remoteId, inBuffer)
		local remoteEndPoint = VFS.EndPointManager:GetEndPoint (remoteId)
		remoteEndPoint:HandleIncomingPacket (inBuffer:UInt32 (), inBuffer)
	end
)

VFS.Net.RegisterChannel ("vfs_notification",
	function (remoteId, inBuffer)
		local remoteEndPoint = VFS.EndPointManager:GetEndPoint (remoteId)
		local typeId = inBuffer:UInt32 ()
		local packetType = VFS.Protocol.StringTable:StringFromHash (typeId)
		
		local ctor = VFS.Protocol.ResponseTable [packetType]
		if not ctor then
			ErrorNoHalt ("vfs_notification : No handler for " .. tostring (packetType) .. " is registered!\n")
			return
		end
		local session = ctor ()
		session:SetRemoteEndPoint (remoteEndPoint)
		remoteEndPoint:HandleIncomingNotification (session, inBuffer)
	end
)