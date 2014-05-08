local self = {}
GLib.Containers.BinaryTree = GLib.MakeConstructor (self)

function self:ctor ()
	self.Root = nil
end

function self:Clear ()
	if not self.Root then return end
	
	self.Root:Orphan ()
end

function self:GetLeftmost ()
	if not self.Root then return nil end
	return self.Root:GetLeftmost ()
end

function self:GetRightmost ()
	if not self.Root then return nil end
	return self.Root:GetRightmost ()
end

function self:GetRoot ()
	return self.Root
end

function self:SetRoot (root)
	if self.Root == root then return end
	
	if self.Root then
		self.Root.Tree = nil
	end
	
	self.Root = root
	
	if self.Root then
		self.Root.Tree = self
	end
end

function self:ToString ()
	if not self.Root then return "[nil]" end
	return self.Root:ToStringRecursive ()
end