-- Entity Detection Module
-- Detects spawned entities, particle effects, and other suspicious activities

local spawnedEntities = {}
local particleEffects = {}
local lastEntityCheck = 0

-- Initialize entity detection
CreateThread(function()
    Wait(3000)
    
    if Config.Protection.PlayerProtection.AntiSpawnEntity then
        Logger.info("Entity detection system initialized")
        startEntityMonitoring()
    end
end)

-- Monitor entity spawning
function startEntityMonitoring()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Protection.PlayerProtection.AntiSpawnEntity then
                Wait(5000)
                goto continue
            end
            
            -- Monitor vehicles
            monitorVehicleSpawning()
            
            -- Monitor peds
            monitorPedSpawning()
            
            -- Monitor objects
            monitorObjectSpawning()
            
            -- Monitor particle effects
            if Config.Protection.PlayerProtection.AntiParticleFX then
                monitorParticleEffects()
            end
            
            ::continue::
        end
    end)
end

-- Monitor vehicle spawning
function monitorVehicleSpawning()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local vehicles = getEntitiesInArea(playerCoords, 100.0, 2) -- Type 2 = vehicles
    
    for _, vehicle in ipairs(vehicles) do
        if not spawnedEntities[vehicle] then
            local owner = NetworkGetEntityOwner(vehicle)
            local isPlayerVehicle = owner == PlayerId()
            
            if isPlayerVehicle then
                local vehicleModel = GetEntityModel(vehicle)
                local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
                local spawnTime = GetGameTimer()
                
                spawnedEntities[vehicle] = {
                    type = "vehicle",
                    model = vehicleModel,
                    name = vehicleName,
                    spawnTime = spawnTime,
                    coords = GetEntityCoords(vehicle)
                }
                
                -- Check for rapid spawning
                local recentSpawns = 0
                for _, entity in pairs(spawnedEntities) do
                    if entity.type == "vehicle" and spawnTime - entity.spawnTime < 5000 then
                        recentSpawns = recentSpawns + 1
                    end
                end
                
                if recentSpawns > 3 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Rapid Vehicle Spawning", {
                        vehicle = vehicleName,
                        count = recentSpawns
                    })
                    TriggerServerEvent('protector:detection:player', 'rapid_spawn', {type = 'vehicle', count = recentSpawns})
                end
                
                -- Check for blacklisted vehicles
                for _, blacklisted in ipairs(Config.Protection.WeaponProtection.BlacklistVehicles or {}) do
                    if vehicleName == blacklisted then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blacklisted Vehicle Spawned", {
                            vehicle = blacklisted
                        })
                        TriggerServerEvent('protector:detection:player', 'blacklisted_vehicle', {vehicle = blacklisted})
                        
                        -- Remove the vehicle
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteVehicle(vehicle)
                        break
                    end
                end
            end
        end
    end
end

-- Monitor ped spawning
function monitorPedSpawning()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local peds = getEntitiesInArea(playerCoords, 50.0, 1) -- Type 1 = peds
    
    for _, ped in ipairs(peds) do
        if ped ~= playerPed and not spawnedEntities[ped] then
            local owner = NetworkGetEntityOwner(ped)
            local isPlayerPed = owner == PlayerId()
            
            if isPlayerPed then
                local pedModel = GetEntityModel(ped)
                local spawnTime = GetGameTimer()
                
                spawnedEntities[ped] = {
                    type = "ped",
                    model = pedModel,
                    spawnTime = spawnTime,
                    coords = GetEntityCoords(ped)
                }
                
                -- Check for rapid ped spawning
                local recentSpawns = 0
                for _, entity in pairs(spawnedEntities) do
                    if entity.type == "ped" and spawnTime - entity.spawnTime < 5000 then
                        recentSpawns = recentSpawns + 1
                    end
                end
                
                if recentSpawns > 5 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Rapid Ped Spawning", {
                        model = pedModel,
                        count = recentSpawns
                    })
                    TriggerServerEvent('protector:detection:player', 'rapid_spawn', {type = 'ped', count = recentSpawns})
                end
            end
        end
    end
