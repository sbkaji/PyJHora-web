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
            Wait(2000) -- Wait a bit for NUI to load
            SendNUIMessage({
                type = "test_connection",
                message = "Testing NUI communication"
            })
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

-- NUI Callback handlers
RegisterNUICallback('nui_test', function(data, cb)
    if data.status == 'connected' then
        Logger.info("✓ NUI connection test successful")
        print(string.format("^2[Protector] NUI Test: %s^7", data.message))
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
                message = "Manual test from debug command"
            })
        end
    end, false)
end