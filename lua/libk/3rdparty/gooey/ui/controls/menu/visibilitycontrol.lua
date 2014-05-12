local openMenus = {}

function Gooey.CloseMenus ()
	for menu, _ in pairs (openMenus) do
		menu:Hide ()
		openMenus [menu] = nil
	end
end

function Gooey.IsMenuOpen ()
	return next (openMenus) and true or false
end

function Gooey.RegisterOpenMenu (menu)
	openMenus [menu] = true
	
	menu:AddEventListener ("VisibleChanged", "Gooey.MenuVisibilityControl",
		function (_, visible)
			if not visible then
				menu:RemoveEventListener ("VisibleChanged", "Gooey.MenuVisibilityControl")
				openMenus [menu] = nil
			end
		end
	)
end

hook.Add ("VGUIMousePressed", "GMenus",
	function (panel, mouseCode)
		while panel ~= nil and panel:IsValid () do
			if panel.ClassName == "DMenu" then
				return
			end
			panel = panel:GetParent ()
		end
		
		Gooey.CloseMenus ()
	end
)

Gooey:AddEventListener ("Unloaded",
	function ()
		Gooey.CloseMenus ()
	end
)