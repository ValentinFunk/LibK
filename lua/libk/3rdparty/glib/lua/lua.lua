function GLib.Lua.AddressOf (object)
	local addressString = string.format ("%p", object)
	if addressString == "NULL" then return 0 end
	return tonumber (addressString)
end

function GLib.Lua.CreateShadowGlobalTable ()
	local globalShadowTable = GLib.Lua.CreateShadowTable (_G)
	
	globalShadowTable.timer.Adjust  = GLib.NullCallback
	globalShadowTable.timer.Create  = GLib.NullCallback
	globalShadowTable.timer.Destroy = GLib.NullCallback
	globalShadowTable.timer.Pause   = GLib.NullCallback
	globalShadowTable.timer.Stop    = GLib.NullCallback
	globalShadowTable.timer.Simple  = GLib.NullCallback
	globalShadowTable.timer.Toggle  = GLib.NullCallback
	globalShadowTable.timer.UnPause = GLib.NullCallback
	
	globalShadowTable.hook.Add    = GLib.NullCallback
	globalShadowTable.hook.GetTable = function ()
		return GLib.Lua.CreateShadowTable (hook.GetTable ())
	end
	globalShadowTable.hook.Remove = GLib.NullCallback
	
	return globalShadowTable
end

function GLib.Lua.CreateShadowTable (t)
	local shadowTable = {}
	local metatable = {}
	local nils = {}
	
	metatable.__index = function (self, key)
		if rawget (self, key) ~= nil then
			return rawget (self, key)
		end
		
		if nils [key] then
			return nil
		end
		
		if t [key] ~= nil then
			if type (t [key]) == "table" then
				rawset (self, key, GLib.Lua.CreateShadowTable (t [key]))
				return rawget (self, key)
			end
			return t [key]
		end
	end
	
	metatable.__newindex = function (self, key, value)
		rawset (self, key, value)
		nils [key] = value == nil
	end
	
	setmetatable (shadowTable, metatable)
	
	return shadowTable
end

function GLib.Lua.GetFunctionName (func)
	if not GLib.Lua.NameCache               then return nil end
	if not GLib.Lua.NameCache.GetObjectName then return nil end
	
	return GLib.Lua.NameCache:GetFunctionName (func)
end

function GLib.Lua.GetObjectName (object)
	if not GLib.Lua.NameCache               then return nil end
	if not GLib.Lua.NameCache.GetObjectName then return nil end
	
	return GLib.Lua.NameCache:GetObjectName (object)
end

function GLib.Lua.GetTable (tableName)
	local parts = string.Split (tableName, ".")
	
	local t = _G
	for i = 1, #parts do
		if i == 1 and parts [i] == "_R" then
			t = debug.getregistry ()
		else
			t = t [parts [i]]
		end
		
		if not t then break end
	end
	
	if not t then
		GLib.Error ("GLib.Lua.GetTable : Table " .. tableName .. " does not exist.")
		return nil
	end
	
	return t
end

function GLib.Lua.GetTableName (table)
	return GLib.Lua.NameCache:GetTableName (table)
end

