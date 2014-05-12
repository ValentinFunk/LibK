local self = {}
VFS.Protocol.RegisterResponse ("FolderChild", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.ChildName = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.ChildName = inBuffer:String ()
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath .. "/" .. self.ChildName,
		function (returnCode, node)
			local outBuffer = self:CreatePacket ()
			outBuffer:UInt8 (returnCode)
			if returnCode == VFS.ReturnCode.Success then
				self:SerializeNode (node, outBuffer)
				
				self:GetRemoteEndPoint ():HookNode (node:GetParentFolder ())
			end
			self:QueuePacket (outBuffer)
			self:Close ()
		end
	)
end