local self = {}
Gooey.TextRenderer = Gooey.MakeConstructor (self)

--[[
	Events:
		FontChanged (font)
			Fired when the font has changed.
		ParametersChanged ()
			Fired when any of the rendering parameters have changed.
		TextChanged (text)
			Fired when the text has changed.
		WordWrapChanged (wordWrap)
			Fired when word wrapping has been enabled or disabled.
		WordWrapWidthChanged (wordWrapWidth)
			Fired when the word wrap width has changed.
]]

function self:ctor ()
	self.Width  = 256
	self.Height = 256
	
	self.Font = nil
	self.Text = nil
	self.WordWrap = false
	self.WordWrapWidth = 256
	
	self.Cache = nil
	self.CacheValid = false
	
	Gooey.EventProvider (self)
end

function self:GetFont ()
	return self.Font
end

function self:GetHeight ()
	if not self:IsCacheValid () then
		self.Cache = self:RebuildCache (self.Cache)
		self.CacheValid = true
	end
	return self.Height
end

function self:GetText ()
	return self.Text
end

function self:GetWidth ()
	if not self:IsCacheValid () then
		self.Cache = self:RebuildCache (self.Cache)
		self.CacheValid = true
	end
	return self.Width
end

function self:GetWordWrap ()
	return self.WordWrap
end

function self:GetWordWrapWidth ()
	return self.WordWrapWidth
end

function self:InvalidateCache ()
	self.CacheValid = false
end

function self:IsCacheValid ()
	return self.CacheValid
end

function self:RebuildCache (cache)
	cache = cache or {}
	return cache
end

function self:Render (renderContext, x, y, textColor)
	if not self.CacheValid then
		self.Cache = self:RebuildCache (self.Cache)
		self.CacheValid = true
	end
	self:RenderFromCache (renderContext, x or 0, y or 0, textColor or GLib.Colors.CornflowerBlue, self.Cache)
end

function self:RenderFromCache (renderContext, x, y, textColor, cache)
end

function self:SetFont (font)
	if self.Font == font then return end
	
	self.Font = font
	
	self:InvalidateCache ()
	
	self:DispatchEvent ("FontChanged", font)
	self:DispatchEvent ("ParametersChanged")
end

function self:SetHeight (height)
	self.Height = height
end

function self:SetText (text)
	text = tostring (text)
	if self.Text == text then return end
	
	self.Text = text
	
	self:InvalidateCache ()
	
	self:DispatchEvent ("TextChanged", text)
	self:DispatchEvent ("ParametersChanged")
end

function self:SetWidth (width)
	self.Width = width
end

function self:SetWordWrap (wordWrap)
	if self.WordWrap == wordWrap then return end
	
	self.WordWrap = wordWrap
	
	self:InvalidateCache ()
	
	self:DispatchEvent ("WordWrapChanged", wordWrap)
	self:DispatchEvent ("ParametersChanged")
end

function self:SetWordWrapWidth (wordWrapWidth)
	if self.WordWrapWidth == wordWrapWidth then return end
	
	self.WordWrapWidth = wordWrapWidth
	
	self:InvalidateCache ()
	
	self:DispatchEvent ("WordWrapWidthChanged", wordWrapWidth)
	self:DispatchEvent ("ParametersChanged")
end