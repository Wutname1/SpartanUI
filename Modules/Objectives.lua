local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_Objectives')
module.description = 'Allows the hiding of the Objectives tracker based on conditions'
----------------------------------------------------------------------------------------------------
local MoveIt
local ObjectiveTrackerWatcher = CreateFrame('Frame')
local holder = CreateFrame('Frame', 'ObjectiveTrackerHolder', UIParent)
local frameName = 'ObjectiveTrackerFrame'
local RuleList = {'Rule1', 'Rule2', 'Rule3'}
local Conditions = {
	['Group'] = L['In a Group'],
	['Raid'] = L['In a Raid Group'],
	['Boss'] = L['Boss Fight'],
	['Instance'] = L['In a instance'],
	['All'] = L['All the time'],
	['Disabled'] = L['Disabled']
}

local function UpdateSize()
	local screenHeight = GetScreenHeight()
	local FrameHeight = min((screenHeight - (screenHeight - (_G[frameName]:GetTop() or 0))), module.DB.height)

	holder:SetSize(280, FrameHeight)
	_G[frameName]:SetHeight(FrameHeight)
	MoveIt:UpdateMover('ObjectiveTracker')
end

local function MakeMoveable()
	local BlizzObjectiveFrame = _G[frameName]
	local point, anchor, secondaryPoint, x, y =
		strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.ObjectiveTracker)
	holder:SetPoint(point, anchor, secondaryPoint, x, y)
	holder:SetFrameStrata('LOW')
	holder:SetSize(280, module.DB.height)
	holder:Hide()
	holder.OnScale = function(self, val)
		BlizzObjectiveFrame:SetScale(val)
	end

	BlizzObjectiveFrame:SetClampedToScreen(false)
	BlizzObjectiveFrame:ClearAllPoints()
	BlizzObjectiveFrame:SetPoint('TOP', holder, 'TOP')
	BlizzObjectiveFrame:SetMovable(true)
	BlizzObjectiveFrame:SetUserPlaced(true)

	MoveIt:CreateMover(holder, 'ObjectiveTracker', 'Objective Tracker', nil, 'Blizzard UI')
	UpdateSize()
end

local HideFrame = function()
	if SUI.DB.DisabledComponents.Objectives or module.Override then
		return
	end
	if _G[frameName]:GetAlpha() == 0 and _G[frameName].HeaderMenu then
		_G[frameName].HeaderMenu.MinimizeButton:Hide()
	end
end

