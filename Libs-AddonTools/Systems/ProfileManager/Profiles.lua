---@class LibAT.ProfileManager
local LibAT = _G.LibAT
if not LibAT then
	return
end

local ProfileManager = {}
LibAT.ProfileManager = ProfileManager

-- Use LibAT shared UI components
local UI = LibAT.UI

-- Core functionality
local window
local namespaceblacklist = {'LibDualSpec-1.0'}

---@class RegisteredAddon
---@field id string Unique identifier for this addon
---@field displayName string Display name shown in UI
---@field db table AceDB database object
---@field namespaces table|nil Optional array of namespace names
---@field icon string|nil Optional icon path
---@field metadata table|nil Additional addon metadata

-- Registered addons storage
local registeredAddons = {}
local nextAddonId = 1

---Register an addon with the Profile Manager to enable profile import/export
---@param config table Configuration table with: name (string), db (table), namespaces (table|nil), icon (string|nil), id (string|nil)
---@return string addonId The unique ID assigned to this addon (use for ShowExport/ShowImport)
function ProfileManager:RegisterAddon(config)
	-- Validate required fields
	if not config or type(config) ~= 'table' then
		error('ProfileManager:RegisterAddon - config must be a table')
	end
	if not config.name or type(config.name) ~= 'string' then
		error('ProfileManager:RegisterAddon - config.name is required and must be a string')
	end
	if not config.db or type(config.db) ~= 'table' then
		error('ProfileManager:RegisterAddon - config.db is required and must be a table (AceDB object)')
	end

	-- Generate or use provided ID
	local addonId = config.id
	if not addonId then
		addonId = 'addon_' .. nextAddonId
		nextAddonId = nextAddonId + 1
	end

	-- Check if already registered
	if registeredAddons[addonId] then
		LibAT:Print('|cffff9900Warning:|r Addon "' .. config.name .. '" is already registered with ID: ' .. addonId)
		return addonId
	end

	-- Create registration entry
	registeredAddons[addonId] = {
		id = addonId,
		displayName = config.name,
		db = config.db,
		namespaces = config.namespaces,
		icon = config.icon,
		metadata = config.metadata or {}
	}

	-- Rebuild navigation tree if window exists
	if window and window.NavTree then
		BuildNavigationTree()
	end

	LibAT:Print('Registered addon "' .. config.name .. '" with ProfileManager (ID: ' .. addonId .. ')')
	return addonId
end

---Unregister an addon from the Profile Manager
---@param addonId string The unique ID of the addon to unregister
function ProfileManager:UnregisterAddon(addonId)
	if not registeredAddons[addonId] then
		LibAT:Print('|cffff0000Error:|r Addon with ID "' .. addonId .. '" is not registered')
		return
	end

	local addonName = registeredAddons[addonId].displayName
	registeredAddons[addonId] = nil

	-- Rebuild navigation tree if window exists
	if window and window.NavTree then
		BuildNavigationTree()
	end

	LibAT:Print('Unregistered addon "' .. addonName .. '" from ProfileManager')
end

---Get all registered addons
---@return table<string, RegisteredAddon> Table of registered addons keyed by ID
function ProfileManager:GetRegisteredAddons()
	return registeredAddons
end

---Navigate to a specific addon in export mode
---@param addonId string The unique ID of the addon
---@param namespace string|nil Optional specific namespace to export
function ProfileManager:ShowExport(addonId, namespace)
	if not registeredAddons[addonId] then
		LibAT:Print('|cffff0000Error:|r Addon with ID "' .. addonId .. '" is not registered')
		return
	end

	if not window then
		CreateWindow()
	end

	-- Set mode and active addon
	window.mode = 'export'
	window.activeAddonId = addonId
	window.activeNamespace = namespace

	-- Build navigation key
	local navKey = 'Addons.' .. addonId .. '.Export'
	if namespace then
		navKey = navKey .. '.' .. namespace
	end

	-- Update navigation tree
	if window.NavTree then
		window.NavTree.config.activeKey = navKey
		BuildNavigationTree()
	end

	UpdateWindowForMode()
