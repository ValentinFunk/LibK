local PANEL = {}

function PANEL:Init ()
	self.Title = vgui.Create ("DLabel", self)
	self.Title:SetColor (Color (255, 255, 255, 255))
	
	self.Container = vgui.Create ("GPanel", self)
	
	self:SetOutlineColor (Color (160, 160, 160, 255))
	
	for k, _ in pairs (self:GetTable ()) do
		if k:sub (1, 6) == "Create" then
			self [k] = function (self, ...)
				return self:GetContainer () [k] (self:GetContainer (), ...)
			end
		end
	end
	
	self:AddEventListener ("FontChanged",
		function (_, text)
			self.Title:SetFont (font)
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			self.Title:SetText (text)
			self.Title:SizeToContents ()
		end
	)
	
	self:SetFont ("TabLarge")
end

function PANEL:GetContainer ()
	return self.Container
end

function PANEL:GetFont ()
	return self.Font
end

function PANEL:GetOutlineColor ()
	return self.OutlineColor
end

function PANEL:Paint (w, h)
	local textHeight = draw.GetFontHeight (self:GetFont ()) * 0.5
	draw.RoundedBox (4, 0, textHeight, w, h - textHeight, self:GetOutlineColor ())
	draw.RoundedBox (4, 1, 1 + textHeight, w - 2, h - 2 - textHeight, self:GetBackgroundColor ())
	surface.SetDrawColor (self:GetBackgroundColor ())
	surface.DrawRect (self.Title:GetPos () - 4, 0, self.Title:GetWide () + 8, self.Title:GetTall ())
end

function PANEL:PerformLayout ()
	self.Title:SetPos (12, 0)
	self.Container:SetPos (6, self.Title:GetTall () + 4)
	self.Container:SetSize (self:GetWide () - 12, self:GetTall () - self.Title:GetTall () - 8)
	
	self:DispatchEvent ("PerformLayout")
end

function PANEL:SetOutlineColor (color)
	self.OutlineColor = color
end

Gooey.Register ("GGroupBox", PANEL, "GPanel")