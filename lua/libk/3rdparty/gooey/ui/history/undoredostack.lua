local self = {}
Gooey.UndoRedoStack = Gooey.MakeConstructor (self, Gooey.HistoryStack)

--[[
	Events:
		ItemPushed (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been added to this UndoRedoStack.
		ItemRedone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been redone.
		ItemUndone (UndoRedoItem undoRedoItem)
			Fired when an UndoRedoItem has been undone.
		StackChanged ()
			Fired when an UndoRedoItem has been added, undone or redone.
		StackCleared ()
			Fired when this UndoRedoStack has been cleared.
]]

function self:ctor ()
	self:AddEventListener ("MovedForward",
		function (_, historyItem)
			self:DispatchEvent ("ItemRedone", historyItem)
		end
	)
	
	self:AddEventListener ("MovedBack",
		function (_, historyItem)
			self:DispatchEvent ("ItemUndone", historyItem)
		end
	)
end

-- IHistoryStack
function self:Push (historyItem)
	self.PreviousStack:Push (historyItem)
	self.NextStack:Clear ()
	
	self:DispatchEvent ("ItemPushed", self.PreviousStack.Top)
	self:DispatchEvent ("StackChanged")
end

function self:MoveForward (count)
	count = count or 1
	for i = 1, count do
		if self.NextStack.Count == 0 then return end
		
		self.NextStack.Top:Redo ()
		self.PreviousStack:Push (self.NextStack:Pop ())
		
		self:DispatchEvent ("ItemRedone", self.PreviousStack.Top)
		self:DispatchEvent ("MovedForward", self.PreviousStack.Top)
		self:DispatchEvent ("StackChanged")
	end
end

function self:MoveBack (count)
	count = count or 1
	for i = 1, count do
		if self.PreviousStack.Count == 0 then return end
		
		self.PreviousStack.Top:Undo ()
		self.NextStack:Push (self.PreviousStack:Pop ())
		
		self:DispatchEvent ("ItemUndone", self.NextStack.Top)
		self:DispatchEvent ("MovedBack", self.NextStack.Top)
		self:DispatchEvent ("StackChanged")
	end
end

-- UndoRedoStack
function self:CanRedo ()
	return self:CanMoveForward ()
end

function self:CanUndo ()
	return self:CanMoveBack ()
end

function self:GetRedoDescription ()
	return self:GetNextDescription ()
end

function self:GetRedoItem ()
	return self:GetNextItem ()
end

function self:GetRedoStack ()
	return self:GetNextStack ()
end

function self:GetUndoDescription ()
	return self:GetPreviousDescription ()
end

function self:GetUndoItem ()
	return self:GetPreviousItem ()
end

function self:GetUndoStack ()
	return self:GetPreviousStack ()
end

function self:Redo (count)
	self:MoveForward (count)
end

function self:Undo (count)
	self:MoveBack (count)
end