end

---Navigate to a specific addon in import mode
---@param addonId string The unique ID of the addon
---@param namespace string|nil Optional specific namespace to import
function ProfileManager:ShowImport(addonId, namespace)
	if not registeredAddons[addonId] then
		LibAT:Print('|cffff0000Error:|r Addon with ID "' .. addonId .. '" is not registered')
		return
	end

	if not window then
		CreateWindow()
	end

	-- Set mode and active addon
	window.mode = 'import'
	window.activeAddonId = addonId
	window.activeNamespace = namespace

	-- Build navigation key
	local navKey = 'Addons.' .. addonId .. '.Import'
	if namespace then
		navKey = navKey .. '.' .. namespace
	end

	-- Update navigation tree
	if window.NavTree then
		window.NavTree.config.activeKey = navKey
		BuildNavigationTree()
	end

	UpdateWindowForMode()
end

---Build navigation tree categories from registered addons
---@return table categories Navigation tree category structure
local function BuildAddonCategories()
	local categories = {}

	-- Sort addon IDs for consistent display order
	local sortedIds = {}
	for id in pairs(registeredAddons) do
		table.insert(sortedIds, id)
	end
	table.sort(
		sortedIds,
		function(a, b)
			return registeredAddons[a].displayName < registeredAddons[b].displayName
		end
	)

	-- Build category for each registered addon
	for _, addonId in ipairs(sortedIds) do
		local addon = registeredAddons[addonId]
		local categoryKey = 'Addons.' .. addonId

		-- Check if addon has namespaces
		local hasNamespaces = addon.namespaces and #addon.namespaces > 0

		-- Create subcategories for Import and Export
		local subCategories = {}
		local sortedKeys = {}

		-- Import subcategory
		if hasNamespaces then
			-- Add Import with namespace options
			subCategories['Import'] = {
				name = 'Import',
				key = categoryKey .. '.Import',
				expanded = false,
				subCategories = {},
				sortedKeys = {}
			}

			-- Add "ALL" option
			subCategories['Import'].subCategories['ALL'] = {
				name = 'All Namespaces',
				key = categoryKey .. '.Import.ALL',
				onSelect = function()
					window.mode = 'import'
					window.activeAddonId = addonId
					window.activeNamespace = nil
					UpdateWindowForMode()
				end
			}
			table.insert(subCategories['Import'].sortedKeys, 'ALL')

			-- Add individual namespaces
			for _, ns in ipairs(addon.namespaces) do
				subCategories['Import'].subCategories[ns] = {
					name = ns,
					key = categoryKey .. '.Import.' .. ns,
					onSelect = function()
						window.mode = 'import'
						window.activeAddonId = addonId
						window.activeNamespace = ns
						UpdateWindowForMode()
					end
				}
				table.insert(subCategories['Import'].sortedKeys, ns)
			end
		else
			-- Simple import without namespaces
			subCategories['Import'] = {
				name = 'Import',
				key = categoryKey .. '.Import',
				onSelect = function()
					window.mode = 'import'
					window.activeAddonId = addonId
					window.activeNamespace = nil
					UpdateWindowForMode()
				end
			}
		end
		table.insert(sortedKeys, 'Import')

		-- Export subcategory (same structure as Import)
		if hasNamespaces then
			subCategories['Export'] = {
				name = 'Export',
				key = categoryKey .. '.Export',
				expanded = false,
				subCategories = {},
				sortedKeys = {}
			}

			-- Add "ALL" option
			subCategories['Export'].subCategories['ALL'] = {
				name = 'All Namespaces',
				key = categoryKey .. '.Export.ALL',
				onSelect = function()
					window.mode = 'export'
					window.activeAddonId = addonId
					window.activeNamespace = nil
					UpdateWindowForMode()
				end
			}
			table.insert(subCategories['Export'].sortedKeys, 'ALL')

			-- Add individual namespaces
			for _, ns in ipairs(addon.namespaces) do
				subCategories['Export'].subCategories[ns] = {
					name = ns,
					key = categoryKey .. '.Export.' .. ns,
					onSelect = function()
						window.mode = 'export'
						window.activeAddonId = addonId
						window.activeNamespace = ns
						UpdateWindowForMode()
					end
				}
				table.insert(subCategories['Export'].sortedKeys, ns)
			end
		else
			-- Simple export without namespaces
			subCategories['Export'] = {
				name = 'Export',
				key = categoryKey .. '.Export',
				onSelect = function()
					window.mode = 'export'
					window.activeAddonId = addonId
					window.activeNamespace = nil
					UpdateWindowForMode()
				end
			}
		end
		table.insert(sortedKeys, 'Export')

		-- Create main category
		categories[addonId] = {
			name = addon.displayName,
			key = categoryKey,
			expanded = false,
			icon = addon.icon,
			subCategories = subCategories,
			sortedKeys = sortedKeys
		}
	end

	return categories
