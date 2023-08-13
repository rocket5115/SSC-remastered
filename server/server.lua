if GConfig.Enable then
    Current_Sessions = {}
    Current_Templates = {}

    RegisterNetEvent('SSC:Server:CreateSession', function(id,_src,ov)
        local src = _src or source
        local uid = GetUniqueId(src)
        if not Current_Sessions[uid] then
            local data = RetrieveFile('_SSC_Session_'..id, src)or {}
            Current_Sessions[uid] =  {
                id = id,
                scenes = (not ov and data.scenes) or {
                    ['0'] = {
                        Entities = {},
                        Files = {} -- Scene '0' is permanent, therefore it holds all info
                    }
                }
            }
            Current_Templates[src]=false
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
            Current_Templates[src]=false
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:SaveSession', function(_src, data, id)
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
            SaveFile('_SSC_Session_'..(id and id or Current_Sessions[uid].id),Current_Sessions[uid],src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:add_entity', function(data)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            table.insert(Current_Sessions[uid].scenes[data.scene].Entities, data)
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:remove_entity', function(data)
        print(data.id,source)
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
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:add_scene', function(name)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            Current_Sessions[uid].scenes[name]=Current_Sessions[uid].scenes[name]or{Entities={}}
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:remove_scene', function(name)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            Current_Sessions[uid].scenes[name]=nil
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:change_entity_scene', function(data)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            for k,v in ipairs(Current_Sessions[uid].scenes[data.from].Entities)do
                if v.id==data.entity then
                    v.scene=data.to
                    table.insert(Current_Sessions[uid].scenes[data.to].Entities, v)
                    table.remove(Current_Sessions[uid].scenes[data.from].Entities, k)
                    break
                end
            end
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:save_entity', function(data)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            for k,v in ipairs(Current_Sessions[uid].scenes[data.scene].Entities)do
                if v.id==data.id then
                    Current_Sessions[uid].scenes[data.scene].Entities[k]=data
                    break
                end
            end
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:change_entity_name', function(o_name, n_name, scene)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            for k,v in ipairs(Current_Sessions[uid].scenes[scene].Entities)do
                if v.id==o_name then
                    Current_Sessions[uid].scenes[scene].Entities[k].id = n_name
                    break
                end
            end
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            if not Current_Templates[src] then SendError(src, 'Session not loaded. Any Changes will not be saved!') end
        end
    end)

    RegisterNetEvent('SSC:Server:create_template', function(name, data)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            local temp = RetrieveFile('_SSC_Template_'..name, src)
            if temp then
                SaveFile('_SSC_Template_'..name, data, src)
                SendMessage(src, 'Warning', 'Template overwritten', 'orange')
            else
                SaveFile('_SSC_Template_'..name, data, src)
                SendMessage(src, 'Success', 'Template created', 'green')
            end
        else
            SendError(src, 'Session not loaded. Template cannot be created.')
        end
    end)

    RegisterNetEvent('SSC:Server:load_template', function(name)
        local src = source
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] and Current_Sessions[uid].id~='TEMP' then
            SendError(src, 'Session is currently loaded, please unload before proceeding.')
        else
            if not Current_Sessions[uid] then
                TriggerEvent('SSC:Server:CreateSession', 'TEMP', src, true) -- id, source, overwrite file
            end
            local temp = RetrieveFile('_SSC_Template_'..name, src)
            if temp then
                if #temp == 0 then
                    return
                else
                    Current_Templates[src]=true
                    TriggerClientEvent('SSC:Client:load_template', src, temp)
                end
            end
        end
    end)

    RegisterCommand('savetemplatescene', function(source,args)
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] or args[1]=="" then
            SendError(src, 'Invalid Name for session')
            return
        end
        if Current_Sessions[uid] and Current_Sessions[uid].id=='TEMP' then
            TriggerEvent('SSC:Server:SaveSession', src, nil, args[1])
            SendMessage(src, 'Success', 'Saved Template File as Session File, ID: '..args[1], 'lightgreen')
        else
            SendError(src, 'Current Session MUST be `TEMP` or created by template')
        end
    end)

    RegisterCommand('attachfile', function(source,args)
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] then
            SendError(src, 'You must provide file name!')
            return
        end
        if Current_Sessions[uid] then
            if not Files[args[1]] then
                local data = Sessions[args[1]]or RetrieveAttachment(args[1])
                if not data then
                    SendError(src, 'File does not exist!')
                    return
                else
                    Current_Sessions[uid].scenes['0'].Files[args[1]] = true
                    SendMessage(src, 'Warning', 'Attachment File Attached and Loaded directly from code', 'orange')
                    TriggerEvent('SSC:Server:SaveSession', src)
                    load(type(data)=="string"and data or "")()
                end
            elseif not Current_Sessions[uid].scenes['0'].Files[args[1]] then
                Current_Sessions[uid].scenes['0'].Files[args[1]] = true
                TriggerEvent('SSC:Server:SaveSession', src)
                SendMessage(src, 'Success', 'Attachment File Attached to current session', 'green')
            else
                SendError(src, 'File already attached!')
            end
        else
            SendError(src, 'Session must be loaded before attaching any files!')
        end
    end)

    RegisterCommand('detachfile', function(source,args)
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] then
            SendError(src, 'You must provide file name!')
            return
        end
        if Current_Sessions[uid] then
            if not Current_Sessions[uid].scenes['0'].Files[args[1]] then
                SendError(src, 'File already detached')
            elseif Current_Sessions[uid].scenes['0'].Files[args[1]] then
                Current_Sessions[uid].scenes['0'].Files[args[1]] = nil
                TriggerEvent('SSC:Server:SaveSession', src)
                SendMessage(src, 'Success', 'Attachment File Detached from current session', 'green')
            end
        else
            SendError(src, 'Session must be loaded to detach any files')
        end
    end)

    RegisterCommand('createstaticmap', function(source, args)
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] then
            SendError(src, 'You must provide static file name!')
            return
        end
        if Current_Sessions[uid] then
            local data = RetrieveFile('_SSC_Static_'..args[1])
            if data then
                if data.lasteditor~="" and data.lasteditor ~= uid then
                    SendError(src, 'File already exists and it can only be overwritten by it\'s original author!')
                    return
                end
                SaveFile('_SSC_Static_'..args[1], RetrieveStaticFileData(src))
                SendMessage(src, 'Success', 'Static File created. You can use it with Config.StaticScenes.')
            else
                SaveFile('_SSC_Static_'..args[1], RetrieveStaticFileData(src))
                SendMessage(src, 'Success', 'Static File created. You can use it with Config.StaticScenes.')
            end
        else
            SendError(src, 'Session must be loaded in order to create static file')
        end
    end)
