local SUI, L = SUI, SUI.L
local print, error = SUI.print, SUI.Error
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_War')
module.Settings = {}
module.Trays = {}
module.StatusBarSettings = {
	bars = {
		'StatusBar_Left',
		'StatusBar_Right'
	},
	StatusBar_Left = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = -16},
		MaxWidth = 48
	},
	StatusBar_Right = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		Grow = 'RIGHT',
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = 16},
		MaxWidth = 48
	}
}
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	-- Bartender 4 Settings
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.War = {
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_ActionBarAnchor,TOP,0,70',
		--
		['BT4BarStanceBar'] = 'TOP,SpartanUI,TOP,-309,0',
		['BT4BarPetBar'] = 'TOP,SpartanUI,TOP,-558,0',
		--
		['BT4BarMicroMenu'] = 'TOP,SpartanUI,TOP,369,0',
		['BT4BarBagBar'] = 'TOP,SpartanUI,TOP,680,0'
	}

	-- Unitframes Settings
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	local Images = {
		Alliance = {
			bg = {
				Coords = {0, 0.458984375, 0.74609375, 1}
			},
			top = {
				Coords = {0.03125, 0.427734375, 0, 0.421875}
			},
			bottom = {
				Coords = {0.541015625, 1, 0, 0.421875}
			}
		},
		Horde = {
			bg = {
				Coords = {0.572265625, 0.96875, 0.74609375, 1}
			},
			top = {
				Coords = {0.541015625, 1, 0, 0.421875}
			},
			bottom = {
				Coords = {0.541015625, 1, 0, 0.421875}
			}
		}
	}
	local pathFunc = function(frame, position)
		local factionGroup = UnitFactionGroup(frame.unit) or 'Neutral'
		if factionGroup == 'Horde' or factionGroup == 'Alliance' then
			return 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames'
		end
		if position == 'bg' then
			return 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
		end

		return false
	end
	local TexCoordFunc = function(frame, position)
		local factionGroup = UnitFactionGroup(frame.unit) or 'Neutral'

		if factionGroup == 'Horde' then
			-- Horde Graphics
			if position == 'top' then
				return {0.541015625, 1, 0, 0.1796875}
			elseif position == 'bg' then
				return {0.572265625, 0.96875, 0.74609375, 1}
			elseif position == 'bottom' then
				return {0.541015625, 1, 0.37109375, 0.421875}
			end
		elseif factionGroup == 'Alliance' then
			-- Alliance Graphics
			if position == 'top' then
				return {0.03125, 0.458984375, 0, 0.1796875}
			elseif position == 'bg' then
				return {0, 0.458984375, 0.74609375, 1}
			elseif position == 'bottom' then
				return {0.03125, 0.458984375, 0.37109375, 0.421875}
			end
		else
			return {1, 1, 1, 1}
		end
	end
	UnitFrames.Artwork.war = {
		name = 'War',
		top = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			heightScale = .225,
			yScale = -.0555,
			PVPAlpha = .6
		},
		bg = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			PVPAlpha = .7
		},
		bottom = {
			path = pathFunc,
			TexCoord = TexCoordFunc,
			heightScale = .0825,
			yScale = 0.0223,
			PVPAlpha = .7
			-- height = 40,
			-- y = 40,
			-- alpha = 1,
			-- VertexColor = {0, 0, 0, .6},
			-- position = {Pos table},
			-- scale = 1,
		}
	}
	-- Default frame posistions
	UnitFrames.FramePos['War'] = {
		['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-45,250'
	}
	module:CreateArtwork()
end

function module:OnEnable()
	if (SUI.DBMod.Artwork.Style ~= 'War') then
		module:Disable()
	else
		module:SetupMenus()
		module:EnableArtwork()
	end
end

function module:OnDisable()
	SUI_Art_War:Hide()
end
