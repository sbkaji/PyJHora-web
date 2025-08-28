# 🛡️ FiveM Server Protector MVP

A comprehensive, lightweight, and extensible FiveM server protection system designed to detect, prevent, and log malicious activity with advanced anti-cheat capabilities, webhook alerts, and modular features.

## ✨ Features

### 🔐 Advanced Anti-Cheat System
- **External Cheat Detection** - Detects popular cheat menus (TZx, Susano, etc.)
- **Memory Manipulation Detection** - Advanced memory integrity checks
- **Executor Detection** - Prevents Lua code injection and script execution
- **Dumper Protection** - Detects memory dumping attempts
- **NUI DevTools Detection** - Prevents browser developer tools usage
- **Resource Protection** - Prevents resource manipulation and renaming
- **Event Protection** - Automatically protects against event injection

### 🔫 Weapon Protection
- **Anti-Aimbot** - Magic bullet, silent aim, corner shoot, and lock detection
- **Anti-Reload Hack** - Detects rapid reload modifications
- **Anti-Damage Modifier** - Prevents weapon damage manipulation
- **Anti-Infinite Ammo** - Detects unlimited ammunition cheats
- **Anti-No Recoil** - Identifies recoil pattern manipulation
- **Weapon Blacklist** - Automatically removes blacklisted weapons
- **Vehicle Blacklist** - Prevents spawning of restricted vehicles

### 🧍 Player Protection
- **Anti-Godmode** - Multiple detection methods for invincibility
- **Anti-Speed Hack** - Comprehensive speed manipulation detection
- **Anti-Teleport** - Configurable distance-based teleport detection
- **Anti-Super Jump** - Abnormal jump height detection
- **Anti-Invisible** - Player visibility manipulation detection
- **Anti-Noclip** - Movement through solid objects detection
- **Anti-Freecam** - Camera distance anomaly detection
- **Anti-Spectator** - Unauthorized spectating detection
- **Anti-Vision Hacks** - Night vision and thermal vision detection
- **Anti-VDM** - Vehicle death match prevention
- **Content Filtering** - Blacklisted words and commands protection

### 🌐 Server Protection
- **DDoS Protection** - Advanced connection pattern analysis
- **Rate Limiting** - Configurable request throttling
- **IP Blacklist** - Automatic and manual IP blocking
- **VPN/Proxy Detection** - Basic proxy connection identification
- **Firewall System** - Comprehensive network protection

### 📁 File Scanner
- **Backdoor Detection** - Scans for malicious code patterns
- **Obfuscation Detection** - Identifies obfuscated Lua code
- **URL Scanning** - Detects suspicious external connections
- **Resource Integrity** - Monitors resource file changes
- **Automatic Quarantine** - Isolates high-risk files

### 🔨 Ban System
- **Automatic Bans** - Configurable auto-ban thresholds
- **Temporary Bans** - Duration-based punishment system
- **Permanent Bans** - Persistent player exclusion
- **Whitelist Protection** - Prevents accidental admin bans
- **Ban History** - Comprehensive logging and tracking

### 🔗 Integrations
- **Discord Webhooks** - Real-time alerts and notifications
- **Database Logging** - Optional MySQL/SQLite integration
- **Local File Logging** - Detailed log file generation
- **Admin Commands** - In-game management interface

## 🚀 Installation

### Prerequisites
- FiveM Server (Latest recommended)
- Basic server administration knowledge
- Discord webhook URL (optional but recommended)

### Quick Setup

1. **Download & Extract**
   ```bash
   # Download the resource to your resources folder
   cd resources/
   git clone <repository-url> fivem-protector
   ```

2. **Configure the System**
   ```lua
   -- Edit config/config.lua
   Config.Webhook.URL = "YOUR_DISCORD_WEBHOOK_URL_HERE"
   Config.Protection.Enabled = true
   ```

3. **Add to server.cfg**
   ```
   ensure fivem-protector
   
   # Add admin permissions
   add_ace group.admin protector.admin allow
   add_principal identifier.license:YOUR_LICENSE_HERE group.admin
   ```

4. **Start Your Server**
   ```bash
   # The protector will automatically initialize
   # Check console for initialization messages
   ```

### Advanced Configuration

#### Webhook Setup (Recommended)
1. Create a Discord server and channel for alerts
2. Go to Channel Settings → Integrations → Webhooks
3. Create a new webhook and copy the URL
4. Add the URL to `Config.Webhook.URL` in the config file

#### Database Integration (Optional)
```lua
Config.Database = {
    Enabled = true,
    Type = "mysql", -- or "sqlite"
    ConnectionString = "mysql://user:password@localhost/fivem_protector"
}
```

#### Custom Ban Durations
```lua
Config.BanSystem.BanDurations = {
    Warning = 0,
    Light = 3600,      -- 1 hour
    Medium = 86400,    -- 24 hours
    Heavy = 604800,    -- 1 week
    Permanent = -1
}
```

## 📋 Commands

