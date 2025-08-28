Logger = {}

local logLevels = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
}

local logColors = {
    DEBUG = "^7",     -- White
    INFO = "^2",      -- Green
    WARNING = "^3",   -- Yellow
    ERROR = "^1",     -- Red
    CRITICAL = "^5"   -- Pink
}

function Logger.log(level, message, data)
    if not Config.Logging.Enabled then return end
    
    local currentLevel = logLevels[Config.Logging.LogLevel] or 2
    if logLevels[level] < currentLevel then return end
    
    -- Use different timestamp methods for client vs server
    local timestamp
    if IsDuplicityVersion() then
        -- Server side - os is available
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    else
        -- Client side - use GetGameTimer as fallback
        local gameTime = GetGameTimer()
        timestamp = string.format("T+%d", math.floor(gameTime / 1000))
    end
    
    local color = logColors[level] or "^7"
    local formattedMessage = string.format("[%s] [%s%s^7] %s", timestamp, color, level, message)
    
    -- Console output
    print(formattedMessage)
    
    -- File logging (server-side only)
    if IsDuplicityVersion() and Config.Logging.LocalFile then
        local logEntry = string.format("[%s] [%s] %s\n", timestamp, level, message)
        if data then
            logEntry = logEntry .. string.format("Data: %s\n", json.encode(data))
        end
        
        -- Write to file (simplified - in production use proper file handling)
        SaveResourceFile(GetCurrentResourceName(), Config.Logging.LocalFile, logEntry, -1)
    end
end

function Logger.debug(message, data)
    Logger.log("DEBUG", message, data)
end

function Logger.info(message, data)
    Logger.log("INFO", message, data)
end

function Logger.warning(message, data)
    Logger.log("WARNING", message, data)
end

function Logger.error(message, data)
    Logger.log("ERROR", message, data)
end

function Logger.critical(message, data)
    Logger.log("CRITICAL", message, data)
end

-- Anti-cheat specific logging
function Logger.logDetection(playerName, playerId, detectionType, details)
    local message = string.format("Detection: %s (ID: %s) - %s", playerName, playerId, detectionType)
    Logger.warning(message, details)
    
    -- Trigger webhook if enabled
    if IsDuplicityVersion() then
        TriggerEvent('protector:webhook:send', {
            type = 'detection',
            player = playerName,
            playerId = playerId,
            detection = detectionType,
            details = details,
            timestamp = os.time()
        })
    else
        -- Client side - send to server for webhook
        TriggerServerEvent('protector:client:detection', {
            type = 'detection',
            player = playerName,
            playerId = playerId,
            detection = detectionType,
            details = details
        })
    end
end

function Logger.logBan(playerName, playerId, reason, duration)
    local message = string.format("Ban: %s (ID: %s) - Reason: %s, Duration: %s", 
        playerName, playerId, reason, duration)
    Logger.critical(message)
    
    -- Trigger webhook if enabled (server side only)
    if IsDuplicityVersion() then
        TriggerEvent('protector:webhook:send', {
            type = 'ban_action',
            player = playerName,
            playerId = playerId,
            reason = reason,
            duration = duration,
            timestamp = os.time()
        })
    end
end

function Logger.logExploit(playerName, playerId, exploitType, severity)
    local message = string.format("Exploit Attempt: %s (ID: %s) - %s (Severity: %s)", 
        playerName, playerId, exploitType, severity)
    Logger.error(message)
    
    -- Trigger webhook if enabled (server side only)
    if IsDuplicityVersion() then
        TriggerEvent('protector:webhook:send', {
            type = 'exploit_attempt',
            player = playerName,
            playerId = playerId,
            exploit = exploitType,
            severity = severity,
            timestamp = os.time()
        })
    end
end