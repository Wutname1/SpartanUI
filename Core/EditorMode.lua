local SUI = SUI
local module = SUI:NewModule('EditorMode') ---@type SUI.Module

function module:OnEnable()
	-- local SUILayout =
	-- 	"0 30 0 0 1 7 7 UIParent 0.0 45.0 -1 ##$$%/&('%)#+# 0 1 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$%/&('%(#,$ 0 2 1 6 0 MultiBarBottomLeft 0.0 5.0 -1 ##$$%/&('%(#,$ 0 3 1 5 5 UIParent -5.0 -77.0 -1 #$$$%/&('%(#,$ 0 4 1 2 0 MultiBarRight -5.0 0.0 -1 #$$$%/&('%(#,$ 0 5 1 1 4 UIParent 0.0 0.0 -1 ##$$%/&('%(#,$ 0 6 1 1 7 MultiBar5 0.0 0.0 -1 ##$$%/&('%(#,$ 0 7 1 1 7 MultiBar6 0.0 0.0 -1 ##$$%/&('%(#,$ 0 10 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$&('% 0 11 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$&('%,# 0 12 1 6 0 MainMenuBar 0.0 5.0 -1 ##$$&('% 1 -1 1 4 4 UIParent 0.0 0.0 -1 ##$# 2 -1 0 1 1 UIParent -24.5 -18.1 -1 ##$# 3 0 1 8 7 UIParent -300.0 250.0 -1 $#3# 3 1 1 6 7 UIParent 300.0 250.0 -1 %#3# 3 2 1 3 5 TargetFrame -10.0 0.0 -1 %#&#3# 3 3 0 3 3 UIParent 522.0 72.4 -1 '#(#)#-#.#/#1$3& 3 4 1 0 2 CompactRaidFrameManager 0.0 -5.0 -1 ,#-#.#/#0#1#2( 3 5 1 5 5 UIParent 0.0 0.0 -1 &#*$3# 3 6 1 5 5 UIParent 0.0 0.0 -1 3# 4 -1 1 7 1 MainMenuBar 0.0 5.0 -1 # 5 -1 1 6 0 MainMenuBar 0.0 5.0 -1 # 6 0 0 1 1 UIParent 920.0 -2.0 -1 ##$#%#&.(()(*# 6 1 0 1 7 BuffFrame 61.9 -4.0 -1 ##$#%#'+(()(*# 7 -1 1 6 0 MainMenuBar 0.0 5.0 -1 # 8 -1 0 3 3 UIParent 2.0 -502.5 -1 #'$A%$&7 9 -1 1 6 0 MainMenuBar 0.0 5.0 -1 # 10 -1 1 0 0 UIParent 16.0 -116.0 -1 # 11 -1 1 8 8 UIParent -9.0 85.0 -1 # 12 -1 0 5 5 UIParent -10.3 -4.4 -1 #B"
	-- local layoutInfo = C_EditMode.ConvertStringToLayoutInfo(SUILayout)
	-- SUI_Minimap.layoutInfo = layoutInfo
	-- EditModeManagerFrame.editModeActive = true
	-- EditModeManagerFrame:ClearActiveChangesFlags()
	-- EditModeManagerFrame:ImportLayout(layoutInfo, Enum.EditModeLayoutType.Account, 'SpartanUI-Default')
	-- local settings = {
	-- 	['MinimapCluster'] = {
	-- 		anchorInfo = 'TOP,UIParent,TOP,0,24'
	-- 	}
	-- }
	-- for frameName, values in pairs(settings) do
	-- 	local object = _G[frameName]
	-- 	print(object:GetName())
	-- 	object.hasActiveChanges = true
	-- 	if values.anchorInfo then
	-- 		object:ClearAllPoints()
	-- 		local point, anchor, secondaryPoint, x, y = strsplit(',', values.anchorInfo)
	-- 		object:SetPoint(point, anchor, secondaryPoint, x, y)
	-- 	end
	-- 	EditModeManagerFrame:OnSystemPositionChange(object, false)
	-- for setting, value in pairs(values.settings or {}) do
	-- 	EditModeManagerFrame:OnSystemSettingChange(barObj, setting, value)
	-- end
	-- end
	-- EditModeManagerFrame.hasActiveChanges = true
	-- EditModeManagerFrame:SaveLayouts()
end
