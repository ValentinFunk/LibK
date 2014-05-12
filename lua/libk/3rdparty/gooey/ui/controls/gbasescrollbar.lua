local PANEL = {}

--[[
	GBaseScrollBar
		Code is based on DVScrollBar
		
	Events:
		InterpolatedScroll (interpolatedViewOffset)
			Fired when the interpolated scroll position has changed.
		Scroll (viewOffset)
			Fired when the scroll bar has been scrolled.
		SmallIncrementChanged (smallIncrement)
			Fired when the small increment has changed.
]]

function PANEL:Init ()
	self.ContentSize = 1
	
	self.InterpolatedViewOffset = 0
	self.ViewOffset = 0
	self.ViewSize = 1
	
	self.AnimationEnabled = true
	self.LiveSmoothingInterpolator = Gooey.LiveSmoothingInterpolator ()
	self.LiveSmoothingInterpolator:SetDefaultDuration (0.5)
	self.LiveSmoothingInterpolator:SetFinalValue (0)
	self.LiveSmoothingInterpolator:AddEventListener ("ValueChanged",
		function (_, value)
			-- Set the cached interpolated value before firing
			-- the InterpolatedScroll event, so that GetInterpolatedViewOffset
			-- returns an up-to-date value.
			self.InterpolatedViewOffset = value
			
			self:DispatchEvent ("InterpolatedScroll", self:IsAnimationEnabled () and value or self:GetViewOffset ())
			self:InvalidateLayout ()
		end
	)
	
	self.Grip = vgui.Create ("GScrollBarGrip", self)
	self.Grip:SetScrollBar (self)
	
	-- Button scrolling
	self.SmallIncrement = 1
	
	-- Mouse click scrolling
	self.NextMouseScrollTime = 0
	self.FirstMouseScrollInterval = 0.5
	self.MouseScrollInterval = 0.050
	
	self:SetSize (15, 15)
	
	self:AddEventListener ("EnabledChanged",
		function (_, enabled)
			self.Grip:SetEnabled (enabled)
			self.Grip:SetVisible (enabled)
		end
	)
	self:AddEventListener ("MouseDown",
		function (_, mouseCode, x, y)
			if mouseCode == MOUSE_LEFT then
				self:MouseCapture (true)
			end
		end
	)
	self:AddEventListener ("MouseUp",
		function (_, mouseCode, x, y)
			if mouseCode == MOUSE_LEFT then
				self:MouseCapture (false)
			end
		end
	)
	self:AddEventListener ("MouseWheel",
		function (_, delta, x, y)
			self:ScrollAnimated (delta * -3 * self:GetSmallIncrement ())
			return true
		end
	)
end

function PANEL:GetContentSize ()
	return self.ContentSize
end

function PANEL:GetGripSize ()
	local gripFraction = self.ViewSize / self.ContentSize
	if gripFraction > 1 then gripFraction = 1 end
	local gripSize = gripFraction * self:GetTrackSize ()
	if gripSize < 10 then gripSize = 10 end
	return gripSize
end

function PANEL:GetOrientation ()
	Gooey.Error (self.ClassName .. ":GetOrientation : Not implemented.")
end

function PANEL:GetScrollableTrackSize ()
	return self:GetTrackSize () - self:GetGripSize ()
end

function PANEL:GetSmallIncrement ()
	return self.SmallIncrement
end

function PANEL:GetThickness ()
	Gooey.Error (self.ClassName .. ":GetThickness : Not implemented.")
end

function PANEL:GetTrackSize ()
	Gooey.Error (self.ClassName .. ":GetTraceSize : Not implemented.")
end

function PANEL:GetInterpolatedViewOffset ()
	if not self:IsAnimationEnabled () then return self:GetViewOffset () end
	return self.InterpolatedViewOffset
end

function PANEL:GetViewOffset ()
	return self.ViewOffset
end

function PANEL:GetViewSize ()
	return self.ViewSize
end

function PANEL:IsAnimationEnabled ()
	return self.AnimationEnabled
end

function PANEL:Paint (w, h)
	derma.SkinHook ("Paint", "VScrollBar", self, w, h)
	return true
end

