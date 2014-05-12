Gooey.RenderHooks = {}

hook.Add ("PostRenderVGUI", "Gooey.PostRenderVGUI",
	function ()
		if Gooey.RenderHooks [Gooey.RenderType.DragDropPreview] then
			for _, renderFunction in pairs (Gooey.RenderHooks [Gooey.RenderType.DragDropPreview]) do
				xpcall (renderFunction, Gooey.Error)
			end
		end
		if Gooey.RenderHooks [Gooey.RenderType.ToolTip] then
			for _, renderFunction in pairs (Gooey.RenderHooks [Gooey.RenderType.ToolTip]) do
				xpcall (renderFunction, Gooey.Error)
			end
		end
	end
)

Gooey:AddEventListener ("Unloaded",
	function ()
		hook.Remove ("PostRenderVGUI", "Gooey.PostRenderVGUI")
	end
)

function Gooey.AddRenderHook (renderType, name, renderFunction)
	if not renderFunction then return end
	name = tostring (name)
	
	Gooey.RenderHooks [renderType] = Gooey.RenderHooks [renderType] or {}
	Gooey.RenderHooks [renderType] [name] = renderFunction
end

function Gooey.RemoveRenderHook (renderType, name)
	name = tostring (name)
	
	if not Gooey.RenderHooks [renderType] then return end
	Gooey.RenderHooks [renderType] [name] = nil
	if not next (Gooey.RenderHooks [renderType]) then
		Gooey.RenderHooks [renderType] = nil
	end
end