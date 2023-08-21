local show = false
local lastsession = '0'
RegisterCommand('openssc', function()
    if not GConfig.Admin then return end
    show=not show
    display(show,false)
end)

RegisterCommand('createsession', function(_,args)
    if not GConfig.Admin then return end
    local id = args[1] or '0'
    TriggerServerEvent('SSC:Server:CreateSession', id)
    lastsession=id
end)

RegisterCommand('unloadsession', function()
    if not GConfig.Admin then return end
    TriggerServerEvent('SSC:Server:UnloadSession', id)
end)

RegisterCommand('loadsession', function(_,args)
    if not GConfig.Admin then return end
    local id = args[1] or '0'
    TriggerServerEvent('SSC:Server:LoadSession', id)
    lastsession=id
end)

RegisterCommand('createtemplate', function(_,args)
    if not GConfig.Admin then return end
    local name = args[1]
    if not name or name:len()==0 then
        SendNUIMessage({
            type = 'notification',
            title = 'error',
            message = 'name length > 0',
            color = 'red',
            time = 4000
        })
        return
    else
        TriggerServerEvent('SSC:Server:create_template', name, RetrieveTemplateData())
    end
end)

RegisterCommand('loadtemplate', function(_,args)
    if not GConfig.Admin then return end
    local name = args[1]
    if not name or name:len()==0 then
        SendNUIMessage({
            title = 'error',
            message = 'name length > 0',
            color = 'red',
            time = 4000
        })
        return
    else
        TriggerServerEvent('SSC:Server:load_template', name)
    end
end)

RegisterCommand('savesession', function()
    if not GConfig.Admin then return end
    for k,v in pairs(C_Entities) do
        v.data.coords = GetEntityCoords(k)
        v.data.rotation = GetEntityRotation(k)
        SendNUIMessage({
            type = 'update_entity_data',
            coords = v.data.coords,
            rotation = v.data.rotation,
            network = v.data.network,
            mission = v.data.mission,
            classes = v.data.classes
        })
    end
    TriggerServerEvent('SSC:Server:SaveSession', nil, C_Entities)
end)

AddEventHandler('SSC:NUI:Status', function(s)
    show = s
end)

RegisterNetEvent('SSC:Client:LoadSession', function(data)
    SendNUIMessage({
        type = 'remove_scenes'
    })
    for k in pairs(C_Entities)do
        if DoesEntityExist(k) then
            DeleteNetworkedEntity(k)
        end
    end
    local peds,vehicles,objects = GetGamePool('CPed'),GetGamePool('CVehicle'),GetGamePool('CObject')
    local assured = false
    SendNotification({
        title = 'Information',
        message = 'Loading Session: '..data.id..'<br>Please Wait up to 10s for collisions to load.',
        color = 'yellow',
        time = 3000
    })
    local ent
    for name,data in pairs(data.scenes) do
        SendNUIMessage({
            type = 'new_scene',
            name = name
        })
        for _,v in ipairs(data.Entities) do
            local coords = vector3(v.coords.x, v.coords.y, v.coords.z)
            if not assured then
                EnsurePlayerPosition(coords)
                assured = true
            end
            local entity
            if v.type==1 or v.type==2 then
                if v.type == 1 then
                    for i=1,#peds do
                        if GetEntityModel(peds[i])==v.model and #(GetEntityCoords(peds[i])-coords)<10.0 then
                            DeleteNetworkedEntity(peds[i])
                        end
                    end
                    entity = CreateLocalPed(coords.x, coords.y, coords.z - 1.0, v.rotation.z, v.model, v.network, v.mission, {scene=name,id=v.id,classes=v.classes})
                    SetPedStill(entity)
                elseif v.type == 2 then
                    for i=1,#vehicles do
                        if GetEntityModel(vehicles[i])==v.model and #(GetEntityCoords(vehicles[i])-coords)<10.0 then
                            DeleteNetworkedEntity(vehicles[i])
                        end
                    end
                    entity = CreateLocalVehicle(coords.x, coords.y, coords.z, v.rotation.z, v.model, v.network, v.mission, {scene=name,id=v.id,classes=v.classes})
                end
            elseif v.type==3 then
                for i=1,#objects do
                    if GetEntityModel(objects[i])==v.model and #(GetEntityCoords(objects[i])-coords)<10.0 then
                        DeleteNetworkedEntity(objects[i])
                    end
                end
                entity = CreateLocalObject(coords.x, coords.y, coords.z, v.model, v.network, v.mission, v.door, {scene=name,id=v.id,classes=v.classes})
                SetEntityRotation(entity, v.rotation.x, v.rotation.y, v.rotation.z)
            end
            FreezeEntityPosition(entity, true)
            SendNUIMessage({
                type = 'new_entity',
                _type = v.type,
                entity = C_Entities[entity].data.id,
                scene = C_Entities[entity].data.scene
            })
            local classes = ""
            for i=1,#C_Entities[entity].data.classes do
                classes = classes..'#'..C_Entities[entity].data.classes[i]
            end
            SendNUIMessage({
                type = 'update_entity',
                data = {
                    entity = C_Entities[entity].data.id,
                    coords = tostring(RoundNumber(coords.x,4))..","..tostring(RoundNumber(coords.y,4))..","..tostring(RoundNumber(v.type~=1 and coords.z or coords.z-1.0,4)),
                    rot = tostring(RoundNumber(v.rotation.x,4))..","..tostring(RoundNumber(v.rotation.y,4))..","..tostring(RoundNumber(v.rotation.z,4)),
                    mission = v.mission,
                    network = v.network,
                    classes = classes
                }
            })
            ent = entity
            Wait(10)
        end
    end
    SendNUIMessage({
        type = 'event',
        name = 'loaded-session',
        data = {
            id = data.id
        }
    })
    SendNotification({
        title = 'Information',
        message = 'Loaded/Created Session: '..data.id,
        color = 'green',
        time = 3000
    })
    TriggerServerEvent('SSC:Server:LoadedSession', data.id)
end)

