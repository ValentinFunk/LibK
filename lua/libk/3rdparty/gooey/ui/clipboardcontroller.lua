local self = {}
Gooey.ClipboardController = Gooey.MakeConstructor (self, Gooey.ButtonController)

--[[
	Events:
		ClipboardTextChanged (clipboardText)
			Fired when the clipboard text has changed.
		CanCopyChanged (canCopy)
			Fired when the copy command has been enabled or disabled.
		CanCutChanged (canCut)
			Fired when the cut command has been enabled or disabled.
		CanPasteChanged (canPaste)
			Fired when the paste command has been enabled or disabled.
]]

function self:ctor (clipboardTarget)
	self.ClipboardTarget = nil
	
	self:RegisterAction ("Copy",  "CanCopyChanged")
	self:RegisterAction ("Cut",   "CanCutChanged")
	self:RegisterAction ("Paste", "CanPasteChanged")
	
	Gooey.Clipboard:RegisterClipboardController (self)
	self:UpdateButtonState ()
	
	-- Event handlers
	self.CanCopyChanged = function ()
		self:UpdateCopyState ()
		self:UpdateCutState ()
	end
	
	self:AddEventListener ("ClipboardTextChanged", self:GetHashCode (),
		function ()
			self:UpdateButtonState ()
		end
	)
	
	self:SetClipboardTarget (clipboardTarget)
end

function self:dtor ()
	Gooey.Clipboard:UnregisterClipboardController (self)
end

function self:AddCopyAction (action)
	self:AddAction ("Copy", action)
end

function self:AddCopyButton (button)
	self:AddButton ("Copy", button)
end

function self:AddCutAction (action)
	self:AddAction ("Cut", action)
end

function self:AddCutButton (button)
	self:AddButton ("Cut", button)
end

function self:AddPasteAction (action)
	self:AddAction ("Paste", action)
end

function self:AddPasteButton (button)
	self:AddButton ("Paste", button)
end

function self:CanCopy ()
	return self:CanPerformAction ("Copy")
end

function self:CanCut ()
	return self:CanPerformAction ("Cut")
end

function self:CanPaste ()
	return self:CanPerformAction ("Paste")
end

function self:GetClipboardTarget ()
	return self.ClipboardTarget
end

function self:SetClipboardTarget (clipboardTarget)
	if self.ClipboardTarget then
		self.ClipboardTarget:RemoveEventListener ("CanCopyChanged", self:GetHashCode ())
	end
	
	self.ClipboardTarget = clipboardTarget
	
	if self.ClipboardTarget then
		self.ClipboardTarget:AddEventListener ("CanCopyChanged", self:GetHashCode (), self.CanCopyChanged)
	end
	
	self:UpdateButtonState ()
end

-- Internal, do not call
function self:UpdateButtonState ()
	self:UpdateCopyState ()
	self:UpdateCutState ()
	self:UpdatePasteState ()
end

function self:UpdateCopyState ()
	self:UpdateActionState ("Copy", self.ClipboardTarget ~= nil and self.ClipboardTarget:CanCopy ())
end

function self:UpdateCutState ()
	self:UpdateActionState ("Cut", self.ClipboardTarget ~= nil and self.ClipboardTarget:CanCut ())
end

function self:UpdatePasteState ()
	self:UpdateActionState ("Paste", not Gooey.Clipboard:IsEmpty () and self.ClipboardTarget ~= nil and self.ClipboardTarget:CanPaste ())
end

-- Event handlers
self.CanCopyChanged = Gooey.NullCallback