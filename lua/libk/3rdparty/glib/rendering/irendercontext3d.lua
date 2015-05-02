local self = {}
GLib.Rendering.IRenderContext3d = GLib.MakeConstructor (self)

function self:ctor ()
	self.GraphicsDevice = nil
	self.GraphicsView   = nil
	self.RenderContext  = nil
	
	-- Buffers
	self.VertexBuffer = nil
	self.IndexBuffer  = nil
	
	-- Shaders
	self.VertexShader = nil
	self.PixelShader  = nil
	self.VertexShaderArguments = nil
	self.PixelShaderArguments  = nil
	
	-- Textures
	self.Texture = nil
	
	-- Matrices
	self.WorldMatrixStack      = GLib.Rendering.Matrices.MatrixStack ()
	self.ViewMatrixStack       = GLib.Rendering.Matrices.MatrixStack ()
	self.ProjectionMatrixStack = GLib.Rendering.Matrices.MatrixStack ()
end

function self:GetGraphicsDevice ()
	return self.GraphicsDevice
end

function self:GetGraphicsView ()
	return self.GraphicsView
end

function self:GetRenderContext ()
	return self.RenderContext
end

-- Buffers
function self:GetVertexBuffer ()
	return self.VertexBuffer
end

function self:GetIndexBuffer ()
	return self.IndexBuffer
end

function self:GetRenderContext ()
	return self.RenderContext
end

function self:SetVertexBuffer (vertexBuffer)
	if self.VertexBuffer == vertexBuffer then return self end
	
	self.VertexBuffer = vertexBuffer
	return self
end

function self:SetIndexBuffer (indexBuffer)
	if self.IndexBuffer == indexBuffer then return self end
	
	self.IndexBuffer = indexBuffer
	return self
end

function self:DrawPrimitives (primitiveTopology, startVertex, vertexCount)
	GLib.Error ("IRenderContext3d:DrawPrimitives : Not implemented.")
end

-- Shaders
function self:GetVertexShader ()
	return self.VertexShader
end

function self:GetPixelShader ()
	return self.PixelShader
end

function self:SetVertexShader (vertexShader)
	if self.VertexShader == vertexShader then return self end
	
	self.VertexShader = vertexShader
	return self
end

function self:SetPixelShader (pixelShader)
	if self.PixelShader == pixelShader then return self end
	
	self.PixelShader = pixelShader
	return self
end

function self:GetVertexShaderArguments ()
	return self.VertexShaderArguments
end

function self:GetPixelShaderArguments ()
	return self.PixelShaderArguments
end

function self:SetVertexShaderArguments (vertexShaderArguments)
	if self.VertexShaderArguments == vertexShaderArguments then return self end
	
	self.VertexShaderArguments = vertexShaderArguments
	return self
end

function self:SetPixelShaderArguments (pixelShaderArguments)
	if self.PixelShaderArguments == pixelShaderArguments then return self end
	
	self.PixelShaderArguments = pixelShaderArguments
	return self
end

-- Textures
function self:GetTexture ()
	return self.Texture
end

function self:SetTexture (texture)
	if self.Texture == texture then return self end
	
	self.Texture = texture
	return self
end

-- Matrices
function self:GetWorldMatrixStack ()
	return self.WorldMatrixStack
end

function self:GetViewMatrixStack ()
	return self.ViewMatrixStack
end

function self:GetProjectionMatrixStack ()
	return self.ProjectionMatrixStack
end

function self:GetWorldMatrix ()
	return self.WorldMatrixStack.Top
end

function self:GetViewMatrix ()
	return self.ViewMatrixStack.Top
end

function self:GetProjectionMatrix ()
	return self.ProjectionMatrixStack.Top
end

function self:SetWorldMatrix (worldMatrix)
	self.WorldMatrixStack:SetTop (worldMatrix)
end

function self:SetViewMatrix (viewMatrix)
	self.ViewMatrixStack:SetTop (worldMatrix)
end

function self:SetProjectionMatrix (projectionMatrix)
	self.ProjectionMatrixStack:SetTop (worldMatrix)
end

