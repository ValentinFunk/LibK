local PANEL = {}
Gooey.Image = Gooey.MakeConstructor (PANEL, Gooey.VPanel)

function PANEL:ctor ()
	self:Init ()
end

function PANEL:Init ()
	self.Image = nil
	self:SetSize (16, 16)
	
	if self.SetMouseInputEnabled then
		self:SetMouseInputEnabled (false)
	end
	
	self.GetWidth  = self.GetWidth  or self.GetWide
	self.GetHeight = self.GetHeight or self.GetTall
end

function PANEL:GetImage ()
	return self.Image
end

function PANEL:Paint (renderContext)
	renderContext = renderContext or Gooey.RenderContext
	
	if self.Image then
		local image = Gooey.ImageCache:GetImage (self.Image)
		if self:IsEnabled () then
			image:Draw (renderContext, (self:GetWidth () - image:GetWidth ()) * 0.5, (self:GetHeight () - image:GetHeight ()) * 0.5)
		else
			image:Draw (renderContext, (self:GetWidth () - image:GetWidth ()) * 0.5, (self:GetHeight () - image:GetHeight ()) * 0.5, 0, 0, 0, 160)
			image:Draw (renderContext, (self:GetWidth () - image:GetWidth ()) * 0.5, (self:GetHeight () - image:GetHeight ()) * 0.5, nil, nil, nil, 32)
		end
	end
end

function PANEL:SetImage (image)
	self.Image = image
	return self
end

PANEL = table.Copy (PANEL)
PANEL.__index = nil
PANEL.__base = nil
Gooey.Register ("GImage", PANEL, "GPanel")