### Admin Commands
| Command | Description | Permission |
|---------|-------------|------------|
| `/protector status` | Show system status | `protector.admin` |
| `/protector stats` | Display protection statistics | `protector.admin` |
| `/protector reload` | Reload configuration | `protector.admin` |
| `/protector scan` | Start manual file scan | `protector.admin` |
| `/ban <id> <reason> [duration]` | Ban a player | `protector.admin` |
| `/unban <license> [reason]` | Unban a player | `protector.admin` |
| `/whitelist add <license> [reason]` | Add to whitelist | `protector.admin` |
| `/whitelist remove <license>` | Remove from whitelist | `protector.admin` |

### Console Commands
```bash
# View scan results
scan_results

# Manual file scan
scan_files

# System status
protector status
```

## ⚙️ Configuration Options

### Protection Levels
- **Paranoid** - Maximum protection, may cause false positives
- **Balanced** - Recommended for most servers
- **Relaxed** - Minimal protection, fewer false positives

### Detection Thresholds
Customize when automatic actions are taken:
```lua
Config.Thresholds = {
    SpeedHack = 5,        -- Detections before action
    Teleport = 3,         -- Detections before action
    WeaponHack = 2,       -- Detections before action
    Aimbot = 3           -- Detections before action
}
```

### Performance Tuning
```lua
Config.Performance = {
    MaxChecksPerFrame = 10,      -- Limit checks per frame
    ThreadPriority = "normal",   -- Thread priority
    MemoryOptimization = true,   -- Enable garbage collection
    GarbageCollection = true     -- Automatic memory cleanup
}
```

## 🐛 Troubleshooting

### Common Issues

#### False Positives
- Adjust detection thresholds in config
- Add legitimate players to whitelist
- Review logs for pattern analysis

#### Performance Issues
- Reduce `MaxChecksPerFrame` value
- Disable unnecessary protection modules
- Enable memory optimization

#### Webhook Not Working
- Verify webhook URL is correct
- Check Discord channel permissions
- Test webhook manually with curl

#### Detection Not Working
- Ensure `Config.Protection.Enabled = true`
- Check module-specific enable flags
- Verify admin permissions

### Debug Mode
Enable debug mode for detailed logging:
```lua
Config.Protection.Debug = true
Config.Logging.LogLevel = "DEBUG"
```

### Support
- Check the logs in `logs/protector.log`
- Use `/protector_debug` command (when debug enabled)
- Review Discord webhook alerts for patterns

## 🔧 Development

### Adding Custom Detections
```lua
-- client/custom/my_detection.lua
function detectCustomCheat()
    CreateThread(function()
        while true do
            Wait(1000)
            
            -- Your detection logic here
            if suspiciousActivity then
                TriggerServerEvent('protector:detection:cheat', 'custom_cheat', {
                    details = "Custom detection triggered"
                })
            end
        end
    end)
end

-- Initialize your detection
if Config.Protection.CustomDetection then
    detectCustomCheat()
end
```

### Custom Ban Reasons
```lua
-- Add to config/config.lua
Config.CustomBanReasons = {
    ["custom_cheat"] = {
        duration = Config.BanSystem.BanDurations.Heavy,
        autoban = true
    }
}
```

### Extending the File Scanner
```lua
-- Add custom patterns
Config.FileScanner.CustomPatterns = {
    suspicious_api_calls = {
        "TriggerServerEvent%s*%(%s*['\"]__cfx_internal",
        "exports%[.-%]%:__cfx_internal"
    }
}
```

## 📊 Monitoring & Alerts

### Discord Webhook Alerts
The system sends various types of alerts:
- 🔍 **Detection Alerts** - When cheats are detected
- ⚠️ **Exploit Attempts** - When exploits are attempted
- 🔨 **Ban Actions** - When players are banned
- 🚨 **DDoS Attacks** - When attacks are detected
- ❌ **System Errors** - When errors occur

### Log File Structure
```
[2024-01-01 12:00:00] [INFO] Protection system initialized
[2024-01-01 12:01:00] [WARNING] Detection: Player123 - Speed hack
[2024-01-01 12:01:30] [CRITICAL] Ban: Player123 - Automatic ban issued
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues** - Submit detailed bug reports
2. **Suggest Features** - Request new protection methods
3. **Submit Code** - Create pull requests with improvements
4. **Documentation** - Help improve this documentation

## 📄 License

This project is licensed under the MIT License. See LICENSE file for details.

## ⚠️ Disclaimer

This software is provided as-is for educational and server protection purposes. Users are responsible for:
- Complying with FiveM Terms of Service
- Following applicable laws and regulations
- Testing thoroughly before production use
- Monitoring for false positives

## 🔄 Version History

### v1.0.0 (MVP Release)
- Initial release with core protection features
- Basic anti-cheat detection system
- Weapon and player protection modules
- File scanner and ban system
- Discord webhook integration
- Comprehensive logging system

## 📞 Support

For support, feature requests, or bug reports:
- Create an issue in the repository
- Join our Discord community
- Check the troubleshooting section above

---

**🛡️ Keep your FiveM server safe with FiveM Server Protector!**