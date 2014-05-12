local self = {}
Gooey.HistoryItem = Gooey.MakeConstructor (self)

function self:ctor ()
	self.Description = "<action>"
	
	self.ChainedItem = nil
end

function self:ChainItem (historyItem)
	if not historyItem then return end
	
	if self.ChainedItem then
		self.ChainedItem:ChainItem (historyItem)
		return
	else
		self.MoveForwardFunction = self.MoveForward
		self.MoveBackFunction    = self.MoveBack
		
		self.MoveForward = self.MoveForwardChain
		self.MoveBack    = self.MoveBackChain
	end
	self.ChainedItem = historyItem
end

function self:GetDescription ()
	return self.Description
end

function self:MoveForward ()
end

function self:SetDescription (description)
	self.Description = description or "<action>"
end

function self:MoveBack ()
end

-- Internal, do not call
function self:MoveForwardChain ()
	self:MoveForwardFunction ()
	if self.ChainedItem then
		self.ChainedItem:MoveForward ()
	end
end

function self:MoveBackChain ()
	if self.ChainedItem then
		self.ChainedItem:MpveBack ()
	end
	self:MoveBackFunction ()
end