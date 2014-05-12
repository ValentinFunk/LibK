local self = {}
Gooey.RenderContext = Gooey.MakeConstructor (self)

function self:ctor ()
	self.PreviousRenderTargets = {}
	self.ViewPortStack = {}
	self.ViewPortStackCount = 0
	
	self.ScreenWidth = 0
	self.ScreenHeight = 0
	
	self.DefaultViewPort =
	{
		x = 0,
		y = 0,
		w = 0,
		h = 0
	}
end

function self:ClearColor (color, a)
	render.Clear (color.r, color.g, color.b, a or color.a)
end

function self:ClearDepth ()
	render.ClearDepth ()
end

function self:PopRenderTarget ()
	render.SetRenderTarget (self.PreviousRenderTargets [#self.PreviousRenderTargets])
	self.PreviousRenderTargets [#self.PreviousRenderTargets] = nil
end

function self:PopViewPort ()
	self.ViewPortStackCount = self.ViewPortStackCount - 1
	
	local viewPort = self.ViewPortStack [self.ViewPortStackCount] or self.DefaultViewPort
	render.SetViewPort (viewPort.x, viewPort.y, viewPort.w, viewPort.h)
end

function self:PushRelativeViewPort (x, y, w, h)
	local previousViewPort = self.ViewPortStack [self.ViewPortStackCount]
	if previousViewPort then
		x = x + previousViewPort.x
		y = y + previousViewPort.y
	else
		self.ScreenHeight = ScrH ()
		self.ScreenWidth = ScrW ()
		self.DefaultViewPort.w = self.ScreenWidth
		self.DefaultViewPort.h = self.ScreenHeight
	end
	w = w or self.ScreenWidth
	h = h or self.ScreenHeight
	self.ViewPortStackCount = self.ViewPortStackCount + 1
	self.ViewPortStack [self.ViewPortStackCount] = self.ViewPortStack [self.ViewPortStackCount] or {}
	self.ViewPortStack [self.ViewPortStackCount].x = x
	self.ViewPortStack [self.ViewPortStackCount].y = y
	self.ViewPortStack [self.ViewPortStackCount].w = w
	self.ViewPortStack [self.ViewPortStackCount].h = h
	render.SetViewPort (x, y, w, h)
end

function self:PushRenderTarget (renderTarget)
	self.PreviousRenderTargets [#self.PreviousRenderTargets + 1] = render.GetRenderTarget ()
	render.SetRenderTarget (renderTarget)
end

function self:PushScreenViewPort ()
	if self.ViewPortStackCount == 0 then
		self.ScreenWidth = ScrW ()
		self.ScreenHeight = ScrH ()
		self.DefaultViewPort.w = self.ScreenWidth
		self.DefaultViewPort.h = self.ScreenHeight
	end
	self:PushViewPort (0, 0, self.ScreenWidth, self.ScreenHeight)
end

function self:PushViewPort (x, y, w, h)
	if self.ViewPortStackCount == 0 then
		self.ScreenWidth = ScrW ()
		self.ScreenHeight = ScrH ()
	end
	w = w or self.ScreenWidth
	h = h or self.ScreenHeight
	self.ViewPortStackCount = self.ViewPortStackCount + 1
	self.ViewPortStack [self.ViewPortStackCount] = self.ViewPortStack [self.ViewPortStackCount] or {}
	self.ViewPortStack [self.ViewPortStackCount].x = x
	self.ViewPortStack [self.ViewPortStackCount].y = y
	self.ViewPortStack [self.ViewPortStackCount].w = w
	self.ViewPortStack [self.ViewPortStackCount].h = h
	render.SetViewPort (x, y, w, h)
end

function self:SetRelativeViewPort (x, y, w, h)
	if self.ViewPortStackCount == 0 then
		self:PushViewPort (x, y, w, h)
		return
	end
	local previousViewPort = self.ViewPortStack [self.ViewPortStackCount - 1]
	if previousViewPort then
		x = x + previousViewPort.x
		y = y + previousViewPort.y
	end
	w = w or self.ScreenWidth
	h = h or self.ScreenHeight
	
	local viewPort = self.ViewPortStack [self.ViewPortStackCount]
	viewPort.x = x
	viewPort.y = y
	viewPort.w = w
	viewPort.h = h
	render.SetViewPort (x, y, w, h)
end

function self:SetViewPort (x, y, w, h)
	if self.ViewPortStackCount == 0 then
		self:PushViewPort (x, y, w, h)
		return
	end
	w = w or self.ScreenWidth
	h = h or self.ScreenHeight
	
	local viewPort = self.ViewPortStack [self.ViewPortStackCount]
	viewPort.x = x
	viewPort.y = y
	viewPort.w = w
	viewPort.h = h
	render.SetViewPort (x, y, w, h)
end

Gooey.RenderContext = Gooey.RenderContext ()