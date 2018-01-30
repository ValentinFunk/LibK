-- Makes it possible to use DermaMenus with DoModal

local function DeactivateMouseForAllParents(panel)
    if not IsValid(panel) then return end

    local parent = panel
    repeat
        parent._oldMouseInputState = parent:IsMouseInputEnabled()
        parent:SetMouseInputEnabled(false)
        parent = parent:GetParent()
    until not IsValid(parent) or parent:GetParent() == parent
end

local function RestoreMouseInputState(panel)
    if not IsValid(panel) then return end

    local parent = panel
    repeat
        if parent._oldMouseInputState != nil then
            parent:SetMouseInputEnabled(parent._oldMouseInputState)
        end
        parent = parent:GetParent()
    until not IsValid(parent) or parent:GetParent() == parent
end

local menus = {}
hook.Add( "CloseDermaMenus", "TrackHack", function()
    for k, menu in pairs(menus) do
        if IsValid(menu) then
            RestoreMouseInputState(menu._parent)
            menu:Remove()
            menus[k] = nil
        end
    end
end )
function DermaMenuHack(parent)
    if not IsValid(parent) then return end
    local menu = DermaMenu(nil, parent)
    menu._parent = parent
    menu:SetDeleteSelf( false )
    function menu:OpenForModal(x, y)
        x = x or gui.MouseX()
        y = y or gui.MouseY()
        self:Open(x, y, false, parent)
        DeactivateMouseForAllParents(parent)
    end
    table.insert(menus, menu)

    return menu
end