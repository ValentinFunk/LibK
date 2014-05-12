local self = {}
Gooey.UndoRedoController = Gooey.MakeConstructor (self, Gooey.ButtonController)

--[[
	Events:
		CanRedoChanged (canRedo)
			Fired when the redo command has been enabled or disabled.
		CanUndoChanged (canUndo)
			Fired when the undo command has been enabled or disabled.
]]

function self:ctor (undoRedoStack)
	self.UndoRedoStack = nil
	
	self:RegisterAction ("Redo", "CanRedoChanged")
	self:RegisterAction ("Undo", "CanUndoChanged")
	
	-- Event handlers
	self.StackChanged = function ()
		self:UpdateButtonState ()
	end
	
	self:SetUndoRedoStack (undoRedoStack)
end

function self:AddRedoAction (action)
	self:AddAction ("Redo", action)
end

function self:AddRedoButton (button)
	self:AddButton ("Redo", button)
	
	button:AddEventListener ("Click",
		function ()
			if not self.UndoRedoStack then return end
			self.UndoRedoStack:Redo ()
		end
	)
end

function self:AddUndoAction (action)
	self:AddAction ("Undo", action)
end

function self:AddUndoButton (button)
	self:AddButton ("Undo", button)
	
	button:AddEventListener ("Click",
		function ()
			if not self.UndoRedoStack then return end
			self.UndoRedoStack:Undo ()
		end
	)
end

function self:CanRedo ()
	return self:CanPerformAction ("Redo")
end

function self:CanUndo ()
	return self:CanPerformAction ("Undo")
end

function self:GetUndoRedoStack ()
	return self.UndoRedoStack
end

function self:SetUndoRedoStack (undoRedoStack)
	if self.UndoRedoStack then
		self.UndoRedoStack:RemoveEventListener ("StackChanged", self:GetHashCode ())
	end
	
	self.UndoRedoStack = undoRedoStack
	
	if self.UndoRedoStack then
		self.UndoRedoStack:AddEventListener ("StackChanged", self:GetHashCode (), self.StackChanged)
	end
	
	self:UpdateButtonState ()
end

-- Internal, do not call
function self:UpdateButtonState ()
	self:UpdateRedoState ()
	self:UpdateUndoState ()
end

function self:UpdateRedoState ()
	self:UpdateActionState ("Redo", self.UndoRedoStack and self.UndoRedoStack:CanRedo () or false)
end

function self:UpdateUndoState ()
	self:UpdateActionState ("Undo", self.UndoRedoStack and self.UndoRedoStack:CanUndo () or false)
end

-- Event handlers
self.StackChanged = Gooey.NullCallback