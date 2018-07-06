local SUI = SUI
local module = SUI:GetModule('Style_Transparent')
---------------------------------------------------------------------------
function Transparent_MiniMapCreate()
	Minimap:SetSize(130, 130)
	Minimap:ClearAllPoints()
	Minimap:SetPoint('CENTER', 'Transparent_SpartanUI', 'CENTER', 0, -5)

	Transparent_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('TOP', UIParent, 'TOP', 0, -15)
		end
	)

	Transparent_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', 'Transparent_SpartanUI', 'CENTER', 0, -5)
		end
	)

	module.handleBuff = true
end

function module:InitMinimap()
end

function module:EnableMinimap()
	if (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
		Transparent_MiniMapCreate()
	end
end
