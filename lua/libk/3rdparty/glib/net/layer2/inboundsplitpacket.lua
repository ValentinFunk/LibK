local self = {}
GLib.Net.Layer2.InboundSplitPacket = GLib.MakeConstructor (self)

function self:ctor (id)
	self.Id = id
	
	self.Data = nil
	
	self.EncodedData   = nil
	self.EncodedLength = 0
	
	self.Chunks = {}
	self.ChunkSize  = 0
	self.ChunkCount = 0
	self.NextChunk  = 1
end

function self:GetData ()
	return self.Data
end

function self:GetId ()
	return self.Id
end

function self:IsFinished ()
	return self.NextChunk > 1 and self.NextChunk > self.ChunkCount
end

function self:IsStarted ()
	return self.NextChunk > 1
end

function self:DeserializeFirstChunk (inBuffer)
	self.EncodedLength = inBuffer:UInt32 ()
	self:SetChunkSize (inBuffer:UInt32 ())
	self:DeserializeNextChunk (inBuffer)
end

function self:DeserializeNextChunk (inBuffer)
	self.Chunks [#self.Chunks + 1] = inBuffer:LongString ()
	self.NextChunk = self.NextChunk + 1
	
	if self:IsFinished () then
		self:DecodeData ()
	end
end

function self:SetId (id)
	self.Id = id
end

-- Internal, do not call
function self:DecodeData ()
	self.EncodedData = table.concat (self.Chunks)
	self.Data = self.EncodedData
end

function self:SetChunkSize (chunkSize)
	if self:IsStarted () then
		GLib.Error ("InboundTransfer:SetChunkSize : Cannot set chunk size after a transfer has started.")
	end
	
	self.ChunkSize  = chunkSize
	self.ChunkCount = math.ceil (self.EncodedLength / self.ChunkSize)
end