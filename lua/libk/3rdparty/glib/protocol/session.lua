local self = {}
GLib.Protocol.Session = GLib.MakeConstructor (self)

function self:ctor ()
	self.Id = 0
	
	self.RemoteEndPoint = nil
	
	self.PacketQueue = {}
	self.LastActivityTime = SysTime ()
	
	self.Closing = false
	
	GLib.EventProvider (self)
end

function self:Close ()
	if self.Closing then return end
	self.Closing = true
end

function self:CreatePacket ()
	local outBuffer = GLib.Net.OutBuffer ()
	outBuffer:UInt32 (self:GetId ())
	
	return outBuffer
end

function self:DequeuePacket ()
	local outBuffer = self.PacketQueue [1]
	table.remove (self.PacketQueue, 1)
	if outBuffer then
		self:ResetTimeout ()
	end
	return outBuffer
end

function self:GetId ()
	return self.Id
end

function self:GetRemoteEndPoint ()
	return self.RemoteEndPoint
end

function self:GetType ()
	return self.Type
end

--[[
	Session:GetTypeId ()
		Returns: Int32 typeId
]]
function self:GetTypeId ()
	return self.TypeId
end

-- overrideable
function self:HandleInitialPacket (inBuffer)
end

-- overrideable
function self:HandlePacket (inBuffer)
end

-- overrideable
function self:HandleTimeOut ()
end

function self:HasQueuedPackets ()
	return #self.PacketQueue > 0
end

function self:HasTimedOut ()
	return SysTime () - self.LastActivityTime > 120
end

function self:IsClosing ()
	return self.Closing
end

function self:QueuePacket (outBuffer)
	self.PacketQueue [#self.PacketQueue + 1] = outBuffer
	self:ResetTimeout ()
end

function self:ResetTimeout ()
	self.LastActivityTime = SysTime ()
end

function self:SetId (id)
	self.Id = id
end

function self:SetRemoteEndPoint (remoteEndPoint)
	self.RemoteEndPoint = remoteEndPoint
end

-- overrideable
function self:Tick ()
end

function self:ToString ()
	return self:GetType () .. ":" .. self:GetId ()
end