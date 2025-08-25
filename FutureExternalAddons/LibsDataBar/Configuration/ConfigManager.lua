---@diagnostic disable: duplicate-set-field
--[===[ File: Configuration/ConfigManager.lua
LibsDataBar Advanced Configuration Management System
Real-time preview, templates, presets, and advanced configuration features
--]===]

-- Get the LibsDataBar addon
---@class LibsDataBar
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- AceGUI for interface elements
local AceGUI = LibStub('AceGUI-3.0', true)
local AceConfig = LibStub('AceConfig-3.0', true)
local AceConfigDialog = LibStub('AceConfigDialog-3.0', true)

---@class ConfigManager
---@field previewMode boolean Whether preview mode is active
---@field previewChanges table Temporary changes for preview
---@field configTemplates table<string, table> Configuration templates
---@field configPresets table<string, table> User presets
---@field advancedFrame AceGUIFrame|nil Advanced config frame
---@field realTimeCallbacks table<string, function> Real-time change callbacks
local ConfigManager = {}

-- Enhanced Configuration Manager for LibsDataBar
LibsDataBar.configManager = LibsDataBar.configManager
	or setmetatable({
		previewMode = false,
		previewChanges = {},
		configTemplates = {},
		configPresets = {},
		advancedFrame = nil,
		realTimeCallbacks = {},
	}, { __index = ConfigManager })

-- Configuration Templates
local CONFIG_TEMPLATES = {
	['minimal'] = {
		name = 'Minimal Setup',
		description = 'Clean, minimal configuration with essential plugins only',
		config = {
			bars = {
				main = {
					position = 'bottom',
					size = { height = 20 },
					appearance = {
						background = { show = false },
						border = { show = false },
					},
					plugins = { 'Clock', 'Currency', 'Performance', 'Location' },
				},
			},
			theme = 'minimal',
			animation = { enabled = false },
		},
	},
	['gaming'] = {
		name = 'Gaming Focused',
		description = 'Performance monitoring and gaming-focused plugins',
		config = {
			bars = {
				main = {
					position = 'top',
					size = { height = 24 },
					appearance = {
						background = { show = true, alpha = 0.8 },
						border = { show = true },
					},
					plugins = { 'Performance', 'Repair', 'Bags', 'PlayedTime' },
				},
			},
			theme = 'gaming',
			animation = { enabled = true, speed = 'fast' },
		},
	},
	['information'] = {
		name = 'Information Rich',
		description = 'Maximum information display with multiple bars',
		config = {
			bars = {
				main = {
					position = 'bottom',
					size = { height = 26 },
					plugins = { 'Clock', 'Currency', 'Location', 'Reputation' },
				},
				secondary = {
					position = 'top',
					size = { height = 22 },
					plugins = { 'Performance', 'Bags', 'Friends', 'Volume' },
				},
			},
			theme = 'default',
			animation = { enabled = true, speed = 'normal' },
		},
	},
	['development'] = {
		name = 'Development Setup',
		description = 'Configuration optimized for addon development',
		config = {
			bars = {
				main = {
					position = 'bottom',
					size = { height = 28 },
					plugins = { 'Performance', 'Clock', 'Location' },
				},
				debug = {
					position = 'top',
					size = { height = 20 },
					plugins = { 'Currency', 'Bags' },
				},
			},
			theme = 'dark',
			debug = { enabled = true, categories = { 'all' } },
			hotReload = { enabled = true },
		},
	},
}

---Initialize the advanced configuration manager
function ConfigManager:Initialize()
	-- Load templates
	for templateId, template in pairs(CONFIG_TEMPLATES) do
		self.configTemplates[templateId] = template
	end

	-- Load user presets from saved variables
	self:LoadUserPresets()

	-- Initialize real-time callbacks
	self:InitializeRealTimeCallbacks()

	LibsDataBar:DebugLog('info', 'Advanced configuration manager initialized', 'config')
end

---Load user presets from saved variables
function ConfigManager:LoadUserPresets()
	local savedPresets = LibsDataBar.config:GetConfig('global.configuration.userPresets') or {}
	for presetId, preset in pairs(savedPresets) do
		self.configPresets[presetId] = preset
	end

	LibsDataBar:DebugLog('debug', string.format('Loaded %d user presets', self:GetPresetCount()), 'config')
end

---Save user presets to saved variables
function ConfigManager:SaveUserPresets()
	LibsDataBar.config:SetConfig('global.configuration.userPresets', self.configPresets)
	LibsDataBar:DebugLog('debug', 'User presets saved', 'config')
