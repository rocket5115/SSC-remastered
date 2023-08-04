Current_Sessions = {}
Current_Players = {}

RegisterNetEvent('SSC:Server:CreateSession', function(id,_src)
    local src = _src or source
    Current_Players[src] = Current_Players[src] or {
        source = src,
        uid = GetUniqueId(src)
    }
    local uid = Current_Players[src].uid
    if not Current_Sessions[uid] then
        local data = RetrieveFile('_SSC_Session_'..id, src)or {}
        Current_Sessions[uid] =  {
            id = id,
            scenes = data.scenes or {
                ['0'] = {
                    Entities = {}
                }
            }
        }
        SaveFile('_SSC_Session_'..id,{id = id, scenes = Current_Sessions[uid].scenes},src)
        TriggerClientEvent('SSC:Client:LoadSession', src, Current_Sessions[uid])
    elseif Current_Sessions[uid].id == id then
        TriggerClientEvent('SSC:Client:UnloadSession', src, Current_Sessions[uid])
        Current_Sessions[uid]=nil
    end
end)

RegisterNetEvent('SSC:Server:LoadSession', function(id)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        TriggerClientEvent('SSC:Client:UnloadSession', src, Current_Sessions[uid])
        Current_Sessions[uid]=nil
        Wait(0) -- for future
        TriggerEvent('SSC:Server:CreateSession', id, src)
    else
        TriggerEvent('SSC:Server:CreateSession', id, src)
    end
end)

RegisterNetEvent('SSC:Server:UnloadSession', function(_src)
    local src = _src or source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        TriggerClientEvent('SSC:Client:UnloadSession', src, Current_Sessions[uid])
        Current_Sessions[uid]=nil
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:SaveSession', function(_src, data)
    local src = _src or source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        if data then
            for k,v in pairs(Current_Sessions[uid].scenes)do
                for i=1,#v.Entities do
                    v.Entities[i]=data[v.Entities[i].entity]or v.Entities[i]
                end
            end
        end
        SaveFile('_SSC_Session_'..Current_Sessions[uid].id,Current_Sessions[uid],src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:add_entity', function(data, session)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        table.insert(Current_Sessions[uid].scenes[data.scene].Entities, data)
        TriggerEvent('SSC:Server:SaveSession', src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:remove_entity', function(data,session)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        for k,v in ipairs(Current_Sessions[uid].scenes[data.scene].Entities)do
            if v.id==data.id then
                table.remove(Current_Sessions[uid].scenes[data.scene].Entities, k)
                break
            end
        end
        TriggerEvent('SSC:Server:SaveSession', src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:add_scene', function(name)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        Current_Sessions[uid].scenes[name]=Current_Sessions[uid].scenes[name]or{Entities={}}
        TriggerEvent('SSC:Server:SaveSession', src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:remove_scene', function(name)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        Current_Sessions[uid].scenes[name]=nil
        TriggerEvent('SSC:Server:SaveSession', src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)

RegisterNetEvent('SSC:Server:change_entity_scene', function(data)
    local src = source
    local uid = GetUniqueId(src)
    if Current_Sessions[uid] then
        for k,v in ipairs(Current_Sessions[uid].scenes[data.from].Entities)do
            if v.id==data.name then
                v.scene=data.new
                table.insert(Current_Sessions[uid].scenes[data.to].Entities, v)
                table.remove(Current_Sessions[uid].scenes[data.from].Entities, k)
                break
            end
        end
        TriggerEvent('SSC:Server:SaveSession', src)
    else
        SendError(src, 'Session not loaded. Any Changes will not be saved!')
    end
end)