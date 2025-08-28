-- FiveM Server Protector - Example Configuration
-- Copy this file to config/config.lua and modify as needed

Config = {}

-- ===== CORE PROTECTION SETTINGS =====
Config.Protection = {
    Enabled = true,  -- Master switch for all protection
    Debug = false,   -- Enable debug mode (verbose logging)
    
    -- Anti-cheat system configuration
    AntiCheat = {
        Enabled = true,
        CheckInterval = 500,  -- Milliseconds between checks (500 = 0.5 seconds)
        
        -- Detection modules
        GlobalCheatDetection = true,      -- Detect cheat menus on screen
        ExecutorDetection = true,         -- Detect script executors
        DumperDetection = true,          -- Detect memory dumpers [BETA]
        NUIDevToolsDetection = true,     -- Detect browser dev tools
        ResourceRenameProtection = true,  -- Prevent resource renaming
        TriggerEventProtection = true,   -- Protect against event injection
        StopResourceProtection = true,   -- Prevent resource stopping
        
        -- Event blacklist (events that should never be triggered by clients)
        BlacklistedEvents = {
            "giveWeaponEvent",
            "esx:getSharedObject",
            "gcPhone:_internalAddMessage",
            "esx_billing:sendBill"
        }
    },
    
    -- Weapon protection settings
    WeaponProtection = {
        Enabled = true,
        
        -- Aimbot detection
        AntiAimbot = {
            MagicBullet = true,   -- Detect impossible bullet trajectories
            SilentAim = true,     -- Detect aim direction mismatches
            CornerShoot = true,   -- Detect shooting through walls
            Lock = true           -- Detect aim locking
        },
        
        -- Weapon modification protection
        AntiReloadHack = true,        -- Detect rapid reloading
        AntiDamageModifier = true,    -- Detect damage modifications
        AntiChangeBulletType = true,  -- Detect bullet type changes
        AntiInfiniteAmmo = true,      -- Detect unlimited ammo
        AntiNoRecoil = true,          -- Detect recoil removal
        AntiGiveWeapon = true,        -- Detect weapon spawning
        AntiRemoveWeapon = true,      -- Detect weapon removal
        
        -- Blacklisted items (will be automatically removed)
        BlacklistWeapons = {
            "WEAPON_RAILGUN",        -- Railgun
            "WEAPON_MINIGUN",        -- Minigun
            "WEAPON_RPG",            -- RPG
            "WEAPON_GRENADELAUNCHER" -- Grenade Launcher
        },
        
        BlacklistVehicles = {
            "HYDRA",    -- Hydra jet
            "LAZER",    -- P-996 Lazer
            "RHINO",    -- Tank
            "SAVAGE"    -- Savage helicopter
        }
    },
    
    -- Player protection settings
    PlayerProtection = {
        Enabled = true,
        
        -- Movement and physics protection
        AntiGodmode = true,           -- Detect invincibility
        AntiSuperJump = true,         -- Detect excessive jump height
        AntiInvisible = true,         -- Detect invisibility
        AntiRagdoll = true,          -- Detect ragdoll manipulation
        AntiHealthHack = true,        -- Detect health modifications
        AntiSpeedHack = true,         -- Detect speed modifications
        AntiStaminaHack = true,       -- Detect stamina modifications
        AntiInfiniteStamina = true,   -- Detect unlimited stamina
        AntiArmourHack = true,        -- Detect armor modifications
        AntiFreecam = true,           -- Detect camera manipulation
        AntiClearPedTask = true,      -- Detect task clearing
        AntiExplosion = true,         -- Detect explosion spawning
        
        -- Teleport protection
        AntiTeleport = {
            Enabled = true,
            MaxDistance = 50.0  -- Maximum allowed movement per second (meters)
        },
        
        -- Other protections
        AntiNoclip = true,            -- Detect no-clipping
        AntiSpectator = true,         -- Detect spectator mode
        AntiNightVision = true,       -- Detect night vision
        AntiThermalVision = true,     -- Detect thermal vision
        AntiSpawnEntity = true,       -- Detect entity spawning
        AntiVDM = true,              -- Detect vehicle ramming
        AntiMenyoo = true,           -- Detect Menyoo menu
        AntiSuicide = true,          -- Detect suicide commands
        AntiPickupCollect = true,     -- Detect pickup manipulation
        AntiPedChange = true,         -- Detect model changes
        AntiTinyPed = true,          -- Detect tiny player models
        AntiParticleFX = true,       -- Detect particle effects
        
        -- Content filtering
        BlacklistWords = {
            "cheat",
            "hack",
            "exploit",
            "mod menu",
            "lua executor"
        },
        
        BlacklistCommands = {
            "give",
            "spawn",
            "teleport",
            "god",
            "noclip"
        }
    }
}

-- ===== FIREWALL SETTINGS =====
Config.Firewall = {
    Enabled = true,
    
    -- DDoS protection
    DDoSProtection = true,
    
    -- Rate limiting
    RateLimit = {
        Enabled = true,
        MaxRequests = 100,      -- Maximum requests per time window
        TimeWindow = 60000      -- Time window in milliseconds (60 seconds)
    },
    
    -- IP management
    IPBlacklist = {
        -- Add problematic IPs here
        -- "192.168.1.100",
        -- "10.0.0.50"
    },
    
    -- VPN/Proxy detection
    VPNProxyDetection = false,  -- Set to true if you want to block VPNs
    
    -- Geographic blocking (optional)
    GeoBlocking = {
        Enabled = false,
        AllowedCountries = {"US", "CA", "GB", "DE", "FR"}
    }
}

