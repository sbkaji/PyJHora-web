-- Weapon Protection System
-- Comprehensive weapon-based cheat detection and prevention

local weaponStats = {}
local lastWeaponCheck = 0
local shotsFired = {}
local lastShotTime = {}
local damageDealt = {}
local weaponSwitchCount = 0
local lastWeaponSwitch = 0

-- Initialize weapon protection
CreateThread(function()
    Wait(3000)
    
    if Config.Protection.WeaponProtection.Enabled then
        Logger.info("Weapon protection system initialized")
    end
end)

-- Anti Aimbot Detection
local function detectAimbot()
    CreateThread(function()
        while true do
            Wait(50) -- High frequency check for aimbot
            
            if not Config.Protection.WeaponProtection.Enabled then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if currentWeapon and currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                local isAiming = IsPlayerFreeAiming(PlayerId())
                local isShooting = IsPedShooting(playerPed)
                
                if isAiming or isShooting then
                    local camCoords = GetGameplayCamCoord()
                    local camRot = GetGameplayCamRot(0)
                    local forwardVector = RotationToDirection(camRot)
                    local endCoords = camCoords + (forwardVector * 1000.0)
                    
                    -- Magic Bullet Detection
                    if Config.Protection.WeaponProtection.AntiAimbot.MagicBullet then
                        local hit, hitCoords, hitEntity = RaycastFromCamera(camCoords, endCoords)
                        if hit and hitEntity and IsEntityAPed(hitEntity) and hitEntity ~= playerPed then
                            local distance = #(GetEntityCoords(playerPed) - hitCoords)
                            local weaponRange = GetWeaponRange(currentWeapon)
                            
                            if distance > weaponRange * 1.5 then
                                Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Magic Bullet Detection", {
                                    weapon = currentWeapon,
                                    distance = distance,
                                    maxRange = weaponRange
                                })
                                TriggerServerEvent('protector:detection:aimbot', 'magic_bullet', {distance = distance})
                            end
                        end
                    end
                    
                    -- Silent Aim Detection
                    if Config.Protection.WeaponProtection.AntiAimbot.SilentAim and isShooting then
                        local weaponCoords = GetPedBoneCoords(playerPed, 57005, 0.0, 0.0, 0.0) -- Right hand
                        local targetCoords = endCoords
                        local angleDifference = GetAngleBetweenVectors(camCoords, targetCoords, weaponCoords, targetCoords)
                        
                        if angleDifference > 45.0 then -- Suspicious angle difference
                            Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Silent Aim Detection", {
                                weapon = currentWeapon,
                                angleDifference = angleDifference
                            })
                            TriggerServerEvent('protector:detection:aimbot', 'silent_aim', {angle = angleDifference})
                        end
                    end
                    
                    -- Corner Shoot Detection
                    if Config.Protection.WeaponProtection.AntiAimbot.CornerShoot then
                        local playerCoords = GetEntityCoords(playerPed)
                        local hit, _, _, _, materialHash = GetShapeTestResult(StartShapeTestCapsule(playerCoords.x, playerCoords.y, playerCoords.z, endCoords.x, endCoords.y, endCoords.z, 0.5, 1, playerPed, 7))
                        
                        if hit and isShooting then
                            -- Check if shooting through walls
                            Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Corner Shoot Detection", {
                                weapon = currentWeapon,
                                materialHash = materialHash
                            })
                            TriggerServerEvent('protector:detection:aimbot', 'corner_shoot', {material = materialHash})
                        end
                    end
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti Damage Modifier
local function detectDamageModifier()
    CreateThread(function()
        while true do
            Wait(1000)
            
            if not Config.Protection.WeaponProtection.AntiDamageModifier then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if currentWeapon and currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                local weaponDamage = GetWeaponDamage(currentWeapon, 0)
                local storedDamage = weaponStats[currentWeapon] and weaponStats[currentWeapon].damage
                
                if not storedDamage then
                    weaponStats[currentWeapon] = {damage = weaponDamage}
                elseif weaponDamage > storedDamage * 1.5 then -- 50% increase threshold
                    Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Damage Modifier Detection", {
                        weapon = currentWeapon,
                        originalDamage = storedDamage,
                        currentDamage = weaponDamage
                    })
                    TriggerServerEvent('protector:detection:weapon', 'damage_modifier', {originalDamage = storedDamage, currentDamage = weaponDamage})
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti Infinite Ammo Detection
local function detectInfiniteAmmo()
    CreateThread(function()
        while true do
            Wait(2000)
            
            if not Config.Protection.WeaponProtection.AntiInfiniteAmmo then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if currentWeapon and currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon)
                local maxAmmo = GetMaxAmmo(playerPed, currentWeapon)
                
                if not weaponStats[currentWeapon] then
                    weaponStats[currentWeapon] = {lastAmmo = currentAmmo}
                else
                    local lastAmmo = weaponStats[currentWeapon].lastAmmo
                    local shotsFiredSinceCheck = (shotsFired[currentWeapon] or 0)
                    
                    -- If ammo didn't decrease despite shots fired
                    if shotsFiredSinceCheck > 0 and currentAmmo >= lastAmmo then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Infinite Ammo Detection", {
                            weapon = currentWeapon,
                            shotsFired = shotsFiredSinceCheck,
                            currentAmmo = currentAmmo,
                            lastAmmo = lastAmmo
                        })
                        TriggerServerEvent('protector:detection:weapon', 'infinite_ammo', {shotsFired = shotsFiredSinceCheck})
                    end
                    
                    weaponStats[currentWeapon].lastAmmo = currentAmmo
                    shotsFired[currentWeapon] = 0
                end
            end
            
            ::continue::
        end
    end)
