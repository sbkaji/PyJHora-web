-- FiveM Server Protector - Client Main
-- Coordinates all client-side protection systems

local protectorInitialized = false
local systemStatus = {
    anticheat = false,
    weaponProtection = false,
    playerProtection = false
}

-- Initialize the protection system
CreateThread(function()
    Wait(2000) -- Wait for resource to fully load
    
    if not Config.Protection.Enabled then
        Logger.warning("Protection system is disabled in config")
        return
    end
    
    Logger.info("Initializing FiveM Server Protector client systems...")
    
    -- Initialize core systems based on config
    if Config.Protection.AntiCheat.Enabled then
        systemStatus.anticheat = true
        Logger.info("✓ Anti-cheat system loaded")
    end
    
    if Config.Protection.WeaponProtection.Enabled then
        systemStatus.weaponProtection = true
        Logger.info("✓ Weapon protection system loaded")
    end
    
    if Config.Protection.PlayerProtection.Enabled then
        systemStatus.playerProtection = true
        Logger.info("✓ Player protection system loaded")
    end
    
    protectorInitialized = true
    Logger.info("🛡️ FiveM Server Protector client initialized successfully")
    
    -- Test NUI functionality
    if Config.Protection.AntiCheat.NUIDevToolsDetection then
        CreateThread(function()
            Wait(3000) -- Wait for NUI to fully load
            SendNUIMessage({
                type = "test_connection",
                message = "Initial startup test"
            })
            
            -- Set up NUI debug mode if general debug is enabled
            if Config.Protection.Debug then
                SendNUIMessage({
                    type = "enable_debug"
                })
            end
        end)
    end
    
    -- Send initialization confirmation to server
    TriggerServerEvent('protector:client:initialized', systemStatus)
end)

-- Handle rate limiting from server
RegisterNetEvent('protector:rate_limited')
AddEventHandler('protector:rate_limited', function()
    Logger.warning("Rate limit exceeded - throttling requests")
    
    -- Show notification to player
    if GetResourceState('mythic_notify') == 'started' then
        exports['mythic_notify']:DoHudText('error', 'You are sending too many requests. Please slow down.')
    else
        -- Fallback notification
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~Rate limit exceeded. Please slow down.")
        DrawNotification(false, false)
    end
end)

-- Protection status check
RegisterNetEvent('protector:request_status')
AddEventHandler('protector:request_status', function()
    TriggerServerEvent('protector:client_status', {
        initialized = protectorInitialized,
        systems = systemStatus,
        playerInfo = {
            name = GetPlayerName(PlayerId()),
            serverId = GetPlayerServerId(PlayerId()),
            coords = GetEntityCoords(PlayerPedId())
        }
    })
end)

-- Handle disconnect for violations
RegisterNetEvent('protector:disconnect')
AddEventHandler('protector:disconnect', function(reason)
    Logger.critical(string.format("Disconnected by protector: %s", reason))
end)

-- Heartbeat system to ensure client is responsive
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        if protectorInitialized then
            TriggerServerEvent('protector:heartbeat', {
                timestamp = GetGameTimer(),
                systems = systemStatus,
                health = GetEntityHealth(PlayerPedId())
            })
        end
    end
end)

-- Anti-tamper protection
CreateThread(function()
    while true do
        Wait(5000)
        
        if not protectorInitialized then
            goto continue
        end
        
        -- Check if critical functions are still intact
        if not TriggerServerEvent or not RegisterNetEvent then
            Logger.critical("Critical client functions have been tampered with")
            TriggerEvent('protector:tamper_detected', 'critical_functions')
        end
        
        -- Check resource integrity
        local resourceName = GetCurrentResourceName()
        if not resourceName or resourceName == "" then
            Logger.critical("Resource name tampering detected")
            TriggerEvent('protector:tamper_detected', 'resource_name')
        end
        
        ::continue::
    end
end)

-- Handle tamper detection
RegisterNetEvent('protector:tamper_detected')
AddEventHandler('protector:tamper_detected', function(tamperType)
    Logger.critical(string.format("Tamper detection: %s", tamperType))
    TriggerServerEvent('protector:detection:cheat', 'tamper_detected', {type = tamperType})
end)

-- Chat command protection
AddEventHandler('chatMessage', function(source, name, message)
    if not Config.Protection.PlayerProtection.Enabled then return end
    
    -- Check for blacklisted words
    local lowerMessage = string.lower(message)
    for _, word in ipairs(Config.Protection.PlayerProtection.BlacklistWords or {}) do
        if string.find(lowerMessage, string.lower(word)) then
            Logger.logDetection(name, source, "Blacklisted Word Used", {word = word, message = message})
            TriggerServerEvent('protector:detection:player', 'blacklisted_word', {word = word})
            CancelEvent()
            return
        end
    end
    
    -- Check for command injection
    if string.match(message, "^/") then
        local command = string.match(message, "^/(%w+)")
        if command then
            for _, blacklistedCmd in ipairs(Config.Protection.PlayerProtection.BlacklistCommands or {}) do
                if string.lower(command) == string.lower(blacklistedCmd) then
                    Logger.logDetection(name, source, "Blacklisted Command Used", {command = command})
                    TriggerServerEvent('protector:detection:player', 'blacklisted_command', {command = command})
                    CancelEvent()
                    return
                end
            end
        end
    end
end)

