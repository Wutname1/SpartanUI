---@class SUI
local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('ExpandedExpansionButton') ---@class SUI.Module.ExpandedExpansionButton : SUI.Module
module.DisplayName = 'Expanded Expansion Button'
module.description = 'Provides enhanced right-click menu for expansion features'

----------------------------------------------------------------------------------------------------
-- Module Variables
local registeredExpansions = {}
local menuFrame = nil
local LibQTip = SUI.Lib.LibQTip

-- Define expansion order globally (oldest to newest, so newest appears at bottom)
local expansionOrder = {
	['WOD'] = 1, -- Warlords of Draenor
	['LEG'] = 2, -- Legion
	['BFA'] = 3, -- Battle for Azeroth
	['SL'] = 4, -- Shadowlands
	['DF'] = 5, -- Dragonflight
	['TWW'] = 6, -- The War Within
	['MID'] = 7, -- Midnight (best guess)
	['TLT'] = 8, -- The Last Titan (best guess)
	[''] = 999, -- Non-expansion items (Great Vault, etc.) - force to bottom
}

-- Default expansion registrations
local defaultExpansions = {
	{
		expansion = 'TWW',
		displayText = 'TWW: Renown',
		enabled = true,
		icon = 'warwithin-landingbutton-up',
		onClick = function()
			if not ExpansionLandingPageMinimapButton then return end
			ExpansionLandingPageMinimapButton:ToggleLandingPage()
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 10 -- The War Within
		end,
	},
	{
		expansion = '',
		displayText = 'Great Vault',
		enabled = true,
		icon = function()
			-- Dynamic icon based on Great Vault state
			if not C_WeeklyRewards then return 'mythicplus-greatvault-incomplete' end

			-- Ensure weekly rewards addon is loaded
			if not C_AddOns.IsAddOnLoaded('Blizzard_WeeklyRewards') then C_AddOns.LoadAddOn('Blizzard_WeeklyRewards') end

			-- Check if there are rewards available to collect
			if C_WeeklyRewards.HasAvailableRewards and C_WeeklyRewards.HasAvailableRewards() then return 'mythicplus-greatvault-collect' end

			-- Check if any activities are completed but already claimed
			local activities = C_WeeklyRewards.GetActivities()
			if not activities or #activities == 0 then return 'mythicplus-greatvault-incomplete' end

			local hasComplete = false

			for _, activity in ipairs(activities) do
				-- Check all activity types
				if
					activity.type == Enum.WeeklyRewardChestThresholdType.Activities
					or activity.type == Enum.WeeklyRewardChestThresholdType.Raid
					or activity.type == Enum.WeeklyRewardChestThresholdType.World
				then
					if activity.progress >= activity.threshold then
						hasComplete = true
						break
					end
				end
			end

			if hasComplete then
				return 'mythicplus-greatvault-complete'
			else
				return 'mythicplus-greatvault-incomplete'
			end
		end,
		onClick = function()
			if InCombatLockdown() then
				SUI:Print(L['You cannot open the Great Vault while in combat.'])
				return
			end

			if not WeeklyRewardsFrame then UIParentLoadAddOn('Blizzard_WeeklyRewards') end

			if _G['WeeklyRewardsFrame'] then
				ShowUIPanel(WeeklyRewardsFrame, true)
			else
				SUI:Print('Something went wrong and the weekly rewards could not be loaded.')
			end
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 8 -- Available since Shadowlands
		end,
	},
	{
		expansion = '',
		displayText = 'Skyriding',
		enabled = true,
		icon = 'Interface\\Icons\\Ability_DragonRiding_Glyph01',
		onClick = function()
			if InCombatLockdown() then
				SUI:Print('Cannot open Skyriding while in combat.')
				return
			end

			if GenericTraitFrame and GenericTraitFrame:IsShown() then GenericTraitFrame:Hide() end

			GenericTraitUI_LoadUI()
			GenericTraitFrame:SetSystemID(30)
			GenericTraitFrame:SetTreeID(672)
			ToggleFrame(GenericTraitFrame)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 10 -- The War Within (Skyriding available)
		end,
	},
	{
		expansion = 'TWW',
		displayText = 'TWW: Brann Configuration',
		enabled = true,
		icon = 'delves-bountiful',
		onClick = function()
			if not DelvesCompanionConfigurationFrame then C_AddOns.LoadAddOn('Blizzard_DelvesCompanionConfiguration') end
			if not DelvesCompanionConfigurationFrame:IsShown() then
				ShowUIPanel(DelvesCompanionConfigurationFrame)
			else
				HideUIPanel(DelvesCompanionConfigurationFrame)
			end
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 10
		end,
	},
	{
		expansion = 'TWW',
		displayText = 'TWW: Reshii Wraps',
		enabled = true,
		icon = 'Interface\\Icons\\Inv_cape_armor_etherealshawl_d_01',
		onClick = function()
			if GenericTraitFrame and GenericTraitFrame:IsShown() then GenericTraitFrame:Hide() end

			GenericTraitUI_LoadUI()
			GenericTraitFrame:SetSystemID(29)
			GenericTraitFrame:SetTreeID(1115)
			ToggleFrame(GenericTraitFrame)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 10
		end,
	},
	{
		expansion = 'DF',
		displayText = 'DF: Renown',
		enabled = true,
		icon = 'dragonflight-landingbutton-up',
		onClick = function()
			-- Dragonflight constants
			local dragonflightLandingPageTypeID = Enum.ExpansionLandingPageType.Dragonflight

			-- Ensure ExpansionLandingPage exists
			if not ExpansionLandingPage then
				print('ExpansionLandingPage frame not available')
				return
			end

			-- Close any conflicting frames
			if GarrisonLandingPage and GarrisonLandingPage:IsShown() then HideUIPanel(GarrisonLandingPage) end

			if ExpansionLandingPage:IsShown() and ExpansionLandingPage.expansionLandingPageType ~= dragonflightLandingPageTypeID then HideUIPanel(ExpansionLandingPage) end

			-- Set the expansion landing page type
			ExpansionLandingPage.expansionLandingPageType = dragonflightLandingPageTypeID

			-- Create and apply Dragonflight overlay using built-in Blizzard mixin
			local function ApplyDragonflightOverlay()
				-- Hide existing overlay if present
				if ExpansionLandingPage.overlayFrame then ExpansionLandingPage.overlayFrame:Hide() end

				-- Create Dragonflight overlay using Blizzard's built-in mixin
				if DragonflightLandingOverlayMixin then
					local dragonflightOverlay = CreateFromMixins(DragonflightLandingOverlayMixin)
					if dragonflightOverlay and dragonflightOverlay.CreateOverlay then
						ExpansionLandingPage.overlayFrame = dragonflightOverlay.CreateOverlay(ExpansionLandingPage.Overlay)
						if ExpansionLandingPage.overlayFrame then ExpansionLandingPage.overlayFrame:Show() end
					else
						print('Warning: Could not create Dragonflight overlay')
					end
				else
					print('Warning: DragonflightLandingOverlayMixin not available')
				end
			end

			-- Apply the overlay
			ApplyDragonflightOverlay()

			-- Open the landing page
			ToggleExpansionLandingPage()
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 9 -- Dragonflight
		end,
	},
	{
		expansion = 'SL',
		displayText = 'SL: Covenants',
		enabled = true,
		icon = function()
			-- Dynamic icon based on player's covenant
			if not C_Covenants or not C_Covenants.GetActiveCovenantID then
				return 'CovenantChoice-Celebration-KyrianSigil' -- Default fallback
			end

			local covenantID = C_Covenants.GetActiveCovenantID()
			if covenantID == 1 then
				return 'CovenantChoice-Celebration-KyrianSigil' -- Kyrian
			elseif covenantID == 2 then
				return 'CovenantChoice-Celebration-VenthyrSigil' -- Venthyr
			elseif covenantID == 3 then
				return 'CovenantChoice-Celebration-NightFaeSigil' -- Night Fae
			elseif covenantID == 4 then
				return 'CovenantChoice-Celebration-NecrolordSigil' -- Necrolord
			else
				return 'CovenantChoice-Celebration-KyrianSigil' -- Default/No covenant
			end
		end,
		onClick = function()
			if InCombatLockdown() then
				SUI:Print('Cannot open Covenants while in combat.')
				return
			end

			-- Load Garrison UI for Shadowlands covenant missions/followers
			if not C_AddOns.IsAddOnLoaded('Blizzard_GarrisonUI') then C_AddOns.LoadAddOn('Blizzard_GarrisonUI') end

			-- Small delay to ensure addon is loaded
			C_Timer.After(0.1, function()
				-- Enum.GarrisonType.Type_9_0_Garrison = Shadowlands Covenant
				if _G['ShowGarrisonLandingPage'] and Enum.GarrisonType.Type_9_0_Garrison then
					ShowGarrisonLandingPage(Enum.GarrisonType.Type_9_0_Garrison)
				else
					SUI:Print('Covenant missions could not be loaded.')
				end
			end)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 8 and C_Covenants and C_Covenants.GetActiveCovenantID
		end,
		isDisabled = function()
			-- Disable if no covenant is selected
			if not C_Covenants or not C_Covenants.GetActiveCovenantID then return true end
			return C_Covenants.GetActiveCovenantID() == 0
		end,
		disabledTooltip = 'No Covenant Selected',
	},
	{
		expansion = 'BFA',
		displayText = 'BFA: Mission Table',
		enabled = true,
		icon = 'Interface\\Icons\\inv_misc_treasurechest02b',
		onClick = function()
			if InCombatLockdown() then
				SUI:Print('Cannot open BFA Mission Table while in combat.')
				return
			end

			-- Load BFA Garrison UI
			if not C_AddOns.IsAddOnLoaded('Blizzard_GarrisonUI') then C_AddOns.LoadAddOn('Blizzard_GarrisonUI') end

			-- Small delay to ensure addon is loaded
			C_Timer.After(0.1, function()
				-- Enum.GarrisonType.Type_8_0_Garrison = BFA Mission Table
				if _G['ShowGarrisonLandingPage'] and Enum.GarrisonType.Type_8_0_Garrison then
					ShowGarrisonLandingPage(Enum.GarrisonType.Type_8_0_Garrison)
				else
					SUI:Print('BFA Mission Table could not be loaded.')
				end
			end)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 7 -- Battle for Azeroth
		end,
	},
	{
		expansion = 'WOD',
		displayText = 'WOD: Garrison',
		enabled = true,
		icon = 'Interface\\Icons\\Garrison_Building_Townhall',
		onClick = function()
			if InCombatLockdown() then
				SUI:Print('Cannot open Garrison while in combat.')
				return
			end

			-- Load WoD Garrison UI
			if not C_AddOns.IsAddOnLoaded('Blizzard_GarrisonUI') then C_AddOns.LoadAddOn('Blizzard_GarrisonUI') end

			-- Small delay to ensure addon is loaded
			C_Timer.After(0.1, function()
				-- Enum.GarrisonType.Type_6_0_Garrison = WoD Garrison
				if _G['ShowGarrisonLandingPage'] and Enum.GarrisonType.Type_6_0_Garrison then
					ShowGarrisonLandingPage(Enum.GarrisonType.Type_6_0_Garrison)
				else
					SUI:Print('WoD Garrison could not be loaded.')
				end
			end)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 5 -- Warlords of Draenor
		end,
	},
	{
		expansion = 'LEG',
		displayText = 'LEG: Order Hall',
		enabled = true,
		icon = function()
			-- Dynamic icon based on player class
			local _, class = UnitClass('player')
			if class then
				local className = class:lower()
				return 'legionmission-landingbutton-' .. className .. '-up'
			else
				-- Fallback to generic Legion icon
				return 'legionmission-landingbutton-warrior-up'
			end
		end,
		onClick = function()
			if InCombatLockdown() then
				SUI:Print('Cannot open Order Hall while in combat.')
				return
			end

			-- Load Legion Garrison UI
			if not C_AddOns.IsAddOnLoaded('Blizzard_GarrisonUI') then C_AddOns.LoadAddOn('Blizzard_GarrisonUI') end

			-- Small delay to ensure addon is loaded
			C_Timer.After(0.1, function()
				-- Enum.GarrisonType.Type_7_0_Garrison = Legion Order Hall
				if _G['ShowGarrisonLandingPage'] and Enum.GarrisonType.Type_7_0_Garrison then
					ShowGarrisonLandingPage(Enum.GarrisonType.Type_7_0_Garrison)
				else
					SUI:Print('Legion Order Hall could not be loaded.')
				end
			end)
		end,
		requirementCheck = function()
			return GetExpansionLevel() >= 6 -- Legion
		end,
	},
}