local ObjTrackerUpdate = function()
	if SUI.DB.DisabledComponents.Objectives or module.Override then
		return
	end
	local FadeIn = true -- Default to display incase user changes to disabled while hidden
	local FadeOut = false

	--Figure out if we need to hide objectives
	for _, v in ipairs(RuleList) do
		if module.DB[v].Status ~= 'Disabled' then
			local CombatRule = false
			if InCombatLockdown() and module.DB[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not module.DB[v].Combat then
				CombatRule = true
			end

			if module.DB[v].Status == 'Group' and (IsInGroup() and not IsInRaid()) and CombatRule then
				FadeOut = true
			elseif module.DB[v].Status == 'Raid' and IsInRaid() and CombatRule then
				FadeOut = true
			elseif module.DB[v].Status == 'Boss' and event == 'ENCOUNTER_START' then
				FadeOut = true
			elseif module.DB[v].Status == 'Instance' and IsInInstance() then
				FadeOut = true
			elseif module.DB[v].Status == 'All' and CombatRule then
				FadeOut = true
			else
				FadeIn = true
			end
		end
	end

	--Scenario Detection
	local ScenarioActive = false
	if ScenarioBlocksFrame and ScenarioBlocksFrame:IsVisible() then
		ScenarioActive = true
	end

	-- Always Shown logic
	if (module.DB.AlwaysShowScenario and ScenarioActive) then
		FadeIn = true
		FadeOut = false
	end

	if FadeOut and _G[frameName]:GetAlpha() == 1 then
		_G[frameName].FadeOut:Play()
		C_Timer.After(1, HideFrame)
	elseif FadeIn and _G[frameName]:GetAlpha() == 0 and not FadeOut then
		if _G[frameName].HeaderMenu then
			_G[frameName].HeaderMenu.MinimizeButton:Show()
		end
		_G[frameName].FadeOut:Stop()
		_G[frameName].FadeIn:Play()
	end
end

local function Options()
	SUI.opt.args.ModSetting.args.Objectives = {
		type = 'group',
		name = L.Objectives,
		args = {
			AlwaysShowScenario = {
				name = L['Always show in a scenario'],
				type = 'toggle',
				order = 0,
				width = 'full',
				get = function(info)
					return module.DB.AlwaysShowScenario
				end,
				set = function(info, val)
					module.DB.AlwaysShowScenario = val
					ObjTrackerUpdate()
				end
			},
			height = {
				name = L['Height'],
				type = 'range',
				min = 20,
				max = 1000,
				step = 1,
				order = .1,
				width = 'full',
				get = function(info)
					return module.DB.height
				end,
				set = function(info, val)
					module.DB.height = val
					UpdateSize()
				end
			}
		}
	}
	for k, v in ipairs(RuleList) do
		SUI.opt.args.ModSetting.args.Objectives.args[v] = {
			name = v,
			type = 'group',
			inline = true,
			order = k + 5.2,
			get = function(info)
				return module.DB[v][info[#info]]
			end,
			set = function(info, val)
				module.DB[v][info[#info]] = val
				ObjTrackerUpdate()
			end,
			args = {
				Status = {
					name = L['When to hide'],
					type = 'select',
					order = 1,
					values = Conditions
				},
				Combat = {
					name = L['Only if in combat'],
					type = 'toggle',
					order = 2
				}
			}
		}
	end
end

function module:OnInitialize()
	local defaults = {
		profile = {
			SetupDone = false,
			AlwaysShowScenario = true,
			height = 480,
			Rule1 = {
				Status = 'Raid',
				Combat = false
			},
			Rule2 = {
				Status = 'Disabled',
				Combat = false
			},
			Rule3 = {
				Status = 'Disabled',
				Combat = false
			}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Objectives', defaults)
	module.DB = module.Database.profile

	--Migrate old settings
	if SUI.DB.Objectives then
		module.DB = SUI:MergeData(module.DB, SUI.DB.Objectives, true)
		SUI.DB.Objectives = nil
	end

	-- Is the player is on classic disable the module
	if SUI.IsClassic then
		module.Override = true
	end
	MoveIt = SUI:GetModule('Component_MoveIt')
end

function module:OnEnable()
	module:FirstTimeSetup()

	if SUI:IsModuleDisabled('Objectives') or module.Override then
		return
	end

	-- Add Fade in and out
	if SUI.IsClassic or SUI.IsBCC then
		frameName = 'QuestWatchFrame'
	end

	_G[frameName].FadeIn = _G[frameName]:CreateAnimationGroup()
	local FadeIn = _G[frameName].FadeIn:CreateAnimation('Alpha')
	FadeIn:SetOrder(1)
	FadeIn:SetDuration(0.2)
	FadeIn:SetFromAlpha(0)
	FadeIn:SetToAlpha(1)
	_G[frameName].FadeIn:SetToFinalAlpha(true)

	_G[frameName].FadeOut = _G[frameName]:CreateAnimationGroup()
	local FadeOut = _G[frameName].FadeOut:CreateAnimation('Alpha')
	FadeOut:SetOrder(1)
	FadeOut:SetDuration(0.3)
	FadeOut:SetFromAlpha(1)
	FadeOut:SetToAlpha(0)
	FadeOut:SetStartDelay(.5)
	_G[frameName].FadeOut:SetToFinalAlpha(true)

	--Event Manager
	ObjectiveTrackerWatcher:SetScript('OnEvent', ObjTrackerUpdate)

	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED')
	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED_INDOORS')
	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	ObjectiveTrackerWatcher:RegisterEvent('PLAYER_REGEN_DISABLED')
	ObjectiveTrackerWatcher:RegisterEvent('PLAYER_REGEN_ENABLED')
	ObjectiveTrackerWatcher:RegisterEvent('COMBAT_LOG_EVENT')
	ObjectiveTrackerWatcher:RegisterEvent('GROUP_JOINED')
	ObjectiveTrackerWatcher:RegisterEvent('GROUP_ROSTER_UPDATE')
	ObjectiveTrackerWatcher:RegisterEvent('RAID_INSTANCE_WELCOME')
	ObjectiveTrackerWatcher:RegisterEvent('ENCOUNTER_START')
	ObjectiveTrackerWatcher:RegisterEvent('ENCOUNTER_END')

	if SUI.IsRetail then
		--Scenarios
		ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_COMPLETED')
		ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
		ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_UPDATE')
	end

	ObjTrackerUpdate()
	Options()
	MakeMoveable()
end

function module:OnDisable()
	-- Make sure everything is visible
	if _G[frameName].HeaderMenu then
		_G[frameName].HeaderMenu.MinimizeButton:Show()
	end
	_G[frameName].FadeOut:Stop()
	_G[frameName].FadeIn:Play()
end

local DummyFunction = function()
end

function module:update()
	if SUI.DB.DisabledComponents.Objectives or module.Override then
		return
	end

	UpdateSize()
	ObjTrackerUpdate()
end

function module:FirstTimeSetup()
	local PageData = {
		ID = 'Objectives',
		name = L['Objectives'],
		SubTitle = 'Objectives',
		Desc1 = 'The objectives module can hide the objectives based on diffrent conditions. This allows you to free your screen when you need it the most automatically.',
		Desc2 = 'The defaults here are based on your current level.',
		RequireDisplay = (not module.DB.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			local gui = LibStub('AceGUI-3.0')

			--Container
			SUI_Win.Objectives = CreateFrame('Frame', nil)
			SUI_Win.Objectives:SetParent(SUI_Win)
			SUI_Win.Objectives:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('Objectives') or module.Override then
				SUI_Win.Objectives.lblDisabled = StdUi:Label(SUI_Win.Objectives, 'Disabled', 20)
				SUI_Win.Objectives.lblDisabled:SetPoint('CENTER', SUI_Win.Objectives)
			else
				--scenario
				local line = gui:Create('Heading')
				line:SetText(L['Global'])
				line:SetPoint('TOP', SUI_Win.Objectives, 'TOP', 0, 0)
				line:SetPoint('LEFT', SUI_Win.Objectives, 'LEFT')
				line:SetPoint('RIGHT', SUI_Win.Objectives, 'RIGHT')
				line.frame:SetParent(SUI_Win.Objectives)
				line.frame:Show()
				SUI_Win.Objectives.GlobalLine = line

				local AlwaysShowScenario = gui:Create('CheckBox')
				AlwaysShowScenario:SetLabel(L['Always show in a scenario'])
				AlwaysShowScenario:SetPoint('TOP', SUI_Win.Objectives, 'TOP', 0, -15)
				AlwaysShowScenario.frame:SetParent(SUI_Win.Objectives)
				AlwaysShowScenario.frame:Show()
				AlwaysShowScenario:SetValue(true)
				SUI_Win.Objectives.AlwaysShowScenario = AlwaysShowScenario

				for k, _ in ipairs(RuleList) do
					SUI_Win.Objectives[k] = {}
					--Rule 1
					line = gui:Create('Heading')
					line:SetText(L['Rule'] .. k)
					if k == 1 then
						line:SetPoint('TOP', SUI_Win.Objectives.AlwaysShowScenario.frame, 'TOP', 0, -30)
					else
						line:SetPoint('TOP', SUI_Win.Objectives[(k - 1)].InCombat, 'BOTTOM', 0, -5)
					end
					line:SetPoint('LEFT', SUI_Win.Objectives, 'LEFT')
					line:SetPoint('RIGHT', SUI_Win.Objectives, 'RIGHT')
					line.frame:SetParent(SUI_Win.Objectives)
					line.frame:Show()
					SUI_Win.Objectives[k].line = line

					--Condition
					local control = gui:Create('Dropdown')
					control:SetLabel('When to hide')
					control:SetList(Conditions)
					control:SetValue('Disabled')
					control:SetPoint('TOP', SUI_Win.Objectives[k].line.frame, 'BOTTOM', -55, 0)
					control.frame:SetParent(SUI_Win.Objectives)
					control.frame:Show()
					SUI_Win.Objectives[k].Condition = control

					--InCombat 1
					SUI_Win.Objectives[k].InCombat =
						CreateFrame('CheckButton', 'SUI_Objectives_InCombat_' .. k, SUI_Win.Objectives, 'OptionsCheckButtonTemplate')
					SUI_Win.Objectives[k].InCombat:SetPoint('LEFT', SUI_Win.Objectives[k].Condition.frame, 'RIGHT', 20, -7)
					_G['SUI_Objectives_InCombat_' .. k .. 'Text']:SetText(L['Only if in combat'])
					SUI_Win.Objectives[k].InCombat:SetScript('OnClick', DummyFunction)
				end

				--Defaults
				SUI_Win.Objectives[1].Condition:SetValue('Raid')

				if UnitLevel('player') == 110 then
					SUI_Objectives_InCombat_1:SetChecked(true)
					SUI_Win.Objectives[2].Condition:SetValue('Instance')
				end
			end
		end,
		Next = function()
			module.DB.SetupDone = true

			if SUI:IsModuleEnabled('Objectives') then
				local SUI_Win = SUI:GetModule('SetupWizard').window.content
				module.DB.AlwaysShowScenario = SUI_Win.Objectives.AlwaysShowScenario:GetValue()

				for k, v in ipairs(RuleList) do
					module.DB[v] = {
						Status = SUI_Win.Objectives[k].Condition:GetValue(),
						Combat = (SUI_Win.Objectives[k].InCombat:GetChecked() == true or false)
					}
				end
			end
		end
	}
	SUI:GetModule('SetupWizard'):AddPage(PageData)
end
