local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('ObjectiveTracker') ---@type SUI.Module.ObjectiveTracker
module.DisplayName = 'Objective Tracker'
module.description = 'Enhanced objective tracker with advanced customization options'

----------------------------------------------------------------------------------------------------
-- Module Variables
local ObjectiveTrackerFrame
local fadeInAnim, fadeOutAnim
local backgroundFrame

----------------------------------------------------------------------------------------------------
-- Database and Settings

function module:OnInitialize()
	---@class SUI.ObjectiveTracker.Database
	local defaults = {
		enabled = true,
		keybindToggle = nil,
		hideInCombat = false,
		scale = 1.0,
		opacity = 1.0,
		mouseoverOpacity = true,
		mouseoverFadeIn = 1.0,
		mouseoverFadeOut = 0.6,
		mouseoverDelay = 0.4,
		backgroundEnabled = false,
		backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
		autoCollapseInCombat = {
			achievement = false,
			quest = true,
			bonus = false,
			scenario = false,
			world = false,
		},
	}

	module.Database = SUI.SpartanUIDB:RegisterNamespace('ObjectiveTracker', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.ObjectiveTracker.Database
end

function module:OnEnable()
	if SUI:IsModuleDisabled('ObjectiveTracker') then return end

	-- Initialize frame references
	ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame

	-- Wait for ObjectiveTrackerFrame if it's not available yet
	if not ObjectiveTrackerFrame then
		local waitFrame = CreateFrame('Frame')
		waitFrame:RegisterEvent('ADDON_LOADED')
		waitFrame:RegisterEvent('PLAYER_LOGIN')
		waitFrame:SetScript('OnEvent', function(self, event)
			ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
			if ObjectiveTrackerFrame then
				waitFrame:UnregisterAllEvents()
				module:SetupObjectiveTracker()
			end
		end)
	else
		module:SetupObjectiveTracker()
	end

	module:SetupKeyBindings()
	module:SetupEventHandlers()
	module:BuildOptions()
end

function module:OnDisable()
	module:CleanupModule()
end

function module:CleanupModule()
	-- Clean up animations
	if fadeInAnim then
		fadeInAnim:Stop()
		fadeInAnim = nil
	end
	if fadeOutAnim then
		fadeOutAnim:Stop()
		fadeOutAnim = nil
	end

	-- Clean up mouseover area and timers
	if module.mouseArea then
		module.mouseArea:SetScript('OnUpdate', nil)
		module.mouseArea:Hide()
		module.mouseArea = nil
	end

	-- Clean up any pending timers
	if module.checkTimer then
		module.checkTimer:Cancel()
		module.checkTimer = nil
	end

	-- Reset ObjectiveTrackerFrame to original state
	if ObjectiveTrackerFrame then
		ObjectiveTrackerFrame:SetScale(1.0)
		ObjectiveTrackerFrame:SetAlpha(1.0)
		ObjectiveTrackerFrame:Show()
	end

	-- Clean up background frame
	if backgroundFrame then backgroundFrame:Hide() end
end

----------------------------------------------------------------------------------------------------
-- Core Functionality

function module:SetupObjectiveTracker()
	if not ObjectiveTrackerFrame then return end

	-- Create a separate background frame
	if not backgroundFrame then
		backgroundFrame = CreateFrame('Frame', nil, ObjectiveTrackerFrame)
		backgroundFrame:SetAllPoints(ObjectiveTrackerFrame.NineSlice)
		backgroundFrame:SetFrameLevel(ObjectiveTrackerFrame:GetFrameLevel() - 1)

		local bg = backgroundFrame:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.5)
		backgroundFrame.texture = bg
		backgroundFrame:Hide()
	end

	-- Apply initial settings
	module:UpdateScale()
	module:UpdateOpacity()
	module:UpdateBackground()

	-- Setup mouseover effects
	module:SetupMouseoverEffects()
end

