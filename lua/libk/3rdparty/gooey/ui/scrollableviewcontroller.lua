local self = {}
Gooey.ScrollableViewController = Gooey.MakeConstructor (self)

--[[
	Events:
		ContentHeightChanged (contentHeight)
			Fired when the content height has changed.
		ContentWidthChanged (contentWidth)
			Fired when the content width has changed.
		ContentSizeChanged (contentWidth, contentHeight)
			Fired when the content size has changed.
		InterpolatedViewPositionChanged (interpolatedViewX, interpolatedViewY)
			Fired when the interpolated view position has changed.
		InterpolatedViewXChanged (interpolatedViewX)
			Fired when the interpolated view x-coordinate has changed.
		InterpolatedViewYChanged (interpolatedViewY)
			Fired when the interpolated view y-coordinate has changed.
		ViewHeightChanged (viewHeight)
			Fired when the view height has changed.
		ViewPositionChanged (viewX, viewY)
			Fired when the view position has changed.
		ViewSizeChanged (viewWidth, viewHeight)
			Fired when the view size has changed.
		ViewWidthChanged (viewWidth)
			Fired when the view width has changed.
		ViewXChanged (viewX)
			Fired when the view x-coordinate has changed.
		ViewYChanged (viewY)
			Fired when the view y-coordinate has changed.
]]

function self:ctor ()
	self.ContentWidth  = 0
	self.ContentHeight = 0
	
	self.ViewWidth  = 0
	self.ViewHeight = 0
	self.ViewWidthWithScrollBars  = nil
	self.ViewHeightWithScrollBars = nil
	
	self.ViewX = 0
	self.ViewY = 0
	
	self.VerticalScrollBar   = nil
	self.HorizontalScrollBar = nil
	self.ScrollBarCorner     = nil
	
	self.AutoHideVerticalScrollBar   = true
	self.AutoHideHorizontalScrollBar = true
	
	Gooey.EventProvider (self)
end

function self:dtor ()
end

function self:GetContentHeight ()
	return self.ContentHeight
end

function self:GetContentWidth ()
	return self.ContentWidth
end

function self:GetInterpolatedViewX ()
	if self.HorizontalScrollBar then
		return self.HorizontalScrollBar:GetInterpolatedViewOffset ()
	end
	return self.ViewX
end

function self:GetInterpolatedViewY ()
	if self.VerticalScrollBar then
		return self.VerticalScrollBar:GetInterpolatedViewOffset ()
	end
	return self.ViewY
end

function self:GetViewHeight ()
	return self.ViewHeight
end

function self:GetViewHeightWithScrollBars ()
	if self.ViewHeightWithScrollBars then return self.ViewHeightWithScrollBars end
	if self.HorizontalScrollBar then return self.ViewHeight - self.HorizontalScrollBar:GetTall () end
	return self.ViewHeight
end

function self:GetViewWidth ()
	return self.ViewWidth
end

function self:GetViewWidthWithScrollBars ()
	if self.ViewWidthWithScrollBars then return self.ViewWidthWithScrollBars end
	if self.VerticalScrollBar then return self.ViewWidth - self.VerticalScrollBar:GetWide () end
	return self.ViewWidth
end

function self:GetViewX ()
	return self.ViewX
end

function self:GetViewY ()
	return self.ViewY
end

function self:IsHorizontalScrollBarVisible ()
	if not self.HorizontalScrollBar then return end
	return self.HorizontalScrollBar:IsVisible ()
end

function self:IsVerticalScrollBarVisible ()
	if not self.VerticalScrollBar then return end
	return self.VerticalScrollBar:IsVisible ()
end

function self:SetContentHeight (contentHeight)
	if self.ContentHeight == contentHeight then return self end
	
	self.ContentHeight = contentHeight
	
	if self.VerticalScrollBar then
		self.VerticalScrollBar:SetContentSize (self.ContentHeight)
	end
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ContentHeightChanged", self.ContentHeight)
	self:DispatchEvent ("ContentSizeChanged", self.ContentWidth, self.ContentHeight)
	return self
