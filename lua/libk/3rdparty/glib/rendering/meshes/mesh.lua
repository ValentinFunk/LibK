local self = {}
GLib.Rendering.Meshes.Mesh = GLib.MakeConstructor (self, GLib.Rendering.Meshes.IMesh)

function self:ctor (graphicsDevice, vertexLayout, vertexCount, indexCount, meshFlags)
	self.GraphicsDevice = graphicsDevice
	
	self.Flags = meshFlags
	
	self.VertexBuffer = self.GraphicsDevice:CreateVertexBuffer (vertexCount, vertexLayout, bit.band (meshFlags, GLib.Rendering.Meshes.MeshFlags.Dynamic) ~= 0 and GLib.Rendering.Buffers.BufferFlags.Dynamic or GLib.Rendering.Buffers.BufferFlags.None)
	
	if indexCount > 0 then
		self.IndexBuffer = self.GraphicsDevice:CreateIndexBuffer (indexCount, GLib.Rendering.Buffers.BufferElementType.UInt16, bit.band (meshFlags, GLib.Rendering.Meshes.MeshFlags.Dynamic) ~= 0 and GLib.Rendering.Buffers.BufferFlags.Dynamic or GLib.Rendering.Buffers.BufferFlags.None)
	end
end

function self:dtor ()
	if self.VertexBuffer then
		self.VertexBuffer:dtor ()
		self.VertexBuffer = nil
	end
	if self.IndexBuffer then
		self.IndexBuffer:dtor ()
		self.IndexBuffer = nil
	end
end

-- Buffers
function self:AppendVertices (vertexCount, vertices)
	local firstVertex = self.NextFreeVertex
	
	self.VertexBuffer:SetElements (firstVertex, vertexCount, vertices)
	self.NextFreeVertex = self.NextFreeVertex + vertexCount
	
	return firstVertex
end

function self:AppendIndices (indexCount, indices)
	local firstIndex = self.NextFreeIndex
	
	self.IndexBuffer:SetElements (firstIndex, indexCount, indices)
	self.NextFreeIndex = self.NextFreeIndex + indexCount
	
	return firstIndex
end

function self:Clear ()
	self.NextFreeVertex = 0
	self.NextFreeIndex  = 0
	
	self:ClearRenderGroups ()
end

-- Render Groups
function self:AppendRenderGroup (primitiveTopology, startVertex, vertexCount, merge)
	if merge and self.RenderGroups.Count > 0 then
		local lastRenderGroup = self.RenderGroups [self.RenderGroups.Count]
		if lastRenderGroup.PrimitiveTopology == primitiveTopology and
		   lastRenderGroup.StartElement + lastRenderGroup.ElementCount == startVertex then
			lastRenderGroup.ElementCount = lastRenderGroup.ElementCount + vertexCount
			self.RenderGroups [self.RenderGroups.Count] = lastRenderGroup
		end
	end
	
	self.RenderGroups:Add (GLib.Rendering.Meshes.RenderGroup (primitiveTopology, startVertex, vertexCount))
end

function self:ClearRenderGroups ()
	self.RenderGroups:Clear ()
end

function self:DrawAllRenderGroups (renderContext)
	GLib.Error ("Mesh:DrawAllRenderGroups : Not implemented.")
end