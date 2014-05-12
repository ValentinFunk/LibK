 local PANEL = {}

function PANEL:Init ()
	self.Items = {}
	self.ItemsById = {}
	
	self.HoveredItem = nil
	self:SetTall (28)
	
	self.MouseCaptured = false
	
	self.VPanelContainer = Gooey.VPanelContainer (self)
end

function PANEL:AddButton (text, callback)
	local button = Gooey.ToolbarButton (text, callback)
	self.VPanelContainer:AddControl (button)
	button:SetId (text)
	
	self.Items [#self.Items + 1] = button
	self.ItemsById [button:GetId ()] = button
	
	return button
end

function PANEL:AddComboBox ()
	local comboBox = Gooey.ToolbarComboBox ()
	self.VPanelContainer:AddControl (comboBox)
	
	self.Items [#self.Items + 1] = comboBox
	
	return comboBox:GetComboBox ()
end

function PANEL:AddSeparator ()
	local separator = Gooey.ToolbarSeparator ()
	self.VPanelContainer:AddControl (separator)
	self.Items [#self.Items + 1] = separator
	
	return separator
end

function PANEL:AddSplitButton (text, callback)
	local button = Gooey.ToolbarSplitButton (text, callback)
	self.VPanelContainer:AddControl (button)
	button:SetId (text)
	
	self.Items [#self.Items + 1] = button
	self.ItemsById [button:GetId ()] = button
	
	return button
end

function PANEL:Clear ()
	self.VPanelContainer:Clear ()
end

function PANEL:GetItemById (id)
	return self.ItemsById [id]
end

function PANEL:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, GLib.Colors.Silver)
	
	self.VPanelContainer:Paint (Gooey.RenderContext)
end

function PANEL:PerformLayout ()
	local x = 2
	for _, item in ipairs (self.Items) do
		item:SetLeft (x)
		item:SetTop ((self:GetTall () - item:GetHeight ()) * 0.5)
		x = x + item:GetWidth ()
	end
end

-- Event handlers
function PANEL:OnRemoved ()
	self:Clear ()
end

Gooey.Register ("GToolbar", PANEL, "GPanel")