end

function self:SetContentSize (contentWidth, contentHeight)
	if self.ContentWidth  == contentWidth and
	   self.ContentHeight == contentHeight then
		return
	end
	
	self.ContentWidth  = contentWidth
	self.ContentHeight = contentHeight
	
	if self.HorizontalScrollBar then
		self.HorizontalScrollBar:SetContentSize (self.ContentWidth)
	end
	if self.VerticalScrollBar then
		self.VerticalScrollBar:SetContentSize (self.ContentHeight)
	end
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ContentWidthChanged", self.ContentWidth)
	self:DispatchEvent ("ContentHeightChanged", self.ContentHeight)
	self:DispatchEvent ("ContentSizeChanged", self.ContentWidth, self.ContentHeight)
end

function self:SetContentWidth (contentWidth)
	if self.ContentWidth == contentWidth then return self end
	
	self.ContentWidth = contentWidth
	
	if self.HorizontalScrollBar then
		self.HorizontalScrollBar:SetContentSize (self.ContentWidth)
	end
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ContentWidthChanged", self.ContentWidth)
	self:DispatchEvent ("ContentSizeChanged", self.ContentWidth, self.ContentHeight)
	return self
end

function self:SetViewHeight (viewHeight)
	if self.ViewHeight == viewHeight then return self end
	
	self.ViewHeight = viewHeight
	
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ViewHeightChanged", self.ViewHeight)
	self:DispatchEvent ("ViewSizeChanged", self.ViewWidth, self.ViewHeight)
	return self
end

function self:SetViewHeightWithScrollBars (viewHeightWithScrollBars)
	if self.ViewHeightWithScrollBars == viewHeightWithScrollBars then return self end
	
	self.ViewHeightWithScrollBars = viewHeightWithScrollBars
	
	self:UpdateScrollBarViewSize ()
	
	return self
end

function self:SetViewSize (viewWidth, viewHeight)
	if self.ViewWidth  == viewWidth and
	   self.ViewHeight == viewHeight then
		return self
	end
	
	self.ViewWidth  = viewWidth
	self.ViewHeight = viewHeight
	
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ViewWidthChanged", self.ViewWidth)
	self:DispatchEvent ("ViewHeightChanged", self.ViewHeight)
	self:DispatchEvent ("ViewSizeChanged", self.ViewWidth, self.ViewHeight)
	return self
end

function self:SetViewSizeWithScrollBars (viewWidthWithScrollBars, viewHeightWithScrollBars)
	if self.ViewWidthWithScrollBars  == viewWidthWithScrollBars and
	   self.ViewHeightWithScrollBars == viewHeightWithScrollBars then
		return
	end
	
	self.ViewWidthWithScrollBars  = viewWidthWithScrollBars
	self.ViewHeightWithScrollBars = viewHeightWithScrollBars
	
	self:UpdateScrollBarViewSize ()
	
	return self
end

function self:SetViewWidth (viewWidth)
	if self.ViewWidth == viewWidth then return self end
	
	self.ViewWidth = viewWidth
	
	self:UpdateScrollBarViewSize ()
	
	self:DispatchEvent ("ViewWidthChanged", self.ViewWidth)
	self:DispatchEvent ("ViewSizeChanged", self.ViewWidth, self.ViewHeight)
	return self
end

function self:SetViewWidthWithScrollBars (viewWidthWithScrollBars)
	if self.ViewWidthWithScrollBars == viewWidthWithScrollBars then return self end
	
	self.ViewWidthWithScrollBars = viewWidthWithScrollBars
	
	self:UpdateScrollBarViewSize ()
	
	return self
end

function self:SetViewX (viewX)
	if self.ViewX == viewX then return self end
	self.ViewX = viewX
	
	if self.HorizontalScrollBar then
		self.HorizontalScrollBar:SetViewOffset (self.ViewX)
	end
	
	self:DispatchEvent ("ViewXChanged", self.ViewX)
	self:DispatchEvent ("ViewPositionChanged", self.ViewX, self.ViewY)
	return self
