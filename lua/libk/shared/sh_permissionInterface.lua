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

	KLogf(4, "[KReport] No compatible admin mod detected. ULX, Evolve and Exsto are supported- Defaulting." )
	
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
