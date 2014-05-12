local PANEL = {}

--[[
	Events:
		TargetPositionChanged (x, y)
			Fired when this ScrollBarGrip is dragged.
]]

function PANEL:Init ()
	self.ScrollBar = nil
	
	self.DragController = Gooey.DragController (self)
	self.DragController:AddEventListener ("PositionCorrectionChanged",
		function (_, dx, dy)
			local x, y = self:GetPos ()
			self:DispatchEvent ("TargetPositionChanged", x + dx, y + dy)
		end
	)
end

function PANEL:GetScrollBar ()
	return self.ScrollBar
end

function PANEL:Paint (w, h)
	derma.SkinHook ("Paint", "ScrollBarGrip", self, w, h)
end

function PANEL:SetScrollBar (scrollBar)
	self.ScrollBar = scrollBar
end

Gooey.Register ("GScrollBarGrip", PANEL, "GPanel")