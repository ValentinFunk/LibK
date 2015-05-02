local self = {}
GLib.Rendering.Meshes.IMesh = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	
	self.Flags = GLib.Rendering.Meshes.MeshFlags.None
	
	-- Buffers
	self.VertexBuffer = nil
	self.IndexBuffer  = nil
	
	self.NextFreeIndex   = 1
	self.NextFreeVertex  = 1
	
	-- Render Groups
	self.RenderGroups = GLib.Containers.List ()
end

function self:dtor ()
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:Destroy ()
	self:dtor ()
end

function self:GetFlags ()
	return self.Flags
end

-- Buffers
function self:GetVertexBuffer ()
	return self.VertexBuffer
end

function self:GetIndexBuffer ()
	return self.IndexBuffer
end

function self:AppendVertices (vertexCount, vertices)
	GLib.Error ("IMesh:AppendVertices : Not implemented.")
end

function self:AppendIndices (vertexCount, vertices)
	GLib.Error ("IMesh:AppendIndices : Not implemented.")
end

function self:Clear ()
	GLib.Error ("IMesh:Clear : Not implemented.")
end

function self:GetFreeIndexCount ()
	if not self.IndexBuffer then return 0 end
	return self.IndexBuffer:GetElementCount () - self.NextFreeIndex
end

function self:GetFreeVertexCount ()
	if not self.VertexBuffer then return 0 end
	return self.VertexBuffer:GetElementCount () - self.NextFreeVertex
end

function self:GetNextFreeIndex ()
	return self.NextFreeIndex
end

function self:GetNextFreeVertex ()
	return self.NextFreeVertex
end

-- Render Groups
function self:AppendRenderGroup (primitiveTopology, startVertex, vertexCount, merge)
	GLib.Error ("IMesh:AppendRenderGroup : Not implemented.")
end

function self:ClearRenderGroups ()
	GLib.Error ("IMesh:ClearRenderGroups : Not implemented.")
end

function self:DrawAllRenderGroups (renderContext)
	GLib.Error ("IMesh:DrawAllRenderGroups : Not implemented.")
end

function self:GetRenderGroups ()
	return self.RenderGroups
end