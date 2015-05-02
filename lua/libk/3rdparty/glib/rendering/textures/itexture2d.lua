local self = {}
GLib.Rendering.Textures.ITexture2d = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.Handle = nil
	
	self.Size = nil
	self.PixelFormat = GLib.Rendering.Textures.PixelFormat.R8G8B8A8
end

function self:dtor ()
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetHandle ()
	return self.Handle
end

function self:Destroy ()
	self:dtor ()
end

function self:GetSize ()
	return self.Size
end

function self:GetPixelFormat ()
	return self.PixelFormat
end

function self:SetPixels (mipMap, topLeft, size, pixels)
	GLib.Error ("ITexture2d:SetPixels : Not implemented.")
end