local PANEL = {}

function PANEL:Init ()
	self:SetSize (24, 24)
	
	self:SetCursor ("sizenwse")
	
	self.DragController = Gooey.DragController (self)
	self.DragController:AddEventListener ("PositionCorrectionChanged",
		function (_, deltaX, deltaY)
			local frame = self:GetParent ()
			if frame.ClassName == "GStatusBar" then
				frame = frame:GetParent ()
			end
			
			local x, y   = frame:GetPos ()
			local width  = frame:GetWide () + deltaX
			local height = frame:GetTall () + deltaY
			
			-- Clamp to bottom right corner of screen
			width  = math.min (width,  ScrW () - x)
			height = math.min (height, ScrH () - y)
			
			-- Enforce minimum frame size
			width  = math.max (width,  128)
			height = math.max (height, self:GetTall () * 2 + 24)
			
			frame:SetSize (width, height)
		end
	)
	
	self:AddEventListener ("ParentChanged",
		function (_, oldParent, parent)
			if oldParent and oldParent:IsValid () then
				oldParent:RemoveEventListener ("SizeChanged", self:GetHashCode ())
			end
			if parent and parent:IsValid () then
				parent:AddEventListener ("SizeChanged", self:GetHashCode (),
					function ()
						self:PerformLayout ()
					end
				)
			end
		end
	)
	self:DispatchEvent ("ParentChanged", nil, self:GetParent ())
end

function PANEL:Paint (w, h)
	local padding = 3
	local dotSize = math.min ((math.min (w, h) - padding * 2) / 5, 3)
	dotSize = math.floor (dotSize + 0.5) -- round dotSize
	
	local x = w - padding - dotSize * 5
	draw.RoundedBox (2, x, h - padding - dotSize, dotSize, dotSize, GLib.Colors.Gray)
	x = w - padding - dotSize * 3
	draw.RoundedBox (2, x, h - padding - dotSize * 3, dotSize, dotSize, GLib.Colors.Gray)
	draw.RoundedBox (2, x, h - padding - dotSize, dotSize, dotSize, GLib.Colors.Gray)
	x = w - padding - dotSize
	draw.RoundedBox (2, x, h - padding - dotSize * 5, dotSize, dotSize, GLib.Colors.Gray)
	draw.RoundedBox (2, x, h - padding - dotSize * 3, dotSize, dotSize, GLib.Colors.Gray)
	draw.RoundedBox (2, x, h - padding - dotSize, dotSize, dotSize, GLib.Colors.Gray)
end

function PANEL:PerformLayout ()
	self:SetPos (self:GetParent ():GetWide () - self:GetWide (), self:GetParent ():GetTall () - self:GetTall ())
end

-- Event handlers
function PANEL:OnRemoved ()
	self:DispatchEvent ("ParentChanged", self:GetParent (), nil)
end

Gooey.Register ("GResizeGrip", PANEL, "GPanel")