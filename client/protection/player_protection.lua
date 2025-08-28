-- Player Protection System
-- Comprehensive player-based cheat detection and prevention

local playerStats = {
    lastPosition = nil,
    lastHealth = 200,
    lastArmour = 100,
    lastStamina = 100,
    speedChecks = 0,
    teleportChecks = 0,
    healthChecks = 0,
    godmodeChecks = 0,
    lastVehicle = nil,
    suspiciousJumps = 0
}

local protectionFlags = {}
local lastFlagReset = GetGameTimer()

-- Initialize player protection
CreateThread(function()
    Wait(3000)
    
    if Config.Protection.PlayerProtection.Enabled then
        local playerPed = PlayerPedId()
        playerStats.lastPosition = GetEntityCoords(playerPed)
        playerStats.lastHealth = GetEntityHealth(playerPed)
        playerStats.lastArmour = GetPedArmour(playerPed)
        
        Logger.info("Player protection system initialized")
    end
end)

-- Anti Godmode Detection
local function detectGodmode()
    CreateThread(function()
        while true do
            Wait(2000)
            
            if not Config.Protection.PlayerProtection.AntiGodmode then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentHealth = GetEntityHealth(playerPed)
            local isInvincible = false
            
            -- Safe call to GetPlayerInvincible
            if GetPlayerInvincible then
                isInvincible = GetPlayerInvincible(PlayerId())
            end
            
            -- Additional check with GetEntityInvincible (if available)
            if GetEntityInvincible and not isInvincible then
                isInvincible = GetEntityInvincible(playerPed)
            end
            
            -- Check for invincibility flags
            if isInvincible then
                protectionFlags.godmode = (protectionFlags.godmode or 0) + 1
                if protectionFlags.godmode > 3 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Godmode Detection", {
                        isInvincible = isInvincible,
                        health = currentHealth
                    })
                    TriggerServerEvent('protector:detection:player', 'godmode', {type = 'invincible_flag'})
                    protectionFlags.godmode = 0
                end
            else
                protectionFlags.godmode = math.max(0, (protectionFlags.godmode or 0) - 1)
            end
            
            -- Check for health anomalies
            if currentHealth > 200 then -- Max health is typically 200
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Health Hack Detection", {
                    currentHealth = currentHealth,
                    maxHealth = 200
                })
                TriggerServerEvent('protector:detection:player', 'health_hack', {health = currentHealth})
            end
            
            playerStats.lastHealth = currentHealth
            
            ::continue::
        end
    end)
end

-- Anti Speed Hack Detection
local function detectSpeedHack()
    CreateThread(function()
        while true do
            Wait(500)
            
            if not Config.Protection.PlayerProtection.AntiSpeedHack then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentPos = GetEntityCoords(playerPed)
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            
            if playerStats.lastPosition then
                local distance = #(currentPos - playerStats.lastPosition)
                local timeElapsed = 0.5 -- 500ms
                local speed = distance / timeElapsed
                
                -- Different thresholds for on foot vs in vehicle
                local maxSpeed = isInVehicle and 120.0 or 15.0 -- m/s
                
                if speed > maxSpeed then
                    playerStats.speedChecks = playerStats.speedChecks + 1
                    if playerStats.speedChecks > 3 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Speed Hack Detection", {
                            speed = speed,
                            maxSpeed = maxSpeed,
                            distance = distance,
                            isInVehicle = isInVehicle
                        })
                        TriggerServerEvent('protector:detection:player', 'speed_hack', {
                            speed = speed,
                            maxSpeed = maxSpeed
                        })
                        playerStats.speedChecks = 0
                    end
                else
                    playerStats.speedChecks = math.max(0, playerStats.speedChecks - 1)
                end
            end
            
            playerStats.lastPosition = currentPos
            
            ::continue::
        end
    end)
end

