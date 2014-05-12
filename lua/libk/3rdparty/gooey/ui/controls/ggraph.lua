local PANEL = {}

function PANEL:Init ()
	self:SetBackgroundColor (GLib.Colors.White)
	
	self.Function = function (x) return x end
	
	self.XMin = -50
	self.XMax =  50
	self.YMin = -1.2
	self.YMax =  1.2
end

function PANEL:GraphToPanel (x, y)
	local w = self:GetWide () - 16
	local h = self:GetTall () - 16
	
	x = 8 + (x - self.XMin) / (self.XMax - self.XMin) * w
	y = self:GetTall () - 8 - (y - self.YMin) / (self.YMax - self.YMin) * h
	
	return x, y
end

function PANEL:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, self:GetBackgroundColor ())
	
	local x, y = 8, 8
	w = w - 16
	h = h - 16
	
	surface.SetDrawColor (GLib.Colors.Black)
	
	local x1, y1 = 0, 0
	local x2, y2 = 0, 0
	
	-- Axes
	-- X Axis
	x1, y1 = self:GraphToPanel (self.XMin, 0)
	x2, y2 = self:GraphToPanel (self.XMax, 0)
	surface.DrawLine (x1, y1, x2, y2)
	
	-- Y Axis
	x1, y1 = self:GraphToPanel (0, self.YMin)
	x2, y2 = self:GraphToPanel (0, self.YMax)
	surface.DrawLine (x1, y1, x2, y2)
	
	-- Plot
	x1, y1 = self:LocalToScreen (8, 8)
	render.SetScissorRect (x1, y1, x1 + w, y1 + h, true)
	surface.SetDrawColor (GLib.Colors.Red)
	x2, y2 = self:GraphToPanel (self.XMin, self.Function (self.XMin))
	for x = 2, self:GetWide () - 16, 2 do
		x1 = x2
		y1 = y2
		
		local x = self.XMin + x * (self.XMax - self.XMin) / (self:GetWide () - 16)
		x2, y2 = self:GraphToPanel (x, self.Function (x))
		surface.DrawLine (x1, y1, x2, y2)
	end
	render.SetScissorRect (0, 0, 0, 0, false)
end

function PANEL:SetFunction (f)
	self.Function = f
	return self
end

function PANEL:SetXRange (x1, x2)
	self.XMin = x1
	self.XMax = x2
	return self
end

function PANEL:SetYRange (y1, y2)
	self.YMin = y1
	self.YMax = y2
	return self
end

Gooey.Register ("GGraph", PANEL, "GPanel")

function Gooey.Plot (f)
	if not f then return end
	
	if not Gooey.PlotFrame or not Gooey.PlotFrame:IsValid () then
		Gooey.PlotFrame = vgui.Create ("GFrame")
		Gooey.PlotFrame:SetSize (ScrW () * 0.8, ScrH () * 0.8)
		Gooey.PlotFrame:MakePopup ()
		Gooey.PlotFrame:Center ()
		
		Gooey.PlotFrame:SetTitle ("Plot")
		Gooey.PlotFrame.Graph = vgui.Create ("GGraph", Gooey.PlotFrame)
		
		function Gooey.PlotFrame:PerformLayout ()
			DFrame.PerformLayout (self)
			
			self.Graph:SetPos (8, 32)
			self.Graph:SetSize (Gooey.PlotFrame:GetWide () - 16, Gooey.PlotFrame:GetTall () - 40)
		end
	end
	
	Gooey.PlotFrame.Graph:SetFunction (f)
	
	return Gooey.PlotFrame.Graph
end