local self = {}
GAuth.Protocol.NodeAdditionNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("NodeAdditionNotification", GAuth.Protocol.NodeAdditionNotification)

function self:ctor (groupTree, childNode)
	self.GroupId = groupTree and groupTree:GetFullName ()
	self.ChildName = childNode and childNode:GetName ()
	self.IsGroupTree = childNode and childNode:IsGroupTree () or false
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	outBuffer:String (self.ChildName)
	outBuffer:Boolean (self.IsGroupTree)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	self.ChildName = inBuffer:String ()
	self.IsGroupTree = inBuffer:Boolean ()
	
	local groupTree = GAuth.ResolveGroupTree (self.GroupId)
	if not groupTree then return end
	if not self:ShouldProcessNotification (groupTree) then return end
	
	if self.IsGroupTree then
		groupTree:DispatchEvent ("NotifyGroupTreeAdded", self.ChildName)
	else
		groupTree:DispatchEvent ("NotifyGroupAdded", self.ChildName)
	end
end