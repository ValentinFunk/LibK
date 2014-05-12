local self = {}
GAuth.Protocol.Register ("NodeAddition", self)
GAuth.Protocol.NodeAdditionRequest = GAuth.MakeConstructor (self, GAuth.Protocol.Session)

function self:ctor (groupTree, childName, isGroupTree, callback)
	self.Callback = callback or GAuth.NullCallback
	self.GroupId = groupTree:GetFullName ()
	self.ChildName = childName
	self.IsGroupTree = isGroupTree
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.GroupId)
	outBuffer:String (self.ChildName)
	outBuffer:Boolean (self.IsGroupTree)
end

function self:HandlePacket (inBuffer)
	local returnCode = inBuffer:UInt8 ()
	if returnCode == GAuth.ReturnCode.Success then
		local group = GAuth.ResolveGroupTree (self.GroupId)
		if group then group = group:GetChild (self.ChildName) end
		if group and group:IsGroupTree () ~= self.IsGroupTree then group = nil end
		self.Callback (returnCode, group)
	else
		self.Callback (returnCode)
	end
	self:Close ()
end

function self:HandleTimeOut ()
	self.Callback (GAuth.ReturnCode.TimedOut)
end