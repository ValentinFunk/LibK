local self = {}
GLib.Protocol.EndPoint = GLib.MakeConstructor (self)

local nextUniqueId = 0

function self:ctor (remoteId, systemName)
	self.SystemName = systemName
	self.RemoteId = remoteId
	self.UniqueId = self.RemoteId .. "." .. tostring (nextUniqueId)
	nextUniqueId = nextUniqueId + 1
	
	self.Sessions = {}
	self.NextSessionId = 0
	if SERVER then self.NextSessionId = self.NextSessionId + 65536 end
	
	self.DataChannel = "glib_session_data"
	self.NewSessionChannel = "glib_new_session"
	self.NotificationChannel = "glib_notification"
	
	timer.Create (self.SystemName .. ".Net.EndPoint." .. self.UniqueId, 0.01, 0,
		function ()
			self:ProcessSessions ()
		end
	)
	
	self.Log = {}
end

function self:dtor ()
	timer.Destroy (self.SystemName .. ".Net.EndPoint." .. self.UniqueId)
	
	for _, session in pairs (self.Sessions) do
		session:HandleTimeOut ()
		session:Close ()
	end
end

function self:CloseSession (session)
	if not self.Sessions [session:GetId ()] then return end
	
	if not session:HasQueuedPackets () then
		self:DebugMessage (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ": Session " .. session:ToString () .. " closed.")
		session:DispatchEvent ("Closed")
		self.Sessions [session:GetId ()] = nil
	end
	
	session:Close ()
end

function self:DebugMessage (message)
	if true then return end
	
	message = tostring (CurTime ()) .. ": " .. message
	self.Log [#self.Log + 1] =
	{
		Message = message,
		StackTrace = GLib.StackTrace ()
	}
	if #self.Log > 100 then
		table.remove (self.Log, 1)
	end
end

function self:GetRemoteId ()
	return self.RemoteId
end

function self:HandleIncomingNotification (session, inBuffer)
	session:HandleInitialPacket (inBuffer)
end

function self:HandleIncomingPacket (sessionId, inBuffer)
	local session = self.Sessions [sessionId]
	if not session then
		ErrorNoHalt (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ":HandleIncomingPacket : Session " .. sessionId .. " not found!\n")
		ErrorNoHalt ("Data: " .. GLib.PrettifyString (inBuffer:Bytes (20)) .. "\n")
		return
	end
	session:ResetTimeout ()
	session:HandlePacket (inBuffer)
end

function self:HandleIncomingSession (session, inBuffer)
	self.Sessions [session:GetId ()] = session
	session:HandleInitialPacket (inBuffer)
end

function self:ProcessSessions ()
	local timedOut = {}
	local closed = {}
	for _, session in pairs (self.Sessions) do
		session:Tick ()
		
		local outBuffer = session:DequeuePacket ()
		if outBuffer then
			self:DebugMessage (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ": Session " .. session:ToString () .. " packet sent to " .. self.RemoteId .. ".")
			GLib.Net.DispatchPacket (self.RemoteId, self.DataChannel, outBuffer)
		end
		
		if session:HasTimedOut () then
			timedOut [session] = true
		end
		
		if session:IsClosing () and not session:HasQueuedPackets () then
			closed [session] = true
		end
	end
	
	for session, _ in pairs (timedOut) do
		if not session:IsClosing () then
			self:DebugMessage (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ": Session " .. session:ToString () .. " timed out.")
			session:DispatchEvent ("TimedOut")
			session:HandleTimeOut ()
			session:Close ()
		end
	end
	
	for session, _ in pairs (closed) do
		self:CloseSession (session)
	end
end

function self:SendNotification (session)
	session:SetRemoteEndPoint (self)
	self:DebugMessage (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ":SendNotification : " .. session:ToString ())
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (session:GetTypeId ())
	session:GenerateInitialPacket (outBuffer)
	
	GLib.Net.DispatchPacket (self.RemoteId, self.NotificationChannel, outBuffer)
end

function self:StartSession (session)
	session:SetRemoteEndPoint (self)
	session:SetId (self.NextSessionId)
	self.NextSessionId = self.NextSessionId + 1
	
	self:DebugMessage (self.SystemName .. ".Net.EndPoint." .. self.UniqueId .. ":StartSession : New " .. session:ToString ())
	
	self.Sessions [session:GetId ()] = session
	
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (session:GetId ())
	outBuffer:UInt32 (session:GetTypeId ())
	session:GenerateInitialPacket (outBuffer)
	
	GLib.Net.DispatchPacket (self.RemoteId, self.NewSessionChannel, outBuffer)
	session:ResetTimeout ()
end