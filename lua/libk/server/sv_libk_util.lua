function LibK.addContentFolder( path, noRecurse )
	local files, folders = file.Find( path .. "/*", "GAME" )
	for k, v in pairs( files ) do
		resource.AddFile( path .. "/" .. v )
		if LibK.Debug then
			--print( "[LibK] Resource Added " .. path .. "/" .. v )
		end
	end
	
	if noRecurse then return end
	for k, v in pairs( folders ) do
		LibK.addContentFolder( path .. "/" .. v )
	end
end