end

---Initialize real-time configuration callbacks
function ConfigManager:InitializeRealTimeCallbacks()
	-- Bar appearance changes
	self.realTimeCallbacks['bar.appearance'] = function(barId, config)
		local bar = LibsDataBar.bars[barId]
		if bar and bar.UpdateAppearance then bar:UpdateAppearance() end
	end

	-- Bar position changes
	self.realTimeCallbacks['bar.position'] = function(barId, config)
		local bar = LibsDataBar.bars[barId]
		if bar and bar.UpdatePosition then bar:UpdatePosition() end
	end

	-- Theme changes
	self.realTimeCallbacks['theme'] = function(themeId)
		if LibsDataBar.themes then LibsDataBar.themes:SetCurrentTheme(themeId) end
	end

	-- Plugin changes
	self.realTimeCallbacks['plugins'] = function(barId, pluginChanges)
		local bar = LibsDataBar.bars[barId]
		if not bar then return end

		for pluginId, enabled in pairs(pluginChanges) do
			local plugin = LibsDataBar.plugins[pluginId]
			if plugin then
				if enabled and not bar.plugins[pluginId] then
					bar:AddPlugin(plugin)
				elseif not enabled and bar.plugins[pluginId] then
					bar:RemovePlugin(pluginId)
				end
			end
		end
	end
end

---Start preview mode
function ConfigManager:StartPreview()
	if self.previewMode then return end

	self.previewMode = true
	self.previewChanges = {}

	LibsDataBar:DebugLog('info', 'Configuration preview mode started', 'config')
end

---Apply a preview change
---@param configPath string Configuration path (e.g., "bars.main.position")
---@param value any New value
function ConfigManager:ApplyPreviewChange(configPath, value)
	if not self.previewMode then self:StartPreview() end

	-- Store the change
	self.previewChanges[configPath] = value

	-- Apply change temporarily
	self:ApplyTemporaryChange(configPath, value)

	-- Trigger real-time callback if available
	self:TriggerRealTimeCallback(configPath, value)

	LibsDataBar:DebugLog('debug', string.format('Preview change applied: %s = %s', configPath, tostring(value)), 'config')
end

---Apply a temporary change for preview
---@param configPath string Configuration path
---@param value any New value
function ConfigManager:ApplyTemporaryChange(configPath, value)
	local pathParts = { strsplit('.', configPath) }

	-- Handle different configuration types
	if pathParts[1] == 'bars' then
		self:ApplyBarChange(pathParts, value)
	elseif pathParts[1] == 'theme' then
		self:ApplyThemeChange(value)
	elseif pathParts[1] == 'plugins' then
		self:ApplyPluginChange(pathParts, value)
	end
end

---Apply bar configuration change
---@param pathParts table Path components
---@param value any New value
function ConfigManager:ApplyBarChange(pathParts, value)
	if #pathParts < 3 then return end

	local barId = pathParts[2]
	local property = pathParts[3]
	local bar = LibsDataBar.bars[barId]

	if not bar then return end

	if property == 'position' then
		bar.config.position = value
		if bar.UpdatePosition then bar:UpdatePosition() end
	elseif property == 'size' and pathParts[4] then
		if pathParts[4] == 'height' then
			bar.config.size.height = value
			if bar.UpdateSize then bar:UpdateSize() end
		elseif pathParts[4] == 'width' then
			bar.config.size.width = value
			if bar.UpdateSize then bar:UpdateSize() end
		end
	elseif property == 'appearance' then
		-- Handle nested appearance properties
		if pathParts[4] == 'background' and pathParts[5] then
			if pathParts[5] == 'show' then
				bar.config.appearance.background.show = value
			elseif pathParts[5] == 'alpha' then
				bar.config.appearance.background.alpha = value
			end
			if bar.UpdateAppearance then bar:UpdateAppearance() end
		end
	end
end

---Apply theme change
---@param themeId string Theme ID
function ConfigManager:ApplyThemeChange(themeId)
	if LibsDataBar.themes then LibsDataBar.themes:SetCurrentTheme(themeId) end
end

---Apply plugin change
---@param pathParts table Path components
---@param value any New value
function ConfigManager:ApplyPluginChange(pathParts, value)
	if #pathParts < 3 then return end

	local barId = pathParts[2]
	local pluginId = pathParts[3]

	local bar = LibsDataBar.bars[barId]
	local plugin = LibsDataBar.plugins[pluginId]

	if not bar or not plugin then return end

	if value and not bar.plugins[pluginId] then
		bar:AddPlugin(plugin)
	elseif not value and bar.plugins[pluginId] then
		bar:RemovePlugin(pluginId)
	end
