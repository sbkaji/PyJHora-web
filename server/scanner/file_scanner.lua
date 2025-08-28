-- File Scanner Module
-- Scans for backdoors, malicious code, and suspicious patterns in resources

local scanResults = {}
local scanInProgress = false
local lastScanTime = 0
local quarantinedFiles = {}

-- Malicious patterns to detect
local suspiciousPatterns = {
    backdoors = {
        "loadstring%s*%(",
        "load%s*%(",
        "dofile%s*%(",
        "io%.popen%s*%(",
        "os%.execute%s*%(",
        "debug%.getfenv",
        "debug%.setfenv",
        "getfenv%s*%(",
        "setfenv%s*%(",
        "_G%[.+%]%s*=",
        "rawget%s*%(%s*_G",
        "rawset%s*%(%s*_G"
    },
    
    eval_load = {
        "eval%s*%(",
        "loadstring%s*%(%s*['\"]",
        "load%s*%(%s*function",
        "pcall%s*%(%s*loadstring",
        "xpcall%s*%(%s*loadstring",
        "assert%s*%(%s*loadstring"
    },
    
    obfuscated = {
        "\\x[0-9a-fA-F][0-9a-fA-F]",
        "\\[0-9][0-9][0-9]",
        "string%.char%s*%(",
        "string%.byte%s*%(",
        "table%.concat%s*%(",
        "[a-zA-Z_][a-zA-Z0-9_]*%[.-%]%s*="
    },
    
    network_abuse = {
        "PerformHttpRequest%s*%(.+%.exe",
        "PerformHttpRequest%s*%(.+%.bat",
        "PerformHttpRequest%s*%(.+%.sh",
        "http://[^%s]+%.tk",
        "http://[^%s]+%.ml",
        "https://bit%.ly",
        "https://tinyurl%.com",
        "discord%.gg/[a-zA-Z0-9]+"
    },
    
    resource_manipulation = {
        "StopResource%s*%(",
        "StartResource%s*%(",
        "RestartResource%s*%(",
        "RefreshResource%s*%(",
        "ExecuteCommand%s*%(%s*['\"]restart",
        "ExecuteCommand%s*%(%s*['\"]stop",
        "ExecuteCommand%s*%(%s*['\"]start"
    },
    
    injection_patterns = {
        "TriggerServerEvent%s*%(%s*['\"]esx:",
        "TriggerServerEvent%s*%(%s*['\"]gcphone:",
        "TriggerEvent%s*%(%s*['\"]esx_billing:",
        "TriggerEvent%s*%(%s*['\"]banking:",
        "exports%[.-%]%:",
        "exports%.%w+%:"
    }
}

-- Initialize file scanner
CreateThread(function()
    Wait(10000) -- Wait for server to fully start
    
    if Config.FileScanner.Enabled then
        Logger.info("File scanner initialized")
        
        -- Start periodic scanning
        CreateThread(function()
            while true do
                if not scanInProgress then
                    performScan()
                end
                Wait(Config.FileScanner.ScanInterval)
            end
        end)
    end
end)

-- Perform comprehensive file scan
function performScan()
    scanInProgress = true
    lastScanTime = os.time()
    local scanStartTime = os.clock()
    
    Logger.info("Starting file system scan")
    
    local totalFiles = 0
    local suspiciousFiles = 0
    local quarantined = 0
    
    for _, path in ipairs(Config.FileScanner.ScanPaths) do
        local results = scanDirectory(path)
        totalFiles = totalFiles + results.totalFiles
        suspiciousFiles = suspiciousFiles + results.suspiciousFiles
        quarantined = quarantined + results.quarantined
    end
    
    local scanDuration = os.clock() - scanStartTime
    
    Logger.info(string.format("File scan completed - Files: %d, Suspicious: %d, Quarantined: %d, Duration: %.2fs", 
        totalFiles, suspiciousFiles, quarantined, scanDuration))
    
    -- Send webhook notification
    if suspiciousFiles > 0 then
        TriggerEvent('protector:webhook:send', {
            type = 'detection',
            title = 'File Scanner Alert',
            description = string.format('Detected %d suspicious files during scan', suspiciousFiles),
            totalFiles = totalFiles,
            suspiciousFiles = suspiciousFiles,
            quarantined = quarantined,
            duration = scanDuration,
            timestamp = os.time()
        })
    end
    
    scanInProgress = false
