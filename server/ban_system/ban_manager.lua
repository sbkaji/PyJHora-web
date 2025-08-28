-- Ban System Manager
-- Comprehensive ban management with automatic and manual banning capabilities

local activeBans = {}
local tempBans = {}
local whitelist = {}
local banHistory = {}
local detectionCounts = {}

-- Ban reasons and their default durations
local banReasons = {
    ["external_cheat"] = {duration = Config.BanSystem.BanDurations.Heavy, autoban = true},
    ["susano_cheat"] = {duration = Config.BanSystem.BanDurations.Permanent, autoban = true},
    ["aimbot"] = {duration = Config.BanSystem.BanDurations.Heavy, autoban = true},
    ["speed_hack"] = {duration = Config.BanSystem.BanDurations.Medium, autoban = true},
    ["godmode"] = {duration = Config.BanSystem.BanDurations.Medium, autoban = true},
    ["teleport"] = {duration = Config.BanSystem.BanDurations.Light, autoban = false},
    ["weapon_hack"] = {duration = Config.BanSystem.BanDurations.Heavy, autoban = true},
    ["noclip"] = {duration = Config.BanSystem.BanDurations.Medium, autoban = true},
    ["spectator"] = {duration = Config.BanSystem.BanDurations.Light, autoban = false},
    ["vdm"] = {duration = Config.BanSystem.BanDurations.Medium, autoban = false},
    ["spam"] = {duration = Config.BanSystem.BanDurations.Light, autoban = false},
    ["toxic_behavior"] = {duration = Config.BanSystem.BanDurations.Medium, autoban = false}
}

-- Initialize ban system
CreateThread(function()
    Wait(5000)
    
    if Config.BanSystem.Enabled then
        Logger.info("Ban system initialized")
        
        -- Load existing bans and whitelist
        loadBansFromStorage()
        loadWhitelistFromStorage()
        
        -- Start cleanup thread
        cleanupExpiredBans()
    end
end)

-- Check if player is banned on connect
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    
    Wait(100)
    
    local identifiers = getPlayerIdentifiers(source)
    local banInfo = checkPlayerBan(identifiers)
    
    if banInfo then
        local message = formatBanMessage(banInfo)
        deferrals.done(message)
        
        Logger.info(string.format("Banned player %s (%s) attempted to connect", name, identifiers.license or "Unknown"))
        return
    end
    
    -- Check whitelist if protection is enabled
    if Config.BanSystem.WhitelistProtection then
        if not isPlayerWhitelisted(identifiers) then
            deferrals.done("You are not whitelisted on this server")
            return
        end
    end
    
    deferrals.done()
end)

-- Main ban function
function banPlayer(source, reason, duration, adminName, evidence)
    if not Config.BanSystem.Enabled then
        return false, "Ban system is disabled"
    end
    
    local identifiers = getPlayerIdentifiers(source)
    if not identifiers.license then
        return false, "Could not retrieve player identifiers"
    end
    
    -- Check if player is whitelisted
    if isPlayerWhitelisted(identifiers) and not adminName then
        Logger.warning(string.format("Attempted to ban whitelisted player: %s", GetPlayerName(source)))
        return false, "Cannot ban whitelisted player"
    end
    
    local playerName = GetPlayerName(source)
    local currentTime = os.time()
    local banDuration = duration or banReasons[reason]?.duration or Config.BanSystem.BanDurations.Medium
    local isPermanent = banDuration == -1
    local expiresAt = isPermanent and -1 or (currentTime + banDuration)
    
    local banData = {
        playerId = identifiers.license,
        playerName = playerName,
        reason = reason,
        duration = banDuration,
        bannedAt = currentTime,
        expiresAt = expiresAt,
        bannedBy = adminName or "System",
        evidence = evidence or {},
        active = true,
        type = isPermanent and "permanent" or "temporary"
    }
    
    -- Store ban
    activeBans[identifiers.license] = banData
    table.insert(banHistory, banData)
    
    -- Drop player
    local banMessage = formatBanMessage(banData)
    DropPlayer(source, banMessage)
    
    -- Log ban
    Logger.logBan(playerName, source, reason, isPermanent and "Permanent" or formatDuration(banDuration))
    
    -- Save to storage
    saveBanToStorage(banData)
    
    return true, "Player banned successfully"
end

-- Unban player
function unbanPlayer(identifier, reason, adminName)
    if not Config.BanSystem.Enabled then
        return false, "Ban system is disabled"
    end
    
    if not activeBans[identifier] then
        return false, "Player is not banned"
    end
    
    local banData = activeBans[identifier]
    banData.active = false
    banData.unbannedAt = os.time()
    banData.unbanReason = reason
    banData.unbannedBy = adminName or "System"
    
    activeBans[identifier] = nil
    
    Logger.info(string.format("Player %s unbanned by %s. Reason: %s", banData.playerName, adminName or "System", reason))
    
    -- Update storage
    updateBanInStorage(banData)
    
    return true, "Player unbanned successfully"
