local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Component_Objectives')
----------------------------------------------------------------------------------------------------
local ObjectiveTrackerWatcher = CreateFrame('Frame')
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

local HideFrame = function()
	if not SUI.DB.EnabledComponents.Objectives or module.Override then
		return
	end
	if _G[frameName]:GetAlpha() == 0 and _G[frameName].HeaderMenu then
		_G[frameName].HeaderMenu.MinimizeButton:Hide()
	end
end

local ObjTrackerUpdate = function()
	if not SUI.DB.EnabledComponents.Objectives or module.Override then
		return
	end
	local FadeIn = true -- Default to display incase user changes to disabled while hidden
	local FadeOut = false

	--Figure out if we need to hide objectives
	for _, v in ipairs(RuleList) do
		if SUI.DBMod.Objectives[v].Status ~= 'Disabled' then
			local CombatRule = false
			if InCombatLockdown() and SUI.DBMod.Objectives[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not SUI.DBMod.Objectives[v].Combat then
				CombatRule = true
			end

			if SUI.DBMod.Objectives[v].Status == 'Group' and (IsInGroup() and not IsInRaid()) and CombatRule then
				FadeOut = true
			elseif SUI.DBMod.Objectives[v].Status == 'Raid' and IsInRaid() and CombatRule then
				FadeOut = true
			elseif SUI.DBMod.Objectives[v].Status == 'Boss' and event == 'ENCOUNTER_START' then
				FadeOut = true
			elseif SUI.DBMod.Objectives[v].Status == 'Instance' and IsInInstance() then
				FadeOut = true
			elseif SUI.DBMod.Objectives[v].Status == 'All' and CombatRule then
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
	if (SUI.DBMod.Objectives.AlwaysShowScenario and ScenarioActive) then
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

function module:OnInitialize()
	local Defaults = {
		SetupDone = false,
		AlwaysShowScenario = true,
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
	if not SUI.DBMod.Objectives then
		SUI.DBMod.Objectives = Defaults
	else
		SUI.DBMod.Objectives = SUI:MergeData(SUI.DBMod.Objectives, Defaults, false)
	end
	if SUI.DBMod.Artwork.SetupDone then
		SUI.DBMod.Objectives.SetupDone = true
	end
	-- Is the player is on classic disable the module
	if SUI.IsClassic then
		module.Override = true
	end
end

function module:OnEnable()
	if not SUI.DB.EnabledComponents.Objectives or module.Override then
		return
	end

	module:FirstTimeSetup()

	-- Add Fade in and out
	if SUI.IsClassic then
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
	module:BuildOptions()
end

function module:OnDisable()
	-- Make sure everything is visible
	if _G[frameName].HeaderMenu then
		_G[frameName].HeaderMenu.MinimizeButton:Show()
	end
	_G[frameName].FadeOut:Stop()
	_G[frameName].FadeIn:Play()
end

function module:BuildOptions()
	SUI.opt.args['ModSetting'].args['Objectives'] = {
		type = 'group',
		name = L['Objectives'],
		args = {
			AlwaysShowScenario = {
				name = L['Always show in a scenario'],
				type = 'toggle',
				order = 0,
				width = 'full',
				get = function(info)
					return SUI.DBMod.Objectives.AlwaysShowScenario
				end,
				set = function(info, val)
					SUI.DBMod.Objectives.AlwaysShowScenario = val
					ObjTrackerUpdate()
				end
			}
		}
	}
	for k, v in ipairs(RuleList) do
		SUI.opt.args['ModSetting'].args['Objectives'].args[v .. 'Title'] = {
			name = v,
			type = 'header',
			order = k,
			width = 'full'
		}
		SUI.opt.args['ModSetting'].args['Objectives'].args[v .. 'Status'] = {
			name = 'When to hide',
			type = 'select',
			order = k + .2,
			values = Conditions,
			get = function(info)
				return SUI.DBMod.Objectives[v].Status
			end,
			set = function(info, val)
				SUI.DBMod.Objectives[v].Status = val
				ObjTrackerUpdate()
			end
		}
		SUI.opt.args['ModSetting'].args['Objectives'].args[v .. 'Text'] = {
			name = '',
			type = 'description',
			order = k + .3,
			width = 'half'
		}
		SUI.opt.args['ModSetting'].args['Objectives'].args[v .. 'Combat'] = {
			name = L['Only if in combat'],
			type = 'toggle',
			order = k + .4,
			get = function(info)
				return SUI.DBMod.Objectives[v].Combat
			end,
			set = function(info, val)
				SUI.DBMod.Objectives[v].Combat = val
				ObjTrackerUpdate()
			end
		}
	end
end

function module:HideOptions()
	SUI.opt.args['ModSetting'].args['Objectives'].disabled = true
end

local DummyFunction = function()
end

function module:FirstTimeSetup()
	local PageData = {
		ID = 'Objectives',
		Name = 'Objectives',
		SubTitle = 'Objectives',
		Desc1 = 'The objectives module can hide the objectives based on diffrent conditions. This allows you to free your screen when you need it the most automatically.',
		Desc2 = 'The defaults here are based on your current level.',
		RequireDisplay = (not SUI.DBMod.Objectives.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			local gui = LibStub('AceGUI-3.0')
			if not SUI.DB.EnabledComponents.Objectives or module.Override then
				window.Skip:Click()
				return
			end

			--Container
			SUI_Win.Objectives = CreateFrame('Frame', nil)
			SUI_Win.Objectives:SetParent(SUI_Win)
			SUI_Win.Objectives:SetAllPoints(SUI_Win)

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
		end,
		Next = function()
			local SUI_Win = SUI:GetModule('SetupWizard').window.content
			SUI.DBMod.Objectives.SetupDone = true
			SUI.DBMod.Objectives.AlwaysShowScenario = SUI_Win.Objectives.AlwaysShowScenario:GetValue()

			for k, v in ipairs(RuleList) do
				SUI.DBMod.Objectives[v] = {
					Status = SUI_Win.Objectives[k].Condition:GetValue(),
					Combat = (SUI_Win.Objectives[k].InCombat:GetChecked() == true or false)
				}
			end
		end,
		Skip = function()
			SUI.DB.Objectives.SetupDone = false
		end
	}
	SUI:GetModule('SetupWizard'):AddPage(PageData)
end
