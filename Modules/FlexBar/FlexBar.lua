---@diagnostic disable: cast-local-type
---@class FlexBar : SUI.Module
local FlexBar
if SUI then
	FlexBar = SUI:NewModule('AFKEffects')
else
	FlexBar = LibStub('AceAddon-3.0'):NewAddon('FlexBar')
end

local Bar = {}
FlexBar.Bar = Bar

-- Libraries
local LDB = LibStub("LibDataBroker-1.1")
local LSM = LibStub("LibSharedMedia-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Constants
FlexBar.DEFAULT_BAR_HEIGHT = 20
FlexBar.DEFAULT_ICON_SIZE = 16

-- Database schema
local defaults = {
    profile = {
        bars = {
            ["Bar1"] = {
                name = "Bar1",
                enabled = true,
                position = "TOP",
                height = FlexBar.DEFAULT_BAR_HEIGHT,
                texture = "Blizzard",
                color = {r = 0, g = 0, b = 0, a = 0.5},
                locked = false,
            },
        },
        plugins = {},
        general = {
            locked = false,
        },
    },
}

function FlexBar:OnInitialize()
    -- Initialize database
    self.db = AceDB:New(addonName.."DB", defaults, true)

    -- Register slash commands
    self:RegisterChatCommand("flexbar", "SlashCommand")

    -- Initialize bars
    self:InitializeBars()

    -- Register LDB callbacks
    self:RegisterLDBCallbacks()

    -- Load options (assuming we'll have an Options.lua file)
    self:LoadOptions()
end

function FlexBar:OnEnable()
    self:Print("FlexBar enabled. Use /flexbar to access settings.")
end

function FlexBar:OnDisable()
    self:Print("FlexBar disabled.")
end

function FlexBar:InitializeBars()
    self.bars = {}
    for barName, barSettings in pairs(self.db.profile.bars) do
        self:CreateBar(barName, barSettings)
    end
end

function FlexBar:CreateBar(name, settings)
    -- This function will be implemented in Bar.lua
    -- Here we'll just call the function from the Bar module
    local bar = FlexBar.Bar:New(name, settings)
    self.bars[name] = bar
    return bar
end

function FlexBar:RegisterLDBCallbacks()
    LDB.RegisterCallback(self, "LibDataBroker_DataObjectCreated", "OnDataObjectCreated")
    LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged", "OnAttributeChanged")
end

function FlexBar:OnDataObjectCreated(event, name, dataobj)
    self:AddPluginToBar(name, dataobj)
end

function FlexBar:OnAttributeChanged(event, name, attr, value, dataobj)
    -- Update the plugin display when its data changes
    if self.plugins[name] then
        self.plugins[name]:UpdateDisplay(attr, value)
    end
end

function FlexBar:AddPluginToBar(name, dataobj)
    local barName = self:GetBarForPlugin(name)
    if not barName then return end

    local bar = self.bars[barName]
    if not bar then return end

    -- This function will be implemented in Bar.lua
    bar:AddPlugin(name, dataobj)
end

function FlexBar:GetBarForPlugin(pluginName)
    -- Logic to determine which bar a plugin should be added to
    -- For now, just return the first bar
    return next(self.bars)
end

function FlexBar:SlashCommand(input)
    if input == "" then
        -- Open main options panel
        self:OpenOptions()
    elseif input == "lock" then
        self:LockBars()
    elseif input == "unlock" then
        self:UnlockBars()
    else
        self:Print("Unknown command. Use /flexbar for options, or /flexbar lock/unlock to toggle bar lock.")
    end
end

function FlexBar:LockBars()
    self.db.profile.general.locked = true
    for _, bar in pairs(self.bars) do
        bar:Lock()
    end
    self:Print("Bars locked.")
end

function FlexBar:UnlockBars()
    self.db.profile.general.locked = false
    for _, bar in pairs(self.bars) do
        bar:Unlock()
    end
    self:Print("Bars unlocked.")
end

function FlexBar:OpenOptions()
    -- This function will be implemented in Options.lua
    self:ShowOptionsDialog()
end

-- Additional utility functions can be added here

-- Return the addon object
return FlexBar