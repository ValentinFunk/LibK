local self = {}
Gooey.BasePanel = self

GLib.Lua.NameCache:Index (self, "Gooey.BasePanel")

Gooey.LastFocusRequestPanel = nil
Gooey.LastFocusRequestTime  = 0

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
		FontChanged (font)
			Fired when this panel's font has changed.
		GotFocus ()
			Fired when this panel has acquired keyboard focus.
		HeightChanged (height)
			Fired when this panel's height has changed.
		LostFocus ()
			Fired when this panel has lost keyboard focus.
		OwnerChanged (Panel oldOwner, Panel owner)
			Fired when this panel's owner has changed.
		ParentChanged (Panel oldParent, Panel parent)
			Fired when this panel's parent has changed.
		PositionChanged (x, y)
			Fired when this panel's position has changed.
		Removed ()
			Fired when this panel has been removed.
		SizeChanged (width, height)
			Fired when this panel's size has changed.
		TextChanged (text)
			Fired when this panel's text has changed.
		VisibleChanged (visible)
			Fired when this panel's visibility has changed.
		WidthChanged (width)
			Fired when this panel's width has changed.
]]

function self:_ctor ()
	if self.BasePanelInitialized then return end
	self.BasePanelInitialized = true
	
	-- Control
	self.Owner = nil
	
	self.Enabled = true
	self.Pressed = false
	
	-- Focus
	self.Focusable = false
	self.Focused = false
	
	-- Colors
	self.BackgroundColor = nil
	self.TextColor = nil
	
	-- Text
	self.Text = self:GetText ()
	self.Font = nil
	
	-- Fade effects
	self.FadingOut = false
	self.FadeEndTime = SysTime ()
	self.FadeDuration = 1
	
	-- ToolTip
	self.ToolTipText = nil
	self.ToolTipController = nil
	
	-- Actions
	self.Action      = nil
	self.ActionMap   = nil
	self.KeyboardMap = nil
	
	Gooey.EventProvider (self)
end

-- Identity
function self:GetHashCode ()
	if not self.__HashCode then
		self.__HashCode = string.sub (tostring (self:GetTable ()), -8)
	end
	
	return self.__HashCode
end

-- Control
function self:Contains (control)
	if not control then return false end
	if not control:IsValid () then return false end
	
	local parent = control:GetParent ()
	while parent and parent:IsValid () do
		if parent == self then return true end
		parent = parent:GetParent ()
	end
	return false
end

function self:Create (class, parent)
	return vgui.Create (class, parent or self)
end

function self:CreateLabel (text)
	local label = vgui.Create ("DLabel", self)
	label:SetText (text)
	return label
end

function self:GetOwner ()
	return self.Owner
end

function self:GetWidth ()
	return self:GetWide ()
end

function self:GetHeight ()
	return self:GetTall ()
end

function self:IsEnabled ()
	return self.Enabled
end

function self:IsHovered ()
	return self.Hovered
end

function self:IsPressed ()
	return self.Pressed
end

function self:LocalToParent (x, y)
	return x + self.X, y + self.Y
end

function self:LocalToScreen (x, y)
	local parentX, parentY = self:LocalToParent (x, y)
	if not self:GetParent () then return parentX, parentY end
	return self:GetParent ():LocalToScreen (parentX, parentY)
end

function self:Remove ()
	if self:IsMarkedForDeletion () then return end
	
	-- Call OnRemoved for base classes
	local classTable = self
	while classTable do
		if classTable.OnRemoved then classTable.OnRemoved (self) end
		classTable = classTable.BaseClass
	end
	
	self:DispatchEvent ("Removed")
	
	for _, v in ipairs (self:GetChildren ()) do
		if not v:IsMarkedForDeletion () then
			v:Remove ()
		end
	end
	
	debug.getregistry ().Panel.Remove (self)
end

function self:SetEnabled (enabled)
	if self.Enabled == enabled then return self end
	
	self.Enabled = enabled
	self.m_bDisabled = not enabled -- for DPanel compatibility
	
	self:DispatchEvent ("EnabledChanged", enabled)
	return self
end

function self:SetHeight (height)
	if self:GetTall () == height then return self end
	
	debug.getregistry ().Panel.SetTall (self, height)
	self:DispatchEvent ("HeightChanged", self:GetTall ())
	self:DispatchEvent ("SizeChanged", self:GetWide (), self:GetTall ())
	
	return self
end

function self:SetOwner (owner)
	if self.Owner == owner then return self end
	
	local oldParent = self.Owner
	self.Owner = owner
	
	self:DispatchEvent ("OwnerChanged", oldOwner, self.Owner)
	
	return self
end

