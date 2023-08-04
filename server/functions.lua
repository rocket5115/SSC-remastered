Files = {}
local files = {}
local resourceName = GetCurrentResourceName()

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
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find('license:') then
            return v:gsub('license:',''):sub(1,10)
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

function SendError(src,message)
    TriggerClientEvent('SSC:Client:Notification', src, {
        title = 'error',
        message = message,
        color = 'red',
        time = 4000
    })
end