local self = {}
GAuth.Protocol.RegisterResponse ("NodeRemoval", GAuth.MakeConstructor (self, GAuth.Protocol.Session))

function self:ctor ()
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
	
	if groupTreeNode then
		groupTreeNode:GetParentNode ():RemoveNode (self:GetRemoteEndPoint ():GetRemoteId (), groupTreeNode:GetName (),
			function (returnCode)
				local outBuffer = self:CreatePacket ()
				outBuffer:UInt8 (returnCode)
				self:QueuePacket (outBuffer)
				self:Close ()
			end
		)
	else
		local outBuffer = self:CreatePacket ()
		outBuffer:UInt8 (GAuth.ReturnCode.Success)
		self:QueuePacket (outBuffer)
		self:Close ()
	end
end