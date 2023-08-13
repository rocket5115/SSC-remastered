PendingAnims = {}
PendingEntities = {}

local TPA = TaskPlayAnim
TaskPlayAnim = function(entity,...)
    local data = {...}
    local netid = NetworkGetNetworkIdFromEntity(entity)
    TriggerClientEvent('SSC:Client:AnimInteractionZone', -1, GetEntityCoords(entity), netid, ...)
    PendingEntities[netid] = {
        coords = GetEntityCoords(entity),
        data = {...}
    }
    TPA(entity, ...)
end

RegisterNetEvent('SSC:Server:ActivePlayer', function()
    local player = source
    TriggerClientEvent('SSC:Client:AnimInteractionZones', player, PendingEntities)
end)

Sessions = {}

function EnsureSession(name)
    Sessions[name] = Sessions[name] or {listener={}}
    return {
        listener = {}
    }
end

function StartSession(name, entities)
    if not Sessions[name] then return end
    for i=1,#entities do
        local type = entities[i].type
        type = ((type==1 and'ped')or type==2 and'vehicle')or'object'
        if Sessions[name].listener[type] then
            Sessions[name].listener[type](entities[i].entity)
        end
        Wait(10)
        if Sessions[name].listener[entities[i].id] then
            Sessions[name].listener[entities[i].id](entities[i].entity)
        end
    end
end