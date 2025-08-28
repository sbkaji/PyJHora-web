# 🖥️ NUI (UI) Troubleshooting Guide

This guide helps resolve NUI (user interface) issues with the FiveM Server Protector.

## 🔍 Quick NUI Test

### Step 1: Check if NUI is enabled
```lua
-- In config/config.lua, make sure this is set to true:
Config.Protection.AntiCheat.NUIDevToolsDetection = true
```

### Step 2: Test NUI connection
```
/test_nui
```
**Expected output:**
```
[Protector] Testing NUI connection...
[Protector] NUI Test: NUI is working correctly
```

### Step 3: Enable debug mode (if needed)
```lua
-- In config/config.lua
Config.Protection.Debug = true
```

Then use:
```
/protector_debug
```

## 🛠️ Common NUI Issues & Fixes

### Issue 1: "NUI not responding"
**Symptoms:** No response from `/test_nui` command

**Causes & Solutions:**
1. **NUI disabled in config**
   ```lua
   -- Fix: Enable in config/config.lua
   Config.Protection.AntiCheat.NUIDevToolsDetection = true
   ```

2. **Resource not restarted after changes**
   ```
   stop leo-anticheat
   refresh
   ensure leo-anticheat
   ```

3. **Manifest file issues**
   ```lua
   -- Check fxmanifest.lua contains:
   ui_page 'html/devtools_check.html'
   files {
       'html/devtools_check.html'
   }
   ```

### Issue 2: "HTML file not found"
**Error:** `Failed to load resource file`

**Solutions:**
1. **Check file exists:**
   ```
   resources/leo-anticheat/html/devtools_check.html
   ```

2. **Verify file permissions (Linux):**
   ```bash
   chmod 644 resources/leo-anticheat/html/devtools_check.html
   ```

3. **Check manifest syntax:**
   ```lua
   -- Make sure paths are correct in fxmanifest.lua
   ui_page 'html/devtools_check.html'
   ```

### Issue 3: "JavaScript errors in NUI"
**Check browser console:** F8 → Console

**Common fixes:**
1. **Clear browser cache:** Restart FiveM completely
2. **Update FiveM:** Older builds may have NUI issues
3. **Check HTML syntax:** Validate HTML file

### Issue 4: "NUI callbacks not working"
**Symptoms:** NUI loads but doesn't communicate with game

**Solutions:**
1. **Check callback registration:**
   ```lua
   -- Should be in client/main.lua
   RegisterNUICallback('nui_test', function(data, cb)
       -- Handler code
       cb('ok')
   end)
   ```

2. **Verify fetch URLs:**
   ```javascript
   // In HTML, should use resource name:
   fetch('https://leo-anticheat/nui_test', {
   ```

3. **Check for conflicts:**
   - Other resources using same NUI callbacks
   - Chat resources interfering with NUI

## 🔧 Advanced Troubleshooting

### Enable Browser Developer Tools (Temporarily)
**For debugging only - disable in production!**

1. Add to `fxmanifest.lua`:
   ```lua
   client_script 'debug_nui.lua'
   ```

2. Create `debug_nui.lua`:
   ```lua
   -- DEBUGGING ONLY - REMOVE IN PRODUCTION
   CreateThread(function()
       Wait(5000)
       SetNuiFocus(true, true) -- Enable NUI focus
       print("Debug: NUI focus enabled")
   end)
   ```

3. Press F12 in game to open developer tools
4. Check Console and Network tabs for errors
5. **Remove debug files when done!**

### Check Resource Load Order
```cfg
# In server.cfg, ensure proper load order:
ensure leo-anticheat
# Other resources after
```

### Verify FiveM Build
```
# Check FiveM version
version
```
**Minimum recommended:** Build 4752+

## 📋 Manual NUI Test

### Create test HTML file:
```html
<!-- test_nui.html -->
<!DOCTYPE html>
<html>
<head>
    <title>NUI Test</title>
</head>
<body>
    <h1>NUI Test</h1>
    <button onclick="testCallback()">Test Callback</button>
    <script>
        function testCallback() {
            fetch('https://leo-anticheat/test', {
                method: 'POST',
                body: JSON.stringify({test: true})
            });
        }
    </script>
</body>
</html>
```

### Add to manifest:
```lua
ui_page 'test_nui.html'
files { 'test_nui.html' }
```

### Test callback:
```lua
RegisterNUICallback('test', function(data, cb)
    print("NUI test callback received!")
    cb('ok')
end)
```

## ✅ Verification Checklist

- [ ] NUI detection enabled in config
- [ ] HTML file exists and is readable
- [ ] Manifest includes ui_page and files
- [ ] Resource restarted after changes
- [ ] No conflicting resources
- [ ] FiveM build 4752 or higher
- [ ] `/test_nui` command works
- [ ] Browser console shows no errors

## 🚨 Still Not Working?

### Collect Debug Information:
1. **FiveM Build:** Run `version` in F8 console
2. **Browser Console:** F8 → Console → Screenshots of errors
3. **Resource Status:** `refresh` then `ensure leo-anticheat`
4. **File Check:** Verify `html/devtools_check.html` exists
5. **Manifest Check:** Verify syntax of `fxmanifest.lua`

### Temporary Workaround:
If NUI continues to fail, you can disable DevTools detection:
```lua
-- In config/config.lua
Config.Protection.AntiCheat.NUIDevToolsDetection = false
```

**Note:** This will disable browser DevTools protection but other anticheat features will continue working.

### Emergency Fix:
If NUI is causing crashes or issues:
```lua
-- Minimal NUI setup in fxmanifest.lua
-- Comment out these lines temporarily:
-- ui_page 'html/devtools_check.html'
-- files { 'html/devtools_check.html' }
```

---

**The anticheat system will work without NUI** - it's just one additional protection layer. Core detection features don't depend on NUI functionality.