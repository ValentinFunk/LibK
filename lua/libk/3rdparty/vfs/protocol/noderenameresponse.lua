local self = {}
VFS.Protocol.RegisterResponse ("NodeRename", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.OldName = nil
	self.NewName = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.OldName = VFS.SanitizeNodeName (inBuffer:String ())
	self.NewName = VFS.SanitizeNodeName (inBuffer:String ())
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				node:RenameChild (self:GetRemoteEndPoint ():GetRemoteId (), self.OldName, self.NewName,
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