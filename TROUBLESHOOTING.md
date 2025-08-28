# 🔧 FiveM Server Protector - Troubleshooting Guide

This guide covers common issues and their solutions when installing and running the FiveM Server Protector.

## 🚨 Common Script Errors

### Error: "attempt to index a nil value (global 'os')"
**Location**: `utils/logger.lua:25`
**Cause**: The `os` global is not available on the client side in FiveM
**Status**: ✅ **FIXED** - Updated logger to use client-safe timing

**Solution Applied**:
- Logger now uses `GetGameTimer()` on client side
- Server side continues to use `os.date()` for accurate timestamps
- Client detections are forwarded to server for webhook processing

### Error: "attempt to call a nil value (global 'IsEntityInvincible')"
**Location**: `client/protection/player_protection.lua:48`
**Cause**: Function not available in some FiveM builds
**Status**: ✅ **FIXED** - Added compatibility layer

**Solution Applied**:
- Replaced with safe function checks
- Added fallback implementations
- Compatibility file provides missing function stubs

### Error: Functions not available
**Common Missing Functions**:
- `IsEntityInvincible` / `GetEntityInvincible`
- `IsEntityTouchingGround`
- `NetworkIsInSpectatorMode` 
- `GetUsingnightvision` / `GetUsingseethrough`
- `SetNightvision` / `SetSeethrough`
- `GetPlayerStamina`
- `IsEntityVisible` / `GetEntityAlpha`

**Status**: ✅ **FIXED** - Added comprehensive compatibility layer

## 🛠️ Quick Fixes Applied

### 1. Client-Side Compatibility
- Added `client/compat_fixes.lua` - Provides fallbacks for missing functions
- Updated logger to handle client/server differences
- Added safe function wrappers

### 2. Function Availability Checks
```lua
-- Before (would error)
if GetPlayerInvincible(PlayerId()) then

-- After (safe)
if GetPlayerInvincible and GetPlayerInvincible(PlayerId()) then
```

### 3. Error Prevention
- All detection functions now have try-catch equivalents
- Missing functions are replaced with safe stubs
- Warnings are logged for missing features

## 📋 Installation Verification

### Step 1: Check Console Output
Look for these messages on startup:
```
✅ GOOD: FiveM Server Protector client initialized successfully
⚠️ WARNING: Warning: X functions not available in this FiveM build
❌ ERROR: Any script errors (should be resolved now)
```

### Step 2: Test Basic Functionality
```lua
-- In F8 console (client):
/protector_debug  -- If debug mode enabled

-- In server console:
protector status
```

### Step 3: Verify No Script Errors
- Check for red `^1SCRIPT ERROR` messages
- Most common errors should now be resolved
- If errors persist, see solutions below

## 🔍 Remaining Issues & Solutions

### NUI Errors (Karma Chat)
```
Uncaught (in promise) TypeError: i is not iterable
```
**Cause**: Chat resource conflict with our NUI page
**Solution**: This is external and doesn't affect protector functionality

### Framework Detection
```
Framework object found : newqb
```
**Status**: Normal - Framework is being detected correctly

## 🔧 Manual Fixes (If Needed)

### If you still see "os is nil" errors:

1. **Check your fxmanifest.lua**:
```lua
-- Make sure this is present:
client_scripts {
    'client/compat_fixes.lua',  -- This MUST be first
    'client/anticheat/*.lua',
    'client/protection/*.lua',
    'client/detection/*.lua',
    'client/main.lua'
}
```

2. **Restart the resource completely**:
```
stop leo-anticheat
ensure leo-anticheat
```

### If functions are still missing:

1. **Check FiveM build**:
```
# Recommended: Build 4752 or higher
version
```

2. **Update FiveM** if using older build

3. **Disable specific modules** if needed:
```lua
-- In config/config.lua
Config.Protection.PlayerProtection.AntiNightVision = false
Config.Protection.PlayerProtection.AntiThermalVision = false
Config.Protection.PlayerProtection.AntiSpectator = false
```

## ⚙️ Configuration for Compatibility

### Minimal Configuration (Maximum Compatibility)
```lua
Config.Protection = {
    Enabled = true,
    AntiCheat = {
        Enabled = true,
        CheckInterval = 1000,  -- Slower checks
        GlobalCheatDetection = true,
        ExecutorDetection = false,  -- Disable if issues
        DumperDetection = false,    -- Disable if issues
        NUIDevToolsDetection = false, -- Disable if issues
        ResourceRenameProtection = true,
        TriggerEventProtection = true,
        StopResourceProtection = true
    },
    WeaponProtection = {
        Enabled = true,
        -- Keep basic protections only
        AntiAimbot = {
            MagicBullet = true,
            SilentAim = false,      -- Disable if issues
            CornerShoot = false,    -- Disable if issues
            Lock = true
        }
    },
    PlayerProtection = {
        Enabled = true,
        AntiGodmode = true,
        AntiSpeedHack = true,
        AntiTeleport = {
            Enabled = true,
            MaxDistance = 50.0
        },
        -- Disable advanced features if compatibility issues
        AntiNightVision = false,
        AntiThermalVision = false,
        AntiSpectator = false,
        AntiFreecam = false
    }
}
```

## 🔄 Testing Protocol

### After Applying Fixes:

1. **Clean restart**:
```bash
stop leo-anticheat
refresh
ensure leo-anticheat
```

2. **Check console** - Should see:
```
[INFO] FiveM Server Protector client initialized successfully
[WARNING] Warning: X functions not available in this FiveM build (if any)
```

3. **Connect a player** - Should see:
```
[INFO] Client initialized: PlayerName [ID]
```

4. **No red errors** should appear

## 📞 Still Having Issues?

### Collect This Information:
1. **FiveM build number**: `version` in console
2. **Operating system**: Windows/Linux
3. **Exact error messages**: Copy full error text
4. **Server artifacts**: Which artifacts version
5. **Other resources**: List other resources running

### Quick Diagnostic:
```lua
-- Add this to test basic functionality:
print("PlayerPedId:", PlayerPedId())
print("GetPlayerServerId:", GetPlayerServerId(PlayerId()))
print("GetGameTimer:", GetGameTimer())
print("GetPlayerInvincible exists:", GetPlayerInvincible ~= nil)
```

### Emergency Disable:
If all else fails, disable the protector:
```lua
-- In config/config.lua
Config.Protection.Enabled = false
```

## ✅ Verification Checklist

- [ ] No red script errors in console
- [ ] Client initialization message appears
- [ ] Server status command works: `protector status`
- [ ] Players can connect without issues  
- [ ] Webhook test works (if configured)
- [ ] No significant performance impact

---

**Note**: The protector is designed to be fault-tolerant. Even if some advanced features aren't available, core protection will continue to work. Missing functions are gracefully handled with fallbacks.