end

---Rebuild the entire navigation tree with current registered addons
local function BuildNavigationTree()
	if not window or not window.NavTree then
		return
	end

	-- Build addon categories
	local addonCategories = BuildAddonCategories()

	-- Combine with settings category
	local allCategories = addonCategories

	-- Add settings at the end
	allCategories['Settings'] = {
		name = 'Settings',
		key = 'Settings',
		expanded = false,
		subCategories = {
			['Options'] = {
				name = 'Options',
				key = 'Settings.Options',
				onSelect = function()
					LibAT:Print('Profile options coming in Phase 2')
				end
			},
			['Namespaces'] = {
				name = 'Namespace Filter',
				key = 'Settings.Namespaces',
				onSelect = function()
					LibAT:Print('Namespace filtering coming in Phase 2')
				end
			}
		},
		sortedKeys = {'Options', 'Namespaces'}
	}

	-- Update navigation tree
	window.NavTree.config.categories = allCategories
	UI.BuildNavigationTree(window.NavTree)
end

local function UpdateWindowForMode()
	if not window then
		return
	end

	-- Clear text box
	window.EditBox:SetText('')

	-- Get active addon info for display
	local addonInfo = ''
	if window.activeAddonId and registeredAddons[window.activeAddonId] then
		local addon = registeredAddons[window.activeAddonId]
		addonInfo = ' - ' .. addon.displayName
		if window.activeNamespace then
			addonInfo = addonInfo .. ' (' .. window.activeNamespace .. ')'
		elseif addon.namespaces and #addon.namespaces > 0 then
			addonInfo = addonInfo .. ' (All Namespaces)'
		end
	end

	-- Update mode display
	if window.mode == 'export' then
		window.ModeLabel:SetText('|cff00ff00Export Mode|r' .. addonInfo)
		window.Description:SetText('Click Export to generate profile data, then copy the text below.')
		window.ExportButton:Show()
		window.ImportButton:Hide()
	else
		window.ModeLabel:SetText('|cff00aaffImport Mode|r' .. addonInfo)
		window.Description:SetText('Paste profile data below, then click Import to apply changes.')
		window.ExportButton:Hide()
		window.ImportButton:Show()
	end

	-- Update navigation tree to highlight current selection
	if window.NavTree and window.activeAddonId then
		local navKey = 'Addons.' .. window.activeAddonId .. '.' .. (window.mode == 'export' and 'Export' or 'Import')
		if window.activeNamespace then
			navKey = navKey .. '.' .. window.activeNamespace
		elseif registeredAddons[window.activeAddonId] and registeredAddons[window.activeAddonId].namespaces then
			navKey = navKey .. '.ALL'
		end
		window.NavTree.config.activeKey = navKey
		UI.BuildNavigationTree(window.NavTree)
	end

	window:Show()
end

