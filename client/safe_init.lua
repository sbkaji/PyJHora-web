-- Safe Initialization to Prevent Infinite Loops
-- This file prevents CreateThread stack overflows

local initializationComplete = false
local protectionThreads = {}
local maxThreads = 20
local currentThreads = 0

-- Safe CreateThread wrapper
local originalCreateThread = CreateThread
CreateThread = function(func)
    if currentThreads >= maxThreads then
        print("^1[Protector] Maximum thread limit reached, preventing infinite loop^7")
        return
    end
    
    currentThreads = currentThreads + 1
    
    return originalCreateThread(function()
        local success, err = pcall(func)
        if not success then
            print(string.format("^1[Protector] Thread error: %s^7", err))
        end
        currentThreads = currentThreads - 1
    end)
end

-- Safe initialization check
function SafeInit(name, initFunction)
    if protectionThreads[name] then
        print(string.format("^3[Protector] Warning: %s already initialized^7", name))
        return
    end
    
    protectionThreads[name] = true
    
    CreateThread(function()
        Wait(math.random(1000, 3000)) -- Stagger initialization
        
        local success, err = pcall(initFunction)
        if not success then
            print(string.format("^1[Protector] Failed to initialize %s: %s^7", name, err))
            protectionThreads[name] = false
        else
            print(string.format("^2[Protector] %s initialized successfully^7", name))
        end
    end)
end

-- Reset thread counter periodically
CreateThread(function()
    while true do
        Wait(60000) -- Every minute
        if currentThreads > 15 then
            print(string.format("^3[Protector] High thread count: %d^7", currentThreads))
        end
    end
end)

-- Export functions
exports('SafeInit', SafeInit)
exports('GetThreadCount', function() return currentThreads end)