-- ===== FILE SCANNER SETTINGS =====
Config.FileScanner = {
    Enabled = true,
    ScanInterval = 1800000,  -- Scan every 30 minutes (in milliseconds)
    
    -- What to scan for
    ScanFor = {
        Backdoors = true,              -- Malicious code patterns
        EvalLoadPatterns = true,       -- Dynamic code execution
        ObfuscatedLua = true,          -- Obfuscated scripts
        SuspiciousUrls = true,         -- Unknown external URLs
        ExternalHttpRequests = true    -- HTTP requests to external servers
    },
    
    -- Domains to ignore (won't be flagged as suspicious)
    IgnoreDomains = {
        ".com", ".net", ".org", ".gov", ".edu",
        "github.com", "raw.githubusercontent.com",
        "pastebin.com", "discord.com"
    },
    
    -- Paths to scan
    ScanPaths = {
        "resources/",
        "cache/"
    }
}

-- ===== BAN SYSTEM SETTINGS =====
Config.BanSystem = {
    Enabled = true,
    AutomaticBans = true,      -- Enable automatic banning on detection
    TempBans = true,           -- Allow temporary bans
    PermanentBans = true,      -- Allow permanent bans
    WhitelistProtection = true, -- Prevent banning whitelisted players
    
    -- Ban duration presets (in seconds, -1 = permanent)
    BanDurations = {
        Warning = 0,           -- Just a warning
        Light = 3600,          -- 1 hour
        Medium = 86400,        -- 24 hours
        Heavy = 604800,        -- 1 week
        Permanent = -1         -- Permanent
    }
}

-- ===== DISCORD WEBHOOK SETTINGS =====
Config.Webhook = {
    Enabled = true,
    
    -- Get this URL from your Discord server webhook settings
    URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
    
    -- Types of alerts to send
    Types = {
        Detection = true,        -- Cheat detection alerts
        Error = true,           -- System error alerts
        ExploitAttempt = true,  -- Exploit attempt alerts
        DDoSAttack = true,      -- DDoS attack alerts
        BanAction = true        -- Ban action alerts
    },
    
    -- Alert colors (Discord embed colors)
    Colors = {
        Info = 3447003,      -- Blue
        Warning = 16776960,  -- Yellow
        Critical = 16711680  -- Red
    }
}

-- ===== DATABASE SETTINGS =====
Config.Database = {
    Enabled = false,  -- Set to true to enable database logging
    Type = "mysql",   -- Options: "mysql", "sqlite"
    
    -- For MySQL/MariaDB
    ConnectionString = "mysql://username:password@localhost/database_name",
    
    -- For SQLite (simpler option)
    -- ConnectionString = "database.db"
}

-- ===== LOGGING SETTINGS =====
Config.Logging = {
    Enabled = true,
    LocalFile = "logs/protector.log",    -- Local log file path
    LogLevel = "INFO",                   -- Options: DEBUG, INFO, WARNING, ERROR, CRITICAL
    MaxFileSize = 10485760,              -- 10MB max file size
    BackupCount = 5                      -- Keep 5 backup files
}

-- ===== PERFORMANCE SETTINGS =====
Config.Performance = {
    MaxChecksPerFrame = 10,              -- Limit checks per game frame
    ThreadPriority = "normal",           -- Options: low, normal, high
    MemoryOptimization = true,           -- Enable memory optimization
    GarbageCollection = true             -- Enable automatic garbage collection
}

-- ===== DETECTION THRESHOLDS =====
-- How many detections before taking action
Config.Thresholds = {
    SpeedHack = 5,       -- 5 detections before ban
    Teleport = 3,        -- 3 detections before ban
    WeaponHack = 2,      -- 2 detections before ban
    Aimbot = 3,          -- 3 detections before ban
    Godmode = 3,         -- 3 detections before ban
    Noclip = 3,          -- 3 detections before ban
    EventSpam = 10       -- 10 spam events before action
}

-- ===== CUSTOM SETTINGS =====
-- Add your own custom configuration here
Config.Custom = {
    ServerName = "My FiveM Server",
    ContactInfo = "admin@myserver.com",
    
    -- Custom protection rules
    ExtraProtections = {
        AntiCarSpawn = true,
        AntiMoneyDrop = true,
        AntiTPToPlayer = true
    }
}

-- ===== FRAMEWORK INTEGRATION =====
-- Configure integration with popular frameworks
Config.Framework = {
    -- Automatically detect and integrate with these frameworks
    AutoDetect = true,
    
    -- Specific framework settings
    ESX = {
        Enabled = false,  -- Set to true if using ESX
        TriggerName = "esx:getSharedObject"
    },
    
    QBCore = {
        Enabled = false,  -- Set to true if using QBCore
        TriggerName = "QBCore:GetObject"
    },
    
    vRP = {
        Enabled = false,  -- Set to true if using vRP
        TriggerName = "vRP:Tunnel"
    }
}

-- ===== NOTIFICATION SETTINGS =====
Config.Notifications = {
    -- How to notify players of violations
    Method = "chat",  -- Options: chat, notification, none
    
    -- Messages shown to players
    Messages = {
        RateLimited = "You are sending too many requests. Please slow down.",
        Kicked = "You have been kicked for suspicious activity.",
        Banned = "You have been banned for cheating."
    }
}

--[[
    CONFIGURATION TIPS:
    
    1. Start with default settings and adjust as needed
    2. Monitor logs for false positives
    3. Use whitelist for trusted staff members
    4. Test webhook integration before going live
    5. Enable debug mode initially to understand detection patterns
    6. Adjust thresholds based on your server's needs
    7. Regularly review ban logs and statistics
    
    SECURITY BEST PRACTICES:
    
    1. Keep your webhook URL private
    2. Use strong database passwords
    3. Regularly update the protection system
    4. Monitor system performance impact
    5. Train staff on proper admin commands
    6. Keep logs for compliance and analysis
]]