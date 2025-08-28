# 📋 FiveM Server Protector - Installation Guide

This guide will walk you through the complete installation and configuration process for the FiveM Server Protector.

## 📋 Table of Contents
1. [System Requirements](#system-requirements)
2. [Quick Installation](#quick-installation)
3. [Detailed Configuration](#detailed-configuration)
4. [Discord Webhook Setup](#discord-webhook-setup)
5. [Database Setup (Optional)](#database-setup-optional)
6. [Admin Permissions](#admin-permissions)
7. [Testing the Installation](#testing-the-installation)
8. [Optimization](#optimization)
9. [Troubleshooting](#troubleshooting)

## 🔧 System Requirements

### Minimum Requirements
- **FiveM Server Build**: 4752 or higher
- **OS**: Windows 10/11, Linux (Ubuntu 18.04+), or macOS
- **RAM**: 2GB available for the protector
- **Storage**: 100MB free space
- **Network**: Stable internet connection for webhooks

### Recommended Requirements
- **FiveM Server Build**: Latest stable release
- **RAM**: 4GB+ available
- **CPU**: Multi-core processor
- **Database**: MySQL 5.7+ or MariaDB 10.3+

### Dependencies
- **Required**: None (all dependencies included)
- **Optional**: 
  - MySQL/MariaDB for advanced logging
  - `mysql-async` resource for database integration

## 🚀 Quick Installation

### Step 1: Download the Resource
```bash
# Navigate to your resources folder
cd /path/to/your/fivem/server/resources

# Clone or download the protector
git clone https://github.com/your-repo/fivem-protector.git fivem-protector

# Alternative: Extract downloaded ZIP file
unzip fivem-protector.zip
mv fivem-protector-main fivem-protector
```

### Step 2: Basic Configuration
```lua
-- Edit config/config.lua
Config.Protection.Enabled = true
Config.Webhook.URL = "YOUR_DISCORD_WEBHOOK_URL"  -- Get this from Discord
```

### Step 3: Update server.cfg
```cfg
# Add to your server.cfg file
ensure fivem-protector

# Basic admin permissions
add_ace group.admin protector.admin allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin
```

### Step 4: Start Server
```bash
# Start your FiveM server
# The protector will automatically initialize
```

## ⚙️ Detailed Configuration

### Core Protection Settings

#### Anti-Cheat Configuration
```lua
Config.Protection.AntiCheat = {
    Enabled = true,
    CheckInterval = 500,  -- Milliseconds between checks (lower = more frequent)
    GlobalCheatDetection = true,
    ExecutorDetection = true,
    DumperDetection = true,
    NUIDevToolsDetection = true,
    ResourceRenameProtection = true,
    TriggerEventProtection = true,
    StopResourceProtection = true
}
```

#### Weapon Protection Settings
```lua
Config.Protection.WeaponProtection = {
    Enabled = true,
    AntiAimbot = {
        MagicBullet = true,
        SilentAim = true,
        CornerShoot = true,
        Lock = true
    },
    AntiReloadHack = true,
    AntiDamageModifier = true,
    AntiInfiniteAmmo = true,
    AntiNoRecoil = true,
    BlacklistWeapons = {
        "WEAPON_RAILGUN",
        "WEAPON_MINIGUN",
        "WEAPON_RPG"
    },
    BlacklistVehicles = {
        "HYDRA",
        "LAZER",
        "RHINO"
    }
}
```

#### Player Protection Settings
```lua
Config.Protection.PlayerProtection = {
    Enabled = true,
    AntiGodmode = true,
    AntiSpeedHack = true,
    AntiTeleport = {
        Enabled = true,
        MaxDistance = 50.0  -- Meters
    },
    AntiNoclip = true,
    AntiInvisible = true,
    BlacklistWords = {
        "cheat",
        "hack",
        "exploit"
    },
    BlacklistCommands = {
        "give",
        "spawn",
        "teleport"
    }
}
```

### Firewall Configuration
```lua
Config.Firewall = {
    Enabled = true,
    DDoSProtection = true,
    RateLimit = {
        Enabled = true,
        MaxRequests = 100,    -- Max requests per time window
        TimeWindow = 60000    -- Time window in milliseconds (1 minute)
    },
    IPBlacklist = {
        -- Add problematic IPs here
        -- "192.168.1.100",
        -- "10.0.0.50"
    },
    VPNProxyDetection = true
}
```

### File Scanner Configuration
```lua
Config.FileScanner = {
    Enabled = true,
    ScanInterval = 1800000,  -- 30 minutes in milliseconds
    ScanFor = {
        Backdoors = true,
        EvalLoadPatterns = true,
        ObfuscatedLua = true,
        SuspiciousUrls = true,
        ExternalHttpRequests = true
    },
    IgnoreDomains = {
        ".com", ".net", ".org", ".gov"
    },
    ScanPaths = {
        "resources/",
        "cache/"
    }
}
```

### Ban System Configuration
```lua
Config.BanSystem = {
    Enabled = true,
    AutomaticBans = true,
    TempBans = true,
    PermanentBans = true,
    WhitelistProtection = true,
    BanDurations = {
        Warning = 0,
        Light = 3600,      -- 1 hour
        Medium = 86400,    -- 24 hours  
        Heavy = 604800,    -- 1 week
        Permanent = -1
    }
}
```

## 🔗 Discord Webhook Setup

### Step 1: Create Discord Server & Channel
1. Create a new Discord server or use an existing one
2. Create a dedicated channel for server alerts (e.g., #server-alerts)
3. Make sure you have "Manage Webhooks" permission

### Step 2: Create Webhook
1. Right-click on your alerts channel
2. Select "Edit Channel"
3. Go to "Integrations" tab
4. Click "Create Webhook"
5. Set a name (e.g., "FiveM Protector")
6. Copy the webhook URL

### Step 3: Configure Webhook
```lua
Config.Webhook = {
    Enabled = true,
    URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
    Types = {
        Detection = true,      -- Cheat detections
        Error = true,          -- System errors
        ExploitAttempt = true, -- Exploit attempts
        DDoSAttack = true,     -- DDoS attacks
        BanAction = true       -- Ban notifications
    },
    Colors = {
        Info = 3447003,        -- Blue
        Warning = 16776960,    -- Yellow
        Critical = 16711680    -- Red
    }
}
```

### Step 4: Test Webhook
```bash
# Use console command to test
protector webhook_test
```

## 🗄️ Database Setup (Optional)

### MySQL/MariaDB Setup

#### Step 1: Create Database
```sql
CREATE DATABASE fivem_protector;
CREATE USER 'protector'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON fivem_protector.* TO 'protector'@'localhost';
FLUSH PRIVILEGES;
```

#### Step 2: Configure Database Connection
```lua
Config.Database = {
    Enabled = true,
    Type = "mysql",
    ConnectionString = "mysql://protector:secure_password@localhost/fivem_protector"
}
```

#### Step 3: Install mysql-async
```cfg
# Add to server.cfg BEFORE fivem-protector
ensure mysql-async
ensure fivem-protector
```

### SQLite Setup (Simpler Alternative)
```lua
Config.Database = {
    Enabled = true,
    Type = "sqlite",
    ConnectionString = "database.db"
}
```

## 👑 Admin Permissions

### Basic Permission Setup
```cfg
# Add to server.cfg

# Create admin group
add_ace group.admin command allow
add_ace group.admin protector.admin allow

# Add yourself as admin (replace with your license)
add_principal identifier.license:YOUR_LICENSE_HERE group.admin

# Add other admins
add_principal identifier.license:ADMIN2_LICENSE_HERE group.admin
add_principal identifier.steam:STEAM_ID_HERE group.admin
```

### Advanced Permission Setup
```cfg
# Granular permissions
add_ace group.moderator protector.ban allow
add_ace group.moderator protector.unban allow
add_ace group.admin protector.admin allow
add_ace group.admin protector.whitelist allow
add_ace group.superadmin protector.* allow

# Assign roles
add_principal identifier.license:MOD_LICENSE group.moderator
add_principal identifier.license:ADMIN_LICENSE group.admin
add_principal identifier.license:SUPER_ADMIN_LICENSE group.superadmin
```

## 🧪 Testing the Installation

### Step 1: Verify System Status
```bash
# In server console
protector status
```
Expected output:
```
=== FiveM Server Protector Status ===
Protection: ✓ Enabled
Anti-cheat: ✓ Active
Firewall: ✓ Active
File Scanner: ✓ Active
Ban System: ✓ Active
Webhooks: ✓ Connected
Protected Players: X
```

### Step 2: Test Client Connection
1. Connect to your server
2. Check console for initialization messages
3. Look for: "🛡️ FiveM Server Protector client initialized successfully"

### Step 3: Test Detection (Optional)
```lua
-- Temporary test code (remove after testing)
TriggerServerEvent('protector:detection:cheat', 'test_detection', {test = true})
```

### Step 4: Test Admin Commands
```
/protector status
/protector stats
```

### Step 5: Test Webhook
Should receive Discord notification when server starts.

## ⚡ Optimization

### Performance Tuning
```lua
Config.Performance = {
    MaxChecksPerFrame = 10,      -- Reduce if experiencing lag
    ThreadPriority = "normal",   -- Options: low, normal, high
    MemoryOptimization = true,   -- Enable garbage collection
    GarbageCollection = true     -- Automatic memory cleanup
}
```

### Check Intervals (Reduce for better performance)
```lua
Config.Protection.AntiCheat.CheckInterval = 1000  -- Increase from 500ms
-- Player protection checks will automatically adjust
```

### Selective Module Enabling
```lua
-- Disable modules you don't need
Config.Protection.WeaponProtection.AntiAimbot.CornerShoot = false
Config.Protection.PlayerProtection.AntiTinyPed = false
Config.FileScanner.ScanFor.ObfuscatedLua = false
```

## 🐛 Troubleshooting

### Common Issues

#### "Resource failed to start"
**Cause**: Missing dependencies or configuration errors
**Solution**:
1. Check `fxmanifest.lua` syntax
2. Verify all required files exist
3. Check server console for specific errors

#### "Webhook not working"
**Cause**: Invalid webhook URL or Discord permissions
**Solution**:
1. Verify webhook URL is correct
2. Test webhook manually:
```bash
curl -X POST -H "Content-Type: application/json" \
-d '{"content":"Test message"}' \
YOUR_WEBHOOK_URL
```

#### "High false positive rate"
**Cause**: Detection thresholds too sensitive
**Solution**:
1. Increase detection thresholds
2. Add legitimate players to whitelist
3. Adjust check intervals

#### "Poor performance"
**Cause**: Too many concurrent checks
**Solution**:
1. Reduce `MaxChecksPerFrame`
2. Increase check intervals
3. Disable unnecessary modules

#### "Database connection failed"
**Cause**: Incorrect credentials or missing database
**Solution**:
1. Verify database exists
2. Check connection string
3. Ensure mysql-async is running

### Log File Analysis
```bash
# Check main log file
tail -f logs/protector.log

# Look for specific errors
grep "ERROR" logs/protector.log
grep "CRITICAL" logs/protector.log
```

### Debug Mode
```lua
Config.Protection.Debug = true
Config.Logging.LogLevel = "DEBUG"
```

### Getting Help
1. Check this documentation
2. Review log files
3. Test with minimal configuration
4. Join community Discord for support

---

## ✅ Installation Complete!

Your FiveM Server Protector should now be:
- ✅ Installed and running
- ✅ Protecting against cheats
- ✅ Logging activities
- ✅ Sending Discord alerts
- ✅ Ready for monitoring

**Next Steps:**
- Monitor the logs for the first few days
- Adjust thresholds based on your server's needs
- Train your staff on the admin commands
- Set up regular file scans
- Review ban reports weekly

**Need help?** Check the main README.md for additional information and support options.