function LibK.addContentFolder( path )
	local files, folders = file.Find( path .. "/*", "GAME" )
	for k, v in pairs( files ) do
		resource.AddFile( path .. "/" .. v )
		if LibK.Debug then
			--print( "[LibK] Resource Added " .. path .. "/" .. v )
		end
	end
	
	for k, v in pairs( folders ) do
		addContent( path .. "/" .. v )
	end
end