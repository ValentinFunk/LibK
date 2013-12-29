CONTROLLERS = {}
BaseController = { }

function BaseController:included( class )
	function class.static.getInstance( class )
		class.static.instance = class.static.instance or class:new( )
		return class.static.instance
	end
end

--Call for auto sending an error message to the specified view, if error outside of internal range(<0)
function BaseController:reportError( view, ply, strDesc, errid, err )
	if errid < 1 then
		self:startView( view, "displayError", ply, Format( "%s, Internal Error( Code %i )", strDesc, errid or -4000 ) )
	else
		self:startView( view, "displayError", ply, Format( "%s: %s", strDesc, err ) )
	end
end

util.AddNetworkString( "StartView" )
function BaseController:startView( viewName, func, target,  ... )
	--Prepare the data
	local vars = { ... }
	--generate net tables for class instances that are passed as args
	local netTable = generateNetTable( vars )
	
	if not target or ( type( target ) != "Player" and not istable( target ) ) then
		error( "Invalid arg #3 to startView, player/playerTable expected, got " .. type( target ), 2 )
	end
	
	--Send it
	net.Start( "StartView" )
		net.WriteString( viewName )
		net.WriteTable( netTable )
		net.WriteString( func )
	net.Send( target )
end

--Override for access controll
--returns a promise, resolved if user can do it, rejected with error if he cant
function BaseController:canDoAction( ply, action )
	local def = Deferred( )
	def:Reject( 1, "Access Denied" )
	return def:Promise( )
end

util.AddNetworkString( "ControllerAction" )
net.Receive( "ControllerAction", function( len, ply )
	local controller = net.ReadString( )
	local action = net.ReadString( )
	local view = net.ReadString( )
	local args = net.ReadTable( )
	
	local controllerClass = getClass(controller)
	if not controllerClass then 
		error( "Got action request for invalid controller " .. controller )
	end
	local instance = controllerClass:getInstance( )

	--Debug log
	local argStrs = {}
	for k, v in pairs( args ) do
		table.insert( argStrs, tostring( v ) )
	end
	KLogf( 4, "%s@%s -> %s:%s( %s ) len %i", ply:Nick( ), view, controller, action, table.concat( argStrs, " ," ), len )
	
	instance:canDoAction( ply, action )
	:Then( function( )
		local def = Deferred( )
		if LibK.Debug then
			instance[action]( instance, ply, unpack( args ) )
		else
			local succ, err = pcall( instance[action], instance, ply, unpack( args ) )
			if not succ then
				def:Reject( 1, "Internal Server Errror" )
				KLogf( 1, "LUA Error in Controller " .. controller .. " action " .. action .. ":\n" )
				KLogf( 1, err )
				debug.Trace( )
			end
		end
		
		return def:Promise( )
	end )
	:Fail( function( errid, err )
		instance:startView( view, "displayError", ply, err, "Error" )
	end )
end )