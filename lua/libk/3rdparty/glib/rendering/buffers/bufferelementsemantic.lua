GLib.Rendering.Buffers.BufferElementSemantic = GLib.Enum (
	{
		None                =  0,
		
		Binormal            =  1,
		BlendIndices        =  2,
		BlendWeight         =  3,
		Color               =  4,
		Normal              =  5,
		Position            =  6,
		PositionTransformed =  7,
		PointSize           =  8,
		Tangent             =  9,
		TextureCoordinates  = 10,
		
		-- Output-specific
		Fog                 = 11,
		TessellationFactor  = 12,
		Face                = 13,
		ScreenPosition      = 14
	}
)