end

-- Monitor object spawning
function monitorObjectSpawning()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local objects = getEntitiesInArea(playerCoords, 50.0, 3) -- Type 3 = objects
    
    for _, object in ipairs(objects) do
        if not spawnedEntities[object] then
            local owner = NetworkGetEntityOwner(object)
            local isPlayerObject = owner == PlayerId()
            
            if isPlayerObject then
                local objectModel = GetEntityModel(object)
                local spawnTime = GetGameTimer()
                
                spawnedEntities[object] = {
                    type = "object",
                    model = objectModel,
                    spawnTime = spawnTime,
                    coords = GetEntityCoords(object)
                }
                
                -- Check for rapid object spawning
                local recentSpawns = 0
                for _, entity in pairs(spawnedEntities) do
                    if entity.type == "object" and spawnTime - entity.spawnTime < 3000 then
                        recentSpawns = recentSpawns + 1
                    end
                end
                
                if recentSpawns > 10 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Rapid Object Spawning", {
                        model = objectModel,
                        count = recentSpawns
                    })
                    TriggerServerEvent('protector:detection:player', 'rapid_spawn', {type = 'object', count = recentSpawns})
                end
            end
        end
    end
end

-- Monitor particle effects
function monitorParticleEffects()
    -- This is a basic implementation - in practice, detecting particle effects is complex
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check for common particle effect abuse patterns
    local currentTime = GetGameTimer()
    
    -- Look for signs of particle spam (performance impact)
    local frameTime = GetFrameTime()
    if frameTime > 0.05 then -- 20 FPS or lower
        if not particleEffects.lastLagCheck or currentTime - particleEffects.lastLagCheck > 5000 then
            particleEffects.lastLagCheck = currentTime
            particleEffects.lagCount = (particleEffects.lagCount or 0) + 1
            
            if particleEffects.lagCount > 3 then
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Possible Particle FX Abuse", {
                    frameTime = frameTime,
                    lagCount = particleEffects.lagCount
                })
                TriggerServerEvent('protector:detection:player', 'particle_abuse', {frameTime = frameTime})
                particleEffects.lagCount = 0
            end
        end
    end
end

-- Get entities in area
function getEntitiesInArea(coords, radius, entityType)
    local entities = {}
    local handle, entity
    
    if entityType == 1 then -- Peds
        handle, entity = FindFirstPed()
    elseif entityType == 2 then -- Vehicles
        handle, entity = FindFirstVehicle()
    elseif entityType == 3 then -- Objects
        handle, entity = FindFirstObject()
    else
        return entities
    end
    
    local success = true
    while success do
        local entityCoords = GetEntityCoords(entity)
        local distance = #(coords - entityCoords)
        
        if distance <= radius then
            table.insert(entities, entity)
        end
        
        if entityType == 1 then
            success, entity = FindNextPed(handle)
        elseif entityType == 2 then
            success, entity = FindNextVehicle(handle)
        elseif entityType == 3 then
            success, entity = FindNextObject(handle)
        end
    end
    
    if entityType == 1 then
        EndFindPed(handle)
    elseif entityType == 2 then
        EndFindVehicle(handle)
    elseif entityType == 3 then
        EndFindObject(handle)
    end
    
    return entities
end

-- Clean up old entity data
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        local currentTime = GetGameTimer()
        local cleanupThreshold = 60000 -- 1 minute
        
        for entity, data in pairs(spawnedEntities) do
            if not DoesEntityExist(entity) or currentTime - data.spawnTime > cleanupThreshold then
                spawnedEntities[entity] = nil
            end
        end
    end
end)

-- Export functions
exports('getSpawnedEntities', function() return spawnedEntities end)
exports('getEntitySpawnCount', function(entityType, timeWindow)
    local count = 0
    local currentTime = GetGameTimer()
    timeWindow = timeWindow or 10000 -- Default 10 seconds
    
    for _, data in pairs(spawnedEntities) do
        if data.type == entityType and currentTime - data.spawnTime < timeWindow then
            count = count + 1
        end
    end
    
    return count
end)