function module:SetupMouseoverEffects()
	if not module.DB.mouseoverOpacity or not ObjectiveTrackerFrame then return end

	-- Set initial alpha
	ObjectiveTrackerFrame:SetAlpha(module.DB.mouseoverFadeOut)

	-- Track mouse state
	local isFadedIn = false
	local fadeTimer = nil

	-- Function to fade elements in/out using UIFrameFadeIn/UIFrameFadeOut (like BetterBlizzFrames)
	local function FadeInFrame()
		UIFrameFadeIn(ObjectiveTrackerFrame, 0.2, ObjectiveTrackerFrame:GetAlpha(), module.DB.mouseoverFadeIn)
	end

	local function FadeOutFrame()
		UIFrameFadeOut(ObjectiveTrackerFrame, 0.5, ObjectiveTrackerFrame:GetAlpha(), module.DB.mouseoverFadeOut)
	end

	-- Function to check if mouse is over actual objective tracker content areas
	local function IsAnyMouseOver()
		-- Check the main header
		if ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header:IsMouseOver() then return true end

		-- Check individual tracker modules (only the actual content areas)
		local trackerModules = {
			'AchievementObjectiveTracker',
			'QuestObjectiveTracker',
			'BonusObjectiveTracker',
			'ScenarioObjectiveTracker',
			'WorldQuestObjectiveTracker',
			'CampaignQuestObjectiveTracker',
			'MonthlyActivitiesObjectiveTracker',
			'AdventureObjectiveTracker',
			'ProfessionsRecipeTracker',
		}

		for _, moduleName in ipairs(trackerModules) do
			local trackerModule = _G[moduleName]
			if trackerModule and trackerModule:IsShown() and trackerModule:IsMouseOver() then return true end
		end

		return false
	end

	-- Show elements (fade in)
	local function ShowElements()
		-- Check if mouseover is enabled
		if not module.DB.mouseoverOpacity then return end

		if not isFadedIn then
			if fadeTimer then
				fadeTimer:Cancel()
				fadeTimer = nil
				module.checkTimer = nil
			end
			FadeInFrame()
			isFadedIn = true
		end
	end

	-- Hide elements (fade out with grace period)
	local function HideElements()
		-- Check if mouseover is enabled
		if not module.DB.mouseoverOpacity then return end

		if fadeTimer then fadeTimer:Cancel() end

		fadeTimer = C_Timer.NewTimer(module.DB.mouseoverDelay, function()
			if not IsAnyMouseOver() then
				FadeOutFrame()
				isFadedIn = false
			end
			fadeTimer = nil
			module.checkTimer = nil
		end)
		module.checkTimer = fadeTimer
	end

	-- Clean up any existing hooks to avoid duplicates
	if ObjectiveTrackerFrame.suiMouseHooked then
		-- We can't easily unhook, but we can mark and avoid re-hooking
	end

	-- Hook mouse events to individual content areas instead of the entire frame
	-- Hook the header
	if ObjectiveTrackerFrame.Header and not ObjectiveTrackerFrame.Header.suiMouseHooked then
		ObjectiveTrackerFrame.Header:HookScript('OnEnter', ShowElements)
		ObjectiveTrackerFrame.Header:HookScript('OnLeave', HideElements)
		ObjectiveTrackerFrame.Header.suiMouseHooked = true
	end

	-- Hook each tracker module
	local trackerModules = {
		'AchievementObjectiveTracker',
		'QuestObjectiveTracker',
		'BonusObjectiveTracker',
		'ScenarioObjectiveTracker',
		'WorldQuestObjectiveTracker',
		'CampaignQuestObjectiveTracker',
		'MonthlyActivitiesObjectiveTracker',
		'AdventureObjectiveTracker',
		'ProfessionsRecipeTracker',
	}

	for _, moduleName in ipairs(trackerModules) do
		local trackerModule = _G[moduleName]
		if trackerModule and not trackerModule.suiMouseHooked then
			trackerModule:HookScript('OnEnter', ShowElements)
			trackerModule:HookScript('OnLeave', HideElements)
			trackerModule.suiMouseHooked = true
		end
	end

	-- Initial state: start faded out
	FadeOutFrame()
	isFadedIn = false
end