end

---Trigger real-time callback
---@param configPath string Configuration path
---@param value any New value
function ConfigManager:TriggerRealTimeCallback(configPath, value)
	local pathParts = { strsplit('.', configPath) }
	local callbackKey = pathParts[1]
	if #pathParts > 1 then callbackKey = pathParts[1] .. '.' .. pathParts[2] end

	local callback = self.realTimeCallbacks[callbackKey]
	if callback then pcall(callback, pathParts[2], value) end
end

---Commit preview changes
function ConfigManager:CommitPreview()
	if not self.previewMode then return end

	-- Apply all changes permanently
	for configPath, value in pairs(self.previewChanges) do
		LibsDataBar.config:SetConfig(configPath, value)
	end

	-- Clear preview state
	self.previewMode = false
	self.previewChanges = {}

	LibsDataBar:DebugLog('info', 'Configuration preview changes committed', 'config')
	print('LibsDataBar: Configuration changes applied successfully')
end

---Cancel preview changes
function ConfigManager:CancelPreview()
	if not self.previewMode then return end

	-- Revert all changes
	for configPath, _ in pairs(self.previewChanges) do
		local currentValue = LibsDataBar.config:GetConfig(configPath)
		self:ApplyTemporaryChange(configPath, currentValue)
	end

	-- Clear preview state
	self.previewMode = false
	self.previewChanges = {}

	LibsDataBar:DebugLog('info', 'Configuration preview changes cancelled', 'config')
	print('LibsDataBar: Configuration changes cancelled')
end

---Apply a configuration template
---@param templateId string Template ID to apply
function ConfigManager:ApplyTemplate(templateId)
	local template = self.configTemplates[templateId]
	if not template then
		LibsDataBar:DebugLog('warning', 'Unknown configuration template: ' .. templateId, 'config')
		return false
	end

	LibsDataBar:DebugLog('info', 'Applying configuration template: ' .. template.name, 'config')

	-- Start preview mode
	self:StartPreview()

	-- Apply template configuration
	self:ApplyConfiguration(template.config)

	print("LibsDataBar: Applied template '" .. template.name .. "' - Preview active")
	return true
end

---Apply a configuration preset
---@param presetId string Preset ID to apply
function ConfigManager:ApplyPreset(presetId)
	local preset = self.configPresets[presetId]
	if not preset then
		LibsDataBar:DebugLog('warning', 'Unknown configuration preset: ' .. presetId, 'config')
		return false
	end

	LibsDataBar:DebugLog('info', 'Applying configuration preset: ' .. preset.name, 'config')

	-- Start preview mode
	self:StartPreview()

	-- Apply preset configuration
	self:ApplyConfiguration(preset.config)

	print("LibsDataBar: Applied preset '" .. preset.name .. "' - Preview active")
	return true
end

---Apply a configuration recursively
---@param config table Configuration to apply
---@param basePath string|nil Base configuration path
function ConfigManager:ApplyConfiguration(config, basePath)
	basePath = basePath or ''

	for key, value in pairs(config) do
		local configPath = basePath == '' and key or (basePath .. '.' .. key)

		if type(value) == 'table' and not self:IsValueTable(value) then
			-- Recursively apply nested configuration
			self:ApplyConfiguration(value, configPath)
		else
			-- Apply the value
			self:ApplyPreviewChange(configPath, value)
		end
	end
end

---Check if a table represents a value rather than nested config
---@param t table Table to check
---@return boolean isValue Whether this is a value table
function ConfigManager:IsValueTable(t)
	-- Check for common value table patterns
	if t.r and t.g and t.b then return true end -- Color table
	if t.width and t.height then return true end -- Size table
	if t.x and t.y then return true end -- Position table
	if t[1] then return true end -- Array table

	return false
end

---Save current configuration as a preset
---@param name string Preset name
---@param description string|nil Preset description
function ConfigManager:SaveAsPreset(name, description)
	local currentConfig = self:ExportCurrentConfiguration()

	local presetId = name:lower():gsub('%s', '_')
	self.configPresets[presetId] = {
		name = name,
		description = description or 'User created preset',
		config = currentConfig,
		created = time(),
	}

	self:SaveUserPresets()

	LibsDataBar:DebugLog('info', 'Configuration preset saved: ' .. name, 'config')
	print("LibsDataBar: Configuration saved as preset '" .. name .. "'")
