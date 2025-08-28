Webhook = {}

local function getWebhookColor(type)
    if type == 'detection' or type == 'exploit_attempt' then
        return Config.Webhook.Colors.Warning
    elseif type == 'ban_action' or type == 'error' then
        return Config.Webhook.Colors.Critical
    else
        return Config.Webhook.Colors.Info
    end
end

local function formatWebhookMessage(data)
    local embed = {
        title = "🛡️ FiveM Protector Alert",
        color = getWebhookColor(data.type),
        timestamp = data.timestamp and os.date("!%Y-%m-%dT%H:%M:%SZ", data.timestamp) or os.date("!%Y-%m-%dT%H:%M:%SZ"),
        footer = {
            text = "FiveM Server Protector",
            icon_url = "https://cdn.discordapp.com/attachments/123456789/shield.png"
        }
    }
    
    if data.type == 'detection' then
        embed.title = "🔍 Cheat Detection"
        embed.description = string.format("**Player:** %s (ID: %s)\n**Detection:** %s", 
            data.player, data.playerId, data.detection)
        if data.details then
            embed.description = embed.description .. "\n**Details:** " .. json.encode(data.details)
        end
        
    elseif data.type == 'exploit_attempt' then
        embed.title = "⚠️ Exploit Attempt"
        embed.description = string.format("**Player:** %s (ID: %s)\n**Exploit:** %s\n**Severity:** %s", 
            data.player, data.playerId, data.exploit, data.severity)
            
    elseif data.type == 'ban_action' then
        embed.title = "🔨 Ban Action"
        embed.description = string.format("**Player:** %s (ID: %s)\n**Reason:** %s\n**Duration:** %s", 
            data.player, data.playerId, data.reason, data.duration)
            
    elseif data.type == 'ddos_attack' then
        embed.title = "🚨 DDoS Attack Detected"
        embed.description = string.format("**Source IP:** %s\n**Attack Type:** %s\n**Requests:** %d", 
            data.sourceIP or "Unknown", data.attackType or "Unknown", data.requestCount or 0)
            
    elseif data.type == 'error' then
        embed.title = "❌ System Error"
        embed.description = string.format("**Error:** %s\n**Component:** %s", 
            data.error, data.component or "Unknown")
    end
    
    return {
        username = "FiveM Protector",
        avatar_url = "https://cdn.discordapp.com/attachments/123456789/shield.png",
        embeds = {embed}
    }
end

function Webhook.send(data)
    -- Only send webhooks from server-side
    if not IsDuplicityVersion() then
        return
    end
    
    if not Config.Webhook.Enabled or not Config.Webhook.URL or Config.Webhook.URL == "" then
        return
    end
    
    if not Config.Webhook.Types[data.type] then
        return
    end
    
    local payload = formatWebhookMessage(data)
    
    PerformHttpRequest(Config.Webhook.URL, function(statusCode, response, headers)
        if statusCode == 200 or statusCode == 204 then
            Logger.debug("Webhook sent successfully", {type = data.type})
        else
            Logger.error("Failed to send webhook", {
                statusCode = statusCode,
                response = response,
                type = data.type
            })
        end
    end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

-- Server-side event handler
if IsDuplicityVersion() then
    RegisterNetEvent('protector:webhook:send')
    AddEventHandler('protector:webhook:send', function(data)
        Webhook.send(data)
    end)
end