local self = {}
GLib.Rendering.Buffers.BufferLayout = GLib.MakeConstructor (self)

function self:ctor (...)
	self.Locked = false
	
	self.SemanticCounts = {}
	self.Elements = GLib.Containers.List ()
	self.ElementIndices = {}
	
	self.SizeValid = false
	self.Size = nil
	
	self:AddRange ({...})
end

function self:GetEnumerator ()
	return self.Elements:GetEnumerator ()
end

function self:Add (bufferElement)
	if self.Locked then
		GLib.Error ("BufferLayout:Add : This BufferLayout is locked!")
	end
	
	if type (bufferElement) == "number" then
		bufferElement = GLib.Rendering.Buffers.BufferElement (bufferElement)
	end
	
	if not self.SemanticCounts [bufferElement:GetSemantic ()] then
		self.SemanticCounts [bufferElement:GetSemantic ()] = 0
	end
	
	self.Elements:Add (bufferElement)
	self.ElementIndices [#self.ElementIndices + 1] = self.SemanticCounts [bufferElement:GetSemantic ()]
	self.SemanticCounts [bufferElement:GetSemantic ()] = self.SemanticCounts [bufferElement:GetSemantic ()] + 1
	
	self:InvalidateComputedSize ()
end

function self:AddRange (bufferElements)
	for _, bufferElement in ipairs (bufferElements) do
		self:Add (bufferElement)
	end
end

function self:GetCount ()
	return self.Elements.Count
end

function self:Lock ()
	self.Locked = true
end

function self:GetElement (index)
	return self.Elements:Get (index)
end

function self:GetElementSemanticIndex (index)
	return self.ElementIndices [index]
end

function self:GetSize ()
	if not self.SizeValid then
		local size = 0
		
		for bufferElement in self:GetEnumerator () do
			size = size + bufferElement:GetSize ()
		end
		
		self.Size = size
		self.SizeValid = true
	end
	
	return self.Size
end

function self:InvalidateComputedSize ()
	self.SizeValid = false
end

GLib.Rendering.Buffers.BufferLayout.PositionVertex = GLib.Rendering.Buffers.BufferLayout (GLib.Rendering.Buffers.BufferElement.Position4f)
GLib.Rendering.Buffers.BufferLayout.TexturedVertex = GLib.Rendering.Buffers.BufferLayout (GLib.Rendering.Buffers.BufferElement.Position4f, GLib.Rendering.Buffers.BufferElement.TextureCoordinates2f)