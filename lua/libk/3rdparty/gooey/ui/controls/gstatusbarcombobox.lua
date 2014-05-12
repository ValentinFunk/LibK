local PANEL = {}

--[[
	Events:
		MenuOpening (GMenu menu)
			Fired when the menu is opening.
]]

local textArrowSpacing = 2
local arrowWidth = 14
function PANEL:Init ()
	self.Label = vgui.Create ("DLabel", self)
	self.Label:SetText ("")
	self.Label:SetTextColor (GLib.Colors.Black)
	self.Label:SetTextInset (4, 0)
	self.Label:SetContentAlignment (4)
	
	self.Menu = Gooey.Menu ()
	self.MenuDownwards = true
	self.MenuOpen = false
	self.MenuCloseTime = 0
	self.Menu:AddEventListener ("MenuOpening",
		function ()
			self:DispatchEvent ("MenuOpening", self.Menu)
		end
	)
	self.Menu:AddEventListener ("MenuClosed",
		function ()
			self.MenuOpen = false
			self.MenuCloseTime = CurTime ()
			if not self:IsPressed () then
				self.Label:SetPos (0, 0)
			end
		end
	)
	
	self:AddEventListener ("MouseDown",
		function (_, mouseCode)
			if mouseCode == MOUSE_LEFT then
				self.Label:SetPos (1, 1)
				
				if self.MenuCloseTime ~= CurTime () then
					if not self.Menu then return end
					self.MenuOpen = true
					
					local x, y = self:LocalToScreen (0, 1)
					local menu = self.Menu:Show (self, x, y, self:GetWide (), self:GetTall () - 2, Gooey.Orientation.Vertical)
					self.MenuDownwards = menu:GetAnchorVerticalAlignment () == Gooey.VerticalAlignment.Top
				end
			end
		end
	)
	
	self:AddEventListener ("MouseEnter",
		function (_, mouseCode)
			if self:IsPressed () then
				self.Label:SetPos (1, 1)
			end
		end
	)
	
	self:AddEventListener ("MouseLeave",
		function (_, mouseCode)
			if not self.MenuOpen then
				self.Label:SetPos (0, 0)
			end
		end
	)
	
	self:AddEventListener ("MouseUp",
		function (_, mouseCode)
			if mouseCode == MOUSE_LEFT and not self.MenuOpen then
				self.Label:SetPos (0, 0)
			end
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			self.Label:SetText (text)
		end
	)
end

function PANEL:Paint (w, h)
	surface.SetFont ("DermaDefault")
	local textWidth = surface.GetTextSize (self:GetText ())
	local boxWidth = math.min (w, 4 + textWidth + textArrowSpacing + arrowWidth)
	textWidth = boxWidth - 4 - textArrowSpacing - arrowWidth
	
	if self:IsHovered () or self.MenuOpen then
		draw.RoundedBoxEx (4, 0, 0, boxWidth, h, GLib.Colors.Gray, self.MenuDownwards or not self.MenuOpen, self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen)
		if self:IsPressed () or self.MenuOpen then
			draw.RoundedBoxEx (4, 1, 1, boxWidth - 2, h - 2, GLib.Colors.DarkGray,       self.MenuDownwards or not self.MenuOpen, self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen)
		else
			draw.RoundedBoxEx (4, 1, 1, boxWidth - 2, h - 2, self:GetBackgroundColor (), self.MenuDownwards or not self.MenuOpen, self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen, not self.MenuDownwards or not self.MenuOpen)
		end
	else
		draw.RoundedBoxEx (4, 4 + textWidth + textArrowSpacing,     0, arrowWidth,     h,     GLib.Colors.Gray,           true, self.MenuDownwards or not self.MenuOpen, true, not self.MenuDownwards or not self.MenuOpen)
		draw.RoundedBoxEx (4, 4 + textWidth + textArrowSpacing + 1, 1, arrowWidth - 2, h - 2, self:GetBackgroundColor (), true, self.MenuDownwards or not self.MenuOpen, true, not self.MenuDownwards or not self.MenuOpen)
	end
	
	local arrowColor = self:IsEnabled () and GLib.Colors.Black or GLib.Colors.Gray
	if (self:IsHovered () and self:IsPressed ()) or self.MenuOpen then
		Gooey.Glyphs.Draw ("down", Gooey.RenderContext, arrowColor, 4 + textWidth + textArrowSpacing + 1, 1, arrowWidth, h)
	else
		Gooey.Glyphs.Draw ("down", Gooey.RenderContext, arrowColor, 4 + textWidth + textArrowSpacing + 0, 0, arrowWidth, h)
	end
end

function PANEL:PerformLayout ()
	if self:IsPressed () or self.MenuOpen then
		self.Label:SetPos (1, 1)
	else
		self.Label:SetPos (0, 0)
	end
	self.Label:SetSize (self:GetWide () - textArrowSpacing - arrowWidth, self:GetTall ())
end

-- Event handlers
function PANEL:OnRemoved ()
	self.Menu:dtor ()
end

Gooey.Register ("GStatusBarComboBox", PANEL, "GPanel")