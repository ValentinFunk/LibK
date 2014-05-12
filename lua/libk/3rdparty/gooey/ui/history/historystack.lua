local self = {}
Gooey.HistoryStack = Gooey.MakeConstructor (self, Gooey.IHistoryStack)

--[[
	Events:
		ItemPushed (HistoryItem historyItem)
			Fired when a HistoryItem has been added to this HistoryStack.
		MovedForward (HistoryItem historyItem)
			Fired when the state has been moved forward.
		MovedBack (HistoryItem historyItem)
			Fired when the state has been moved back.
		CurrentItemChanged (HistoryItem historyItem)
			Fired when the current HistoryItem has been changed.
		StackChanged ()
			Fired when a HistoryItem has been added or the state has been moved forward or back.
		StackCleared ()
			Fired when this UndoRedoStack has been cleared.
]]

function self:ctor ()
	self.PreviousStack = Gooey.Containers.Stack ()
	self.NextStack     = Gooey.Containers.Stack ()
	self.CurrentItem   = nil
end

-- IHistoryStack
function self:CanMoveForward ()
	return self.NextStack.Count > 0
end

function self:CanMoveBack ()
	return self.PreviousStack.Count > 0
end

function self:Clear ()
	self.PreviousStack:Clear ()
	self.NextStack    :Clear ()
	self.CurrentItem = nil
	
	self:DispatchEvent ("StackChanged")
	self:DispatchEvent ("StackCleared")
	self:DispatchEvent ("CurrentItemChanged", self.CurrentItem)
end

function self:GetCurrentItem ()
	return self.CurrentItem
end

function self:GetNextDescription ()
	return self.NextStack.Top:GetDescription ()
end

function self:GetNextItem ()
	return self.NextStack.Top
end

function self:GetNextStack ()
	return self.NextStack
end

function self:GetPreviousDescription ()
	return self.PreviousStack.Top:GetDescription ()
end

function self:GetPreviousItem ()
	return self.PreviousStack.Top
end

function self:GetPreviousStack ()
	return self.PreviousStack
end

function self:Push (historyItem)
	if self:GetCurrentItem () then
		self.PreviousStack:Push (self:GetCurrentItem ())
	end
	self.CurrentItem = historyItem
	self.NextStack:Clear ()
	
	self:DispatchEvent ("CurrentItemChanged", self.CurrentItem)
	self:DispatchEvent ("ItemPushed", self.CurrentItem)
	self:DispatchEvent ("StackChanged")
end

function self:MoveForward (count)
	count = count or 1
	for i = 1, count do
		if self.NextStack.Count == 0 then return end
		
		self.PreviousStack:Push (self.CurrentItem)
		self.NextStack.Top:MoveForward ()
		self.CurrentItem = self.NextStack:Pop ()
		
		self:DispatchEvent ("MovedForward", self.CurrentItem)
		self:DispatchEvent ("CurrentItemChanged", self.CurrentItem)
		self:DispatchEvent ("StackChanged")
	end
end

function self:MoveBack (count)
	count = count or 1
	for i = 1, count do
		if self.PreviousStack.Count == 0 then return end
		
		self.NextStack:Push (self.CurrentItem)
		self.PreviousStack.Top:MoveBack ()
		self.CurrentItem = self.PreviousStack:Pop ()
		
		self:DispatchEvent ("MovedBack", self.CurrentItem)
		self:DispatchEvent ("CurrentItemChanged", self.CurrentItem)
		self:DispatchEvent ("StackChanged")
	end
end