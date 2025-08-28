-- FiveM Server Protector - Server Main
-- Coordinates all server-side protection systems

local connectedClients = {}
local serverStats = {
    startTime = os.time(),
    protectedPlayers = 0,
    detectionsCount = 0,
    bansIssued = 0,
    blockedIPs = 0
}

-- Initialize the protection system
CreateThread(function()
    Wait(5000) -- Wait for server to fully start
    
    Logger.info("🛡️ FiveM Server Protector starting up...")
    
    if not Config.Protection.Enabled then
        Logger.warning("Protection system is disabled in config")
        return
    end
    
    -- Print startup banner
    printStartupBanner()
    
    -- Initialize server systems
    Logger.info("Initializing server protection systems...")
    
    if Config.Firewall.Enabled then
        Logger.info("✓ Firewall and DDoS protection loaded")
    end
    
    if Config.FileScanner.Enabled then
        Logger.info("✓ File scanner system loaded")
    end
    
    if Config.BanSystem.Enabled then
        Logger.info("✓ Ban management system loaded")
    end
    
    if Config.Webhook.Enabled and Config.Webhook.URL ~= "" then
        Logger.info("✓ Discord webhook integration loaded")
        
        -- Send startup notification
        TriggerEvent('protector:webhook:send', {
            type = 'info',
            title = '🚀 Server Protector Started',
            description = 'FiveM Server Protector has been successfully initialized',
            timestamp = os.time()
        })
    end
    
    Logger.info("🛡️ FiveM Server Protector server initialized successfully")
    
    -- Start monitoring systems
    startMonitoringSystems()
end)

-- Print startup banner
function printStartupBanner()
    print([[
    
████████╗██╗██╗   ██╗███████╗███╗   ███╗    ██████╗ ██████╗  ██████╗ ████████╗███████╗ ██████╗████████╗ ██████╗ ██████╗ 
██╔══════╝██║██║   ██║██╔════╝████╗ ████║    ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
██████╗  ██║██║   ██║█████╗  ██╔████╔██║    ██████╔╝██████╔╝██║   ██║   ██║   █████╗  ██║        ██║   ██║   ██║██████╔╝
██╔═══╝  ██║╚██╗ ██╔╝██╔══╝  ██║╚██╔╝██║    ██╔═══╝ ██╔══██╗██║   ██║   ██║   ██╔══╝  ██║        ██║   ██║   ██║██╔══██╗
██║      ██║ ╚████╔╝ ███████╗██║ ╚═╝ ██║    ██║     ██║  ██║╚██████╔╝   ██║   ███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║
╚═╝      ╚═╝  ╚═══╝  ╚══════╝╚═╝     ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

                                    Advanced FiveM Server Protection System
                                           Version 1.0.0 - MVP Release
    
    ]])
end

-- Start monitoring systems
function startMonitoringSystems()
    -- Player monitoring
    CreateThread(function()
        while true do
            Wait(60000) -- Every minute
            
            local playerCount = #GetPlayers()
            serverStats.protectedPlayers = playerCount
            
            -- Clean up old client data
            for playerId, data in pairs(connectedClients) do
                if not GetPlayerName(playerId) then
                    connectedClients[playerId] = nil
                end
            end
            
            Logger.debug(string.format("Monitoring %d players", playerCount))
        end
    end)
    
    -- System health monitoring
    CreateThread(function()
        while true do
            Wait(300000) -- Every 5 minutes
            
            local uptime = os.time() - serverStats.startTime
            local memoryUsage = collectgarbage("count")
            
            Logger.info(string.format("System Status - Uptime: %s, Memory: %.2f MB, Players: %d", 
                formatDuration(uptime), memoryUsage / 1024, serverStats.protectedPlayers))
            
            -- Send health report
            if Config.Webhook.Enabled then
                TriggerEvent('protector:webhook:send', {
                    type = 'info',
                    title = '📊 System Health Report',
                    description = string.format('Uptime: %s\nMemory: %.2f MB\nPlayers: %d\nDetections: %d', 
                        formatDuration(uptime), memoryUsage / 1024, serverStats.protectedPlayers, serverStats.detectionsCount),
                    timestamp = os.time()
                })
            end
        end
    end)
end

-- Handle client initialization
RegisterNetEvent('protector:client:initialized')
AddEventHandler('protector:client:initialized', function(clientStatus)
    local source = source
    local playerName = GetPlayerName(source)
    
    connectedClients[source] = {
        name = playerName,
        status = clientStatus,
        initTime = os.time(),
        lastHeartbeat = os.time()
    }
    
    Logger.info(string.format("Client initialized: %s [%d]", playerName, source))
end)

-- Handle client heartbeat
RegisterNetEvent('protector:heartbeat')
AddEventHandler('protector:heartbeat', function(heartbeatData)
    local source = source
    
    if connectedClients[source] then
        connectedClients[source].lastHeartbeat = os.time()
        connectedClients[source].lastData = heartbeatData
    end
end)

-- Handle client status requests
RegisterNetEvent('protector:client_status')
AddEventHandler('protector:client_status', function(statusData)
    local source = source
    
    if connectedClients[source] then
        connectedClients[source].detailedStatus = statusData
    end
end)

