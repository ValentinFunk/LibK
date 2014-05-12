local self = {}
VFS.Protocol.RegisterResponse ("FolderListing", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.FolderPath = nil
end

function self:HandleInitialPacket (inBuffer)
	self.FolderPath = inBuffer:String ()
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), self.FolderPath,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if node:IsFolder () then
					self:GetRemoteEndPoint ():HookNode (node)
					
					local lastChildName = ""
					node:EnumerateChildren (self:GetRemoteEndPoint ():GetRemoteId (),
						function (returnCode, node)
							if returnCode == VFS.ReturnCode.Success then
								lastChildName = node:GetName ()
							
								local outBuffer = self:CreatePacket ()
								outBuffer:UInt8 (returnCode)
								self:SerializeNode (node, outBuffer)							
								self:QueuePacket (outBuffer)
							elseif returnCode == VFS.ReturnCode.Finished then
								self:SendFinished (lastChildName)
								self:Close ()
							elseif returnCode == VFS.ReturnCode.EndOfBurst then
							else
								self:SendReturnCode (returnCode)
								self:SendFinished (lastChildName)
								self:Close ()
							end
						end
					)
					
					-- If it's the root folder, synchronize permissions too
					if node:IsRoot () then
						VFS.PermissionBlockNetworker:SynchronizeBlock (self:GetRemoteEndPoint ():GetRemoteId (), node:GetPermissionBlock ())
					end
				else
					self:SendReturnCode (VFS.ReturnCode.NotAFolder)
					self:Close ()
				end
			else
				self:SendReturnCode (returnCode)
				self:SendFinished ()
				self:Close ()
			end
		end
	)
end

function self:SendFinished (lastChildName)
	lastChildName = lastChildName or ""
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt8 (VFS.ReturnCode.Finished)
	outBuffer:String (lastChildName)
	self:QueuePacket (outBuffer)
	
	VFS.Debug (self:ToString () .. ": " .. VFS.ReturnCode [VFS.ReturnCode.Finished])
end