PermissionInterface = {}

--Check if user has acces to "access"
function PermissionInterface.query( ply, access )
	--ULX
	if ULib then
		return ULib.ucl.query( ply, access )
	end

	--Evolve
	if ply.EV_HasPrivilege then
		return ply:EV_HasPrivilege( access )
	end

	--Exsto
	if exsto then
		return ply:IsAllowed( access )
	end

	--SAM
	if sam then
		return ply:HasPermission( access )
	end

	KLogf(4, "[KReport] No compatible admin mod detected. ULX, Evolve, Exsto and SAM are supported- Defaulting." )

	if ply:IsSuperAdmin() then
		return true
	end

	return false
end

function PermissionInterface.anyAllowed( ply, tblAccess )
	for k, v in pairs( tblAccess ) do
		if PermissionInterface.query( ply, v ) then
			return true
		end
	end
end

function PermissionInterface.getRankTitle( internalName )
	local ranks = PermissionInterface.getRanks( )
	for k, v in pairs( ranks ) do
		if v.internalName == internalName then
			return v.title
		end
	end
end

function PermissionInterface.getRanks( )
	local ranks = { } --internalName: string, title: string
	if ULib then
		for internalName, rankInfo in pairs( ULib.ucl.groups ) do
			if v != ULib.ACCESS_ALL then
				table.insert( ranks, { internalName = internalName, title = internalName } )
			end
		end
		return ranks
	end

	if evolve then
		for internalName, rankInfo in pairs( evolve.ranks ) do
			table.insert( ranks, { internalName = internalName, title = rankInfo.Title } )
		end
		return ranks
	end
	

	if serverguard then
		for internalName, rankInfo in pairs( serverguard.ranks.stored ) do
			table.insert( ranks, { internalName = internalName, title = rankInfo.name } )
		end
		return ranks
	end

	if sam then
		for internalName, rankInfo in pairs(sam.ranks.get_ranks()) do
			table.insert( ranks, { internalName = internalName, title = internalName } )
		end
	end

	return ranks
end