function self:SetParent (parent)
	if self:GetParent () == parent then return self end
	
	local oldParent = self:GetParent ()
	
	debug.getregistry ().Panel.SetParent (self, parent)
	self:DispatchEvent ("ParentChanged", oldParent, self:GetParent ())
	
	return self
end

function self:SetPos (x, y, ...)
	local currentX, currentY = self:GetPos ()
	if currentX == x and currentY == y then return self end
	
	debug.getregistry ().Panel.SetPos (self, x, y)
	self:DispatchEvent ("PositionChanged", x, y)
	
	return self
end

function self:SetSize (width, height, ...)
	if self:GetWide () == width and self:GetTall () == height then return self end
	
	debug.getregistry ().Panel.SetSize (self, width, height)
	self:DispatchEvent ("WidthChanged", self:GetWide ())
	self:DispatchEvent ("HeightChanged", self:GetTall ())
	self:DispatchEvent ("SizeChanged", self:GetWide (), self:GetTall ())
	
	return self
end

self.SetTall = self.SetHeight

function self:SetWide (width)
	if self:GetWide () == width then return self end
	
	debug.getregistry ().Panel.SetWide (self, width)
	self:DispatchEvent ("WidthChanged", self:GetWide ())
	self:DispatchEvent ("SizeChanged", self:GetWide (), self:GetTall ())
	
	return self
end

self.SetWidth = self.SetWide

-- Focus
function self:CanFocus ()
	return self.Focusable
end

function self:ContainsFocus ()
	if self:IsFocused () then return true end
	
	local focusedPanel = vgui.GetKeyboardFocus ()
	while focusedPanel and focusedPanel:IsValid () do
		if self == focusedPanel or
		   self:Contains (focusedPanel) then
			return true
		end
		focusedPanel = focusedPanel.GetOwner and focusedPanel:GetOwner ()
	end
	return false
end

function self:Focus ()
	debug.getregistry ().Panel.RequestFocus (self)
	
	Gooey.LastFocusRequestPanel = self
	Gooey.LastFocusRequestTime  = CurTime ()
end

function self:IsFocused ()
	if self.Focused then return true end
	if self == Gooey.LastFocusRequestPanel and
	   Gooey.LastFocusRequestTime == CurTime () then
		return true
	end
	
	local focusedPanel = vgui.GetKeyboardFocus ()
	while focusedPanel and focusedPanel:IsValid () do
		if self == focusedPanel then return true end
		focusedPanel = focusedPanel.GetOwner and focusedPanel:GetOwner ()
	end
	return false
end

function self:SetCanFocus (canFocus)
	self.Focusable = canFocus
	return self
end

-- Colors
function self:GetBackgroundColor ()
	if not self.BackgroundColor then
		self.BackgroundColor = self.m_Skin.control_color or GLib.Colors.DarkGray
	end
	return self.BackgroundColor
end

function self:GetTextColor ()
	return self.TextColor or GLib.Colors.Black
end

function self:SetBackgroundColor (color)
	self.BackgroundColor = color
	self:DispatchEvent ("BackgroundColorChanged", self.BackgroundColor)
	return self
end

function self:SetTextColor (color)
	if self.TextColor == color then return end
	if self.TextColor and
	   self.TextColor.r == color.r and 
	   self.TextColor.g == color.g and 
	   self.TextColor.b == color.b and 
	   self.TextColor.a == color.a then
		return
	end
	self.TextColor = color
	
	if type (color) == "number" then
		Gooey.PrintStackTrace ()
	end
	debug.getregistry ().Panel.SetFGColor (self, color)
	self.m_cTextColor = color -- for DTree_Node compatibility
	self.m_colText    = color -- for DLabel compatibility
	
	DLabel.ApplySchemeSettings (self)
	
	return self
end

-- Text
function self:GetFont ()
	return self.Font or debug.getregistry ().Panel.GetFont (self)
end

function self:GetText ()
	return self.Text or debug.getregistry ().Panel.GetText (self)
end

function self:SetFont (font)
	if self:GetFont () == font then return end
	
	self.Font = font
	self.m_FontName = font
	debug.getregistry ().Panel.SetFontInternal (self, font)
	self:DispatchEvent ("FontChanged", font)
	return self
end

function self:SetText (text)
	if self.Text == text then return self end
	
	self.Text = text
	debug.getregistry ().Panel.SetText (self, text)
	
	self:DispatchEvent ("TextChanged", self.Text)
	
	return self
end

-- Fade effects
function self:CancelFade ()
	self.FadingOut = false
end

function self:FadeOut ()
	if not self:IsVisible () then return end
	
	self.FadingOut = true
	self.FadeEndTime = SysTime () + self:GetAlpha () / 255 * self.FadeDuration
	self:FadeThink ()
