local PANEL = {}

function PANEL:Init ()
	self.MenuStrip = nil
	
	self:SetIsMenu (true)
	self:SetDrawBackground (false)
	
	self.Menu = nil
	
	self:AddEventListener ("MouseDown",
		function (_)
			if not self:IsEnabled () then return end
			if not self:GetMenu () then return end
			
			if self:GetMenu ():IsVisible () or
			   self:GetMenu ().CloseTime == CurTime () then
				self:GetMenu ():Hide ()
				return
			end
			
			local x, y = self:LocalToScreen (0, 1)
			self:GetMenu ():Show (self, x, y, self:GetWide (), self:GetTall () - 2, Gooey.Orientation.Vertical)
		end
	)
	
	self:AddEventListener ("MouseEnter",
		function (_)
			if not self:IsEnabled () then return end
			if not self:GetMenuStrip () then return end
			if not self:GetMenu () then return end
			
			if not self:GetMenuStrip ():IsMenuOpen () then return end
			
			self:GetMenuStrip ():CloseMenus ()
			
			local x, y = self:LocalToScreen (0, 1)
			self:GetMenu ():Show (self, x, y, self:GetWide (), self:GetTall () - 2, Gooey.Orientation.Vertical)
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_)
			surface.SetFont ("DermaDefault")
			self:SetWide (12 + surface.GetTextSize (self:GetText ()))
		end
	)
end

function PANEL:GetMenu ()
	return self.Menu
end

function PANEL:GetMenuStrip ()
	if not self.MenuStrip then return nil end
	if not self.MenuStrip:IsValid () then return nil end
	return self.MenuStrip
end

function PANEL:IsMenuOpen ()
	if not self:GetMenu () then return false end
	return self:GetMenu ():IsVisible ()
end

function PANEL:Paint (w, h)
	if self:IsEnabled () and (self:IsHovered () or self:IsMenuOpen ()) then
		-- Enabled and hovered
		if self:IsPressed () or self:IsMenuOpen () then
			draw.RoundedBox (4, 0, 0, w,     h,     GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, w - 2, h - 2, GLib.Colors.DarkGray)
		else
			draw.RoundedBox (4, 0, 0, w,     h,     GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, w - 2, h - 2, GLib.Colors.LightGray)
		end
	end
	
	surface.SetFont ("DermaDefault")
	local _, h = surface.GetTextSize (self:GetText ())
	local y = 0.5 * (self:GetTall () - h)
	if self:IsEnabled () then
		surface.SetTextColor (GLib.Colors.Black)
		surface.SetTextPos (6, y)
	else
		surface.SetTextColor (GLib.Colors.White)
		surface.SetTextPos (7, y + 1)
		surface.DrawText (self:GetText ())
		surface.SetTextColor (GLib.Colors.Gray)
		surface.SetTextPos (6, y)
	end
	surface.DrawText (self:GetText ())
end

function PANEL:SetMenu (menu)
	self:UnhookMenu (self.Menu)
	self.Menu = menu
	self:HookMenu (self.Menu)
end

function PANEL:SetMenuStrip (menuStrip)
	self.MenuStrip = menuStrip
end

-- Event handlers
function PANEL:OnRemoved ()
	self:SetMenu (nil)
end

-- Internal, do not call
function PANEL:HookMenu (menu)
	if not menu then return end
	
	menu:AddEventListener ("MenuClosed",
		function (_)
			menu.CloseTime = CurTime ()
		end
	)
end

function PANEL:UnhookMenu (menu)
	if not menu then return end
	
	menu:RemoveEventListener ("MenuClosed",     self:GetHashCode ())
end

Gooey.Register ("GMenuStripItem", PANEL, "GPanel")