end

-- Anti No Recoil Detection
local function detectNoRecoil()
    CreateThread(function()
        while true do
            Wait(100)
            
            if not Config.Protection.WeaponProtection.AntiNoRecoil then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            
            if IsPedShooting(playerPed) then
                local currentWeapon = GetSelectedPedWeapon(playerPed)
                local camRot = GetGameplayCamRot(0)
                
                if not weaponStats[currentWeapon] then
                    weaponStats[currentWeapon] = {lastRotation = camRot, shotCount = 0}
                else
                    local lastRot = weaponStats[currentWeapon].lastRotation
                    local rotDifference = math.abs(camRot.x - lastRot.x) + math.abs(camRot.y - lastRot.y)
                    
                    weaponStats[currentWeapon].shotCount = weaponStats[currentWeapon].shotCount + 1
                    
                    -- If rotation barely changes despite continuous shooting
                    if weaponStats[currentWeapon].shotCount > 10 and rotDifference < 1.0 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "No Recoil Detection", {
                            weapon = currentWeapon,
                            shotCount = weaponStats[currentWeapon].shotCount,
                            rotationDifference = rotDifference
                        })
                        TriggerServerEvent('protector:detection:weapon', 'no_recoil', {shotCount = weaponStats[currentWeapon].shotCount})
                        weaponStats[currentWeapon].shotCount = 0
                    end
                    
                    weaponStats[currentWeapon].lastRotation = camRot
                end
                
                -- Track shots fired
                shotsFired[currentWeapon] = (shotsFired[currentWeapon] or 0) + 1
            end
            
            ::continue::
        end
    end)
end

-- Anti Weapon Give/Remove Detection
local function detectWeaponManipulation()
    CreateThread(function()
        local lastWeaponHash = nil
        
        while true do
            Wait(1000)
            
            if not (Config.Protection.WeaponProtection.AntiGiveWeapon or Config.Protection.WeaponProtection.AntiRemoveWeapon) then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if lastWeaponHash and lastWeaponHash ~= currentWeapon then
                weaponSwitchCount = weaponSwitchCount + 1
                local currentTime = GetGameTimer()
                
                -- Check for rapid weapon switching (possible menu usage)
                if lastWeaponSwitch and currentTime - lastWeaponSwitch < 500 then
                    if weaponSwitchCount > 5 then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Rapid Weapon Switch Detection", {
                            switchCount = weaponSwitchCount,
                            timeFrame = currentTime - lastWeaponSwitch
                        })
                        TriggerServerEvent('protector:detection:weapon', 'rapid_switch', {count = weaponSwitchCount})
                        weaponSwitchCount = 0
                    end
                else
                    weaponSwitchCount = 1
                end
                
                lastWeaponSwitch = currentTime
                
                -- Check for blacklisted weapons
                for _, blacklistedWeapon in ipairs(Config.Protection.WeaponProtection.BlacklistWeapons or {}) do
                    if currentWeapon == GetHashKey(blacklistedWeapon) then
                        Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Blacklisted Weapon Detection", {
                            weapon = blacklistedWeapon,
                            weaponHash = currentWeapon
                        })
                        TriggerServerEvent('protector:detection:weapon', 'blacklisted_weapon', {weapon = blacklistedWeapon})
                        RemoveWeaponFromPed(playerPed, currentWeapon)
                    end
                end
            end
            
            lastWeaponHash = currentWeapon
            
            ::continue::
        end
    end)
