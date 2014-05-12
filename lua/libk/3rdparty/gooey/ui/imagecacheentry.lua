local self = {}
Gooey.ImageCacheEntry = Gooey.MakeConstructor (self)

function self:ctor (imageCache, image)
	self.Image = image
	self.Material = Material (image)
	if self.Material:IsError () then
		local fallbackImage = imageCache:GetFallbackImage ()
		if fallbackImage then
			self.Material = imageCache:GetFallbackImage ():GetMaterial ()
		end
	end
	
	if string.find (self.Material:GetShader (), "VertexLitGeneric") or
		string.find (self.Material:GetShader (), "Cable") then
		local baseTexture = self.Material:GetString ("$basetexture")
		if baseTexture then
			self.Material = CreateMaterial (image .. "_DImage", "UnlitGeneric",
				{
					["$basetexture"] = baseTexture,
					["$vertexcolor"] = 1,
					["$vertexalpha"] = 1
				}
			)
		end
	end
	
	local texture = self.Material:GetTexture ("$basetexture")
	if texture then
		self.Width  = texture:Width ()
		self.Height = texture:Height ()
	else
		self.Width  = 16
		self.Height = 16
	end
end

function self:Draw (renderContext, x, y, r, g, b, a)
	surface.SetMaterial (self.Material)
	surface.SetDrawColor (r or 255, g or 255, b or 255, a or 255)
	surface.DrawTexturedRect (x or 0, y or 0, self.Width, self.Height)
end

function self:DrawEx (renderContext, x, y, w, h, r, g, b, a)
	surface.SetMaterial (self.Material)
	surface.SetDrawColor (r or 255, g or 255, b or 255, a or 255)
	surface.DrawTexturedRect (x or 0, y or 0, w or self.Width, h or self.Height)
end

function self:GetHeight ()
	return self.Height
end

function self:GetMaterial ()
	return self.Material
end

function self:GetSize ()
	return self.Width, self.Height
end

function self:GetWidth ()
	return self.Width
end

function self:SetSize (width, height)
	self.Width  = width
	self.Height = height
end

function self:SetWidth (width)
	self.Width = width
end

function self:SetHeight (height)
	self.Height = height
end