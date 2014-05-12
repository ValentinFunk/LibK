local PANEL = {}
Gooey.ToolbarSplitButton = Gooey.MakeConstructor (PANEL, Gooey.ToolbarItem)

function PANEL:ctor (text)
	self:Init ()
	
	self.Text = ""
	self.Width = 36
	self.Height = 24
	
	self.DropDownMenu = Gooey.Menu ()
	self.DropDownMenuAlignment = Gooey.VerticalAlignment.Top
	self.DropDownMenuOpen = false
	self.DropDownCloseTime = 0
	self.DropDownMenu:AddEventListener ("MenuClosed",
		function (_)
			self.DropDownMenuOpen = false
			self.DropDownCloseTime = CurTime ()
			self:DispatchEvent ("DropDownClosed", self.DropDownMenu)
		end
	)
	
	self:AddEventListener ("MouseDown", self:GetHashCode (),
		function (_, mouseCode, x, y)
			local buttonWidth = self.Height
			local rightWidth = self.Width - self.Height
			if x < buttonWidth then
				self:SetPressed (true)
			elseif self:IsEnabled () then
				if not self.DropDownMenu then return end
				if self.DropDownCloseTime ~= CurTime () then
					self.DropDownMenuOpen = true
					self:DispatchEvent ("DropDownOpening", self.DropDownMenu)
					
					local x, y = self:LocalToScreen (0, 1)
					local w = self:GetWidth ()
					local h = self:GetHeight () - 2
					local menu = self.DropDownMenu:Show (self, x, y, w, h, Gooey.Orientation.Vertical)
					self.DropDownMenuAlignment = menu:GetAnchorVerticalAlignment ()
				end
			end
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			self:SetToolTipText (text)
		end
	)
	
	self:SetText (text)
end

function PANEL:Init ()
	self.Icon = nil
end

function PANEL:GetIcon ()
	return self.Icon
end

function PANEL:Paint (renderContext)
	local buttonWidth = self.Height
	local rightWidth = self.Width - self.Height
	
	local roundTops    = not self.DropDownMenuOpen or self.DropDownMenuAlignment == Gooey.VerticalAlignment.Top
	local roundBottoms = not self.DropDownMenuOpen or self.DropDownMenuAlignment == Gooey.VerticalAlignment.Bottom
	
	if self:IsEnabled () and (self:IsHovered () or self.DropDownMenuOpen) then
		-- Enabled and hovered
		if self:IsPressed () then
			draw.RoundedBoxEx (4, 0, 0, self.Width,     self.Height,     GLib.Colors.Gray,      roundTops, roundTops, roundBottoms, roundBottoms)
			draw.RoundedBoxEx (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.DarkGray,  roundTops, roundTops, roundBottoms, roundBottoms)
		else
			draw.RoundedBoxEx (4, 0, 0, self.Width,     self.Height,     GLib.Colors.Gray,      roundTops, roundTops, roundBottoms, roundBottoms)
			draw.RoundedBoxEx (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.LightGray, roundTops, roundTops, roundBottoms, roundBottoms)
		end
		surface.SetDrawColor (GLib.Colors.Gray)
		surface.DrawLine (buttonWidth, 0, buttonWidth, self.Height)
	end
	
	local dropDownArrowColor = self:IsEnabled () and GLib.Colors.Black or GLib.Colors.Gray
	if self.DropDownMenuOpen then
		draw.RoundedBoxEx (4, buttonWidth,     0, rightWidth,     self.Height,     GLib.Colors.Gray,     false, roundTops, false, roundBottoms)
		draw.RoundedBoxEx (4, buttonWidth + 1, 1, rightWidth - 2, self.Height - 2, GLib.Colors.DarkGray, false, roundTops, false, roundBottoms)
		Gooey.Glyphs.Draw ("down", renderContext, dropDownArrowColor, self.Height + 1, 1, rightWidth, self.Height)
	else
		Gooey.Glyphs.Draw ("down", renderContext, dropDownArrowColor, self.Height    , 0, rightWidth, self.Height)
	end
	
	if self.Icon then
		local image = Gooey.ImageCache:GetImage (self.Icon)
		if self:IsEnabled () then
			-- Enabled
			if self:IsPressed () then
				image:Draw (renderContext, (buttonWidth - image:GetWidth ()) * 0.5 + 1, (self.Height - image:GetHeight ()) * 0.5 + 1)
			else
				image:Draw (renderContext, (buttonWidth - image:GetWidth ()) * 0.5, (self.Height - image:GetHeight ()) * 0.5)
			end
		else
			-- Disabled
			image:Draw (renderContext, (buttonWidth - image:GetWidth ()) * 0.5, (self.Height - image:GetHeight ()) * 0.5, 0, 0, 0, 160)
			image:Draw (renderContext, (buttonWidth - image:GetWidth ()) * 0.5, (self.Height - image:GetHeight ()) * 0.5, nil, nil, nil, 32)
		end
	end
end

function PANEL:SetIcon (icon)
	self.Icon = icon
	
	return self
end

-- Event handlers
function PANEL:OnRemoved ()
	self.DropDownMenu:dtor ()
end