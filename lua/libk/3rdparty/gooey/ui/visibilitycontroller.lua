local self = {}
Gooey.VisibilityController = Gooey.MakeConstructor (self, Gooey.BooleanController)

--[[
	Events:
		VisibleChanged (visible)
			Fired when the visibility of the object this controller controls has changed.
]]

function self:ctor (control)
	self.Control = nil
	
	self:SetControl (control)
end

function self:dtor ()
	self:SetControl (nil)
end

function self:IsVisible ()
	return self.Control and self.Control:IsVisible () or false
end
self.GetValue = self.IsVisible

function self:SetControl (control)
	if self.Control == control then return end
	
	local visible = self:IsVisible ()
	self:UnhookControl (control)
	self.Control = control
	self:HookControl (control)
	
	if self:IsVisible () ~= visible then
		self:DispatchEvent ("ValueChanged",   self:IsVisible ())
		self:DispatchEvent ("VisibleChanged", self:IsVisible ())
	end
end

function self:SetVisible (visible)
	if not self.Control then return end
	
	self.Control:SetVisible (visible)
end
self.SetValue = self.SetVisible

-- Internal, do not call
function self:HookControl (control)
	if not control then return end
	
	control:AddEventListener ("VisibleChanged", self:GetHashCode (),
		function (_, visible)
			self:DispatchEvent ("ValueChanged",   visible)
			self:DispatchEvent ("VisibleChanged", visible)
		end
	)
	
	control:AddEventListener ("Removed", self:GetHashCode (),
		function (_)
			self:SetControl (nil)
		end
	)
end

function self:UnhookControl (control)
	if not control then return end
	
	control:RemoveEventListener ("VisibleChanged", self:GetHashCode ())
	control:RemoveEventListener ("Removed", self:GetHashCode ())
end