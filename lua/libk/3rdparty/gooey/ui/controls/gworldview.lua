local PANEL = {}

function PANEL:Init ()
	self.DirectionalLight = {}
	self.FOV = 70
	
	self.AmbientLight = Color (50, 50, 50, 255)
	self.Color = Color (255, 255, 255, 255)
	
	self:SetDirectionalLight (BOX_TOP, Color (255, 255, 255))
	self:SetDirectionalLight (BOX_FRONT, Color (255, 255, 255))
	
	self.ScreenWidth = ScrW ()
	self.ScreenHeight = ScrH ()
	
	self.CameraPosition = LocalPlayer ():GetShootPos ()
	self.CameraAngle = LocalPlayer ():EyeAngles ()
	
	-- mouse input
	self.IsMouseDown = false
	self.MouseDownX = 0
	self.MouseDownY = 0
	self.MouseDownAngle = Angle (0, 0, 0)
	
	-- keyboard input
	self:SetKeyboardInputEnabled (true)
end

function PANEL:DisableScissorRect ()
	render.SetScissorRect (0, 0, 0, 0, false)
end

function PANEL:DrawEntities ()
	pcall (ents.GetByIndex (0).DrawModel, ents.GetByIndex (0))
	
	for _, ent in ipairs (ents.GetAll ()) do
		if ent:EntIndex () ~= 0 then
			pcall (ent.Draw or ent.DrawModel, ent)
		end
	end
	
	self:DispatchEvent ("PostDrawEntities")
end

function PANEL:EnableScissorRect ()
	local left, top = 0, 0
	local right, bottom = self.ScreenWidth, self.ScreenHeight
	
	local panel = self
	while panel and panel:IsValid () do
		local panelLeft, panelTop = panel:LocalToScreen (0, 0)
		local panelRight = panelLeft + panel:GetWide ()
		local panelBottom = panelTop + panel:GetTall ()
		
		if panelLeft > left		then left	= panelLeft		end
		if panelRight < right	then right	= panelRight	end
		if panelTop > top		then top	= panelTop		end
		if panelBottom < bottom	then bottom	= panelBottom	end
		
		panel = panel:GetParent ()
	end

	render.SetScissorRect (left, top, right, bottom, true)	
end

function PANEL:GetCameraAngle ()
	return self.CameraAngle
end

function PANEL:GetCameraPosition ()
	return self.CameraPosition
end

function PANEL:GetCameraTrace ()
	local traceInput =
		{
			start = self.CameraPosition,
			endpos = self.CameraPosition + self.CameraAngle:Forward () * 65536
		}
	
	return util.TraceLine (traceInput)
end

function PANEL:GetCameraTraceEntity ()
	local traceInput =
		{
			start = self.CameraPosition,
			endpos = self.CameraPosition + self.CameraAngle:Forward () * 65536
		}
	
	return util.TraceLine (traceInput).Entity
end

function PANEL:OnCursorMoved (x, y)
	if not self.IsMouseDown then
		return
	end
	local dx = x - self.MouseDownX
	local dy = y - self.MouseDownY
	self.CameraAngle = Angle (self.MouseDownAngle.p + dy * 0.5, self.MouseDownAngle.y - dx * 0.5, self.MouseDownAngle.r)
end

function PANEL:OnMousePressed (mouseCode)
	self:MouseCapture (true)
	self.IsMouseDown = true
	self.MouseDownX, self.MouseDownY = self:CursorPos ()
	self.MouseDownAngle = self.CameraAngle
end

function PANEL:OnMouseReleased (mouseCode)
	self.IsMouseDown = false
	self:MouseCapture (false)
end

function PANEL:Paint (w, h)
	draw.RoundedBox (4, 0, 0, w, h, Vector (128, 128, 128, 255))

	local x, y = self:LocalToScreen (0, 0)

	local rw, rh = w, h
	if w < h then
		rw, rh = h, h
	elseif h < w then
		rw, rh = w, w
	end
	local dx = (w - rw) * 0.5
	local dy = (h - rh) * 0.5
	
	self:SaveScreenSize ()
	cam.Start3D (self.CameraPosition, self.CameraAngle, self.FOV, math.max (0, x + dx), math.max (0, y + dy), rw, rh)
	cam.IgnoreZ (true)
	
	render.SuppressEngineLighting (true)
	render.SetLightingOrigin (Vector (0, 0, 0))
	render.ResetModelLighting (self.AmbientLight.r / 255, self.AmbientLight.g / 255, self.AmbientLight.b / 255)
	render.SetColorModulation (self.Color.r / 255, self.Color.g / 255, self.Color.b / 255)
	render.SetBlend (self.Color.a / 255)
	
	for i = 0, 6 do
		local col = self.DirectionalLight [i]
		if col then
			render.SetModelLighting (i, col.r / 255, col.g / 255, col.b / 255)
		end
	end
	
	self:EnableScissorRect ()
	pcall (self.DrawEntities, self)
	self:DisableScissorRect ()
	
	render.SuppressEngineLighting (false)
	cam.IgnoreZ (false)
	cam.End3D ()
	
	self:DispatchEvent ("Post3DRender")
end

function PANEL:SaveScreenSize ()
	self.ScreenWidth = ScrW ()
	self.ScreenHeight = ScrH ()
end

function PANEL:SetCameraAngle (angle)
	self.CameraAngle = angle
end

function PANEL:SetCameraPosition (pos)
	self.CameraPosition = pos
end

function PANEL:SetDirectionalLight (direction, color)
	self.DirectionalLight [direction] = color
end

function PANEL:Think ()
	if self:IsFocused () or self.IsMouseDown or self.Hovered then
		local scale = 10
		if input.IsKeyDown (KEY_LCONTORL) then
			scale = 5
		end
		if input.IsKeyDown (KEY_LSHIFT) then
			scale = 20
		end
		if input.IsKeyDown (KEY_W) then
			self.CameraPosition = self.CameraPosition + self.CameraAngle:Forward () * scale
		end
		if input.IsKeyDown (KEY_S) then
			self.CameraPosition = self.CameraPosition - self.CameraAngle:Forward () * scale
		end
		if input.IsKeyDown (KEY_A) then
			self.CameraPosition = self.CameraPosition - self.CameraAngle:Right () * scale
		end
		if input.IsKeyDown (KEY_D) then
			self.CameraPosition = self.CameraPosition + self.CameraAngle:Right () * scale
		end
		if input.IsKeyDown (KEY_SPACE) then
			self.CameraPosition = self.CameraPosition + Vector (0, 0, 1) * scale
		end
	end
end

Gooey.Register ("GWorldView", PANEL, "DPanel")