----------------------------------------------------------------------------------------------------
-- Core Registration System

---Register a new expansion menu item
---@param expansion string Expansion abbreviation (e.g., "DF", "SL")
---@param displayText string Text to show in menu (e.g., "DF: Renown")
---@param onClick function Function to call when clicked
---@param requirementCheck function|nil Optional function to check if item should be shown
---@param enabled boolean|nil Whether this item is enabled by default
---@param icon string|nil Optional icon path for the menu item
---@param isDisabled function|nil Optional function to check if item should be disabled
---@param disabledTooltip string|nil Optional tooltip text when disabled
function module:RegisterExpansionItem(expansion, displayText, onClick, requirementCheck, enabled, icon, isDisabled, disabledTooltip)
	if not expansion or not displayText or not onClick then
		SUI:Error('ExpandedExpansionButton', 'Invalid registration parameters')
		return
	end

	local item = {
		expansion = expansion,
		displayText = displayText,
		onClick = onClick,
		requirementCheck = requirementCheck or function()
			return true
		end,
		enabled = enabled ~= false,
		icon = icon,
		isDisabled = isDisabled,
		disabledTooltip = disabledTooltip,
		id = expansion .. '_' .. displayText:gsub('[^%w]', ''),
	}

	table.insert(registeredExpansions, item)

	-- Sort by expansion then by display text using global expansion order
	table.sort(registeredExpansions, function(a, b)
		local orderA = expansionOrder[a.expansion] or 999
		local orderB = expansionOrder[b.expansion] or 999

		if orderA == orderB then
			-- Same expansion, sort by display text
			return a.displayText < b.displayText
		end
		return orderA < orderB
	end)
