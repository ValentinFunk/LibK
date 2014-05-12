local self = {}
GAuth.Protocol.NodeRemovalNotification = GAuth.MakeConstructor (self, GAuth.Protocol.Session)
GAuth.Protocol.RegisterNotification ("NodeRemovalNotification", GAuth.Protocol.NodeRemovalNotification)

function self:ctor (groupTree, childNode)
	self.GroupId = childNode and childNode:GetFullName ()
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
end

function self:HandleInitialPacket (inBuffer)
	self.GroupId = inBuffer:String ()
	
	local groupTreeNode = GAuth.ResolveGroupTreeNode (self.GroupId)
	if not groupTreeNode then return end
	if not self:ShouldProcessNotification (groupTreeNode:GetParentNode ()) then return end
	
	groupTreeNode:GetParentNode ():DispatchEvent ("NotifyNodeRemoved", groupTreeNode:GetName ())
end