RegisterNetEvent('SSC:Client:UnloadSession', function(data)
    SendNUIMessage({
        type = 'remove_scenes'
    })
    for k in pairs(C_Entities)do
        DeleteNetworkedEntity(k)
    end
    SendNotification({
        title = 'Information',
        message = 'Unloaded Session: '..data.id,
        color = 'blue',
        time = 3000
    })
    SendNUIMessage({
        type = 'event',
        name = 'unloaded-session',
        data = {
            id = data.id
        }
    })
    C_Entities = {}
    Entities = {}
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

local ents = {}
local cur_I = 1
local last_I = 1
local max_I = 1
local cur_cam = 0
local cur_slider = ''
local last_ent = 0

AddEventHandler('SSC:Internal:go_to_entity', function(entity,cam,entities)
    ents = entities or GetEntitiesInScene(C_Entities[entity].data.scene)
    max_I = #ents
    cur_cam = cam
    for i=1,#ents do
        if ents[i].entity==entity then
            cur_I = i
            break
        end
    end
    last_ent = cur_I
    cur_slider = 'Entities'
    if ents[cur_I].data.type == 1 then
        SetEntityAlpha(ents[cur_I].entity, 200)
    else
        SetEntityDrawOutline(ents[cur_I].entity, true)
		SetEntityDrawOutlineColor(255,0,0,100)
    end
    SendNUIMessage({
        type = 'information',
        data = {
            title = 'Scene: '..C_Entities[ents[cur_I].entity].data.scene,
            options = {
                {
                    text = 'Name:',
                    type = 'var',
                    id = 'name'
                },
                {
                    text = 'Change Position: [ENTER]',
                    type = 'text'
                },
                {
                    text = 'Remove Entity: [DELETE]',
                    type = 'text'
                },
                {
                    text = 'Cancel: [BACKSPACE]',
                    type = 'text'
                },
                {
                    title = 'Entities',
                    type = 'slider',
                    start = cur_I,
                    stop = max_I
                }
            }
        }
    })
    SendNUIMessage({
        type = 'info_update_slider',
        name = cur_slider,
        value = cur_I,
        ids = {
            name = C_Entities[ents[cur_I].entity].data.id
        }
    })
end)

local function UpdateFreecamFocus(entity)
    SetFreecamPosition(table.unpack(GetEntityCoords(entity)+vector3(5.0,5.0,0.0)))
    PointCamAtEntity(cur_cam, entity, 0.0, 0.0, 0.0, 1)
    SetFreecamRotation(table.unpack(GetCamRot(cur_cam)))
    local ent = ents[last_ent].entity
    if ents[last_ent].data.type == 1 then
        ResetEntityAlpha(ent)
    else
        SetEntityDrawOutline(ent, false)
    end
    last_ent = cur_I
    if ents[cur_I].data.type == 1 then
        SetEntityAlpha(entity, 200)
    else
        SetEntityDrawOutline(entity, true)
		SetEntityDrawOutlineColor(255,0,0,100)
    end
end

AddEventHandler('SSC:Internal:slider_left', function(name)
    last_I = cur_I
    cur_I = cur_I - 1
    if cur_I < 1 then
        cur_I = max_I
    end
    UpdateFreecamFocus(ents[cur_I].entity)
    SendNUIMessage({
        type = 'info_update_slider',
        name = name,
        value = cur_I,
        ids = {
            name = C_Entities[ents[cur_I].entity].data.id
        }
    })
end)

AddEventHandler('SSC:Internal:slider_right', function(name)
    last_I = cur_I
    cur_I = cur_I + 1
    if cur_I > max_I then
        cur_I = 1
    end
    UpdateFreecamFocus(ents[cur_I].entity)
    SendNUIMessage({
        type = 'info_update_slider',
        name = name,
        value = cur_I,
        ids = {
            name = C_Entities[ents[cur_I].entity].data.id
        }
    })
end)

RegisterCommand('SSC_sliderr', function()
    if not GConfig.Admin then return end
    if not ents or #ents==0 or cur_I==0 then return end
    TriggerEvent('SSC:Internal:slider_right', cur_slider)
end)

RegisterCommand('SSC_sliderl', function()
    if not GConfig.Admin then return end
    if not ents or #ents==0 or cur_I==0 then return end
    TriggerEvent('SSC:Internal:slider_left', cur_slider)
end)

RegisterCommand('SSC_sliderd', function()
    if not GConfig.Admin then return end
    SendNUIMessage({
        type = 'remove_entity',
        entity = ents[cur_I].data.id
    })
    table.remove(ents, cur_I)
    local newEntity = cur_I-1>0 and ents[cur_I-1].entity or (ents[cur_I] and ents[cur_I].entity)
    if not newEntity then
        SendNUIMessage({
            type = 'd_information'
        })
        SetFreecamActive(false)
    else
        SendNUIMessage({
            type = 'd_information'
        })
        last_ent = cur_I-1>0 and cur_I-1 or cur_I
        cur_I = cur_I-1>0 and cur_I-1 or cur_I
        UpdateFreecamFocus(newEntity)
        TriggerEvent('SSC:Internal:go_to_entity', newEntity, cur_cam, ents)
    end
end)

RegisterKeyMapping('openssc', '', 'keyboard', 'TAB')
RegisterKeyMapping('SSC_sliderr', '', 'keyboard', 'RIGHT')
RegisterKeyMapping('SSC_sliderl', '', 'keyboard', 'LEFT')
RegisterKeyMapping('SSC_sliderd', '', 'keyboard', 'DELETE')

AddEventHandler('SSC:Internal:go_to_cancel', function(camera)
    ResetEntityAlpha(ents[last_ent].entity)
    SetEntityDrawOutline(ents[last_ent].entity, false)
end)

AddEventHandler('SSC:Internal:go_to_accept', function(camera)
    ResetEntityAlpha(ents[last_ent].entity)
    SetEntityDrawOutline(ents[last_ent].entity, false)
    Wait(50)
    local entity = ents[cur_I].entity
    local keep = true
    local proceed = true
    local fCoords = vector3(0.0,0.0,0.0)
    local heading = 0.0
    local camera = CreateCamera(nil, {
        destructor = function(camera)
            keep = false
            proceed = false
        end,
        accept = function(camera)
            heading = GetCamRot(camera).z
            keep = false
        end,
        onupdate = function(camera)
            local hit,coords,entity = RaycastGameplayCamera(1000.0, camera)
            if hit then
                fCoords = coords
            end
        end
    })
    while keep do
        Wait(10)
        DrawSphere(fCoords.x, fCoords.y, fCoords.z, 0.2, 255, 0, 0, 1.0)
    end
    if not proceed then
        return
    end
    SetEntityCoords(entity, fCoords.x, fCoords.y, fCoords.z, false, false, false, false)
    local rot = GetEntityRotation(entity)
    if ents[cur_I].data.type~=2 then 
        SetEntityHeading(entity,heading)
    else 
        SetEntityRotation(entity, rot.x, rot.y, heading)
    end
    rot = GetEntityRotation(entity)
    C_Entities[entity].data.coords = fCoords
    C_Entities[entity].data.rotation = GetEntityRotation(entity)
    SendNUIMessage({
        type = 'update_entity',
        data = {
            entity = C_Entities[entity].data.id,
            coords = tostring(RoundNumber(fCoords.x,4))..","..tostring(RoundNumber(fCoords.y,4))..","..tostring(RoundNumber(fCoords.z,4)),
            rot = tostring(RoundNumber(rot.x,4))..","..tostring(RoundNumber(rot.y,4))..","..tostring(RoundNumber(rot.z,4)),
        }
    })
    TriggerServerEvent('SSC:Server:save_entity', C_Entities[entity].data)
end)

local TemplateEntities = {}

RegisterNetEvent('SSC:Client:load_template', function(data)
    local ents = CreateTemplateEntities(data, GetEntityCoords(PlayerPedId()))
    local camera = CreateCamera(nil, {
        destructor = function(camera)
            for i=1,#ents do
                DeleteNetworkedEntity(ents[i].entity)
            end
            ents = nil
        end,
        accept = function(camera)
            TemplateEntities=ents
            local name = 'TEMP'..math.random(99999)
            SendNUIMessage({
                type = 'new_scene',
                name = name
            })
            TriggerEvent('SSC:Internal:new_scene', name)
            for i=1,#ents do
                local entity = ents[i].entity
                SendNUIMessage({
                    type = 'new_entity',
                    _type = C_Entities[entity].data.type,
                    entity = C_Entities[entity].data.id,
                    scene = name
                })
                C_Entities[entity].data.scene = name
                C_Entities[entity].data.coords = GetEntityCoords(entity)
                if C_Entities[entity].data.type == 1 then
                    C_Entities[entity].data.coords = C_Entities[entity].data.coords - vector3(0.0,0.0,1.0)
                end
                C_Entities[entity].data.rotation = GetEntityRotation(entity)
                local rot = C_Entities[entity].data.rotation
                SendNUIMessage({
                    type = 'update_entity',
                    data = {
                        entity = C_Entities[entity].data.id,
                        coords = tostring(RoundNumber(C_Entities[entity].data.coords.x,4))..","..tostring(RoundNumber(C_Entities[entity].data.coords.y,4))..","..tostring(RoundNumber(C_Entities[entity].data.coords.z,4)),
                        rot = tostring(RoundNumber(rot.x,4))..","..tostring(RoundNumber(rot.y,4))..","..tostring(RoundNumber(rot.z,4)),
                        mission = C_Entities[entity].data.mission,
                        network = C_Entities[entity].data.network,
                        classes = C_Entities[entity].data.classes
                    }
                })
                TriggerEvent('SSC:Internal:new_entity', entity)
                Wait(10)
            end
            SendNUIMessage({
                type = 'notification',
                title = 'info',
                color = 'green',
                message = 'Successfully Created and Set Template<br>It\'s available in editor under name: '..name
            })
        end,
        onupdate = function(camera)
            local hit,coords,entity = RaycastGameplayCamera(1000.0, camera)
            if hit and not C_Entities[entity] then
                local r = GetCamRot(camera).z
                SetTemplatePosition(ents, coords, r)
                DrawSphere(coords.x, coords.y, coords.z, 0.2, 255, 0, 0, 1.0)
            end
        end
    })
end)

RegisterNetEvent('SSC:Client:LoadAnim', function(entity, ...)
    local data = {...}
    local entity = NetworkGetEntityFromNetworkId(entity)
    local dict = data[1]
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(entity, ...)
end)

RegisterNetEvent('SSC:Client:LoadAnims', function(anims, ents)
    for k,v in pairs(anims) do
        RequestAnimDict(k)
    end
    for k,v in pairs(anims)do
        while not HasAnimDictLoaded(k)do Wait(10) end
    end
    for k,v in pairs(ents) do
        local ent = NetworkGetEntityFromNetworkId(k)
        if DoesEntityExist(ent) then
            TaskPlayAnim(ent, table.unpack(v))
        end
    end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(100)
    end
    Wait(1000)
    TriggerServerEvent('SSC:Server:ActivePlayer')
end)

local GCoords = {}

RegisterNetEvent('SSC:Client:AnimInteractionZone', function(coords, entity, ...)
    local data = {...}
    RequestAnimDict(data[1])
    while not HasAnimDictLoaded(data[1])do Wait(10)end
    GCoords[#GCoords+1] = {
        coords = coords,
        entity = entity,
        data = data
    }
end)

RegisterNetEvent('SSC:Client:AnimInteractionZones', function(data)
    for k,v in pairs(data)do
        RequestAnimDict(v.data[1])
    end
    for k,v in pairs(data)do
        while not HasAnimDictLoaded(v.data[1])do Wait(10)end
    end
    for k,v in pairs(data)do
        GCoords[#GCoords+1] = {
            coords = v.coords,
            entity = k,
            data = v.data
        }
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local len = #GCoords
        if len~=0 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            for i=1,len do
                local j = (len - i) + 1
                local req = 0
                if #(GCoords[j].coords-coords)<30.0 then
                    while not HasCollisionLoadedAroundEntity(ped) and req<100 do Wait(100) req = req + 1 end
                    if NetworkDoesEntityExistWithNetworkId(GCoords[j].entity) then
                        local entity = NetworkGetEntityFromNetworkId(GCoords[j].entity)
                        TaskPlayAnim(entity, table.unpack(GCoords[j].data))
                    end
                    table.remove(GCoords, j)
                end
            end
        end
    end
end)