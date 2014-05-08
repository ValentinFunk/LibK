local self = {}
GLib.Containers.Queue = GLib.MakeConstructor (self)

function self:ctor ()
	self.LinkedList = GLib.Containers.LinkedList ()
	self.Front = nil
	
	self.Count = 0
end

function self:Clear ()
	self.LinkedList:Clear ()
	self.Front = nil
	self.Count = 0
end

function self:Dequeue ()
	local node = self.LinkedList.First
	self.LinkedList:Remove (node)
	self.Count = self.Count - 1
	
	self.Front = self.LinkedList.First and self.LinkedList.First.Value or nil
	return node.Value
end

function self:Enqueue (item)
	self.LinkedList:AddLast (item)
	self.Count = self.Count + 1
	
	self.Front = self.LinkedList.First and self.LinkedList.First.Value or nil
end

function self:GetCount ()
	return self.Count
end

function self:GetFront ()
	return self.Front
end

function self:IsEmpty ()
	return self.Count == 0
end

function self:ToString ()
	return self.LinkedList:ToString ()
end