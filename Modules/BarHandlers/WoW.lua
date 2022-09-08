local SUI = SUI
local L = SUI.L
local module = SUI:GetModule('Component_BarHandler')

------------------------------------------------------------

local function OnInitialize(args)
	-- local CUSTOM_SYSTEM_ID = 999
	-- local CustomSystem = CreateFrame('Frame', nil, UIParent)
	-- CustomSystem.system = CUSTOM_SYSTEM_ID
	-- CustomSystem.systemNameString = 'Custom AddOn System'
	-- CustomSystem:EnableMouse(true)
	-- CustomSystem:SetClampedToScreen(true)
	-- CustomSystem:SetPoint('CENTER')
	-- CustomSystem:SetSize(400, 32)
	-- CustomSystem.Selection = CreateFrame('Frame', nil, CustomSystem, 'EditModeSystemSelectionTemplate')
	-- CustomSystem.Selection:SetAllPoints(CustomSystem)
	-- Mixin(CustomSystem, EditModeSystemMixin)
	-- CustomSystem:SetScript('OnHide', CustomSystem.OnSystemHide)
	-- CustomSystem:OnSystemLoad()
	-- EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[CUSTOM_SYSTEM_ID] = {}
end

local function OnEnable(args)
	if StatusTrackingBarManager then
		StatusTrackingBarManager:Hide()
	end
end

local function Unlock(args)
end

local function RefreshConfig(args)
end

module:AddBarSystem('WoW', OnInitialize, OnEnable, nil, Unlock, RefreshConfig)
