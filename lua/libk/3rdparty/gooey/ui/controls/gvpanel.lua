local PANEL = {}
Gooey.VPanel = Gooey.MakeConstructor (PANEL)

--[[
	Events:
		ActionChanged (actionName)
			Fired when this panel's action has changed.
		ActionMapChanged (ActionMap actionMap)
			Fired when this panel's action map has changed.
		BackgroundColorChanged (backgroundColor)
			Fired when this panel's background color has changed.
		EnabledChanged (enabled)
			Fired when this panel has been enabled or disabled.
		OwnerChanged (Panel oldOwner, Panel owner)
			Fired when this panel's owner has changed.
		ParentChanged (Panel oldParent, Panel parent)
			Fired when this panel's parent has changed.
		PositionChanged (x, y)
			Fired when this panel's position has changed.
		Removed ()
			Fired when this panel has been removed.
		TextChanged (text)
			Fired when this panel's text has changed.
		VisibleChanged (visible)
			Fired when this panel's visibility has changed.
]]


function PANEL:ctor ()
	PANEL.Init (self)
end

function PANEL:Init ()
	self.Id = ""
	
	self.Parent = nil
	self.Owner = nil
	self.Children = {}
	
	self.Enabled = true
	self.Visible = true
	
	self.Hovered = false
	self.Pressed = false
	self.ShouldCaptureMouse = false
	self.MouseCaptured = false
	
	-- Colors
	self.BackgroundColor = nil
	self.TextColor = nil
	
	-- Positioning
	self.X = 0
	self.Y = 0
	self.Width = 24
	self.Height = 24
	
	self.Text = ""
	
	-- ToolTip
	self.ToolTipText = nil
	self.ToolTipController = nil
	
	-- Actions
	self.Action    = nil
	self.ActionMap = nil
	
	self.LayoutValid = false
	
	Gooey.EventProvider (self)
	
	self:AddEventListener ("MouseLeave", self:GetHashCode (),
		function (_)
			if self:IsPressed () and not self:HasMouseCapture () then
				self:SetPressed (false)
			end
		end
	)
	
	self:AddEventListener ("MouseDown", self:GetHashCode (),
		function (_, mouseCode, x, y)
			if mouseCode == MOUSE_LEFT then
				self:SetPressed (true)
				if self.ShouldCaptureMouse then
					self:CaptureMouse (true)
				end
			end
		end
	)
	
	self:AddEventListener ("MouseUp", self:GetHashCode (),
		function (_, mouseCode, x, y)
			if mouseCode == MOUSE_LEFT then
				if self:IsPressed () then
					self:SetPressed (false)
					if self:ContainsPoint (x, y) and self:IsEnabled () then
						self:DispatchEvent ("Click")
					end
				end
				if self:HasMouseCapture () then
					self:CaptureMouse (false)
				end
			elseif mouseCode == MOUSE_RIGHT then
				if self:ContainsPoint (x, y) and self:IsEnabled () then
					self:DispatchEvent ("RightClick")
				end
			end
		end
	)
end

function PANEL:CaptureMouse (capture, control)
	control = control or self
	
	if not self:GetParent () then return end
	self:GetParent ():CaptureMouse (capture, control)
	
	self.MouseCaptured = capture
end

function PANEL:ContainsPoint (x, y)
	return x >= 0 and x < self:GetWidth () and
	       y >= 0 and y < self:GetHeight ()
end

function PANEL:DispatchAction (actionName, ...)
	local actionMap, control = self:GetActionMap ()
	if not actionMap then return end
	actionMap:Execute (actionName, control, ...)
end

function PANEL:GetAction ()
	return self.Action
end

function PANEL:GetActionMap ()
	if self.ActionMap then
		return self.ActionMap, self
	end
	
	local actionMap, control = nil, nil
	if self:GetOwner () and type (self:GetOwner ().GetActionMap) == "function" then
		actionMap, control = self:GetOwner ():GetActionMap ()
	end
	if actionMap then return actionMap, control end
	
	local parent = self:GetParent ()
	while parent and parent:IsValid () do
		if type (parent.GetActionMap) == "function" then
			actionMap, control = parent:GetActionMap ()
			if actionMap then return actionMap, control end
		end
		if type (parent.GetOwner) == "function" then
			local owner = parent:GetOwner ()
			if owner and owner:IsValid () and type (owner.GetActionMap) == "function" then
				actionMap, control = owner:GetActionMap ()
				if actionMap then return actionMap, control end
			end
		end
		parent = parent:GetParent ()
	end
	
	return nil, nil
end

function PANEL:GetBackgroundColor ()
	if not self.BackgroundColor then
		self.BackgroundColor = GLib.Colors.DarkGray
	end
	return self.BackgroundColor
end

function PANEL:GetBottom ()
	return self.Y + self.Height
end

function PANEL:GetHeight ()
	return self.Height
end

function PANEL:GetId ()
	return self.Id
end

function PANEL:GetLeft ()
	return self.X
end

function PANEL:GetOwner ()
	return self.Owner
end

function PANEL:GetParent ()
	return self.Parent
end

function PANEL:GetPos ()
	return self.X, self.Y
end

function PANEL:GetRight ()
	return self.X + self.Width
end

function PANEL:GetText ()
	return self.Text
end

function PANEL:GetTextColor ()
	return self.TextColor or GLib.Colors.Black