end

-- Scan a directory recursively
function scanDirectory(path)
    local results = {totalFiles = 0, suspiciousFiles = 0, quarantined = 0}
    
    -- Get all Lua files in directory
    local files = getFilesInDirectory(path, "lua")
    
    for _, file in ipairs(files) do
        results.totalFiles = results.totalFiles + 1
        
        local scanResult = scanFile(file)
        if scanResult.suspicious then
            results.suspiciousFiles = results.suspiciousFiles + 1
            
            if scanResult.severity == "HIGH" then
                quarantineFile(file, scanResult.threats)
                results.quarantined = results.quarantined + 1
            end
        end
    end
    
    return results
end

-- Scan individual file for threats
function scanFile(filePath)
    local result = {
        file = filePath,
        suspicious = false,
        threats = {},
        severity = "LOW",
        timestamp = os.time()
    }
    
    -- Read file content
    local content = readFile(filePath)
    if not content then
        return result
    end
    
    -- Check against all pattern categories
    for category, patterns in pairs(suspiciousPatterns) do
        if Config.FileScanner.ScanFor[category] then
            for _, pattern in ipairs(patterns) do
                local matches = findMatches(content, pattern)
                if #matches > 0 then
                    result.suspicious = true
                    table.insert(result.threats, {
                        category = category,
                        pattern = pattern,
                        matches = matches,
                        count = #matches
                    })
                    
                    -- Determine severity
                    if category == "backdoors" or category == "resource_manipulation" then
                        result.severity = "HIGH"
                    elseif category == "eval_load" or category == "injection_patterns" then
                        result.severity = "MEDIUM"
                    end
                end
            end
        end
    end
    
    -- Check for suspicious URLs
    if Config.FileScanner.ScanFor.suspicious_urls then
        local urls = extractURLs(content)
        for _, url in ipairs(urls) do
            if not isAllowedDomain(url) then
                result.suspicious = true
                table.insert(result.threats, {
                    category = "suspicious_urls",
                    url = url,
                    reason = "Unknown domain"
                })
                result.severity = "MEDIUM"
            end
        end
    end
    
    -- Store scan result
    scanResults[filePath] = result
    
    if result.suspicious then
        Logger.warning(string.format("Suspicious file detected: %s (Severity: %s)", filePath, result.severity))
        
        for _, threat in ipairs(result.threats) do
            Logger.debug(string.format("  Threat: %s - %s", threat.category, threat.pattern or threat.url))
        end
    end
    
    return result
end

-- Find pattern matches in content
function findMatches(content, pattern)
    local matches = {}
    local lines = splitLines(content)
    
    for lineNum, line in ipairs(lines) do
        if string.match(line, pattern) then
            table.insert(matches, {
                line = lineNum,
                content = line:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
            })
        end
    end
    
    return matches
end

-- Extract URLs from content
function extractURLs(content)
    local urls = {}
    local patterns = {
        "https?://[%w%.%-_/]+",
        "ftp://[%w%.%-_/]+",
        "www%.[%w%.%-_/]+"
    }
    
    for _, pattern in ipairs(patterns) do
        for url in string.gmatch(content, pattern) do
            table.insert(urls, url)
        end
    end
    
    return urls
end

-- Check if domain is allowed
function isAllowedDomain(url)
    local domain = string.match(url, "https?://([^/]+)")
    if not domain then
        domain = string.match(url, "www%.([^/]+)")
    end
    
    if not domain then return false end
    
    for _, allowedDomain in ipairs(Config.FileScanner.IgnoreDomains) do
        if string.find(domain, allowedDomain, 1, true) then
            return true
        end
    end
    
    return false