local function CreateWindow()
	-- Create base window using LibAT.UI
	window =
		UI.CreateWindow(
		{
			name = 'LibAT_ProfileWindow',
			title = '|cffffffffLib|cffe21f1fAT|r Profile Manager',
			width = 800,
			height = 538,
			portrait = 'Interface\\AddOns\\Libs-AddonTools\\Logo-Icon'
		}
	)
	window.mode = 'import'
	window.activeAddonId = nil -- Currently selected addon ID
	window.activeNamespace = nil -- Currently selected namespace (nil = all)

	-- Create control frame (top bar)
	window.ControlFrame = UI.CreateControlFrame(window)

	-- Add mode label (shows current mode)
	window.ModeLabel = UI.CreateHeader(window.ControlFrame, 'Import Mode')
	window.ModeLabel:SetPoint('LEFT', window.ControlFrame, 'LEFT', 10, 0)

	-- Add switch mode button
	window.SwitchModeButton = UI.CreateButton(window.ControlFrame, 100, 22, 'Switch Mode')
	window.SwitchModeButton:SetPoint('RIGHT', window.ControlFrame, 'RIGHT', -10, 0)
	window.SwitchModeButton:SetScript(
		'OnClick',
		function()
			window.mode = window.mode == 'import' and 'export' or 'import'
			UpdateWindowForMode()
		end
	)

	-- Create main content area
	window.MainContent = UI.CreateContentFrame(window, window.ControlFrame)

	-- Create left panel for navigation
	window.LeftPanel = UI.CreateLeftPanel(window.MainContent)

	-- Initialize navigation tree with registered addons
	window.NavTree =
		UI.CreateNavigationTree(
		{
			parent = window.LeftPanel,
			categories = {},
			activeKey = nil
		}
	)

	-- Build initial navigation tree
	BuildNavigationTree()

	-- Create right panel for content
	window.RightPanel = UI.CreateRightPanel(window.MainContent, window.LeftPanel)

	-- Add description header
	window.Description = UI.CreateLabel(window.RightPanel, '', window.RightPanel:GetWidth() - 40)
	window.Description:SetPoint('TOP', window.RightPanel, 'TOP', 0, -10)
	window.Description:SetJustifyH('CENTER')
	window.Description:SetWordWrap(true)

	-- Create scrollable text display for profile data
	window.TextPanel, window.EditBox = UI.CreateScrollableTextDisplay(window.RightPanel)
	window.TextPanel:SetPoint('TOPLEFT', window.Description, 'BOTTOMLEFT', 6, -10)
	window.TextPanel:SetPoint('BOTTOMRIGHT', window.RightPanel, 'BOTTOMRIGHT', -6, 50)
	window.EditBox:SetWidth(window.TextPanel:GetWidth() - 20)

	-- Create action buttons
	local actionButtons =
		UI.CreateActionButtons(
		window,
		{
			{
				text = 'Clear',
				width = 70,
				onClick = function()
					window.EditBox:SetText('')
				end
			},
			{
				text = 'Close',
				width = 70,
				onClick = function()
					window:Hide()
				end
			}
		}
	)

	-- Import button (shown in import mode)
	window.ImportButton = UI.CreateButton(window, 100, 22, 'Import')
	window.ImportButton:SetPoint('RIGHT', actionButtons[1], 'LEFT', -5, 0)
	window.ImportButton:SetScript(
		'OnClick',
		function()
			ProfileManager:DoImport()
		end
	)

	-- Export button (shown in export mode)
	window.ExportButton = UI.CreateButton(window, 100, 22, 'Export')
	window.ExportButton:SetPoint('RIGHT', actionButtons[1], 'LEFT', -5, 0)
	window.ExportButton:SetScript(
		'OnClick',
		function()
			ProfileManager:DoExport()
		end
	)

	-- Hide window initially
	window:Hide()
end

function ProfileManager:ImportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'import'
	UpdateWindowForMode()
end

function ProfileManager:ExportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'export'
	UpdateWindowForMode()
end

function ProfileManager:ToggleWindow()
	if not window then
		CreateWindow()
	end
	if window:IsVisible() then
		window:Hide()
	else
		UpdateWindowForMode()
	end
end

