local self = {}
GLib.Rendering.Buffers.BufferElement = GLib.MakeConstructor (self)

function self:ctor (semantic, type)
	self.Semantic = nil
	self.Type     = nil
	
	if semantic then
		self:SetSemantic (semantic)
	end
	if type then
		self:SetType (type)
	end
end

function self:GetSemantic ()
	return self.Semantic
end

function self:SetSemantic (semantic)
	if self.Semantic == semantic then return self end
	
	self.Semantic = semantic
	self.Type = GLib.Rendering.Buffers.BufferElementTypes:GetType (self.Semantic)
	
	return self
end

function self:GetSize ()
	return GLib.Rendering.Buffers.BufferElementTypes:GetTypeSize (self.Type)
end

function self:GetType ()
	return self.Type
end

function self:SetType (type)
	if self.Type == type then return self end
	
	self.Type = type
	
	return self
end

GLib.Rendering.Buffers.BufferElement.Position2f           = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Position,           GLib.Rendering.Buffers.BufferElementType.Float2);
GLib.Rendering.Buffers.BufferElement.Position3f           = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Position,           GLib.Rendering.Buffers.BufferElementType.Float3);
GLib.Rendering.Buffers.BufferElement.Position4f           = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Position,           GLib.Rendering.Buffers.BufferElementType.Float4);
GLib.Rendering.Buffers.BufferElement.Color3b              = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Color,              GLib.Rendering.Buffers.BufferElementType.UInt83);
GLib.Rendering.Buffers.BufferElement.Color4b              = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Color,              GLib.Rendering.Buffers.BufferElementType.UInt84);
GLib.Rendering.Buffers.BufferElement.Color4f              = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.Color,              GLib.Rendering.Buffers.BufferElementType.Float4);
GLib.Rendering.Buffers.BufferElement.TextureCoordinates2f = GLib.Rendering.Buffers.BufferElement (GLib.Rendering.Buffers.BufferElementSemantic.TextureCoordinates, GLib.Rendering.Buffers.BufferElementType.Float2);