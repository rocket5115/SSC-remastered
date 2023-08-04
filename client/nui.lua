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
    local entity = GetEntityFromName(data.name)
    C_Entities[entity].data.scene = data.to
    TriggerEvent('SSC:Internal:entity_move_scene', data)
end)

RegisterNUICallback('update_entity_name', function(data)
    local old,new,id = data.name,data.new,data.scene_id
    local entity = GetEntityFromName(old)
    C_Entities[entity].data.id = new
end)

RegisterNUICallback('update_entity_coord', function(data)
    local entity,coords = GetEntityFromName(data.name),(((data.x and'x')or(data.y and'y'))'z')
    local v = GetEntityCoords(entity)
    v[coords]=data[coords]
    SetEntityCoords(entity,v)
end)

RegisterNUICallback('go_to_entity', function(data)
    local entity = GetEntityFromName(data.name)
    local cam = CreateCamera(GetEntityCoords(entity)+vector3(1.0,1.0,0.0), {
        onupdate = function(camera)
            SetFreecamRotation(table.unpack(GetCamRot(camera)))
        end
    })
    PointCamAtEntity(cam, entity, 0.0, 0.0, 0.0, 1)
    SetFreecamRotation(table.unpack(GetCamRot(cam)))
    display(false,false)
end)

RegisterNUICallback('spawn_entity', function(data)
    display(false,false)
    local type,model,mission,network,door,coords = data.type,data.model,data.mission,data.network,data.door,GetEntityCoords(PlayerPedId())+vector3(1.0,1.0,0.0)
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
    local entity
    if type == 1 then
        entity = CreateLocalPed(fCoords.x, fCoords.y, fCoords.z, heading, model, network, mission)
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
    display(true,false)
end)

RegisterNUICallback('scene_create', function(data)
    TriggerEvent('SSC:Internal:new_scene', data.id)
end)

RegisterNUICallback('scene_delete', function(data)
    TriggerEvent('SSC:Internal:remove_scene', data.id)
end)