local self = {}
GAuth.Protocol.Register ("UserRemoval", self)
GAuth.Protocol.UserRemovalRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (group, userId, callback)
	self.Callback = callback or GAuth.NullCallback
	self.GroupId = group:GetFullName ()
	self.UserId = userId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	outBuffer:String (self.UserId)
end

function self:HandlePacket (inBuffer)
	self.Callback (inBuffer:UInt8 ())
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end