-- Core Anticheat Detection System
-- Based on advanced memory manipulation and external cheat detection

local mightyCasual = 0
local mL_cBaPm = false
local eA_yPauK = false
local detectionFlags = {}
local lastMemoryCheck = 0
local suspiciousActivity = 0

-- Advanced memory integrity checks
function returnCoreInit()
    local Beta, Alpha = Citizen.InvokeNative(0x873C9F3104101DD3, Citizen.PointerValueInt(), Citizen.PointerValueInt())
    local teq, jiu = Citizen.InvokeNative(0xBDBA226F, Citizen.PointerValueInt(), Citizen.PointerValueInt())
    
    if Beta == 0 or Alpha == 0 then
        return 0, 0
    end
    
    local lan = (teq + 1) / Beta
    local uefi = (jiu + 1) / Alpha
    return lan, uefi
end

-- External cheat detection (similar to your provided code)
CreateThread(function()
    while true do
        Wait(Config.Protection.AntiCheat.CheckInterval or 500)
        
        if not Config.Protection.AntiCheat.Enabled then
            Wait(5000)
            goto continue
        end
        
        if mL_cBaPm then
            local a, b = returnCoreInit()
            local c = Citizen.InvokeNative(0xFC695459D4D0E219, a, b)
            
            if not c then
                mightyCasual = mightyCasual + 1
                if mightyCasual >= 4 then
                    mightyCasual = 0
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "External Cheat Detected", {
                        type = "TZx",
                        memoryValues = {a = a, b = b},
                        timestamp = GetGameTimer()
                    })
                    TriggerServerEvent('protector:detection:cheat', 'external_cheat', 'TZx')
                    return
                end
                Wait(250)
            else
                mightyCasual = 0
            end
        end
        
        ::continue::
    end
end)

-- Susano detection system (enhanced from your code)
local aP_inAloam = false
local aL_jelpeaB = false
local sP_passPc = false

CreateThread(function()
    Citizen.InvokeNative(0xFC695459D4D0E219, 0.78, 0.96)
    
    while true do
        Wait(2500)
        
        if not Config.Protection.AntiCheat.Enabled then
            Wait(5000)
            goto continue
        end
        
        local a, b = Citizen.InvokeNative(0xBDBA226F, Citizen.PointerValueInt(), Citizen.PointerValueInt())
        
        -- First stage detection
        if a ~= 1497 and b ~= 1036 then
            aP_inAloam = true
        end
        
        if aP_inAloam then
            if a == 1497 and b == 1036 then
                Citizen.InvokeNative(0xFC695459D4D0E219, 0.13, 0.43)
                aL_jelpeaB = true
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Susano Pattern Detected", {
                    stage = "first",
                    values = {a = a, b = b}
                })
            end
            
            -- Second stage detection
            if aL_jelpeaB then
                local y, o = Citizen.InvokeNative(0xBDBA226F, Citizen.PointerValueInt(), Citizen.PointerValueInt())
                if y ~= 249 and o ~= 464 then
                    sP_passPc = true
                end
                
                if sP_passPc then
                    if y == 249 and o == 464 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Susano Cheat Confirmed", {
                            stage = "final",
                            values = {y = y, o = o}
                        })
                        TriggerServerEvent('protector:detection:cheat', 'susano_cheat', 'confirmed')
                        return
                    end
                end
            end
        end
        
        ::continue::
    end
end)

-- Anti Eulen Spectate Detection (enhanced)
CreateThread(function()
    while true do
        Wait(5000)
        
        if not Config.Protection.AntiCheat.Enabled then
            Wait(5000)
            goto continue
        end
        
        -- Enhanced spectate detection
        Citizen.InvokeNative(0x423DE3854BB50894, true, GetPlayerPed(-1))
        Wait(100)
        local cur_spec = Citizen.InvokeNative(0x048746E388762E11)
        Wait(100)
        
        if not cur_spec then
            Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Eulen Spectate Detected", {
                method = "native_check",
                spectateState = cur_spec
            })
            TriggerServerEvent("protector:detection:spectate")
        end
        
        Citizen.InvokeNative(0x423DE3854BB50894, false, GetPlayerPed(-1))
        
        ::continue::
    end
end)

