local PANEL = {}

function PANEL:Init ()
	self:AddEventListener ("Click",
		function (_)
			self:RunAction ()
		end
	)
end

-- Event handlers
function PANEL:DoClick ()
	self:DispatchEvent ("Click")
end

function PANEL:DoRightClick ()
	self:DispatchEvent ("RightClick")
end

function PANEL:OnCursorEntered ()
	self:DispatchEvent ("MouseEnter")
	DButton.OnCursorEntered (self)
	if self.OnMouseEnter then self:OnMouseEnter () end
end

function PANEL:OnCursorExited ()
	self:DispatchEvent ("MouseLeave")
	DButton.OnCursorExited (self)
	if self.OnMouseLeave then self:OnMouseLeave () end
	
	self.Depressed = false
	self.Pressed = false
end

function PANEL:OnMousePressed (mouseCode)
	self:DispatchEvent ("MouseDown", mouseCode, self:CursorPos ())
	DButton.OnMousePressed (self, mouseCode)
	if self.OnMouseDown then self:OnMouseDown (mouseCode, self:CursorPos ()) end
	
	if mouseCode == MOUSE_LEFT then
		self.Depressed = true
		self.Pressed = true
	end
end

function PANEL:OnMouseReleased (mouseCode)
	self:DispatchEvent ("MouseUp", mouseCode, self:CursorPos ())
	DButton.OnMouseReleased (self, mouseCode)
	if self.OnMouseUp then self:OnMouseUp (mouseCode, self:CursorPos ()) end
	
	if mouseCode == MOUSE_LEFT then
		self.Depressed = false
		self.Pressed = false
	end
end

Gooey.Register ("GButton", PANEL, "DButton")