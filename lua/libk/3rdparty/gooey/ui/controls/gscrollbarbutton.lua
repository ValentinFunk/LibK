local PANEL = {}

function PANEL:Init ()
	self.ScrollBar = nil
	self.ScrollIncrement = 1
	
	self.Direction = "Up"
	
	self:SetText ("")
	
	self.NextIncrementTime = 0
	self.FirstIncrementInterval = 0.5
	self.IncrementInterval = 0.050
	
	self:AddEventListener ("MouseDown",
		function (_, mouseCode)
			if mouseCode == MOUSE_LEFT then
				if self.ScrollBar then
					self.ScrollBar:ScrollAnimated (self:GetScrollIncrement ())
					self.NextIncrementTime = SysTime () + self.FirstIncrementInterval
				end
			end
		end
	)
end

function PANEL:GetDirection ()
	return self.Direction or "Up"
end

function PANEL:GetScrollBar ()
	return self.ScrollBar
end

function PANEL:GetScrollIncrement ()
	return self.ScrollIncrement
end

function PANEL:Paint (w, h)
	if self:GetSkin () and
	   self:GetSkin ().tex and
	   self:GetSkin ().tex.Scroller and
	   not self:GetSkin ().tex.Scroller.LeftButton_Dead then
		self:InitializeDisabledButtonTextures ()
	end
	
	derma.SkinHook ("Paint", "Button" .. self:GetDirection (), self, w, h)
end

function PANEL:SetDirection (direction)
	self.Direction = direction or "Up"
end

function PANEL:SetScrollBar (scrollBar)
	self.ScrollBar = scrollBar
end

function PANEL:SetScrollIncrement (increment)
	self.ScrollIncrement = increment or 1
end

-- Event handlers
function PANEL:Think ()
	if self:IsPressed () then
		if SysTime () >= self.NextIncrementTime then
			if self.ScrollBar then
				self.ScrollBar:Scroll (self:GetScrollIncrement ())
				self.NextIncrementTime = SysTime () + self.IncrementInterval
			end
		end
	end
end

-- Internal, do not call
function PANEL:InitializeDisabledButtonTextures ()
	local _SKIN = _G.SKIN
	SKIN = self:GetSkin ()
	
	SKIN.tex.Scroller.LeftButton_Dead  = GWEN.CreateTextureBorder (480,	272,	    15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.UpButton_Dead    = GWEN.CreateTextureBorder (480,	272 + 16,	15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.RightButton_Dead = GWEN.CreateTextureBorder (480,	272 + 32,	15, 15, 2, 2, 2, 2)
	SKIN.tex.Scroller.DownButton_Dead  = GWEN.CreateTextureBorder (480,	272 + 48,	15, 15, 2, 2, 2, 2)
	
	_G.SKIN = _SKIN
end

Gooey.Register ("GScrollBarButton", PANEL, "GButton")