end

function self:SetViewY (viewY)
	if self.ViewY == viewY then return self end
	self.ViewY = viewY
	
	if self.VerticalScrollBar then
		self.VerticalScrollBar:SetViewOffset (self.ViewY)
	end
	
	self:DispatchEvent ("ViewYChanged", self.ViewY)
	self:DispatchEvent ("ViewPositionChanged", self.ViewX, self.ViewY)
	return self
end

-- Controls
function self:GetHorizontalScrollBar ()
	return self.HorizontalScrollBar
end

function self:GetScrollBarCorner ()
	return self.ScrollBarCorner
end

function self:GetVerticalScrollBar ()
	return self.VerticalScrollBar
end

function self:SetAutoHideHorizontalScrollBar (autoHideHorizontalScrollBar)
	if self.AutoHideHorizontalScrollBar == autoHideHorizontalScrollBar then return self end
	
	self.AutoHideHorizontalScrollBar = autoHideHorizontalScrollBar
	self:UpdateHorizontalScrollBarVisibility ()
	return self
end

function self:SetAutoHideVerticalScrollBar (autoHideVerticalScrollBar)
	if self.AutoHideVerticalScrollBar == autoHideHVerticalScrollBar then return self end
	
	self.AutoHideVerticalScrollBar = autoHideVerticalScrollBar
	self:UpdateVerticalScrollBarVisibility ()
	return self
end

function self:SetHorizontalScrollBar (horizontalScrollBar)
	self:UnhookHorizontalScrollBar (self.HorizontalScrollBar)
	self.HorizontalScrollBar = horizontalScrollBar
	
	if self.HorizontalScrollBar then
		self.HorizontalScrollBar:SetContentSize (self:GetContentWidth ())
		self.HorizontalScrollBar:SetViewSize (self:GetViewWidth ())
		self.HorizontalScrollBar:SetViewOffset (self:GetViewX ())
		self:UpdateHorizontalScrollBarVisibility ()
		self:HookHorizontalScrollBar (self.HorizontalScrollBar)
	end
	
	return self
end

function self:SetScrollBarCorner (scrollBarCorner)
	self.ScrollBarCorner = scrollBarCorner
	return self
end

function self:SetVerticalScrollBar (verticalScrollBar)
	self:UnhookVerticalScrollBar (self.VerticalScrollBar)
	self.VerticalScrollBar = verticalScrollBar
	
	if self.VerticalScrollBar then
		self.VerticalScrollBar:SetContentSize (self:GetContentHeight ())
		self.VerticalScrollBar:SetViewSize (self:GetViewHeight ())
		self.VerticalScrollBar:SetViewOffset (self:GetViewY ())
		self:UpdateVerticalScrollBarVisibility ()
		self:HookVerticalScrollBar (self.VerticalScrollBar)
	end
	
	return self
end

function self:ShouldAutoHideHorizontalScrollBar ()
	return self.AutoHideHorizontalScrollBar
end

function self:ShouldAutoHideVerticalScrollBar ()
	return self.AutoHideVerticalScrollBar
end

-- Internal, do not call
function self:HookHorizontalScrollBar (horizontalScrollBar)
	if not horizontalScrollBar then return end
	
	horizontalScrollBar:AddEventListener ("InterpolatedScroll", self:GetHashCode (),
		function (_, interpolatedViewX)
			self:DispatchEvent ("InterpolatedViewXChanged", interpolatedViewX)
			self:DispatchEvent ("InterpolatedViewPositionChanged", interpolatedViewX, self:GetInterpolatedViewY ())
		end
	)
	horizontalScrollBar:AddEventListener ("Removed", self:GetHashCode (),
		function (_)
			self:SetHorizontalScrollBar (nil)
		end
	)
	horizontalScrollBar:AddEventListener ("Scroll", self:GetHashCode (),
		function (_, viewX)
			self:SetViewX (horizontalScrollBar:GetViewOffset ())
		end
	)
