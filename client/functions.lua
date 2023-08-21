--[[
    Misc
]]

local sin,cos,abs,pi = math.sin,math.cos,math.abs,math.pi
local hp = (pi/180)

function RaycastGameplayCamera(distance,camera)
    local rotation = camera and GetCamRot(camera) or GetGameplayCamRot()
    local cameraCoord = camera and GetCamCoord(camera) or GetGameplayCamCoord()
    local x,z = hp * rotation.x, hp * rotation.z
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, (cameraCoord.x + (-sin(z) * abs(cos(x))) * distance), (cameraCoord.y + (cos(z) * abs(cos(x))) * distance), (cameraCoord.z + sin(x) * distance), -1, -1, 1))
    return b, c, e
end

function RoundNumber(number, decimal)
    local power = 10 ^ decimal
    return math.floor(number * power + 0.5) / power
end

--[[
    Objects/Peds/Vehicles
]]--

function PrepareModel(model,err)
    return(((type(model)=='string'and model~='')and GetHashKey(model)or type(model)=='number'and model)or err)
end

function RequestModelSync(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return true
end

function CreateLocalPed(x,y,z,h,model,network,mission,options)
    if network then network = true else network = false end
    model = PrepareModel(model,`a_m_m_mexlabor_01`)
    RequestModelSync(model)
    local entity = CreatePed(1,model,x,y,z,h,network,mission)
    options = options or{}
    options.mission = mission
    RegisterEntity(entity, C_Scene, options)
    return entity
end

function CreateLocalVehicle(x,y,z,h,model,network,mission,options)
    if network then network = true else network = false end
    model = PrepareModel(model,`blista`)
    RequestModelSync(model)
    local entity = CreateVehicle(model,x,y,z,h,network,mission)
    options = options or{}
    options.mission = mission
    RegisterEntity(entity, C_Scene, options)
    return entity
end

function CreateLocalObject(x,y,z,model,network,mission,door,options)
    if network then network = true else network = false end
    model = PrepareModel(model,`prop_weed_block_01`)
    RequestModelSync(model)
    local entity = CreateObject(model,x,y,z,network,mission,door)
    options = options or{}
    options.mission = mission
    RegisterEntity(entity, C_Scene, options)
    return entity
end

Citizen.CreatePed = CreateLocalPed
Citizen.CreateVehicle = CreateLocalVehicle
Citizen.CreateObject = CreateLocalObject

function SetPedStill(ped)
    SetPedFleeAttributes(ped, 2)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedDiesWhenInjured(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanPlayAmbientAnims(ped, false)
    TaskStandStill(ped,-1)
end

function RequestNetworkControl(ent)
    if DoesEntityExist(ent) then
        local request = 0
        NetworkRequestControlOfEntity(ent)
        while not NetworkHasControlOfEntity(ent)and request<50 do
            Wait(10)
            NetworkRequestControlOfEntity(ent)
            request=request+1
        end
    end
end

function DeleteNetworkedEntity(entity)
    if NetworkGetEntityIsNetworked(entity) then
        while not NetworkHasControlOfEntity(entity) and DoesEntityExist(entity) do
            NetworkRequestControlOfEntity(entity)
            Wait(1)
        end
        if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
            SetEntityAsMissionEntity(entity, false, true)
            DeleteEntity(entity)
        end
    else
        SetEntityAsMissionEntity(entity,false,false)
        DeleteEntity(entity)
        DeleteObject(entity)
    end
end

function DrawXYZGraphFromEntity(entity)
    local start = GetEntityCoords(entity)
    local x,y,z = start-GetOffsetFromEntityInWorldCoords(entity,2.0,0.0,0.0),start-GetOffsetFromEntityInWorldCoords(entity,0.0,2.0,0.0),start-GetOffsetFromEntityInWorldCoords(entity,0.0,0.0,2.0)
    local x1,x2,y1,y2,z1,z2 = start-x,start+x,start-y,start+y,start-z,start+z
    DrawLine(x1.x,x1.y,x1.z,x2.x,x2.y,x2.z,255,0,0,255)
    DrawLine(y1.x,y1.y,y1.z,y2.x,y2.y,y2.z,0,0,255,255)
    DrawLine(z1.x,z1.y,z1.z,z2.x,z2.y,z2.z,0,255,0,255)
end

function RegisterEntity(entity,scene,options)
    options = options or {}
    scene = options.scene or scene
    mission = options.mission
    if mission==nil then 
        mission = IsEntityAMissionEntity(entity)
    end
    local newEntity = {
        entity=entity, -- def 0 for exports
        data = {
            type = GetEntityType(entity),
            model = GetEntityModel(entity),
            coords = GetEntityCoords(entity),
            rotation = GetEntityRotation(entity)or vector3(0,0,0),
            network = NetworkGetEntityIsNetworked(entity),
            mission = mission,
            door = false,
            id = options.id or tostring(math.random(99999)),
            scene = tostring(scene)or'0',
            classes = options.classes or {}
        }
    }
    table.insert(Entities, newEntity)
    C_Entities[entity] = newEntity
end

function SetEntityScene(entity,scene)
    C_Entities[entity].data.scene = scene or C_Scene
end

function GetEntityFromName(name)
    name = tostring(name)
    for k,v in pairs(C_Entities) do
        if v.data.id==name then return k end
    end
    return 0
end

function RemoveEntity(entity)
    if not C_Entities[entity]then return end
    local tab = C_Entities[entity]
    for i=1,#Entities do
        if Entities[i]==tab then
            table.remove(Entities, i)
            break
        end
    end
    C_Entities[entity] = nil
    DeleteNetworkedEntity(entity)
end

function GetEntitiesInScene(scene)
    local retval = {}
    for k,v in pairs(C_Entities) do
        if v.data.scene == scene then
            retval[#retval+1] = v
        end
    end
    return retval
end

function EnsurePlayerPosition(coords)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    if #(c-coords)<100.0 then
        return true
    end
    FreezeEntityPosition(ped,true)
    SetEntityCoords(ped, coords.x, coords.y, coords.z+1.0, false, false, false, false)
    local requests = 0
    while not HasCollisionLoadedAroundEntity() and requests<100 do
        Wait(100)
        requests=requests+1
    end
    local found,z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
    if found then
        SetEntityCoords(ped, coords.x, coords.y, z, false, false, false, false)
    end
    FreezeEntityPosition(ped,false)
    return true
end

function RetrieveTemplateData()
    local fEntity
    local retval = {}
    for k,v in pairs(C_Entities) do
        if not fEntity then
            fEntity = v.entity
            retval[1] = {
                model = v.data.model,
                type = v.data.type,
                rotation = v.data.rotation,
                network = v.data.network,
                mission = v.data.mission,
                rOffset = 0.0,
                offset = vector3(0.0,0.0,0.0),
                id = v.data.id,
                classes = v.data.classes
            }
        else
            retval[#retval+1] = {
                model = v.data.model,
                type = v.data.type,
                rotation = v.data.rotation,
                network = v.data.network,
                mission = v.data.mission,
                rOffset = v.data.rotation.z - retval[1].rotation.z,
                offset = GetOffsetFromEntityGivenWorldCoords(fEntity, table.unpack(GetEntityCoords(v.entity))),
                id = v.data.id,
                classes = v.data.classes
            }
        end
    end
    return retval
end

function CreateTemplateEntities(data, c)
    local first = data[1]
    local fCoords
    for k,v in ipairs(data) do
        local coords
        if k==1 then
            coords = c
        else
            coords = GetOffsetFromEntityInWorldCoords(data[1].entity, v.offset.x, v.offset.y, v.offset.z)
        end
        if v.type==1 or v.type==2 then
            if v.type == 1 then
                v.entity = CreateLocalPed(coords.x, coords.y, coords.z - 1.0, v.rotation.z, v.model, v.network, v.mission, {id="TE"..math.random(99999)})
            elseif v.type == 2 then
                v.entity = CreateLocalVehicle(coords.x, coords.y, coords.z, v.rotation.z, v.model, v.network, v.mission, {id="TE"..math.random(99999)})
            end
        elseif v.type==3 then
            v.entity = CreateLocalObject(coords.x, coords.y, coords.z, v.model, v.network, v.mission, false, {id="TE"..math.random(99999)})
        end
        data[k].id = C_Entities[v.entity].data.id
        SetEntityRotation(v.entity, v.rotation.x, v.rotation.y, v.rotation.z)
        FreezeEntityPosition(v.entity, true)
    end
    return data
end

function SetTemplatePosition(data, c, r)
    local rot = GetEntityRotation(data[1].entity)
    SetEntityRotation(data[1].entity, rot.x, rot.y, r)
    for k,v in ipairs(data) do
        local coords
        if k==1 then
            coords = c
        else
            coords = GetOffsetFromEntityInWorldCoords(data[1].entity, v.offset.x, v.offset.y, v.offset.z)
        end
        SetEntityCoords(v.entity, (v.type==1 and k~=1) and coords - vector3(0.0,0.0,1.0) or coords)
        SetEntityRotation(v.entity, v.rotation.x, v.rotation.y, r-v.rOffset)
    end
end