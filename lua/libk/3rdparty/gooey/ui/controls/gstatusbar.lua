local PANEL = {}

function PANEL:Init ()
	self:SetTall (24)
	
	self.Panels = {}
	self.ResizeGrip = vgui.Create ("GResizeGrip", self)
	
	self.Text = ""
	
	self:SetBackgroundColor (GLib.Colors.Silver)
	
	self:AddEventListener ("BackgroundColorChanged",
		function (_, backgroundColor)
			for _, panel in ipairs (self.Panels) do
				panel:SetBackgroundColor (backgroundColor)
			end
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			if self:GetPanelCount () == 0 then return end
			self:GetPanel (1):SetText (text)
		end
	)
end

function PANEL:AddPanel (text)
	return self:AddTextPanel (text)
end

function PANEL:AddCustomPanel (contents, class)
	local panel = vgui.Create (class or "GStatusBarPanel", self)
	self.Panels [#self.Panels + 1] = panel
	panel:SetContents (contents) -- has to be done before SetBackgroundColor so that the background color is applied recursively
	panel:SetSizingMethod (Gooey.SizingMethod.ExpandToFit)
	panel:SetBackgroundColor (self:GetBackgroundColor ())
	
	panel:AddEventListener ("VisibleChanged", self:GetHashCode (),
		function ()
			self:InvalidateLayout ()
		end
	)
	
	self:InvalidateLayout ()
	return panel
end

function PANEL:AddComboBoxPanel ()
	local comboBox = vgui.Create ("GStatusBarComboBox")
	return self:AddCustomPanel (comboBox, "GStatusBarComboBoxPanel")
end

function PANEL:AddProgressPanel ()
	local progress = vgui.Create ("GProgressBar")
	return self:AddCustomPanel (progress)
end

function PANEL:AddTextPanel (text)
	local label = vgui.Create ("DLabel")
	label:SetText (text or "")
	label:SetTextColor (GLib.Colors.Black)
	label:SetTextInset (4, 0)
	label:SetContentAlignment (4)
	return self:AddCustomPanel (label)
end

function PANEL:Clear ()
	for _, panel in ipairs (self.Panels) do
		panel:Remove ()
	end
	self.Panels = {}
end

function PANEL:GetPanel (index)
	return self.Panels [index]
end

function PANEL:GetPanelCount ()
	return #self.Panels
end

function PANEL:GetText ()
	if self:GetPanelCount () == 0 then return self.Text or "" end
	return self:GetPanel (1):GetText ()
end

function PANEL:Paint (w, h)
	draw.RoundedBoxEx (4, 0, 0, w, h, self:GetBackgroundColor (), false, false, true, true)
	
	if self:GetPanelCount () == 0 then
		surface.SetFont ("DermaDefault")
		local w, h = surface.GetTextSize (self:GetText ())
		surface.SetTextColor (self:GetTextColor ())
		surface.SetTextPos (4, (self:GetTall () - h) * 0.5)
		surface.DrawText (self:GetText ())
	else
		surface.SetDrawColor (GLib.Colors.Gray)
		for i = 2, self:GetPanelCount () do
			if self:GetPanel (i):IsVisible () then
				local x = self:GetPanel (i):GetPos ()
				surface.DrawLine (x - 2, 2, x - 2, self:GetTall () - 1)
			end
		end
	end
	
	local x = self.ResizeGrip:GetPos ()
	surface.SetDrawColor (GLib.Colors.Gray)
	surface.DrawLine (x - 2, 2, x - 2, self:GetTall () - 1)
end

function PANEL:PerformLayout ()
	self:SetWide (self:GetParent ():GetWide () - 4)
	self:SetPos (2, self:GetParent ():GetTall () - self:GetTall () - 2)
	
	if self.ResizeGrip then
		self.ResizeGrip:SetSize (self:GetTall (), self:GetTall ())
		self.ResizeGrip:PerformLayout ()
		
		-- Calculate panel widths
		local x = 0
		local w = self:GetWide () - self.ResizeGrip:GetWide ()
		local remainingWidth = w
		local index = 1
		
		local dividerWidth = 3
		
		local expandToFitPanelCount = 0
		for i = 1, self:GetPanelCount () do
			local panel = self:GetPanel (i)
			if panel:IsVisible () then
				local panelWidth = 0
				local sizingMethod = panel:GetSizingMethod ()
				if sizingMethod == Gooey.SizingMethod.Fixed then
					panelWidth = math.min (remainingWidth - dividerWidth, panel:GetFixedWidth ())
				elseif sizingMethod == Gooey.SizingMethod.Percentage then
					panelWidth = math.min (remainingWidth - dividerWidth, math.floor (panel:GetPercentageWidth () / 100 * w + 0.5))
				else
					expandToFitPanelCount = expandToFitPanelCount + 1
				end
				panel:SetWide (panelWidth)
				
				if sizingMethod ~= Gooey.SizingMethod.ExpandToFit then
					x = x + panelWidth + dividerWidth
					remainingWidth = remainingWidth - panelWidth - dividerWidth
				end
			end
		end
		
		-- Distribute remaining width among panels which expand to fit
		local dividedWidth = (remainingWidth - expandToFitPanelCount * dividerWidth) / expandToFitPanelCount
		for i = 1, self:GetPanelCount () do
			local panel = self:GetPanel (i)
			if panel:IsVisible () then
				if panel:GetSizingMethod () == Gooey.SizingMethod.ExpandToFit then
					panel:SetWidth (dividedWidth)
				end
			end
		end
		
		-- Layout panels
		local x = 0
		for i = 1, self:GetPanelCount () do
			local panel = self:GetPanel (i)
			if panel:IsVisible () and panel:GetWide () > 0 then
				panel:SetPos (x, 0)
				panel:SetTall (self:GetTall ())
				
				x = x + panel:GetWide () + dividerWidth
			end
		end
	end
end

-- Event handlers
function PANEL:OnRemoved ()
	self:Clear ()
end

Gooey.Register ("GStatusBar", PANEL, "GPanel")