function module:SetupKeyBindings()
	-- Register the binding name in WoW's system
	_G['BINDING_HEADER_SUI_OBJECTIVES'] = 'SpartanUI Objectives'
	_G['BINDING_NAME_SUI_TOGGLE_OBJECTIVES'] = 'Toggle Objective Tracker'

	-- Store the function globally for the binding system
	_G['SUI_ToggleObjectiveTracker'] = function()
		module:ToggleObjectiveTracker()
	end

	-- If user has set a keybind in DB, apply it
	if module.DB.keybindToggle and module.DB.keybindToggle ~= '' then
		-- Clear any existing binding for this action
		local key1, key2 = GetBindingKey('SUI_TOGGLE_OBJECTIVES')
		if key1 then SetBinding(key1) end
		if key2 then SetBinding(key2) end

		-- Set the new binding
		SetBinding(module.DB.keybindToggle, 'SUI_TOGGLE_OBJECTIVES')
		SaveBindings(GetCurrentBindingSet())
	end
end

function module:SetupEventHandlers()
	if not module.eventFrame then
		module.eventFrame = CreateFrame('Frame')
		module.eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED') -- Combat start
		module.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED') -- Combat end

		module.eventFrame:SetScript('OnEvent', function(self, event)
			if event == 'PLAYER_REGEN_DISABLED' then
				module:OnCombatStart()
			elseif event == 'PLAYER_REGEN_ENABLED' then
				module:OnCombatEnd()
			end
		end)
	end
end

----------------------------------------------------------------------------------------------------
-- Event Handlers

function module:OnCombatStart()
	-- Store the main tracker collapsed state before combat
	if not module.preCollapseState then module.preCollapseState = {} end

	-- Handle main tracker collapse in combat
	if module.DB.hideInCombat then
		if ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header.MinimizeButton then
			-- Store the current collapsed state of the main tracker
			module.preCollapseState.mainTracker = ObjectiveTrackerFrame.collapsed or false

			-- Only collapse if it's not already collapsed
			if not module.preCollapseState.mainTracker then ObjectiveTrackerFrame.Header.MinimizeButton:Click() end
		end
	end

	-- Store the current state of ALL sections before making any changes
	local sectionMap = {
		achievement = 'AchievementObjectiveTracker',
		quest = 'QuestObjectiveTracker',
		bonus = 'BonusObjectiveTracker',
		scenario = 'ScenarioObjectiveTracker',
		world = 'WorldQuestObjectiveTracker',
	}

	-- First, store the current state of all sections
	for section, moduleKey in pairs(sectionMap) do
		local trackerModule = _G[moduleKey]
		if trackerModule then
			local wasCollapsed = false
			if trackerModule.Header and trackerModule.Header.MinimizeButton then wasCollapsed = trackerModule.collapsed or false end
			module.preCollapseState[section] = wasCollapsed
		end
	end

	-- Auto-collapse individual sections in combat
	for section, shouldCollapse in pairs(module.DB.autoCollapseInCombat) do
		if shouldCollapse then
			if not ObjectiveTrackerFrame then return end

			local moduleKey = sectionMap[section]
			local trackerModule = _G[moduleKey]
			if trackerModule then
				-- Only collapse if it's not already collapsed
				local isCurrentlyCollapsed = trackerModule.collapsed or false
				if not isCurrentlyCollapsed then
					-- Use pcall to safely attempt the collapse
					local success, err = pcall(function()
						-- Try different collapse methods based on WoW version/structure
						if trackerModule.SetCollapsed then
							trackerModule:SetCollapsed(true)
						elseif trackerModule.Header and trackerModule.Header.MinimizeButton then
							-- Simulate clicking the minimize button
							trackerModule.Header.MinimizeButton:Click()
						elseif trackerModule.Collapse then
							trackerModule:Collapse()
						end
					end)
				end
			end
		end
	end
end

