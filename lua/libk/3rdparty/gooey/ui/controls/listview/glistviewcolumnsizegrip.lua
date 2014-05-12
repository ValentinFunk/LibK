local PANEL = {}

function PANEL:Init ()
	self.Column = nil
	
	self:SetWide (8)
	self:SetCursor ("sizewe")
	
	self:SetZPos (10)
	
	self.DragController = Gooey.DragController (self)
	self.DragController:AddEventListener ("PositionCorrectionChanged",
		function (_, deltaX, deltaY)
			local width = self.Column:GetHeader ():GetWide () + deltaX
			width = math.max (0, self.Column:GetMinimumWidth (), width)
			self.Column:SetWidth (width)
			
			local _, y = self:GetPos ()
			self:SetPos (self.Column:GetHeader ():GetPos () + self.Column:GetHeader ():GetWide () - self:GetWide () / 2, y)
		end
	)
	
	self:AddEventListener ("RightClick",
		function (_)
			if not self:GetListView ():GetHeaderMenu () then return end
			self:GetListView ():GetHeaderMenu ():Show (self:GetListView (), self.Column)
		end
	)
end

function PANEL:GetListView ()
	return self.Column:GetListView ()
end

function PANEL:Paint (w, h)
end

function PANEL:SetColumn (column)
	self.Column = column
	return self
end

Gooey.Register ("GListViewColumnSizeGrip", PANEL, "GPanel")