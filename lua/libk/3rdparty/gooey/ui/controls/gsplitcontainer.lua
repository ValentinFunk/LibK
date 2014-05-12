local PANEL = {}

function PANEL:Init ()
	self.Orientation = Gooey.Orientation.Vertical
	
	self.Splitter = vgui.Create ("GSplitContainerSplitter", self)
	self.Panel1 = nil
	self.Panel2 = nil
	
	self.SplitterFraction = 0
	self.SplitterPosition = 0
	self.InverseSplitterPosition = 0
	
	self.SplitterThickness = 5
	
	self.FixedPanel = Gooey.SplitContainerPanel.None
	self.HiddenPanel = Gooey.SplitContainerPanel.None
	
	self.Splitter.DragController:AddEventListener ("PositionCorrectionChanged",
		function (_, deltaX, deltaY)
			local x, y = self.Splitter:GetPos ()
			local splitterPosition
			if self.Orientation == Gooey.Orientation.Vertical then
				splitterPosition = x + deltaX + self:GetSplitterThickness () * 0.5
			else
				splitterPosition = y + deltaY + self:GetSplitterThickness () * 0.5
			end
			self:SetSplitterPosition (splitterPosition)
		end
	)
	
	self:SetSize (100, 100)
	self:SetSplitterFraction (0.5)
end

function PANEL:GetFixedPanel ()
	return self.FixedPanel
end

function PANEL:GetHiddenPanel ()
	return self.HiddenPanel
end

function PANEL:GetOrientation ()
	return self.Orientation
end

function PANEL:GetPanel1 ()
	return self.Panel1
end

function PANEL:GetPanel2 ()
	return self.Panel2
end

function PANEL:GetSplitterFraction ()
	return self.SplitterFraction
end

function PANEL:GetSplitterPosition ()
	return self.SplitterPosition
end

function PANEL:GetSplitterThickness ()
	return self.SplitterThickness
end

function PANEL:Paint (w, h)
end

function PANEL:PerformLayout ()
	local splitterSize = self:GetSplitterThickness ()
	local size = self.Orientation == Gooey.Orientation.Vertical and self:GetWide () or self:GetTall ()
	local panel1Offset
	local panel2Offset
	local panel1Size
	local panel2Size
	
	panel1Offset = 0
	if self.FixedPanel == Gooey.SplitContainerPanel.None then
		panel2Offset = size * self.SplitterFraction + splitterSize * 0.5
		
		self.SplitterPosition = size * self.SplitterFraction
		self.InverseSplitterPosition = size - self.SplitterPosition
	elseif self.FixedPanel == Gooey.SplitContainerPanel.Panel1 then
		panel2Offset = self.SplitterPosition + splitterSize * 0.5
		
		self.InverseSplitterPosition = size - self.SplitterPosition
		self.SplitterFraction = self.SplitterPosition / size
	else
		panel2Offset = size - self.InverseSplitterPosition + splitterSize * 0.5
		
		self.SplitterPosition = size - self.InverseSplitterPosition
		self.SplitterFraction = self.SplitterPosition / size
	end
	panel1Size = panel2Offset - splitterSize
	panel2Size = size - panel2Offset
	
	local panel1X, panel1Y = 0, 0
	local panel2X, panel2Y = 0, 0
	local panel1Width, panel1Height = self:GetSize ()
	local panel2Width, panel2Height = self:GetSize ()
	
	panel2Size = panel2Offset + panel2Size - math.floor (panel2Offset)
	
	if self.Orientation == Gooey.Orientation.Vertical then
		panel1X = panel1Offset
		panel2X = panel2Offset
		panel1Width = panel1Size
		panel2Width = panel2Size
		
		self.Splitter:SetPos (panel2Offset - splitterSize, 0)
		self.Splitter:SetSize (splitterSize, self:GetTall ())
	else
		panel1Y = panel1Offset
		panel2Y = panel2Offset
		panel1Height = panel1Size
		panel2Height = panel2Size
		
		self.Splitter:SetPos (0, panel2Offset - splitterSize)
		self.Splitter:SetSize (self:GetWide (), splitterSize)
	end
	
	if self.HiddenPanel == Gooey.SplitContainerPanel.Panel1 then
		self.Panel1:SetVisible (false)
		self.Splitter:SetVisible (false)
		
		panel2X = 0
		panel2Y = 0
		panel2Width = self:GetWide ()
		panel2Height = self:GetTall ()
	elseif self.HiddenPanel == Gooey.SplitContainerPanel.Panel2 then
		self.Panel2:SetVisible (false)
		self.Splitter:SetVisible (false)
		
		panel1Width = self:GetWide ()
		panel1Height = self:GetTall ()
	else
		self.Panel1:SetVisible (true)
		self.Panel2:SetVisible (true)
		self.Splitter:SetVisible (true)
	end
	
	if self.Panel1 then
		self.Panel1:SetPos (panel1X, panel1Y)
		self.Panel1:SetSize (panel1Width, panel1Height)
	end
	if self.Panel2 then
		self.Panel2:SetPos (panel2X, panel2Y)
		self.Panel2:SetSize (panel2Width, panel2Height)
	end
