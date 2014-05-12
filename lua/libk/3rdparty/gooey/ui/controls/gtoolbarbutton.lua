local PANEL = {}
Gooey.ToolbarButton = Gooey.MakeConstructor (PANEL, Gooey.ToolbarItem)

function PANEL:ctor (text)
	self:Init ()
	
	self.Text = ""
	self.Width = 24
	self.Height = 24
	
	self:AddEventListener ("ActionChanged",
		function (_, actionName)
			local actionMap, control = self:GetActionMap ()
			if not actionMap then return end
			
			local action = actionMap:GetAction (actionName, control)
			if not action then return end
			
			if action and action:GetIcon () then
				self:SetIcon (action:GetIcon ())
			end
		end
	)
	
	self:AddEventListener ("Click",
		function (_, text)
			self:RunAction ()
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
	if self:IsEnabled () and self:IsHovered () then
		-- Enabled and hovered
		if self:IsPressed () then
			draw.RoundedBox (4, 0, 0, self.Width,     self.Height,     GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.DarkGray)
		else
			draw.RoundedBox (4, 0, 0, self.Width,     self.Height,     GLib.Colors.Gray)
			draw.RoundedBox (4, 1, 1, self.Width - 2, self.Height - 2, GLib.Colors.LightGray)
		end
	end
	if self.Icon then
		local image = Gooey.ImageCache:GetImage (self.Icon)
		if self:IsEnabled () then
			-- Enabled
			if self:IsPressed () then
				image:Draw (renderContext, (self.Width - image:GetWidth ()) * 0.5 + 1, (self.Height - image:GetHeight ()) * 0.5 + 1)
			else
				image:Draw (renderContext, (self.Width - image:GetWidth ()) * 0.5,     (self.Height - image:GetHeight ()) * 0.5)
			end
		else
			-- Disabled
			image:Draw (renderContext, (self.Width - image:GetWidth ()) * 0.5, (self.Height - image:GetHeight ()) * 0.5,   0,   0,   0, 160)
			image:Draw (renderContext, (self.Width - image:GetWidth ()) * 0.5, (self.Height - image:GetHeight ()) * 0.5, nil, nil, nil,  32)
		end
	end
end

function PANEL:SetIcon (icon)
	self.Icon = icon
	
	return self
end