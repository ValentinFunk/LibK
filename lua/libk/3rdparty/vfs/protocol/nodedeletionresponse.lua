local self = {}
VFS.Protocol.RegisterResponse ("NodeDeletion", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.ChildName = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.ChildName = inBuffer:String ()
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				node:DeleteDirectChild (self:GetRemoteEndPoint ():GetRemoteId (), self.ChildName,
					function (returnCode)
						self:SendReturnCode (returnCode)
						self:Close ()
					end
				)
			else
				self:SendReturnCode (returnCode)
				self:Close ()
			end
		end
	)
end