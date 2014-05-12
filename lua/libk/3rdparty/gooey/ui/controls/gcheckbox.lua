local PANEL = {}

--[[
	Events:
		CheckStateChanged (bool checked)
			Fired when this checkbox has been checked or unchecked.
]]

function PANEL:Init ()
	self.Checked = false
	
	self:SetContentAlignment (4)
	self:SetText ("")
	self:SetTextColor (self:GetSkin ().Colours.Label.Default)
end

function PANEL:IsChecked ()
	return self.Checked
end

function PANEL:Paint (w, h)
	local w = 15
	local h = 15
	
	if self:IsChecked () then
		if self:IsEnabled () then
			self:GetSkin ().tex.Checkbox_Checked (0, 0, w, h)
		else
			self:GetSkin ().tex.CheckboxD_Checked (0, 0, w, h)
		end
	else
		if self:IsEnabled () then
			self:GetSkin ().tex.Checkbox (0, 0, w, h)
		else
			self:GetSkin ().tex.CheckboxD (0, 0, w, h)
		end
	end
	return false
end

function PANEL:PerformLayout ()
	self:SetTextInset (self:GetTall () + 4, 0)
end

function PANEL:SetChecked (checked)
	if self.Checked == checked then return end
	self.Checked = checked
	self:DispatchEvent ("CheckStateChanged", checked)
end

PANEL.SetValue = PANEL.SetChecked

-- Event handlers
function PANEL:DoClick ()
	if not self:IsEnabled () then return end
	self:SetChecked (not self.Checked)
end

Gooey.Register ("GCheckbox", PANEL, "GButton")