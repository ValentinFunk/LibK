local self = {}
GLib.Net.Layer2.OutboundSplitPacket = GLib.MakeConstructor (self)

function self:ctor (id, data)
	self.Id = id
	
	self.Data = data
	
	self.EncodedData   = data
	self.EncodedLength = #self.EncodedData
	
	self.ChunkSize  = 0
	self.ChunkCount = 0
	self.NextChunk  = 1
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

function self:SerializeFirstChunk (outBuffer)
	outBuffer:UInt32 (self.EncodedLength)
	outBuffer:UInt32 (self.ChunkSize)
	self:SerializeNextChunk (outBuffer)
end

function self:SerializeNextChunk (outBuffer)
	-- Include the next chunk
	local chunkStart = (self.NextChunk - 1) * self.ChunkSize + 1
	local chunkEnd   = self.NextChunk * self.ChunkSize
	local chunk      = string.sub (self.EncodedData, chunkStart, chunkEnd)
	
	outBuffer:LongString (chunk)
	
	self.NextChunk = self.NextChunk + 1
end

function self:SetChunkSize (chunkSize)
	if self:IsStarted () then
		GLib.Error ("OutboundSplitPacket:SetChunkSize : Cannot set chunk size after transmission has started.")
	end
	
	self.ChunkSize  = chunkSize
	self.ChunkCount = math.ceil (self.EncodedLength / self.ChunkSize)
end

function self:SetId (id)
	self.Id = id
end