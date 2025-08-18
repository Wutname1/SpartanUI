---@diagnostic disable: duplicate-set-field
--[===[ File: Options.lua
LibsDataBar Configuration Interface
Basic options setup for Phase 1 implementation
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary("LibsDataBar-1.0")
if not LibsDataBar then return end

-- Local references
local L = {} -- Localization table (will be expanded later)
local AceConfig = LibStub("AceConfig-3.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)

-- Basic localization (English only for now)
L["LibsDataBar"] = "LibsDataBar"
L["Options"] = "Options"
L["General"] = "General"
L["Bars"] = "Bars"
L["Plugins"] = "Plugins"
L["Performance"] = "Performance"
L["Theme"] = "Theme"
L["Enable Debug Mode"] = "Enable Debug Mode"
L["Show debug messages in chat"] = "Show debug messages in chat"
L["Enable Performance Monitoring"] = "Enable Performance Monitoring"
L["Track performance metrics for optimization"] = "Track performance metrics for optimization"

---@class LibsDataBarOptions
local Options = {}

-- Configuration table for AceConfig
local configTable = {
    type = "group",
    name = L["LibsDataBar"],
    args = {
        general = {
            type = "group",
            name = L["General"],
            order = 1,
            args = {
                header = {
                    type = "header",
                    name = L["LibsDataBar"] .. " v" .. LibsDataBar.version,
                    order = 0,
                },
                debugMode = {
                    type = "toggle",
                    name = L["Enable Debug Mode"],
                    desc = L["Show debug messages in chat"],
                    order = 10,
                    get = function() return LibsDataBar.config:GetConfig("global.developer.debugMode") or false end,
                    set = function(_, value) 
                        LibsDataBar.config:SetConfig("global.developer.debugMode", value)
                    end,
                },
                performanceMonitoring = {
                    type = "toggle",
                    name = L["Enable Performance Monitoring"],
                    desc = L["Track performance metrics for optimization"],
                    order = 20,
                    get = function() return LibsDataBar.config:GetConfig("global.performance.enableProfiler") or false end,
                    set = function(_, value)
                        LibsDataBar.config:SetConfig("global.performance.enableProfiler", value)
                        LibsDataBar.performance.enabled = value
                    end,
                },
            },
        },
        bars = {
            type = "group",
            name = L["Bars"],
            order = 2,
            args = {
                mainBar = {
                    type = "group",
                    name = "Main Bar",
                    order = 1,
                    inline = true,
                    args = {
                        enabled = {
                            type = "toggle",
                            name = "Show Main Bar",
                            desc = "Show or hide the main data bar",
                            order = 1,
                            get = function()
                                local mainBar = LibsDataBar.bars["main"]
                                return mainBar and mainBar.frame:IsShown()
                            end,
                            set = function(_, value)
                                local mainBar = LibsDataBar.bars["main"]
                                if mainBar then
                                    if value then
                                        mainBar:Show()
                                    else
                                        mainBar:Hide()
                                    end
                                end
                            end,
                        },
                        position = {
                            type = "select",
                            name = "Position",
                            desc = "Choose where to position the main bar",
                            order = 2,
                            values = {
                                ["bottom"] = "Bottom",
                                ["top"] = "Top",
                                ["left"] = "Left",
                                ["right"] = "Right",
                            },
                            get = function()
                                local mainBar = LibsDataBar.bars["main"]
                                return mainBar and mainBar.config.position or "bottom"
                            end,
                            set = function(_, value)
                                local mainBar = LibsDataBar.bars["main"]
                                if mainBar then
                                    mainBar.config.position = value
                                    mainBar:UpdatePosition()
                                end
                            end,
                        },
                        height = {
                            type = "range",
                            name = "Height",
                            desc = "Set the height of the main bar",
                            order = 3,
                            min = 16,
                            max = 48,
                            step = 2,
                            get = function()
                                local mainBar = LibsDataBar.bars["main"]
                                return mainBar and mainBar.config.size.height or 24
                            end,
                            set = function(_, value)
                                local mainBar = LibsDataBar.bars["main"]
                                if mainBar then
                                    mainBar.config.size.height = value
                                    mainBar:UpdateSize()
                                    mainBar:UpdateLayout()
                                end
                            end,
                        },
                        background = {
                            type = "toggle",
                            name = "Show Background",
                            desc = "Show background on the main bar",
                            order = 4,
                            get = function()
                                local mainBar = LibsDataBar.bars["main"]
                                return mainBar and mainBar.config.appearance.background.show or false
                            end,
                            set = function(_, value)
                                local mainBar = LibsDataBar.bars["main"]
                                if mainBar then
                                    mainBar.config.appearance.background.show = value
                                    mainBar:UpdateAppearance()
                                end
                            end,
                        },
                    },
                },
            },
        },
        plugins = {
            type = "group",
            name = L["Plugins"],
            order = 3,
            childGroups = "tab",
            args = {
                builtin = {
                    type = "group",
                    name = "Built-in Plugins",
                    order = 1,
                    args = {
                        description = {
                            type = "description",
                            name = "Enable or disable built-in LibsDataBar plugins. Changes take effect immediately.",
                            order = 0,
                        },
                    },
                },
                ldb = {
                    type = "group",
                    name = "LibDataBroker",
                    order = 2,
                    args = {
                        description = {
                            type = "description",
                            name = "LibDataBroker plugins are automatically detected and can be enabled here.",
                            order = 0,
                        },
                        autoDiscovery = {
                            type = "toggle",
                            name = "Auto-Discovery",
                            desc = "Automatically detect and register new LibDataBroker plugins",
                            order = 1,
                            get = function()
                                return LibsDataBar.ldb and LibsDataBar.ldb.autoDiscovery or false
                            end,
                            set = function(_, value)
                                if LibsDataBar.ldb then
                                    LibsDataBar.ldb:SetAutoDiscovery(value)
                                end
                            end,
                        },
                    },
                },
            },
        },
        themes = {
            type = "group",
            name = "Themes",
            order = 4,
            args = {
                currentTheme = {
                    type = "select",
                    name = "Active Theme",
                    desc = "Select the active theme for all bars",
                    order = 1,
                    values = function()
                        local themes = {}
                        if LibsDataBar.themes then
                            for themeId, theme in pairs(LibsDataBar.themes.themes or {}) do
                                themes[themeId] = theme.name or themeId
                            end
                        end
                        return themes
                    end,
                    get = function()
                        return LibsDataBar.themes and LibsDataBar.themes.currentTheme or "default"
                    end,
                    set = function(_, value)
                        if LibsDataBar.themes then
                            LibsDataBar.themes:SetCurrentTheme(value)
                        end
                    end,
                },
                description = {
                    type = "description",
                    name = function()
                        if LibsDataBar.themes then
                            local theme = LibsDataBar.themes:GetCurrentTheme()
                            if theme then
                                return "Current: " .. (theme.name or "Unknown") .. 
                                       (theme.description and ("\n" .. theme.description) or "")
                            end
                        end
                        return "No theme information available"
                    end,
                    order = 2,
                },
            },
        },
    },
}

-- Initialize options
function Options:Initialize()
    -- Generate dynamic plugin options
    self:GeneratePluginOptions()
    
    -- Register with AceConfig if available
    if AceConfig and AceConfigDialog then
        AceConfig:RegisterOptionsTable("LibsDataBar", configTable)
        AceConfigDialog:AddToBlizOptions("LibsDataBar", L["LibsDataBar"])
        
        -- Add slash commands
        SLASH_LIBSDATABAR1 = "/libsdatabar"
        SLASH_LIBSDATABAR2 = "/ldb"
        SlashCmdList["LIBSDATABAR"] = function(msg)
            AceConfigDialog:Open("LibsDataBar")
        end
        
        LibsDataBar:DebugLog("info", "Options interface initialized")
    end
end

-- Generate plugin options dynamically
function Options:GeneratePluginOptions()
    local builtinArgs = configTable.args.plugins.args.builtin.args
    local ldbArgs = configTable.args.plugins.args.ldb.args
    
    -- Add built-in plugin toggles
    for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
        if plugin and plugin.name and plugin.type ~= "ldb" then
            local safeName = pluginId:gsub("[^%w]", "_")
            builtinArgs[safeName] = {
                type = "toggle",
                name = plugin.name,
                desc = plugin.description or ("Enable/disable " .. plugin.name),
                order = 10,
                get = function()
                    local mainBar = LibsDataBar.bars["main"]
                    return mainBar and mainBar.plugins[pluginId] ~= nil
                end,
                set = function(_, value)
                    local mainBar = LibsDataBar.bars["main"]
                    if mainBar then
                        if value then
                            mainBar:AddPlugin(plugin)
                        else
                            mainBar:RemovePlugin(pluginId)
                        end
                    end
                end,
            }
        end
    end
    
    -- Add LDB plugin toggles
    if LibsDataBar.ldb and LibsDataBar.ldb.registeredObjects then
        for ldbName, wrapper in pairs(LibsDataBar.ldb.registeredObjects) do
            if wrapper and wrapper.plugin then
                local safeName = ldbName:gsub("[^%w]", "_")
                ldbArgs[safeName] = {
                    type = "toggle",
                    name = wrapper.name or ldbName,
                    desc = "LibDataBroker plugin: " .. ldbName,
                    order = 20,
                    get = function()
                        local mainBar = LibsDataBar.bars["main"]
                        return mainBar and mainBar.plugins[wrapper.plugin.id] ~= nil
                    end,
                    set = function(_, value)
                        local mainBar = LibsDataBar.bars["main"]
                        if mainBar then
                            if value then
                                mainBar:AddPlugin(wrapper.plugin)
                            else
                                mainBar:RemovePlugin(wrapper.plugin.id)
                            end
                        end
                    end,
                }
            end
        end
    end
end

-- Initialize options when ready
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    C_Timer.After(2, function() -- Delay to ensure LibsDataBar defaults are setup
        Options:Initialize()
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)

-- Export the options table for external access
LibsDataBar.Options = Options