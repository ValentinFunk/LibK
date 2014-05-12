local PANEL = {}

function PANEL:Init ()
	self.Header = nil
	self.Column = nil
	
	self:SetCursor ("arrow")
	self:SetTextInset (8, 0)
	self:SetWide (256)
	
	self:AddEventListener ("RightClick",
		function (_)
			if not self:GetListView ():GetHeaderMenu () then return end
			self:GetListView ():GetHeaderMenu ():Show (self:GetListView (), self.Column)
		end
	)
end

function PANEL:GetColumn ()
	return self.Column
end

function PANEL:GetHeader ()
	return self.Header
end

function PANEL:GetListView ()
	return self.Column:GetListView ()
end

function PANEL:IsFirstColumn ()
	return self.Header:GetFirstHeader () == self
end

function PANEL:IsLastColumn ()
	return self.Header:GetLastHeader () == self
end

function PANEL:Paint (w, h)
	local x = 0
	if self:IsFirstColumn () then
		x = x - 1
		w = w + 1
	elseif self:IsLastColumn () then
		w = w + 1
	end
	
	-- Based on SKIN:PaintButton in skins/default.lua
	if self.Depressed then
		self:GetSkin ().tex.Button_Down (x, 0, w, h)
	elseif not self:IsEnabled () then
		self:GetSkin ().tex.Button_Dead (x, 0, w, h)
	elseif self:IsHovered () then
		self:GetSkin ().tex.Button_Hovered (x, 0, w, h)
	else
		self:GetSkin ().tex.Button (x, 0, w, h)
	end
end

local overlayColor = Color (GLib.Colors.CornflowerBlue.r, GLib.Colors.CornflowerBlue.g, GLib.Colors.CornflowerBlue.b, 64)
function PANEL:PaintOver (w, h)
	if self:GetListView ():GetSortColumnId () == self.Column:GetId () then
		surface.SetDrawColor (overlayColor)
		if self:IsFirstColumn () then
			surface.DrawRect (0, 1, w - 1, h - 2)
		else
			surface.DrawRect (1, 1, w - 2, h - 2)
		end
		
		if self:GetListView ():GetSortOrder () == Gooey.SortOrder.Ascending then
			Gooey.Glyphs.Draw ("up",   Gooey.RenderContext, GLib.Colors.Black, 0, 0, self:GetWide (), 8)
		else
			Gooey.Glyphs.Draw ("down", Gooey.RenderContext, GLib.Colors.Black, 0, 0, self:GetWide (), 8)
		end
	end
end

function PANEL:ResizeColumn (size)
	self:GetListView ():OnRequestResize (self:GetColumn (), size)
end

function PANEL:SetColumn (column)
	self.Column = column
end

function PANEL:SetHeader (header)
	self.Header = header
end

function PANEL:SetWidth (width)
	width = math.Clamp (width, self.m_iMinWidth, self.m_iMaxWidth)
	
	if width ~= self:GetWide () then
		self:GetListView ():SetDirty (true)
	end
	
	self:SetWide (width)
	return width
end

Gooey.Register ("GListViewColumnHeader", PANEL, "GButton")