local self = {}
GLib.Containers.LinkedListNode = GLib.MakeConstructor (self)

function self:ctor ()
	self.List     = nil
	self.Next     = nil
	self.Previous = nil
	self.Value    = nil
end

function self:InsertNext (node)
	if node == nil then return end
	
	node.List = self.List
	node.Previous = self
	node.Next = self.Next
	
	self.Next = node
	
	if node.Next then node.Next.Previous = node end
	
	if self.List then
		self.List.Count = self.List.Count + 1
		if self.List.Last == self then
			self.List.Last = node
		end
	end
end

function self:InsertPrevious (node)
	if node == nil then return end
	
	node.List = self.List
	node.Next = self
	node.Previous = self.Previous
	
	self.Previous = node
	
	if node.Previous then node.Previous.Next = node end
	
	if self.List then
		self.List.Count = self.List.Count + 1
		if self.List.First == self then
			self.List.First = node
		end
	end
end

function self:ToString ()
	if not self.Value then return "[nil]" end
	
	if type (self.Value) == "table" and self.Value.ToString then return self.Value:ToString () end
	if type (self.Value) == "string" then return "\"" .. GLib.String.Escape (self.Value) .. "\"" end
	return tostring (self.Value)
end