-- Export function - Works with registered addons
function ProfileManager:DoExport()
	if not window then
		return
	end

	-- Check if an addon is selected
	if not window.activeAddonId or not registeredAddons[window.activeAddonId] then
		LibAT:Print('|cffff0000Error:|r No addon selected for export')
		return
	end

	local addon = registeredAddons[window.activeAddonId]
	local db = addon.db

	-- Validate AceDB structure
	if not db or not db.sv then
		LibAT:Print('|cffff0000Error:|r Invalid AceDB object for ' .. addon.displayName)
		return
	end

	-- Build export data
	local exportData = {
		version = '2.0.0',
		timestamp = date('%Y-%m-%d %H:%M:%S'),
		addon = addon.displayName,
		addonId = addon.id,
		data = {}
	}

	-- Export based on namespace selection
	if window.activeNamespace then
		-- Export single namespace
		if db.sv.namespaces and db.sv.namespaces[window.activeNamespace] then
			exportData.data[window.activeNamespace] = db.sv.namespaces[window.activeNamespace]
			exportData.namespace = window.activeNamespace
		else
			LibAT:Print('|cffff0000Error:|r Namespace "' .. window.activeNamespace .. '" not found')
			return
		end
	else
		-- Export all namespaces (excluding blacklist)
		if db.sv.namespaces then
			for namespace, data in pairs(db.sv.namespaces) do
				if not tContains(namespaceblacklist, namespace) then
					exportData.data[namespace] = data
				end
			end
		end

		-- Also export profile data if available
		if db.sv.profiles then
			exportData.profiles = db.sv.profiles
		end
	end

	-- Serialize to string
	local exportString = '-- ' .. addon.displayName .. ' Profile Export\n'
	exportString = exportString .. '-- Generated: ' .. exportData.timestamp .. '\n'
	exportString = exportString .. '-- Version: ' .. exportData.version .. '\n'
	if window.activeNamespace then
		exportString = exportString .. '-- Namespace: ' .. window.activeNamespace .. '\n'
	end
	exportString = exportString .. '\n'

	local function serializeTable(tbl, indent)
		indent = indent or ''
		local result = '{\n'
		for k, v in pairs(tbl) do
			result = result .. indent .. '  [' .. string.format('%q', tostring(k)) .. '] = '
			if type(v) == 'table' then
				result = result .. serializeTable(v, indent .. '  ')
			else
				result = result .. string.format('%q', tostring(v))
			end
			result = result .. ',\n'
		end
		result = result .. indent .. '}'
		return result
	end

	exportString = exportString .. 'return ' .. serializeTable(exportData)

	window.EditBox:SetText(exportString)
	window.EditBox:SetCursorPosition(0)
	window.EditBox:HighlightText(0)

	LibAT:Print('|cff00ff00Profile exported successfully!|r Select all (Ctrl+A) and copy (Ctrl+C).')
end