-- Anti Teleport Detection
local function detectTeleport()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Protection.PlayerProtection.AntiTeleport.Enabled then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentPos = GetEntityCoords(playerPed)
            local isInVehicle = IsPedInAnyVehicle(playerPed, false)
            
            if playerStats.lastPosition then
                local distance = #(currentPos - playerStats.lastPosition)
                local maxDistance = Config.Protection.PlayerProtection.AntiTeleport.MaxDistance or 50.0
                
                -- Increase threshold if in vehicle
                if isInVehicle then
                    maxDistance = maxDistance * 2
                end
                
                if distance > maxDistance then
                    playerStats.teleportChecks = playerStats.teleportChecks + 1
                    if playerStats.teleportChecks > 2 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Teleport Detection", {
                            distance = distance,
                            maxDistance = maxDistance,
                            fromPos = playerStats.lastPosition,
                            toPos = currentPos
                        })
                        TriggerServerEvent('protector:detection:player', 'teleport', {
                            distance = distance,
                            maxDistance = maxDistance
                        })
                        playerStats.teleportChecks = 0
                    end
                else
                    playerStats.teleportChecks = math.max(0, playerStats.teleportChecks - 1)
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti Super Jump Detection
local function detectSuperJump()
    CreateThread(function()
        while true do
            Wait(100)
            
            if not Config.Protection.PlayerProtection.AntiSuperJump then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local velocity = GetEntityVelocity(playerPed)
            local isOnGround = true
            
            -- Safe call to IsEntityTouchingGround
            if IsEntityTouchingGround then
                isOnGround = IsEntityTouchingGround(playerPed)
            end
            
            -- Check for abnormal upward velocity
            if velocity.z > 10.0 and not isOnGround then
                playerStats.suspiciousJumps = playerStats.suspiciousJumps + 1
                if playerStats.suspiciousJumps > 3 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Super Jump Detection", {
                        velocity = velocity,
                        isOnGround = isOnGround
                    })
                    TriggerServerEvent('protector:detection:player', 'super_jump', {velocity = velocity.z})
                    playerStats.suspiciousJumps = 0
                end
            else
                playerStats.suspiciousJumps = math.max(0, playerStats.suspiciousJumps - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti Invisible Detection
local function detectInvisible()
    CreateThread(function()
        while true do
            Wait(3000)
            
            if not Config.Protection.PlayerProtection.AntiInvisible then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local alpha = 255
            local isVisible = true
            
            -- Safe calls to visibility functions
            if GetEntityAlpha then
                alpha = GetEntityAlpha(playerPed)
            end
            
            if IsEntityVisible then
                isVisible = IsEntityVisible(playerPed)
            end
            
            if alpha < 100 or not isVisible then
                protectionFlags.invisible = (protectionFlags.invisible or 0) + 1
                if protectionFlags.invisible > 2 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Invisible Detection", {
                        alpha = alpha,
                        isVisible = isVisible
                    })
                    TriggerServerEvent('protector:detection:player', 'invisible', {alpha = alpha})
                    protectionFlags.invisible = 0
                end
            else
                protectionFlags.invisible = math.max(0, (protectionFlags.invisible or 0) - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti Noclip Detection
local function detectNoclip()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Protection.PlayerProtection.AntiNoclip then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local velocity = GetEntityVelocity(playerPed)
            local isOnGround = true
            
            -- Safe call to IsEntityTouchingGround
            if IsEntityTouchingGround then
                isOnGround = IsEntityTouchingGround(playerPed)
            end
            
            -- Check if player is moving through solid objects
            if not isOnGround and velocity.z == 0.0 and (velocity.x ~= 0.0 or velocity.y ~= 0.0) then
                local hit, _, _, _, materialHash = GetShapeTestResult(
                    StartShapeTestCapsule(
                        playerCoords.x, playerCoords.y, playerCoords.z,
                        playerCoords.x, playerCoords.y, playerCoords.z - 2.0,
                        1.0, 1, playerPed, 7
                    )
                )
                
                if not hit then -- No ground detected but player is moving horizontally
                    protectionFlags.noclip = (protectionFlags.noclip or 0) + 1
                    if protectionFlags.noclip > 3 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Noclip Detection", {
                            velocity = velocity,
                            isOnGround = isOnGround,
                            coords = playerCoords
                        })
                        TriggerServerEvent('protector:detection:player', 'noclip', {coords = playerCoords})
                        protectionFlags.noclip = 0
                    end
                else
                    protectionFlags.noclip = math.max(0, (protectionFlags.noclip or 0) - 1)
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti Stamina Hack Detection
local function detectStaminaHack()
    CreateThread(function()
        while true do
            Wait(2000)
            
            if not (Config.Protection.PlayerProtection.AntiStaminaHack or Config.Protection.PlayerProtection.AntiInfiniteStamina) then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentStamina = 100.0
            local isRunning = IsPedRunning(playerPed) or IsPedSprinting(playerPed)
            
            -- Safe call to GetPlayerStamina
            if GetPlayerStamina then
                currentStamina = GetPlayerStamina(PlayerId())
            end
            
            -- Check for infinite stamina
            if Config.Protection.PlayerProtection.AntiInfiniteStamina and isRunning then
                if currentStamina >= playerStats.lastStamina and currentStamina > 90 then
                    protectionFlags.infiniteStamina = (protectionFlags.infiniteStamina or 0) + 1
                    if protectionFlags.infiniteStamina > 5 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Infinite Stamina Detection", {
                            stamina = currentStamina,
                            isRunning = isRunning
                        })
                        TriggerServerEvent('protector:detection:player', 'infinite_stamina', {stamina = currentStamina})
                        protectionFlags.infiniteStamina = 0
                    end
                else
                    protectionFlags.infiniteStamina = math.max(0, (protectionFlags.infiniteStamina or 0) - 1)
                end
            end
            
            playerStats.lastStamina = currentStamina
            
            ::continue::
        end
    end)
