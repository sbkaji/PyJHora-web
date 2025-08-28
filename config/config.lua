Config = {}

-- Core Protection Settings
Config.Protection = {
    Enabled = true,
    Debug = false,
    AntiCheat = {
        Enabled = true,
        CheckInterval = 500, -- milliseconds
        GlobalCheatDetection = true,
        ExecutorDetection = true,
        DumperDetection = true,
        NUIDevToolsDetection = true,
        ResourceRenameProtection = true,
        TriggerEventProtection = true,
        StopResourceProtection = true
    },
    
    -- Weapon Protection
    WeaponProtection = {
        Enabled = true,
        AntiAimbot = {
            MagicBullet = true,
            SilentAim = true,
            CornerShoot = true,
            Lock = true
        },
        AntiReloadHack = true,
        AntiDamageModifier = true,
        AntiChangeBulletType = true,
        AntiInfiniteAmmo = true,
        AntiNoRecoil = true,
        AntiGiveWeapon = true,
        AntiRemoveWeapon = true,
        BlacklistWeapons = {
            "WEAPON_RAILGUN",
            "WEAPON_MINIGUN",
            "WEAPON_RPG",
            "WEAPON_GRENADELAUNCHER"
        },
        BlacklistVehicles = {
            "HYDRA",
            "LAZER",
            "RHINO",
            "SAVAGE"
        }
    },
    
    -- Player Protection
    PlayerProtection = {
        Enabled = true,
        AntiGodmode = true,
        AntiSuperJump = true,
        AntiInvisible = true,
        AntiRagdoll = true,
        AntiHealthHack = true,
        AntiSpeedHack = true,
        AntiStaminaHack = true,
        AntiInfiniteStamina = true,
        AntiArmourHack = true,
        AntiFreecam = true,
        AntiClearPedTask = true,
        AntiExplosion = true,
        AntiTeleport = {
            Enabled = true,
            MaxDistance = 50.0 -- meters
        },
        AntiNoclip = true,
        AntiSpectator = true,
        AntiNightVision = true,
        AntiThermalVision = true,
        AntiSpawnEntity = true,
        AntiVDM = true,
        AntiMenyoo = true,
        AntiSuicide = true,
        AntiPickupCollect = true,
        AntiPedChange = true,
        AntiTinyPed = true,
        AntiParticleFX = true,
        BlacklistWords = {
            "cheat",
            "hack",
            "exploit",
            "mod menu"
        },
        BlacklistCommands = {
            "give",
            "spawn",
            "teleport",
            "god"
        }
    }
}

-- Firewall Settings
Config.Firewall = {
    Enabled = true,
    DDoSProtection = true,
    RateLimit = {
        Enabled = true,
        MaxRequests = 100,
        TimeWindow = 60000 -- 1 minute
    },
    IPBlacklist = {},
    VPNProxyDetection = true,
    GeoBlocking = {
        Enabled = false,
        AllowedCountries = {"US", "CA", "GB"}
    }
}

-- File Scanner Settings
Config.FileScanner = {
    Enabled = true,
    ScanInterval = 1800000, -- 30 minutes in milliseconds
    ScanFor = {
        Backdoors = true,
        EvalLoadPatterns = true,
        ObfuscatedLua = true,
        SuspiciousUrls = true,
        ExternalHttpRequests = true
    },
    IgnoreDomains = {".com", ".net", ".org"},
    ScanPaths = {
        "resources/",
        "cache/"
    }
}

-- Ban System
Config.BanSystem = {
    Enabled = true,
    AutomaticBans = true,
    TempBans = true,
    PermanentBans = true,
    WhitelistProtection = true,
    BanDurations = {
        Warning = 0,
        Light = 3600, -- 1 hour
        Medium = 86400, -- 24 hours
        Heavy = 604800, -- 1 week
        Permanent = -1
    }
}

-- Discord Webhook Integration
Config.Webhook = {
    Enabled = true,
    URL = "", -- Set your Discord webhook URL here
    Types = {
        Detection = true,
        Error = true,
        ExploitAttempt = true,
        DDoSAttack = true,
        BanAction = true
    },
    Colors = {
        Info = 3447003, -- Blue
        Warning = 16776960, -- Yellow
        Critical = 16711680 -- Red
    }
}

-- Database Settings
Config.Database = {
    Enabled = false, -- Set to true if using database logging
    Type = "mysql", -- mysql, sqlite
    ConnectionString = "mysql://user:password@localhost/fivem_protector"
}

-- Logging Settings
Config.Logging = {
    Enabled = true,
    LocalFile = "logs/protector.log",
    LogLevel = "INFO", -- DEBUG, INFO, WARNING, ERROR, CRITICAL
    MaxFileSize = 10485760, -- 10MB
    BackupCount = 5
}

-- Performance Settings
Config.Performance = {
    MaxChecksPerFrame = 10,
    ThreadPriority = "normal", -- low, normal, high
    MemoryOptimization = true,
    GarbageCollection = true
}