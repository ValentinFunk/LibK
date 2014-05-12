local self = {}
VFS.Protocol.Register ("FileOpen", self)
VFS.Protocol.FileOpenRequest = VFS.MakeConstructor (self, VFS.Protocol.Session)

VFS.Protocol.FileStreamAction =
{
	Close   = 0,
	Read    = 1,
	Write   = 2
}

function self:ctor (file, openFlags, callback)
	self.Callback = callback or VFS.NullCallback
	self.File = file
	self.OpenFlags = openFlags
	self.FileStream = nil
	
	self.NextSubRequestId = 0
	self.SubRequestCallbacks = {}
	self.SubRequestTypes = {}
	self.SubRequestData = {}
end

function self:CloseStream ()
	self.SubRequestCallbacks [self.NextSubRequestId] = VFS.NullCallback
	self.SubRequestTypes [self.NextSubRequestId] = VFS.Protocol.FileStreamAction.Close
	
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt32 (self.NextSubRequestId)
	outBuffer:UInt8 (VFS.Protocol.FileStreamAction.Close)
	self:QueuePacket (outBuffer)
	
	self.NextSubRequestId = self.NextSubRequestId + 1
	self:Close ()
end

function self:GenerateInitialPacket (outBuffer)
	outBuffer:String (self.File:GetPath ())
	outBuffer:UInt8 (self.OpenFlags)
end

function self:HandlePacket (inBuffer)
	if not self.FileStream then
		local returnCode = inBuffer:UInt8 ()
		if returnCode == VFS.ReturnCode.Success then
			local length = inBuffer:UInt32 ()
			self.File:SetSize (length)
			self.FileStream = VFS.NetFileStream (self, self.File, length)
			self.Callback (returnCode, self.FileStream)

			function self:HasTimedOut ()
				return false
			end
		else
			self.Callback (returnCode)
			self:Close ()
		end
	else
		local subRequestId = inBuffer:UInt32 ()
		local returnCode = inBuffer:UInt8 ()
		local callback = self.SubRequestCallbacks [subRequestId]
		if not callback then return end
		if not callback (returnCode, inBuffer) then
			self.SubRequestCallbacks [subRequestId] = nil
			self.SubRequestTypes [subRequestId] = nil
			self.SubRequestData [subRequestId] = nil
		end
	end
end

function self:HandleTimeOut ()
	self.Callback (VFS.ReturnCode.TimedOut)
end

function self:Read (pos, size, callback)
	local dataTable =
	{
		Position = pos,
		ReadSize = size,
		ReceivedSize = 0,
		Blocks = {}
	}
	self.SubRequestTypes [self.NextSubRequestId] = VFS.Protocol.FileStreamAction.Read
	self.SubRequestData [self.NextSubRequestId] = dataTable
	self.SubRequestCallbacks [self.NextSubRequestId] = function (returnCode, inBuffer)
		local index = inBuffer:UInt16 ()
		local data = inBuffer:String ()
		dataTable.Blocks [index] = data
		dataTable.ReceivedSize = dataTable.ReceivedSize + data:len ()
		if dataTable.ReceivedSize >= dataTable.ReadSize then
			callback (VFS.ReturnCode.Success, table.concat (dataTable.Blocks))
		else
			callback (VFS.ReturnCode.Progress, dataTable.ReceivedSize / dataTable.ReadSize)
		end
		return true
	end
	
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt32 (self.NextSubRequestId)
	outBuffer:UInt8 (VFS.Protocol.FileStreamAction.Read)
	outBuffer:UInt32 (pos)
	outBuffer:UInt32 (size)
	self:QueuePacket (outBuffer)
	
	self.NextSubRequestId = self.NextSubRequestId + 1
end

function self:Tick ()
	for _, dataTable in pairs (self.SubRequestData) do
		if dataTable.Tick then
			local deltaTime = SysTime () - (dataTable.LastTick or 0)
			if deltaTime > (dataTable.TickInterval or 0) then
				dataTable.Tick ()
				dataTable.LastTick = SysTime ()
			end
		end
	end
end

function self:Write (pos, size, data, callback)
	if bit.band (self.OpenFlags, VFS.OpenFlags.Write) == 0 then callback (VFS.ReturnCode.AccessDenied) return end

	self.SubRequestCallbacks [self.NextSubRequestId] = callback
	self.SubRequestTypes [self.NextSubRequestId] = VFS.Protocol.FileStreamAction.Write
	
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt32 (self.NextSubRequestId)
	outBuffer:UInt8 (VFS.Protocol.FileStreamAction.Write)
	outBuffer:UInt32 (pos)
	outBuffer:UInt32 (size)
	outBuffer:String (data)
	self:QueuePacket (outBuffer)
	
	self.NextSubRequestId = self.NextSubRequestId + 1
end