end

---Export current configuration
---@return table config Current configuration
function ConfigManager:ExportCurrentConfiguration()
	local config = {}

	-- Export bar configurations
	config.bars = {}
	for barId, bar in pairs(LibsDataBar.bars or {}) do
		config.bars[barId] = {
			position = bar.config.position,
			size = {
				width = bar.config.size.width,
				height = bar.config.size.height,
			},
			appearance = bar.config.appearance,
			plugins = {},
		}

		-- Export enabled plugins
		for pluginId, _ in pairs(bar.plugins or {}) do
			table.insert(config.bars[barId].plugins, pluginId)
		end
	end

	-- Export theme
	if LibsDataBar.themes then config.theme = LibsDataBar.themes.currentTheme end

	-- Export other relevant settings
	config.debug = {
		enabled = LibsDataBar.debugger and LibsDataBar.debugger.enabled or false,
	}

	return config
end

---Get available templates
---@return table templates List of available templates
function ConfigManager:GetTemplateList()
	local templates = {}
	for templateId, template in pairs(self.configTemplates) do
		table.insert(templates, {
			id = templateId,
			name = template.name,
			description = template.description,
		})
	end
	return templates
end

---Get available presets
---@return table presets List of available presets
function ConfigManager:GetPresetList()
	local presets = {}
	for presetId, preset in pairs(self.configPresets) do
		table.insert(presets, {
			id = presetId,
			name = preset.name,
			description = preset.description,
			created = preset.created,
		})
	end
	return presets
end

---Get number of presets
---@return number count Number of presets
function ConfigManager:GetPresetCount()
	local count = 0
	for _ in pairs(self.configPresets) do
		count = count + 1
	end
	return count
end

---Delete a preset
---@param presetId string Preset ID to delete
function ConfigManager:DeletePreset(presetId)
	if not self.configPresets[presetId] then return false end

	local presetName = self.configPresets[presetId].name
	self.configPresets[presetId] = nil
	self:SaveUserPresets()

	LibsDataBar:DebugLog('info', 'Configuration preset deleted: ' .. presetName, 'config')
	print("LibsDataBar: Preset '" .. presetName .. "' deleted")
	return true
end

-- Add enhanced slash commands
SLASH_LDB_CONFIG1 = '/ldb-config'
SlashCmdList['LDB_CONFIG'] = function(msg)
	local args = { strsplit(' ', msg) }
	local command = args[1] or ''

	if command == 'template' then
		local templateId = args[2]
		if templateId then
			if LibsDataBar.configManager:ApplyTemplate(templateId) then print("Use '/ldb-config commit' to apply or '/ldb-config cancel' to revert") end
		else
			print('Available templates:')
			for _, template in ipairs(LibsDataBar.configManager:GetTemplateList()) do
				print('  ' .. template.id .. ': ' .. template.name)
			end
		end
	elseif command == 'preset' then
		local presetId = args[2]
		if presetId then
			if LibsDataBar.configManager:ApplyPreset(presetId) then print("Use '/ldb-config commit' to apply or '/ldb-config cancel' to revert") end
		else
			print('Available presets:')
			for _, preset in ipairs(LibsDataBar.configManager:GetPresetList()) do
				print('  ' .. preset.id .. ': ' .. preset.name)
			end
		end
	elseif command == 'save' then
		local name = table.concat(args, ' ', 2)
		if name and name ~= '' then
			LibsDataBar.configManager:SaveAsPreset(name)
		else
			print('Usage: /ldb-config save <preset name>')
		end
	elseif command == 'commit' then
		LibsDataBar.configManager:CommitPreview()
	elseif command == 'cancel' then
		LibsDataBar.configManager:CancelPreview()
	elseif command == 'export' then
		local config = LibsDataBar.configManager:ExportCurrentConfiguration()
		LibsDataBar.debugger:DumpObject(config, 'Current Configuration')
	else
		print('LibsDataBar Advanced Configuration Commands:')
		print('  /ldb-config template [id] - Apply template or list templates')
		print('  /ldb-config preset [id] - Apply preset or list presets')
		print('  /ldb-config save <name> - Save current config as preset')
		print('  /ldb-config commit - Apply preview changes')
		print('  /ldb-config cancel - Cancel preview changes')
		print('  /ldb-config export - Export current configuration')
	end
end

-- Initialize when ready
LibsDataBar.configManager:Initialize()

LibsDataBar:DebugLog('info', 'Advanced configuration manager loaded successfully', 'config')
