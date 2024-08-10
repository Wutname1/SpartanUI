local SUI = SUI
local L = SUI.L
local module = SUI.Handlers.BarSystem

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
	-- MainMenuBar.hasActiveChanges = true
	-- MainMenuBar.systemInfo.settings[Enum.EditModeActionBarSetting.HideBarArt].value = 1
	-- MainMenuBar:UpdateSystemSetting(Enum.EditModeActionBarSetting.HideBarArt)
	-- EditModeManagerFrame.hasActiveChanges = true
	-- EditModeManagerFrame:SaveLayouts()
end

local function OnEnable(args)
	if StatusTrackingBarManager then StatusTrackingBarManager:Hide() end

	local settings = {
		['MainMenuBar'] = {
			settings = {
				[Enum.EditModeActionBarSetting.HideBarArt] = 1,
				[Enum.EditModeActionBarSetting.HideBarScrolling] = 1,
				-- [Enum.EditModeActionBarSetting.IconSize] = 2
			},
			anchorInfo = 'BOTTOM,UIParent,BOTTOM,-364,78',
		},
		['MultiBarRight'] = {
			settings = {
				[Enum.EditModeActionBarSetting.Orientation] = Enum.ActionBarOrientation.Horizontal,
			},
			anchorInfo = 'BOTTOM,UIParent,BOTTOM,364,78',
		},
		['MultiBarBottomRight'] = {
			settings = {
				[Enum.EditModeActionBarSetting.NumRows] = 3,
			},
			anchorInfo = 'BOTTOM,UIParent,BOTTOM,-550,20',
		},
		['MultiBarBottomLeft'] = {
			settings = {
				[Enum.EditModeActionBarSetting.NumRows] = 3,
			},
			anchorInfo = 'BOTTOM,UIParent,BOTTOM,550,20',
		},
		['MultiBarLeft'] = {
			settings = {
				[Enum.EditModeActionBarSetting.Orientation] = Enum.ActionBarOrientation.Horizontal,
			},
			anchorInfo = 'BOTTOM,UIParent,BOTTOM,366,24',
		},
	}
	-- for bar, values in pairs(settings) do
	-- 	local barObj = _G[bar]
	-- 	print(barObj:GetName())
	-- 	-- barObj.hasActiveChanges = true
	-- 	if values.anchorInfo then
	-- 		barObj:ClearAllPoints()
	-- 		local point, anchor, secondaryPoint, x, y = strsplit(',', values.anchorInfo)
	-- 		barObj:SetPoint(point, anchor, secondaryPoint, x, y)
	-- 	end
	-- 	EditModeManagerFrame:OnSystemPositionChange(barObj, false)

	-- 	for setting, value in pairs(values.settings or {}) do
	-- 		print(setting)
	-- 		EditModeManagerFrame:OnSystemSettingChange(barObj, setting, value)
	-- 	end
	-- end

	-- EditModeManagerFrame.hasActiveChanges = true
	-- EditModeManagerFrame:SaveLayouts()

	module:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
end

function module:EDIT_MODE_LAYOUTS_UPDATED()
	--TODO: Prompt to apply SUI defaults
end

local function RefreshConfig(args) end

module:AddBarSystem('WoW', OnInitialize, OnEnable, nil, nil, RefreshConfig)
