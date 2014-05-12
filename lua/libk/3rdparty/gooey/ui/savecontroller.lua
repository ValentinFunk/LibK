local self = {}
Gooey.SaveController = Gooey.MakeConstructor (self, Gooey.ButtonController)

--[[
	Events:
		CanSaveChanged (canSave)
			Fired when the save command has been enabled or disabled.
]]

function self:ctor (savable)
	self.Savable = nil
	
	self:RegisterAction ("Save", "CanSaveChanged")
	
	-- Event handlers
	self.CanSaveChanged = function ()
		self:UpdateSaveState ()
	end
	
	self:SetSavable (savable)
end

function self:AddSaveAction (action)
	self:AddAction ("Save", action)
end

function self:AddSaveButton (button)
	self:AddButton ("Save", button)
end

function self:CanSave ()
	return self:CanPerformAction ("Save")
end

function self:GetSavable ()
	return self.Savable
end

function self:SetSavable (savable)
	if self.Savable then
		self.Savable:RemoveEventListener ("CanSaveChanged", self:GetHashCode ())
	end
	
	self.Savable = savable
	
	if self.Savable then
		self.Savable:AddEventListener ("CanSaveChanged", self:GetHashCode (), self.CanSaveChanged)
	end
	
	self:UpdateButtonState ()
end

-- Internal, do not call
function self:UpdateButtonState ()
	self:UpdateSaveState ()
end

function self:UpdateSaveState ()
	self:UpdateActionState ("Save", self.Savable and self.Savable:CanSave () or false)
end

-- Event handlers
self.CanSaveChanged = Gooey.NullCallback