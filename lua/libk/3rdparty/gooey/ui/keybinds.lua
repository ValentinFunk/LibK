Gooey.KeyBinds = {}

local bindKeys = {}

function Gooey.GetKeyBinding (key)
	return Gooey.KeyBinds [key]
end

hook.Add ("PlayerBindPress", "Gooey.Keybinds",
	function (ply, bind, pressed)
		if bindKeys [bind] then return end
		
		local key = input.LookupBinding (bind)
		if not key then return end
		
		bindKeys [bind] = key
		Gooey.KeyBinds [key] = bind
	end
)