end

local buckets = {}

CreateThread(function()
    Wait(0)
    for k,v in ipairs(Config.StaticScenes)do
        local file = RetrieveFile('_SSC_Static_'..v.id)
        if file then
            local ents = LoadSceneBucket(file.entities)
            SetSceneBucket(ents, v.bucket or 0)
            buckets[v.id] = {ents = ents, bucket=v.bucket or 0}
            for k,v in pairs(file.Files)do
                if Sessions[k] then
                    StartSession(k, ents)
                end
            end
        else
            print('Scene: '..v.id..' not found!')
        end
    end
end)

RegisterCommand('loadscenebucket', function(source,args)
    if not IsAllowed(source, true) then SendError(source, 'You are not allowed to do that') return end
    if not args[1] then SendError(source, 'Invalid Static Scene Id') return end
    if buckets[args[1]] then
        UnloadSceneBucket(buckets[args[1]].ents)
        local file = RetrieveFile('_SSC_Static_'..args[1])
        if not file then SendError(source, 'Static Scene not found') return end
        local ents = LoadSceneBucket(file.entities)
        SetSceneBucket(ents, tonumber(args[2]or 0) or 0)
        for k,v in pairs(file.Files)do
            if Sessions[k] then
                StartSession(k, ents)
            end
        end
        buckets[args[1]].bucket = tonumber(args[2]or 0)
    else
        local file = RetrieveFile('_SSC_Static_'..args[1])
        if not file then SendError(source, 'Static Scene not found') return end
        local ents = LoadSceneBucket(file.entities)
        SetSceneBucket(ents, tonumber(args[2]or 0) or 0)
        for k,v in pairs(file.Files)do
            if Sessions[k] then
                StartSession(k, ents)
            end
        end
        buckets[args[1]] = {
            ents = ents,
            bucket = tonumber(args[2]or 0) or 0
        }
    end
end)

RegisterCommand('unloadscenebucket', function(source,args)
    if not IsAllowed(source, true) then SendError(source, 'You are not allowed to do that') return end
    if not args[1] then SendError(source, 'Invalid Static Scene Id') return end
    if buckets[args[1]] then
        UnloadSceneBucket(buckets[args[1]].ents)
        buckets[args[1]]=nil
    else
        SendError(source, 'Invalid Static Scene Id or already unloaded')
    end
end)