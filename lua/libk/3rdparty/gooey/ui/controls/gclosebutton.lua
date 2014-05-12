local PANEL = {}
Gooey.CloseButton = Gooey.MakeConstructor (PANEL, Gooey.VPanel)

function PANEL:ctor (text)
	self:Init ()
end

function PANEL:Init ()
	self.Icon = nil
	self.Text = text
	
	self.DrawBackground = true
	
	self:SetWidth (14)
	self:SetHeight (14)
	
	self:SetShouldCaptureMouse (false)
	
	self.Gray707070 = Color (0x70, 0x70, 0x70, 0xFF)
end

function PANEL:Paint (renderContext)
	if self:ShouldDrawBackground () and
	   self:IsEnabled () and self:IsHovered () then
		-- Enabled and hovered
		if self:IsPressed () then
			draw.RoundedBox (4, 0, 0, self.Width, self.Height, GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.DarkGray)
		else
			draw.RoundedBox (4, 0, 0, self.Width, self.Height, GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.LightGray)
		end
	end
	
	if self:IsEnabled () then
		-- Enabled
		if self:IsPressed () then
			Gooey.Glyphs.Draw ("close", renderContext, GLib.Colors.Gray, 1, 1, self.Width, self.Height)
		elseif self:IsHovered () then
			Gooey.Glyphs.Draw ("close", renderContext, GLib.Colors.Gray, 0, 0, self.Width, self.Height)
		else
			if self:GetParent () and not self:GetParent ():IsSelected () then
				-- Rendering on an inactive tab header
				Gooey.Glyphs.Draw ("close", renderContext, self.Gray707070, 0, 0, self.Width, self.Height)
			else
				Gooey.Glyphs.Draw ("close", renderContext, GLib.Colors.DarkGray, 0, 0, self.Width, self.Height)
			end
		end
	else
		-- Disabled
		Gooey.Glyphs.Draw ("close", renderContext, GLib.Colors.Gray, 0, 0, self.Width, self.Height)
	end
end

function PANEL:SetShouldDrawBackground (shouldDrawBackground)
	self.DrawBackground = shouldDrawBackground
end

function PANEL:ShouldDrawBackground ()
	return self.DrawBackground
end