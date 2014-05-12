local PANEL = {}

--[[
	Events:
]]

function PANEL:Init ()
	self:SetAllowNonAsciiCharacters (true)
end

-- Compatibility with Derma skin's PaintTextEntry
function PANEL:HasFocus ()
	return self:IsFocused ()
end

-- Compatibility with spawn menu hooks
function PANEL:HasParent (control)
	return debug.getregistry ().Panel.HasParent (self, control)
end

function PANEL:GetText ()
	return debug.getregistry ().Panel.GetText (self)
end

function PANEL:SetText (text)
	if self:GetText () == text then return self end
	
	self.Text = text
	debug.getregistry ().Panel.SetText (self, text)
	
	self:DispatchEvent ("TextChanged", self.Text)
	
	return self
end

-- Event handlers
Gooey.CreateMouseEvents (PANEL)

function PANEL:OnTextChanged ()
	self.Text = self:GetText ()
	self:DispatchEvent ("TextChanged", self:GetText ())
end

Gooey.Register ("GTextEntry", PANEL, "DTextEntry") 