end

---Unregister an expansion item by ID
---@param itemId string The ID of the item to unregister
function module:UnregisterExpansionItem(itemId)
	for i, item in ipairs(registeredExpansions) do
		if item.id == itemId then
			table.remove(registeredExpansions, i)
			break
		end
	end
end

---Get all registered expansion items
---@return table Array of registered expansion items
function module:GetRegisteredItems()
	return registeredExpansions
end

---Check if an item is enabled in settings
---@param itemId string The ID of the item to check
---@return boolean Whether the item is enabled
function module:IsItemEnabled(itemId)
	return module.DB.enabledItems[itemId] ~= false
end

---Set whether an item is enabled
---@param itemId string The ID of the item
---@param enabled boolean Whether to enable the item
function module:SetItemEnabled(itemId, enabled)
	module.DB.enabledItems[itemId] = enabled
end

----------------------------------------------------------------------------------------------------
-- Menu Creation and Display

---Create menu using LibQTip
local function CreateLibQTipMenu()
	if menuFrame then
		menuFrame:Release()
		menuFrame = nil
	end

	-- Hide any existing tooltips to prevent overlap
	GameTooltip:Hide()
	if ExpansionLandingPageMinimapButton and ExpansionLandingPageMinimapButton.tooltip then ExpansionLandingPageMinimapButton.tooltip:Hide() end

	menuFrame = LibQTip:Acquire('SUI_ExpandedExpansionMenu', 2, 'LEFT', 'LEFT')

	if not menuFrame then return end
	menuFrame:SetAutoHideDelay(0.1, ExpansionLandingPageMinimapButton)
	menuFrame:SmartAnchorTo(ExpansionLandingPageMinimapButton)

	-- Apply SpartanUI theming with modern backdrop support
	if BackdropTemplateMixin then
		Mixin(menuFrame, BackdropTemplateMixin)
		menuFrame:SetBackdrop({
			bgFile = 'Interface\\ChatFrame\\ChatFrameBackground',
			edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
			tile = true,
			tileSize = 16,
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		menuFrame:SetBackdropColor(0.05, 0.05, 0.15, 0.95)
		menuFrame:SetBackdropBorderColor(0.6, 0.6, 0.8, 1)
	end

	-- Add sparkly header with colored text
	local headerLine = menuFrame:AddHeader()
	menuFrame:SetCell(headerLine, 1, '|cffFFD700|r', 'CENTER', 1, nil, nil, nil, 18, 18)
	menuFrame:SetCell(headerLine, 2, '|cffFFD700Expansion Features|r', 'LEFT')

	-- Add separator
	menuFrame:AddSeparator()

	-- Group items by expansion
	local expansionGroups = {}
	for _, item in ipairs(registeredExpansions) do
		local requirementMet = item.requirementCheck()
		local itemEnabled = module:IsItemEnabled(item.id)

		if requirementMet and itemEnabled then
			if not expansionGroups[item.expansion] then expansionGroups[item.expansion] = {} end
			table.insert(expansionGroups[item.expansion], item)
		end
	end

	-- Add items grouped by expansion in proper order
	local firstGroup = true

	-- Create sorted list of expansions
	local sortedExpansions = {}
	for expansion, items in pairs(expansionGroups) do
		table.insert(sortedExpansions, { expansion = expansion, items = items })
	end

	-- Sort expansions by our defined order
	table.sort(sortedExpansions, function(a, b)
		local orderA = expansionOrder[a.expansion] or 999
		local orderB = expansionOrder[b.expansion] or 999
		return orderA < orderB
	end)

	-- Display expansions in sorted order
	for _, expansionData in ipairs(sortedExpansions) do
		if not firstGroup then menuFrame:AddSeparator() end
		firstGroup = false
		local items = expansionData.items

		for _, item in ipairs(items) do
			-- Check if item should be disabled
			local isItemDisabled = item.isDisabled and item.isDisabled() or false

			local line = menuFrame:AddLine()

			-- Use actual texture icons if available, otherwise fall back to symbols
			local iconContent
			local iconPath = item.icon

			-- Handle dynamic icon functions
			if type(iconPath) == 'function' then iconPath = iconPath() end

			if iconPath and iconPath ~= '' then
				-- Check if it's an atlas texture (no Interface\ prefix) or regular texture
				if iconPath:find('^Interface\\') then
					-- Regular texture path
					iconContent = '|T' .. iconPath .. ':16:16:0:0|t'
				else
					-- Atlas texture
					iconContent = '|A:' .. iconPath .. ':16:16:0:0|a'
				end
			else
				-- Fallback to expansion-specific symbols
				local iconSymbol = '|cffCCCCFF•|r' -- default bullet
				if item.expansion == 'TWW' then
					iconSymbol = '|cff9D4A9A◆|r' -- purple diamond
				elseif item.expansion == 'DF' then
					iconSymbol = '|cff4A9AFF▲|r' -- blue triangle
				elseif item.expansion == 'SL' then
					iconSymbol = '|cffB4A7D6♦|r' -- light purple diamond
				elseif item.expansion == 'BFA' then
					iconSymbol = '|cffFFAA00●|r' -- orange circle
				elseif item.expansion == 'LEG' then
					iconSymbol = '|cff00FF96■|r' -- green square
				elseif item.expansion == 'WOD' then
					iconSymbol = '|cffAA6C39♦|r' -- brown diamond
				end
				iconContent = iconSymbol
			end

			-- Dim icon if disabled
			if isItemDisabled then iconContent = '|cff666666' .. iconContent .. '|r' end

			menuFrame:SetCell(line, 1, iconContent, 'CENTER')

			-- Color code expansion names
			local coloredText = item.displayText
			if isItemDisabled then
				coloredText = '|cff666666' .. item.displayText .. '|r'
			elseif item.expansion == 'TWW' then
				coloredText = '|cff9D4A9A' .. item.displayText .. '|r'
			elseif item.expansion == 'DF' then
				coloredText = '|cff4A9AFF' .. item.displayText .. '|r'
			elseif item.expansion == 'SL' then
				coloredText = '|cffB4A7D6' .. item.displayText .. '|r'
			elseif item.expansion == 'BFA' then
				coloredText = '|cffFFAA00' .. item.displayText .. '|r'
			elseif item.expansion == 'LEG' then
				coloredText = '|cff00FF96' .. item.displayText .. '|r'
			elseif item.expansion == 'WOD' then
				coloredText = '|cffAA6C39' .. item.displayText .. '|r'
			end

			menuFrame:SetCell(line, 2, coloredText, 'LEFT')

			-- Add hover effects and tooltip handling
			menuFrame:SetLineScript(line, 'OnEnter', function(self)
				-- Show tooltip if item is disabled
				if isItemDisabled and item.disabledTooltip then
					GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
					GameTooltip:SetText(item.disabledTooltip, 1, 0.8, 0, 1, true)
					GameTooltip:Show()
				end
			end)
			menuFrame:SetLineScript(line, 'OnLeave', function(self)
				GameTooltip:Hide()
			end)

			-- Set up click handler using LibQTip's cell click method
			-- LibQTip specific cell click handler
			menuFrame:SetCellScript(line, 2, 'OnMouseUp', function(self, button)
				-- Don't execute if item is disabled
				if isItemDisabled then return end

				-- LibQTip might pass button differently
				if not button or button == 'LeftButton' then
					-- Hide menu first
					if menuFrame then
						menuFrame:Release()
						menuFrame = nil
					end

					-- Execute the function with a small delay to ensure menu is hidden
					C_Timer.After(0.1, function()
						local success, errorMsg = pcall(item.onClick)
						if not success then SUI:Print('Error executing ' .. item.displayText .. ': ' .. tostring(errorMsg)) end
					end)
				end
			end)

			-- Also set line script as fallback
			menuFrame:SetLineScript(line, 'OnMouseUp', function(self, button)
				-- Don't execute if item is disabled
				if isItemDisabled then return end

				if not button or button == 'LeftButton' then
					if menuFrame then
						menuFrame:Release()
						menuFrame = nil
					end

					C_Timer.After(0.1, function()
						local success, errorMsg = pcall(item.onClick)
						if not success then SUI:Print('Error executing ' .. item.displayText .. ': ' .. tostring(errorMsg)) end
					end)
				end
			end)
		end
	end

	-- Add settings line with sparkle
	if #registeredExpansions > 0 then
		menuFrame:AddSeparator()
		local line = menuFrame:AddLine()
		menuFrame:SetCell(line, 1, '|A:mechagon-projects:16:16:0:0|a', 'CENTER')
		menuFrame:SetCell(line, 2, '|cff999999Settings...|r', 'LEFT')
		-- Use both cell and line scripts for settings too
		menuFrame:SetCellScript(line, 2, 'OnMouseUp', function(self, button)
			if not button or button == 'LeftButton' then
				-- Hide menu first
				if menuFrame then
					menuFrame:Release()
					menuFrame = nil
				end

				-- Open settings with a small delay
				C_Timer.After(0.1, function()
					local success, errorMsg = pcall(module.OpenSettings, module)
					if not success then SUI:Print('Error opening settings: ' .. tostring(errorMsg)) end
				end)
			end
		end)

		menuFrame:SetLineScript(line, 'OnMouseUp', function(self, button)
			if not button or button == 'LeftButton' then
				if menuFrame then
					menuFrame:Release()
					menuFrame = nil
				end

				C_Timer.After(0.1, function()
					local success, errorMsg = pcall(module.OpenSettings, module)
					if not success then SUI:Print('Error opening settings: ' .. tostring(errorMsg)) end
				end)
			end
		end)
		menuFrame:SetLineScript(line, 'OnEnter', function(self)
			-- LibQTip will handle highlighting
		end)
		menuFrame:SetLineScript(line, 'OnLeave', function(self)
			-- LibQTip will handle highlighting
		end)
	end

	menuFrame:Show()
end

---Create menu using native dropdown (fallback)
local function CreateDropdownMenu()
	local menu = CreateFrame('Frame', 'SUI_ExpandedExpansionMenu', UIParent, 'UIDropDownMenuTemplate')

	local function InitializeMenu(self, level)
		level = level or 1

		-- Group items by expansion
		local expansionGroups = {}
		for _, item in ipairs(registeredExpansions) do
			if item.requirementCheck() and module:IsItemEnabled(item.id) then
				if not expansionGroups[item.expansion] then expansionGroups[item.expansion] = {} end
				table.insert(expansionGroups[item.expansion], item)
			end
		end

		-- Add header
		local info = UIDropDownMenu_CreateInfo()
		info.text = 'Expansion Features'
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)

		-- Add items
		for expansion, items in pairs(expansionGroups) do
			for _, item in ipairs(items) do
				info = UIDropDownMenu_CreateInfo()
				info.text = item.displayText
				info.func = item.onClick
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, level)
			end
		end

		-- Add separator and settings
		if #registeredExpansions > 0 then
			info = UIDropDownMenu_CreateInfo()
			info.text = ''
			info.disabled = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info = UIDropDownMenu_CreateInfo()
			info.text = '|cff999999Settings...|r'
			info.func = function()
				module:OpenSettings()
			end
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)
		end
	end

	UIDropDownMenu_Initialize(menu, InitializeMenu, 'MENU')
	ToggleDropDownMenu(1, nil, menu, 'cursor', 3, -3)
