local self = {}
Gooey.VPanelContainer = Gooey.MakeConstructor (self)

function self:ctor (control)
	self.Control = control
	
	self.Controls = {}
	self.HoveredControl = nil
	self.MouseCaptured = false
	
	if not control then
		Gooey.Error ("VPanelContainers must be constructed with a host VGUI panel.")
		return
	end
	
	control:AddEventListener ("MouseDown",
		function (_, mouseCode, x, y)
			local control = self:GetHoveredControl ()
			if not control then return end
			control:DispatchEvent ("MouseDown", mouseCode, control:ParentToLocal (x, y))
		end
	)
	
	control:AddEventListener ("MouseEnter",
		function (_)
			if self.MouseCaptured then return end
			
			local x, y = self.Control:CursorPos ()
			self:SetHoveredControl (self:ControlFromPoint (x, y))
		end
	)
	
	control:AddEventListener ("MouseLeave",
		function (_)
			if self.MouseCaptured then return end
			
			self:SetHoveredControl (nil)
		end
	)
	
	control:AddEventListener ("MouseMove",
		function (_, mouseCode, x, y)
			if not self.MouseCaptured then
				self:SetHoveredControl (self:ControlFromPoint (x, y))
			end
			
			local control = self:GetHoveredControl ()
			if not control then return end
			control:DispatchEvent ("MouseMove", mouseCode, control:ParentToLocal (x, y))
		end
	)
	
	control:AddEventListener ("MouseUp",
		function (_, mouseCode, x, y)
			local control = self:GetHoveredControl ()
			if not control then return end
			control:DispatchEvent ("MouseUp", mouseCode, control:ParentToLocal (x, y))
		end
	)
end

function self:AddControl (control)
	self.Controls [#self.Controls + 1] = control
	control:SetParent (self)
end

function self:CaptureMouse (capture, control)
	if capture then
		self.MouseCaptured = true
		self.Control:MouseCapture (true)
		self:SetHoveredControl (control)
	else
		self.MouseCaptured = false
		self.Control:MouseCapture (false)
		self:SetHoveredControl (self:ControlFromPoint (self.Control:CursorPos ()))
	end
end

function self:Clear ()
	for _, control in ipairs (self.Controls) do
		control:Remove ()
	end
	self.Controls = {}
	self.HoveredControl = nil
end

function self:GetHoveredControl ()
	return self.HoveredControl
end

function self:ControlFromPoint (x, y)
	for _, control in pairs (self.Controls) do
		if control:IsVisible () and
		   control:ContainsPoint (control:ParentToLocal (x, y)) then
			return control
		end
	end
	return nil
end

function self:GetParent ()
	return self.Control
end

function self:IsHovered ()
	return self.Control and self.Control.IsHovered and self.Control:IsHovered () or false
end

function self:IsSelected ()
	return self.Control and self.Control.IsSelected and self.Control:IsSelected () or false
end

function self:IsValid ()
	return true
end

function self:IsVisible ()
	if not self.Control then return false end
	
	return self.Control:IsVisible ()
end

function self:LocalToScreen (x, y)
	return self.Control:LocalToScreen (x, y)
end

function self:Paint (renderContext)
	renderContext = renderContext or Gooey.RenderContext
	
	-- Calculate scissor rect
	-- Start in local panel coordinates and work upwards until screen coordinates
	local panel = self.Control
	
	local left, top = 0, 0
	local right, bottom = panel:GetSize ()
	
	local dx, dy = panel:GetPos ()
	panel = panel:GetParent ()
	while panel and panel:IsValid () do
		left   = left   + dx
		top    = top    + dy
		right  = right  + dx
		bottom = bottom + dy
		
		local w, h = panel:GetSize ()
		if left   < 0 then left   = 0 end
		if top    < 0 then top    = 0 end
		if right  > w then right  = w end
		if bottom > h then bottom = h end
		
		dx, dy = panel:GetPos ()
		panel = panel:GetParent ()
	end
	
	-- Apply scissor rect
	render.SetScissorRect (left, top, right, bottom, true)
	renderContext:PushScreenViewPort ()
	
	-- Render children
	local control = nil
	for i = 1, #self.Controls do
		control = self.Controls [i]
		if control:IsVisible () then
			renderContext:SetRelativeViewPort (control:GetLeft (), control:GetTop ())
			surface.DisableClipping (true)
			control:Paint (renderContext)
		end
	end
	
	-- Restore render settings
	renderContext:PopViewPort ()
	render.SetScissorRect (0, 0, ScrW (), ScrH (), false)
	surface.DisableClipping (false)
end

function self:SetHoveredControl (control)
	if self.HoveredControl == control then return end
	
	if self.HoveredControl then
		self.HoveredControl:SetHovered (false)
	end
	
	self.HoveredControl = control
	
	if self.HoveredControl then
		self.HoveredControl:SetHovered (true)
	end
end