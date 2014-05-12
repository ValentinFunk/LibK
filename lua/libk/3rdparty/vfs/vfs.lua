if VFS then return end
VFS = VFS or {}

include ("glib/glib.lua")
include ("gooey/gooey.lua")
include ("gauth/gauth.lua")

GLib.Initialize ("VFS", VFS)
GLib.AddCSLuaPackSystem ("VFS")
GLib.AddCSLuaPackFile ("autorun/vfs.lua")
GLib.AddCSLuaPackFolderRecursive ("vfs")

VFS.PlayerMonitor = VFS.PlayerMonitor ("VFS")

include ("clipboard.lua")
include ("path.lua")
include ("openflags.lua")
include ("returncode.lua")
include ("seektype.lua")
include ("updateflags.lua")

include ("filesystemwatcher.lua")
include ("permissionsaver.lua")

-- Resources
include ("iresource.lua")
include ("httpresource.lua")
include ("fileresource.lua")
include ("iresourcelocator.lua")
include ("defaultresourcelocator.lua")

include ("filesystem/nodetype.lua")
include ("filesystem/inode.lua")
include ("filesystem/ifile.lua")
include ("filesystem/ifolder.lua")
include ("filesystem/ifilestream.lua")
include ("filesystem/memoryfilestream.lua")

-- Real
include ("filesystem/realnode.lua")
include ("filesystem/realfile.lua")
include ("filesystem/realfolder.lua")
include ("filesystem/realfilestream.lua")

-- Networked
include ("filesystem/netnode.lua")
include ("filesystem/netfile.lua")
include ("filesystem/netfolder.lua")
include ("filesystem/netfilestream.lua")

-- Virtual
include ("filesystem/vnode.lua")
include ("filesystem/vfile.lua")
include ("filesystem/vfolder.lua")
include ("filesystem/vfilestream.lua")

-- Mounted
include ("filesystem/mountednode.lua")
include ("filesystem/mountedfile.lua")
include ("filesystem/mountedfolder.lua")
include ("filesystem/mountedfilestream.lua")

if CLIENT then
	include ("filetypes.lua")
	include ("filetype.lua")
	include ("filetypes/adv_duplicator.lua")
	include ("filetypes/cpuchip.lua")
	include ("filetypes/expression2.lua")
	include ("filetypes/gpuchip.lua")
	include ("filetypes/spuchip.lua")
	include ("filetypes/starfall.lua")
end

-- Networking
include ("protocol/protocol.lua")
include ("protocol/session.lua")
include ("protocol/nodecreationnotification.lua")
include ("protocol/nodedeletionnotification.lua")
include ("protocol/noderenamenotification.lua")
include ("protocol/nodeupdatenotification.lua")
include ("protocol/fileopenrequest.lua")
include ("protocol/fileopenresponse.lua")
include ("protocol/folderchildrequest.lua")
include ("protocol/folderchildresponse.lua")
include ("protocol/folderlistingrequest.lua")
include ("protocol/folderlistingresponse.lua")
include ("protocol/nodecreationrequest.lua")
include ("protocol/nodecreationresponse.lua")
include ("protocol/nodedeletionrequest.lua")
include ("protocol/nodedeletionresponse.lua")
include ("protocol/noderenamerequest.lua")
include ("protocol/noderenameresponse.lua")

include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")

if CLIENT then
	VFS.IncludeDirectory ("vfs/ui")
end
	
-- include ("adaptors/adv_duplicator.lua")
-- include ("adaptors/expression2_editor.lua")
-- include ("adaptors/expression2_files.lua")
-- include ("adaptors/expression2_upload.lua")

VFS.AddReloadCommand ("vfs/vfs.lua", "vfs", "VFS")

local nextUniqueName = -1
function VFS.GetUniqueName ()
	nextUniqueName = nextUniqueName + 1
	return string.format ("%08x%02x", os.time (), nextUniqueName % 256)
end

if SERVER then
	function VFS.GetLocalHomeDirectory ()
		return ""
	end
else
	function VFS.GetLocalHomeDirectory ()
		return GAuth.GetLocalId ()
	end
end

function VFS.SanitizeNodeName (segment)
	segment = segment:gsub ("\\", "_")
	segment = segment:gsub ("/", "_")
	if segment == "." then return nil end
	if segment == ".." then return nil end
	return segment
end

function VFS.SanitizeOpenFlags (openFlags)
	if bit.band (openFlags, VFS.OpenFlags.Overwrite) ~= 0 and bit.band (openFlags, VFS.OpenFlags.Write) == 0 then
		openFlags = openFlags - VFS.OpenFlags.Overwrite
	end
	return openFlags
end

--[[
	Server:
		root (VFolder)
			STEAM_X:X:X (NetFolder)
			...
			Public (VFolder)
			Admins (VFolder)
			...
	
	Client:
		root (NetFolder)
			STEAM_X:X:X (NetFolder)
			STEAM_LOCAL (VFolder)
]]
VFS.RealRoot    = VFS.RealFolder ("", "GAME", "")
if SERVER then
	VFS.Root = VFS.VFolder ("")