end

function PANEL:GetToolTipController ()
	if not self.ToolTipController then
		self.ToolTipController = Gooey.ToolTipController (self)
		self.ToolTipController:SetEnabled (false)
	end
	return self.ToolTipController
end

function PANEL:GetToolTipText ()
	return self.ToolTipText or ""
end

function PANEL:GetTop ()
	return self.Y
end

function PANEL:GetWidth ()
	return self.Width
end

function PANEL:HasMouseCapture ()
	return self.MouseCaptured
end

function PANEL:InvalidateLayout ()
	self.LayoutValid = false
end

function PANEL:IsEnabled ()
	return self.Enabled
end

function PANEL:IsHovered ()
	return self.Hovered
end

function PANEL:IsLayoutValid ()
	return self.LayoutValid
end

function PANEL:IsPressed ()
	return self.Pressed
end

function PANEL:IsValid ()
	return true
end

function PANEL:IsVisible ()
	return self.Visible
end

function PANEL:LocalToParent (x, y)
	return x + self.X, y + self.Y
end

function PANEL:LocalToScreen (x, y)
	local parentX, parentY = self:LocalToParent (x, y)
	if not self:GetParent () then return parentX, parentY end
	return self:GetParent ():LocalToScreen (parentX, parentY)
end

function PANEL:ParentToLocal (x, y)
	return x - self.X, y - self.Y
end

function PANEL:PerformLayout ()
end

function PANEL:Remove ()
	if self.OnRemoved then self:OnRemoved () end
	self:DispatchEvent ("Removed")
end

function PANEL:RunAction (...)
	if not self:GetAction () then return end
	self:DispatchAction (self:GetAction (), ...)
end

function PANEL:SetAction (action)
	if self.Action == action then return self end
	
	self.Action = action
	self:DispatchEvent ("ActionChanged", self.Action)
	
	return self
end

function PANEL:SetActionMap (actionMap)
	if self.ActionMap == actionMap then return self end
	
	self.ActionMap = actionMap
	self:DispatchEvent ("ActionMapChanged", self.ActionMap)
	
	return self
end

function PANEL:SetBackgroundColor (color)
	self.BackgroundColor = color
	self:DispatchEvent ("BackgroundColorChanged", self.BackgroundColor)
	return self
end

function PANEL:SetEnabled (enabled)
	if self.Enabled == enabled then return self end
	
	self.Enabled = enabled
	
	self:DispatchEvent ("EnabledChanged", enabled)
	return self
end

function PANEL:SetHeight (height)
	self.Height = height
	return self
end

function PANEL:SetHovered (hovered)
	if self.Hovered == hovered then return end
	self.Hovered = hovered
	
	if self.Hovered then
		self:DispatchEvent ("MouseEnter")
	else
		self:DispatchEvent ("MouseLeave")
	end
	return self
end

function PANEL:SetId (id)
	self.Id = id
	return self
end

function PANEL:SetLeft (x)
	if self.X == x then return self end
	
	self.X = x
	
	self:DispatchEvent ("PositionChanged", self.X, self.Y)
	
	return self
end

function PANEL:SetOwner (owner)
	if self.Owner == owner then return self end
	
	local oldParent = self.Owner
	self.Owner = owner
	
	self:DispatchEvent ("OwnerChanged", oldOwner, self.Owner)
	
	return self
end

function PANEL:SetParent (parent)
	if self.Parent == parent then return self end
	
	local oldParent = self.Parent
	self.Parent = parent
	
	self:DispatchEvent ("ParentChanged", oldParent, self.Parent)
	
	return self
end

function PANEL:SetPos (x, y)
	if self.X == x and self.Y == y then return self end
	
	self.X = x
	self.Y = y
	
	self:DispatchEvent ("PositionChanged", self.X, self.Y)
	
	return self
end

function PANEL:SetPressed (pressed)
	self.Pressed = pressed
	return self
end

function PANEL:SetShouldCaptureMouse (shouldCaptureMouse)
	self.ShouldCaptureMouse = shouldCaptureMouse
	return self
end

function PANEL:SetSize (width, height)
	self.Width = width
	self.Height = height
	return self
end

function PANEL:SetText (text)
	text = text or ""
	if self.Text == text then return self end
	
	self.Text = text
	self:DispatchEvent ("TextChanged", text)
	return self
end

function PANEL:SetTextColor (color)
	self.TextColor = color
	
	if type (color) == "number" then
		Gooey.PrintStackTrace ()
	end
	
	return self
end

function PANEL:SetToolTipText (text)
	if self.ToolTipText == text then return self end
	
	self.ToolTipText = text
	if not self.ToolTipController then
		self.ToolTipController = Gooey.ToolTipController (self)
	end
	self.ToolTipController:SetEnabled (self.ToolTipText ~= nil)
	
	return self
end

function PANEL:SetTop (y)
	if self.Y == y then return self end
	
	self.Y = y
	
	self:DispatchEvent ("PositionChanged", self.X, self.Y)
	
	return self
end

function PANEL:SetVisible (visible)
	if self.Visible == visible then return self end
	
	self.Visible = visible
	self:DispatchEvent ("VisibleChanged", visible)
	
	return self
end

function PANEL:SetWidth (width)
	self.Width = width
	return self
end

function PANEL:ValidateLayout ()
	self.LayoutValid = true
end