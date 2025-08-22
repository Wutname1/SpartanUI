---@diagnostic disable: duplicate-set-field
--[===[ File: Plugins/Volume.lua
LibsDataBar Volume Plugin
Displays and controls audio volume (Master, Music, Sound Effects)
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Plugin Definition
---@class VolumePlugin : Plugin
local VolumePlugin = {
	-- Required metadata
	id = 'LibsDataBar_Volume',
	name = 'Volume',
	version = '1.0.0',
	author = 'LibsDataBar Team',
	category = 'Audio',
	description = 'Displays and controls audio volume settings',

	-- Dependencies
	dependencies = {
		['LibsDataBar-1.0'] = '1.0.0',
	},

	-- Private variables
	_masterVolume = 1.0,
	_musicVolume = 1.0,
	_soundVolume = 1.0,
	_ambientVolume = 1.0,
	_dialogVolume = 1.0,
}

-- Plugin Configuration Defaults
local volumeDefaults = {
	displayType = 'master', -- 'master', 'music', 'sound', 'all', 'custom'
	showIcon = true,
	showPercent = true,
	enableMouseWheel = true,
	wheelStep = 5, -- Percent per scroll
	colorByLevel = true,
	showAllInTooltip = true,
	volumeStep = 0.1, -- Step for click adjustments
}

-- Volume type mappings
local VOLUME_TYPES = {
	master = { cvar = 'Sound_MasterVolume', name = 'Master' },
	music = { cvar = 'Sound_MusicVolume', name = 'Music' },
	sound = { cvar = 'Sound_SFXVolume', name = 'Sound Effects' },
	ambient = { cvar = 'Sound_AmbienceVolume', name = 'Ambient' },
	dialog = { cvar = 'Sound_DialogVolume', name = 'Dialog' },
}

---Required: Get the display text for this plugin
---@return string text Display text
function VolumePlugin:GetText()
	local displayType = self:GetConfig('displayType')
	local showPercent = self:GetConfig('showPercent')
	local colorByLevel = self:GetConfig('colorByLevel')

	self:UpdateVolumeData()

	local volume, volumeName

	if displayType == 'master' then
		volume = self._masterVolume
		volumeName = 'Master'
	elseif displayType == 'music' then
		volume = self._musicVolume
		volumeName = 'Music'
	elseif displayType == 'sound' then
		volume = self._soundVolume
		volumeName = 'SFX'
	elseif displayType == 'all' then
		-- Show all three main volumes
		local text = string.format('M:%d%% | Mu:%d%% | S:%d%%', self._masterVolume * 100, self._musicVolume * 100, self._soundVolume * 100)
		return colorByLevel and self:ApplyVolumeColor(text, self._masterVolume) or text
	else
		-- Default to master
		volume = self._masterVolume
		volumeName = 'Vol'
	end

	local percent = math.floor(volume * 100)
	local text

	if showPercent then
		text = string.format('%s: %d%%', volumeName, percent)
	else
		text = volumeName
	end

	-- Apply color coding based on volume level
	if colorByLevel then text = self:ApplyVolumeColor(text, volume) end

	return text
end

---Optional: Get the icon for this plugin
---@return string icon Icon texture path
function VolumePlugin:GetIcon()
	local displayType = self:GetConfig('displayType')
	local volume

	if displayType == 'music' then
		volume = self._musicVolume
		if volume == 0 then
			return 'Interface\\Icons\\Spell_Shadow_Silence'
		else
			return 'Interface\\Icons\\INV_Misc_Drum_04'
		end
	elseif displayType == 'sound' then
		volume = self._soundVolume
	else
		volume = self._masterVolume
	end

	-- Return appropriate volume icon based on level
	if volume == 0 then
		return 'Interface\\Icons\\Spell_Shadow_Silence' -- Muted
	elseif volume < 0.33 then
		return 'Interface\\Icons\\Spell_Nature_Purge' -- Low volume
	elseif volume < 0.66 then
		return 'Interface\\Icons\\Spell_Holy_Silence' -- Medium volume
	else
		return 'Interface\\Icons\\Spell_Frost_WindWalk' -- High volume
	end
end

---Optional: Get tooltip information
---@return string tooltip Tooltip text
function VolumePlugin:GetTooltip()
	self:UpdateVolumeData()

	local tooltip = 'Audio Volume Settings:\\n\\n'

	-- Show all volume types if enabled
	if self:GetConfig('showAllInTooltip') then
		tooltip = tooltip .. string.format('Master Volume: %d%%\\n', self._masterVolume * 100)
		tooltip = tooltip .. string.format('Music Volume: %d%%\\n', self._musicVolume * 100)
		tooltip = tooltip .. string.format('Sound Effects: %d%%\\n', self._soundVolume * 100)
		tooltip = tooltip .. string.format('Ambient Volume: %d%%\\n', self._ambientVolume * 100)
		tooltip = tooltip .. string.format('Dialog Volume: %d%%\\n', self._dialogVolume * 100)
	else
		-- Show only the selected type
		local displayType = self:GetConfig('displayType')
		local volume, name

		if displayType == 'master' then
			volume = self._masterVolume
			name = 'Master Volume'
		elseif displayType == 'music' then
			volume = self._musicVolume
			name = 'Music Volume'
		elseif displayType == 'sound' then
			volume = self._soundVolume
			name = 'Sound Effects Volume'
		else
			volume = self._masterVolume
			name = 'Master Volume'
		end

		tooltip = tooltip .. string.format('%s: %d%%\\n', name, volume * 100)
	end

	tooltip = tooltip .. '\\nControls:\\n'
	tooltip = tooltip .. 'Left-click: Toggle mute\\n'
	tooltip = tooltip .. 'Right-click: Configuration options\\n'
	tooltip = tooltip .. 'Middle-click: Cycle display mode\\n'

	if self:GetConfig('enableMouseWheel') then tooltip = tooltip .. string.format('Scroll wheel: Adjust volume (±%d%%)\\n', self:GetConfig('wheelStep')) end

	return tooltip
end

---Optional: Handle mouse clicks
---@param button string Mouse button
function VolumePlugin:OnClick(button)
	local displayType = self:GetConfig('displayType')

	if button == 'LeftButton' then
		-- Toggle mute for the displayed volume type
		self:ToggleMute(displayType)
	elseif button == 'RightButton' then
		-- Show configuration menu (placeholder)
		LibsDataBar:DebugLog('info', 'Volume configuration menu (coming in Phase 2)')
	elseif button == 'MiddleButton' then
		-- Cycle through display modes
		self:CycleDisplayMode()
	end
end

---Optional: Handle mouse wheel scrolling
---@param delta number Scroll direction (+1 up, -1 down)
function VolumePlugin:OnMouseWheel(delta)
	if not self:GetConfig('enableMouseWheel') then return end

	local displayType = self:GetConfig('displayType')
	local step = self:GetConfig('wheelStep') / 100 -- Convert to decimal

	if delta > 0 then
		self:AdjustVolume(displayType, step)
	else
		self:AdjustVolume(displayType, -step)
	end
end

---Update volume data from game settings
function VolumePlugin:UpdateVolumeData()
	self._masterVolume = tonumber(GetCVar('Sound_MasterVolume')) or 1.0
	self._musicVolume = tonumber(GetCVar('Sound_MusicVolume')) or 1.0
	self._soundVolume = tonumber(GetCVar('Sound_SFXVolume')) or 1.0
	self._ambientVolume = tonumber(GetCVar('Sound_AmbienceVolume')) or 1.0
	self._dialogVolume = tonumber(GetCVar('Sound_DialogVolume')) or 1.0
end

---Apply color coding based on volume level
---@param text string Text to color
---@param volume number Volume level (0-1)
---@return string coloredText Colored text
function VolumePlugin:ApplyVolumeColor(text, volume)
	if volume == 0 then
		return '|cFFFF0000' .. text .. '|r' -- Red for muted
	elseif volume < 0.25 then
		return '|cFFFF8000' .. text .. '|r' -- Orange for very low
	elseif volume < 0.5 then
		return '|cFFFFFF00' .. text .. '|r' -- Yellow for low
	elseif volume < 0.75 then
		return '|cFFFFFFFF' .. text .. '|r' -- White for normal
	else
		return '|cFF00FF00' .. text .. '|r' -- Green for high
	end
end

---Toggle mute for a volume type
---@param volumeType string Volume type to toggle
function VolumePlugin:ToggleMute(volumeType)
	local volumeInfo = VOLUME_TYPES[volumeType] or VOLUME_TYPES.master
	local currentVolume = tonumber(GetCVar(volumeInfo.cvar)) or 1.0

	if currentVolume > 0 then
		-- Store current volume and mute
		self:SetConfig('saved_' .. volumeType, currentVolume)
		SetCVar(volumeInfo.cvar, 0)
		LibsDataBar:DebugLog('info', volumeInfo.name .. ' volume muted')
	else
		-- Restore previous volume or set to 50% if none saved
		local savedVolume = self:GetConfig('saved_' .. volumeType) or 0.5
		SetCVar(volumeInfo.cvar, savedVolume)
		LibsDataBar:DebugLog('info', volumeInfo.name .. ' volume restored to ' .. (savedVolume * 100) .. '%')
	end

	self:UpdateVolumeData()
end

---Adjust volume by a specific amount
---@param volumeType string Volume type to adjust
---@param delta number Amount to adjust (-1 to 1)
function VolumePlugin:AdjustVolume(volumeType, delta)
	local volumeInfo = VOLUME_TYPES[volumeType] or VOLUME_TYPES.master
	local currentVolume = tonumber(GetCVar(volumeInfo.cvar)) or 1.0
	local newVolume = math.max(0, math.min(1, currentVolume + delta))

	SetCVar(volumeInfo.cvar, newVolume)
	self:UpdateVolumeData()

	LibsDataBar:DebugLog('info', string.format('%s volume adjusted to %d%%', volumeInfo.name, newVolume * 100))
end

---Cycle through different display modes
function VolumePlugin:CycleDisplayMode()
	local modes = { 'master', 'music', 'sound', 'all' }
	local current = self:GetConfig('displayType')
	local currentIndex = 1

	-- Find current mode index
	for i, mode in ipairs(modes) do
		if mode == current then
			currentIndex = i
			break
		end
	end

	-- Move to next mode (wrap around)
	local nextIndex = currentIndex < #modes and currentIndex + 1 or 1
	local nextMode = modes[nextIndex]

	self:SetConfig('displayType', nextMode)
	LibsDataBar:DebugLog('info', 'Volume display mode changed to: ' .. nextMode)
end

---Get configuration options
---@return table options AceConfig options table
function VolumePlugin:GetConfigOptions()
	return {
		type = 'group',
		name = self.name,
		desc = self.description,
		args = {
			displayType = {
				type = 'select',
				name = 'Display Type',
				desc = 'Choose which volume to display',
				order = 10,
				values = {
					master = 'Master Volume',
					music = 'Music Volume',
					sound = 'Sound Effects',
					all = 'All Volumes',
				},
				get = function()
					return self:GetConfig('displayType')
				end,
				set = function(_, value)
					self:SetConfig('displayType', value)
				end,
			},
			showPercent = {
				type = 'toggle',
				name = 'Show Percentage',
				desc = 'Display volume as percentage',
				order = 20,
				get = function()
					return self:GetConfig('showPercent')
				end,
				set = function(_, value)
					self:SetConfig('showPercent', value)
				end,
			},
			colorByLevel = {
				type = 'toggle',
				name = 'Color by Volume Level',
				desc = 'Use colors to indicate volume level',
				order = 30,
				get = function()
					return self:GetConfig('colorByLevel')
				end,
				set = function(_, value)
					self:SetConfig('colorByLevel', value)
				end,
			},
			enableMouseWheel = {
				type = 'toggle',
				name = 'Enable Mouse Wheel',
				desc = 'Allow volume adjustment with mouse wheel',
				order = 40,
				get = function()
					return self:GetConfig('enableMouseWheel')
				end,
				set = function(_, value)
					self:SetConfig('enableMouseWheel', value)
				end,
			},
			wheelStep = {
				type = 'range',
				name = 'Wheel Step Size',
				desc = 'Percentage to adjust per scroll wheel step',
				order = 50,
				min = 1,
				max = 20,
				step = 1,
				get = function()
					return self:GetConfig('wheelStep')
				end,
				set = function(_, value)
					self:SetConfig('wheelStep', value)
				end,
			},
		},
	}
end

---Get default configuration
---@return table defaults Default configuration table
function VolumePlugin:GetDefaultConfig()
	return volumeDefaults
end

---Lifecycle: Plugin initialization
function VolumePlugin:OnInitialize()
	self:UpdateVolumeData()
	LibsDataBar:DebugLog('info', 'Volume plugin initialized')
end

---Lifecycle: Plugin enabled
function VolumePlugin:OnEnable()
	-- Register for sound/UI events
	self:RegisterEvent('CVAR_UPDATE', 'OnCVarUpdate')
	LibsDataBar:DebugLog('info', 'Volume plugin enabled')
end

---Lifecycle: Plugin disabled
function VolumePlugin:OnDisable()
	self:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Volume plugin disabled')
end

---Event handler for CVar updates
---@param cvarName string Name of the changed CVar
function VolumePlugin:OnCVarUpdate(cvarName)
	-- Check if it's a volume-related CVar
	for _, volumeInfo in pairs(VOLUME_TYPES) do
		if cvarName == volumeInfo.cvar then
			self:UpdateVolumeData()
			if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_PluginUpdate', self.id) end
			break
		end
	end
end

---Helper: Register for an event
---@param event string Event name
---@param method string Method name to call
function VolumePlugin:RegisterEvent(event, method)
	LibsDataBar.events:RegisterEvent(event, function(...)
		if self[method] then self[method](self, ...) end
	end, { owner = self.id })
end

---Helper: Unregister all events
function VolumePlugin:UnregisterAllEvents()
	LibsDataBar:DebugLog('info', 'Volume plugin events unregistered')
end

---Helper: Get plugin configuration value
---@param key string Configuration key
---@return any value Configuration value
function VolumePlugin:GetConfig(key)
	return LibsDataBar.config:GetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key) or volumeDefaults[key]
end

---Helper: Set plugin configuration value
---@param key string Configuration key
---@param value any Configuration value
function VolumePlugin:SetConfig(key, value)
	return LibsDataBar.config:SetConfig('plugins.' .. self.id .. '.pluginSettings.' .. key, value)
end

-- Initialize the plugin
VolumePlugin:OnInitialize()

-- Register as LibDataBroker object for standardized plugin system
local LDB = LibStub:GetLibrary('LibDataBroker-1.1', true)
if LDB then
	local volumeLDBObject = LDB:NewDataObject('LibsDataBar_Volume', {
		type = 'data source',
		text = VolumePlugin:GetText(),
		icon = VolumePlugin:GetIcon(),
		label = VolumePlugin.name,

		-- Forward methods to VolumePlugin with database access preserved
		OnClick = function(self, button)
			VolumePlugin:OnClick(button)
		end,

		OnTooltipShow = function(tooltip)
			local tooltipText = VolumePlugin:GetTooltip()
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
			self.text = VolumePlugin:GetText()
			self.icon = VolumePlugin:GetIcon()
		end,
	})

	-- Store reference for updates
	VolumePlugin._ldbObject = volumeLDBObject

	LibsDataBar:DebugLog('info', 'Volume plugin registered as LibDataBroker object')
else
	LibsDataBar:DebugLog('error', 'LibDataBroker not available for Volume plugin')
end

-- Return plugin for external access
return VolumePlugin
