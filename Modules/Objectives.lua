local _G, SUI, L = _G, SUI, SUI.L
if SUI.IsRetail then return end
local module = SUI:NewModule('Objectives') ---@type SUI.Module
module.description = 'Allows the hiding of the Objectives tracker based on conditions'
----------------------------------------------------------------------------------------------------
local MoveIt
local ObjectiveTrackerWatcher = CreateFrame('Frame')
local holder = CreateFrame('Frame', 'ObjectiveTrackerHolder', UIParent)
local frameName = 'WatchFrame'
local RuleList = { 'Rule1', 'Rule2', 'Rule3' }
local Conditions = {
	['Group'] = L['In a Group'],
	['Raid'] = L['In a Raid Group'],
	['Boss'] = L['Boss Fight'],
	['Instance'] = L['In a instance'],
	['All'] = L['All the time'],
	['Disabled'] = L['Disabled'],
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
	if BlizzObjectiveFrame then
		local point, anchor, secondaryPoint, x, y = strsplit(',', SUI.DB.Styles[SUI.DB.Artwork.Style].BlizzMovers.ObjectiveTracker)
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
end

function module:OnInitialize()
	---@class SUI.Objectives.DB
	local defaults = {
		SetupDone = false,
		AlwaysShowScenario = true,
		height = 480,
		Sections = {
			['**'] = {
				Rules = {
					['**'] = {
						Display = 'collapsed',
						Combat = true,
					},
				},
			},
			ObjectiveTrackerFrame = {
				Rules = {
					['1'] = {
						Combat = true,
						ScenarioObjectiveTracker = false,
						AchievementObjectiveTracker = false,
					},
				},
			},
			ScenarioObjectiveTracker = {},
			QuestObjectiveTracker = {},
			AchievementObjectiveTracker = {},
		},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Objectives', { profile = defaults })
	module.DB = module.Database.profile

	--Migrate old settings
	if SUI.DB.Objectives then
		module.DB = SUI:MergeData(module.DB, SUI.DB.Objectives, true)
		SUI.DB.Objectives = nil
	end

	-- Is the player is on classic disable the module
	if SUI.IsClassic then module.Override = true end
	MoveIt = SUI:GetModule('MoveIt')
	if SUI.IsClassic or SUI.IsTBC and _G['QuestWatchFrame'] then frameName = 'QuestWatchFrame' end
end

function module:OnEnable()
	module:FirstTimeSetup()

	if SUI:IsModuleDisabled('Objectives') or module.Override then return end

	--Event Manager
	-- ObjectiveTrackerWatcher:SetScript('OnEvent', ObjTrackerUpdate)

	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED')
	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED_INDOORS')
	ObjectiveTrackerWatcher:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	ObjectiveTrackerWatcher:RegisterEvent('PLAYER_REGEN_DISABLED')
	ObjectiveTrackerWatcher:RegisterEvent('PLAYER_REGEN_ENABLED')
	ObjectiveTrackerWatcher:RegisterEvent('GROUP_JOINED')
	ObjectiveTrackerWatcher:RegisterEvent('GROUP_ROSTER_UPDATE')
	ObjectiveTrackerWatcher:RegisterEvent('RAID_INSTANCE_WELCOME')
	ObjectiveTrackerWatcher:RegisterEvent('ENCOUNTER_START')
	ObjectiveTrackerWatcher:RegisterEvent('ENCOUNTER_END')
	--Scenarios
	ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_COMPLETED')
	ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
	ObjectiveTrackerWatcher:RegisterEvent('SCENARIO_UPDATE')

	MakeMoveable()
end

function module:OnDisable()
	-- Make sure everything is visible
	if _G[frameName].HeaderMenu then _G[frameName].HeaderMenu.MinimizeButton:Show() end
	_G[frameName].FadeOut:Stop()
	_G[frameName].FadeIn:Play()
end

function module:FirstTimeSetup()
	local PageData = {
		ID = 'Objectives',
		name = L['Objectives'],
		SubTitle = 'Objectives',
		Desc1 = 'The objectives module can hide the objectives based on diffrent conditions. This allows you to free your screen when you need it the most automatically.',
		Desc2 = 'The defaults here are based on your current level.',
		RequireDisplay = (not module.DB.SetupDone) and (SUI:IsModuleEnabled(module) or not module.Override),
		Display = function()
			local SUI_Win = SUI.Setup.window.content
			local StdUi = SUI.StdUi
			local gui = LibStub('AceGUI-3.0')

			--Container
			SUI_Win.Objectives = CreateFrame('Frame', nil)
			SUI_Win.Objectives:SetParent(SUI_Win)
			SUI_Win.Objectives:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('Objectives') or module.Override then
				SUI_Win.Objectives.lblDisabled = StdUi:Label(SUI_Win.Objectives, 'Disabled', 20)
				SUI_Win.Objectives.lblDisabled:SetPoint('CENTER', SUI_Win.Objectives)
				SUI.Setup.window.Next:Click()
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
					SUI_Win.Objectives[k].InCombat = CreateFrame('CheckButton', 'SUI_Objectives_InCombat_' .. k, SUI_Win.Objectives, 'OptionsCheckButtonTemplate')
					SUI_Win.Objectives[k].InCombat:SetPoint('LEFT', SUI_Win.Objectives[k].Condition.frame, 'RIGHT', 20, -7)
					_G['SUI_Objectives_InCombat_' .. k .. 'Text']:SetText(L['Only if in combat'])
					SUI_Win.Objectives[k].InCombat:SetScript('OnClick', DummyFunction)
				end

				--Defaults
				SUI_Win.Objectives[1].Condition:SetValue('Raid')

				if UnitLevel('player') == 110 then
					SUI_Win.Objectives[1].InCombat:SetChecked(true)
					SUI_Win.Objectives[2].Condition:SetValue('Instance')
				end
			end
		end,
		Next = function()
			module.DB.SetupDone = true

			if not (SUI:IsModuleDisabled('Objectives') or module.Override) then
				local SUI_Win = SUI.Setup.window.content
				module.DB.AlwaysShowScenario = SUI_Win.Objectives.AlwaysShowScenario:GetValue()

				for k, v in ipairs(RuleList) do
					module.DB[v] = {
						Status = SUI_Win.Objectives[k].Condition:GetValue(),
						Combat = (SUI_Win.Objectives[k].InCombat:GetChecked() == true or false),
					}
				end
			end
		end,
	}
	SUI.Setup:AddPage(PageData)
end
