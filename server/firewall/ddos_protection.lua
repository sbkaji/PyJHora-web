-- DDoS Protection and Firewall System
-- Advanced protection against various types of network attacks

local connectionTracker = {}
local ipRequestCount = {}
local suspiciousIPs = {}
local blockedIPs = {}
local rateLimitTracker = {}

-- Initialize firewall protection
CreateThread(function()
    Wait(5000)
    
    if Config.Firewall.Enabled then
        Logger.info("Firewall and DDoS protection initialized")
        
        -- Load blocked IPs from database/file if needed
        loadBlockedIPs()
        
        -- Start monitoring threads
        monitorConnections()
        monitorRequests()
        cleanupOldData()
    end
end)

-- Monitor player connections for suspicious patterns
function monitorConnections()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Firewall.DDoSProtection then
                Wait(10000)
                goto continue
            end
            
            -- Check for rapid connection attempts from same IP
            for ip, data in pairs(connectionTracker) do
                local currentTime = os.time()
                local timeWindow = 60 -- 1 minute
                
                -- Count connections in the last minute
                local recentConnections = 0
                for _, timestamp in ipairs(data.connections) do
                    if currentTime - timestamp < timeWindow then
                        recentConnections = recentConnections + 1
                    end
                end
                
                -- Threshold for suspicious activity
                if recentConnections > 10 then
                    suspiciousIPs[ip] = {
                        reason = "rapid_connections",
                        count = recentConnections,
                        firstSeen = data.firstSeen,
                        lastSeen = currentTime
                    }
                    
                    Logger.logExploit("Unknown", -1, "DDoS Attack Detected", "HIGH")
                    
                    -- Send webhook notification
                    TriggerEvent('protector:webhook:send', {
                        type = 'ddos_attack',
                        sourceIP = ip,
                        attackType = 'rapid_connections',
                        requestCount = recentConnections,
                        timestamp = os.time()
                    })
                    
                    -- Auto-block if enabled
                    blockIP(ip, "DDoS - Rapid connections")
                end
            end
            
            ::continue::
        end
    end)
end

-- Monitor request patterns for rate limiting
function monitorRequests()
    CreateThread(function()
        while true do
            Wait(5000)
            
            if not Config.Firewall.RateLimit.Enabled then
                Wait(10000)
                goto continue
            end
            
            local currentTime = os.time()
            local timeWindow = Config.Firewall.RateLimit.TimeWindow / 1000 -- Convert to seconds
            local maxRequests = Config.Firewall.RateLimit.MaxRequests
            
            for ip, requests in pairs(ipRequestCount) do
                local recentRequests = 0
                
                -- Count requests in the time window
                for _, timestamp in ipairs(requests) do
                    if currentTime - timestamp < timeWindow then
                        recentRequests = recentRequests + 1
                    end
                end
                
                if recentRequests > maxRequests then
                    Logger.warning(string.format("Rate limit exceeded for IP %s: %d requests", ip, recentRequests))
                    
                    -- Add to rate limit tracker
                    rateLimitTracker[ip] = {
                        count = recentRequests,
                        lastViolation = currentTime,
                        violations = (rateLimitTracker[ip] and rateLimitTracker[ip].violations or 0) + 1
                    }
                    
                    -- Block after multiple violations
                    if rateLimitTracker[ip].violations > 3 then
                        blockIP(ip, "Rate limit violations")
                    end
                end
            end
            
            ::continue::
        end
    end)
end

-- Clean up old tracking data
function cleanupOldData()
    CreateThread(function()
        while true do
            Wait(300000) -- 5 minutes
            
            local currentTime = os.time()
            local cleanupThreshold = 3600 -- 1 hour
            
            -- Cleanup connection tracker
            for ip, data in pairs(connectionTracker) do
                local cleanConnections = {}
                for _, timestamp in ipairs(data.connections) do
                    if currentTime - timestamp < cleanupThreshold then
                        table.insert(cleanConnections, timestamp)
                    end
                end
                
                if #cleanConnections > 0 then
                    connectionTracker[ip].connections = cleanConnections
                else
                    connectionTracker[ip] = nil
                end
            end
            
            -- Cleanup request tracker
            for ip, requests in pairs(ipRequestCount) do
                local cleanRequests = {}
                for _, timestamp in ipairs(requests) do
                    if currentTime - timestamp < cleanupThreshold then
                        table.insert(cleanRequests, timestamp)
                    end
                end
                
                if #cleanRequests > 0 then
                    ipRequestCount[ip] = cleanRequests
                else
                    ipRequestCount[ip] = nil
                end
            end
            
            -- Cleanup rate limit tracker
            for ip, data in pairs(rateLimitTracker) do
                if currentTime - data.lastViolation > cleanupThreshold then
                    rateLimitTracker[ip] = nil
                end
            end
            
            Logger.debug("Cleaned up old firewall tracking data")
        end
    end)
end

