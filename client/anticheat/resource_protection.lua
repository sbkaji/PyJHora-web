-- Resource Protection Module
-- Protects against resource manipulation and unauthorized modifications

local originalResourceNames = {}
local protectedEvents = {}
local eventCallCount = {}
local lastEventTime = {}

-- Initialize resource protection
CreateThread(function()
    Wait(2000)
    
    if not Config.Protection.AntiCheat.ResourceRenameProtection then
        return
    end
    
    -- Store original resource names
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            originalResourceNames[i] = resourceName
        end
    end
    
    Logger.info("Resource protection initialized", {resourceCount = numResources})
end)

-- Anti Resource Rename Protection
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        
        if not Config.Protection.AntiCheat.ResourceRenameProtection then
            Wait(30000)
            goto continue
        end
        
        local numResources = GetNumResources()
        for i = 0, numResources - 1 do
            local currentName = GetResourceByFindIndex(i)
            local originalName = originalResourceNames[i]
            
            if originalName and currentName and originalName ~= currentName then
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Resource Rename Detected", {
                    originalName = originalName,
                    currentName = currentName,
                    index = i
                })
                TriggerServerEvent('protector:detection:resource_rename', originalName, currentName)
            end
        end
        
        ::continue::
    end
end)

-- Anti Stop Resource Protection
local originalStopResource = StopResource
if originalStopResource then
    StopResource = function(resourceName)
        if Config.Protection.AntiCheat.StopResourceProtection then
            Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Stop Resource Attempt", {
                resourceName = resourceName,
                stackTrace = debug.traceback()
            })
            TriggerServerEvent('protector:detection:stop_resource', resourceName)
            return false
        end
        return originalStopResource(resourceName)
    end
end

-- Anti Trigger Event Protection
local originalTriggerEvent = TriggerEvent
local originalTriggerServerEvent = TriggerServerEvent

if originalTriggerEvent then
    TriggerEvent = function(eventName, ...)
        if Config.Protection.AntiCheat.TriggerEventProtection then
            -- Check if event is blacklisted
            for _, blacklistedEvent in ipairs(Config.Protection.AntiCheat.BlacklistedEvents or {}) do
                if eventName == blacklistedEvent then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blacklisted Event Triggered", {
                        eventName = eventName,
                        args = {...}
                    })
                    TriggerServerEvent('protector:detection:blacklisted_event', eventName, {...})
                    return
                end
            end
            
            -- Rate limiting for events
            local currentTime = GetGameTimer()
            eventCallCount[eventName] = (eventCallCount[eventName] or 0) + 1
            
            if lastEventTime[eventName] and currentTime - lastEventTime[eventName] < 100 then
                if eventCallCount[eventName] > 10 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Event Spam Detected", {
                        eventName = eventName,
                        callCount = eventCallCount[eventName]
                    })
                    TriggerServerEvent('protector:detection:event_spam', eventName, eventCallCount[eventName])
                    return
                end
            else
                eventCallCount[eventName] = 1
            end
            
            lastEventTime[eventName] = currentTime
        end
        
        return originalTriggerEvent(eventName, ...)
    end
end

if originalTriggerServerEvent then
    TriggerServerEvent = function(eventName, ...)
        if Config.Protection.AntiCheat.TriggerEventProtection then
            -- Check if event is blacklisted
            for _, blacklistedEvent in ipairs(Config.Protection.AntiCheat.BlacklistedEvents or {}) do
                if eventName == blacklistedEvent then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blacklisted Server Event Triggered", {
                        eventName = eventName,
                        args = {...}
                    })
                    TriggerServerEvent('protector:detection:blacklisted_server_event', eventName, {...})
                    return
                end
            end
            
            -- Rate limiting for server events
            local currentTime = GetGameTimer()
            local serverEventKey = "server_" .. eventName
            eventCallCount[serverEventKey] = (eventCallCount[serverEventKey] or 0) + 1
            
            if lastEventTime[serverEventKey] and currentTime - lastEventTime[serverEventKey] < 200 then
                if eventCallCount[serverEventKey] > 5 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Server Event Spam Detected", {
                        eventName = eventName,
                        callCount = eventCallCount[serverEventKey]
                    })
                    -- Note: We can't trigger server event here as it would cause recursion
                    return
                end
            else
                eventCallCount[serverEventKey] = 1
            end
            
            lastEventTime[serverEventKey] = currentTime
        end
        
        return originalTriggerServerEvent(eventName, ...)
    end
end

-- Monitor for unauthorized native calls
local dangerousNatives = {
    0x9A83F5F9963775EF, -- NETWORK_OVERRIDE_CLOCK_TIME
    0x1B15C2065C4AEE5, -- NETWORK_OVERRIDE_CLOCK_RATE
    0x27B2C0A6C46C7D5, -- SET_WEATHER_TYPE_NOW_PERSIST
    0x704983DF373B198, -- CLEAR_WEATHER_TYPE_PERSIST
    0x5CA7FB7D6DE49DDB, -- SET_VEHICLE_ENGINE_HEALTH
    0x93A3996368C94158, -- SET_VEHICLE_BODY_HEALTH
}

local originalInvokeNative = Citizen.InvokeNative
if originalInvokeNative then
    Citizen.InvokeNative = function(hash, ...)
        if Config.Protection.AntiCheat.Enabled then
            for _, dangerousNative in ipairs(dangerousNatives) do
                if hash == dangerousNative then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Dangerous Native Called", {
                        nativeHash = string.format("0x%X", hash),
                        args = {...}
                    })
                    TriggerServerEvent('protector:detection:dangerous_native', hash, {...})
                    return nil
                end
            end
        end
        
        return originalInvokeNative(hash, ...)
    end
end

-- Reset event counters periodically
CreateThread(function()
    while true do
        Wait(30000) -- Reset every 30 seconds
        
        for eventName, count in pairs(eventCallCount) do
            eventCallCount[eventName] = math.max(0, count - 5)
        end
    end
end)

-- Export protection status
function GetResourceProtectionStatus()
    return {
        resourceRenameProtection = Config.Protection.AntiCheat.ResourceRenameProtection,
        stopResourceProtection = Config.Protection.AntiCheat.StopResourceProtection,
        triggerEventProtection = Config.Protection.AntiCheat.TriggerEventProtection,
        eventCounts = eventCallCount,
        protectedResources = #originalResourceNames
    }
end