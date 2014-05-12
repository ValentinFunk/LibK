local self = {}
VFS.Protocol.Register ("FolderListing", self)
VFS.Protocol.FolderListingRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor (folder)
	self.Folder = folder
	self.LastChildName = ""
	self.ReceivedChildren = {}
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.Folder:GetPath ())
end

-- Packets may arrive in any order.
function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == VFS.ReturnCode.Success then
		self.ReceivedChildren [self:DispatchEvent ("ReceivedNodeInfo", inBuffer):GetName ()] = true
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.EndOfBurst)
		if self.ReceivedChildren [self.LastChildName] then
			self:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
			self:Close ()
		end
	elseif returnCode == VFS.ReturnCode.AccessDenied then
		self:DispatchEvent ("RunCallback", VFS.ReturnCode.AccessDenied)
	elseif returnCode == VFS.ReturnCode.Finished then
		self.LastChildName = inBuffer:String ()
		if self.LastChildName == "" or self.ReceivedChildren [self.LastChildName] then
			self:DispatchEvent ("RunCallback", VFS.ReturnCode.Finished)
			self:Close ()
		else
			VFS.Debug (self:ToString () .. " cannot close yet, waiting for " .. self.LastChildName .. "\n")
		end
	end
end