-- Track player connections
function trackConnection(source)
    if not Config.Firewall.Enabled then return end
    
    local playerIP = GetPlayerEndpoint(source)
    if not playerIP then return end
    
    -- Extract IP from endpoint
    local ip = string.match(playerIP, "([^:]+)")
    if not ip then return end
    
    local currentTime = os.time()
    
    if not connectionTracker[ip] then
        connectionTracker[ip] = {
            connections = {},
            firstSeen = currentTime
        }
    end
    
    table.insert(connectionTracker[ip].connections, currentTime)
    
    -- Check if IP is blocked
    if blockedIPs[ip] then
        Logger.warning(string.format("Blocked IP %s attempted to connect", ip))
        DropPlayer(source, "Your IP address has been blocked")
        return false
    end
    
    -- Check IP blacklist
    for _, blacklistedIP in ipairs(Config.Firewall.IPBlacklist) do
        if ip == blacklistedIP then
            Logger.warning(string.format("Blacklisted IP %s attempted to connect", ip))
            DropPlayer(source, "Your IP address is blacklisted")
            return false
        end
    end
    
    return true
end

-- Track requests (called by various events)
function trackRequest(source)
    if not Config.Firewall.RateLimit.Enabled then return true end
    
    local playerIP = GetPlayerEndpoint(source)
    if not playerIP then return true end
    
    local ip = string.match(playerIP, "([^:]+)")
    if not ip then return true end
    
    local currentTime = os.time()
    
    if not ipRequestCount[ip] then
        ipRequestCount[ip] = {}
    end
    
    table.insert(ipRequestCount[ip], currentTime)
    
    -- Check current rate
    local timeWindow = Config.Firewall.RateLimit.TimeWindow / 1000
    local recentRequests = 0
    
    for _, timestamp in ipairs(ipRequestCount[ip]) do
        if currentTime - timestamp < timeWindow then
            recentRequests = recentRequests + 1
        end
    end
    
    if recentRequests > Config.Firewall.RateLimit.MaxRequests then
        Logger.warning(string.format("Rate limit exceeded for player %s (IP: %s)", GetPlayerName(source), ip))
        return false
    end
    
    return true
end

-- Block an IP address
function blockIP(ip, reason)
    if blockedIPs[ip] then return end
    
    blockedIPs[ip] = {
        reason = reason,
        timestamp = os.time(),
        blocked = true
    }
    
    Logger.critical(string.format("Blocked IP: %s - Reason: %s", ip, reason))
    
    -- Find and kick all players with this IP
    for _, playerId in ipairs(GetPlayers()) do
        local playerIP = GetPlayerEndpoint(playerId)
        if playerIP then
            local playerIPOnly = string.match(playerIP, "([^:]+)")
            if playerIPOnly == ip then
                DropPlayer(playerId, string.format("IP blocked: %s", reason))
            end
        end
    end
    
    -- Save to persistent storage if configured
    saveBlockedIP(ip, reason)
end

-- Unblock an IP address
function unblockIP(ip)
    if blockedIPs[ip] then
        blockedIPs[ip] = nil
        Logger.info(string.format("Unblocked IP: %s", ip))
        removeBlockedIP(ip)
        return true
    end
    return false
end

-- VPN/Proxy detection (basic implementation)
function checkVPNProxy(ip)
    if not Config.Firewall.VPNProxyDetection then return false end
    
    -- Basic VPN/Proxy detection patterns
    local vpnPatterns = {
        "^10%.",          -- Private IP range
        "^192%.168%.",    -- Private IP range  
        "^172%.1[6-9]%.", -- Private IP range
        "^172%.2[0-9]%.", -- Private IP range
        "^172%.3[0-1]%."  -- Private IP range
    }
    
    for _, pattern in ipairs(vpnPatterns) do
        if string.match(ip, pattern) then
            return true
        end
    end
    
    -- In a production environment, you would integrate with VPN detection APIs
    -- such as IPQualityScore, MaxMind, or similar services
    
    return false
end

-- Load blocked IPs from storage
function loadBlockedIPs()
    -- Implementation depends on your storage method
    -- This is a placeholder for database/file loading
    Logger.debug("Loading blocked IPs from storage")
end

-- Save blocked IP to storage
function saveBlockedIP(ip, reason)
    -- Implementation depends on your storage method
    -- This is a placeholder for database/file saving
    Logger.debug(string.format("Saving blocked IP %s to storage", ip))
end

-- Remove blocked IP from storage
function removeBlockedIP(ip)
    -- Implementation depends on your storage method
    Logger.debug(string.format("Removing blocked IP %s from storage", ip))
end

-- Event handlers
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    
    Wait(100) -- Small delay to ensure IP is available
    
    if not trackConnection(source) then
        deferrals.done("Connection blocked by firewall")
        return
    end
    
    local playerIP = GetPlayerEndpoint(source)
    if playerIP then
        local ip = string.match(playerIP, "([^:]+)")
        if ip and checkVPNProxy(ip) then
            Logger.warning(string.format("VPN/Proxy detected for player %s (IP: %s)", name, ip))
            deferrals.done("VPN/Proxy connections are not allowed")
            return
        end
    end
    
    deferrals.done()
end)

-- Hook into common events to track requests
RegisterNetEvent('protector:track:request')
AddEventHandler('protector:track:request', function()
    local source = source
    if not trackRequest(source) then
        -- Rate limit exceeded
        TriggerClientEvent('protector:rate_limited', source)
    end
end)

-- Export functions
exports('blockIP', blockIP)
exports('unblockIP', unblockIP)
exports('isIPBlocked', function(ip) return blockedIPs[ip] ~= nil end)
exports('getFirewallStats', function()
    return {
        blockedIPs = blockedIPs,
        suspiciousIPs = suspiciousIPs,
        connectionTracker = connectionTracker,
        rateLimitTracker = rateLimitTracker
    }
end)