local PANEL = {}

function PANEL:Init ()
	self.Progress = 0
end

function PANEL:GetProgress ()
	return self.Progress * 100
end

function PANEL:Paint (w, h)
	local barWidth = w * self.Progress
	local roundRadius = math.min (4, math.floor (barWidth * 0.5))
	draw.RoundedBox (roundRadius, 0, 0, barWidth, h, GLib.Colors.CornflowerBlue)
end

function PANEL:SetProgress (progress)
	self.Progress = progress / 100
end

Gooey.Register ("GProgressBar", PANEL, "GPanel")