function module:OnCombatEnd()
	-- Restore main tracker state
	if module.DB.hideInCombat and module.preCollapseState and module.preCollapseState.mainTracker ~= nil then
		if ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header.MinimizeButton then
			-- Only expand if it was expanded before combat
			if not module.preCollapseState.mainTracker then ObjectiveTrackerFrame.Header.MinimizeButton:Click() end
		end
	end

	-- Restore individual section collapsed states
	if module.preCollapseState then
		local sectionMap = {
			achievement = 'AchievementObjectiveTracker',
			quest = 'QuestObjectiveTracker',
			bonus = 'BonusObjectiveTracker',
			scenario = 'ScenarioObjectiveTracker',
			world = 'WorldQuestObjectiveTracker',
		}

		for section, wasCollapsed in pairs(module.preCollapseState) do
			-- Skip the mainTracker entry since that's not a section
			if section ~= 'mainTracker' then
				-- Only restore sections that:
				-- 1. Were expanded before combat (wasCollapsed = false)
				-- 2. Have auto-collapse enabled (so we actually changed them during combat)
				if module.DB.autoCollapseInCombat[section] and not wasCollapsed then
					if not ObjectiveTrackerFrame then return end

					local moduleKey = sectionMap[section]
					local trackerModule = _G[moduleKey]
					if trackerModule then
						-- Check if it's currently collapsed (it should be if our auto-collapse worked)
						local isCurrentlyCollapsed = trackerModule.collapsed or false
						if isCurrentlyCollapsed then
							-- Use pcall to safely attempt the expand
							local success, err = pcall(function()
								-- Try different expand methods based on WoW version/structure
								if trackerModule.SetCollapsed then
									trackerModule:SetCollapsed(false)
								elseif trackerModule.Header and trackerModule.Header.MinimizeButton then
									-- Click to expand
									trackerModule.Header.MinimizeButton:Click()
								elseif trackerModule.Expand then
									trackerModule:Expand()
								end
							end)
						end
					end
				end
			end
		end
		-- Clear the stored state
		module.preCollapseState = {}
	end
end

----------------------------------------------------------------------------------------------------
-- Update Functions

function module:UpdateScale()
	if ObjectiveTrackerFrame then
		-- Validate scale bounds
		local scale = math.max(0.5, math.min(2.0, module.DB.scale))
		if scale ~= module.DB.scale then module.DB.scale = scale end
		ObjectiveTrackerFrame:SetScale(scale)
	end
end

function module:UpdateOpacity()
	if not module.DB.mouseoverOpacity and ObjectiveTrackerFrame then
		-- Validate opacity bounds
		local opacity = math.max(0.1, math.min(1.0, module.DB.opacity))
		if opacity ~= module.DB.opacity then module.DB.opacity = opacity end
		ObjectiveTrackerFrame:SetAlpha(opacity)
	end
end

function module:UpdateBackground()
	if not ObjectiveTrackerFrame then return end

	if module.DB.backgroundEnabled and backgroundFrame then
		-- Show background
		if backgroundFrame.texture then
			local color = module.DB.backgroundColor
			backgroundFrame.texture:SetColorTexture(color.r, color.g, color.b, color.a)
			backgroundFrame:Show()
		end
	else
		if backgroundFrame then backgroundFrame:Hide() end
	end
end

function module:UpdateMouseoverSettings()
	-- Clean up existing mouseover effects
	if fadeInAnim then
		fadeInAnim:Stop()
		fadeInAnim = nil
	end
	if fadeOutAnim then
		fadeOutAnim:Stop()
		fadeOutAnim = nil
	end
	if module.mouseArea then
		module.mouseArea:SetScript('OnUpdate', nil)
		module.mouseArea:Hide()
		module.mouseArea = nil
	end
	if module.checkTimer then
		module.checkTimer:Cancel()
		module.checkTimer = nil
	end

	-- Only setup mouseover if ObjectiveTrackerFrame exists and mouseover is enabled
	if ObjectiveTrackerFrame and module.DB.mouseoverOpacity then
		module:SetupMouseoverEffects()
	elseif ObjectiveTrackerFrame then
		-- Reset to normal opacity when mouseover is disabled
		ObjectiveTrackerFrame:SetAlpha(module.DB.opacity)
	end
end

----------------------------------------------------------------------------------------------------
-- Public API

function module:ToggleObjectiveTracker()
	if ObjectiveTrackerFrame:IsShown() then
		module:SetObjectiveTrackerVisible(false)
	else
		module:SetObjectiveTrackerVisible(true)
	end
end

function module:SetObjectiveTrackerVisible(visible)
	if visible then
		ObjectiveTrackerFrame:Show()
	else
		ObjectiveTrackerFrame:Hide()
	end
end

