local self = {}
GAuth.Protocol.RegisterResponse ("UserRemoval", GAuth.MakeConstructor (self, GAuth.Protocol.Session))

function self:ctor ()
end

function self:HandleInitialPacket (inBuffer)
	local groupId = inBuffer:String ()
	local userId = inBuffer:String ()
	local group = GAuth.ResolveGroup (groupId)
	
	if group then
		group:RemoveUser (self:GetRemoteEndPoint ():GetRemoteId (), userId,
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