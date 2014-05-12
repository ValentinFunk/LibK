if GAuth then return end
GAuth = GAuth or {}

include ("glib/glib.lua")
include ("gooey/gooey.lua")

GLib.Initialize ("GAuth", GAuth)
GLib.AddCSLuaPackSystem ("GAuth")
GLib.AddCSLuaPackFile ("autorun/gauth.lua")
GLib.AddCSLuaPackFolderRecursive ("gauth")

GAuth.PlayerMonitor = GAuth.PlayerMonitor ("GAuth")

GAuth.AddReloadCommand ("gauth/gauth.lua", "gauth", "GAuth")

function GAuth.GetUserDisplayName (userId)
	return GAuth.PlayerMonitor:GetUserName (userId)
end

function GAuth.GetUserIcon (userId)
	if userId == GAuth.GetSystemId () then return "icon16/cog.png" end
	if userId == GAuth.GetServerId () then return "icon16/server.png" end
	if userId == GAuth.GetEveryoneId () then return "icon16/world.png" end
	return "icon16/user.png"
end

function GAuth.IsUserInGroup (groupId, authId, permissionBlock)
	local groupTreeNode = GAuth.ResolveGroupTreeNode (groupId)
	if not groupTreeNode then return false end
	return groupTreeNode:ContainsUser (authId, permissionBlock)
end

function GAuth.ResolveGroup (groupId)
	local node = GAuth.ResolveGroupTreeNode (groupId)
	if node and not node:IsGroup () then
		GAuth.Error ("GAuth.ResolveGroup : " .. groupId .. " is not a group.")
		node = nil
	end
	return node
end

function GAuth.ResolveGroupTree (groupId)
	local node = GAuth.ResolveGroupTreeNode (groupId)
	if node and not node:IsGroupTree () then
		GAuth.Error ("GAuth.ResolveGroup : " .. groupId .. " is not a group tree.")
		node = nil
	end
	return node
end

function GAuth.ResolveGroupTreeNode (groupId)
	if groupId == "" then return GAuth.Groups end
	
	local groupIdLength = groupId:len ()
	
	-- First segment
	local partStart = 1
	local partEnd = groupId:find ("/", partStart, true)
	partEnd = partEnd and partEnd - 1 or groupIdLength
	
	local node = GAuth.Groups
	while partStart <= groupIdLength do
		if not node:IsGroupTree () then return nil end
		node = node:GetChild (groupId:sub (partStart, partEnd))
		if not node then return nil end
		
		-- Next segment
		partStart = partEnd + 2
		partEnd = groupId:find ("/", partStart, true)
		partEnd = partEnd and partEnd - 1 or groupIdLength
	end
	return node
end

--[[
	Server keeps authoritative group tree
	GroupGroups have permissions - each player's GroupGroup resets to default on server, loads from saved on client.
	
	initial sync:
		local player sends groupgroup permissions to server
		local player sends groups under groupgroup + their permissions
		
		server sends everything else to player
		
	after:
		on permission changed, sync to everyone
		on group created, sync
		on group deleted, sync
		on player added to group, sync
		on player removed from group, sync
		
		
]]

include ("access.lua")
include ("returncode.lua")

include ("grouptreenode.lua")
include ("group.lua")
include ("grouptree.lua")
include ("permissionblock.lua")
include ("permissiondictionary.lua")

include ("permissionblocknetworkermanager.lua")
include ("permissionblocknetworker.lua")
include ("grouptreesaver.lua")
include ("grouptreesender.lua")

include ("protocol/protocol.lua")
include ("protocol/endpoint.lua")
include ("protocol/endpointmanager.lua")
include ("protocol/session.lua")

include ("protocol/initialsyncrequest.lua")

-- Group Tree Nodes
include ("protocol/useradditionnotification.lua")
include ("protocol/userremovalnotification.lua")
include ("protocol/nodeadditionnotification.lua")
include ("protocol/noderemovalnotification.lua")

include ("protocol/useradditionrequest.lua")
include ("protocol/useradditionresponse.lua")
include ("protocol/userremovalrequest.lua")
include ("protocol/userremovalresponse.lua")
include ("protocol/nodeadditionrequest.lua")
include ("protocol/nodeadditionresponse.lua")
include ("protocol/noderemovalrequest.lua")
include ("protocol/noderemovalresponse.lua")

-- Permission Blocks
include ("protocol/permissionblocknotification.lua")
include ("protocol/permissionblockrequest.lua")
include ("protocol/permissionblockresponse.lua")

include ("protocol/permissionblock/groupentryadditionnotification.lua")
include ("protocol/permissionblock/groupentryremovalnotification.lua")
include ("protocol/permissionblock/grouppermissionchangenotification.lua")
include ("protocol/permissionblock/inheritownerchangenotification.lua")
include ("protocol/permissionblock/inheritpermissionschangenotification.lua")
include ("protocol/permissionblock/ownerchangenotification.lua")

include ("protocol/permissionblock/groupentryadditionrequest.lua")
include ("protocol/permissionblock/groupentryadditionresponse.lua")
include ("protocol/permissionblock/groupentryremovalrequest.lua")
include ("protocol/permissionblock/groupentryremovalresponse.lua")
include ("protocol/permissionblock/grouppermissionchangerequest.lua")
include ("protocol/permissionblock/grouppermissionchangeresponse.lua")
include ("protocol/permissionblock/inheritownerchangerequest.lua")
include ("protocol/permissionblock/inheritownerchangeresponse.lua")
include ("protocol/permissionblock/inheritpermissionschangerequest.lua")
include ("protocol/permissionblock/inheritpermissionschangeresponse.lua")
include ("protocol/permissionblock/ownerchangerequest.lua")
include ("protocol/permissionblock/ownerchangeresponse.lua")

