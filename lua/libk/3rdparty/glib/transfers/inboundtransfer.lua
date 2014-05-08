local self = {}
GLib.Transfers.InboundTransfer = GLib.MakeConstructor (self)

--[[
	Events:
		Finished ()
			Fired when this transfer has finished.
		RequestAccepted (transferId)
			Fired when this transfer request has been accepted.
		RequestRejected ()
			Fired when this transfer request has been rejected.
		TimedOut ()
			Fired when this transfer has timed out.
]]

function self:ctor (id)
	self.Id = id
	self.DisplayId = nil
	
	self.RequestId = nil
	
	self.SourceId = nil
	self.SourcePlayer = nil
	
	self.ChannelName = nil
	self.Data = nil
	
	self.EncodedData   = nil
	self.EncodedLength = 0
	
	self.Chunks = {}
	self.ChunkSize  = 0
	self.ChunkCount = 0
	self.NextChunk  = 1
	
	GLib.EventProvider (self)
end

function self:GetChannelName ()
	return self.ChannelName
end

function self:GetData ()
	return self.Data
end

function self:GetDisplayId ()
	if self.DisplayId then return self.DisplayId end
	return self:GetSourceId () .. "/" .. self:GetChannelName () .. "/" .. self:GetId ()
end

function self:GetFirstChunk ()
	return self.Chunks [1]
end

function self:GetId ()
	return self.Id
end

function self:GetRequestId ()
	return self.RequestId
end

function self:GetSourceId ()
	return self.SourceId
end

function self:IsFinished ()
	return self.NextChunk > 1 and self.NextChunk > self.ChunkCount
end

function self:IsSourceValid ()
	if CLIENT then return true end
	return self.SourcePlayer and self.SourcePlayer:IsValid () or false
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

function self:SetChannelName (channelName)
	self.ChannelName = channelName
end

function self:SetDisplayId (displayId)
	self.DisplayId = displayId
end

function self:SetId (id)
	self.Id = id
end

function self:SetRequestId (requestId)
	self.RequestId = requestId
end

function self:SetSourceId (sourceId)
	self.SourceId = sourceId
	self.SourcePlayer = nil
	if SERVER then
		for _, v in ipairs (player.GetAll ()) do
			if GLib.GetPlayerId (v) == sourceId then
				self.SourcePlayer = v
				break
			end
		end
	end
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