---@diagnostic disable: duplicate-set-field
--[===[ File: Options.lua
LibsDataBar Configuration Interface
Basic options setup for Phase 1 implementation
--]===]

-- Get the LibsDataBar addon
---@class LibsDataBar
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Local references
local L = {} -- Localization table (will be expanded later)
local AceConfig = LibStub('AceConfig-3.0', true)
local AceConfigDialog = LibStub('AceConfigDialog-3.0', true)

-- Basic localization (English only for now)
L['LibsDataBar'] = 'LibsDataBar'
L['Options'] = 'Options'
L['General'] = 'General'
L['Bars'] = 'Bars'
L['Plugins'] = 'Plugins'
L['Performance'] = 'Performance'
L['Theme'] = 'Theme'
L['Enable Debug Mode'] = 'Enable Debug Mode'
L['Show debug messages in chat'] = 'Show debug messages in chat'
L['Enable Performance Monitoring'] = 'Enable Performance Monitoring'
L['Track performance metrics for optimization'] = 'Track performance metrics for optimization'

---@class LibsDataBarOptions
local Options = {}

-- Configuration table for AceConfig
local configTable = {
	type = 'group',
	name = L['LibsDataBar'],
	args = {
		general = {
			type = 'group',
			name = L['General'],
			order = 1,
			args = {
				header = {
					type = 'header',
					name = L['LibsDataBar'] .. ' v' .. LibsDataBar.version,
					order = 0,
				},
				debugMode = {
					type = 'toggle',
					name = L['Enable Debug Mode'],
					desc = L['Show debug messages in chat'],
					order = 10,
					get = function()
						return LibsDataBar.config:GetConfig('global.developer.debugMode') or false
					end,
					set = function(_, value)
						LibsDataBar.config:SetConfig('global.developer.debugMode', value)
					end,
				},
				performanceMonitoring = {
					type = 'toggle',
					name = L['Enable Performance Monitoring'],
					desc = L['Track performance metrics for optimization'],
					order = 20,
					get = function()
						return LibsDataBar.config:GetConfig('global.performance.enableProfiler') or false
					end,
					set = function(_, value)
						LibsDataBar.config:SetConfig('global.performance.enableProfiler', value)
						LibsDataBar.performance.enabled = value
					end,
				},
			},
		},
		bars = {
			type = 'group',
			name = L['Bars'],
			order = 2,
			childGroups = 'tab',
			args = {
				multiBar = {
					type = 'group',
					name = 'Multi-Bar Management',
					order = 2,
					inline = true,
					args = {
						createBar = {
							type = 'execute',
							name = 'Create New Bar',
							desc = 'Create a new data bar with intelligent positioning',
							order = 1,
							func = function()
								local newBar = LibsDataBar:CreateQuickBar()
								if newBar then
									print('LibsDataBar: Created new bar: ' .. newBar.id)
									-- Refresh options to show the new bar
									Options:GenerateBarOptions()
									if AceConfigDialog and AceConfig then
										AceConfig:RegisterOptionsTable('LibsDataBar', configTable)
										if AceConfigDialog.RefreshOptionsPanel then AceConfigDialog:RefreshOptionsPanel('LibsDataBar') end
									end
								else
									print('LibsDataBar: Failed to create new bar')
								end
							end,
						},
						barList = {
							type = 'description',
							name = function()
								local bars = LibsDataBar:GetBarList()
								if #bars > 0 then
									return 'Active bars: ' .. table.concat(bars, ', ')
								else
									return 'No active bars'
								end
							end,
							order = 2,
						},
						deleteBar = {
							type = 'select',
							name = 'Delete Bar',
							desc = 'Select a bar to delete (cannot delete main bar)',
							order = 3,
							values = function()
								local values = {}
								for _, barId in ipairs(LibsDataBar:GetBarList()) do
									if barId ~= 'main' then values[barId] = barId end
								end
								return values
							end,
							disabled = function()
								local barList = LibsDataBar:GetBarList()
								return #barList <= 1
							end,
							get = function()
								return ''
							end,
							set = function(_, value)
								if value and value ~= '' and value ~= 'main' then
									if LibsDataBar:DeleteBar(value) then
										print('LibsDataBar: Deleted bar: ' .. value)
									else
										print('LibsDataBar: Failed to delete bar: ' .. value)
									end
								end
							end,
						},
					},
				},
			},
		},
		plugins = {
			type = 'group',
			name = L['Plugins'],
			order = 3,
			childGroups = 'tab',
			args = {
				builtin = {
					type = 'group',
					name = 'Built-in Plugins',
					order = 1,
					args = {
						description = {
							type = 'description',
							name = 'Enable or disable built-in LibsDataBar plugins. Changes take effect immediately.',
							order = 0,
						},
					},
				},
				ldb = {
					type = 'group',
					name = 'LibDataBroker',
					order = 2,
					args = {
						description = {
							type = 'description',
							name = 'LibDataBroker plugins are automatically detected and can be enabled here.',
							order = 0,
						},
						autoDiscovery = {
							type = 'toggle',
							name = 'Auto-Discovery',
							desc = 'Automatically detect and register new LibDataBroker plugins',
							order = 1,
							get = function()
								return LibsDataBar.ldb and LibsDataBar.ldb.autoDiscovery or false
							end,
							set = function(_, value)
								if LibsDataBar.ldb then LibsDataBar.ldb:SetAutoDiscovery(value) end
							end,
						},
					},
				},
			},
		},
		themes = {
			type = 'group',
			name = 'Themes',
			order = 4,
			args = {
				currentTheme = {
					type = 'select',
					name = 'Active Theme',
					desc = 'Select the active theme for all bars',
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
						return LibsDataBar.themes and LibsDataBar.themes.currentTheme or 'default'
					end,
					set = function(_, value)
						if LibsDataBar.themes then LibsDataBar.themes:SetCurrentTheme(value) end
					end,
				},
				description = {
					type = 'description',
					name = function()
						if LibsDataBar.themes then
							local theme = LibsDataBar.themes:GetCurrentTheme()
							if theme then return 'Current: ' .. (theme.name or 'Unknown') .. (theme.description and ('\n' .. theme.description) or '') end
						end
						return 'No theme information available'
					end,
					order = 2,
				},
				note = {
					type = 'description',
					name = 'Standard themes use proper backdrop system to avoid texture issues.',
					order = 10,
				},
			},
		},
	},
}

