local self = {}
Gooey.IHistoryStack = Gooey.MakeConstructor (self)

--[[
	Events:
		ItemPushed (HistoryItem historyItem)
			Fired when a HistoryItem has been added to this HistoryStack.
		MovedForward (HistoryItem historyItem)
			Fired when the state has been moved forward.
		MovedBack (HistoryItem historyItem)
			Fired when the state has been moved back.
		StackChanged ()
			Fired when a HistoryItem has been added or the state has been moved forward or back.
		StackCleared ()
			Fired when this UndoRedoStack has been cleared.
]]

function self:ctor ()
	Gooey.EventProvider (self)
end

function self:CanMoveForward ()
	GLib.Error ("IHistoryStack:CanMoveForward : Not implemented.")
end

function self:CanMoveBack ()
	GLib.Error ("IHistoryStack:CanMoveBack : Not implemented.")
end

function self:Clear ()
	GLib.Error ("IHistoryStack:Clear : Not implemented.")
end

function self:GetNextDescription ()
	GLib.Error ("IHistoryStack:GetNextDescription : Not implemented.")
end

function self:GetNextItem ()
	GLib.Error ("IHistoryStack:GetNextItem : Not implemented.")
end

function self:GetNextStack ()
	GLib.Error ("IHistoryStack:GetNextStack : Not implemented.")
end

function self:GetPreviousDescription ()
	GLib.Error ("IHistoryStack:GetPreviousDescription : Not implemented.")
end

function self:GetPreviousItem ()
	GLib.Error ("IHistoryStack:GetPreviousItem : Not implemented.")
end

function self:GetPreviousStack ()
	GLib.Error ("IHistoryStack:GetPreviousStack : Not implemented.")
end

function self:Push (historyItem)
	GLib.Error ("IHistoryStack:Push : Not implemented.")
end

function self:MoveForward (count)
	GLib.Error ("IHistoryStack:MoveForward : Not implemented.")
end

function self:MoveBack (count)
	GLib.Error ("IHistoryStack:MoveBack : Not implemented.")
end