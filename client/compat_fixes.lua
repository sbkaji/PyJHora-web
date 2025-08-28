-- Compatibility Fixes for FiveM Server Protector
-- Handles missing functions and client-side limitations

-- Check for missing functions and provide fallbacks
CreateThread(function()
    Wait(1000) -- Wait for game to initialize
    
    -- Check for commonly missing functions and log warnings
    local missingFunctions = {}
    
    if not GetPlayerInvincible then
        table.insert(missingFunctions, "GetPlayerInvincible")
        GetPlayerInvincible = function(playerId)
            return false -- Always return false if function doesn't exist
        end
    end
    
    if not NetworkIsInSpectatorMode then
        table.insert(missingFunctions, "NetworkIsInSpectatorMode")
        NetworkIsInSpectatorMode = function()
            return false
        end
    end
    
    if not GetUsingnightvision then
        table.insert(missingFunctions, "GetUsingnightvision")
        GetUsingnightvision = function()
            return false
        end
    end
    
    if not GetUsingseethrough then
        table.insert(missingFunctions, "GetUsingseethrough")
        GetUsingseethrough = function()
            return false
        end
    end
    
    if not SetNightvision then
        table.insert(missingFunctions, "SetNightvision")
        SetNightvision = function(enabled)
            -- Do nothing if function doesn't exist
        end
    end
    
    if not SetSeethrough then
        table.insert(missingFunctions, "SetSeethrough")
        SetSeethrough = function(enabled)
            -- Do nothing if function doesn't exist
        end
    end
    
    -- Log missing functions
    if #missingFunctions > 0 then
        print(string.format("^3[Protector] Warning: %d functions not available in this FiveM build^7", #missingFunctions))
        print(string.format("^3[Protector] Missing functions: %s^7", table.concat(missingFunctions, ", ")))
        print("^3[Protector] Some protection features may be limited^7")
    end
end)

-- Provide safe wrapper functions for common operations
function SafeGetEntityHealth(entity)
    if entity and DoesEntityExist(entity) then
        return GetEntityHealth(entity)
    end
    return 0
end

function SafeGetEntityCoords(entity)
    if entity and DoesEntityExist(entity) then
        return GetEntityCoords(entity)
    end
    return vector3(0, 0, 0)
end

function SafeGetEntityVelocity(entity)
    if entity and DoesEntityExist(entity) then
        return GetEntityVelocity(entity)
    end
    return vector3(0, 0, 0)
end

-- Enhanced error handling for detection functions
function SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print(string.format("^1[Protector] Error calling function: %s^7", tostring(result)))
        return nil
    end
    return result
end

-- Export safe functions
exports('SafeGetEntityHealth', SafeGetEntityHealth)
exports('SafeGetEntityCoords', SafeGetEntityCoords)
exports('SafeGetEntityVelocity', SafeGetEntityVelocity)
exports('SafeCall', SafeCall)