elseif CLIENT then
	VFS.Client = VFS.EndPointManager:GetEndPoint (GAuth.GetServerId ())
	VFS.Root = VFS.Client:GetRoot ()
end
VFS.Root:SetDeletable (false)
VFS.Root:MarkPredicted ()
VFS.PermissionDictionary = GAuth.PermissionDictionary ()
VFS.PermissionDictionary:AddPermission ("Create Folder")
VFS.PermissionDictionary:AddPermission ("Delete")
VFS.PermissionDictionary:AddPermission ("Read")
VFS.PermissionDictionary:AddPermission ("Rename")
VFS.PermissionDictionary:AddPermission ("View Folder")
VFS.PermissionDictionary:AddPermission ("Write")
VFS.Root:GetPermissionBlock ():SetPermissionDictionary (VFS.PermissionDictionary)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Everyone", "View Folder",        GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Modify Permissions", GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Set Owner",          GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Create Folder",      GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Delete",             GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Read",               GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Rename",             GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "View Folder",        GAuth.Access.Allow)
VFS.Root:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Write",              GAuth.Access.Allow)
VFS.Root:ClearPredictedFlag ()

VFS.PermissionSaver:Load ()
VFS.PermissionSaver:HookNodeRecursive (VFS.Root)

VFS.IncludeDirectory ("vfs/folders")
VFS.IncludeDirectory ("vfs/folders/" .. (SERVER and "server" or "client"))

-- Events
VFS.PlayerMonitor:AddEventListener ("PlayerConnected",
	function (_, ply, userId, isLocalPlayer)
		local folder = nil
		local mountedFolder = nil
		if isLocalPlayer then
			-- create the VFolder and mount it into the root NetFolder
			folder = VFS.VFolder (GAuth.GetLocalId (), VFS.Root)
			mountedFolder = VFS.Root:MountLocal (GAuth.GetLocalId (), folder)
		else
			-- pre-empt the NetFolder creation
			local endPoint = nil
			if SERVER then
				endPoint = VFS.EndPointManager:GetEndPoint (userId)
			elseif CLIENT then
				endPoint = VFS.Client
			end
			folder = endPoint:GetRoot ():CreatePredictedFolder (userId)
			mountedFolder = folder
		end
		mountedFolder.PlayerFolder = true
		
		folder:SetDeletable (false)
		folder:MarkPredicted ()
		folder:SetDisplayName (ply:Nick ())
		if SERVER then
			VFS.Root:Mount (userId, folder)
			folder:GetPermissionBlock ():SetParentFunction (
				function ()
					return VFS.Root:GetPermissionBlock ()
				end
			)
		elseif CLIENT then
			if isLocalPlayer then				
				local mountPaths =
				{
					"data/adv_duplicator",
					"data/cadmin/client_logs",
					"data/CPUChip",
					"data/e2files",
					"data/Expression2",
					"data/ExpressionGate",
					"data/LemonGate",
					"data/luapad",
					"data/GPUChip",
					"data/SPUChip",
					"data/Starfall",
					"screenshots"
				}
				for _, realPath in ipairs (mountPaths) do
					VFS.RealRoot:GetChild (GAuth.GetSystemId (), realPath,
						function (returnCode, node)
							if not node then return end
							folder:Mount (node:GetName (), node)
								:SetDeletable (false)
						end
					)
				end
				
				folder:CreateFolder (GAuth.GetSystemId (), "tmp",
					function (returnCode, node)
						if node then node:SetDeletable (false) end
					end
				)
				
				VFS.EndPointManager:GetEndPoint ("Server"):HookNode (mountedFolder)
				VFS.PermissionBlockNetworker:SynchronizeBlock ("Server", mountedFolder:GetPermissionBlock ())
			end
		end
		
		-- Do permission block stuff after folder has been inserted into filesystem tree
		folder:SetOwner (GAuth.GetSystemId (), userId)
		folder:GetPermissionBlock ():SetInheritPermissions (GAuth.GetSystemId (), false)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Modify Permissions", GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Set Owner",          GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Create Folder",      GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Delete",             GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Read",               GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Rename",             GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "View Folder",        GAuth.Access.Allow)
		folder:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner",    "Write",              GAuth.Access.Allow)
		folder:ClearPredictedFlag ()
	end
)

VFS.PlayerMonitor:AddEventListener ("PlayerDisconnected",
	function (_, ply, userId)
		if userId == "" then return end
		if SERVER then
			VFS.EndPointManager:RemoveEndPoint (userId)
			if VFS.Root:GetChildSynchronous (userId) then
				VFS.Root:GetChildSynchronous (userId):SetDeletable (true)
				VFS.Root:DeleteChild (GAuth.GetSystemId (), userId)
			end
		end
	end
)

VFS:AddEventListener ("Unloaded", function ()
	VFS.PermissionSaver:dtor ()
	VFS.PlayerMonitor:dtor ()
end)