end

---Create the right-click menu using LibQTip or fallback to dropdown
local function CreateMenu()
	if LibQTip then
		CreateLibQTipMenu()
	else
		CreateDropdownMenu()
	end
end

---Handle right-click on expansion button
local function OnExpansionButtonRightClick()
	if InCombatLockdown() then
		SUI:Print('Cannot open expansion menu while in combat.')
		return
	end

	CreateMenu()
end

----------------------------------------------------------------------------------------------------
-- Settings Panel

function module:OpenSettings()
	-- Open SpartanUI settings to the ExpandedExpansionButton panel
	if SUI.Options and SUI.Options.ToggleOptions then SUI.Options:ToggleOptions({ 'Modules', 'ExpandedExpansionButton' }) end
end

function module:BuildOptions()
	local options = {
		type = 'group',
		name = L['Expanded Expansion Button'],
		args = {
			description = {
				type = 'description',
				name = 'Configure which expansion features appear in the right-click menu.',
				order = 1,
			},
			enabledItems = {
				type = 'group',
				name = 'Menu Items',
				inline = true,
				order = 2,
				args = {},
			},
		},
	}

	-- Dynamically add options for each registered item
	for i, item in ipairs(registeredExpansions) do
		if item.requirementCheck() then
			options.args.enabledItems.args[item.id] = {
				type = 'toggle',
				name = item.displayText,
				desc = 'Enable this item in the expansion menu',
				get = function()
					return module:IsItemEnabled(item.id)
				end,
				set = function(_, value)
					module:SetItemEnabled(item.id, value)
				end,
				order = i,
			}
		end
	end

	SUI.Options:AddOptions(options, 'ExpandedExpansionButton')
