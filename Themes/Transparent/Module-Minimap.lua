local SUI = SUI
local module = SUI:GetModule('Style_Transparent')
---------------------------------------------------------------------------

local function Transparent_MiniMapCreate()
	Minimap:SetSize(130, 130)
	Minimap:ClearAllPoints()
	Minimap:SetPoint('CENTER', 'SUI_Art_Transparent', 'CENTER', 0, -5)

	SUI_Art_Transparent:HookScript(
		'OnHide',
		function(this, event)
			if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
				Minimap:ClearAllPoints()
				Minimap:SetParent(UIParent)
				Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			end
		end
	)

	SUI_Art_Transparent:HookScript(
		'OnShow',
		function(this, event)
			if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
				Minimap:ClearAllPoints()
				Minimap:SetPoint('CENTER', 'SUI_Art_Transparent', 'CENTER', 0, -5)
			end
		end
	)

	module.handleBuff = true
end

function module:InitMinimap()
end

function module:EnableMinimap()
	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		Transparent_MiniMapCreate()
	end
end
