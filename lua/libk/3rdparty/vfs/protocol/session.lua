local self = {}
VFS.Protocol.Session = GAuth.MakeConstructor (self, VFS.Protocol.Session)

function self:ctor ()
end

-- The corresponding DeserializeNode function is in
-- vfs/filesystem/netfolder.lua : NetFolder:DeserializeNode
function self:SerializeNode (node, outBuffer)
	VFS.Debug ("\tSerializeNode: " .. node:GetPath ())
	outBuffer:UInt8 (node:GetNodeType ())
	outBuffer:String (node:GetName ())
	if node:GetName () == node:GetDisplayName () then
		outBuffer:String ("")
	else
		outBuffer:String (node:GetDisplayName ())
	end
	
	local size = node:IsFile () and node:GetSize () or -1
	outBuffer:UInt32 (size ~= -1 and size or 0xFFFFFFFF)
	local lastModified = node:GetModificationTime ()
	outBuffer:UInt32 (lastModified ~= -1 and lastModified or 0xFFFFFFFF)
	
	-- Now the permission block (urgh)
	local synchronizationTable = VFS.PermissionBlockNetworker:PreparePermissionBlockSynchronizationList (node:GetPermissionBlock ())
	outBuffer:UInt16 (#synchronizationTable)
	for _, session in ipairs (synchronizationTable) do
		outBuffer:UInt32 (session:GetTypeId ())
		VFS.Debug ("\t" .. session:ToString ())
		session:GenerateInitialPacket (outBuffer)
	end
	
	return outBuffer
end

function self:SendReturnCode (returnCode)
	local outBuffer = self:CreatePacket ()
	outBuffer:UInt8 (returnCode)
	self:QueuePacket (outBuffer)
	
	VFS.Debug (self:ToString () .. ": " .. VFS.ReturnCode [returnCode])
end