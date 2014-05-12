local PANEL = {}

--[[
	GHScrollBar
		
	Events:
		Scroll (viewOffset)
			Fired when the scroll bar has been scrolled.
		SmallIncrementChanged (smallIncrement)
			Fired when the small increment has changed.
]]

function PANEL:Init ()
	self.Grip:AddEventListener ("TargetPositionChanged",
		function (_, x, y)
			local scrollFraction = (x - self:GetThickness ()) / self:GetScrollableTrackSize ()
			if scrollFraction < 0 then scrollFraction = 0 end
			if scrollFraction > 1 then scrollFraction = 1 end
			local viewOffset = scrollFraction * (self.ContentSize - self.ViewSize)
			self:SetViewOffset (viewOffset)
		end
	)
	
	self.LeftButton = vgui.Create ("GScrollBarButton", self)
	self.LeftButton:SetScrollBar (self)
	self.LeftButton:SetScrollIncrement (-self:GetSmallIncrement ())
	self.LeftButton:SetDirection ("Left")
	
	self.RightButton = vgui.Create ("GScrollBarButton", self)
	self.RightButton:SetScrollBar (self)
	self.RightButton:SetScrollIncrement (self:GetSmallIncrement ())
	self.RightButton:SetDirection ("Right")
	
	self:SetWide (256)
	
	self:AddEventListener ("EnabledChanged",
		function (_, enabled)
			self.LeftButton:SetEnabled (enabled)
			self.RightButton:SetEnabled (enabled)
		end
	)
	self:AddEventListener ("MouseDown",
		function (_, mouseCode, x, y)
			if mouseCode == MOUSE_LEFT then
				self:ScrollToMouse (x)
				self.NextMouseScrollTime = SysTime () + self.FirstMouseScrollInterval
			end
		end
	)
	self:AddEventListener ("Scroll",
		function (_, viewOffset)
			if self:GetParent ().OnHScroll then
				self:GetParent ():OnHScroll (viewOffset)
			else
				self:GetParent ():InvalidateLayout ()
			end
		end
	)
	self:AddEventListener ("SmallIncrementChanged",
		function (_, smallIncrement)
			self.LeftButton:SetScrollIncrement (-smallIncrement)
			self.RightButton:SetScrollIncrement (smallIncrement)
		end
	)
end

function PANEL:GetOrientation ()
	return Gooey.Orientation.Horizontal
end

function PANEL:GetThickness ()
	return self:GetTall ()
end

function PANEL:GetTrackSize ()
	return self:GetWide () - self.LeftButton:GetWide () - self.RightButton:GetWide ()
end

function PANEL:Paint (w, h)
	derma.SkinHook ("Paint", "VScrollBar", self, w, h)
	return true
end

function PANEL:PerformLayout ()
	local buttonSize = self:GetThickness ()
	
	self.LeftButton:SetPos (0, 0)
	self.LeftButton:SetSize (buttonSize, buttonSize)
	
	self.RightButton:SetPos (self:GetWide () - buttonSize, 0)
	self.RightButton:SetSize (buttonSize, buttonSize)
	
	self.Grip:SetPos (math.floor (self.LeftButton:GetWide () + self:GetInterpolatedViewOffset () / (self.ContentSize - self.ViewSize) * self:GetScrollableTrackSize () + 0.5), 0)
	self.Grip:SetSize (self:GetGripSize (), buttonSize)
end

Gooey.Register ("GHScrollBar", PANEL, "GBaseScrollBar")