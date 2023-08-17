if not GConfig.Enable then
    local rnc = RegisterNUICallback
    local rc = RegisterCommand
    local aeh = AddEventHandler
    RegisterNUICallback = function()end
    RegisterCommand = function()end
    AddEventHandler = function()end
end

NUIOn = false
NUILoaded = false
local actives = {}
local args = {}

function SendWhenNUIActive(data,...)
    if(type(data)~='function')then
        if NUILoaded then
            SendNUIMessage(data)
        else
            actives[#actives+1]=data
        end
    else
        if NUILoaded then
            data(...)
        else
            actives[#actives+1]=data
            args[#actives]={...}
        end
    end
end

CreateThread(function()
    local requested = 0
    while not NUILoaded and requested<50 do
        Wait(50)
        requested=requested+1
    end
    NUILoaded=true
    for i=1,#actives do
        if(type(actives[i])~='function')then
            SendNUIMessage(actives[i])
        else
            actives[i](table.unpack(args[i]))
        end
    end
    actives = nil
    args = nil
end)

function display(p1,p2)
    NUIOn=p1
    if p2 then
        SetNuiFocus(false,false)
        SetNuiFocusKeepInput(true)
    else
        SetNuiFocusKeepInput(false)
        SetNuiFocus(p1,p1)
    end
    SendNUIMessage({
        type='show',
        show=NUIOn
    })
    TriggerEvent('SSC:NUI:Status', NUIOn)
end

function IsNUIActive()
    return NUIOn
end

function SendNotification(options)
    SendNUIMessage({
        type = 'notification',
        options = options
    })
end

RegisterNUICallback('nuioff', function()
    display(false,false)
end)

RegisterNUICallback('loaded', function()
    NUILoaded = true
end)

RegisterNUICallback('remove_entity', function(data)
    local entity = GetEntityFromName(data.name)
    TriggerEvent('SSC:Internal:entity_removed', C_Entities[entity])
    RemoveEntity(entity)
end)

RegisterNUICallback('entity_move_scene', function(data)
    local entity = GetEntityFromName(data.entity)
    C_Entities[entity].data.scene = data.to
    TriggerEvent('SSC:Internal:entity_move_scene', data)
end)

RegisterNUICallback('update_entity_name', function(data)
    local old,new,id = data.name,data.new,data.scene_id
    local entity = GetEntityFromName(old)
    C_Entities[entity].data.id = new
    TriggerServerEvent('SSC:Server:change_entity_name', old, new, C_Entities[entity].data.scene)
end)

RegisterNUICallback('update_entity_coords', function(data)
    local entity = GetEntityFromName(data.name)
    SetEntityCoords(entity, data.coords.x, data.coords.y, data.coords.z, false, false, false, false)
end)

RegisterNUICallback('update_entity_rotation', function(data)
    local entity = GetEntityFromName(data.name)
    SetEntityRotation(entity, data.rot.x, data.rot.y, data.rot.z)
end)

RegisterNUICallback('update_entity_mission', function(data)
    local entity = GetEntityFromName(data.name)
    C_Entities[entity].data.mission = data.value
end)

RegisterNUICallback('update_entity_network', function(data)
    local entity = GetEntityFromName(data.name)
    C_Entities[entity].data.network = data.value
end)

RegisterNUICallback('go_to_entity', function(data)
    local entity = GetEntityFromName(data.name)
    local cam = CreateCamera(GetEntityCoords(entity)+vector3(1.0,1.0,0.0), {
        onupdate = function(camera)
            SetFreecamRotation(table.unpack(GetCamRot(camera)))
        end,
        destructor = function(camera)
            SendNUIMessage({
                type = 'd_information'
            })
            TriggerEvent('SSC:Internal:go_to_cancel', camera)
        end,
        accept = function(camera)
            SendNUIMessage({
                type = 'd_information'
            })
            TriggerEvent('SSC:Internal:go_to_accept', camera)
        end
    })
    PointCamAtEntity(cam, entity, 0.0, 0.0, 0.0, 1)
    SetFreecamRotation(table.unpack(GetCamRot(cam)))
    display(false,false)
    TriggerEvent('SSC:Internal:go_to_entity', entity, cam)
end)

RegisterNUICallback('spawn_entity', function(data)
    display(false,false)
    local type,model,mission,network,door,coords = data.type,data.model,data.mission,data.network,data.door,GetEntityCoords(PlayerPedId())+vector3(1.0,1.0,0.0)
    local keep = true
    local proceed = true
    local fCoords = vector3(0.0,0.0,0.0)
    local heading = 0.0
    SendNUIMessage({
        type = 'information',
        data = {
            title = 'New Entity',
            options = {
                {
                    text = 'Accept Position: [ENTER]',
                    type = 'text'
                },
                {
                    text = 'Cancel: [BACKSPACE]',
                    type = 'text'
                }
            }
        }
    })
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
    SendNUIMessage({
        type = 'd_information'
    })
    if not proceed then
        return
    end
    local entity
    if type == 1 then
        entity = CreateLocalPed(fCoords.x, fCoords.y, fCoords.z, heading, model, network, mission)
        C_Entities[entity].data.coords = C_Entities[entity].data.coords-vector3(0.0,0.0,1.0)
    elseif type == 2 then
        entity = CreateLocalVehicle(fCoords.x, fCoords.y, fCoords.z, heading, model, network, mission)
    elseif type == 3 then
        entity = CreateLocalObject(fCoords.x, fCoords.y, fCoords.z, model, network, door)
        SetEntityRotation(entity, 0.0, 0.0, heading)
    end
    TriggerEvent('SSC:Internal:new_entity', entity)
    SendNUIMessage({
        type = 'new_entity',
        _type = type,
        entity = C_Entities[entity].data.id
    })
    local rot = GetEntityRotation(entity)
    SendNUIMessage({
        type = 'update_entity',
        data = {
            entity = C_Entities[entity].data.id,
            coords = tostring(RoundNumber(fCoords.x,4))..","..tostring(RoundNumber(fCoords.y,4))..","..tostring(RoundNumber(fCoords.z,4)),
            rot = tostring(RoundNumber(rot.x,4))..","..tostring(RoundNumber(rot.y,4))..","..tostring(RoundNumber(rot.z,4)),
            mission = C_Entities[entity].data.mission,
            network = C_Entities[entity].data.network
        }
    })
    display(true,false)
end)

RegisterNUICallback('scene_create', function(data)
    TriggerEvent('SSC:Internal:new_scene', data.id)
end)

RegisterNUICallback('scene_delete', function(data)
    TriggerEvent('SSC:Internal:remove_scene', data.id)
end)

RegisterNUICallback('slider_left', function(data)
    TriggerEvent('SSC:Internal:slider_left', data.name)
end)

RegisterNUICallback('slider_right', function(data)
    TriggerEvent('SSC:Internal:slider_right', data.name)
end)

RegisterNUICallback('search_entity', function()
    local keep = true
    local proceed = true
    local fCoords = vector3(0.0,0.0,0.0)
    local entity = 0
    local entType = 1
    SendNUIMessage({
        type = 'information',
        data = {
            title = 'New Entity',
            options = {
                {
                    text = 'Accept Entity: [ENTER]',
                    type = 'text'
                },
                {
                    text = 'Cancel: [BACKSPACE]',
                    type = 'text'
                }
            }
        }
    })
    local camera = CreateCamera(nil, {
        destructor = function(camera)
            keep = false
            proceed = false
            SetEntityDrawOutline(entity, false)
            ResetEntityAlpha(entity)
        end,
        accept = function(camera)
            keep = false
        end,
        onupdate = function(camera)
            local hit,coords,fEntity = RaycastGameplayCamera(1000.0, camera)
            if hit then
                fCoords = coords
                if entity~=fEntity and not C_Entities[fEntity] and DoesEntityExist(fEntity) then
                    if entity~=0 then
                        SetEntityDrawOutline(entity, false)
                        ResetEntityAlpha(entity)
                    end
                    entType = GetEntityType(entity)
                    entity = fEntity
                    if entType == 1 then
                        SetEntityAlpha(entity, 200, true)
                    elseif entType > 1 then
                        SetEntityDrawOutline(entity, true)
                        SetEntityDrawOutlineColor(255,0,0,100)
                    end
                end
            end
        end
    })
    while keep do
        Wait(10)
        local t = GetEntityType(entity)
        if entity == 0 or t==0 then
            DrawSphere(fCoords.x, fCoords.y, fCoords.z, 0.05, 255, 0, 0, 1.0)
        else
            if t == 1 then
                SetEntityAlpha(entity, 200, true)
            elseif t > 1 then
                SetEntityDrawOutline(entity, true)
                SetEntityDrawOutlineColor(255,0,0,100)
            end
        end
    end
    SendNUIMessage({
        type = 'd_information'
    })
    if not proceed then
        return
    end
    SetEntityDrawOutline(entity, false)
    ResetEntityAlpha(entity)
    RegisterEntity(entity, C_Scene)
    TriggerEvent('SSC:Internal:new_entity', entity)
    SendNUIMessage({
        type = 'new_entity',
        _type = entType,
        entity = C_Entities[entity].data.id
    })
    local rot = GetEntityRotation(entity)
    SendNUIMessage({
        type = 'update_entity',
        data = {
            entity = C_Entities[entity].data.id,
            coords = tostring(RoundNumber(fCoords.x,4))..","..tostring(RoundNumber(fCoords.y,4))..","..tostring(RoundNumber(fCoords.z,4)),
            rot = tostring(RoundNumber(rot.x,4))..","..tostring(RoundNumber(rot.y,4))..","..tostring(RoundNumber(rot.z,4)),
            mission = C_Entities[entity].data.mission,
            network = C_Entities[entity].data.network
        }
    })
end)

RegisterNUICallback('load_session', function(data)
    ExecuteCommand('loadsession '..data.id)
end)

RegisterNUICallback('remove_session', function(data)
    ExecuteCommand('removesession '..data.id)
end)

RegisterNUICallback('save_session', function()
    ExecuteCommand('savesession')
end)

RegisterNUICallback('unload_session', function()
    ExecuteCommand('unloadsession')
end)

RegisterNUICallback('create_session', function(data)
    ExecuteCommand('createsession '..data.name)
end)

local TempPromise = nil

RegisterNUICallback('get_templates', function(_,cb)
    TempPromise = promise:new()
    TriggerServerEvent('SSC:Server:RetrieveTemplates')
    Citizen.Await(TempPromise)
    cb(TempPromise.value)
end)

RegisterNetEvent('SSC:Client:RetrieveTemplates', function(data)
    if TempPromise then
        TempPromise:resolve(data)
        TempPromise = nil
    end
end)

local SessionPromise = nil

RegisterNUICallback('get_sessions', function(_,cb)
    SessionPromise = promise:new()
    TriggerServerEvent('SSC:Server:RetrieveSessions')
    Citizen.Await(SessionPromise)
    cb(SessionPromise.value)
end)

RegisterNetEvent('SSC:Client:RetrieveSessions', function(data)
    if SessionPromise then
        SessionPromise:resolve(data)
        SessionPromise = nil
    end
end)

RegisterNUICallback('load_template', function(data)
    display(false,false)
    ExecuteCommand('loadtemplate '..data.id)
end)

RegisterNUICallback('create_template', function(data)
    ExecuteCommand('createtemplate '..data.name)
end)

local FilesPromise = nil

RegisterNUICallback('refresh_files', function(_,cb)
    FilesPromise = promise:new()
    TriggerServerEvent('SSC:Server:RetrieveFiles')
    Citizen.Await(FilesPromise)
    cb(FilesPromise.value)
end)

RegisterNetEvent('SSC:Client:RetrieveFiles', function(data)
    if FilesPromise then
        FilesPromise:resolve(data)
        FilesPromise = nil
    end
end)

local AttachedFilesPromise = nil

RegisterNUICallback('refresh_a_files', function(_,cb)
    AttachedFilesPromise = promise:new()
    TriggerServerEvent('SSC:Server:RetrieveAttachedFiles')
    Citizen.Await(AttachedFilesPromise)
    cb(AttachedFilesPromise.value)
end)

RegisterNetEvent('SSC:Client:RetrieveAttachedFiles', function(data)
    if AttachedFilesPromise then
        AttachedFilesPromise:resolve(data)
        AttachedFilesPromise = nil
    end
end)

RegisterNUICallback('attach_file', function(data)
    ExecuteCommand('attachfile '..data.name)
end)

RegisterNUICallback('detach_file', function(data)
    ExecuteCommand('detachfile '..data.name)
end)

RegisterNUICallback('create_static_map', function(data)
    ExecuteCommand('createstaticmap '..data.name)
end)