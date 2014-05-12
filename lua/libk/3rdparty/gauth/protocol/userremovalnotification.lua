local self = {}
GAuth.Protocol.UserRemovalNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("UserRemovalNotification", GAuth.Protocol.UserRemovalNotification)

function self:ctor (group, userId)
	self.GroupId = group and group:GetFullName ()
	self.UserId = userId
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	outBuffer:String (self.UserId)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	self.UserId = inBuffer:String ()
	
	local group = GAuth.ResolveGroup (self.GroupId)
	if not group then return end
	if not self:ShouldProcessNotification (group) then return end
	
	group:DispatchEvent ("NotifyUserRemoved", self.UserId)
end