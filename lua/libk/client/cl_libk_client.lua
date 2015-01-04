LibK.InitPostEntityPromise = Deferred( )
hook.Add( "InitPostEntity", "LibK_InitPostEntity", function( )
	LibK.InitPostEntityPromise:Resolve( )
end )