end

----------------------------------------------------------------------------------------------------
-- Initialization and Events

function module:OnInitialize()
	---@class SUI.ExpandedExpansionButton.Database
	local defaults = {
		enabled = true,
		enabledItems = {},
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('ExpandedExpansionButton', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.ExpandedExpansionButton.Database

	-- Register default expansion items
	for _, item in ipairs(defaultExpansions) do
		module:RegisterExpansionItem(item.expansion, item.displayText, item.onClick, item.requirementCheck, item.enabled, item.icon, item.isDisabled, item.disabledTooltip)
	end
end

function module:OnEnable()
	if SUI:IsModuleDisabled('ExpandedExpansionButton') then return end

	-- Verify LibQTip is available
	if not LibQTip then return end

	-- Hook the expansion button right-click
	if ExpansionLandingPageMinimapButton then
		ExpansionLandingPageMinimapButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

		-- Store original script
		local originalOnClick = ExpansionLandingPageMinimapButton:GetScript('OnClick')

		ExpansionLandingPageMinimapButton:SetScript('OnClick', function(self, button, down)
			if button == 'RightButton' then
				OnExpansionButtonRightClick()
				return -- Block default behavior
			elseif originalOnClick then
				originalOnClick(self, button, down)
			end
		end)
	else
		-- Wait for the button to be created
		local frame = CreateFrame('Frame')
		frame:RegisterEvent('ADDON_LOADED')
		frame:RegisterEvent('PLAYER_ENTERING_WORLD')
		frame:SetScript('OnEvent', function(_, event, addonName)
			if ExpansionLandingPageMinimapButton then
				ExpansionLandingPageMinimapButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

				-- Store original script
				local originalOnClick = ExpansionLandingPageMinimapButton:GetScript('OnClick')

				ExpansionLandingPageMinimapButton:SetScript('OnClick', function(self, button, down)
					if button == 'RightButton' then
						OnExpansionButtonRightClick()
						return -- Block default behavior
					elseif originalOnClick then
						originalOnClick(self, button, down)
					end
				end)

				frame:UnregisterAllEvents()
			end
		end)
	end

	-- Build options panel
	module:BuildOptions()
end

----------------------------------------------------------------------------------------------------
-- API for external addons

-- Expose registration function globally for other addons
SUI.ExpandedExpansionButton = {
	RegisterExpansionItem = function(...)
		return module:RegisterExpansionItem(...)
	end,
	UnregisterExpansionItem = function(...)
		return module:UnregisterExpansionItem(...)
	end,
	GetRegisteredItems = function(...)
		return module:GetRegisteredItems(...)
	end,
}
