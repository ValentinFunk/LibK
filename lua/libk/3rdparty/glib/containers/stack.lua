local self = {}
GLib.Containers.Stack = GLib.MakeConstructor (self)

function self:ctor ()
	self.Items = {}
	self.Count = 0
	self.Top = nil
end

--- Clears the stack
function self:Clear ()
	self.Count = 0
	self.Top = nil
end

--- Returns the item at the top of the stack
-- @return The item at the top of the stack
function self:GetTop ()
	return self.Top
end

--- Returns whether the stack is empty
-- @return true if the stack is empty
function self:IsEmpty ()
	return self.Count == 0
end

--- Returns the nth item from the top of the stack
-- @return The nth item from the top of the stack
function self:Peek (offset)
	offset = offset or 0
	if offset < 0 then offset = -offset end
	return self.Items [self.Count - offset]
end

--- Pops an item from the top of the stack
-- @return The item that was popped from the top of the stack or nil if the stack was already empty
function self:Pop ()
	if self.Count == 0 then return nil end
	local top = self.Top
	self.Items [self.Count] = nil
	self.Count = self.Count - 1
	self.Top = self.Items [self.Count]
	return top
end

--- Pushes an item onto the top of the stack
-- @param value The item to be pushed onto the top of the stack
function self:Push (value)
	self.Count = self.Count + 1
	self.Items [self.Count] = value
	self.Top = value
end

--- Sets the item at the top of the stack
-- @param value The item to replace the top of the stack
function self:SetTop (value)
	self.Items [self.Count] = value
	self.Top = value
end

--- Returns a string representation of this stack
-- @return A string representation of this stack
function self:ToString ()
	local stack = "[Stack (" .. string.format ("%02d", self.Count) .. ")]"
	for i = 1, self.Count do
		stack = stack .. "\n[" .. string.format ("%02d", i) .. "] "
		if type (self.Items [i]) == "table" and type (self.Items [i].ToString) == "function" then
			stack = stack .. self.Items [i]:ToString ()
		else
			stack = stack .. tostring (self.Items [i])
		end
	end
	return stack
end