end

-- ToolTip
function self:GetToolTipController ()
	if not self.ToolTipController then
		self.ToolTipController = Gooey.ToolTipController (self)
		self.ToolTipController:SetEnabled (false)
	end
	return self.ToolTipController
end

function self:GetToolTipText ()
	return self.ToolTipText or ""
end

function self:SetToolTipText (text)
	if self.ToolTipText == text then return self end
	
	self.ToolTipText = text
	if not self.ToolTipController then
		self.ToolTipController = Gooey.ToolTipController (self)
	end
	self.ToolTipController:SetEnabled (self.ToolTipText ~= nil)
	
	return self
end

-- Actions
function self:DispatchAction (actionName, ...)
	local actionMap, control = self:GetActionMap ()
	if not actionMap then return false end
	return actionMap:Execute (actionName, control, ...)
end

function self:DispatchKeyboardAction (keyCode, ctrl, shift, alt)
	if ctrl  == nil then ctrl    = input.IsKeyDown (KEY_LCONTROL) or input.IsKeyDown (KEY_RCONTROL) end
	if shift == nil then shift   = input.IsKeyDown (KEY_LSHIFT)   or input.IsKeyDown (KEY_RSHIFT)   end
	if alt   == nil then alt     = input.IsKeyDown (KEY_LALT)     or input.IsKeyDown (KEY_RALT)     end
	
	local keyHandled = false
	local keyboardMap = self:GetKeyboardMap ()
	if keyboardMap then
		keyHandled = keyboardMap:Execute (self, keyCode, ctrl, shift, alt)
	end
	
	if not keyHandled then
		local parent = self:GetParent ()
		while parent and parent:IsValid () do
			if type (parent.DispatchKeyboardAction) == "function" then
				return parent:DispatchKeyboardAction (keyCode, ctrl, shift, alt)
			end
			parent = parent:GetParent ()
		end
	end
	
	return keyHandled
end

function self:GetAction ()
	return self.Action
end

function self:GetActionMap ()
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

function self:GetKeyboardMap ()
	return self.KeyboardMap
end

function self:RunAction (...)
	if not self:GetAction () then return end
	self:DispatchAction (self:GetAction (), ...)
end

function self:SetAction (action)
	if self.Action == action then return self end
	
	self.Action = action
	self:DispatchEvent ("ActionChanged", self.Action)
	if self.OnActionChanged then self:OnActionChanged (self.Action) end
	
	return self
end

function self:SetActionMap (actionMap)
	if self.ActionMap == actionMap then return self end
	
	self.ActionMap = actionMap
	self:DispatchEvent ("ActionMapChanged", self.ActionMap)
	
	return self
end

function self:SetKeyboardMap (keyboardMap)
	self.KeyboardMap = keyboardMap
	return self
end

function self:SetVisible (visible)
	if self:IsVisible () == visible then return self end
	
	debug.getregistry ().Panel.SetVisible (self, visible)
	self:DispatchEvent ("VisibleChanged", visible)
	
	return self
end

-- Event handlers
function self:OnFocusChanged (focused)
	self.Focused = focused
	
	if focused then
		self:DispatchEvent ("GotFocus")
		if self.OnGotFocus then self:OnGotFocus () end
	else
		self:DispatchEvent ("LostFocus")
		if self.OnLostFocus then self:OnLostFocus () end
	end
end

-- Internal, do not call
function self:FadeThink ()
	if not self.FadingOut then return end
	
	local alpha = self:GetFadeAlpha ()
	self:SetAlpha (alpha)
	if alpha == 0 then
		self.FadingOut = false
		self:SetVisible (false)
		self:SetAlpha (255)
		return
	end
	
	GLib.CallDelayed (
		function ()
			if not self or not self:IsValid () then return end
			self:FadeThink ()
		end
	)
end

function self:GetFadeAlpha ()
	local t = (self.FadeEndTime - SysTime ()) / self.FadeDuration
	local alpha = t * 255
	if alpha < 0 then alpha = 0 end
	if alpha > 255 then alpha = 255 end
	return alpha
end

-- Deprecated functions
function self:GetDisabled ()
	return not self:IsEnabled ()
end

function self:IsDisabled ()
	return not self:IsEnabled ()
end

self.GetColor     = Gooey.DeprecatedFunction
self.HasFocus     = Gooey.DeprecatedFunction
self.HasParent    = Gooey.DeprecatedFunction
self.RequestFocus = Gooey.DeprecatedFunction
self.SetColor     = Gooey.DeprecatedFunction
self.SetDisabled  = Gooey.DeprecatedFunction