--[[
		promises.lua
		Copyright (c) 2013 Lex Robinson
		This code is freely available under the MIT License
--]]

local setmetatable, pcall, table, pairs, error, ErrorNoHalt =
		  setmetatable, pcall, table, pairs, error, ErrorNoHalt or print;
local function new(tab, ...)
	local ret = setmetatable({}, {__index=tab});
	ret:_init(...);
	return ret;
end

local function bind(what, context)
		return function(...)
				if (context) then
						return what(context, ...);
				else
						return what(...);
				end
		end
end

local function pbind(func)
	if type( func ) != "function" then
		debug.Trace( )
	end
	return function(...)
			func( ... )
			--KAMSHAK: disabled lua error catching
			/*local r, e = pcall(func, ...);
			if (not r) then
					ErrorNoHalt('Callback failed: ', e, "\n");
			end*/
	end
end

local promise = {
		_IsPromise = true;
		Map = function(self, mapFn) 
			return self:Then(function( result )
				return Promise.Map( result, mapFn )
			end )
		end,
		Filter = function (self, filterFn)
			return self:Then( function(result)
				return Promise.Filter( result, filterFn )
			end )
		end,
		Then = function(self, succ, fail, prog)
				local def = Deferred();
				if (type(succ) == 'function') then
						local s = succ;
						succ = function(...)
								--local ret = { pcall(s, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, s( ... ) };
								if (not ret[1]) then
										print( "WARNING: Lua Error - " .. ret[2] )
										def:Reject(ret[2]);
										return;
								end
								if (type(ret[2]) == 'table' and ret[2]._IsPromise) then
										local r = ret[2];
										r:Progress(bind(def.Notify, def), true);
										r:Done(bind(def.Resolve, def),    true);
										r:Fail(bind(def.Reject, def),     true);
								else
										def:Resolve(unpack(ret, 2));
								end
						end
				else
						succ = bind(def.Resolve, def);
				end
				if (type(fail) == 'function') then
						local f = fail;
						fail = function(...)
								--local ret = { pcall(f, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, f( ... ) };
								if (not ret[1]) then
										print( "WARNING: Lua Error - " .. ret[2] )
										def:Reject(ret[2]);
										return;
								end
								if (type(ret[2]) == 'table' and ret[2]._IsPromise) then
										local r = ret[2];
										r:Progress(bind(def.Notify, def), true);
										r:Done(bind(def.Resolve, def),    true);
										r:Fail(bind(def.Reject, def),     true);
								else
										def:Resolve(unpack(ret, 2));
								end
						end
				else
						fail = bind(def.Reject, def);
				end
				-- Promises/A barely mentions progress handlers, so I've just made this up.
				if (type(prog) == 'function') then
						local p = prog;
						prog = function(...)
								--local ret = { pcall(s, ...) }; --KAMSHAK: Disabled lua err catching
								local ret = { true, s( ... ) };
								if (not ret[1]) then
										ErrorNoHalt("Progress handler failed: ", ret[2], "\n");
										-- Carry on as if that never happened
										def:Notify(...);
								else
										def:Notify( unpack(ret, 2) );
								end
						end
				else
						prog = bind(def.Notify, def);
				end
				-- Run progress first so any progs happen before the resolution
				self:Progress(prog, true);
				self:Done(succ, true);
				self:Fail(fail, true);
				return def:Promise();
		end;
		Done = function(self, succ, nobind)
				if (not nobind) then
						succ = pbind(succ);
				end
				if (self._state == 'done') then
						succ(unpack(self._res));
				else
						table.insert(self._succs, succ);
				end
				return self;
		end;
		Fail = function(self, fail, nobind)
				if (not nobind) then
						fail = pbind(fail);
				end
				if (self._state == 'fail') then
						fail(unpack(self._res))
				else
						table.insert(self._fails, fail);
				end
				return self;
		end;
		Progress = function(self, prog, nobind)
				if (not nobind) then
						prog = pbind(prog);
				end
				table.insert(self._progs, prog);
				if (self._progd) then
						for _, d in ipairs(self._progd) do
								prog(unpack(d));
						end
				end
				return self;
		end;
		Always = function(self, alwy, nobind)
				if (not nobind) then
						alwy = pbind(alwy);
				end
				if (self._state ~= 'pending') then
						alwy(unpack(self._res));
				else
						table.insert(self._alwys, alwy)
				end
				return self;
		end;

		_init = function(self)
				self._state = 'pending';
				self._succs = {};
				self._fails = {};
				self._progs = {};
				self._alwys = {};
		end;
};
local deferred = {
		_IsDeferred = true;
		Resolve = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to resolve an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._state = 'done';
				p._res = {...};
				for _, f in pairs(p._succs) do
						f(...);
				end
				for _, f in pairs(p._alwys) do
						f(...);
				end
				return self;
		end;

		Reject = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to reject an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._state = 'fail';
				p._res = {...};
				if #p._fails == 0 then
					MsgC( Color(255, 0, 0), "WARNIG: uncaught error in Promise: ", ..., "\n" )
					MsgC( Color(255, 0, 0), LibK.GLib.StackTrace (nil, 1) )
				end
				for _, f in pairs(p._fails) do
						f(...);
				end
				for _, f in pairs(p._alwys) do
						f(...);
				end
				return self;
		end;

		Notify = function(self, ...)
				local p = self._promise;
				if (p._state ~= 'pending') then
						error("Tried to notify an already " .. (state == "done" and "resolved" or "rejected") .. " deferred!", 2);
				end
				p._progd = p._progd or {};
				table.insert(p._progd, {...});
				for _, f in pairs(p._progs) do
						f(...);
				end
				return self;
		end;

		_init = function(self)
				self._promise = new(promise);
		end;

		Promise = function(self) return self._promise; end;

		-- Proxies
		_IsPromise = true;
		Then = function(self, ...) return self._promise:Then(...); end;
		Done = function(self, ...) self._promise:Done(...); return self; end;
		Fail = function(self, ...) self._promise:Fail(...); return self; end;
		Progress = function(self, ...) self._promise:Progress(...); return self; end;
		Always = function(self, ...) self._promise:Always(...); return self; end;
};

function Deferred()
		return new(deferred);
end

function getPromiseState( promise )
	if promise and promise._IsDeferred then
		return promise._promise._state
	elseif promise and ( promise._IsPromise or promise._promise ) then
		return promise._state
	else
		debug.Trace( )
		error( "Invalid object passed to getPromiseState(expected deferred/promise got " .. type( promise ) ..")" )
	end
end

--Kamshak

-- Waits for all promises to be finished, when one errors it rejects, else it returns the results in order
function WhenAllFinished( tblPromises, options )
	local def = Deferred( )
	local results = {}
	local options = options or {}

	if #tblPromises == 0 then
		if options.noUnpack then
			def:Resolve({})
		else
			def:Resolve()
		end
		return def:Promise( )
	end

	--Add result fetching Done funcs first
	--to make sure that instant returning promises are fetched correctly
	for k, v in pairs( tblPromises ) do
		v:Done( function( ... )
			local args = {...}
			if #args > 1 then
				results[k] = args
			else
				results[k] = args[1]
			end
		end )
	end

	for k, v in pairs( tblPromises ) do
		v:Done( function( )
			if def._promise._state == 'fail' or def._promise._state == 'done' then --might have errored or finished already
				return
			end
			local allDone = true
			for _, promise in pairs( tblPromises ) do
				if promise == v then continue end
				if promise._state == 'pending' then
					allDone = false
				end
			end
			if allDone then
				if options.noUnpack then
					def:Resolve( results )
				else
					def:Resolve( unpack( results ) )
				end
			end
		end )
		v:Fail( function( ... )
			if def._promise._state == 'pending' then
				def:Reject( ... )
			end
		end )
	end
	return def:Promise( ), def
end

Promise = {}

function Promise.Reject( ... )
	local def = Deferred( )

	local args = { ... }
	LibK.GLib.Threading.Thread():Start( function()
		def:Reject( unpack( args ) )
	end )

	return def:Promise()
end

function ispromise( val )
    return val and istable(val) and ( val._IsDeferred or val._IsPromise )
end

-- Maps promises to results and resolves to the map when finished
function Promise.Map( tbl, mapFn )
	local opts = opts or {}
    local promises = {}
    for k, v in pairs( tbl ) do
        local promise = Promise.Resolve()
        :Then( function( )
            if ispromise( v ) then
                return v:Then( mapFn )
            end
            return mapFn( v )
        end )

        table.insert( promises, promise )
    end

    return WhenAllFinished( promises, { noUnpack = true } )
end

function Promise.Wrap( valueOrPromise )
	if ispromise( valueOrPromise ) then
		return valueOrPromise
	end
	return Promise.Resolve( valueOrPromise )
end

function Promise.Filter( tbl, filterFn )
	local promises = {}
    for k, v in ipairs( tbl ) do
		local promise = Promise.Wrap( v ):Then( function( resolved )
			local result = filterFn( resolved )
			return Promise.Wrap( result ):Then( function( included ) 
				return {
					included = included,
					value = resolved
				}
			end )
		end )

        table.insert( promises, promise )
    end

	return WhenAllFinished( promises, { noUnpack = true } ):Then( function( results ) 
		return LibK._(results):chain():filter( function( result )
			return result.included
		end ):pluck( "value" ):value()
	end )
end

function Promise.Resolve( ... )
	local def = Deferred( )
	def:Resolve( ... )
	return def:Promise()
end

-- Delay the calling of a function or resolving of a value through a promise.
function Promise.Delay( delay, funcOrValue )
    local def = Deferred( )
    timer.Simple( delay, function( )
        if type(funcOrValue) == "function" then
            -- CAll the function and forward results. If the function returns a promise wait for completion and handle resolve and reject
            local results = {funcOrValue()}
            if #results == 1 and ispromise( results[1] ) then
                results[1]:Then( function( ... )
                    def:Resolve( ... )
                end, function( ... )
                    def:Reject( ... )
                end )
            end
            def:Resolve( unpack( results ) )
        else
            def:Resolve( funcOrValue )
        end
    end )
    return def:Promise( )
end


return Deferred;