function module:ToggleSection(sectionType, visible)
	if not ObjectiveTrackerFrame then return end

	local sectionMap = {
		achievement = 'AchievementObjectiveTracker',
		quest = 'QuestObjectiveTracker',
		bonus = 'BonusObjectiveTracker',
		scenario = 'ScenarioObjectiveTracker',
		world = 'WorldQuestObjectiveTracker',
	}

	local moduleKey = sectionMap[sectionType]
	local trackerModule = _G[moduleKey]
	if trackerModule then
		-- Use pcall to safely attempt the visibility change
		local success, err = pcall(function()
			if trackerModule.SetShown then
				trackerModule:SetShown(visible)
			elseif visible then
				if trackerModule.Show then trackerModule:Show() end
			else
				if trackerModule.Hide then trackerModule:Hide() end
			end
		end)
		if not success then
			-- Silently fail, different versions may have different methods
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Options Panel

function module:BuildOptions()
	local options = {
		type = 'group',
		name = L['Objective Tracker'],
		args = {
			description = {
				type = 'description',
				name = L['Configure the objective tracker with advanced options including keybinds, opacity, scaling, and individual section control.'],
				order = 1,
			},
			general = {
				type = 'group',
				name = L['General'],
				inline = true,
				order = 2,
				args = {
					keybindToggle = {
						type = 'keybinding',
						name = L['Toggle Keybind'],
						desc = L['Set a keybind to toggle the objective tracker'],
						get = function()
							return GetBindingKey('SUI_TOGGLE_OBJECTIVES') or module.DB.keybindToggle
						end,
						set = function(_, value)
							-- Clear existing binding
							local key1, key2 = GetBindingKey('SUI_TOGGLE_OBJECTIVES')
							if key1 then SetBinding(key1) end
							if key2 then SetBinding(key2) end

							-- Set new binding if value provided
							if value and value ~= '' then
								SetBinding(value, 'SUI_TOGGLE_OBJECTIVES')
								SaveBindings(GetCurrentBindingSet())
							end

							module.DB.keybindToggle = value
						end,
						order = 1,
					},
					hideInCombat = {
						type = 'toggle',
						name = L['Hide in Combat'],
						desc = L['Hide the objective tracker during combat'],
						get = function()
							return module.DB.hideInCombat
						end,
						set = function(_, value)
							module.DB.hideInCombat = value
						end,
						order = 2,
					},
				},
			},
			appearance = {
				type = 'group',
				name = L['Appearance'],
				inline = true,
				order = 3,
				args = {
					scale = {
						type = 'range',
						name = L['Scale'],
						desc = L['Adjust the scale of the objective tracker'],
						min = 0.5,
						max = 2.0,
						step = 0.05,
						get = function()
							return module.DB.scale
						end,
						set = function(_, value)
							module.DB.scale = value
							module:UpdateScale()
						end,
						order = 1,
					},
					opacity = {
						type = 'range',
						name = L['Opacity'],
						desc = L['Base opacity when mouseover is disabled'],
						min = 0.1,
						max = 1.0,
						step = 0.05,
						disabled = function()
							return module.DB.mouseoverOpacity
						end,
						get = function()
							return module.DB.opacity
						end,
						set = function(_, value)
							module.DB.opacity = value
							module:UpdateOpacity()
						end,
						order = 3,
					},
				},
			},
			mouseover = {
				type = 'group',
				name = L['Mouseover Effects'],
				inline = true,
				order = 4,
				args = {
					mouseoverOpacity = {
						type = 'toggle',
						name = L['Enable Mouseover'],
						desc = L['Enable opacity changes on mouseover'],
						get = function()
							return module.DB.mouseoverOpacity
						end,
						set = function(_, value)
							module.DB.mouseoverOpacity = value
							module:UpdateMouseoverSettings()
						end,
						order = 1,
					},
					mouseoverFadeIn = {
						type = 'range',
						name = L['Mouseover Opacity'],
						desc = L['Opacity when mouse is over the tracker'],
						min = 0.1,
						max = 1.0,
						step = 0.05,
						disabled = function()
							return not module.DB.mouseoverOpacity
						end,
						get = function()
							return module.DB.mouseoverFadeIn
						end,
						set = function(_, value)
							module.DB.mouseoverFadeIn = value
							module:UpdateMouseoverSettings()
						end,
						order = 2,
					},
					mouseoverFadeOut = {
						type = 'range',
						name = L['Normal Opacity'],
						desc = L['Opacity when mouse is not over the tracker'],
						min = 0.0,
						max = 1.0,
						step = 0.05,
						disabled = function()
							return not module.DB.mouseoverOpacity
						end,
						get = function()
							return module.DB.mouseoverFadeOut
						end,
						set = function(_, value)
							module.DB.mouseoverFadeOut = value
							module:UpdateMouseoverSettings()
						end,
						order = 3,
					},
					mouseoverDelay = {
						type = 'range',
						name = L['Fade Out Delay'],
						desc = L['Delay in seconds before fading out when mouse leaves the tracker'],
						min = 0.0,
						max = 2.0,
						step = 0.1,
						disabled = function()
							return not module.DB.mouseoverOpacity
						end,
						get = function()
							return module.DB.mouseoverDelay
						end,
						set = function(_, value)
							module.DB.mouseoverDelay = value
							module:UpdateMouseoverSettings()
						end,
						order = 4,
					},
				},
			},
			background = {
				type = 'group',
				name = L['Background'],
				inline = true,
				order = 5,
				args = {
					backgroundEnabled = {
						type = 'toggle',
						name = L['Show Background'],
						desc = L['Show a simple color background behind the objective tracker'],
						get = function()
							return module.DB.backgroundEnabled
						end,
						set = function(_, value)
							module.DB.backgroundEnabled = value
							module:UpdateBackground()
						end,
						order = 1,
					},
					backgroundColor = {
						type = 'color',
						name = L['Background Color'],
						desc = L['Color of the objective tracker background'],
						hasAlpha = true,
						disabled = function()
							return not module.DB.backgroundEnabled
						end,
						get = function()
							local color = module.DB.backgroundColor
							return color.r, color.g, color.b, color.a
						end,
						set = function(_, r, g, b, a)
							module.DB.backgroundColor = { r = r, g = g, b = b, a = a }
							module:UpdateBackground()
						end,
						order = 2,
					},
					spacer1 = {
						type = 'description',
						name = ' ',
						order = 3,
					},
				},
			},
			combatBehavior = {
				type = 'group',
				name = L['Combat Behavior'],
				inline = true,
				order = 7,
				args = {
					description = {
						type = 'description',
						name = L['Configure how sections behave during combat'],
						order = 1,
					},
					achievementCombat = {
						type = 'toggle',
						name = L['Auto-collapse Achievement'],
						desc = L['Automatically collapse achievement tracking in combat'],
						get = function()
							return module.DB.autoCollapseInCombat.achievement
						end,
						set = function(_, value)
							module.DB.autoCollapseInCombat.achievement = value
						end,
						order = 2,
					},
					questCombat = {
						type = 'toggle',
						name = L['Auto-collapse Quest'],
						desc = L['Automatically collapse quest tracking in combat'],
						get = function()
							return module.DB.autoCollapseInCombat.quest
						end,
						set = function(_, value)
							module.DB.autoCollapseInCombat.quest = value
						end,
						order = 3,
					},
					bonusCombat = {
						type = 'toggle',
						name = L['Auto-collapse Bonus'],
						desc = L['Automatically collapse bonus objectives in combat'],
						get = function()
							return module.DB.autoCollapseInCombat.bonus
						end,
						set = function(_, value)
							module.DB.autoCollapseInCombat.bonus = value
						end,
						order = 4,
					},
					scenarioCombat = {
						type = 'toggle',
						name = L['Auto-collapse Scenario'],
						desc = L['Automatically collapse scenario tracking in combat'],
						get = function()
							return module.DB.autoCollapseInCombat.scenario
						end,
						set = function(_, value)
							module.DB.autoCollapseInCombat.scenario = value
						end,
						order = 5,
					},
					worldCombat = {
						type = 'toggle',
						name = L['Auto-collapse World Quests'],
						desc = L['Automatically collapse world quest tracking in combat'],
						get = function()
							return module.DB.autoCollapseInCombat.world
						end,
						set = function(_, value)
							module.DB.autoCollapseInCombat.world = value
						end,
						order = 6,
					},
				},
			},
		},
	}

	SUI.Options:AddOptions(options, 'ObjectiveTracker')
end

----------------------------------------------------------------------------------------------------
-- Global API for keybindings
_G.SUI_ToggleObjectiveTracker = function()
	if module then module:ToggleObjectiveTracker() end
end
