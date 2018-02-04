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

local PANEL = {}

function PANEL:OpenMenu( pControlOpener )

	if ( pControlOpener && pControlOpener == self.TextEntry ) then
		return
	end

	-- Don't do anything if there aren't any options..
	if ( #self.Choices == 0 ) then return end

	-- If the menu still exists and hasn't been deleted
	-- then just close it and don't open a new one.
	if ( IsValid( self.Menu ) ) then
		CloseDermaMenus()
	end

	self.Menu = DermaMenuHack( self )

	if ( self:GetSortItems() ) then
		local sorted = {}
		for k, v in pairs( self.Choices ) do
			local val = tostring( v ) --tonumber( v ) || v -- This would make nicer number sorting, but SortedPairsByMemberValue doesn't seem to like number-string mixing
			if ( string.len( val ) > 1 && !tonumber( val ) && val:StartWith( "#" ) ) then val = language.GetPhrase( val:sub( 2 ) ) end
			table.insert( sorted, { id = k, data = v, label = val } )
		end
		for k, v in SortedPairsByMemberValue( sorted, "label" ) do
			self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )
		end
	else
		for k, v in pairs( self.Choices ) do
			self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
		end
	end

	local x, y = self:LocalToScreen( 0, self:GetTall() )

	self.Menu:SetMinimumWidth( self:GetWide() )
	self.Menu:OpenForModal( x, y )
end

function PANEL:ChooseOption( value, index )

	if IsValid( self.Menu ) then
		CloseDermaMenus()
	end

	self:SetText( value )

	-- This should really be the here, but it is too late now and convar changes are handled differently by different child elements
	--self:ConVarChanged( self.Data[ index ] )

	self.selected = index
	self:OnSelect( index, value, self.Data[ index ] )

end

function PANEL:CloseMenu()
    CloseDermaMenus()
end

derma.DefineControl( "DComboBoxHack", "", PANEL, "DComboBox" )
