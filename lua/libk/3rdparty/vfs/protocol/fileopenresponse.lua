local self = {}
VFS.Protocol.RegisterResponse ("FileOpen", VFS.MakeConstructor (self, VFS.Protocol.Session))

function self:ctor ()
	self.File = nil
	self.FileStream = nil
	
	self.SubRequestCallbacks = {}
	self.SubRequestTypes = {}
	self.SubRequestData = {}
	
	self:AddEventListener ("Closed", self.Closed)
end

function self:HandleInitialPacket (inBuffer)
	local path = inBuffer:String ()
	self.OpenFlags = inBuffer:UInt8 ()
	VFS.Root:GetChild (self:GetRemoteEndPoint ():GetRemoteId (), path,
		function (returnCode, node)
			if returnCode == VFS.ReturnCode.Success then
				if node:IsFile () then
					self.File = node
					self.File:Open (self:GetRemoteEndPoint ():GetRemoteId (), self.OpenFlags,
						function (returnCode, fileStream)
							local outBuffer = self:CreatePacket ()
							outBuffer:UInt8 (returnCode)
							if returnCode == VFS.ReturnCode.Success then
								self.FileStream = fileStream
								outBuffer:UInt32 (self.FileStream:GetLength ())
								self:QueuePacket (outBuffer)
							else
								self:SendReturnCode (returnCode)
								self:Close ()
							end
						end
					)
				else
					self:SendReturnCode (VFS.ReturnCode.NotAFile)
					self:Close ()
				end
			else
				self:SendReturnCode (returnCode)
				self:Close ()
			end
		end
	)
end

function self:HandlePacket (inBuffer)
	local subRequestId = inBuffer:UInt32 ()
	local actionId = inBuffer:UInt8 ()
	if actionId == VFS.Protocol.FileStreamAction.Close then
		self:Close ()
	elseif actionId == VFS.Protocol.FileStreamAction.Read then
		self:HandleRead (subRequestId, inBuffer)
	elseif actionId == VFS.Protocol.FileStreamAction.Write then
		local pos = inBuffer:UInt32 ()
		local size = inBuffer:UInt32 ()
		local data = inBuffer:String ()
		self.FileStream:Seek (pos)
		self.FileStream:Write (size, data,
			function (returnCode)
				local outBuffer = self:CreatePacket ()
				outBuffer:UInt32 (subRequestId)
				outBuffer:UInt8 (returnCode)
				self:QueuePacket (outBuffer)
			end
		)
	else
		local outBuffer = self:CreatePacket ()
		outBuffer:UInt32 (subRequestId)
		outBuffer:UInt8 (VFS.ReturnCode.AccessDenied)
		self:QueuePacket (outBuffer)
	end
end

function self:HandleRead (subRequestId, inBuffer)
	local pos = inBuffer:UInt32 ()
	local size = inBuffer:UInt32 ()
	self.FileStream:Seek (pos)
	self.FileStream:Read (size,
		function (returnCode, data)
			if returnCode == VFS.ReturnCode.Progress then return end
			if returnCode == VFS.ReturnCode.Success then
				local chunkSize = 1024
				local dataTable = nil
				dataTable =
				{
					Position = pos,
					ReadSize = size,
					SentSize = 0,
					Data = data,
					Index = 1,
					
					TickInterval = 0.05,
					Tick = function ()
						local chunk = data:sub (dataTable.SentSize + 1, dataTable.SentSize + chunkSize)
						local outBuffer = self:CreatePacket ()
						outBuffer:UInt32 (subRequestId)
						outBuffer:UInt8 (VFS.ReturnCode.Success)
						outBuffer:UInt16 (dataTable.Index)
						dataTable.Index = dataTable.Index + 1
						
						outBuffer:String (chunk)
						self:QueuePacket (outBuffer)
						
						dataTable.SentSize = dataTable.SentSize + chunkSize
						if dataTable.SentSize >= dataTable.ReadSize then
							self.SubRequestData [subRequestId] = nil
						end
					end
				}
				self.SubRequestData [subRequestId] = dataTable
				self.SubRequestData [subRequestId].Tick ()
			else
				local outBuffer = self:CreatePacket ()
				outBuffer:UInt32 (subRequestId)
				outBuffer:UInt8 (returnCode)
				self:QueuePacket (outBuffer)
			end
		end
	)
end

function self:HasTimedOut ()
	return false
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

-- Events
function self:Closed ()
	if self.FileStream then
		self.FileStream:Close ()
	end
end