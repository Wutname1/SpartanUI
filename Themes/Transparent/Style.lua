local SUI = SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Transparent')
local artFrame = CreateFrame('Frame', 'SUI_Art_Transparent', SpartanUI)
----------------------------------------------------------------------------------------------------
local InitRan = false

function module:OnInitialize()
	--Enable the in the Core options screen
	SUI.opt.args['General'].args['style'].args['OverallStyle'].args['Transparent'].disabled = false
	SUI.opt.args['General'].args['style'].args['Artwork'].args['Transparent'].disabled = false

	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Transparent = {
		['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-347,80',
		['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-347,25',
		['BT4Bar3'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,344,80',
		['BT4Bar4'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,344,25',
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOMLEFT,0,5',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOMRIGHT,3,5',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,186',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-581,187',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,320,183',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,611,188',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,15',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,15'
	}

	BarHandler.BarScale.BT4.Transparent = {
		['BT4Bar1'] = 0.77,
		['BT4Bar2'] = 0.77,
		['BT4Bar3'] = 0.77,
		['BT4Bar4'] = 0.77,
		['BT4Bar5'] = 0.74,
		['BT4Bar6'] = 0.74
	}

	-- Unitframes Settings
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Transparent = {
		name = 'Transparent',
		top = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base_plate1',
			TexCoord = {0.03125, 0.458984375, 0, 0.2109375}
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base_plate1',
			TexCoord = {0, 0.458984375, 0.74609375, 1}
		}
	}
	UnitFrames.FramePos.Transparent = {
		['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-123,138',
		['pet'] = 'BOTTOMRIGHT,SUI_UF_player,BOTTOMLEFT,20,0',
		['target'] = 'LEFT,SUI_UF_player,RIGHT,244,0',
		['targettarget'] = 'BOTTOMLEFT,SUI_UF_target,BOTTOMRIGHT,50,0'
	}
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Transparent') then
		module:Disable()
	else
		local plate = CreateFrame('Frame', 'Transparent_ActionBarPlate', SUI_Art_Transparent)
		plate:SetSize(1002, 139)
		plate:SetFrameStrata('BACKGROUND')
		plate:SetFrameLevel(1)
		plate:SetAllPoints(SUI_BottomAnchor)

		local BarBGSettings = {
			name = 'Transparent',
			-- width = 400,
			height = 37,
			TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\bar-backdrop1',
			TexCoord = {0.107421875, 0.896484375, 0.25, 0.765625},
			alpha = .1
		}

		local BarBGSettings2 = {
			name = 'Transparent',
			width = 140,
			height = 110,
			TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\bar-backdrop3',
			alpha = .5,
			TexCoord = {0.23828125, 0.76171875, 0.09375, 0.8828125}
		}

		for i = 1, 4 do
			plate['BG' .. i] = Artwork_Core:CreateBarBG(BarBGSettings, i, Transparent_ActionBarPlate)
		end

		plate['BG5'] = Artwork_Core:CreateBarBG(BarBGSettings2, 5, Transparent_ActionBarPlate)
		plate['BG6'] = Artwork_Core:CreateBarBG(BarBGSettings2, 6, Transparent_ActionBarPlate)

		plate.BG1:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -90, 69)
		plate.BG2:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -90, 23)

		plate.BG3:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 90, 69)
		plate.BG4:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 90, 23)

		plate.BG5:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -498, 2)
		plate.BG6:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 498, 2)

		SUI_Art_Transparent:SetFrameStrata('BACKGROUND')
		SUI_Art_Transparent:SetFrameLevel(1)

		--Setup the Bottom Artwork
		artFrame:SetFrameStrata('BACKGROUND')
		artFrame:SetFrameLevel(1)
		artFrame:SetSize(2, 2)
		artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

		artFrame.Center = artFrame:CreateTexture('SUI_Art_Transparent_Center', 'BACKGROUND')
		artFrame.Center:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base-center')
		artFrame.Center:SetPoint('BOTTOM', artFrame, 'BOTTOM')

		artFrame.Left = artFrame:CreateTexture('SUI_Art_Transparent_Left', 'BACKGROUND')
		artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base-sides')
		artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame.Center, 'BOTTOMLEFT', 0, 0)
		artFrame.FarLeft = artFrame:CreateTexture('SUI_Art_Transparent_FarLeft', 'BACKGROUND')
		artFrame.FarLeft:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base-sides')
		artFrame.FarLeft:SetPoint('BOTTOMRIGHT', artFrame.Left, 'BOTTOMLEFT', 0, 0)
		artFrame.FarLeft:SetPoint('BOTTOMLEFT', SpartanUI, 'BOTTOMLEFT', 0, 0)

		artFrame.Right = artFrame:CreateTexture('SUI_Art_Transparent_Right', 'BACKGROUND')
		artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base-sides')
		artFrame.Right:SetPoint('BOTTOMLEFT', artFrame.Center, 'BOTTOMRIGHT')
		artFrame.FarRight = artFrame:CreateTexture('SUI_Art_Transparent_FarRight', 'BACKGROUND')
		artFrame.FarRight:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Transparent\\Images\\base-sides')
		artFrame.FarRight:SetPoint('BOTTOMLEFT', artFrame.Right, 'BOTTOMRIGHT')
		artFrame.FarRight:SetPoint('BOTTOMRIGHT', SpartanUI, 'BOTTOMRIGHT')

		if SUI.DB.Artwork.VehicleUI then
			RegisterStateDriver(SUI_Art_Transparent, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
		end

		module:SetColor()
		module:SetupMenus()
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = 1,
				width = 'full',
				get = function(info)
					return unpack(SUI.DB.Styles.Transparent.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Transparent.Color.Art = {r, b, g, a}
					module:SetColor()
				end
			}
		}
	}
end

function module:OnDisable()
	UnregisterStateDriver(SUI_Art_Transparent, 'visibility')
	SUI_Art_Transparent:Hide()
end

----------------------------------------------------------------------------------------------------

function module:TooltipLoc(self, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_Transparent', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Transparent, 'visibility')
	end
end

function module:SetColor()
	local r, b, g, a = unpack(SUI.DB.Styles.Transparent.Color.Art)
	for i = 1, 6 do
		if _G['Transparent_Bar' .. i .. 'BG'] then
			_G['Transparent_Bar' .. i .. 'BG']:SetVertexColor(r, b, g)
		end
	end
	_G['SUI_Art_Transparent_Center']:SetVertexColor(r, b, g, a)
	_G['SUI_Art_Transparent_Left']:SetVertexColor(r, b, g, a)
	_G['SUI_Art_Transparent_FarLeft']:SetVertexColor(r, b, g, a)
	_G['SUI_Art_Transparent_Right']:SetVertexColor(r, b, g, a)
	_G['SUI_Art_Transparent_FarRight']:SetVertexColor(r, b, g, a)
end
