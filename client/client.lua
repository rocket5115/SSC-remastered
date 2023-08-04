local show = false
local lastsession = '0'
RegisterCommand('s', function()
    show=not show
    display(show,false)
end)

RegisterCommand('createsession', function(_,args)
    local id = args[1] or '0'
    TriggerServerEvent('SSC:Server:CreateSession', id)
    lastsession=id
end)

RegisterCommand('unloadsession', function()
    TriggerServerEvent('SSC:Server:UnloadSession', id)
end)

RegisterCommand('loadsession', function(_,args)
    local id = args[1] or '0'
    TriggerServerEvent('SSC:Server:LoadSession', id)
    lastsession=id
end)

RegisterCommand('savesession', function()
    for k,v in pairs(C_Entities) do
        v.data.coords = GetEntityCoords(k)
        v.data.rotation = GetEntityRotation(k)
        SendNUIMessage({
            type = 'update_entity_data',
            coords = v.data.coords,
            rotation = v.data.rotation,
            network = v.data.network,
            mission = v.data.mission
        })
    end
    TriggerServerEvent('SSC:Server:SaveSession', nil, C_Entities)
end)

AddEventHandler('SSC:NUI:Status', function(s)
    show = s
end)

RegisterNetEvent('SSC:Client:LoadSession', function(data)
    local peds,vehicles,objects = GetGamePool('CPed'),GetGamePool('CVehicle'),GetGamePool('CObject')
    for name,data in pairs(data.scenes) do
        SendNUIMessage({
            type = 'new_scene',
            name = name
        })
        for _,v in ipairs(data.Entities) do
            local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
            local entity
            if v.type==1 or v.type==2 then
                if v.type == 1 then
                    for i=1,#peds do
                        if GetEntityModel(peds[i])==v.model and #(GetEntityCoords(peds[i])-coords)<10.0 then
                            DeleteNetworkedEntity(peds[i])
                        end
                    end
                    entity = CreateLocalPed(coords.x, coords.y, coords.z, v.rotation.z, v.model, v.network, v.mission, {scene=name,id=v.id})
                elseif v.type == 2 then
                    for i=1,#vehicles do
                        if GetEntityModel(vehicles[i])==v.model and #(GetEntityCoords(vehicles[i])-coords)<10.0 then
                            DeleteNetworkedEntity(vehicles[i])
                        end
                    end
                    entity = CreateLocalVehicle(coords.x, coords.y, coords.z, v.rotation.z, v.model, v.network, v.mission, {scene=name,id=v.id})
                end
            elseif v.type==3 then
                for i=1,#objects do
                    if GetEntityModel(objects[i])==v.model and #(GetEntityCoords(objects[i])-coords)<10.0 then
                        DeleteNetworkedEntity(objects[i])
                    end
                end
                entity = CreateLocalObject(coords.x, coords.y, coords.z, v.model, v.network, v.mission, v.door, {scene=name,id=v.id})
                SetEntityRotation(entity, v.rotation.x, v.rotation.y, v.rotation.z)
            end
            SendNUIMessage({
                type = 'new_entity',
                _type = v.type,
                entity = C_Entities[entity].data.id,
                scene = C_Entities[entity].data.scene
            })
        end
    end
    SendNotification({
        title = 'Information',
        message = 'Loaded/Created Session: '..data.id,
        color = 'green',
        time = 3000
    })
end)

RegisterNetEvent('SSC:Client:UnloadSession', function(data)
    local peds,vehicles,objects = GetGamePool('CPed'),GetGamePool('CVehicle'),GetGamePool('CObject')
    SendNUIMessage({
        type = 'remove_scenes'
    })
    for name,data in pairs(data.scenes) do
        for _,v in ipairs(data.Entities) do
            local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
            if v.type==1 or v.type==2 then
                if v.type == 1 then
                    for i=1,#peds do
                        if GetEntityModel(peds[i])==v.model and #(GetEntityCoords(peds[i])-coords)<10.0 then
                            DeleteNetworkedEntity(peds[i])
                        end
                    end
                elseif v.type == 2 then
                    for i=1,#vehicles do
                        if GetEntityModel(vehicles[i])==v.model and #(GetEntityCoords(vehicles[i])-coords)<10.0 then
                            DeleteNetworkedEntity(vehicles[i])
                        end
                    end
                end
            elseif v.type==3 then
                for i=1,#objects do
                    if GetEntityModel(objects[i])==v.model and #(GetEntityCoords(objects[i])-coords)<10.0 then
                        DeleteNetworkedEntity(objects[i])
                    end
                end
            end
        end
    end
    SendNotification({
        title = 'Information',
        message = 'Unloaded Session: '..data.id,
        color = 'blue',
        time = 3000
    })
end)

function SendQuickInfo(msg,color)
    SendNotification({
        title = 'Info',
        message = msg,
        color = color or 'lightgreen',
        time = 2000
    })
end

RegisterNetEvent('SSC:Client:Notification', function(options)
    SendNotification(options)
end)

AddEventHandler('SSC:Internal:new_entity', function(entity)
    TriggerServerEvent('SSC:Server:add_entity', C_Entities[entity].data, lastsession)
    SendQuickInfo('Added Entity: '..C_Entities[entity].data.id)
end)

AddEventHandler('SSC:Internal:entity_removed', function(data)
    TriggerServerEvent('SSC:Server:remove_entity', data.data, lastsession)
    SendQuickInfo('Removed Entity: '..data.data.id, 'orange')
end)

AddEventHandler('SSC:Internal:new_scene', function(scene)
    TriggerServerEvent('SSC:Server:add_scene', scene)
    SendQuickInfo('Added Scene: '..scene, 'darkgreen')
end)

AddEventHandler('SSC:Internal:remove_scene', function(scene)
    TriggerServerEvent('SSC:Server:remove_scene', scene)
    SendQuickInfo('Removed Scene: '..scene, 'darkorange')
end)

AddEventHandler('SSC:Internal:entity_move_scene', function(data)
    TriggerServerEvent('SSC:Server:change_entity_scene', data)
end)