function PANEL:PaintOver (w, h)
	-- Update the interpolated scroll position.
	-- This is done here because updating it in Panel:Think
	-- will result in other panels' PerformLayout functions
	-- not getting called before the next Paint call.
	self.LiveSmoothingInterpolator:Tick ()
end

function PANEL:PerformLayout ()
end

function PANEL:ScrollAnimated (delta)
	if delta == 0 then return end
	
	self:SetViewOffset (self.ViewOffset + delta, true)
end

function PANEL:Scroll (delta)
	if delta == 0 then return end
	
	self:SetViewOffset (self.ViewOffset + delta)
end

function PANEL:SetAnimationEnabled (animationEnabled)
	if self.AnimationEnabled == animationEnabled then return self end
	
	self.AnimationEnabled = animationEnabled
	return self
end

function PANEL:SetContentSize (contentSize)
	if self.ContentSize == contentSize then return self end
	
	self.ContentSize = contentSize
	self:SetEnabled (self.ViewSize < self.ContentSize)
	if self.ViewOffset + self.ViewSize > self.ContentSize then
		self:SetViewOffset (self.ContentSize - self.ViewSize)
	end
	self:InvalidateLayout ()
	
	return self
end

function PANEL:SetSmallIncrement (smallIncrement)
	if self.SmallIncrement == smallIncrement then return self end
	
	self.SmallIncrement = smallIncrement
	self:DispatchEvent ("SmallIncrementChanged", self.SmallIncrement)
	
	return self
end

function PANEL:SetViewOffset (viewOffset, animated)
	if not self:IsEnabled () then viewOffset = 0 end
	if not self:IsAnimationEnabled () then animated = false end

	if viewOffset + self.ViewSize > self.ContentSize then
		viewOffset = self.ContentSize - self.ViewSize
	end
	if viewOffset <= 0 then
		viewOffset = 0
	end
	if self.ViewOffset == viewOffset then return self end
	
	self.ViewOffset = viewOffset
	if animated then
		self.LiveSmoothingInterpolator:SetTargetValue (self.ViewOffset)
	else
		self.LiveSmoothingInterpolator:SetFinalValue (self.ViewOffset)
	end
	self.LiveSmoothingInterpolator:Tick ()
	
	self:DispatchEvent ("Scroll", self.ViewOffset)
	
	return self
end

function PANEL:SetViewSize (viewSize)
	if self.ViewSize == viewSize then return self end
	
	self.ViewSize = viewSize
	self:SetEnabled (self.ViewSize < self.ContentSize)
	if self.ViewOffset + self.ViewSize > self.ContentSize then
		self:SetViewOffset (self.ContentSize - self.ViewSize)
	end
	self:InvalidateLayout ()
	
	return self
end

-- Event handlers
function PANEL:Think ()
	if self:IsPressed () then
		if SysTime () >= self.NextMouseScrollTime then
			local x, y = self:CursorPos ()
			if self:GetOrientation () == Gooey.Orientation.Horizontal then
				self:ScrollToMouse (x)
			elseif self:GetOrientation () == Gooey.Orientation.Vertical then
				self:ScrollToMouse (y)
			end
		end
	end
	
	-- Note: The interpolated scroll position is updated in PaintOver.
end

-- Internal, do not call
function PANEL:ScrollToMouse (mousePos)
	mousePos = mousePos - self:GetThickness ()
	local gripPos = mousePos - self:GetGripSize () * 0.5
	local scrollFraction = gripPos / self:GetScrollableTrackSize ()
	if scrollFraction < 0 then scrollFraction = 0 end
	if scrollFraction > 1 then scrollFraction = 1 end
	local viewOffset = scrollFraction * (self.ContentSize - self.ViewSize)
	local delta = viewOffset - self.ViewOffset
	if delta < -self.ViewSize then delta = -self.ViewSize end
	if delta > self.ViewSize then delta = self.ViewSize end
		
	self:SetViewOffset (self.ViewOffset + delta, true)
	
	self.NextMouseScrollTime = SysTime () + self.MouseScrollInterval
end

Gooey.Register ("GBaseScrollBar", PANEL, "GPanel")