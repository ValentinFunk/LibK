local self = {}
GLib.Lua.Opcodes = GLib.MakeConstructor (self)

function self:ctor ()
	self.Opcodes = {}
end

function self:AddOpcode (opcode, name)
	self.Opcodes [opcode] = GLib.Lua.OpcodeInfo (opcode, name)
	return self.Opcodes [opcode]
end

function self:GetOpcode (opcode)
	if type (opcode) == "string" then
		opcode = GLib.Lua.Opcode [opcode]
	end
	
	if type (opcode) ~= "number" then return nil end
	
	return self.Opcodes [opcode]
end

GLib.Lua.Opcodes = GLib.Lua.Opcodes ()