-- Initialize options
function Options:Initialize()
	-- Generate dynamic bar options
	self:GenerateBarOptions()

	-- Generate dynamic plugin options
	self:GeneratePluginOptions()

	-- Phase 2: Options registration moved to main addon AceConfig system
	-- This legacy system is disabled to prevent conflicts with new system
	LibsDataBar:DebugLog('info', 'Legacy options system disabled - using new AceConfig system in main addon')
end

-- Generate bar configuration options dynamically
function Options:GenerateBarOptions()
	local barArgs = configTable.args.bars.args

	-- Clear existing bar configurations (except multiBar management)
	for key, _ in pairs(barArgs) do
		if key ~= 'multiBar' then barArgs[key] = nil end
	end

	-- Generate options for each existing bar
	local barList = LibsDataBar:GetBarList()
	for i, barId in ipairs(barList) do
		local bar = LibsDataBar.bars[barId]
		if bar then
			local safeName = barId:gsub('[^%w]', '_')
			local displayName = barId == 'main' and 'Main Bar' or ('Bar: ' .. barId)

			barArgs[safeName] = {
				type = 'group',
				name = displayName,
				order = i,
				args = {
					enabled = {
						type = 'toggle',
						name = 'Show Bar',
						desc = 'Show or hide this data bar',
						order = 1,
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							return currentBar and currentBar.frame:IsShown()
						end,
						set = function(_, value)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								if value then
									currentBar:Show()
								else
									currentBar:Hide()
								end
							end
						end,
					},
					position = {
						type = 'select',
						name = 'Position',
						desc = 'Choose where to position this bar',
						order = 2,
						values = {
							['bottom'] = 'Bottom',
							['top'] = 'Top',
							['left'] = 'Left',
							['right'] = 'Right',
						},
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							return currentBar and currentBar.config.position or 'bottom'
						end,
						set = function(_, value)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.position = value
								currentBar:UpdatePosition()

								-- Notify integrations of position change
								if LibsDataBar.API then LibsDataBar.API:NotifyPositionChange(barId, 'move') end
							end
						end,
					},
					height = {
						type = 'range',
						name = 'Height',
						desc = 'Set the height of this bar',
						order = 3,
						min = 16,
						max = 48,
						step = 2,
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							return currentBar and currentBar.config.size.height or 24
						end,
						set = function(_, value)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.size.height = value
								currentBar:UpdateSize()
								currentBar:UpdateLayout()
							end
						end,
					},
					background = {
						type = 'toggle',
						name = 'Show Background',
						desc = 'Show background on this bar',
						order = 4,
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							return currentBar and currentBar.config.appearance.background.show or false
						end,
						set = function(_, value)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.appearance.background.show = value
								currentBar:UpdateAppearance()
							end
						end,
					},
					backgroundColor = {
						type = 'color',
						name = 'Background Color',
						desc = 'Set the background color and transparency',
						order = 4.5,
						hasAlpha = true,
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							if currentBar and currentBar.config.appearance.background.color then
								local c = currentBar.config.appearance.background.color
								return c.r, c.g, c.b, c.a
							end
							return 0, 0, 0, 0.8
						end,
						set = function(_, r, g, b, a)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.appearance.background.color = { r = r, g = g, b = b, a = a }
								currentBar:UpdateAppearance()
							end
						end,
						disabled = function()
							local currentBar = LibsDataBar.bars[barId]
							return not (currentBar and currentBar.config.appearance.background.show)
						end,
					},
					spacing = {
						type = 'range',
						name = 'Plugin Spacing',
						desc = 'Space between plugins on this bar',
						order = 5,
						min = 0,
						max = 20,
						step = 1,
						get = function()
							local currentBar = LibsDataBar.bars[barId]
							return currentBar and currentBar.config.layout.spacing or 2
						end,
						set = function(_, value)
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.layout.spacing = value
								currentBar:UpdateLayout()
							end
						end,
					},
					resetHeader = {
						type = 'header',
						name = 'Reset Options',
						order = 8,
					},
					resetPosition = {
						type = 'execute',
						name = 'Reset Position',
						desc = 'Reset bar position to default (bottom, 0,0)',
						order = 8.1,
						func = function()
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.position = 'bottom'
								currentBar.config.anchor.x = 0
								currentBar.config.anchor.y = 0
								currentBar:UpdatePosition()
								print('LibsDataBar: Reset position for bar ' .. barId)
							end
						end,
					},
					resetSize = {
						type = 'execute',
						name = 'Reset Size',
						desc = 'Reset bar size to default (height: 24)',
						order = 8.2,
						func = function()
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								currentBar.config.size.height = 24
								currentBar.config.size.scale = 1.0
								currentBar:UpdateSize()
								currentBar:UpdateLayout()
								print('LibsDataBar: Reset size for bar ' .. barId)
							end
						end,
					},
					resetAppearance = {
						type = 'execute',
						name = 'Reset Appearance',
						desc = 'Reset background and spacing to defaults',
						order = 8.3,
						func = function()
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								-- Reset to defaults
								currentBar.config.appearance.background.show = true
								currentBar.config.appearance.background.color = { r = 0, g = 0, b = 0, a = 0.8 }
								currentBar.config.layout.spacing = 4
								currentBar.config.layout.padding = { left = 8, right = 8, top = 2, bottom = 2 }
								currentBar:UpdateAppearance()
								currentBar:UpdateLayout()
								print('LibsDataBar: Reset appearance for bar ' .. barId)
							end
						end,
					},
					resetAll = {
						type = 'execute',
						name = 'Reset All Settings',
						desc = 'Reset all bar settings to defaults',
						order = 8.9,
						confirm = true,
						confirmText = 'Are you sure you want to reset all settings for this bar?',
						func = function()
							local currentBar = LibsDataBar.bars[barId]
							if currentBar then
								-- Reset position
								currentBar.config.position = 'bottom'
								currentBar.config.anchor.x = 0
								currentBar.config.anchor.y = 0

								-- Reset size
								currentBar.config.size.height = 24
								currentBar.config.size.scale = 1.0

								-- Reset appearance
								currentBar.config.appearance.background.show = true
								currentBar.config.appearance.background.color = { r = 0, g = 0, b = 0, a = 0.8 }

								-- Reset layout
								currentBar.config.layout.spacing = 4
								currentBar.config.layout.padding = { left = 8, right = 8, top = 2, bottom = 2 }

								-- Apply all changes
								currentBar:UpdatePosition()
								currentBar:UpdateSize()
								currentBar:UpdateAppearance()
								currentBar:UpdateLayout()

								print('LibsDataBar: Reset all settings for bar ' .. barId)

								-- Refresh options to show updated values
								if AceConfigDialog and AceConfigDialog.RefreshOptionsPanel then AceConfigDialog:RefreshOptionsPanel('LibsDataBar') end
							end
						end,
					},
					deleteBar = barId ~= 'main'
							and {
								type = 'execute',
								name = 'Delete This Bar',
								desc = 'Permanently delete this bar',
								order = 10,
								confirm = true,
								confirmText = 'Are you sure you want to delete this bar?',
								func = function()
									if LibsDataBar:DeleteBar(barId) then
										print('LibsDataBar: Deleted bar: ' .. barId)
										-- Refresh options
										Options:GenerateBarOptions()
										if AceConfigDialog and AceConfig then
											AceConfig:RegisterOptionsTable('LibsDataBar', configTable)
											if AceConfigDialog.RefreshOptionsPanel then AceConfigDialog:RefreshOptionsPanel('LibsDataBar') end
										end
									else
										print('LibsDataBar: Failed to delete bar: ' .. barId)
									end
								end,
							}
						or nil,
				},
			}
		end
	end
