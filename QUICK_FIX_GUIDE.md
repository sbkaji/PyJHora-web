# 🚨 Quick Fix Guide - Immediate Solutions

## 🔥 **EMERGENCY FIX - Stop the infinite loop:**

### **Step 1: Stop the resource immediately**
```
stop leo-anticheat
```

### **Step 2: Restart with safe mode**
```
refresh
ensure leo-anticheat
```

### **Step 3: If still getting stack overflow, disable temporarily**
```lua
-- In config/config.lua - set this to false temporarily:
Config.Protection.Enabled = false
```

Then restart:
```
stop leo-anticheat
ensure leo-anticheat
```

## 🔧 **Fix 1: Discord Webhook**

### **Quick Test:**
```
protector webhook
```

### **Expected Output:**
```
✓ Webhook enabled
✓ Webhook URL set  
✓ Test webhook sent
```

### **If you see errors:**

**Error: "Webhook is DISABLED"**
```lua
// Fix in config/config.lua:
Config.Webhook.Enabled = true
```

**Error: "Webhook URL is NOT SET"**
```lua
// Fix in config/config.lua:
Config.Webhook.URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"
```

**How to get Discord webhook URL:**
1. Go to your Discord server
2. Right-click a channel → Edit Channel
3. Integrations → Webhooks → Create Webhook
4. Copy the webhook URL

## 🖥️ **Fix 2: NUI Commands**

### **Test Commands:**
```
/test_nui          # Test basic NUI
/show_nui          # Show NUI debug (press ESC to close)
/hide_nui          # Hide NUI
/check_devtools    # Check DevTools status
```

### **Expected Results:**
```
✅ [Protector] Testing NUI connection...
✅ [Protector] NUI Test: NUI is working correctly
```

### **If NUI doesn't respond:**

**Check file exists:**
```
resources/leo-anticheat/html/index.html
```

**If file missing, NUI won't work!**

## 🐛 **Fix 3: Stack Overflow Error**

### **Immediate Solution:**
The new `safe_init.lua` file prevents infinite loops. Make sure to:

1. **Restart completely:**
```
stop leo-anticheat
refresh  
ensure leo-anticheat
```

2. **If still getting errors, disable features one by one:**
```lua
// In config/config.lua:
Config.Protection.PlayerProtection.AntiSuperJump = false
Config.Protection.PlayerProtection.AntiNoclip = false
Config.Protection.PlayerProtection.AntiInvisible = false
```

3. **Minimal safe config:**
```lua
Config.Protection = {
    Enabled = true,
    AntiCheat = {
        Enabled = true,
        CheckInterval = 2000,  -- Slower checks
        GlobalCheatDetection = false,  -- Disable temporarily
        ExecutorDetection = false,
        DumperDetection = false,
        NUIDevToolsDetection = false,
        ResourceRenameProtection = true,
        TriggerEventProtection = true,
        StopResourceProtection = true
    },
    WeaponProtection = {
        Enabled = false  -- Disable temporarily
    },
    PlayerProtection = {
        Enabled = false  -- Disable temporarily  
    }
}
```

## ✅ **Verification Steps:**

### **1. Check for successful startup:**
```
✅ [INFO] FiveM Server Protector server initialized successfully
✅ [INFO] FiveM Server Protector client initialized successfully
```

### **2. Test webhook:**
```
protector webhook
```
Should show success messages and send Discord message.

### **3. Test NUI:**
```
/test_nui
```
Should respond with success message.

### **4. Check for errors:**
No red error messages or stack overflows.

## 🆘 **If Nothing Works:**

### **Nuclear Option - Disable Everything:**
```lua
// In config/config.lua:
Config.Protection.Enabled = false
```

### **Then enable features one by one:**
1. Enable basic anticheat first
2. Test each feature individually  
3. Add webhook when basic features work
4. Add NUI last

### **Emergency Contact Info:**
- Check console for specific error messages
- Look for "Failed to load resource file" errors
- Verify all files exist in correct folders

## 📋 **Quick Checklist:**

- [ ] Resource stops and starts without errors
- [ ] No stack overflow messages
- [ ] Webhook test works (`protector webhook`)
- [ ] NUI test works (`/test_nui`)
- [ ] No infinite loop errors
- [ ] Basic protection features working

**Remember: Start with minimal config and add features gradually!**