---@diagnostic disable: duplicate-set-field
--[===[ File: Display/ThemeManager.lua
LibsDataBar Theme Management System
Handles theme application for bars and plugin buttons
--]===]

-- Get the LibsDataBar addon
---@class LibsDataBar
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Local references for performance
local _G = _G
local pairs, ipairs = pairs, ipairs
local type, tostring = type, tostring

---@class ThemeManager
---@field themes table<string, Theme> Available themes
---@field currentTheme string Current active theme
---@field defaultTheme string Default fallback theme
---@field customThemes table<string, Theme> User-created themes
local ThemeManager = {}
ThemeManager.__index = ThemeManager

-- Initialize ThemeManager for LibsDataBar
LibsDataBar.themes = LibsDataBar.themes or setmetatable({
	themes = {},
	currentTheme = 'default',
	defaultTheme = 'default',
	customThemes = {},
}, ThemeManager)

---@class Theme
---@field id string Theme identifier
---@field name string Display name
---@field description string Theme description
---@field version string Theme version
---@field author string Theme author
---@field bar BarTheme Bar styling configuration
---@field button ButtonTheme Button styling configuration
---@field tooltip TooltipTheme Tooltip styling configuration

---@class BarTheme
---@field background table Background styling
---@field border table Border styling
---@field spacing number Plugin spacing
---@field padding table Bar padding

---@class ButtonTheme
---@field font table Font configuration
---@field background table Background styling
---@field border table Border styling
---@field highlight table Highlight styling
---@field spacing number Button spacing
---@field padding table Button padding

---@class TooltipTheme
---@field background table Background styling
---@field border table Border styling
---@field font table Font configuration

