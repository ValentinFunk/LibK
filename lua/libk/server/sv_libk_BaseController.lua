CONTROLLERS = {}
BaseController = { }
local vnet = LibK.GLib.vnet

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

util.AddNetworkString( "LibK_StartView" )
function BaseController:startView( viewName, func, target,  ... )
	--Prepare the data
	local vars = { ... }
	--generate net tables for class instances that are passed as args
	local netTable = generateNetTable( vars )
	
	if not target or ( type( target ) != "Player" and not istable( target ) ) then
		error( "Invalid arg #3 to startView, player/playerTable expected, got " .. type( target ), 2 )
	end
	if istable( target ) and #target == 0 then
		return
	end
	
	local packet = vnet.CreatePacket( "LibK_StartView" )
	packet:String( viewName )
	packet:String( func )
	packet:Table( netTable )
	packet:AddTargets( target )
	packet:Send( )
end

util.AddNetworkString( "LibK_Transaction" )
vnet.Watch( "LibK_Transaction", function( packet )
	local len = packet.Size
	local ply = packet.Source

	local transactionId = packet:Int( )
	local controller = packet:String( )
	local action = packet:String( )
	local view = packet:String( )
	local args = packet:Table( )
	
	local controllerClass = getClass(controller)
	if not controllerClass then 
		error( "Got action request for invalid controller " .. controller .. " (" .. tostring(action) .. ")" )
	end
	local instance = controllerClass:getInstance( )

	--Debug log
	local argStrs = {}
	for k, v in pairs( args ) do
		table.insert( argStrs, tostring( v ) )
	end
	KLogf( 4, "%s@%s -> %s:%s( %s ) | Transaction %i len %i, Compressed: %s", ply:Nick( ), view, controller, action, table.concat( argStrs, " ," ), transactionId, len, packet.Compressed )
	
	instance:canDoAction( ply, action )
	:Then( function( )
		local def = Deferred( )
		
		if LibK.Debug then
			local promise = instance[action]( instance, ply, unpack( args ) )
			if not promise or not istable( promise ) then
				def:Reject( "Internal Server Error 403" ) --bad gateway? hmmm w/e
				ErrorNoHalt( "Invalid transaction " .. action .. ", doesn't return a promise" )
				KLogf( 1, "LUA Error in Controller " .. controller .. " action " .. action .. ":\n" )
				debug.Trace( )
			else
				--Forward promise to transaction
				promise:Done( function( ... )
					def:Resolve( ... )
				end )
				promise:Fail( function( ... )
					def:Reject( ... )
				end )
			end
		else
			local promise = instance[action]( instance, ply, unpack( args ) )
			if not promise or not istable ( promise ) then
				def:Reject( "500 - Internal Server Error" ) 
				ErrorNoHalt( "Invalid transaction " .. action .. ", doesn't return a promise, help!")
			else
				promise:Done ( function( ... ) 
					def:Resolve( ... )
				end )
				promise:Fail( function ( ... )
					def:Reject( ... )
				end )
			end
		end
		
		return def:Promise( )
	end )
	:Done( function( ... )
		instance:startView( view, "transactionCompleted", ply, transactionId, true, ... )
	end )
	:Fail( function( ... )
		instance:startView( view, "transactionCompleted", ply, transactionId, false, ... )
	end )
end, { vnet.OPTION_WATCH_OVERRIDE } )

--Override for access controll
--returns a promise, resolved if user can do it, rejected with error if he cant
function BaseController:canDoAction( ply, action )
	local def = Deferred( )
	def:Reject( 1, "Access Denied" )
	return def:Promise( )
end

util.AddNetworkString( "ControllerAction" )
vnet.Watch( "ControllerAction", function( packet )
	local ply = packet.Source
	local len = packet.Size

	local controller = packet:String( )
	local action = packet:String( )
	local view = packet:String( )
	local args = packet:Table( )
	
	local controllerClass = getClass(controller)
	if not controllerClass then 
		error( "Got action request for invalid controller " .. controller .. " (" .. tostring(action) .. ")" )
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
		if LibK.Debug then
			return instance[action]( instance, ply, unpack( args ) )
		else
			local succ, err = xpcall( instance[action], LibK.GLib.Error, instance, ply, unpack( args ) )
			if not succ then
				KLogf( 1, "LUA Error in Controller " .. controller .. " action " .. action .. ":\n" )
				KLogf( 1, tostring( err ) )
				return Promise.Reject( 1, "There was a Lua error. Please check the server console for details." )
			end
			return err
		end
	end )
	:Fail( function( errid, err )
		instance:startView( view, "displayError", ply, tostring(errid) .. ": " .. tostring(err), "Server Error" )
	end )
end, { vnet.OPTION_WATCH_OVERRIDE } )
