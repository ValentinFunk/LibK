local self = {}
GLib.Rendering.Meshes.RenderGroup = GLib.MakeConstructor (self)

function self:ctor (primitiveTopology, startElement, elementCount)
	self.PrimitiveTopology = primitiveTopology
	self.StartElement = startElement or 0
	self.ElementCount = elementCount or 0
end