local SUI = SUI
local module = SUI:NewModule('Style_Arcane')
----------------------------------------------------------------------------------------------------

function module:OnInitialize()
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.ArcaneRed = {
		name = 'Arcane red',
		top = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.541015625, 1, 0, 0.2109375}
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.572265625, 0.96875, 0.74609375, 1}
		},
		bottom = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.541015625, 1, 0.2109375, 0.421875}
		}
	}
	UnitFrames.Artwork.ArcaneBlue = {
		name = 'Arcane blue',
		top = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.03125, 0.458984375, 0, 0.2109375}
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0, 0.458984375, 0.74609375, 1}
		},
		bottom = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.03125, 0.458984375, 0.2109375, 0.421875}
		}
	}
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Arcane') then
		module:Disable()
	end
end

module.Settings = {}
