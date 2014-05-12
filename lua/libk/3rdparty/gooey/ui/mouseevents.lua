function Gooey.CreateMouseEvents (panel)
	function panel:OnCursorEntered ()
		self.Depressed = input.IsMouseDown (MOUSE_LEFT)
		self.Pressed   = input.IsMouseDown (MOUSE_LEFT)
		
		self:DispatchEvent ("MouseEnter")
		if self.OnMouseEnter then self:OnMouseEnter () end
	end

	function panel:OnCursorMoved (x, y)
		self:DispatchEvent ("MouseMove", 0, self:CursorPos ())
		
		local mouseCode = 0
		if input.IsMouseDown (MOUSE_LEFT)   then mouseCode = mouseCode + MOUSE_LEFT end
		if input.IsMouseDown (MOUSE_RIGHT)  then mouseCode = mouseCode + MOUSE_RIGHT end
		if input.IsMouseDown (MOUSE_MIDDLE) then mouseCode = mouseCode + MOUSE_MIDDLE end
		
		if self.OnMouseMove then self:OnMouseMove (mouseCode, self:CursorPos ()) end
	end

	function panel:OnCursorExited ()
		self:DispatchEvent ("MouseLeave")
		if self.OnMouseLeave then self:OnMouseLeave () end
	end

	function panel:OnMousePressed (mouseCode)
		self:DispatchEvent ("MouseDown", mouseCode, self:CursorPos ())
		if self.OnMouseDown then self:OnMouseDown (mouseCode, self:CursorPos ()) end
		
		if self:CanFocus () and
		   not self:IsFocused () and
		   not vgui.FocusedHasParent (self) then
			self:Focus ()
		end
		
		if mouseCode == MOUSE_LEFT then
			self.Depressed = true
			self.Pressed   = true
		end
	end

	function panel:OnMouseReleased (mouseCode)
		self:DispatchEvent ("MouseUp", mouseCode, self:CursorPos ())
		if self.OnMouseUp then self:OnMouseUp (mouseCode, self:CursorPos ()) end
		
		if mouseCode == MOUSE_LEFT then
			if SysTime () - (self.LastLeftMouseButtonReleaseTime or 0) < 0.4 then
				if self.OnDoubleClick then self:OnDoubleClick (mouseCode, self:CursorPos ()) end
				self:DispatchEvent ("DoubleClick", self:CursorPos ())
			else
				if self.OnClick then self:OnClick (mouseCode, self:CursorPos ()) end
				self:DispatchEvent ("Click", self:CursorPos ())
			end
			self.Depressed = false
			self.Pressed   = false
			
			self.LastLeftMouseButtonReleaseTime = SysTime ()
		elseif mouseCode == MOUSE_RIGHT then
			self:DispatchEvent ("RightClick", self:CursorPos ())
		end
	end

	function panel:OnMouseWheeled (delta)
		local handled = self:DispatchEvent ("MouseWheel", delta, self:CursorPos ())
		if self.OnMouseWheel then handled = handled or self:OnMouseWheel (delta, self:CursorPos ()) end
		if handled then return end
		
		if self:GetParent ().OnMouseWheeled then
			self:GetParent ():OnMouseWheeled (delta)
		end
	end
end