end

-- Anti Freecam Detection
local function detectFreecam()
    CreateThread(function()
        while true do
            Wait(1500)
            
            if not Config.Protection.PlayerProtection.AntiFreecam then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local camCoords = GetGameplayCamCoord()
            local distance = #(playerCoords - camCoords)
            
            -- Check if camera is too far from player
            if distance > 50.0 then
                protectionFlags.freecam = (protectionFlags.freecam or 0) + 1
                if protectionFlags.freecam > 3 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Freecam Detection", {
                        distance = distance,
                        playerCoords = playerCoords,
                        camCoords = camCoords
                    })
                    TriggerServerEvent('protector:detection:player', 'freecam', {distance = distance})
                    protectionFlags.freecam = 0
                end
            else
                protectionFlags.freecam = math.max(0, (protectionFlags.freecam or 0) - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti Spectator Detection
local function detectSpectator()
    CreateThread(function()
        while true do
            Wait(2000)
            
            if not Config.Protection.PlayerProtection.AntiSpectator then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local isPlayerDead = IsPlayerDead(PlayerId())
            local isSpectating = false
            
            -- Safe call to NetworkIsInSpectatorMode
            if NetworkIsInSpectatorMode then
                isSpectating = NetworkIsInSpectatorMode()
            end
            
            if isSpectating and not isPlayerDead then
                protectionFlags.spectator = (protectionFlags.spectator or 0) + 1
                if protectionFlags.spectator > 2 then
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Spectator Mode Detection", {
                        isSpectating = isSpectating,
                        isDead = isPlayerDead
                    })
                    TriggerServerEvent('protector:detection:player', 'spectator', {})
                    protectionFlags.spectator = 0
                end
            else
                protectionFlags.spectator = math.max(0, (protectionFlags.spectator or 0) - 1)
            end
            
            ::continue::
        end
    end)
end