-- Global cheat menu detection
local function detectGlobalCheats()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Protection.AntiCheat.GlobalCheatDetection then
                Wait(5000)
                goto continue
            end
            
            -- Check for common cheat menu signatures
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            -- Detect unusual game state changes
            local isInvincible = false
            if GetPlayerInvincible then
                isInvincible = GetPlayerInvincible(PlayerId())
            end
            
            -- Additional check with GetEntityInvincible (if available)
            if GetEntityInvincible and not isInvincible then
                isInvincible = GetEntityInvincible(playerPed)
            end
            
            if isInvincible then
                detectionFlags.godmode = (detectionFlags.godmode or 0) + 1
                if detectionFlags.godmode > 3 then
                    TriggerServerEvent('protector:detection:cheat', 'godmode_bypass', 'global_menu')
                    detectionFlags.godmode = 0
                end
            else
                detectionFlags.godmode = math.max(0, (detectionFlags.godmode or 0) - 1)
            end
            
            -- Detect impossible movement speeds
            local velocity = GetEntityVelocity(playerPed)
            local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
            if speed > 50.0 and not IsPedInAnyVehicle(playerPed, false) then
                detectionFlags.speed = (detectionFlags.speed or 0) + 1
                if detectionFlags.speed > 5 then
                    TriggerServerEvent('protector:detection:cheat', 'speed_hack', 'excessive_speed')
                end
            else
                detectionFlags.speed = math.max(0, (detectionFlags.speed or 0) - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti Executor Detection
local function detectExecutors()
    CreateThread(function()
        while true do
            Wait(2000)
            
            if not Config.Protection.AntiCheat.ExecutorDetection then
                Wait(5000)
                goto continue
            end
            
            -- Check for executor signatures
            local luaState = collectgarbage("count")
            if luaState > 50000 then -- Abnormally high memory usage
                suspiciousActivity = suspiciousActivity + 1
                if suspiciousActivity > 10 then
                    TriggerServerEvent('protector:detection:cheat', 'executor_detected', 'high_memory_usage')
                    suspiciousActivity = 0
                end
            end
            
            -- Check for modified global environment
            if _G.debug or _G.load or _G.loadstring then
                TriggerServerEvent('protector:detection:cheat', 'executor_detected', 'debug_functions_present')
            end
            
            ::continue::
        end
    end)
end

-- Anti Dumper Detection
local function detectDumpers()
    CreateThread(function()
        while true do
            Wait(3000)
            
            if not Config.Protection.AntiCheat.DumperDetection then
                Wait(5000)
                goto continue
            end
            
            -- Check for dumping signatures
            local resourceName = GetCurrentResourceName()
            local startTime = GetGameTimer()
            
            -- Perform dummy operation to detect hooking
            for i = 1, 100 do
                local test = math.random(1, 1000)
            end
            
            local endTime = GetGameTimer()
            local executionTime = endTime - startTime
            
            -- If execution takes too long, might be hooked
            if executionTime > 50 then
                detectionFlags.dumper = (detectionFlags.dumper or 0) + 1
                if detectionFlags.dumper > 5 then
                    TriggerServerEvent('protector:detection:cheat', 'dumper_detected', 'execution_time_anomaly')
                end
            else
                detectionFlags.dumper = math.max(0, (detectionFlags.dumper or 0) - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti NUI DevTools Detection
local function detectNUIDevTools()
    CreateThread(function()
        while true do
            Wait(1500)
            
            if not Config.Protection.AntiCheat.NUIDevToolsDetection then
                Wait(5000)
                goto continue
            end
            
            -- Send NUI message to check for devtools
            SendNUIMessage({
                type = "devtools_check",
                timestamp = GetGameTimer()
            })
            
            ::continue::
        end
    end)
end

-- NUI Callback for devtools detection
RegisterNUICallback('devtools_detected', function(data, cb)
    if data.detected then
        TriggerServerEvent('protector:detection:cheat', 'nui_devtools', data.method or 'unknown')
    end
    cb('ok')
end)

-- Initialize all detection systems
CreateThread(function()
    Wait(5000) -- Wait for full initialization
    
    if Config.Protection.AntiCheat.Enabled then
        mL_cBaPm = true
        detectGlobalCheats()
        detectExecutors()
        detectDumpers()
        detectNUIDevTools()
        
        Logger.info("Advanced anticheat system initialized")
    end
end)

-- Reset detection flags periodically
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        -- Reset non-critical flags
        for flag, count in pairs(detectionFlags) do
            if count > 0 then
                detectionFlags[flag] = math.max(0, count - 1)
            end
        end
        
        suspiciousActivity = math.max(0, suspiciousActivity - 1)
    end
end)