-- Import function - Works with registered addons
function ProfileManager:DoImport()
	if not window then
		return
	end

	-- Check if an addon is selected
	if not window.activeAddonId or not registeredAddons[window.activeAddonId] then
		LibAT:Print('|cffff0000Error:|r No addon selected for import')
		return
	end

	local importText = window.EditBox:GetText()
	if not importText or importText == '' then
		LibAT:Print('|cffff0000Please paste profile data into the text box first.|r')
		return
	end

	-- Try to parse the import data
	local success, importData = pcall(loadstring(importText))
	if not success or type(importData) ~= 'table' then
		LibAT:Print('|cffff0000Invalid profile data. Please check the format.|r')
		return
	end

	local addon = registeredAddons[window.activeAddonId]
	local db = addon.db

	-- Validate AceDB structure
	if not db or not db.sv then
		LibAT:Print('|cffff0000Error:|r Invalid AceDB object for ' .. addon.displayName)
		return
	end

	-- Validate addon ID matches (optional safety check)
	if importData.addonId and importData.addonId ~= addon.id then
		LibAT:Print('|cffff9900Warning:|r Import data is for addon "' .. (importData.addon or 'Unknown') .. '" but you selected "' .. addon.displayName .. '"')
		LibAT:Print('Continuing with import anyway...')
	end

	-- Apply import data
	local importCount = 0

	if window.activeNamespace then
		-- Import single namespace
		if importData.namespace and importData.namespace == window.activeNamespace then
			if importData.data[window.activeNamespace] then
				if not db.sv.namespaces then
					db.sv.namespaces = {}
				end
				db.sv.namespaces[window.activeNamespace] = importData.data[window.activeNamespace]
				importCount = 1
			else
				LibAT:Print('|cffff0000Error:|r Import data does not contain namespace "' .. window.activeNamespace .. '"')
				return
			end
		else
			LibAT:Print('|cffff0000Error:|r Import data namespace mismatch')
			return
		end
	else
		-- Import all namespaces
		if importData.data then
			if not db.sv.namespaces then
				db.sv.namespaces = {}
			end
			for namespace, data in pairs(importData.data) do
				if not tContains(namespaceblacklist, namespace) then
					db.sv.namespaces[namespace] = data
					importCount = importCount + 1
				end
			end
		end

		-- Import profiles if available
		if importData.profiles then
			db.sv.profiles = importData.profiles
		end
	end

	if importCount > 0 then
		LibAT:Print('|cff00ff00Profile imported successfully!|r Imported ' .. importCount .. ' namespace(s) for ' .. addon.displayName)
		LibAT:Print('|cffff9900Please /reload to apply changes.|r')
	else
		LibAT:Print('|cffff0000No data was imported.|r')
	end
end

-- Register slash commands
function ProfileManager:Initialize()
	-- Register with LibAT
	LibAT:RegisterSystem('ProfileManager', self)

	-- Auto-register LibAT itself if database is available
	if LibAT.Database then
		ProfileManager:RegisterAddon(
			{
				id = 'libat',
				name = 'LibAT Core',
				db = LibAT.Database,
				icon = 'Interface\\AddOns\\Libs-AddonTools\\Logo-Icon'
			}
		)
	end

	-- Create slash commands
	SLASH_LIBATPROFILES1 = '/libatprofiles'
	SLASH_LIBATPROFILES2 = '/profiles'
	SlashCmdList['LIBATPROFILES'] = function(msg)
		msg = msg:lower():trim()
		if msg == 'export' then
			ProfileManager:ExportUI()
		elseif msg == 'import' then
			ProfileManager:ImportUI()
		else
			ProfileManager:ToggleWindow()
		end
	end

	LibAT:Print('Profile Manager initialized - Use /profiles to open')
	LibAT:Print('Addons can register with: LibAT.ProfileManager:RegisterAddon({name = "MyAddon", db = MyAddonDB})')
end

-- Auto-initialize when loaded
ProfileManager:Initialize()

--[[
	REGISTRATION EXAMPLE FOR EXTERNAL ADDONS:

	-- Basic registration (no namespaces)
	local myAddonId = LibAT.ProfileManager:RegisterAddon({
		name = "My Addon",
		db = MyAddonDB  -- Your AceDB database object
	})

	-- Advanced registration (with namespaces and custom ID)
	local spartanId = LibAT.ProfileManager:RegisterAddon({
		id = "spartanui",  -- Optional: provide custom ID (defaults to auto-generated)
		name = "SpartanUI",
		db = SpartanUIDB,
		namespaces = {"PlayerFrame", "TargetFrame", "PartyFrame"},  -- Optional
		icon = "Interface\\AddOns\\SpartanUI\\Images\\Logo"  -- Optional
	})

	-- Later, navigate directly to export/import
	LibAT.ProfileManager:ShowExport("spartanui")  -- Opens export for SpartanUI
	LibAT.ProfileManager:ShowExport("spartanui", "PlayerFrame")  -- Export specific namespace
	LibAT.ProfileManager:ShowImport("spartanui")  -- Opens import for SpartanUI

	-- Unregister when addon unloads (optional)
	LibAT.ProfileManager:UnregisterAddon("spartanui")
]]
return ProfileManager
