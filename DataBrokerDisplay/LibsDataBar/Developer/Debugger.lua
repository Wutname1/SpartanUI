---@diagnostic disable: duplicate-set-field
--[===[ File: Developer/Debugger.lua
LibsDataBar Advanced Debugging Framework
Categorized logging, performance tracking, and developer tools
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary("LibsDataBar-1.0")
if not LibsDataBar then return end

---@class Debugger
---@field enabled boolean Whether debugging is enabled
---@field categories table<string, boolean> Enabled debug categories
---@field logHistory table<DebugEntry> Debug log history
---@field maxHistorySize number Maximum log history entries
---@field logFile table|nil Log file handle for saved debugging
local Debugger = {}

---@class DebugEntry
---@field timestamp number Timestamp of log entry
---@field level string Log level (debug, info, warning, error)
---@field category string Log category
---@field message string Log message
---@field source string|nil Source file/function
---@field stackTrace string|nil Stack trace for errors

-- Initialize Debugger for LibsDataBar
LibsDataBar.debugger = LibsDataBar.debugger or setmetatable({
    enabled = false,
    categories = {
        -- Core system categories
        ["core"] = true,        -- Core library operations
        ["events"] = true,      -- Event system
        ["config"] = true,      -- Configuration system
        ["performance"] = true, -- Performance monitoring
        
        -- Display categories
        ["display"] = true,     -- Display engine
        ["bars"] = true,        -- DataBar operations
        ["plugins"] = true,     -- Plugin system
        ["themes"] = true,      -- Theme management
        ["animations"] = true,  -- Animation system
        
        -- Integration categories
        ["ldb"] = true,         -- LibDataBroker integration
        ["spartanui"] = true,   -- SpartanUI integration
        ["titan"] = false,      -- TitanPanel integration (when implemented)
        
        -- Developer categories
        ["validation"] = true,  -- Plugin validation
        ["templates"] = true,   -- Plugin templates
        ["wizard"] = true,      -- Plugin wizard
        
        -- Advanced categories
        ["memory"] = false,     -- Memory tracking
        ["timing"] = false,     -- Detailed timing
        ["network"] = false,    -- Network operations
        ["ui"] = false          -- UI interactions
    },
    logHistory = {},
    maxHistorySize = 1000,
    logFile = nil
}, { __index = Debugger })

-- Log levels with colors and priorities
local LOG_LEVELS = {
    ["debug"] = { color = "|cff888888", priority = 1 },
    ["info"] = { color = "|cff00ff00", priority = 2 },
    ["warning"] = { color = "|cffffff00", priority = 3 },
    ["error"] = { color = "|cffff0000", priority = 4 },
    ["critical"] = { color = "|cffff00ff", priority = 5 }
}

---Initialize the debugger
function Debugger:Initialize()
    -- Load debug settings from configuration
    self.enabled = LibsDataBar.config:GetConfig("global.developer.debugMode") or false
    
    -- Load category settings
    local categoryConfig = LibsDataBar.config:GetConfig("global.developer.debugCategories") or {}
    for category, enabled in pairs(categoryConfig) do
        if self.categories[category] ~= nil then
            self.categories[category] = enabled
        end
    end
    
    -- Override core DebugLog to use enhanced debugger
    self:HookDebugLog()
    
    LibsDataBar:DebugLog("info", "Enhanced debugger initialized", "core")
end

---Hook the core DebugLog function
function Debugger:HookDebugLog()
    if not LibsDataBar._originalDebugLog then
        LibsDataBar._originalDebugLog = LibsDataBar.DebugLog
    end
    
    LibsDataBar.DebugLog = function(lib, level, message, category, source)
        LibsDataBar.debugger:Log(level, message, category or "core", source)
    end
end

---Log a debug message
---@param level string Log level (debug, info, warning, error, critical)
---@param message string Message to log
---@param category string Log category
---@param source string|nil Source identifier
function Debugger:Log(level, message, category, source)
    if not self.enabled then return end
    if not self.categories[category] then return end
    
    local levelConfig = LOG_LEVELS[level]
    if not levelConfig then
        level = "info"
        levelConfig = LOG_LEVELS[level]
    end
    
    -- Create log entry
    local entry = {
        timestamp = GetTime(),
        level = level,
        category = category,
        message = message,
        source = source
    }
    
    -- Add stack trace for errors
    if level == "error" or level == "critical" then
        entry.stackTrace = debugstack(2)
    end
    
    -- Add to history
    table.insert(self.logHistory, entry)
    if #self.logHistory > self.maxHistorySize then
        table.remove(self.logHistory, 1)
    end
    
    -- Format and output message
    local timestamp = date("%H:%M:%S", entry.timestamp)
    local categoryText = category:upper()
    local sourceText = source and (" [" .. source .. "]") or ""
    local formattedMessage = string.format("%s[%s] %s%s: %s|r", 
                                         levelConfig.color, timestamp, categoryText, sourceText, message)
    
    -- Output to chat
    if GetNumGroupMembers() == 0 or level == "error" or level == "critical" then
        print("LDB-Debug: " .. formattedMessage)
    end
    
    -- Write to log file if enabled
    if self.logFile then
        self:WriteToFile(entry)
    end
    
    -- Trigger debug event for listeners
    self:TriggerDebugEvent(entry)
end

---Write log entry to file
---@param entry DebugEntry Log entry to write
function Debugger:WriteToFile(entry)
    -- This would implement file writing if WoW allowed it
    -- For now, we'll accumulate for potential addon communication
end

---Trigger debug event for external listeners
---@param entry DebugEntry Log entry
function Debugger:TriggerDebugEvent(entry)
    if LibsDataBar.events then
        LibsDataBar.events:TriggerEvent("DEBUG_LOG", entry)
    end
end

---Enable/disable debugging
---@param enabled boolean Whether to enable debugging
function Debugger:SetEnabled(enabled)
    self.enabled = enabled
    LibsDataBar.config:SetConfig("global.developer.debugMode", enabled)
    
    if enabled then
        self:Log("info", "Debugging enabled", "core")
    end
end

---Enable/disable a debug category
---@param category string Category to modify
---@param enabled boolean Whether to enable the category
function Debugger:SetCategoryEnabled(category, enabled)
    if self.categories[category] == nil then
        self:Log("warning", "Unknown debug category: " .. category, "core")
        return
    end
    
    self.categories[category] = enabled
    
    -- Save to configuration
    local categoryConfig = LibsDataBar.config:GetConfig("global.developer.debugCategories") or {}
    categoryConfig[category] = enabled
    LibsDataBar.config:SetConfig("global.developer.debugCategories", categoryConfig)
    
    self:Log("info", string.format("Debug category '%s' %s", category, enabled and "enabled" or "disabled"), "core")
end

---Get debug categories and their status
---@return table categories Table of category -> enabled status
function Debugger:GetCategories()
    return self.categories
end

---Get recent log entries
---@param count number|nil Number of entries to return (default: 50)
---@param category string|nil Filter by category
---@param level string|nil Filter by level
---@return table entries Array of log entries
function Debugger:GetRecentLogs(count, category, level)
    count = count or 50
    local filtered = {}
    
    -- Filter entries
    for i = #self.logHistory, 1, -1 do
        local entry = self.logHistory[i]
        
        -- Apply filters
        if (not category or entry.category == category) and
           (not level or entry.level == level) then
            table.insert(filtered, entry)
            
            if #filtered >= count then
                break
            end
        end
    end
    
    return filtered
end

---Clear log history
function Debugger:ClearHistory()
    self.logHistory = {}
    self:Log("info", "Debug log history cleared", "core")
end

---Get performance statistics
---@return table stats Performance statistics
function Debugger:GetPerformanceStats()
    local stats = {}
    
    -- Category breakdown
    stats.categoryBreakdown = {}
    for _, entry in ipairs(self.logHistory) do
        stats.categoryBreakdown[entry.category] = (stats.categoryBreakdown[entry.category] or 0) + 1
    end
    
    -- Level breakdown
    stats.levelBreakdown = {}
    for _, entry in ipairs(self.logHistory) do
        stats.levelBreakdown[entry.level] = (stats.levelBreakdown[entry.level] or 0) + 1
    end
    
    -- Recent activity (last 5 minutes)
    local recentTime = GetTime() - 300
    stats.recentActivity = 0
    for _, entry in ipairs(self.logHistory) do
        if entry.timestamp >= recentTime then
            stats.recentActivity = stats.recentActivity + 1
        end
    end
    
    stats.totalEntries = #self.logHistory
    stats.memoryUsage = collectgarbage("count") * 1024 -- Convert KB to bytes
    
    return stats
end

---Generate debug report
---@return string report Formatted debug report
function Debugger:GenerateReport()
    local report = {}
    local stats = self:GetPerformanceStats()
    
    table.insert(report, "=== LibsDataBar Debug Report ===")
    table.insert(report, "Generated: " .. date("%Y-%m-%d %H:%M:%S"))
    table.insert(report, "Debug Status: " .. (self.enabled and "ENABLED" or "DISABLED"))
    table.insert(report, "")
    
    -- Overall statistics
    table.insert(report, "STATISTICS:")
    table.insert(report, "  Total Log Entries: " .. stats.totalEntries)
    table.insert(report, "  Recent Activity (5min): " .. stats.recentActivity)
    table.insert(report, "  Memory Usage: " .. string.format("%.2f MB", stats.memoryUsage / 1024 / 1024))
    table.insert(report, "")
    
    -- Category breakdown
    table.insert(report, "CATEGORY BREAKDOWN:")
    for category, count in pairs(stats.categoryBreakdown) do
        local status = self.categories[category] and "ENABLED" or "DISABLED"
        table.insert(report, string.format("  %s: %d entries (%s)", category:upper(), count, status))
    end
    table.insert(report, "")
    
    -- Level breakdown
    table.insert(report, "LEVEL BREAKDOWN:")
    for level, count in pairs(stats.levelBreakdown) do
        table.insert(report, string.format("  %s: %d entries", level:upper(), count))
    end
    table.insert(report, "")
    
    -- Recent errors
    local recentErrors = self:GetRecentLogs(10, nil, "error")
    if #recentErrors > 0 then
        table.insert(report, "RECENT ERRORS:")
        for _, entry in ipairs(recentErrors) do
            table.insert(report, string.format("  [%s] %s: %s", 
                                             date("%H:%M:%S", entry.timestamp), 
                                             entry.category:upper(), 
                                             entry.message))
        end
        table.insert(report, "")
    end
    
    -- Plugin status
    if LibsDataBar.plugins then
        table.insert(report, "PLUGIN STATUS:")
        for pluginId, plugin in pairs(LibsDataBar.plugins) do
            table.insert(report, string.format("  %s: %s (v%s)", 
                                             plugin.name or pluginId, 
                                             plugin.enabled and "ENABLED" or "DISABLED",
                                             plugin.version or "unknown"))
        end
        table.insert(report, "")
    end
    
    return table.concat(report, "\n")
end

---Performance profiler
---@param name string Function/operation name
---@param func function Function to profile
---@param ... any Arguments to pass to function
---@return any ... Function return values
function Debugger:Profile(name, func, ...)
    if not self.enabled or not self.categories["performance"] then
        return func(...)
    end
    
    local startTime = GetTime()
    local startMemory = collectgarbage("count")
    
    -- Execute function
    local results = { pcall(func, ...) }
    local success = table.remove(results, 1)
    
    local endTime = GetTime()
    local endMemory = collectgarbage("count")
    
    -- Log performance data
    local duration = (endTime - startTime) * 1000 -- Convert to milliseconds
    local memoryDelta = endMemory - startMemory
    
    if success then
        self:Log("debug", string.format("PROFILE %s: %.2fms, %.2fKB memory", name, duration, memoryDelta), "performance")
    else
        self:Log("error", string.format("PROFILE %s FAILED: %s (%.2fms)", name, tostring(results[1]), duration), "performance")
    end
    
    -- Return results
    if success then
        return unpack(results)
    else
        error(results[1])
    end
end

---Dump object contents for debugging
---@param obj any Object to dump
---@param name string|nil Object name
---@param maxDepth number|nil Maximum recursion depth (default: 3)
---@return string dump Formatted object dump
function Debugger:DumpObject(obj, name, maxDepth)
    maxDepth = maxDepth or 3
    name = name or "Object"
    
    local function dump(o, depth, visited)
        visited = visited or {}
        depth = depth or 0
        
        if depth > maxDepth then
            return "..."
        end
        
        if visited[o] then
            return "<circular reference>"
        end
        
        local objType = type(o)
        
        if objType == "nil" then
            return "nil"
        elseif objType == "boolean" then
            return tostring(o)
        elseif objType == "number" then
            return tostring(o)
        elseif objType == "string" then
            return string.format("%q", o)
        elseif objType == "function" then
            return "<function>"
        elseif objType == "userdata" then
            return "<userdata>"
        elseif objType == "thread" then
            return "<thread>"
        elseif objType == "table" then
            if depth == 0 then
                visited[o] = true
            end
            
            local lines = {}
            table.insert(lines, "{")
            
            for k, v in pairs(o) do
                local keyStr = dump(k, depth + 1, visited)
                local valueStr = dump(v, depth + 1, visited)
                table.insert(lines, string.format("  %s%s = %s,", string.rep("  ", depth), keyStr, valueStr))
            end
            
            table.insert(lines, string.rep("  ", depth) .. "}")
            return table.concat(lines, "\n")
        end
        
        return "<unknown>"
    end
    
    local result = name .. " = " .. dump(obj)
    self:Log("debug", "DUMP:\n" .. result, "core")
    return result
end

-- Add slash commands for debugging
SLASH_LDB_DEBUG1 = "/ldb-debug"
SlashCmdList["LDB_DEBUG"] = function(msg)
    local args = { strsplit(" ", msg) }
    local command = args[1] or ""
    
    if command == "on" then
        LibsDataBar.debugger:SetEnabled(true)
        print("LibsDataBar debugging enabled")
    elseif command == "off" then
        LibsDataBar.debugger:SetEnabled(false)
        print("LibsDataBar debugging disabled")
    elseif command == "clear" then
        LibsDataBar.debugger:ClearHistory()
        print("LibsDataBar debug history cleared")
    elseif command == "report" then
        local report = LibsDataBar.debugger:GenerateReport()
        print(report)
    elseif command == "categories" then
        print("LibsDataBar Debug Categories:")
        for category, enabled in pairs(LibsDataBar.debugger:GetCategories()) do
            print(string.format("  %s: %s", category, enabled and "ENABLED" or "DISABLED"))
        end
    elseif command == "enable" then
        local category = args[2]
        if category then
            LibsDataBar.debugger:SetCategoryEnabled(category, true)
        else
            print("Usage: /ldb-debug enable <category>")
        end
    elseif command == "disable" then
        local category = args[2]
        if category then
            LibsDataBar.debugger:SetCategoryEnabled(category, false)
        else
            print("Usage: /ldb-debug disable <category>")
        end
    else
        print("LibsDataBar Debug Commands:")
        print("  /ldb-debug on/off - Enable/disable debugging")
        print("  /ldb-debug clear - Clear debug history")
        print("  /ldb-debug report - Generate debug report")
        print("  /ldb-debug categories - List debug categories")
        print("  /ldb-debug enable/disable <category> - Toggle category")
    end
end

-- Initialize when ready
LibsDataBar.debugger:Initialize()

LibsDataBar:DebugLog("info", "Advanced debugger loaded successfully", "core")