if CLIENT then
	GAuth.IncludeDirectory ("gauth/ui")
end

GAuth.Groups = GAuth.GroupTree ()
GAuth.Groups:SetRemovable (false)
GAuth.Groups:SetHost (GAuth.GetServerId ())

-- Set up notification sending
GAuth.GroupTreeSender:HookNode (GAuth.Groups)

GAuth.Groups:MarkPredicted ()

-- Set up permission dictionary
local permissionDictionary = GAuth.PermissionDictionary ()
permissionDictionary:AddPermission ("Create Group")
permissionDictionary:AddPermission ("Create Group Tree")
permissionDictionary:AddPermission ("Delete")
permissionDictionary:AddPermission ("Add User")
permissionDictionary:AddPermission ("Remove User")
GAuth.Groups:GetPermissionBlock ():SetPermissionDictionary (permissionDictionary)

-- Set up root permissions
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Modify Permissions", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Set Owner", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Create Group", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Create Group Tree", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Delete", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Add User", GAuth.Access.Allow)
GAuth.Groups:GetPermissionBlock ():SetGroupPermission (GAuth.GetSystemId (), "Owner", "Remove User", GAuth.Access.Allow)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Administrators",
	function (returnCode, group)
		group:SetRemovable (false)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				local ply = GAuth.PlayerMonitor:GetUserEntity (userId)
				if not ply then return false end
				return ply:IsAdmin ()
			end
		)
		group:SetIcon ("icon16/shield.png")
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Super Administrators",
	function (returnCode, group)
		group:SetRemovable (false)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				local ply = GAuth.PlayerMonitor:GetUserEntity (userId)
				if not ply then return false end
				return ply:IsSuperAdmin ()
			end
		)
		group:SetIcon ("icon16/shield.png")
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Everyone",
	function (returnCode, group)
		group:SetRemovable (false)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				return true
			end
		)
		group:SetIcon ("icon16/world.png")
	end
)

GAuth.Groups:AddGroup (GAuth.GetSystemId (), "Owner",
	function (returnCode, group)
		group:SetRemovable (false)
		group:SetMembershipFunction (
			function (userId, permissionBlock)
				if not permissionBlock then return false end
				return userId == permissionBlock:GetOwner ()
			end
		)
		group:SetIcon ("icon16/user.png")
	end
)
GAuth.Groups:ClearPredictedFlag ()

if SERVER then
	GAuth.GroupTreeSaver:HookNodeRecursive (GAuth.Groups)
	GAuth.GroupTreeSaver:Load ()
end

GAuth.PlayerMonitor:AddEventListener ("PlayerConnected",
	function (_, ply, userId, isLocalPlayer)
		GAuth.Groups:MarkPredicted ()
		GAuth.Groups:AddGroupTree (GAuth.GetSystemId (), userId,
			function (returnCode, groupTree)
				groupTree:SetRemovable (false)
				groupTree:SetHost (userId)
				groupTree:MarkPredicted ()
				groupTree:GetPermissionBlock ():SetOwner (GAuth.GetSystemId (), userId)
				groupTree:SetDisplayName (ply:Name ())
				groupTree:AddGroup (GAuth.GetSystemId (), "Player",
					function (returnCode, playerGroup)
						playerGroup:SetRemovable (false)
						
						-- The host has to be set explicitly in case the server has sent
						-- this group to the client before it gets created here.
						playerGroup:SetHost (userId)
						playerGroup:MarkPredicted ()
						playerGroup:AddUser (GAuth.GetSystemId (), userId)
						playerGroup:SetIcon ("icon16/user.png")
						playerGroup:ClearPredictedFlag ()
					end
				)
				groupTree:AddGroup (GAuth.GetSystemId (), "Friends",
					function (returnCode, playerGroup)
						playerGroup:SetRemovable (false)
						playerGroup:SetHost (userId) -- ensure host is set correctly
						if isLocalPlayer then
							for _, ply in ipairs (player.GetAll ()) do
								if ply:GetFriendStatus () == "friend" then
									playerGroup:AddUser (GAuth.GetSystemId (), GLib.GetPlayerId (ply))
								end
							end
						end
					end
				)
				groupTree:ClearPredictedFlag ()
			end
		)
		GAuth.Groups:ClearPredictedFlag ()
		
		if isLocalPlayer then
			GAuth.EndPointManager:GetEndPoint ("Server"):SendNotification (GAuth.Protocol.InitialSyncRequest ())
			GAuth.GroupTreeSender:SendNode ("Server", GAuth.Groups)
			
			GAuth.GroupTreeSaver:HookNodeRecursive (GAuth.Groups)
			GAuth.GroupTreeSaver:Load ()
		end
		if CLIENT then
			local friendsGroup = GAuth.ResolveGroup (GAuth.GetLocalId () .. "/Friends")
			if friendsGroup then
				if ply:GetFriendStatus () == "friend" then
					friendsGroup:AddUser (GAuth.GetSystemId (), GLib.GetPlayerId (ply))
				else
					friendsGroup:RemoveUser (GAuth.GetSystemId (), GLib.GetPlayerId (ply))
				end
			end
		end
	end
)

GAuth.PlayerMonitor:AddEventListener ("PlayerDisconnected",
	function (_, ply, userId)
		if userId == "" then return end
		if SERVER then
			GAuth.EndPointManager:RemoveEndPoint (userId)
			if GAuth.Groups:GetChild (userId) then
				GAuth.Groups:GetChild (userId):SetRemovable (true)
				GAuth.Groups:RemoveNode (GAuth.GetSystemId (), userId)
			end
		end
	end
)

GAuth:AddEventListener ("Unloaded", function ()
	GAuth.GroupTreeSaver:dtor ()
	GAuth.PlayerMonitor:dtor ()
end)