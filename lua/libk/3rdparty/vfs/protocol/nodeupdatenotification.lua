local self = {}
VFS.Protocol.NodeUpdateNotification = VFS.MakeConstructor (self, VFS.Protocol.Session)
VFS.Protocol.RegisterNotification ("NodeUpdateNotification", VFS.Protocol.NodeUpdateNotification)

function self:ctor (node, updateFlags)
	self.Node = node
	self.Path = self.Node and self.Node:GetPath ()
	self.UpdateFlags = updateFlags
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Path)
	outBuffer:UInt8 (self.UpdateFlags)
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.DisplayName) ~= 0 then
		outBuffer:String (self.Node:GetDisplayName () or "")
	end
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.Size) ~= 0 then
		local size = self.Node:IsFile () and self.Node:GetSize () or -1
		if size == -1 then size = 0xFFFFFFFF end
		outBuffer:UInt32 (size)
	end
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.ModificationTime) ~= 0 then
		local modificationTime = self.Node:GetModificationTime ()
		if modificationTime == -1 then modificationTime = 0xFFFFFFFF end
		outBuffer:UInt32 (modificationTime)
	end
end

function self:HandleInitialPacket (inBuffer)
	self.Path = inBuffer:String ()
	self.UpdateFlags = inBuffer:UInt8 ()
	
	local node = self:GetRemoteEndPoint ():GetRoot ():GetChildSynchronous (self.Path)
	node = node and node:GetInner ()
	if not node then return end
	if not node:IsNetNode () then return end
	
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.DisplayName) ~= 0 then
		local displayName = inBuffer:String ()
		if displayName == "" then displayName = nil end
		node:SetDisplayName (displayName)
	end
	
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.Size) ~= 0 then
		local size = inBuffer:UInt32 ()
		if size == 0xFFFFFFFF then size = -1 end
		if node:IsFile () then node:SetSize (size) end
	end
	
	if bit.band (self.UpdateFlags, VFS.UpdateFlags.ModificationTime) ~= 0 then
		local modificationTime = inBuffer:UInt32 ()
		if modificationTime == 0xFFFFFFFF then modificationTime = -1 end
		node:SetModificationTime (modificationTime)
	end
end