local PANEL = {}

function PANEL:Init ()
	self:SetOrientation (Gooey.Orientation.Vertical)
	
	self.DragController = Gooey.DragController (self)
end

function PANEL:Paint (w, h)
	surface.SetDrawColor (GLib.Colors.LightGray)
	if self.Orientation == Gooey.Orientation.Vertical then
		local x = math.floor (w * 0.5 - 1)
		for y = h * 0.5 - 6, h * 0.5 + 6, 2 do
			surface.DrawRect (x, y, 1, 1)
		end
		x = math.floor (w * 0.5 + 1)
		for y = h * 0.5 - 6, h * 0.5 + 6, 2 do
			surface.DrawRect (x, y, 1, 1)
		end
	else
		local y = math.floor (h * 0.5 - 1)
		for x = w * 0.5 - 6, w * 0.5 + 6, 2 do
			surface.DrawRect (x, y, 1, 1)
		end
		y = math.floor (h * 0.5 + 1)
		for x = w * 0.5 - 6, w * 0.5 + 6, 2 do
			surface.DrawRect (x, y, 1, 1)
		end
	end
end

function PANEL:SetOrientation (orientation)
	if self.Orientation == orientation then return end
	
	self.Orientation = orientation
	if self.Orientation == Gooey.Orientation.Vertical then
		self:SetCursor ("sizewe")
	else
		self:SetCursor ("sizens")
	end
end

Gooey.Register ("GSplitContainerSplitter", PANEL, "GPanel")