local self = {}
GLib.Containers.Tree = GLib.MakeConstructor (self)

function self:ctor (value)
	self.Value = value
	self.Children = GLib.Containers.LinkedList ()
	self.ChildCount = 0
end

function self:Add (value)
	local child = GLib.Containers.Tree (value)
	self.Children:AddLast (child)
	self.ChildCount = self.ChildCount + 1
	return child
end

function self:AddNode (tree)
	if type (tree) ~= "table" then
		GLib.PrintStackTrace ()
	end
	self.Children:AddLast (tree)
	self.ChildCount = self.ChildCount + 1
	return tree
end

function self:AddRange (array)
	for _, value in ipairs (array) do
		self.Children:AddLast (GLib.Containers.Tree ()).Value.Value = value
		self.ChildCount = self.ChildCount + 1
	end
end

function self:Clear ()
	self.Children:Clear ()
	self.ChildCount = 0
end

function self:FindChild (value)
	for linkedListNode in self.Children:GetEnumerator () do
		if linkedListNode.Value.Value == value then
			return linkedListNode.Value
		end
	end
	return nil
end

function self:GetChild (n)
	return self.Children:GetItem (n)
end

function self:GetChildCount ()
	return self.ChildCount
end

function self:GetFirstChild ()
	if not self.Children.First then
		return
	end
	return self.Children.First.Value
end

function self:GetEnumerator ()
	local enumerator = self.Children:GetEnumerator ()
	return function ()
		local childNode = enumerator ()
		if not childNode then
			return nil
		end
		return childNode.Value
	end
end

function self:RemoveLast ()
	if not self.Children.Last then
		return
	end
	self.ChildCount = self.ChildCount - 1
	self.Children:Remove (self.Children.Last)
end

function self:ToString (indent)
	indent = indent or 0
	local tree = string.rep ("  ", indent) .. "+" .. tostring (self.Value)
	
	for linkedListNode in self.Children:GetEnumerator () do
		local treeNode = linkedListNode.Value
		local value
		if treeNode then
			value = treeNode:ToString (indent + 1)
		else
			value = string.rep ("  ", indent + 1) .. "+[nil]"
		end
		tree = tree .. "\n" .. value
	end
	return tree
end