local self = {}
Gooey.ToolTipController = Gooey.MakeConstructor (self)

function self:ctor (control)
	self.Control = nil
	
	self.Enabled = true
	self.Manual = false
	
	-- Positioning
	self.AnchorPoint = 3
	self.PositioningMode = Gooey.ToolTipPositioningMode.Cursor
	
	self.MouseEnterTime = 0
	self.MouseOver = false
	self.ToolTip = nil
	
	self.EnabledChanged = function (_, enabled)
		if not enabled then
			self:HideToolTip ()
		end
	end
	
	self.MouseEnter = function (_)
		self.MouseEnterTime = SysTime ()
		self.MouseOver = true
		
		hook.Add ("Think", "Gooey.ToolTipController",
			function ()
				if self.Manual then return end
				if not self.Control:IsEnabled () then return end
				if not self:GetToolTipText () then return end
				if self:IsToolTipVisible () then return end
				if SysTime () - self.MouseEnterTime > 0.5 then
					self:ShowToolTip ()
				end
			end
		)
	end
	
	self.MouseLeave = function (_)
		self:HideToolTip ()
		
		self.MouseOver = false
		hook.Remove ("Think", "Gooey.ToolTipController")
	end
	
	self.Removed = function (_)
		self:SetControl (nil)
	end
	
	self:SetControl (control)
end

function self:dtor ()
	hook.Remove ("Think", "Gooey.ToolTipController")
end

function self:GetAnchorPoint ()
	return self.AnchorPoint
end

function self:GetPositioningMode ()
	return self.PositioningMode
end

function self:GetToolTip ()
	return self.ToolTip
end

function self:GetToolTipText ()
	if not self.Control then return end
	return self.Control:GetToolTipText ()
end

function self:HideToolTip ()
	if self.ToolTip and self.ToolTip:IsValid () then
		self.ToolTip:RemoveEventListener ("VisibleChanged", "Gooey.ToolTipController")
		self.ToolTip:SetVisible (false)
		self.ToolTip = nil
	end
	
	if self.Control then
		self.Control:RemoveEventListener ("Removed",        "Gooey.ToolTipController")
		self.Control:RemoveEventListener ("VisibleChanged", "Gooey.ToolTipController")
	end
	
	hook.Remove ("Think", "Gooey.ToolTipController.CheckValidity")
end

function self:IsEnabled ()
	return self.Enabled
end

function self:IsToolTipVisible ()
	if not self.ToolTip or not self.ToolTip:IsValid () then return false end
	return self.ToolTip:IsVisible ()
end

function self:SetAnchorPoint (anchorPoint)
	self.AnchorPoint = achorPoint
end

function self:SetControl (control)
	if self.Control == control then return end
	
	self:HideToolTip ()
	if self.Control then
		self.Control:RemoveEventListener ("EnabledChanged", self:GetHashCode ())
		self.Control:RemoveEventListener ("MouseEnter",     self:GetHashCode ())
		self.Control:RemoveEventListener ("MouseLeave",     self:GetHashCode ())
		self.Control:RemoveEventListener ("Removed",        self:GetHashCode ())
		hook.Remove ("Think", "Gooey.ToolTipController")
	end
	
	self.Control = control
	
	if self.Control and self.Enabled then
		self.Control:AddEventListener ("EnabledChanged", self:GetHashCode (), self.EnabledChanged)
		self.Control:AddEventListener ("MouseEnter",     self:GetHashCode (), self.MouseEnter)
		self.Control:AddEventListener ("MouseLeave",     self:GetHashCode (), self.MouseLeave)
		self.Control:AddEventListener ("Removed",        self:GetHashCode (), self.Removed)
	end
end

function self:SetEnabled (enabled)
	if self.Enabled == enabled then return end
	
	self.Enabled = enabled
	
	if self.Control then
		if self.Enabled then
			self.Control:AddEventListener ("EnabledChanged", self:GetHashCode (), self.EnabledChanged)
			self.Control:AddEventListener ("MouseEnter",     self:GetHashCode (), self.MouseEnter)
			self.Control:AddEventListener ("MouseLeave",     self:GetHashCode (), self.MouseLeave)
		else
			self:HideToolTip ()
			self.Control:RemoveEventListener ("EnabledChanged", self:GetHashCode ())
			self.Control:RemoveEventListener ("MouseEnter",     self:GetHashCode ())
			self.Control:RemoveEventListener ("MouseLeave",     self:GetHashCode ())
			hook.Remove ("Think", "Gooey.ToolTipController")
		end
	end
end

function self:SetManual (manual)
	self.Manual = manual
end

function self:SetPositioningMode (positioningMode)
	self.PositioningMode = positioningMode
end

function self:ShowToolTip (text)
	self.ToolTip = Gooey.ToolTipManager:GetToolTip ()
	self.ToolTip:SetText (text or self:GetToolTipText () or "")
	self.ToolTip:SetVisible (true)
	self.ToolTip:AddEventListener ("VisibleChanged", "Gooey.ToolTipController",
		function (_, visible)
			if not visible then
				self:HideToolTip ()
			end
		end
	)
	
	if self.Control then
		self.Control:AddEventListener ("Removed", "Gooey.ToolTipController",
			function (_)
				self:HideToolTip ()
			end
		)
		self.Control:AddEventListener ("VisibleChanged", "Gooey.ToolTipController",
			function (_, visible)
				if not visible then
					self:HideToolTip ()
				end
			end
		)
	end
	
	hook.Add ("Think", "Gooey.ToolTipController.CheckValidity",
		function ()
			if self.Manual then return end
			if not self.Control then return end
			
			-- Check recursive visibility
			local visible = true
			local parent = self.Control:GetParent ()
			while parent do
				visible = visible and parent:IsVisible ()
				parent = parent:GetParent ()
			end
			
			if not visible then
				self:HideToolTip ()
			end
		end
	)
	
	if self.PositioningMode ~= Gooey.ToolTipPositioningMode.Custom then
		local x, y, w, h = 0, 0, 0, 0
		if self.PositioningMode == Gooey.ToolTipPositioningMode.Cursor then
			x = gui.MouseX ()
			y = gui.MouseY ()
			w = 16
			h = 16
		elseif self.PositioningMode == Gooey.ToolTipPositioningMode.Control then
			x, y = self.Control:LocalToScreen (0, 0)
			w, h = self.Control:GetSize ()
		end
		
		local toolTipX = 0
		local toolTipY = 0
		
		-- Horizontal positioning
		if self.AnchorPoint == 1 or self.AnchorPoint == 4 or self.AnchorPoint == 7 then
			toolTipX = x - self.ToolTip:GetWide ()
		elseif self.AnchorPoint == 2 or self.AnchorPoint == 5 or self.AnchorPoint == 8 then
			toolTipX = x + w * 0.5 - self.ToolTip:GetWide () * 0.5
		else
			toolTipX = x + w
		end
		
		-- Vertical positioning
		if self.AnchorPoint == 7 or self.AnchorPoint == 8 or self.AnchorPoint == 9 then
			toolTipY = y - self.ToolTip:GetTall ()
		elseif self.AnchorPoint == 4 or self.AnchorPoint == 5 or self.AnchorPoint == 6 then
			toolTipY = y + h * 0.5 - self.ToolTip:GetTall () * 0.5
		else
			toolTipY = y + h
		end
		self.ToolTip:SetPos (toolTipX, toolTipY)
	end
	return self.ToolTip
end

-- Event handlers
self.EnabledChanged = Gooey.NullCallback
self.MouseEnter     = Gooey.NullCallback
self.MouseLeave     = Gooey.NullCallback