function GLib.Lua.GetTableValue (valueName)
	local parts = string.Split (valueName, ".")
	local valueName = parts [#parts]
	parts [#parts] = nil
	
	local tableName = #parts > 0 and table.concat (parts, ".") or "_G"
	
	local t = _G
	for i = 1, #parts do
		if i == 1 and parts [i] == "_R" then
			t = debug.getregistry ()
		else
			t = t [parts [i]]
		end
		
		if not t then break end
	end
	
	if not t then
		GLib.Error ("GLib.Lua.GetTableValue : Table " .. tostring (tableName) .. " does not exist.")
		return nil
	end
	
	return t [valueName], t, tableName, valueName
end

function GLib.Lua.IsNativeFunction (f)
	return debug.getinfo (f).what == "C"
end

local keywords =
{
	["if"]       = true,
	["then"]     = true,
	["elseif"]   = true,
	["else"]     = true,
	["for"]      = true,
	["while"]    = true,
	["do"]       = true,
	["repeat"]   = true,
	["until"]    = true,
	["end"]      = true,
	["return"]   = true,
	["break"]    = true,
	["continue"] = true,
	["function"] = true,
	["not"]      = true,
	["and"]      = true,
	["or"]       = true,
	["true"]     = true,
	["false"]    = true,
	["nil"]      = true
}

function GLib.Lua.IsValidVariableName (name)
	if not isstring (name) then return false end
	if not keywords [name] and string.match (name, "^[_a-zA-Z][_a-zA-Z0-9]*$") then return true end
	return false
end

local ToCompactLuaString
local ToLuaString

local TypeFormatters =
{
	["nil"] = tostring,
	["boolean"] = tostring,
	["number"] = function (value)
		if value == math.huge then return "math.huge"
		elseif value == -math.huge then return "-math.huge" end
		
		if value >= 65536 and
		   value < 4294967296 and
		   math.floor (value) == value then
			return string.format ("0x%08x", value)
		end
		
		return tostring (value)
	end,
	["string"] = function (value)
		return "\"" .. GLib.String.EscapeNonprintable (value) .. "\""
	end,
	["table"] = function (value)
		local name = GLib.Lua.GetTableName (value)
		if name then return name end
		
		local valueType = type (value)
		local metatable = debug.getmetatable (value)
		if metatable then
			valueType = GLib.Lua.GetTableName (metatable) or valueType
		end
		return string.format ("{ %s: %p }", valueType, value)
	end,
	["Panel"] = function (value)
		return string.format ("{ Panel: %s %p }", value.ClassName or "", value)
	end,
	["Entity"] = function (value)
		if not value:IsValid () then return "NULL" end
		
		-- Serverside entity
		local entityIndex = value:EntIndex ()
		if entityIndex >= 0 then
			local entityInfo = value:GetClass ()
			
			if value:IsPlayer () then
				entityInfo = value:SteamID () .. ", " .. value:GetName ()
			end
			
			return "Entity (" .. entityIndex .. ") --[[ " .. entityInfo .. " ]]"
		end
		
		-- Clientside model
		local model = value:GetModel ()
		return "ClientsideModel (" .. ToCompactLuaString (model) .. ")"
	end,
	["function"] = function (value)
		local name = GLib.Lua.GetFunctionName (value)
		return name or GLib.Lua.FunctionCache:GetFunction (value):GetPrototype ()
	end
}

TypeFormatters ["Player"] = TypeFormatters ["Entity"]
TypeFormatters ["Weapon"] = TypeFormatters ["Entity"]
TypeFormatters ["NPC"]    = TypeFormatters ["Entity"]

function ToCompactLuaString (value, stringBuilder)
	local typeFormatter = TypeFormatters [type (value)] or tostring
	return typeFormatter (value)
end

function ToLuaString (value, stringBuilder)
	local valueType = type (value)
	
	local name = GLib.Lua.GetObjectName (value)
	
	-- TODO: Handle tables and functions
	if type (value) == "function" then
		local functionInfo = GLib.Lua.Function (value)
		if functionInfo:IsNative () then
			if name then return name end
		else
			local sourceFile = functionInfo:GetFilePath ()
			local data = file.Read (sourceFile, "GAME")
			data = data or file.Read (sourceFile, "LUA")
			data = data or file.Read (sourceFile, SERVER and "LSV" or "LCL")
			
			if data then
				-- Normalize line endings
				data = string.gsub (data, "\r\n", "\n")
				data = string.gsub (data, "\r", "\n")
				
				local startLine = functionInfo:GetStartLine ()
				local endLine   = functionInfo:GetEndLine ()
				
				local lines = string.Split (data, "\n")
				if endLine <= #lines then
					local code = {}
					for i = startLine, endLine do
						code [#code + 1] = lines [i]
					end
					code = table.concat (code, "\n")
					return code
				end
			end
			
			return GLib.Lua.BytecodeReader (value):ToString ()
		end
	else
		if name then return name end
	end
	
	return ToCompactLuaString (value, stringBuilder)
end

function GLib.Lua.ToLuaString (value)
	local luaString = ToLuaString (value, stringBuilder)
	
	-- Collapse any StringBuilder objects
	if type (luaString) == "table" then
		luaString = luaString:ToString ()
	end
	
	return luaString
end

function GLib.Lua.ToCompactLuaString (value)
	local luaString = ToCompactLuaString (value, stringBuilder)
	
	-- Collapse any StringBuilder objects
	if type (luaString) == "table" then
		luaString = luaString:ToString ()
	end
	
	return luaString
end