end

-- Anti Reload Hack Detection
local function detectReloadHack()
    CreateThread(function()
        while true do
            Wait(500)
            
            if not Config.Protection.WeaponProtection.AntiReloadHack then
                Wait(5000)
                goto continue
            end
            
            local playerPed = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            
            if currentWeapon and currentWeapon ~= GetHashKey("WEAPON_UNARMED") then
                if IsPlayerFreeAiming(PlayerId()) and IsPedReloading(playerPed) then
                    local reloadTime = GetWeaponTimeToReload(currentWeapon)
                    local currentTime = GetGameTimer()
                    
                    if not weaponStats[currentWeapon] then
                        weaponStats[currentWeapon] = {reloadStartTime = currentTime}
                    elseif weaponStats[currentWeapon].reloadStartTime then
                        local actualReloadTime = currentTime - weaponStats[currentWeapon].reloadStartTime
                        
                        if actualReloadTime < reloadTime * 0.5 then -- 50% faster than normal
                            Logger.logDetection(GetPlayerName(PlayerId()), GetPlayerServerId(PlayerId()), "Reload Hack Detection", {
                                weapon = currentWeapon,
                                normalReloadTime = reloadTime,
                                actualReloadTime = actualReloadTime
                            })
                            TriggerServerEvent('protector:detection:weapon', 'reload_hack', {
                                normalTime = reloadTime,
                                actualTime = actualReloadTime
                            })
                        end
                        
                        weaponStats[currentWeapon].reloadStartTime = nil
                    end
                end
            end
            
            ::continue::
        end
    end)
end

-- Utility functions
function RaycastFromCamera(startCoords, endCoords)
    local raycast = StartShapeTestRay(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y, endCoords.z, -1, PlayerPedId(), 0)
    local hit, hitCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResult(raycast)
    return hit, hitCoords, entityHit, surfaceNormal, materialHash
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

function GetAngleBetweenVectors(pos1, pos2, pos3, pos4)
    local vec1 = pos2 - pos1
    local vec2 = pos4 - pos3
    local dot = vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
    local mag1 = math.sqrt(vec1.x^2 + vec1.y^2 + vec1.z^2)
    local mag2 = math.sqrt(vec2.x^2 + vec2.y^2 + vec2.z^2)
    local cos_angle = dot / (mag1 * mag2)
    return math.deg(math.acos(math.max(-1, math.min(1, cos_angle))))
end

function GetWeaponRange(weaponHash)
    -- Simplified weapon range mapping
    local ranges = {
        [GetHashKey("WEAPON_PISTOL")] = 50.0,
        [GetHashKey("WEAPON_SMG")] = 80.0,
        [GetHashKey("WEAPON_ASSAULTRIFLE")] = 150.0,
        [GetHashKey("WEAPON_SNIPERRIFLE")] = 300.0,
    }
    return ranges[weaponHash] or 100.0
end

function GetWeaponTimeToReload(weaponHash)
    -- Simplified reload time mapping
    local reloadTimes = {
        [GetHashKey("WEAPON_PISTOL")] = 1500,
        [GetHashKey("WEAPON_SMG")] = 2000,
        [GetHashKey("WEAPON_ASSAULTRIFLE")] = 2500,
        [GetHashKey("WEAPON_SNIPERRIFLE")] = 3000,
    }
    return reloadTimes[weaponHash] or 2000
end

-- Initialize all weapon protection systems
if Config.Protection.WeaponProtection.Enabled then
    detectAimbot()
    detectDamageModifier()
    detectInfiniteAmmo()
    detectNoRecoil()
    detectWeaponManipulation()
    detectReloadHack()
end

-- Reset weapon stats periodically
CreateThread(function()
    while true do
        Wait(60000) -- Reset every minute
        
        for weapon, stats in pairs(weaponStats) do
            if stats.shotCount then
                stats.shotCount = math.max(0, stats.shotCount - 5)
            end
        end
        
        weaponSwitchCount = math.max(0, weaponSwitchCount - 1)
    end
end)