local self = {}
GAuth.Protocol.RegisterResponse ("NodeAddition", GAuth.MakeConstructor (self, GAuth.Protocol.Session))

function self:ctor ()
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	local childName = inBuffer:String ()
	local isGroupTree = inBuffer:Boolean ()
	local groupTree = GAuth.ResolveGroupTree (groupId)
	
	if groupTree then
		(isGroupTree and groupTree.AddGroupTree or groupTree.AddGroup) (groupTree, self:GetRemoteEndPoint ():GetRemoteId (), childName,
			function (returnCode)
				local outBuffer = self:CreatePacket ()
				outBuffer:UInt8 (returnCode)
				self:QueuePacket (outBuffer)
				self:Close ()
			end
		)
	else
		local outBuffer = self:CreatePacket ()
		outBuffer:UInt8 (GAuth.ReturnCode.NodeNotFound)
		self:QueuePacket (outBuffer)
		self:Close ()
	end
end