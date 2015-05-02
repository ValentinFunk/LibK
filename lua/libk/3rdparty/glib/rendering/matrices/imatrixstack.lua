local self = {}
GLib.Rendering.Matrices.IMatrixStack = GLib.MakeConstructor (self)

function self:ctor ()
	self.RevisionId = 0
	
	self.Top = nil
end

function self:GetRevisionId ()
	return self.RevisionId
end

function self:GetTop ()
	GLib.Error ("IMatrixStack:GetTop : Not implemented.")
	
	return self.Top
end

function self:SetTop (matrix)
	GLib.Error ("IMatrixStack:SetTop : Not implemented.")
	
	self.Top = matrix
end

function self:Get ()
	GLib.Error ("IMatrixStack:Get : Not implemented.")
	
	return self.Top
end

function self:Push (matrix, pushOperation)
	GLib.Error ("IMatrixStack:Push : Not implemented.")
end

function self:PushIdentity ()
	GLib.Error ("IMatrixStack:PushIdentity : Not implemented.")
end

function self:Pop ()
	GLib.Error ("IMatrixStack:Pop : Not implemented.")
end

function self:Set (matrix)
	GLib.Error ("IMatrixStack:Set : Not implemented.")
	
	self.Top = matrix
end