-- Default theme definitions
local DEFAULT_THEMES = {
	default = {
		id = 'default',
		name = 'Default',
		description = 'Clean default theme for LibsDataBar',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0, 0, 0, 0.8 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = false,
				color = { 1, 1, 1, 0.8 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			spacing = 4,
			padding = { top = 2, bottom = 2, left = 2, right = 2 },
		},

		button = {
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 12,
				flags = 'OUTLINE',
				color = { 1, 1, 1, 1 },
			},
			background = {
				show = false,
				color = { 0, 0, 0, 0.3 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = false,
				color = { 0.5, 0.5, 0.5, 0.8 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			highlight = {
				show = true,
				color = { 1, 1, 1, 0.2 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 3,
			padding = { top = 2, bottom = 2, left = 5, right = 5 },
		},

		tooltip = {
			background = {
				color = { 0, 0, 0, 0.9 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 1, 1, 1, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 12,
				flags = '',
			},
		},
	},

	dark = {
		id = 'dark',
		name = 'Dark',
		description = 'Dark theme with minimal styling',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0.1, 0.1, 0.1, 0.8 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = true,
				color = { 0.3, 0.3, 0.3, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			spacing = 2,
			padding = { top = 4, bottom = 4, left = 6, right = 6 },
		},

		button = {
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = 'OUTLINE',
				color = { 0.9, 0.9, 0.9, 1 },
			},
			background = {
				show = true,
				color = { 0.2, 0.2, 0.2, 0.6 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = false,
				color = { 0.4, 0.4, 0.4, 0.8 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			highlight = {
				show = true,
				color = { 0.3, 0.3, 0.3, 0.5 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 2,
			padding = { top = 3, bottom = 3, left = 6, right = 6 },
		},

		tooltip = {
			background = {
				color = { 0.1, 0.1, 0.1, 0.95 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 0.5, 0.5, 0.5, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = 'OUTLINE',
			},
		},
	},

	modern = {
		id = 'modern',
		name = 'Modern',
		description = 'Clean modern theme with subtle gradients',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0.2, 0.2, 0.25, 0.9 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = true,
				color = { 0.4, 0.6, 0.8, 0.8 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			spacing = 3,
			padding = { top = 4, bottom = 4, left = 6, right = 6 },
		},

		button = {
			font = {
				face = 'Fonts\\ARIALN.TTF',
				size = 12,
				flags = '',
				color = { 0.95, 0.95, 0.95, 1 },
			},
			background = {
				show = true,
				color = { 0.25, 0.25, 0.3, 0.6 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = true,
				color = { 0.5, 0.7, 0.9, 0.6 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			highlight = {
				show = true,
				color = { 0.6, 0.8, 1.0, 0.4 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 4,
			padding = { top = 4, bottom = 4, left = 8, right = 8 },
		},

		tooltip = {
			background = {
				color = { 0.15, 0.15, 0.2, 0.95 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 0.5, 0.7, 0.9, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\ARIALN.TTF',
				size = 12,
				flags = '',
			},
		},
	},

	minimal = {
		id = 'minimal',
		name = 'Minimal',
		description = 'Ultra-minimal theme with maximum screen space',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 0,
			},
			spacing = 8,
			padding = { top = 0, bottom = 0, left = 4, right = 4 },
		},

		button = {
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = '',
				color = { 0.8, 0.8, 0.8, 0.9 },
			},
			background = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 0,
			},
			highlight = {
				show = true,
				color = { 1, 1, 1, 0.15 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 1,
			padding = { top = 1, bottom = 1, left = 3, right = 3 },
		},

		tooltip = {
			background = {
				color = { 0, 0, 0, 0.85 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 0.8, 0.8, 0.8, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = '',
			},
		},
	},

	classic = {
		id = 'classic',
		name = 'Classic',
		description = 'Traditional WoW interface styling',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0.3, 0.25, 0.15, 0.8 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			},
			border = {
				show = true,
				color = { 0.8, 0.7, 0.5, 1 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
				size = 8,
			},
			spacing = 3,
			padding = { top = 5, bottom = 5, left = 8, right = 8 },
		},

		button = {
			font = {
				face = 'Fonts\\MORPHEUS.TTF',
				size = 12,
				flags = '',
				color = { 1, 0.82, 0, 1 },
			},
			background = {
				show = true,
				color = { 0.25, 0.2, 0.1, 0.7 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			},
			border = {
				show = true,
				color = { 0.7, 0.6, 0.4, 0.8 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
				size = 4,
			},
			highlight = {
				show = true,
				color = { 1, 0.9, 0.5, 0.3 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 4,
			padding = { top = 4, bottom = 4, left = 8, right = 8 },
		},

		tooltip = {
			background = {
				color = { 0.2, 0.15, 0.1, 0.95 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			},
			border = {
				color = { 0.8, 0.7, 0.5, 1 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
			},
			font = {
				face = 'Fonts\\MORPHEUS.TTF',
				size = 12,
				flags = '',
			},
		},
	},

	gaming = {
		id = 'gaming',
		name = 'Gaming',
		description = 'High-contrast theme for competitive gaming',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0, 0, 0, 0.95 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = true,
				color = { 0, 1, 0, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 2,
			},
			spacing = 1,
			padding = { top = 2, bottom = 2, left = 4, right = 4 },
		},

		button = {
			font = {
				face = 'Fonts\\ARIALN.TTF',
				size = 11,
				flags = 'OUTLINE',
				color = { 0, 1, 0, 1 },
			},
			background = {
				show = true,
				color = { 0, 0, 0, 0.8 },
				texture = 'Interface\\ChatFrame\\ChatFrameBackground',
			},
			border = {
				show = true,
				color = { 0, 0.8, 0, 0.8 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 1,
			},
			highlight = {
				show = true,
				color = { 0, 1, 0, 0.5 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 1,
			padding = { top = 2, bottom = 2, left = 4, right = 4 },
		},

		tooltip = {
			background = {
				color = { 0, 0, 0, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 0, 1, 0, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\ARIALN.TTF',
				size = 11,
				flags = 'OUTLINE',
			},
		},
	},

	-- Additional Themes (following standard broker display patterns)
	standard = {
		id = 'standard',
		name = 'Standard',
		description = 'Standard theme with simple backgrounds',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0, 0, 0, 1.0 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
				tile = false,
				tileSize = 0,
			},
			border = {
				show = false,
				color = { 0.8, 0.6, 0.0, 1.0 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
				size = 0,
			},
			spacing = 8,
			padding = { top = 2, bottom = 2, left = 8, right = 8 },
		},

		button = {
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 12,
				flags = '',
				color = { 1.0, 0.82, 0, 1 },
			},
			background = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
			},
			border = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
				size = 0,
			},
			highlight = {
				show = true,
				color = { 1, 1, 1, 0.2 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 2,
			padding = { top = 2, bottom = 2, left = 4, right = 4 },
		},

		tooltip = {
			background = {
				color = { 0, 0, 0, 0.9 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 1, 1, 1, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 12,
				flags = '',
			},
		},
	},

	clean = {
		id = 'clean',
		name = 'Clean',
		description = 'Clean theme with minimal backgrounds',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
				tile = false,
				tileSize = 0,
			},
			border = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
				size = 0,
			},
			spacing = 4,
			padding = { top = 1, bottom = 1, left = 2, right = 2 },
		},

		button = {
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = '',
				color = { 0.9, 0.9, 0.9, 1 },
			},
			background = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
			},
			border = {
				show = false,
				color = { 0, 0, 0, 0 },
				texture = '',
				size = 0,
			},
			highlight = {
				show = true,
				color = { 1, 1, 1, 0.15 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 1,
			padding = { top = 1, bottom = 1, left = 3, right = 3 },
		},

		tooltip = {
			background = {
				color = { 0, 0, 0, 0.85 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Background',
			},
			border = {
				color = { 0.8, 0.8, 0.8, 1 },
				texture = 'Interface\\Tooltips\\UI-Tooltip-Border',
			},
			font = {
				face = 'Fonts\\FRIZQT__.TTF',
				size = 11,
				flags = '',
			},
		},
	},

	dialog = {
		id = 'dialog',
		name = 'Dialog',
		description = 'Theme using Blizzard dialog backgrounds',
		version = '1.0.0',
		author = 'LibsDataBar Team',

		bar = {
			background = {
				show = true,
				color = { 0, 0, 0, 1.0 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
				tile = false,
				tileSize = 0,
			},
			border = {
				show = true,
				color = { 0.8, 0.6, 0.0, 1.0 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
				size = 16,
			},
			spacing = 8,
			padding = { top = 5, bottom = 5, left = 8, right = 8 },
		},

		button = {
			font = {
				face = 'Fonts\\MORPHEUS.TTF',
				size = 12,
				flags = '',
				color = { 1, 0.82, 0, 1 },
			},
			background = {
				show = false,
				color = { 0.25, 0.2, 0.1, 0.7 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			},
			border = {
				show = false,
				color = { 0.7, 0.6, 0.4, 0.8 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
				size = 0,
			},
			highlight = {
				show = true,
				color = { 1, 0.9, 0.5, 0.3 },
				texture = 'Interface\\Buttons\\UI-Common-MouseHilight',
			},
			spacing = 4,
			padding = { top = 4, bottom = 4, left = 8, right = 8 },
		},

		tooltip = {
			background = {
				color = { 0.2, 0.15, 0.1, 0.95 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Background',
			},
			border = {
				color = { 0.8, 0.7, 0.5, 1 },
				texture = 'Interface\\DialogFrame\\UI-DialogBox-Border',
			},
			font = {
				face = 'Fonts\\MORPHEUS.TTF',
				size = 12,
				flags = '',
			},
		},
	},
}

---Initialize the theme manager
function ThemeManager:Initialize()
	-- Register default themes
	for themeId, themeData in pairs(DEFAULT_THEMES) do
		self:RegisterTheme(themeData)
	end

	-- Load custom themes from saved variables if available
	self:LoadCustomThemes()

	LibsDataBar:DebugLog('info', 'ThemeManager initialized with ' .. self:GetThemeCount() .. ' themes')
end

---Register a new theme
---@param theme Theme Theme definition
---@return boolean success Whether registration was successful
function ThemeManager:RegisterTheme(theme)
	if not theme or not theme.id then
		LibsDataBar:DebugLog('error', 'Theme registration failed: missing id')
		return false
	end

	-- Validate theme structure
	if not self:ValidateTheme(theme) then
		LibsDataBar:DebugLog('error', 'Theme registration failed: invalid theme structure for ' .. theme.id)
		return false
	end

	self.themes[theme.id] = theme
	LibsDataBar:DebugLog('info', 'Theme registered: ' .. theme.id)

	-- Fire registration event
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_ThemeRegistered', theme.id, theme) end

	return true
end

---Validate theme structure
---@param theme table Theme to validate
---@return boolean valid Whether theme is valid
function ThemeManager:ValidateTheme(theme)
	-- Check required fields
	local required = { 'id', 'name', 'bar', 'button', 'tooltip' }
	for _, field in ipairs(required) do
		if not theme[field] then
			LibsDataBar:DebugLog('error', 'Theme validation failed: missing ' .. field)
			return false
		end
	end

	return true
end

---Get a theme by ID
---@param themeId string Theme identifier
---@return Theme? theme Theme definition or nil
function ThemeManager:GetTheme(themeId)
	return self.themes[themeId]
end

---Get list of available theme IDs
---@return table themeIds Array of theme IDs
function ThemeManager:GetThemeList()
	local themeIds = {}
	for themeId, _ in pairs(self.themes) do
		table.insert(themeIds, themeId)
	end
	return themeIds
end

---Get count of available themes
---@return number count Number of registered themes
function ThemeManager:GetThemeCount()
	local count = 0
	for _ in pairs(self.themes) do
		count = count + 1
	end
	return count
end

---Set the current active theme
---@param themeId string Theme identifier
---@return boolean success Whether theme was applied successfully
function ThemeManager:SetCurrentTheme(themeId)
	local theme = self:GetTheme(themeId)
	if not theme then
		LibsDataBar:DebugLog('error', 'Cannot set theme: ' .. tostring(themeId) .. ' not found')
		return false
	end

	local previousTheme = self.currentTheme
	self.currentTheme = themeId

	-- Apply theme to all existing bars
	self:ApplyThemeToAllBars()

	-- Fire theme change event
	if LibsDataBar.callbacks then LibsDataBar.callbacks:Fire('LibsDataBar_ThemeChanged', themeId, previousTheme) end

	LibsDataBar:DebugLog('info', 'Theme changed to: ' .. themeId)
	return true
end

---Get the current active theme
---@return Theme? theme Current theme or nil
function ThemeManager:GetCurrentTheme()
	return self:GetTheme(self.currentTheme)
end

---Apply current theme to all bars
function ThemeManager:ApplyThemeToAllBars()
	local theme = self:GetCurrentTheme()
	if not theme then
		LibsDataBar:DebugLog('warning', 'No current theme to apply')
		return
	end

	for barId, bar in pairs(LibsDataBar.bars or {}) do
		self:ApplyThemeToBar(bar, theme)
	end
end

---Apply theme to a specific bar
---@param bar DataBar Bar to apply theme to
---@param theme? Theme Theme to apply (defaults to current theme)
function ThemeManager:ApplyThemeToBar(bar, theme)
	theme = theme or self:GetCurrentTheme()
	if not theme or not bar then return end

	-- Apply bar styling
	self:ApplyBarTheme(bar, theme.bar)

	-- Apply theme to all plugins in the bar
	for pluginId, button in pairs(bar.plugins or {}) do
		self:ApplyThemeToButton(button, theme.button)
	end

	-- Update bar layout to reflect theme changes
	if bar.UpdateLayout then bar:UpdateLayout() end

	LibsDataBar:DebugLog('debug', 'Applied theme ' .. theme.id .. ' to bar ' .. bar.id)
end

---Apply bar theme styling (standard backdrop system)
---@param bar DataBar Bar to style
---@param barTheme BarTheme Theme configuration
function ThemeManager:ApplyBarTheme(bar, barTheme)
	if not bar.frame or not barTheme then return end

	-- Apply proper backdrop system (prevents texture issues)
	if barTheme.background and barTheme.background.show then
		-- Use proper SetBackdrop system
		local backdrop = {
			bgFile = barTheme.background.texture,
			edgeFile = barTheme.border and barTheme.border.show and barTheme.border.texture or nil,
			tile = barTheme.background.tile or false,
			tileSize = barTheme.background.tileSize or 0,
			edgeSize = barTheme.border and barTheme.border.size or 0,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		}

		-- Set backdrop
		if bar.frame.SetBackdrop then
			bar.frame:SetBackdrop(backdrop)

			-- Apply colors using standard method
			if barTheme.background.color then
				bar.frame:SetBackdropColor(
					barTheme.background.color[1] or barTheme.background.color.r or 0,
					barTheme.background.color[2] or barTheme.background.color.g or 0,
					barTheme.background.color[3] or barTheme.background.color.b or 0,
					barTheme.background.color[4] or barTheme.background.color.a or 1
				)
			end

			if barTheme.border and barTheme.border.show and barTheme.border.color then
				bar.frame:SetBackdropBorderColor(
					barTheme.border.color[1] or barTheme.border.color.r or 1,
					barTheme.border.color[2] or barTheme.border.color.g or 1,
					barTheme.border.color[3] or barTheme.border.color.b or 1,
					barTheme.border.color[4] or barTheme.border.color.a or 1
				)
			end
		else
			-- Fallback for frames without SetBackdrop
			if not bar.backgroundTexture then bar.backgroundTexture = bar.frame:CreateTexture(nil, 'BACKGROUND') end

			bar.backgroundTexture:SetTexture(barTheme.background.texture)
			if barTheme.background.color then
				bar.backgroundTexture:SetVertexColor(
					barTheme.background.color[1] or barTheme.background.color.r or 0,
					barTheme.background.color[2] or barTheme.background.color.g or 0,
					barTheme.background.color[3] or barTheme.background.color.b or 0,
					barTheme.background.color[4] or barTheme.background.color.a or 1
				)
			end
			bar.backgroundTexture:SetAllPoints(bar.frame)
			bar.backgroundTexture:Show()
		end
	else
		-- Hide background
		if bar.frame.SetBackdrop then bar.frame:SetBackdrop(nil) end
		if bar.backgroundTexture then bar.backgroundTexture:Hide() end
		if bar.borderTexture then bar.borderTexture:Hide() end
	end

	-- Apply spacing and padding to bar configuration
	if barTheme.spacing then
		bar.config.layout = bar.config.layout or {}
		bar.config.layout.spacing = barTheme.spacing
	end

	if barTheme.padding then
		bar.config.layout = bar.config.layout or {}
		bar.config.layout.padding = barTheme.padding
	end
end

---Apply button theme styling
---@param button PluginButton Button to style
---@param buttonTheme ButtonTheme Theme configuration
function ThemeManager:ApplyThemeToButton(button, buttonTheme)
	if not button or not button.frame or not buttonTheme then return end

	-- Apply font styling
	if buttonTheme.font and button.text then
		button.text:SetFont(buttonTheme.font.face, buttonTheme.font.size, buttonTheme.font.flags)
		button.text:SetTextColor(unpack(buttonTheme.font.color))
	end

	-- Apply background
	if buttonTheme.background and button.background then
		if buttonTheme.background.show then
			button.background:SetTexture(buttonTheme.background.texture)
			button.background:SetVertexColor(unpack(buttonTheme.background.color))
			button.background:Show()
		else
			button.background:Hide()
		end
	end

	-- Apply border
	if buttonTheme.border and button.border then
		if buttonTheme.border.show then
			button.border:SetTexture(buttonTheme.border.texture)
			button.border:SetVertexColor(unpack(buttonTheme.border.color))
			button.border:Show()
		else
			button.border:Hide()
		end
	end

	-- Apply highlight
	if buttonTheme.highlight and button.highlightTexture then
		button.highlightTexture:SetTexture(buttonTheme.highlight.texture)
		button.highlightTexture:SetVertexColor(unpack(buttonTheme.highlight.color))
	end

	-- Update button configuration
	if buttonTheme.padding then
		button.config.padding = buttonTheme.padding
		if button.UpdateLayout then button:UpdateLayout() end
	end
end

---Create a custom theme based on an existing theme
---@param baseThemeId string Base theme to copy from
---@param newThemeId string New theme identifier
---@param modifications table Theme modifications to apply
---@return boolean success Whether theme was created successfully
function ThemeManager:CreateCustomTheme(baseThemeId, newThemeId, modifications)
	local baseTheme = self:GetTheme(baseThemeId)
	if not baseTheme then
		LibsDataBar:DebugLog('error', 'Cannot create custom theme: base theme ' .. baseThemeId .. ' not found')
		return false
	end

	if self:GetTheme(newThemeId) then
		LibsDataBar:DebugLog('error', 'Cannot create custom theme: ' .. newThemeId .. ' already exists')
		return false
	end

	-- Deep copy base theme
	local customTheme = self:DeepCopyTable(baseTheme)
	customTheme.id = newThemeId
	customTheme.name = modifications.name or ('Custom ' .. newThemeId)
	customTheme.description = modifications.description or ('Custom theme based on ' .. baseThemeId)
	customTheme.author = 'User'

	-- Apply modifications
	if modifications.bar then self:MergeTable(customTheme.bar, modifications.bar) end

	if modifications.button then self:MergeTable(customTheme.button, modifications.button) end

	if modifications.tooltip then self:MergeTable(customTheme.tooltip, modifications.tooltip) end

	-- Register the custom theme
	self:RegisterTheme(customTheme)
	self.customThemes[newThemeId] = customTheme

	return true
end

---Deep copy a table
---@param orig table Original table
---@return table copy Deep copy of the table
function ThemeManager:DeepCopyTable(orig)
	local copy = {}
	for key, value in pairs(orig) do
		if type(value) == 'table' then
			copy[key] = self:DeepCopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

---Merge source table into target table
---@param target table Target table to merge into
---@param source table Source table to merge from
function ThemeManager:MergeTable(target, source)
	for key, value in pairs(source) do
		if type(value) == 'table' and type(target[key]) == 'table' then
			self:MergeTable(target[key], value)
		else
			target[key] = value
		end
	end
end

---Load custom themes from saved variables
function ThemeManager:LoadCustomThemes()
	-- This would load from SavedVariables in a real implementation
	-- For now, just a placeholder
	LibsDataBar:DebugLog('debug', 'Loading custom themes (placeholder)')
end

---Save custom themes to saved variables
function ThemeManager:SaveCustomThemes()
	-- This would save to SavedVariables in a real implementation
	-- For now, just a placeholder
	LibsDataBar:DebugLog('debug', 'Saving custom themes (placeholder)')
end

---Remove a custom theme
---@param themeId string Theme identifier
---@return boolean success Whether theme was removed
function ThemeManager:RemoveCustomTheme(themeId)
	if not self.customThemes[themeId] then
		LibsDataBar:DebugLog('error', 'Cannot remove theme: ' .. themeId .. ' is not a custom theme')
		return false
	end

	-- Switch to default theme if removing current theme
	if self.currentTheme == themeId then self:SetCurrentTheme(self.defaultTheme) end

	self.themes[themeId] = nil
	self.customThemes[themeId] = nil

	LibsDataBar:DebugLog('info', 'Removed custom theme: ' .. themeId)
	return true
end

-- Initialize the theme manager when this file loads
if LibsDataBar.themes then LibsDataBar.themes:Initialize() end
