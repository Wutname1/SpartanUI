local SUI, L = SUI, SUI.L
local print = SUI.print
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Fel')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Fel', SpartanUI)
module.Settings = {}
local CurScale
----------------------------------------------------------------------------------------------------
local InitRan = false

local function Options()
	SUI.opt.args.Artwork.args.Fel = {
		name = L['Fel style'],
		type = 'group',
		order = 10,
		args = {
			MinimapEngulfed = {
				name = L['Douse the flames'],
				type = 'toggle',
				order = .1,
				desc = L['Is it getting hot in here?'],
				get = function(info)
					return not SUI.DB.Styles.Fel.Minimap.engulfed
				end,
				set = function(info, val)
					print(val)
					SUI.DB.Styles.Fel.Minimap.engulfed = not val or false
					module:MiniMap()
				end
			}
		}
	}
end

function module:OnInitialize()
	-- BarHandler
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Fel = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,707,193'
	}

	-- Unitframes
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Fel = {
		top = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			TexCoord = {0.1796875, 0.736328125, 0, 0.099609375},
			heightScale = .25,
			yScale = -0.05,
			alpha = .8
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			TexCoord = {.02, .385, .45, .575},
			PVPAlpha = .4
		},
		bottom = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\UnitFrames',
			heightScale = .115,
			yScale = 0.0158,
			TexCoord = {0.1796875, 0.736328125, 0.197265625, 0.244140625},
			PVPAlpha = .8
		}
	}

	module:CreateArtwork()
	Options()
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Fel') then
		module:Disable()
	else
		module:EnableArtwork()
	end
end

function module:OnDisable()
	artFrame:Hide()
	SUI.opt.args.Artwork.args.Fel.hidden = true
	UnregisterStateDriver(SUI_Art_Fel, 'visibility')
end

--	Module Calls
function module:BuffLoc(_, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Fel, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Fel, 'visibility')
	end
end

function module:CreateArtwork()
	local plate = CreateFrame('Frame', 'Fel_ActionBarPlate', SpartanUI, 'Fel_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:ClearAllPoints()
	plate:SetAllPoints(SUI_BottomAnchor)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetSize(2, 2)
	artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_Fel_Left', 'BORDER')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Base_Bar_Left')
	-- artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_Fel_Right', 'BORDER')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Base_Bar_Right')
	-- artFrame.Right:SetScale(.75)

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', SpartanUI, 'TOPLEFT', 10, -10)
end

function module:EnableArtwork()
	hooksecurefunc(
		'UIParent_ManageFramePositions',
		function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Fel, 'TOP', 0, 90)
		end
	)

	module:SetupVehicleUI()

	if SUI:IsModuleEnabled('Minimap') and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end
end

-- Minimap
function module:MiniMap()
	local enfulfed = {
		texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Engulfed',
		size = {220, 220},
		position = 'CENTER,Minimap,CENTER,5,23'
	}
	local calmed = {
		texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Calmed',
		size = {162, 162},
		position = 'CENTER,Minimap,CENTER,3,-1'
	}

	if SUI.DB.Styles.Fel.Minimap.engulfed then
		SUI.DB.Styles.Fel.Minimap.BG = SUI:MergeData(SUI.DB.Styles.Fel.Minimap.BG, enfulfed, true)
	else
		SUI.DB.Styles.Fel.Minimap.BG = SUI:MergeData(SUI.DB.Styles.Fel.Minimap.BG, calmed, true)
	end
	SUI:GetModule('Component_Minimap'):update(true)
end