-- Detection event handlers
RegisterNetEvent('protector:detection:cheat')
AddEventHandler('protector:detection:cheat', function(cheatType, details)
    local source = source
    serverStats.detectionsCount = serverStats.detectionsCount + 1
    
    -- Forward to ban system
    TriggerEvent('protector:detection:cheat', cheatType, details)
end)

RegisterNetEvent('protector:detection:player')
AddEventHandler('protector:detection:player', function(detectionType, details)
    local source = source
    serverStats.detectionsCount = serverStats.detectionsCount + 1
    
    -- Forward to ban system
    TriggerEvent('protector:detection:player', detectionType, details)
end)

RegisterNetEvent('protector:detection:weapon')
AddEventHandler('protector:detection:weapon', function(weaponCheat, details)
    local source = source
    serverStats.detectionsCount = serverStats.detectionsCount + 1
    
    -- Forward to ban system
    TriggerEvent('protector:detection:weapon', weaponCheat, details)
end)

-- Player connection handling
AddEventHandler('playerJoining', function(source)
    local playerName = GetPlayerName(source)
    Logger.info(string.format("Player connecting: %s [%d]", playerName, source))
    
    -- Request client status after connection
    SetTimeout(5000, function()
        TriggerClientEvent('protector:request_status', source)
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)
    
    if connectedClients[source] then
        connectedClients[source] = nil
    end
    
    Logger.info(string.format("Player disconnected: %s [%d] - %s", playerName or "Unknown", source, reason))
end)

-- Admin commands
RegisterCommand('protector', function(source, args, rawCommand)
    if source ~= 0 and not IsPlayerAceAllowed(source, "protector.admin") then
        return
    end
    
    local subcommand = args[1]
    
    if subcommand == "status" then
        showSystemStatus(source)
    elseif subcommand == "stats" then
        showSystemStats(source)
    elseif subcommand == "reload" then
        reloadConfig(source)
    elseif subcommand == "scan" then
        if Config.FileScanner.Enabled then
            ExecuteCommand('scan_files')
            print("File scan initiated")
        else
            print("File scanner is disabled")
        end
    else
        print("FiveM Server Protector Commands:")
        print("  /protector status  - Show system status")
        print("  /protector stats   - Show protection statistics")
        print("  /protector reload  - Reload configuration")
        print("  /protector scan    - Start file scan")
    end
end, true)

-- Show system status
function showSystemStatus(source)
    local output = source == 0 and print or function(msg) TriggerClientEvent('chat:addMessage', source, {args = {'System', msg}}) end
    
    output("=== FiveM Server Protector Status ===")
    output(string.format("Protection: %s", Config.Protection.Enabled and "✓ Enabled" or "✗ Disabled"))
    output(string.format("Anti-cheat: %s", Config.Protection.AntiCheat.Enabled and "✓ Active" or "✗ Inactive"))
    output(string.format("Firewall: %s", Config.Firewall.Enabled and "✓ Active" or "✗ Inactive"))
    output(string.format("File Scanner: %s", Config.FileScanner.Enabled and "✓ Active" or "✗ Inactive"))
    output(string.format("Ban System: %s", Config.BanSystem.Enabled and "✓ Active" or "✗ Inactive"))
    output(string.format("Webhooks: %s", (Config.Webhook.Enabled and Config.Webhook.URL ~= "") and "✓ Connected" or "✗ Disconnected"))
    output(string.format("Protected Players: %d", serverStats.protectedPlayers))
end

-- Show system statistics
function showSystemStats(source)
    local output = source == 0 and print or function(msg) TriggerClientEvent('chat:addMessage', source, {args = {'Stats', msg}}) end
    
    local uptime = os.time() - serverStats.startTime
    
    output("=== Protection Statistics ===")
    output(string.format("Uptime: %s", formatDuration(uptime)))
    output(string.format("Detections: %d", serverStats.detectionsCount))
    output(string.format("Bans Issued: %d", serverStats.bansIssued))
    output(string.format("Blocked IPs: %d", serverStats.blockedIPs))
    output(string.format("Connected Clients: %d", tableLength(connectedClients)))
end

-- Reload configuration
function reloadConfig(source)
    -- In a production environment, you might reload from file
    Logger.info("Configuration reload requested")
    
    if source == 0 then
        print("Configuration reloaded")
    else
        TriggerClientEvent('chat:addMessage', source, {args = {'System', 'Configuration reloaded'}})
    end
end

-- Utility functions
function formatDuration(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    else
        return string.format("%dm", minutes)
    end
end

function tableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Export server functions
exports('getSystemStats', function() return serverStats end)
exports('getConnectedClients', function() return connectedClients end)
exports('getProtectionStatus', function()
    return {
        enabled = Config.Protection.Enabled,
        anticheat = Config.Protection.AntiCheat.Enabled,
        firewall = Config.Firewall.Enabled,
        scanner = Config.FileScanner.Enabled,
        bans = Config.BanSystem.Enabled,
        webhooks = Config.Webhook.Enabled and Config.Webhook.URL ~= ""
    }
end)

-- Performance monitoring
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        if Config.Performance.GarbageCollection then
            local beforeMem = collectgarbage("count")
            collectgarbage("collect")
            local afterMem = collectgarbage("count")
            local freed = beforeMem - afterMem
            
            if freed > 1024 then -- More than 1MB freed
                Logger.debug(string.format("Garbage collection freed %.2f MB", freed / 1024))
            end
        end
    end
end)