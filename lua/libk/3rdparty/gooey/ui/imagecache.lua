local self = {}
Gooey.ImageCache = Gooey.MakeConstructor (self)

function self:ctor ()
	self.Images = {}
	
	self.LoadDuration  = 0.005
	self.LastLoadFrame = 0
	self.LoadStartTime = 0
	
	self.FallbackImage    = self:LoadImage ("icon16/cross.png")
	self.PlaceholderImage = self:LoadImage ("icon16/hourglass.png")
end

function self:GetFallbackImage ()
	return self.FallbackImage
end

function self:GetPlaceholderImage ()
	return self.PlaceholderImage
end

function self:GetImage (image)
	image = image:lower ()
	if self.Images [image] then
		return self.Images [image]
	end
	if self.LastLoadFrame ~= CurTime () then
		self.LastLoadFrame = CurTime ()
		self.LoadStartTime = SysTime ()
	end
	if SysTime () - self.LoadStartTime > self.LoadDuration then
		return self:GetPlaceholderImage ()
	end
	
	local imageCacheEntry = Gooey.ImageCacheEntry (self, image)
	self.Images [image] = imageCacheEntry
	return imageCacheEntry
end

function self:LoadImage (image)
	image = image:lower ()
	if self.Images [image] then
		return self.Images [image]
	end
	
	local imageCacheEntry = Gooey.ImageCacheEntry (self, image)
	self.Images [image] = imageCacheEntry
	return imageCacheEntry
end

Gooey.ImageCache = Gooey.ImageCache ()