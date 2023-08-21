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

Sessions['main'].listener['car'] = function(entity)
    FreezeEntityPosition(entity, false)
end

--Classes, featured in SSC 1.2.0+
--[[Sessions['main'].listener['#test'] = function(entity)
    FreezeEntityPosition(entity, false)
    print(entity, 'test')
end

Sessions['main'].listener['#test2'] = function(entity)
    print(entity, 'test2')
end]]