end

-- Add to whitelist
function addToWhitelist(identifier, reason, adminName)
    whitelist[identifier] = {
        addedAt = os.time(),
        addedBy = adminName or "System",
        reason = reason or "No reason provided"
    }
    
    Logger.info(string.format("Player %s added to whitelist by %s", identifier, adminName or "System"))
    saveWhitelistToStorage()
    
    return true
end

-- Remove from whitelist
function removeFromWhitelist(identifier, adminName)
    if whitelist[identifier] then
        whitelist[identifier] = nil
        Logger.info(string.format("Player %s removed from whitelist by %s", identifier, adminName or "System"))
        saveWhitelistToStorage()
        return true
    end
    return false
end

-- Check if player is banned
function checkPlayerBan(identifiers)
    for _, identifier in pairs(identifiers) do
        if activeBans[identifier] then
            local banData = activeBans[identifier]
            
            -- Check if ban has expired
            if banData.expiresAt ~= -1 and os.time() > banData.expiresAt then
                activeBans[identifier] = nil
                updateBanInStorage(banData)
                return nil
            end
            
            return banData
        end
    end
    return nil
end

-- Check if player is whitelisted
function isPlayerWhitelisted(identifiers)
    if not Config.BanSystem.WhitelistProtection then
        return true
    end
    
    for _, identifier in pairs(identifiers) do
        if whitelist[identifier] then
            return true
        end
    end
    return false
end

-- Handle detection events
RegisterNetEvent('protector:detection:cheat')
AddEventHandler('protector:detection:cheat', function(cheatType, details)
    local source = source
    local playerName = GetPlayerName(source)
    local identifiers = getPlayerIdentifiers(source)
    
    if not identifiers.license then return end
    
    -- Increment detection count
    if not detectionCounts[identifiers.license] then
        detectionCounts[identifiers.license] = {}
    end
    
    detectionCounts[identifiers.license][cheatType] = (detectionCounts[identifiers.license][cheatType] or 0) + 1
    local count = detectionCounts[identifiers.license][cheatType]
    
    Logger.logDetection(playerName, source, cheatType, {details = details, count = count})
    
    -- Check if automatic ban should be applied
    if Config.BanSystem.AutomaticBans and banReasons[cheatType] and banReasons[cheatType].autoban then
        local thresholds = {
            ["external_cheat"] = 1,
            ["susano_cheat"] = 1,
            ["aimbot"] = 3,
            ["speed_hack"] = 5,
            ["godmode"] = 3,
            ["weapon_hack"] = 2,
            ["noclip"] = 3
        }
        
        local threshold = thresholds[cheatType] or 5
        
        if count >= threshold then
            banPlayer(source, cheatType, nil, "System", {
                detectionCount = count,
                lastDetection = details,
                autoban = true
            })
        end
    end
end)

-- Handle other detection events
RegisterNetEvent('protector:detection:player')
AddEventHandler('protector:detection:player', function(detectionType, details)
    local source = source
    TriggerEvent('protector:detection:cheat', detectionType, details)
end)

RegisterNetEvent('protector:detection:weapon')
AddEventHandler('protector:detection:weapon', function(weaponCheat, details)
    local source = source
    TriggerEvent('protector:detection:cheat', 'weapon_hack', {type = weaponCheat, details = details})
end)

RegisterNetEvent('protector:detection:spectate')
AddEventHandler('protector:detection:spectate', function()
    local source = source
    TriggerEvent('protector:detection:cheat', 'spectator', {})
end)

-- Utility functions
function getPlayerIdentifiers(source)
    local identifiers = {}
    
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local identifier = GetPlayerIdentifier(source, i)
        local prefix = string.match(identifier, "^([^:]+):")
        local value = string.match(identifier, ":(.+)$")
        
        if prefix and value then
            identifiers[prefix] = value
        end
    end
    
    return identifiers
end

function formatBanMessage(banData)
    local message = string.format([[
🚫 You have been banned from this server

Reason: %s
Banned by: %s
Date: %s
    ]], banData.reason, banData.bannedBy, os.date("%Y-%m-%d %H:%M:%S", banData.bannedAt))
    
    if banData.type == "temporary" then
        message = message .. string.format("Expires: %s\n", os.date("%Y-%m-%d %H:%M:%S", banData.expiresAt))
        message = message .. string.format("Time remaining: %s\n", formatDuration(banData.expiresAt - os.time()))
    else
        message = message .. "Duration: Permanent\n"
    end
    
    message = message .. "\nIf you believe this ban is unjustified, please contact server administration."
    
    return message
