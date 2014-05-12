local self = {}
GAuth.Protocol.Register ("NodeRemoval", self)
GAuth.Protocol.NodeRemovalRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (groupTree, childNode, callback)
	self.Callback = callback or GAuth.NullCallback
	self.GroupId = childNode:GetFullName ()
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end