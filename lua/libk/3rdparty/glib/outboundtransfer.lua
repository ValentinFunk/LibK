local self = {}
GLib.Transfers.OutboundTransfer = GLib.MakeConstructor (self)

function self:ctor (id, data)
	self.Id = id
	self.DisplayId = nil
	
	self.DestinationId = nil
	self.DestinationPlayer = nil
	
	self.ChannelName = nil
	self.Data = data
	
	self.EncodedData   = self.Data
	self.EncodedLength = #self.EncodedData
	
	self.ChunkSize  = 0
	self.ChunkCount = 0
	self.NextChunk  = 1
	
	self:SetChunkSize (16384)
end

function self:GetChannelName ()
	return self.ChannelName
end

function self:GetDestinationId ()
	return self.DestinationId
end

function self:GetDisplayId ()
	if self.DisplayId then return self.DisplayId end
	return self:GetDestinationId () .. "/" .. self:GetChannelName () .. "/" .. self:GetId ()
end

function self:GetId ()
	return self.Id
end

function self:IsDestinationValid ()
	if CLIENT then return true end
	if SERVER and self:GetDestinationId () == GLib.GetEveryoneId () then return true end
	return self.DestinationPlayer and self.DestinationPlayer:IsValid () or false
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

function self:SetChannelName (channelName)
	self.ChannelName = channelName
end

function self:SetChunkSize (chunkSize)
	if self:IsStarted () then
		GLib.Error ("OutboundTransfer:SetChunkSize : Cannot set chunk size after a transfer has started.")
	end
	
	self.ChunkSize  = chunkSize
	self.ChunkCount = math.ceil (self.EncodedLength / self.ChunkSize)
end

function self:SetDestinationId (destinationId)
	self.DestinationId = destinationId
	self.DestinationPlayer = nil
	if SERVER then
		for _, v in ipairs (player.GetAll ()) do
			if GLib.GetPlayerId (v) == destinationId then
				self.DestinationPlayer = v
				break
			end
		end
	end
end

function self:SetDisplayId (displayId)
	self.DisplayId = displayId
end