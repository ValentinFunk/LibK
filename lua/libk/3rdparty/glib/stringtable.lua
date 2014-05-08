local self = {}
GLib.StringTable = GLib.MakeConstructor (self)

function self:ctor ()
	self.StringHashes = {}
	self.HashStrings = {}
end

function self:Add (str)
	if self.StringHashes [str] then return end
	
	local hash = tonumber (util.CRC (str))
	if self.HashStrings [hash] then
		GLib.Error ("StringTable:Add : " .. str .. "'s hash collides with " .. self.HashStrings [hash] .. "'s hash!")
	end
	
	self.StringHashes [str] = hash
	self.HashStrings [hash] = str
end

function self:HashFromString (str)
	if not self.StringHashes [str] then
		GLib.Error ("StringTable:HashFromString : " .. str .. " is not in the table!")
	end
	return self.StringHashes [str]
end

function self:StringFromHash (hash)
	if not self.HashStrings [hash] then
		GLib.Error ("StringTable:StringFromHash : " .. tostring (hash) .. " is not in the table!")
	end
	return self.HashStrings [hash]
end