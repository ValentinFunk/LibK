local self = {}
GLib.Rendering.IGraphicsDevice = GLib.MakeConstructor (self)

function self:ctor ()
	self.DefaultTextRenderer = nil
end

function self:dtor ()
end

function self:Destroy ()
	self:dtor ()
end

function self:GetDefaultTextRenderer ()
	return self.DefaultTextRenderer
end

function self:CreateView (windowHandle)
	GLib.Error ("IGraphicsDevice:CreateView : Not implemented.")
end

function self:CreateTextRenderer ()
	GLib.Error ("IGraphicsDevice:CreateTextRenderer : Not implemented.")
end

-- Textures
function self:CreateTexture (size, mipMapCount, pixelFormat)
	GLib.Error ("IGraphicsDevice:CreateTexture : Not implemented.")
end

-- Buffers
function self:CreateVertexBuffer (elementCount, vertexLayout, bufferFlags)
	GLib.Error ("IGraphicsDevice:CreateVertexBuffer : Not implemented.")
end

function self:CreateIndexBuffer (elementCount, indexType, bufferFlags)
	GLib.Error ("IGraphicsDevice:CreateIndexBuffer : Not implemented.")
end

-- Meshes
function self:CreateMesh (vertexLayout, vertexCount, indexCount, meshFlags)
	GLib.Error ("IGraphicsDevice:CreateMesh : Not implemented.")
end