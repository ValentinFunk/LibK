local self = {}
Gooey.DragDropController = Gooey.MakeConstructor (self)

--[[
	Events:
		ControlChanged (oldControl, control)
			Fired when this DragDropController's control has changed.
]]

function self:ctor (control)
	self.Control = nil
	
	Gooey.EventProvider (self)
	
	self.DropTargetEnabled = false
	
	self.DragRenderer = Gooey.NullCallback
	self.DropRenderer = Gooey.NullCallback
	
	-- Dragging
	self.Dragging = false
	self.ObjectType = nil
	self.Object = nil
	
	self.LastDragX = 0
	self.LastDragY = 0
	self.HoveredPanel = nil
	
	-- Dropping
	self.Hovered = false
	self.LastDropX = 0
	self.LastDropY = 0
	
	self:SetControl (control)
end

function self:dtor ()
	self:EndDrag ()
	self:DragLeave ()
	self:SetControl (nil)
end

function self:EndDrag ()
	if not self.Dragging then return end
	self.Dragging = false
	
	if self.HoveredPanel and self.HoveredPanel.DropTarget then
		self.HoveredPanel.DropTarget:DragDrop (self)
	end
	
	Gooey.RemoveRenderHook (Gooey.RenderType.DragDropPreview, "Gooey.DragDropController." .. self:GetHashCode ())
	hook.Remove ("PreRender", "Gooey.DragDropController." .. self:GetHashCode ())
	self:SetHoveredPanel (nil)
end

function self:GetControl ()
	return self.Control
end

function self:GetObjectType ()
	return self.ObjectType
end

function self:GetObject ()
	return self.Object
end

function self:IsDropTargetEnabled (dragTargetEnabled)
	return self.DropTargetEnabled
end

function self:IsHovered ()
	return self.Hovered
end

function self:SetControl (control)
	if self.Control == control then return end
	
	local oldControl = self.Control
	if self.Control then
		self.Control.DropTarget = nil
	end
	
	self:UnhookControl (self.Control)
	self.Control = control
	self:HookControl (self.Control)
	
	if self.Control then
		self.Control.DropTarget = self
	end
	
	self:OnControlChanged (oldControl, control)
	self:DispatchEvent ("ControlChanged", oldControl, control)
end

function self:SetDragRenderer (dragRenderer)
	self.DragRenderer = dragRenderer or Gooey.NullCallback
end

function self:SetDropRenderer (dropRenderer)
	self.DropRenderer = dropRenderer or Gooey.NullCallback
end

function self:SetDropTargetEnabled (dropTargetEnabled)
	self.DropTargetEnabled = dropTargetEnabled
end

function self:StartDrag (type, object)
	if self.Dragging then return false end
	self.Dragging = true
	
	self.ObjectType = type   or self.Control.ClassName
	self.Object     = object or self.Control
	
	Gooey.AddRenderHook (Gooey.RenderType.DragDropPreview, "Gooey.DragDropController." .. self:GetHashCode (),
		function ()
			if self.HoveredPanel and self.HoveredPanel.DropTarget then
				self.HoveredPanel.DropTarget.DropRenderer (self.HoveredPanel.DropTarget, gui.MousePos ())
			end
			self.DragRenderer (self, gui.MousePos ())
		end
	)
	
	hook.Add ("PreRender", "Gooey.DragDropController." .. self:GetHashCode (),
		function ()
			if not input.IsMouseDown (MOUSE_LEFT) then
				self:EndDrag ()
				return
			end
			
			local mouseX, mouseY = gui.MousePos ()
			if mouseX == self.LastDragX and mouseY == self.LastDragY then return end
			self.LastDragX = mouseX
			self.LastDragY = mouseY
			
			local hoveredPanel = vgui.GetHoveredPanel ()
			while true do
				if not hoveredPanel then break end
				if not hoveredPanel:IsValid () then hoveredPanel = nil break end
				if hoveredPanel.DropTarget and hoveredPanel.DropTarget:IsDropTargetEnabled () then break end
				hoveredPanel = hoveredPanel:GetParent ()
			end
			
			self:SetHoveredPanel (hoveredPanel)
			if self.HoveredPanel then
				self.HoveredPanel.DropTarget:DragOver (self, self.HoveredPanel:CursorPos ())
			end
		end
	)
end

-- Internal, do not call
function self:DragDrop (dragDropController)
	if not self.Control then return end
	if self.Control.OnDragDrop then
		self.Control:OnDragDrop (dragDropController)
	end
	if not self.Control then return end
	self.Control:DispatchEvent ("DragDrop", dragDropController)
	
	self:OnDragDrop (self.Control, dragDropController)
	self:DispatchEvent ("DragDrop", self.Control, dragDropController)
end

function self:DragEnter (dragDropController, lastDropPanel)
	if self.Hovered then return end
	self.Hovered = true
	
	if not self.Control then return end
	if self.Control.OnDragEnter then
		self.Control:OnDragEnter (dragDropController, lastDropPanel)
	end
	if not self.Control then return end
	self.Control:DispatchEvent ("DragEnter", dragDropController, lastDropPanel)
	
	self:OnDragEnter (self.Control, dragDropController, lastDropPanel)
	self:DispatchEvent ("DragEnter", self.Control, dragDropController, lastDropPanel)
end

function self:DragLeave (dragDropController, newDropPanel)
	if not self.Hovered then return end
	self.Hovered = false
	
	if not self.Control then return end
	if self.Control.OnDragLeave then
		self.Control:OnDragLeave (dragDropController, newDropPanel)
	end
	if not self.Control then return end
	self.Control:DispatchEvent ("DragLeave", dragDropController, newDropPanel)
	
	self:OnDragLeave (self.Control, dragDropController, newDropPanel)
	self:DispatchEvent ("DragLeave", self.Control, dragDropController, newDropPanel)
end

function self:DragOver (dragDropController, x, y)
	self.LastDropX = gui.MouseX ()
	self.LastDropY = gui.MouseY ()
	
	if not self.Control then return end
	if self.Control.OnDragOver then
		self.Control:OnDragOver (dragDropController, x, y)
	end
	if not self.Control then return end
	self.Control:DispatchEvent ("DragOver", dragDropController, x, y)
	
	self:OnDragOver (self.Control, dragDropController, x, y)
	self:DispatchEvent ("DragOver", self.Control, dragDropController, x, y)
end

function self:SetHoveredPanel (hoveredPanel)
	if self.HoveredPanel == hoveredPanel then return end
	
	local oldHoveredPanel = self.HoveredPanel
	if self.HoveredPanel and self.HoveredPanel.DropTarget then
		self.HoveredPanel.DropTarget:DragLeave (self, hoveredPanel)
	end
	
	self.HoveredPanel = hoveredPanel
	
	if self.HoveredPanel then
		self.HoveredPanel.DropTarget:DragEnter (self, oldHoveredPanel)
	end
end

function self:HookControl (control)
	if not control then return end
	
	control:AddEventListener ("Removed", self:GetHashCode (),
		function ()
			self:dtor ()
		end
	)
end

function self:UnhookControl (control)
	if not control then return end
	
	control:RemoveEventListener ("Removed", self:GetHashCode ())
end

-- Event handlers
function self:OnControlChanged (oldControl, control)
end

function self:OnDragDrop (control, dragDropController)
end

function self:OnDragEnter (control, dragDropController, lastDropPanel)
end

function self:OnDragLeave (control, dragDropController, newDropPanel)
end

function self:OnDragOver (control, dragDropController, x, y)
end