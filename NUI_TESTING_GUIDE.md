# 🖥️ NUI Testing Guide - Quick Fix

## 🚀 **How to Test if NUI is Working:**

### **Step 1: Restart the Resource**
```
stop leo-anticheat
refresh
ensure leo-anticheat
```

### **Step 2: Look for These Messages**
**You should see:**
```
✅ [INFO] FiveM Server Protector client initialized successfully  
✅ [INFO] NUI system ready
✅ [Protector] NUI loaded successfully
```

### **Step 3: Test Commands**
```
/test_nui           # Test basic NUI communication
/ping_nui           # Test NUI responsiveness  
/check_devtools     # Check if DevTools are detected
```

**Expected results:**
```
✅ [Protector] Testing NUI connection...
✅ [Protector] NUI Test: NUI is working correctly
✅ [Protector] NUI ping successful (latency: Xms)
```

## 🔧 **If NUI Still Doesn't Work:**

### **Option 1: Enable Debug Mode**
```lua
-- In config/config.lua
Config.Protection.Debug = true
```

Then run:
```
/protector_debug
```

### **Option 2: Check File Structure**
Make sure you have:
```
resources/leo-anticheat/
├── html/
│   └── index.html          ← This file MUST exist
├── fxmanifest.lua
└── config/config.lua
```

### **Option 3: Check FiveM Version**
```
version
```
**Need:** Build 4752 or higher

### **Option 4: Simple File Check**
```
refresh
ensure leo-anticheat
```

If you see an error like "Failed to load resource file", the HTML file is missing or corrupted.

## 🐛 **Quick Fixes:**

### **Fix 1: Re-download HTML file**
If `html/index.html` is missing, the NUI won't work.

### **Fix 2: Check Manifest**
Make sure `fxmanifest.lua` contains:
```lua
ui_page 'html/index.html'
files {
    'html/index.html'
}
```

### **Fix 3: Disable NUI Temporarily**
```lua
-- In config/config.lua
Config.Protection.AntiCheat.NUIDevToolsDetection = false
```

**Note:** This disables DevTools protection but keeps other anticheat features.

## ✅ **Success Indicators:**

### **Working NUI will show:**
1. ✅ "NUI system ready" in console
2. ✅ Commands respond with success messages
3. ✅ No "Failed to load resource file" errors
4. ✅ F12 key gets blocked in game

### **Not Working NUI will show:**
1. ❌ No "NUI system ready" message
2. ❌ Commands show "Testing..." but no response
3. ❌ "Failed to load resource file" errors
4. ❌ F12 key works normally in game

## 🆘 **Still Not Working?**

### **Emergency Disable:**
```lua
-- Comment out these lines in fxmanifest.lua:
-- ui_page 'html/index.html'
-- files { 'html/index.html' }
```

### **Check Console for Errors:**
Look for:
- "Failed to load resource file"
- JavaScript errors in F8 console
- NUI-related error messages

### **Test with Minimal Setup:**
1. Stop all other resources except essentials
2. Restart FiveM completely
3. Try again with just leo-anticheat

**Remember:** The anticheat works without NUI - it's just one extra protection layer!