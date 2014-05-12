local self = {}
Gooey.UndoRedoItem = Gooey.MakeConstructor (self, Gooey.HistoryItem)

function self:ctor ()
end

-- HistoryItem
function self:MoveForward ()
	self:Redo ()
end

function self:MoveBack ()
	self:Undo ()
end

-- UndoRedoItem
function self:Redo ()
end

function self:Undo ()
end