Files = {}
local files = {}
local resourceName = GetCurrentResourceName()
local uids = {}

function EnsureConfigFile()
    local config = LoadResourceFile(resourceName, 'data/files.json')
    if config then
        Files = json.decode(config)
    else
        SaveResourceFile(resourceName, 'data/files.json', '[]', -1)
    end
end
EnsureConfigFile()

function GetUniqueId(src)
    if not src or src<=0 then return "" end
    if uids[src] then return uids[src] end
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find('license:') then
            local license = v:gsub('license:',''):sub(1,10)
            uids[src] = license
            return license
        end
    end
    return ""
end

function SaveFile(name, data, src)
    name = GetUniqueId(src)..name
    files[name] = data
    Files[name] = true
    SaveResourceFile(resourceName, 'data/'..name..'.json', type(data)=='string'and data or json.encode(data or ""), -1)
    SaveResourceFile(resourceName, 'data/files.json', json.encode(Files), -1)
end

function RetrieveFile(name, src)
    name = GetUniqueId(src)..name
    local data = files[name]or LoadResourceFile(resourceName, 'data/'..name..'.json')
    if data and type(data)=='string'then Files[name]=true data=json.decode(data)end
    return data
end

function RetrieveAttachment(name)
    local data = files[name]or LoadResourceFile(resourceName, 'attachments/'..name..'.lua')
    if data and type(data)=='string'then Files[name]=true end
    return data
end

function GetFileId(name)
    local _,e = name:find('_SSC_Session_')
    return name:sub(e+1, name:find('.json')-1)or""
end

function SendError(src,message)
    TriggerClientEvent('SSC:Client:Notification', src, {
        title = 'error',
        message = message,
        color = 'red',
        time = 4000
    })
end

function SendMessage(src, title, message, color, time)
    TriggerClientEvent('SSC:Client:Notification', src, {
        title = title or 'info',
        message = message,
        color = color or 'red',
        time = time or 4000
    })
end

function RetrieveStaticFileData(src)
    uid = GetUniqueId(src)
    if not Current_Sessions[uid] then return {}end
    local retval = {
        lasteditor = uid,
        Files = Current_Sessions[uid].scenes["0"].Files,
        entities = {}
    }
    for _,data in pairs(Current_Sessions[uid].scenes) do
        for k,v in pairs(data.Entities) do
            table.insert(retval.entities, {
                type = v.type,
                coords = v.coords,
                rotation = v.rotation,
                model = v.model,
                id = v.id
            })
        end
    end
    return retval
end

local function CreateBucketPed(x,y,z,h,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = CreatePed(1,model,x,y,z,h,true,false)
    return ent
end

local function CreateBucketVehicle(x,y,z,h,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = Citizen.InvokeNative(`CREATE_AUTOMOBILE`, `blista`, x,y,z,h)
    return ent
end

local function CreateBucketObject(x,y,z,model)
    model = (type(model)=='number'and model or GetHashKey(model))
    local ent = CreateObjectNoOffset(model, x,y,z, true, false, false)
    return ent
end

Citizen.CreatePed = CreateBucketPed
Citizen.CreateVehicle = CreateBucketVehicle
Citizen.CreateObject = CreateBucketObject

function LoadSceneBucket(data)
    local objs,vehs,peds = GetAllObjects(),GetAllVehicles(),GetAllPeds()
    for k,v in pairs(data)do
        if v.type==1 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#peds do
                if v.model==GetEntityModel(peds[i]) and #(vec-GetEntityCoords(peds[i]))<10.0 then
                    DeleteEntity(peds[i])
                end
            end
        elseif v.type==2 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#vehs do
                if v.model==GetEntityModel(vehs[i]) and #(vec-GetEntityCoords(vehs[i]))<10.0 then
                    DeleteEntity(vehs[i])
                end
            end
        elseif v.type==3 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#objs do
                if v.model==GetEntityModel(objs[i]) and #(vec-GetEntityCoords(objs[i]))<10.0 then
                    DeleteEntity(objs[i])
                end
            end
        end
    end
    for k,v in pairs(data)do
        if v.type==1 then
            local ped = Citizen.CreatePed(v.coords.x, v.coords.y, v.coords.z, v.rotation.z, v.model)
            SetEntityCoords(ped,v.coords.x, v.coords.y, v.coords.z, false, false, false)
            v.entity = ped
        elseif v.type==2 then
            local veh = Citizen.CreateVehicle(v.coords.x, v.coords.y, v.coords.z, v.rotation.z, v.model)
            SetEntityCoords(veh,v.coords.x, v.coords.y, v.coords.z, false, false, false)
            v.entity = veh
        elseif v.type==3 then
            local obj = Citizen.CreateObject(v.coords.x, v.coords.y, v.coords.z, v.model)
            SetEntityRotation(obj,v.rotation.x,v.rotation.y,v.rotation.z,false,true)
            v.entity = obj
        end
    end
    return data
end

function UnloadSceneBucket(data)
    local objs,vehs,peds = GetAllObjects(),GetAllVehicles(),GetAllPeds()
    for k,v in pairs(data)do
        if v.type==1 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#peds do
                if v.model==GetEntityModel(peds[i]) and #(vec-GetEntityCoords(peds[i]))<10.0 then
                    DeleteEntity(peds[i])
                end
            end
        elseif v.type==2 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#vehs do
                if v.model==GetEntityModel(vehs[i]) and #(vec-GetEntityCoords(vehs[i]))<10.0 then
                    DeleteEntity(vehs[i])
                end
            end
        elseif v.type==3 then
            local vec = vector3(v.coords.x,v.coords.y,v.coords.z)
            for i=1,#objs do
                if v.model==GetEntityModel(objs[i]) and #(vec-GetEntityCoords(objs[i]))<10.0 then
                    DeleteEntity(objs[i])
                end
            end
        end
    end
end

function SetSceneBucket(ents, id)
    id = tonumber(id)
    for k,v in pairs(ents)do
        if DoesEntityExist(v.entity) then
            SetEntityRoutingBucket(v.entity,id)
        end
    end
end

function IsAllowed(src, allow0)
    if src<=0 and allow0 then return true end
    if src<=0 then return false end
    for k,v in ipairs(GetPlayerIdentifiers(src))do
        for i=1,#Config.Admins do
            if v:match(Config.Admins[i]) then return true end
        end
    end
    return false
end