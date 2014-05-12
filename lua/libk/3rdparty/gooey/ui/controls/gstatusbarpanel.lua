local PANEL = {}

--[[
	Events:
		ContentsChanged (Panel oldContents, Panel contents)
			Fired when this panel's contents have changed.
]]

function PANEL:Init ()
	self.StatusBar = nil
	
	self.Contents = nil
	self.OwnsContents = false
	
	self.SizingMethod = Gooey.SizingMethod.ExpandToFit
	self.FixedWidth = 300
	self.PercentageWidth = 100
	
	self:AddEventListener ("BackgroundColorChanged",
		function (_, backgroundColor)
			if self.Contents and type (self.Contents.SetBackgroundColor) == "function" then
				self.Contents:SetBackgroundColor (backgroundColor)
			end
		end
	)
	
	self:AddEventListener ("TextChanged",
		function (_, text)
			if not self.Contents then return end
			self.Contents:SetText (text)
		end
	)
end

function PANEL:GetContents ()
	return self.Contents
end

function PANEL:GetProgress ()
	if not self.Contents then return 0 end
	if type (self.Contents.GetProgress) ~= "function" then return 0 end
	return self.Contents:GetProgress ()
end

function PANEL:GetSizingMethod ()
	return self.SizingMethod
end

function PANEL:GetFixedWidth ()
	return self.FixedWidth
end

function PANEL:GetPercentageWidth ()
	return self.PercentageWidth
end

function PANEL:GetText ()
	if not self.Contents then return end
	return self.Contents:GetText ()
end

function PANEL:IsFixedWidth ()
	return self.SizingMethod == Gooey.SizingMethod.FixedWidth
end

function PANEL:IsPercentageWidth ()
	return self.SizingMethod == Gooey.SizingMethod.PercentageWidth
end

function PANEL:Paint (w, h)
end

function PANEL:PerformLayout ()
	if self.Contents then
		self.Contents:SetPos (2, 2)
		self.Contents:SetSize (self:GetWide () - 4, self:GetTall () - 4)
		self.Contents:InvalidateLayout ()
	end
end

function PANEL:SetContents (contents, ownsContents)
	if self.Contents == contents then return end
	if ownsContents == nil then ownsContents = true end
	
	local oldContents = self.Contents
	
	if self.Contents then
		if self.OwnsContents then
			self.Contents:Remove ()
		end
		self.Contents = nil
	end
	
	self.Contents = contents
	self.OwnsContents = contents
	
	if self.Contents then
		self.Contents:SetParent (self)
		self.Contents:SetVisible (true)
	end
	
	self:DispatchEvent ("ContentsChanged", oldContents, self.Contents)
	
	self:InvalidateLayout ()
end

function PANEL:SetFixedWidth (width)
	self:SetSizingMethod (Gooey.SizingMethod.Fixed)
	
	if self.FixedWidth == width then return end
	self.FixedWidth = width
	self:GetParent ():InvalidateLayout ()
end

function PANEL:SetPercentageWidth (percentage)
	self:SetSizingMethod (Gooey.SizingMethod.Percentage)
	
	if self.PercentageWidth == percentage then return end
	self.PercentageWidth = percentage
	self:GetParent ():InvalidateLayout ()
end

function PANEL:SetSizingMethod (sizingMethod)
	if self.SizingMethod == sizingMethod then return end
	
	self.SizingMethod = sizingMethod
	self:GetParent ():InvalidateLayout ()
end

function PANEL:SetProgress (progress)
	if not self.Contents then return end
	if type (self.Contents.SetProgress) ~= "function" then return end
	if not progress then return end
	
	self.Contents:SetProgress (progress)
end

Gooey.Register ("GStatusBarPanel", PANEL, "GPanel")