end

function self:UnhookHorizontalScrollBar (horizontalScrollBar)
	if not horizontalScrollBar then return end
	
	horizontalScrollBar:RemoveEventListener ("InterpolatedScroll", self:GetHashCode ())
	horizontalScrollBar:RemoveEventListener ("Removed",            self:GetHashCode ())
	horizontalScrollBar:RemoveEventListener ("Scroll",             self:GetHashCode ())
end

function self:HookVerticalScrollBar (verticalScrollBar)
	if not verticalScrollBar then return end
	
	verticalScrollBar:AddEventListener ("InterpolatedScroll", self:GetHashCode (),
		function (_, interpolatedViewY)
			self:DispatchEvent ("InterpolatedViewYChanged", interpolatedViewY)
			self:DispatchEvent ("InterpolatedViewPositionChanged", self:GetInterpolatedViewX (), interpolatedViewY)
		end
	)
	verticalScrollBar:AddEventListener ("Removed", self:GetHashCode (),
		function (_)
			self:SetVerticalScrollBar (nil)
		end
	)
	verticalScrollBar:AddEventListener ("Scroll", self:GetHashCode (),
		function (_, viewY)
			self:SetViewY (verticalScrollBar:GetViewOffset ())
		end
	)
end

function self:UnhookVerticalScrollBar (verticalScrollBar)
	if not verticalScrollBar then return end
	
	verticalScrollBar:RemoveEventListener ("InterpolatedScroll", self:GetHashCode ())
	verticalScrollBar:RemoveEventListener ("Removed",            self:GetHashCode ())
	verticalScrollBar:RemoveEventListener ("Scroll",             self:GetHashCode ())
end

function self:UpdateHorizontalScrollBarVisibility ()
	if not self.HorizontalScrollBar then return end
	
	if self:ShouldAutoHideHorizontalScrollBar () then
		self.HorizontalScrollBar:SetVisible (self.HorizontalScrollBar:IsEnabled ())
	else
		self.HorizontalScrollBar:SetVisible (true)
	end
	
	if self.ScrollBarCorner then
		self.ScrollBarCorner:SetVisible (self:IsVerticalScrollBarVisible () and self:IsHorizontalScrollBarVisible ())
	end
end

function self:UpdateVerticalScrollBarVisibility ()
	if not self.VerticalScrollBar then return end
	
	if self:ShouldAutoHideVerticalScrollBar () then
		self.VerticalScrollBar:SetVisible (self.VerticalScrollBar:IsEnabled ())
	else
		self.VerticalScrollBar:SetVisible (true)
	end
	
	if self.ScrollBarCorner then
		self.ScrollBarCorner:SetVisible (self:IsVerticalScrollBarVisible () and self:IsHorizontalScrollBarVisible ())
	end
end

function self:UpdateScrollBarViewSize ()
	local verticalScrollBarNeeded = self.ViewHeight < self.ContentHeight
	local realViewWidth = verticalScrollBarNeeded and self:GetViewWidthWithScrollBars () or self.ViewWidth
	
	local horizontalScrollBarNeeded = realViewWidth < self.ContentWidth
	local realViewHeight = horizontalScrollBarNeeded and self:GetViewHeightWithScrollBars () or self.ViewHeight
	
	verticalScrollBarNeeded = self.ViewHeight < self.ContentHeight
	realViewWidth = verticalScrollBarNeeded and self:GetViewWidthWithScrollBars () or self.ViewWidth
	
	if self.VerticalScrollBar then
		self.VerticalScrollBar:SetViewSize (realViewHeight)
		self:UpdateVerticalScrollBarVisibility ()
	end
	if self.HorizontalScrollBar then
		self.HorizontalScrollBar:SetViewSize (realViewWidth)
		self:UpdateHorizontalScrollBarVisibility ()
	end
end