end

function PANEL:SetFixedPanel (fixedPanel)
	fixedPanel = fixedPanel or Gooey.SplitContainerPanel.None
	
	if self.FixedPanel == fixedPanel then return end
	
	self.FixedPanel = fixedPanel
	self:InvalidateLayout ()
end

function PANEL:SetHiddenPanel (hiddenPanel)
	hiddenPanel = hiddenPanel or Gooey.SplitContainerPanel.None
	
	if self.HiddenPanel == hiddenPanel then return end
	
	self.HiddenPanel = hiddenPanel
	self:InvalidateLayout ()
end

function PANEL:SetOrientation (orientation)
	if self.Orientation == orientation then return end
	
	self.Orientation = orientation
	self.Splitter:SetOrientation (orientation)
	
	self:InvalidateLayout ()
end

function PANEL:SetPanel1 (panel)
	if self.Panel1 == panel then return end
	
	self.Panel1 = panel
	
	if self.Panel1 then
		self.Panel1:SetParent (self)
	end
	
	self:InvalidateLayout ()
end

function PANEL:SetPanel2 (panel)
	if self.Panel2 == panel then return end
	
	self.Panel2 = panel
	
	if self.Panel2 then
		self.Panel2:SetParent (self)
	end
	
	self:InvalidateLayout ()
end

function PANEL:SetSplitterFraction (splitterFraction)
	local size = self.Orientation == Gooey.Orientation.Vertical and self:GetWide () or self:GetTall ()
	
	if splitterFraction < 0 then splitterFraction = 0 end
	if splitterFraction > 1 then splitterFraction = 1 end
	
	self.SplitterPosition = size * splitterFraction
	self.InverseSplitterPosition = size - self.SplitterPosition
	self.SplitterFraction = splitterFraction
	
	self:InvalidateLayout ()
end

function PANEL:SetSplitterPosition (splitterPosition)
	local size = self.Orientation == Gooey.Orientation.Vertical and self:GetWide () or self:GetTall ()
	
	if splitterPosition < 0 then splitterPosition = 0 end
	if splitterPosition > size then splitterPosition = size end
	
	self.SplitterPosition = splitterPosition
	self.InverseSplitterPosition = size - self.SplitterPosition
	self.SplitterFraction = self.SplitterPosition / size
	
	self:InvalidateLayout ()
end

function PANEL:SetSplitterThickness (thickness)
	if self.SplitterThickness == thickness then return end
	
	self.SplitterThickness = thickness
	
	self:InvalidateLayout ()
end

PANEL.SetSplitterWidth = PANEL.SetSplitterThickness

Gooey.Register ("GSplitContainer", PANEL, "GPanel")