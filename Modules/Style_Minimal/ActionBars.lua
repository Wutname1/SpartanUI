local SUI = SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
local module = SUI:GetModule('Style_Minimal')
----------------------------------------------------------------------------------------------------

function module:SetupProfile()
	Artwork_Core:SetupProfile()
end

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

function module:EnableActionBars()
	module:SlidingTrays()
end


function module:SlidingTrays()
	local Settings = {
		bg = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\base-center-top',
			TexCoord = {.076171875, 0.92578125, 0, 0.18359375}
		},
		bgCollapsed = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\base-center-top',
			TexCoord = {0.076171875, 0.92578125, 1, 0.92578125}
		},
		UpTex = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\base-center-top',
			TexCoord = {0.3671875, 0.640625, 0.20703125, 0.25390625}
		},
		DownTex = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_Minimal\\Images\\base-center-top',
			TexCoord = {0.3671875, 0.640625, 0.25390625, 0.20703125}
		}
	}

	module.Trays = Artwork_Core:SlidingTrays(Settings)
end