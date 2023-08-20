Sessions['main'] = EnsureSession('main')
Sessions['main'].listener['ped'] = function(entity) -- is called after every ped is created
    FreezeEntityPosition(entity, true)
end

Sessions['main'].listener['vehicle'] = function(entity) -- same as peds, but vehs
    FreezeEntityPosition(entity, true)
end

Sessions['main'].listener['object'] = function(entity) -- same as previous, but objs
    FreezeEntityPosition(entity, true)
end

Sessions['main'].listener['zentorno'] = function(entity)
    FreezeEntityPosition(entity, false)
end