-- Vehicle blacklist protection
CreateThread(function()
    while true do
        Wait(2000)
        
        if not Config.Protection.WeaponProtection.BlacklistVehicles then
            Wait(10000)
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle and vehicle ~= 0 then
            local vehicleModel = GetEntityModel(vehicle)
            local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
            
            for _, blacklistedVehicle in ipairs(Config.Protection.WeaponProtection.BlacklistVehicles or {}) do
                if vehicleName == blacklistedVehicle then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blacklisted Vehicle Spawned", {
                        vehicle = blacklistedVehicle,
                        model = vehicleModel
                    })
                    TriggerServerEvent('protector:detection:player', 'blacklisted_vehicle', {vehicle = blacklistedVehicle})
                    
                    -- Remove the vehicle
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                    break
                end
            end
        end
        
        ::continue::
    end
end)

-- Export client functions
exports('getProtectionStatus', function()
    return {
        initialized = protectorInitialized,
        systems = systemStatus
    }
end)

exports('isProtectionEnabled', function(systemName)
    return systemStatus[systemName] or false
end)

-- Main NUI Callback handler
RegisterNUICallback('nui_callback', function(data, cb)
    local messageType = data.type
    local messageData = data.data or {}
    
    if messageType == 'nui_ready' then
        Logger.info("✓ NUI system ready")
        print("^2[Protector] NUI loaded successfully^7")
        
    elseif messageType == 'test_response' then
        Logger.info("✓ NUI connection test successful")
        print(string.format("^2[Protector] NUI Test: %s^7", messageData.message))
        
    elseif messageType == 'devtools_detected' then
        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "NUI DevTools Detection", {
            method = messageData.method,
            userAgent = messageData.userAgent,
            screen = messageData.screen
        })
        TriggerServerEvent('protector:detection:cheat', 'nui_devtools', messageData.method)
        
    elseif messageType == 'devtools_status' then
        if messageData.detected then
            print(string.format("^1[Protector] DevTools currently detected (Count: %d)^7", messageData.detectionCount))
        else
            print(string.format("^2[Protector] No DevTools detected (Count: %d)^7", messageData.detectionCount))
        end
        
    elseif messageType == 'detection_error' then
        Logger.warning("NUI detection error: " .. (messageData.error or "Unknown"))
        
    elseif messageType == 'keyboard_block' then
        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blocked DevTools Hotkey", {
            keyCode = messageData.key
        })
        
    elseif messageType == 'context_menu_block' then
        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blocked Context Menu", {})
        
    elseif messageType == 'heartbeat' then
        -- NUI is alive and responsive
        -- Could log this for monitoring if needed
        
    elseif messageType == 'pong' then
        print(string.format("^2[Protector] NUI ping successful (latency: %dms)^7", 
            GetGameTimer() - (messageData.timestamp or 0)))
    end
    
    cb('ok')
end)

-- Simple command to test NUI
RegisterCommand('test_nui', function()
    if Config.Protection.AntiCheat.NUIDevToolsDetection then
        print("^3[Protector] Testing NUI connection...^7")
        SendNUIMessage({
            type = "test_connection",
            message = "Manual NUI test command"
        })
    else
        print("^1[Protector] NUI DevTools detection is disabled^7")
    end
end, false)

-- Command to check DevTools status
RegisterCommand('check_devtools', function()
    if Config.Protection.AntiCheat.NUIDevToolsDetection then
        print("^3[Protector] Checking DevTools status...^7")
        SendNUIMessage({
            type = "devtools_check"
        })
    else
        print("^1[Protector] NUI DevTools detection is disabled^7")
    end
end, false)

-- Command to ping NUI
RegisterCommand('ping_nui', function()
    if Config.Protection.AntiCheat.NUIDevToolsDetection then
        print("^3[Protector] Pinging NUI...^7")
        SendNUIMessage({
            type = "ping",
            timestamp = GetGameTimer()
        })
    else
        print("^1[Protector] NUI DevTools detection is disabled^7")
    end
end, false)

-- Debug command (only in debug mode)
if Config.Protection.Debug then
    RegisterCommand('protector_debug', function()
        local status = exports[GetCurrentResourceName()]:getProtectionStatus()
        print("=== FiveM Server Protector Debug ===")
        print(json.encode(status, {indent = true}))
        
        -- Test NUI if enabled
        if Config.Protection.AntiCheat.NUIDevToolsDetection then
            print("Testing NUI connection...")
            SendNUIMessage({
                type = "test_connection",
                message = "Debug command test"
            })
            SendNUIMessage({
                type = "enable_debug"
            })
            Wait(1000)
            SendNUIMessage({
                type = "ping",
                timestamp = GetGameTimer()
            })
        end
    end, false)
end