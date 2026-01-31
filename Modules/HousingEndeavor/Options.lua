---@class SUI
local SUI = SUI
local L = SUI.L

-- Only available in Retail
if not SUI.IsRetail then
	return
end

---@class SUI.Module.HousingEndeavor
local module = SUI.HousingEndeavor

-- Text format options for dropdown
local FORMAT_OPTIONS = {
	detailed = L['Detailed'] .. ' |cff888888(Milestone 2: 125.0 / 250.0 (125.0 XP needed))|r',
	simple = L['Simple'] .. ' |cff888888(125.0 XP to Milestone 2)|r',
	percentage = L['Percentage'] .. ' |cff888888(50.0% to M2 - 125.0 XP needed)|r',
	short = L['Short'] .. ' |cff888888(To M2: 125.0 XP)|r',
	minimal = L['Minimal'] .. ' |cff888888(125.0 XP)|r',
	nextfinal = L['Next/Final'] .. ' |cff888888(Next: 125.0 XP | Final: 875.0 XP)|r',
	progress = L['Progress'] .. ' |cff888888(M2 Progress: 125.0/250.0 (50.0%))|r',
}

function module:BuildOptions()
	---@type AceConfig.OptionsTable
	local options = {
		type = 'group',
		name = L['Housing Endeavor'],
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			description = {
				type = 'description',
				name = L['Tracks Housing Endeavor progress (neighborhood contribution XP toward seasonal milestones).'],
				order = 0,
				fontSize = 'medium',
			},
			availability = {
				type = 'description',
				name = function()
					if module:IsInitiativeAvailable() then
						return '|cff00ff00' .. L['Housing Initiative system is available'] .. '|r'
					else
						return '|cffff0000' .. L['Housing Initiative system is not available'] .. '|r'
					end
				end,
				order = 1,
				fontSize = 'medium',
			},
			spacer1 = {
				type = 'description',
				name = ' ',
				order = 2,
			},
			progressEnabled = {
				type = 'toggle',
				name = L['Enable Progress Overlay'],
				desc = L['Show XP progress above the Endeavor progress bar.'],
				order = 10,
				width = 'full',
				get = function()
					return module.DB.progressOverlay.enabled
				end,
				set = function(_, val)
					module.DB.progressOverlay.enabled = val
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
			progressFormat = {
				type = 'select',
				name = L['Text Format'],
				desc = L['Choose how the progress text is displayed.'],
				order = 11,
				width = 'double',
				values = FORMAT_OPTIONS,
				get = function()
					return module.DB.progressOverlay.format
				end,
				set = function(_, val)
					module.DB.progressOverlay.format = val
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
			progressColor = {
				type = 'color',
				name = L['Text Color'],
				order = 12,
				hasAlpha = false,
				get = function()
					local c = module.DB.progressOverlay.color
					return c.r, c.g, c.b
				end,
				set = function(_, r, g, b)
					module.DB.progressOverlay.color.r = r
					module.DB.progressOverlay.color.g = g
					module.DB.progressOverlay.color.b = b
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
			spacer2 = {
				type = 'description',
				name = ' ',
				order = 15,
			},
			taskTooltipsEnabled = {
				type = 'toggle',
				name = L['Enable Task Tooltips'],
				desc = L['Show XP contribution when hovering over completed tasks.'],
				order = 20,
				width = 'full',
				get = function()
					return module.DB.taskTooltips.enabled
				end,
				set = function(_, val)
					module.DB.taskTooltips.enabled = val
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
			spacer3 = {
				type = 'description',
				name = ' ',
				order = 25,
			},
			dataBrokerEnabled = {
				type = 'toggle',
				name = L['Enable DataBroker'],
				desc = L['Enable the DataBroker plugin for broker bar addons.'],
				order = 30,
				width = 'full',
				get = function()
					return module.DB.dataBroker.enabled
				end,
				set = function(_, val)
					module.DB.dataBroker.enabled = val
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
			dataBrokerFormat = {
				type = 'select',
				name = L['Broker Text Format'],
				order = 31,
				width = 'double',
				values = FORMAT_OPTIONS,
				get = function()
					return module.DB.dataBroker.format
				end,
				set = function(_, val)
					module.DB.dataBroker.format = val
					module:SendMessage('SUI_HOUSING_ENDEAVOR_SETTINGS_CHANGED')
				end,
			},
		},
	}

	SUI.Options:AddOptions(options, 'HousingEndeavor')
end