-- Anti Vision Hacks (Night Vision, Thermal Vision)
local function detectVisionHacks()
    CreateThread(function()
        while true do
            Wait(3000)
            
            if not (Config.Protection.PlayerProtection.AntiNightVision or Config.Protection.PlayerProtection.AntiThermalVision) then
                Wait(5000)
                goto continue
            end
            
            local hasNightVision = false
            local hasThermalVision = false
            
            -- Safe calls to vision functions
            if GetUsingnightvision then
                hasNightVision = GetUsingnightvision()
            end
            
            if GetUsingseethrough then
                hasThermalVision = GetUsingseethrough()
            end
            
            if Config.Protection.PlayerProtection.AntiNightVision and hasNightVision then
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Night Vision Detection", {
                    hasNightVision = hasNightVision
                })
                TriggerServerEvent('protector:detection:player', 'night_vision', {})
                if SetNightvision then
                    SetNightvision(false)
                end
            end
            
            if Config.Protection.PlayerProtection.AntiThermalVision and hasThermalVision then
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Thermal Vision Detection", {
                    hasThermalVision = hasThermalVision
                })
                TriggerServerEvent('protector:detection:player', 'thermal_vision', {})
                if SetSeethrough then
                    SetSeethrough(false)
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti VDM (Vehicle Death Match) Detection
local function detectVDM()
    CreateThread(function()
        while true do
            Wait(500)
            
            if not Config.Protection.PlayerProtection.AntiVDM then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle and vehicle ~= 0 then
                local velocity = GetEntityVelocity(vehicle)
                local speed = #velocity
                
                -- Check for high-speed collisions
                if speed > 30.0 then -- High speed threshold
                    local nearbyPeds = GetNearbyPeds(GetEntityCoords(playerPed), 10.0)
                    for _, ped in ipairs(nearbyPeds) do
                        if ped ~= playerPed and not IsPedInAnyVehicle(ped, false) then
                            protectionFlags.vdm = (protectionFlags.vdm or 0) + 1
                            if protectionFlags.vdm > 2 then
                                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "VDM Detection", {
                                    speed = speed,
                                    vehicle = vehicle,
                                    targetPed = ped
                                })
                                TriggerServerEvent('protector:detection:player', 'vdm', {speed = speed})
                                protectionFlags.vdm = 0
                            end
                            break
                        end
                    end
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti Ped Change Detection
local function detectPedChange()
    CreateThread(function()
        local originalModel = nil
        
        while true do
            Wait(2000)
            
            if not Config.Protection.PlayerProtection.AntiPedChange then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentModel = GetEntityModel(playerPed)
            
            if not originalModel then
                originalModel = currentModel
            elseif currentModel ~= originalModel then
                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Ped Change Detection", {
                    originalModel = originalModel,
                    currentModel = currentModel
                })
                TriggerServerEvent('protector:detection:player', 'ped_change', {
                    originalModel = originalModel,
                    currentModel = currentModel
                })
            end
            
            ::continue::
        end
    end)
end

-- Utility function to get nearby peds
function GetNearbyPeds(coords, radius)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success
    
    repeat
        local pedCoords = GetEntityCoords(ped)
        local distance = #(coords - pedCoords)
        
        if distance <= radius then
            table.insert(peds, ped)
        end
        
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    return peds
end

-- Initialize all player protection systems
if Config.Protection.PlayerProtection.Enabled then
    detectGodmode()
    detectSpeedHack()
    detectTeleport()
    detectSuperJump()
    detectInvisible()
    detectNoclip()
    detectStaminaHack()
    detectFreecam()
    detectSpectator()
    detectVisionHacks()
    detectVDM()
    detectPedChange()
end

-- Reset protection flags periodically
CreateThread(function()
    while true do
        Wait(60000) -- Reset every minute
        
        for flag, count in pairs(protectionFlags) do
            if count > 0 then
                protectionFlags[flag] = math.max(0, count - 1)
            end
        end
        
        -- Reset player stats
        playerStats.speedChecks = math.max(0, playerStats.speedChecks - 1)
        playerStats.teleportChecks = math.max(0, playerStats.teleportChecks - 1)
        playerStats.suspiciousJumps = math.max(0, playerStats.suspiciousJumps - 1)
    end
end)