end

-- Quarantine suspicious file
function quarantineFile(filePath, threats)
    local timestamp = os.time()
    local quarantinePath = string.format("quarantine/%d_%s", timestamp, string.gsub(filePath, "/", "_"))
    
    -- Move file to quarantine (in production, actually move the file)
    quarantinedFiles[filePath] = {
        originalPath = filePath,
        quarantinePath = quarantinePath,
        threats = threats,
        timestamp = timestamp,
        status = "quarantined"
    }
    
    Logger.critical(string.format("File quarantined: %s -> %s", filePath, quarantinePath))
    
    -- Send alert
    TriggerEvent('protector:webhook:send', {
        type = 'detection',
        title = 'File Quarantined',
        description = string.format('High-risk file quarantined: %s', filePath),
        file = filePath,
        threats = threats,
        timestamp = timestamp
    })
end

-- Restore quarantined file
function restoreFile(filePath, reason)
    if quarantinedFiles[filePath] then
        quarantinedFiles[filePath].status = "restored"
        quarantinedFiles[filePath].restoreReason = reason
        quarantinedFiles[filePath].restoreTime = os.time()
        
        Logger.info(string.format("File restored: %s - Reason: %s", filePath, reason))
        return true
    end
    return false
end

-- Utility functions
function readFile(filePath)
    -- In a real implementation, this would read the actual file
    -- For FiveM, you might use LoadResourceFile or similar
    local content = LoadResourceFile(GetCurrentResourceName(), filePath)
    return content
end

function getFilesInDirectory(directory, extension)
    -- This is a simplified implementation
    -- In production, you would recursively scan the actual directory
    local files = {}
    
    -- For FiveM resources, you can iterate through resource files
    local resources = {}
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            table.insert(resources, resourceName)
        end
    end
    
    for _, resource in ipairs(resources) do
        -- Add resource files to scan list
        local resourceFiles = getResourceFiles(resource, extension)
        for _, file in ipairs(resourceFiles) do
            table.insert(files, string.format("resources/%s/%s", resource, file))
        end
    end
    
    return files
end

function getResourceFiles(resourceName, extension)
    -- Get files from resource manifest
    local files = {}
    local manifest = LoadResourceFile(resourceName, "fxmanifest.lua") or LoadResourceFile(resourceName, "__resource.lua")
    
    if manifest then
        -- Extract file paths from manifest (simplified)
        for match in string.gmatch(manifest, "['\"]([^'\"]+%." .. extension .. ")['\"]") do
            table.insert(files, match)
        end
    end
    
    return files
end

function splitLines(content)
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    return lines
end

-- Manual scan command
RegisterCommand('scan_files', function(source, args, rawCommand)
    if source ~= 0 then -- Only allow from console
        return
    end
    
    if scanInProgress then
        print("Scan already in progress...")
        return
    end
    
    CreateThread(function()
        performScan()
    end)
end, true)

-- Get scan results
RegisterCommand('scan_results', function(source, args, rawCommand)
    if source ~= 0 then
        return
    end
    
    print("=== File Scanner Results ===")
    print(string.format("Last scan: %s", os.date("%Y-%m-%d %H:%M:%S", lastScanTime)))
    print(string.format("Total files scanned: %d", #scanResults))
    
    local suspiciousCount = 0
    for _, result in pairs(scanResults) do
        if result.suspicious then
            suspiciousCount = suspiciousCount + 1
        end
    end
    
    print(string.format("Suspicious files: %d", suspiciousCount))
    print(string.format("Quarantined files: %d", #quarantinedFiles))
end, true)

-- Export functions
exports('scanFile', scanFile)
exports('getScanResults', function() return scanResults end)
exports('getQuarantinedFiles', function() return quarantinedFiles end)
exports('restoreFile', restoreFile)
exports('isScanInProgress', function() return scanInProgress end)