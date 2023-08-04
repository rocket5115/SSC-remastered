--[[
    Shortcuts
]]

EntityType = {
    [1] = 'ped',
    [2] = 'veh',
    [3] = 'obj'
}
setmetatable(EntityType, {__index = function(t,k) 
    return "none"
end})

--[[
    Main / C_ = Current
]]

Entities = {} -- holds information for entities
C_Entities = {} -- references Entities by entity as index

C_Scene = '0'