local self = {}
GLib.Rendering.Matrices.MatrixStack = GLib.MakeConstructor (self, GLib.Rendering.Matrices.IMatrixStack)

GLib.Rendering.Matrices.MatrixStack.NextStackId = 1
self.IdentityRevisionId = 1

function self:ctor (id)
	self.Top = GLib.Matrix.Identity (4)
	self.RevisionId = self.IdentityRevisionId
	
	self.Stack = GLib.Containers.Stack ()
	self.RevisionIdStack = GLib.Containers.Stack ()
	
	if id == nil then
		id = GLib.Rendering.Matrices.MatrixStack.NextStackId
		GLib.Rendering.Matrices.MatrixStack.NextStackId = GLib.Rendering.Matrices.MatrixStack.NextStackId + 1
	end
	
	self.NextRevisionId = id * 4294967296 + 2
end

function self:GetTop ()
	return self.Top
end

function self:SetTop (matrix)
	self:Set (matrix)
end

function self:Get ()
	return self.Top
end

function self:Push (matrix, pushOperation)
	pushOperation = pushOperation or GLib.Rendering.MatrixPushOperation.Override
	
	self.Stack:Push (self.Top)
	self.RevisionIdStack:Push (self.RevisionId)
	
	if pushOperation == GLib.Rendering.MatrixPushOperation.Override then
		self.Top = matrix
	elseif pushOperation == GLib.Rendering.MatrixPushOperation.PreMultiply then
		-- TODO: Do something about garbage. MatrixPool?
		self.Top = matrix * this.Top
	elseif pushOperation == GLib.Rendering.MatrixPushOperation.PostMultiply then
		-- TODO: Do something about garbage. MatrixPool?
		self.Top = this.Top * matrix
	end
	
	self.RevisionId = self.NextRevisionId
	self.NextRevisionId = self.NextRevisionId + 1
end

function self:PushIdentity ()
	self.Stack:Push (self.Top)
	self.RevisionIdStack:Push (self.RevisionId)
	self.Top = GLib.Matrix.Identity (4)
	self.RevisionId = self.IdentityRevisionId
end

function self:Pop ()
	if self.Stack.Count == 0 then
		GLib.Error ("MatrixStack:Pop : Underflow!")
		return
	end
	
	self.Top = self.Stack:Pop ()
	self.RevisionId = self.RevisionIdStack:Pop ()
end

function self:Set (matrix)
	self.Top = matrix
	self.RevisionId = self.NextRevisionId
	self.NextRevisionId = self.NextRevisionId + 1
end