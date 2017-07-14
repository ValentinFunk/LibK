local function getControlName(dermaInstance)
    return table.KeyFromValue(derma.GetControlList(), dermaInstance)
end

--[[
    Somehow gmod fucks up the last entry and we would end up in and
    infine loop. A quirk is that the class name doesn't match the panel anymore
]]--
local function endOfChain(dermaInstance)
    local controlName = getControlName(dermaInstance)
    return derma.Controls[controlName].ClassName != controlName
end

--[[
    Returns if aControlName inherits from controlName.
    e.g. LibK.DermaInherits()
]]--
function LibK.DermaInherits(aControlName, controlName)
    if aControlName == controlName then
        return true
    end

    local parentName = derma.Controls[aControlName].BaseClass
    local parent = derma.Controls[parentName]
    while parent and not endOfChain(parent) do
        if parentName == controlName then
            return true
        end

        parentName = parent.BaseClass
        if not parentName then
            break
        end
        
        parent = derma.Controls[parentName]
    end
    
    return false
end