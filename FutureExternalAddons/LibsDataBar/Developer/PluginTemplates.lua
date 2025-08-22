---@diagnostic disable: duplicate-set-field
--[===[ File: Developer/PluginTemplates.lua
LibsDataBar Plugin Development Templates
Comprehensive templates for creating native and LDB plugins
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

---@class PluginTemplates
---@field nativeTemplate table Native plugin template
---@field ldbTemplate table LDB plugin template
---@field dataSourceTemplate table Data source template
---@field commandTemplate table Chat command template
local PluginTemplates = {}

-- Initialize Plugin Templates for LibsDataBar
LibsDataBar.templates = LibsDataBar.templates or PluginTemplates

---Native LibsDataBar Plugin Template
PluginTemplates.nativeTemplate = [[
---@diagnostic disable: duplicate-set-field
--[===[ Plugin: {PLUGIN_NAME}
{PLUGIN_DESCRIPTION}
Author: {PLUGIN_AUTHOR}
Version: {PLUGIN_VERSION}
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary("LibsDataBar-1.0")
if not LibsDataBar then return end

-- Plugin Definition
---@class {PLUGIN_CLASS} : Plugin
local {PLUGIN_CLASS} = {
    -- Required metadata
    id = '{PLUGIN_ID}',
    name = '{PLUGIN_NAME}',
    version = '{PLUGIN_VERSION}',
    author = '{PLUGIN_AUTHOR}',
    category = '{PLUGIN_CATEGORY}',
    description = '{PLUGIN_DESCRIPTION}',

    -- Dependencies
    dependencies = {
        ['LibsDataBar-1.0'] = '1.0.0',
    },

    -- Private variables
    _updateInterval = 1.0,
    _lastUpdate = 0,
    _data = {},
}

-- Plugin Configuration Defaults
local {PLUGIN_LOWER}Defaults = {
    enabled = true,
    showIcon = true,
    showText = true,
    updateInterval = 1.0,
    {PLUGIN_CONFIG_DEFAULTS}
}

---Required: Get the display text for this plugin
---@return string text Display text
function {PLUGIN_CLASS}:GetText()
    -- Update data if needed
    if GetTime() - self._lastUpdate > self._updateInterval then
        self:UpdateData()
        self._lastUpdate = GetTime()
    end

    -- Format and return display text
    return self:FormatDisplayText()
end

---Required: Get the icon for this plugin (optional)
---@return string? icon Icon path or nil
function {PLUGIN_CLASS}:GetIcon()
    if self:GetConfig('showIcon') then
        return "{PLUGIN_ICON_PATH}"
    end
    return nil
end

---Update tooltip content
---@param tooltip GameTooltip Tooltip frame
function {PLUGIN_CLASS}:UpdateTooltip(tooltip)
    if not tooltip then return end

    tooltip:AddLine(self.name, 1, 1, 1)
    tooltip:AddLine(self.description, 0.7, 0.7, 0.7, true)
    tooltip:AddLine(" ")

    -- Add plugin-specific tooltip content
    self:AddTooltipContent(tooltip)

    -- Add click instructions
    tooltip:AddLine(" ")
    tooltip:AddLine("Click: Open options", 0.5, 0.5, 1)
    tooltip:AddLine("Right-click: Quick config", 0.5, 0.5, 1)
end

---Handle click events
---@param button string Mouse button clicked
function {PLUGIN_CLASS}:OnClick(button)
    if button == "LeftButton" then
        -- Left click action
        self:OnLeftClick()
    elseif button == "RightButton" then
        -- Right click action
        self:OnRightClick()
    elseif button == "MiddleButton" then
        -- Middle click action
        self:OnMiddleClick()
    end
end

---Update internal data
function {PLUGIN_CLASS}:UpdateData()
    -- Implement data gathering logic here
    -- Example:
    -- self._data.value = GetSomeValue()
    -- self._data.status = CalculateStatus()
end

---Format the display text
---@return string text Formatted display text
function {PLUGIN_CLASS}:FormatDisplayText()
    -- Implement text formatting logic here
    -- Example:
    -- return string.format("%s: %d", self.name, self._data.value or 0)
    return self.name .. ": " .. tostring(self._data.value or "Unknown")
end

---Add content to tooltip
---@param tooltip GameTooltip Tooltip frame
function {PLUGIN_CLASS}:AddTooltipContent(tooltip)
    -- Add plugin-specific tooltip information
    -- Example:
    -- tooltip:AddDoubleLine("Status:", self._data.status or "Unknown", 1, 1, 1, 1, 1, 0)
    -- tooltip:AddDoubleLine("Value:", tostring(self._data.value or 0), 1, 1, 1, 0, 1, 0)
end

---Handle left click
function {PLUGIN_CLASS}:OnLeftClick()
    -- Implement left click behavior
    -- Example: Open main interface, toggle feature, etc.
end

---Handle right click
function {PLUGIN_CLASS}:OnRightClick()
    -- Implement right click behavior
    -- Example: Open context menu, quick toggle, etc.
end

---Handle middle click
function {PLUGIN_CLASS}:OnMiddleClick()
    -- Implement middle click behavior
    -- Example: Reset data, refresh, etc.
end

---Get configuration options for this plugin
---@return table options AceConfig options table
function {PLUGIN_CLASS}:GetConfigOptions()
    return {
        type = "group",
        name = self.name,
        desc = self.description,
        args = {
            header = {
                type = "header",
                name = self.name,
                order = 1
            },

            description = {
                type = "description",
                name = self.description,
                order = 2
            },

            enabled = {
                type = "toggle",
                name = "Enable",
                desc = "Enable/disable this plugin",
                get = function() return self:GetConfig('enabled') end,
                set = function(_, value)
                    self:SetConfig('enabled', value)
                    if value then
                        self:OnEnable()
                    else
                        self:OnDisable()
                    end
                end,
                order = 3
            },

            showIcon = {
                type = "toggle",
                name = "Show Icon",
                desc = "Show the plugin icon",
                get = function() return self:GetConfig('showIcon') end,
                set = function(_, value) self:SetConfig('showIcon', value) end,
                order = 4
            },

            showText = {
                type = "toggle",
                name = "Show Text",
                desc = "Show the plugin text",
                get = function() return self:GetConfig('showText') end,
                set = function(_, value) self:SetConfig('showText', value) end,
                order = 5
            },

            updateInterval = {
                type = "range",
                name = "Update Interval",
                desc = "How often to update the display (seconds)",
                min = 0.1,
                max = 10,
                step = 0.1,
                get = function() return self:GetConfig('updateInterval') end,
                set = function(_, value)
                    self:SetConfig('updateInterval', value)
                    self._updateInterval = value
                end,
                order = 6
            },

            {PLUGIN_CONFIG_OPTIONS}
        }
    }
end

---Get default configuration for this plugin
---@return table defaults Default configuration table
function {PLUGIN_CLASS}:GetDefaultConfig()
    return {PLUGIN_LOWER}Defaults
end

---Lifecycle: Plugin initialization
function {PLUGIN_CLASS}:OnInitialize()
    -- Load configuration
    self._updateInterval = self:GetConfig('updateInterval')

    -- Initialize plugin-specific data
    self:InitializeData()

    LibsDataBar:DebugLog('info', self.name .. ' plugin initialized')
end

---Lifecycle: Plugin enabled
function {PLUGIN_CLASS}:OnEnable()
    -- Register events if needed
    self:RegisterEvents()

    -- Start any timers or background processes
    self:StartBackgroundProcesses()

    LibsDataBar:DebugLog('info', self.name .. ' plugin enabled')
end

---Lifecycle: Plugin disabled
function {PLUGIN_CLASS}:OnDisable()
    -- Unregister events
    self:UnregisterEvents()

    -- Stop any timers or background processes
    self:StopBackgroundProcesses()

    LibsDataBar:DebugLog('info', self.name .. ' plugin disabled')
end

---Initialize plugin-specific data
function {PLUGIN_CLASS}:InitializeData()
    -- Initialize your data structures here
    self._data = {}
end

---Register WoW events
function {PLUGIN_CLASS}:RegisterEvents()
    -- Register for relevant WoW events
    -- Example:
    -- LibsDataBar.events:RegisterEvent('PLAYER_MONEY', function() self:UpdateData() end)
end

---Unregister WoW events
function {PLUGIN_CLASS}:UnregisterEvents()
    -- Unregister events when plugin is disabled
end

---Start background processes
function {PLUGIN_CLASS}:StartBackgroundProcesses()
    -- Start any timers or background updates
end

---Stop background processes
function {PLUGIN_CLASS}:StopBackgroundProcesses()
    -- Clean up timers and background processes
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function {PLUGIN_CLASS}:GetConfig(key)
    return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or {PLUGIN_LOWER}Defaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function {PLUGIN_CLASS}:SetConfig(key, value)
    return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
    local {PLUGIN_LOWER}LDBObject = LDB:NewDataObject('{PLUGIN_ID}', {
        type = 'data source',
        text = {PLUGIN_CLASS}:GetText(),
        icon = {PLUGIN_CLASS}:GetIcon(),
        label = {PLUGIN_CLASS}.name,
        
        -- Forward methods to {PLUGIN_CLASS} with database access preserved
        OnClick = function(self, button)
            {PLUGIN_CLASS}:OnClick(button)
        end,
        
        OnTooltipShow = function(tooltip)
            local tooltipText = {PLUGIN_CLASS}:GetTooltip()
            -- Handle both \n and \\n newline formats
            tooltipText = tooltipText:gsub('\\n', '\n')
            local lines = {strsplit('\n', tooltipText)}
            for i, line in ipairs(lines) do
                if i == 1 then
                    tooltip:SetText(line)
                else
                    tooltip:AddLine(line, 1, 1, 1, true)
                end
            end
        end,
        
        -- Update method to refresh LDB object
        UpdateLDB = function(self)
            self.text = {PLUGIN_CLASS}:GetText()
            self.icon = {PLUGIN_CLASS}:GetIcon()
        end,
    })
    
    -- Store reference for updates
    {PLUGIN_CLASS}._ldbObject = {PLUGIN_LOWER}LDBObject
    
    LibsDataBar:DebugLog('info', '{PLUGIN_NAME} plugin registered as LibDataBroker object')
else
    LibsDataBar:DebugLog('error', 'LibDataBroker not available for {PLUGIN_NAME} plugin')
end

-- Return plugin for external access
return {PLUGIN_CLASS}
]]

---LibDataBroker Plugin Template
PluginTemplates.ldbTemplate = [[
---@diagnostic disable: duplicate-set-field
--[===[ LDB Plugin: {PLUGIN_NAME}
{PLUGIN_DESCRIPTION}
Author: {PLUGIN_AUTHOR}
Version: {PLUGIN_VERSION}
--]===]

-- Get required libraries
local LibStub = LibStub
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
if not LDB then
    error("{PLUGIN_NAME}: LibDataBroker-1.1 is required")
    return
end

-- Plugin metadata
local PLUGIN_NAME = "{PLUGIN_NAME}"
local PLUGIN_VERSION = "{PLUGIN_VERSION}"

-- Plugin data object
local {PLUGIN_LOWER}LDB = {
    type = "data source",
    text = PLUGIN_NAME,
    label = PLUGIN_NAME,
    icon = "{PLUGIN_ICON_PATH}",

    -- Plugin-specific data
    _updateInterval = 1.0,
    _lastUpdate = 0,
    _data = {},
}

---Update the plugin display
function {PLUGIN_LOWER}LDB:UpdateDisplay()
    -- Update data if needed
    if GetTime() - self._lastUpdate > self._updateInterval then
        self:UpdateData()
        self._lastUpdate = GetTime()
    end

    -- Update text and icon
    self.text = self:FormatDisplayText()

    -- Notify LibDataBroker of changes
    LDB:AttributeChanged(PLUGIN_NAME, "text", self.text)
end

---Update internal data
function {PLUGIN_LOWER}LDB:UpdateData()
    -- Implement data gathering logic here
    -- Example:
    -- self._data.value = GetSomeValue()
    -- self._data.status = CalculateStatus()
end

---Format the display text
---@return string text Formatted display text
function {PLUGIN_LOWER}LDB:FormatDisplayText()
    -- Implement text formatting logic here
    return PLUGIN_NAME .. ": " .. tostring(self._data.value or "Unknown")
end

---Handle tooltip display
---@param tooltip GameTooltip Tooltip frame
function {PLUGIN_LOWER}LDB:OnTooltipShow(tooltip)
    tooltip:AddLine(PLUGIN_NAME, 1, 1, 1)
    tooltip:AddLine("{PLUGIN_DESCRIPTION}", 0.7, 0.7, 0.7, true)
    tooltip:AddLine(" ")

    -- Add plugin-specific tooltip content
    self:AddTooltipContent(tooltip)

    -- Add click instructions
    tooltip:AddLine(" ")
    tooltip:AddLine("Click: Open options", 0.5, 0.5, 1)
    tooltip:AddLine("Right-click: Quick config", 0.5, 0.5, 1)
end

---Add content to tooltip
---@param tooltip GameTooltip Tooltip frame
function {PLUGIN_LOWER}LDB:AddTooltipContent(tooltip)
    -- Add plugin-specific tooltip information
    -- Example:
    -- tooltip:AddDoubleLine("Status:", self._data.status or "Unknown", 1, 1, 1, 1, 1, 0)
    -- tooltip:AddDoubleLine("Value:", tostring(self._data.value or 0), 1, 1, 1, 0, 1, 0)
end

---Handle click events
---@param frame Frame The frame that was clicked
---@param button string Mouse button clicked
function {PLUGIN_LOWER}LDB:OnClick(frame, button)
    if button == "LeftButton" then
        -- Left click action
        self:OnLeftClick()
    elseif button == "RightButton" then
        -- Right click action
        self:OnRightClick()
    elseif button == "MiddleButton" then
        -- Middle click action
        self:OnMiddleClick()
    end
end

---Handle left click
function {PLUGIN_LOWER}LDB:OnLeftClick()
    -- Implement left click behavior
end

---Handle right click
function {PLUGIN_LOWER}LDB:OnRightClick()
    -- Implement right click behavior
end

---Handle middle click
function {PLUGIN_LOWER}LDB:OnMiddleClick()
    -- Implement middle click behavior
end

-- Set up event handling and initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == GetAddOnMetadata("{PLUGIN_ADDON_NAME}" or PLUGIN_NAME, "Title") then
            -- Initialize plugin
            {PLUGIN_LOWER}LDB:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        -- Start updates
        {PLUGIN_LOWER}LDB:StartUpdates()
    end
end)

---Initialize the plugin
function {PLUGIN_LOWER}LDB:Initialize()
    -- Initialize plugin-specific data
    self._data = {}

    -- Register events
    self:RegisterEvents()

    print(PLUGIN_NAME .. " v" .. PLUGIN_VERSION .. " loaded")
end

---Start update timer
function {PLUGIN_LOWER}LDB:StartUpdates()
    -- Create update timer
    C_Timer.NewTicker(self._updateInterval, function()
        self:UpdateDisplay()
    end)

    -- Initial update
    self:UpdateDisplay()
end

---Register WoW events
function {PLUGIN_LOWER}LDB:RegisterEvents()
    -- Register for relevant WoW events
    -- Example:
    -- frame:RegisterEvent("PLAYER_MONEY")
    -- frame:SetScript("OnEvent", function(self, event, ...)
    --     {PLUGIN_LOWER}LDB:UpdateData()
    -- end)
end

-- Register with LibDataBroker
LDB:NewDataObject(PLUGIN_NAME, {PLUGIN_LOWER}LDB)
]]

---Generate a new native plugin
---@param config table Plugin configuration
---@return string pluginCode Generated plugin code
function PluginTemplates:GenerateNativePlugin(config)
	local template = self.nativeTemplate

	-- Replace template variables
	local replacements = {
		['{PLUGIN_NAME}'] = config.name or 'MyPlugin',
		['{PLUGIN_DESCRIPTION}'] = config.description or 'A LibsDataBar plugin',
		['{PLUGIN_AUTHOR}'] = config.author or 'Plugin Developer',
		['{PLUGIN_VERSION}'] = config.version or '1.0.0',
		['{PLUGIN_CLASS}'] = config.className or (config.name and config.name:gsub('%s', '') .. 'Plugin') or 'MyPlugin',
		['{PLUGIN_ID}'] = config.id or ('LibsDataBar_' .. (config.name and config.name:gsub('%s', '') or 'MyPlugin')),
		['{PLUGIN_CATEGORY}'] = config.category or 'Information',
		['{PLUGIN_LOWER}'] = config.variableName or (config.name and config.name:lower():gsub('%s', '') or 'myplugin'),
		['{PLUGIN_ICON_PATH}'] = config.iconPath or 'Interface\\Icons\\INV_Misc_QuestionMark',
		['{PLUGIN_CONFIG_DEFAULTS}'] = config.configDefaults or '-- Add your config defaults here',
		['{PLUGIN_CONFIG_OPTIONS}'] = config.configOptions or '-- Add your config options here',
	}

	for placeholder, replacement in pairs(replacements) do
		template = template:gsub(placeholder, replacement)
	end

	return template
end

---Generate a new LDB plugin
---@param config table Plugin configuration
---@return string pluginCode Generated plugin code
function PluginTemplates:GenerateLDBPlugin(config)
	local template = self.ldbTemplate

	-- Replace template variables
	local replacements = {
		['{PLUGIN_NAME}'] = config.name or 'MyPlugin',
		['{PLUGIN_DESCRIPTION}'] = config.description or 'A LibDataBroker plugin',
		['{PLUGIN_AUTHOR}'] = config.author or 'Plugin Developer',
		['{PLUGIN_VERSION}'] = config.version or '1.0.0',
		['{PLUGIN_LOWER}'] = config.variableName or (config.name and config.name:lower():gsub('%s', '') or 'myplugin'),
		['{PLUGIN_ICON_PATH}'] = config.iconPath or 'Interface\\Icons\\INV_Misc_QuestionMark',
		['{PLUGIN_ADDON_NAME}'] = config.addonName or config.name or 'MyPlugin',
	}

	for placeholder, replacement in pairs(replacements) do
		template = template:gsub(placeholder, replacement)
	end

	return template
end

---Get available templates
---@return table templates List of available templates
function PluginTemplates:GetTemplateList()
	return {
		{
			id = 'native',
			name = 'Native LibsDataBar Plugin',
			description = 'Full-featured plugin with complete LibsDataBar integration',
			recommended = true,
		},
		{
			id = 'ldb',
			name = 'LibDataBroker Plugin',
			description = 'Compatible with all LDB display addons',
			compatibility = true,
		},
	}
end

LibsDataBar:DebugLog('info', 'PluginTemplates loaded successfully')
