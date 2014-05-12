local self = {}
Gooey.Tab = Gooey.MakeConstructor (self)

--[[
	Events:
		CloseRequested ()
			Fired when the close button of this tab has been clicked.
		ContentsChanged (Panel oldContents, Panel contents)
			Fired when the content panel of this tab has changed.
		Removed ()
			Fired when this tab has been removed and destroyed.
		TextChanged (text)
			Fired when this tab's header text has changed.
		VisibleChanged (visible)
			Fired when this tab's visibility has changed.
]]

function self:ctor ()
	self.TabControl = nil
	
	self.Visible = true
	
	self.Header = vgui.Create ("GTabHeader")
	self.Header:SetTab (self)
	self.Header:SetVisible (false)
	self.Contents = nil
	
	self.ContextMenu = nil
	self.OwnsContextMenu = false
	
	self:SetText ("Tab")
	
	Gooey.EventProvider (self)
end

function self:Focus ()
	if not self.Contents then return end
	self.Contents:Focus ()
end

function self:GetContents ()
	return self.Contents
end

function self:GetContextMenu ()
	return self.ContextMenu
end

function self:GetHeader ()
	return self.Header
end

function self:GetIcon ()
	return self.Header:GetIcon ()
end

function self:GetIndex ()
	return self.TabControl:GetTabIndex (self)
end

function self:GetTabControl ()
	return self.TabControl
end

function self:GetText ()
	return self.Header:GetText ()
end

function self:GetToolTipText ()
	return self.Header:GetToolTipText ()
end

function self:IsCloseButtonVisible ()
	return self.Header:IsCloseButtonVisible ()
end

function self:IsSelected ()
	if not self.TabControl then return false end
	return self.TabControl:GetSelectedTab () == self
end

function self:IsVisible ()
	return self.Visible
end

function self:LayoutContents ()
	if not self.Contents then return end
	if not self.Contents:IsValid () then return end
	if self.TabControl then
		self.Contents:SetParent (self.TabControl)
		
		local x, y, w, h = self.TabControl:GetContentRectangle ()
		self.Contents:SetPos (x, y)
		self.Contents:SetSize (w, h)
		self.Contents:SetVisible (self:IsSelected ())
	else
		self.Contents:SetVisible (false)
	end
end

function self:Remove ()
	self:SetTabControl (nil)
	if self.Contents then
		self.Contents:Remove ()
	end
	self.Header:Remove ()
	
	if self.ContextMenu then
		if self.OwnsContextMenu then
			self.ContextMenu:dtor ()
		end
		self.ContextMenu = nil
	end
	
	self:DispatchEvent ("Removed")
end

function self:Select ()
	if not self.TabControl then return end
	self.TabControl:SetSelectedTab (self)
end

function self:SetCloseButtonVisible (closeButtonVisible)
	self.Header:SetCloseButtonVisible (closeButtonVisible)
	return self
end

function self:SetContents (contents)
	if self.Contents == contents then return self end
	
	local oldContents = self.Contents
	self.Contents = contents
	
	self:LayoutContents ()
	
	self:DispatchEvent ("ContentsChanged", oldContents, self.Contents)
	return self
end

function self:SetContextMenu (contextMenu, giveOwnership)
	if self.ContextMenu then
		if self.OwnsContextMenu then
			self.ContextMenu:dtor ()
		end
		self.ContextMenu = nil
	end
	self.ContextMenu = contextMenu
	self.OwnsContextMenu = giveOwnership
	return self
end

function self:SetIcon (icon)
	self.Header:SetIcon (icon)
	return self
end

function self:SetTabControl (tabControl)
	if self.TabControl == tabControl then return end

	local lastTabControl = self.TabControl
	self.TabControl = tabControl
	
	if lastTabControl then
		self.Header:SetVisible (false)
		lastTabControl:RemoveTab (self, false)
	end
	
	if not self.TabControl then return end
	
	self.Header:SetParent (self.TabControl)
	self.Header:SetVisible (true)
	self.Header:SetHeight (self.TabControl:GetHeaderHeight ())
	self:LayoutContents ()
end

function self:SetText (text)
	self.Header:SetText (text)
	return self
end

function self:SetToolTipText (text)
	self.Header:SetToolTipText (text)
	return self
end

function self:SetVisible (visible)
	if self.Visible == visible then return self end
	
	self.Visible = visible
	self.Header:SetVisible (self.Visible)
	self:DispatchEvent ("VisibleChanged", self.Visible)
	
	return self
end