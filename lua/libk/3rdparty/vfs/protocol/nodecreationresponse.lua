local self = {}
VFS.Protocol.RegisterResponse ("NodeCreation", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
	self.ChildName = nil
	self.IsFolder = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	self.ChildName = VFS.SanitizeNodeName (inBuffer:String ())
	self.IsFolder = inBuffer:Boolean ()
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				node:CreateDirectNode (self:GetRemoteEndPoint ():GetRemoteId (), self.ChildName, self.IsFolder,
					function (returnCode, childNode)
						if returnCode == VFS.ReturnCode.Success then
							local outBuffer = self:CreatePacket ()
							outBuffer:UInt8 (returnCode)
							self:SerializeNode (childNode, outBuffer)
							self:QueuePacket (outBuffer)
						else
							self:SendReturnCode (returnCode)
						end
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