end

function formatDuration(seconds)
    if seconds <= 0 then return "Expired" end
    
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

-- Cleanup expired bans
function cleanupExpiredBans()
    CreateThread(function()
        while true do
            Wait(300000) -- Check every 5 minutes
            
            local currentTime = os.time()
            local expiredBans = {}
            
            for identifier, banData in pairs(activeBans) do
                if banData.expiresAt ~= -1 and currentTime > banData.expiresAt then
                    banData.active = false
                    banData.expiredAt = currentTime
                    table.insert(expiredBans, identifier)
                    
                    Logger.info(string.format("Ban expired for player %s", banData.playerName))
                end
            end
            
            for _, identifier in ipairs(expiredBans) do
                activeBans[identifier] = nil
            end
            
            if #expiredBans > 0 then
                updateExpiredBansInStorage(expiredBans)
            end
        end
    end)
end

-- Storage functions (implement based on your storage solution)
function loadBansFromStorage()
    -- Load from database or file
    Logger.debug("Loading bans from storage")
end

function loadWhitelistFromStorage()
    -- Load from database or file
    Logger.debug("Loading whitelist from storage")
end

function saveBanToStorage(banData)
    -- Save to database or file
    Logger.debug(string.format("Saving ban to storage: %s", banData.playerId))
end

function updateBanInStorage(banData)
    -- Update in database or file
    Logger.debug(string.format("Updating ban in storage: %s", banData.playerId))
end

function updateExpiredBansInStorage(expiredBans)
    -- Update multiple bans in database or file
    Logger.debug(string.format("Updating %d expired bans in storage", #expiredBans))
end

function saveWhitelistToStorage()
    -- Save whitelist to database or file
    Logger.debug("Saving whitelist to storage")
end

-- Commands
RegisterCommand('ban', function(source, args, rawCommand)
    if source ~= 0 and not isPlayerAdmin(source) then return end
    
    if #args < 2 then
        print("Usage: ban <player_id> <reason> [duration_in_seconds]")
        return
    end
    
    local targetId = tonumber(args[1])
    local reason = args[2]
    local duration = args[3] and tonumber(args[3]) or nil
    local adminName = source == 0 and "Console" or GetPlayerName(source)
    
    if not targetId or not GetPlayerName(targetId) then
        print("Invalid player ID")
        return
    end
    
    local success, message = banPlayer(targetId, reason, duration, adminName)
    print(message)
end, true)

RegisterCommand('unban', function(source, args, rawCommand)
    if source ~= 0 and not isPlayerAdmin(source) then return end
    
    if #args < 1 then
        print("Usage: unban <license_identifier> [reason]")
        return
    end
    
    local identifier = args[1]
    local reason = args[2] or "No reason provided"
    local adminName = source == 0 and "Console" or GetPlayerName(source)
    
    local success, message = unbanPlayer(identifier, reason, adminName)
    print(message)
end, true)

RegisterCommand('whitelist', function(source, args, rawCommand)
    if source ~= 0 and not isPlayerAdmin(source) then return end
    
    if #args < 2 then
        print("Usage: whitelist <add/remove> <license_identifier> [reason]")
        return
    end
    
    local action = args[1]
    local identifier = args[2]
    local reason = args[3]
    local adminName = source == 0 and "Console" or GetPlayerName(source)
    
    if action == "add" then
        addToWhitelist(identifier, reason, adminName)
        print(string.format("Added %s to whitelist", identifier))
    elseif action == "remove" then
        if removeFromWhitelist(identifier, adminName) then
            print(string.format("Removed %s from whitelist", identifier))
        else
            print("Player not found in whitelist")
        end
    else
        print("Invalid action. Use 'add' or 'remove'")
    end
end, true)

-- Helper function to check admin permissions
function isPlayerAdmin(source)
    -- Implement your admin check logic here
    return IsPlayerAceAllowed(source, "protector.admin")
end

-- Export functions
exports('banPlayer', banPlayer)
exports('unbanPlayer', unbanPlayer)
exports('addToWhitelist', addToWhitelist)
exports('removeFromWhitelist', removeFromWhitelist)
exports('isPlayerBanned', function(source) return checkPlayerBan(getPlayerIdentifiers(source)) ~= nil end)
exports('isPlayerWhitelisted', function(source) return isPlayerWhitelisted(getPlayerIdentifiers(source)) end)
exports('getBanInfo', function(source) return checkPlayerBan(getPlayerIdentifiers(source)) end)
exports('getBanStats', function() 
    return {
        activeBans = #activeBans,
        totalBans = #banHistory,
        whitelistedPlayers = #whitelist
    }
end)