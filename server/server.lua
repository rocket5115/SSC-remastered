local buckets = {}
if GConfig.Enable then
    Current_Sessions = {}

    RegisterNetEvent('SSC:Server:CreateSession', function(id,_src,ov)
        local src = (tonumber(source)<=0 and _src or source)
        if not IsAllowed(src)then return end
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
            SaveFile('_SSC_Session_'..id,{id = id, scenes = Current_Sessions[uid].scenes},src)
            TriggerClientEvent('SSC:Client:LoadSession', src, Current_Sessions[uid])
        elseif Current_Sessions[uid].id == id then
            TriggerClientEvent('SSC:Client:UnloadSession', src, Current_Sessions[uid])
            Current_Sessions[uid]=nil
        end
    end)

    RegisterNetEvent('SSC:Server:LoadSession', function(id)
        local src = source
        if not IsAllowed(src)then return end
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
        local src = (source<=0 and _src or source)
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            TriggerClientEvent('SSC:Client:UnloadSession', src, Current_Sessions[uid])
            Current_Sessions[uid]=nil
        else
            SendError(src, 'Session not loaded. Any Changes will not be saved!')
        end
    end)

    RegisterNetEvent('SSC:Server:SaveSession', function(_src, data, id)
        local src = (source<=0 and _src or source)
        if not IsAllowed(src)then return end
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
            SendError(src, 'Session not loaded. Any Changes will not be saved!')
        end
    end)

    RegisterNetEvent('SSC:Server:add_entity', function(data)
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            table.insert(Current_Sessions[uid].scenes[data.scene].Entities, data)
            TriggerEvent('SSC:Server:SaveSession', src)
        else
            SendError(src, 'Session not loaded. Any Changes will not be saved!')
        end
    end)

    RegisterNetEvent('SSC:Server:remove_entity', function(data)
        local src = source
        if not IsAllowed(src)then return end
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
        if not IsAllowed(src)then return end
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
        if not IsAllowed(src)then return end
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
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        if Current_Sessions[uid] then
            for k,v in ipairs(Current_Sessions[uid].scenes[data.from].Entities)do
                if v.id==data.name then
                    v.scene=data.to
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

    RegisterNetEvent('SSC:Server:save_entity', function(data)
        local src = source
        if not IsAllowed(src)then return end
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
            SendError(src, 'Session not loaded. Any Changes will not be saved!')
        end
    end)

    RegisterNetEvent('SSC:Server:change_entity_name', function(o_name, n_name, scene)
        local src = source
        if not IsAllowed(src)then return end
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
            SendError(src, 'Session not loaded. Any Changes will not be saved!')
        end
    end)

    RegisterNetEvent('SSC:Server:create_template', function(name, data)
        local src = source
        if not IsAllowed(src)then return end
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
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        if not Current_Sessions[uid] then
            SendError(src, 'Session not loaded. Template cannot be loaded.')
        else
            local temp = RetrieveFile('_SSC_Template_'..name, src)
            if temp then
                if #temp == 0 then
                    return
                else
                    TriggerClientEvent('SSC:Client:load_template', src, temp)
                end
            end
        end
    end)

    RegisterNetEvent('SSC:Server:RetrieveTemplates', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        for name in pairs(Files) do
            local started,ended = name:find(uid..'_SSC_Template_')
            if started and ended then
                retval[#retval+1] = name:sub(ended+1, name:len())
            end
        end
        TriggerClientEvent('SSC:Client:RetrieveTemplates', src, retval)
    end)

    RegisterNetEvent('SSC:Server:RetrieveSessions', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        for name in pairs(Files) do
            local started,ended = name:find(uid..'_SSC_Session_')
            if started and ended then
                retval[#retval+1] = name:sub(ended+1, name:len())
            end
        end
        TriggerClientEvent('SSC:Client:RetrieveSessions', src, retval)
    end)

    RegisterNetEvent('SSC:Server:RetrieveFiles', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        for k in pairs(Sessions)do
            retval[#retval+1]=k
        end
        TriggerClientEvent('SSC:Client:RetrieveFiles', src, retval)
    end)

    RegisterNetEvent('SSC:Server:RetrieveAttachedFiles', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        if Current_Sessions[uid] then
            for k in pairs(Current_Sessions[uid].scenes['0'].Files)do
                retval[#retval+1]=k
            end
        end
        TriggerClientEvent('SSC:Client:RetrieveAttachedFiles', src, retval)
    end)

    RegisterNetEvent('SSC:Server:RetrieveLoadedStaticMaps', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        if IsAllowed(src) then
            for k,v in pairs(buckets)do
                retval[#retval+1]={
                    name = k:sub(1,k:len()-tostring(v.bucket):len()),
                    bucket = v.bucket
                }
            end
        end
        TriggerClientEvent('SSC:Client:RetrieveLoadedStaticMaps', src, retval)
    end)

    RegisterNetEvent('SSC:Server:RetrieveStaticMaps', function()
        local src = source
        if not IsAllowed(src)then return end
        local uid = GetUniqueId(src)
        local retval = {}
        if IsAllowed(src) then
            for k,v in pairs(Files)do
                if(k:sub(1,12)=='_SSC_Static_')then
                    retval[#retval+1]={
                        name = k:sub(13,k:len()),
                        mine = (RetrieveFile(k)or {}).lasteditor==uid
                    }
                end
            end
        end
        TriggerClientEvent('SSC:Client:RetrieveStaticMaps', src, retval)
    end)

    RegisterCommand('attachfile', function(source,args)
        if not IsAllowed(source)then return end
        local src = source
        if not IsAllowed(src)then return end
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
        if not IsAllowed(source)then return end
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
        if not IsAllowed(source)then return end
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
                SendMessage(src, 'Success', 'Static File created and overwritten. You can use it with Config.StaticScenes.')
            else
                SaveFile('_SSC_Static_'..args[1], RetrieveStaticFileData(src))
                SendMessage(src, 'Success', 'Static File created. You can use it with Config.StaticScenes.')
            end
        else
            SendError(src, 'Session must be loaded in order to create static file')
        end
    end)

    RegisterCommand('removestaticmap', function(source, args)
        if not IsAllowed(source)then return end
        local src = source
        local uid = GetUniqueId(src)
        if IsAllowed(src, true) then
            local file = RetrieveFile('_SSC_Static_'..args[1])
            if not file then
                SendError(src, 'Static File: '..args[1]..'; does not exist')
            elseif file.lasteditor == uid or src<=0 then
                if RemoveFile('_SSC_Static_'..args[1]) then
                    if src>0 then
                        SendMessage(src, 'Success', 'Static File: '..args[1]..'; removed. It is now no more available.', 'orange')
                    else
                        print('Static File: '..args[1]..'; removed successfully')
                    end
                else
                    if src>0 then
                        SendError(src, 'Static File: '..args[1]..'; does not exist')
                    else
                        print('Static File: '..args[1]..'; does not exist')
                    end
                end
            end
        end
    end)

    RegisterCommand('removesession', function(source, args)
        if not IsAllowed(source)then return end
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] then
            SendError(src, 'You must provide session id!')
            return
        end
        if Current_Sessions[uid] then
            if Current_Sessions[uid].id==args[1]then
                SendError(src, 'You cannot remove loaded session!')
                return
            end
        end
        if RetrieveFile('_SSC_Session_'..args[1],src) then
            local res = RemoveFile('_SSC_Session_'..args[1],src)
            if res==true then
                SendMessage(src,'Success', 'Session: '..args[1]..' removed', 'orange')
            else
                SendError(src, 'Error: '..res)
            end
        else
            SendError(src, 'Session does not exist!')
        end
    end)

    RegisterCommand('removetemplate', function(source, args)
        if not IsAllowed(source)then return end
        local src = source
        local uid = GetUniqueId(src)
        if not args[1] then
            SendError(src, 'You must provide template id!')
            return
        end
        if RetrieveFile('_SSC_Template_'..args[1],src) then
            local res = RemoveFile('_SSC_Template_'..args[1],src)
            if res then
                SendMessage(src,'Success', 'Template: '..args[1]..' removed', 'orange')
            else
                SendError(src, 'Error: '..res)
            end
        else
            SendError(src, 'Session does not exist!')
        end
    end)

    RegisterCommand('refreshconfig', function(source, args)
        if not IsAllowed(source,true)then return end
        EnsureConfigFile()
    end)
end

CreateThread(function()
    Wait(0)
    for k,v in ipairs(Config.StaticScenes)do
        local file = RetrieveFile('_SSC_Static_'..v.id)
        if file then
            local ents = LoadSceneBucket(file.entities, v.bucket)
            SetSceneBucket(ents, v.bucket or 0)
            buckets[v.id..(v.bucket or 0)] = {ents = ents, bucket=v.bucket or 0, lasteditor=file.lasteditor}
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
    if not IsAllowed(source, true, true) then SendError(source, 'You are not allowed to do that') return end
    if not args[1] then SendError(source, 'Invalid Static Scene Id') return end
    if buckets[args[1]..(args[2] or 0)] then
        UnloadSceneBucket(buckets[args[1]..(args[2] or 0)].ents)
        local file = RetrieveFile('_SSC_Static_'..args[1])
        if not file then SendError(source, 'Static Scene not found') return end
        local ents = LoadSceneBucket(file.entities, tonumber(args[2]or 0) or 0)
        SetSceneBucket(ents, tonumber(args[2]or 0) or 0)
        for k,v in pairs(file.Files)do
            if Sessions[k] then
                StartSession(k, ents)
            end
        end
        buckets[args[1]..(args[2] or 0)].bucket = tonumber(args[2]or 0)
        buckets[args[1]..(args[2] or 0)].lasteditor=file.lasteditor
    else
        local file = RetrieveFile('_SSC_Static_'..args[1])
        if not file then SendError(source, 'Static Scene not found') return end
        local ents = LoadSceneBucket(file.entities, tonumber(args[2]or 0) or 0)
        SetSceneBucket(ents, tonumber(args[2]or 0) or 0)
        for k,v in pairs(file.Files)do
            if Sessions[k] then
                StartSession(k, ents)
            end
        end
        buckets[args[1]..(args[2] or 0)] = {
            ents = ents,
            bucket = tonumber(args[2]or 0) or 0,
            lasteditor = file.lasteditor
        }
    end
end)

RegisterCommand('unloadscenebucket', function(source,args)
    if not IsAllowed(source, true, true) then SendError(source, 'You are not allowed to do that') return end
    if not args[1] then SendError(source, 'Invalid Static Scene Id') return end
    if buckets[args[1]..(args[2] or 0)] then
        UnloadSceneBucket(buckets[args[1]..(args[2] or 0)].ents, tonumber(args[2]or 0) or 0)
        buckets[args[1]..(args[2] or 0)]=nil
    else
        SendError(source, 'Invalid Static Scene Id or invalid Bucket or already unloaded')
    end
end)

RegisterCommand('unloadallscenebuckets', function(source,args)
    if not IsAllowed(source, true, true) then SendError(source, 'You are not allowed to do that') return end
    if not args[1] then SendError(source, 'Invalid Static Scene Id') return end
    for k,v in pairs(buckets)do
        if k:sub(1,k:len()-tostring(v.bucket):len())==args[1]then
            UnloadSceneBucket(v.ents, v.bucket)
            buckets[k]=nil
        end
    end
end)

RegisterCommand('setbucket', function(source, args)
    SetPlayerRoutingBucket(source, tonumber(args[1]or 0))
end)

RegisterNetEvent('SSC:Server:CheckIfAdmin', function()
    local src = source
    TriggerClientEvent('SSC:Client:IsAdmin', src, IsAllowed(src), IsAllowed(src, false, true))
end)