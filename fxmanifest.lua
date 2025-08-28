fx_version 'cerulean'
game 'gta5'

author 'FiveM Protector Team'
description 'Advanced FiveM Server Protection System'
version '1.0.0'

-- Core system files
shared_scripts {
    'config/config.lua',
    'utils/logger.lua',
    'utils/webhook.lua'
}

-- Client-side protection
client_scripts {
    'client/safe_init.lua',
    'client/compat_fixes.lua',
    'client/anticheat/*.lua',
    'client/protection/*.lua',
    'client/detection/*.lua',
    'client/main.lua'
}

-- Server-side protection
server_scripts {
    'server/firewall/*.lua',
    'server/scanner/*.lua',
    'server/ban_system/*.lua',
    'server/protection/*.lua',
    'server/main.lua'
}

-- Dependencies
dependencies {
    'mysql-async', -- Optional for database logging
    'async'
}

-- UI files
ui_page 'html/index.html'

files {
    'html/index.html'
}

-- Exported functions
exports {
    'addToWhitelist',
    'removeFromWhitelist',
    'banPlayer',
    'unbanPlayer',
    'isPlayerWhitelisted',
    'getProtectionStatus'
}

-- Server exports
server_exports {
    'addToWhitelist',
    'removeFromWhitelist',
    'banPlayer',
    'unbanPlayer',
    'logEvent',
    'sendWebhook'
}