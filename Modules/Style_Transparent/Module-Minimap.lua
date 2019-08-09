local SUI = SUI
local module = SUI:GetModule('Style_Transparent')
---------------------------------------------------------------------------
module.Settings = {
	MiniMap = {
		size = {
			130,
			130
		},
		TextLocation = 'TOP',
		coordsLocation = 'TOP',
		coords = {
			TextColor = {1, .82, 0, 1}
		}
	}
}

function Transparent_MiniMapCreate()
	Minimap:SetSize(130, 130)
	Minimap:ClearAllPoints()
	Minimap:SetPoint('CENTER', 'Transparent_SpartanUI', 'CENTER', 0, -5)

	Transparent_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
				Minimap:ClearAllPoints()
				Minimap:SetParent(UIParent)
				Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			end
		end
	)

	Transparent_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
				Minimap:ClearAllPoints()
				Minimap:SetPoint('CENTER', 'Transparent_SpartanUI', 'CENTER', 0, -5)
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