end

-- Generate plugin options dynamically
function Options:GeneratePluginOptions()
	local builtinArgs = configTable.args.plugins.args.builtin.args
	local ldbArgs = configTable.args.plugins.args.ldb.args

	-- Add built-in plugin toggles
	for pluginId, plugin in pairs(LibsDataBar.plugins or {}) do
		if plugin and plugin.name and plugin.type ~= 'ldb' then
			local safeName = pluginId:gsub('[^%w]', '_')
			builtinArgs[safeName] = {
				type = 'toggle',
				name = plugin.name,
				desc = plugin.description or ('Enable/disable ' .. plugin.name),
				order = 10,
				get = function()
					local mainBar = LibsDataBar.bars['main']
					return mainBar and mainBar.plugins[pluginId] ~= nil
				end,
				set = function(_, value)
					local mainBar = LibsDataBar.bars['main']
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
				local safeName = ldbName:gsub('[^%w]', '_')
				ldbArgs[safeName] = {
					type = 'toggle',
					name = wrapper.name or ldbName,
					desc = 'LibDataBroker plugin: ' .. ldbName,
					order = 20,
					get = function()
						local mainBar = LibsDataBar.bars['main']
						return mainBar and mainBar.plugins[wrapper.plugin.id] ~= nil
					end,
					set = function(_, value)
						local mainBar = LibsDataBar.bars['main']
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
local initFrame = CreateFrame('Frame')
initFrame:RegisterEvent('PLAYER_LOGIN')
initFrame:SetScript('OnEvent', function(self, event, addonName)
	C_Timer.After(2, function() -- Delay to ensure LibsDataBar defaults are setup
		Options:Initialize()
	end)
	self:UnregisterEvent('PLAYER_LOGIN')
end)

-- Refresh all dynamic options (for external use)
function Options:RefreshOptions()
	self:GenerateBarOptions()
	self:GeneratePluginOptions()
	if AceConfigDialog and AceConfig then
		AceConfig:RegisterOptionsTable('LibsDataBar', configTable)
		if AceConfigDialog.RefreshOptionsPanel then AceConfigDialog:RefreshOptionsPanel('LibsDataBar') end
	end
end

-- Export the options table for external access
LibsDataBar.Options = Options
