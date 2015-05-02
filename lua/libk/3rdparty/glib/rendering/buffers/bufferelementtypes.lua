local self = {}
GLib.Rendering.Buffers.BufferElementTypes = GLib.MakeConstructor (self)

function self:ctor ()
	self.SemanticTypes = {}
	self.TypeSizes     = {}
	
	-- Semantic Types
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.None               ] = GLib.Rendering.Buffers.BufferElementType.Float
	
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Binormal           ] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.BlendIndices       ] = GLib.Rendering.Buffers.BufferElementType.UInt32
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.BlendWeight        ] = GLib.Rendering.Buffers.BufferElementType.Float
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Color              ] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Normal             ] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Position           ] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.PositionTransformed] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.PointSize          ] = GLib.Rendering.Buffers.BufferElementType.Float
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Tangent            ] = GLib.Rendering.Buffers.BufferElementType.Float4
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.TextureCoordinates ] = GLib.Rendering.Buffers.BufferElementType.Float2
	
	-- Output-specific
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Fog                ] = GLib.Rendering.Buffers.BufferElementType.Float
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.TessellationFactor ] = GLib.Rendering.Buffers.BufferElementType.Float
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.Face               ] = GLib.Rendering.Buffers.BufferElementType.Float
	self.SemanticTypes [GLib.Rendering.Buffers.BufferElementSemantic.ScreenPosition     ] = GLib.Rendering.Buffers.BufferElementType.Float2
	
	-- Type Sizes
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt8  ] =  1
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt82 ] =  2
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt83 ] =  3
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt84 ] =  4
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt16 ] =  2
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.UInt32 ] =  4
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.Float  ] =  4
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.Float2 ] =  8
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.Float3 ] =  8
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.Float4 ] = 16
	self.TypeSizes [GLib.Rendering.Buffers.BufferElementType.Float16] = 64
end

function self:GetTypeSize (bufferElementType)
	return self.TypeSizes [bufferElementType]
end

function self:GetSemanticSize (bufferElementSemantic)
	return self.TypeSizes [self.SemanticTypes [bufferElementSemantic]]
end

function self:GetLayoutSize (bufferLayout)
	return bufferLayout:GetSize ()
end

function self:GetType (bufferElementSemantic)
	return self.SemanticTypes [bufferElementSemantic]
end

GLib.Rendering.Buffers.BufferElementTypes = GLib.Rendering.Buffers.BufferElementTypes ()