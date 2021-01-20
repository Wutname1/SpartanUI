local SUI, L = SUI, SUI.L
local module = SUI:NewModule('Style_Arcane')
module.Settings = {}
local Artwork_Core = SUI:GetModule('Component_Artwork')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Arcane', SpartanUI)
----------------------------------------------------------------------------------------------------
local function SetupMenus()
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = .5,
				get = function(info)
					if not SUI.DB.Styles.Arcane.Color.Art then
						return {1, 1, 1, 1}
					end
					return unpack(SUI.DB.Styles.Arcane.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Arcane.Color.Art = {r, b, g, a}
					module:SetColor()
				end
			},
			ColorEnabled = {
				name = L['Color enabled'],
				type = 'toggle',
				order = .6,
				get = function(info)
					if SUI.DB.Styles.Arcane.Color.Art then
						return true
					else
						return false
					end
				end,
				set = function(info, val)
					if val then
						SUI.DB.Styles.Arcane.Color.Art = {1, 1, 1, 1}
						module:SetColor()
					else
						SUI.DB.Styles.Arcane.Color.Art = false
						module:SetColor()
					end
				end
			}
		}
	}
end

function module:OnInitialize()
	-- Bartender 4 Settings
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Arcane = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,707,193'
	}

	-- Unitframes Settings
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.ArcaneRed = {
		name = 'Arcane red',
		top = {
			heightScale = .225,
			yScale = -.09,
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.533203125, 1, 0, 0.19921875}
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.533203125, 1, 0.46484375, 0.75}
		},
		bottom = {
			heightScale = .075,
			-- yScale = 0.0223,
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0.533203125, 1, 0.374, 0.403}
		}
	}
	UnitFrames.Artwork.Arcane = {
		name = 'Arcane blue',
		top = {
			heightScale = .225,
			yScale = -.09,
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0, 0.458984375, 0, 0.19921875}
		},
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0, 0.458984375, 0.46484375, 0.75}
		},
		bottom = {
			heightScale = .075,
			-- yScale = 0,
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
			TexCoord = {0, 0.458984375, 0.374, 0.403}
		}
	}

	module:CreateArtwork()
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Arcane') then
		module:Disable()
	else
		hooksecurefunc(
			'UIParent_ManageFramePositions',
			function()
				if TutorialFrameAlertButton then
					TutorialFrameAlertButton:SetParent(Minimap)
					TutorialFrameAlertButton:ClearAllPoints()
					TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
				end
				CastingBarFrame:ClearAllPoints()
				CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Arcane, 'TOP', 0, 90)
			end
		)

		if SUI.DB.Styles.Arcane.Color.Art then
			module:SetColor()
		end
		SetupMenus()
		module:SetupVehicleUI()
	end
end

function module:OnDisable()
	SUI_Art_Arcane:Hide()
	UnregisterStateDriver(SUI_Art_Arcane, 'visibility')
end

function module:SetColor()
	local r, b, g, a = 1, 1, 1, 1
	if SUI.DB.Styles.Arcane.Color.Art then
		r, b, g, a = unpack(SUI.DB.Styles.Arcane.Color.Art)
	end

	SUI_Art_Arcane.Left:SetVertexColor(r, b, g, a)
	SUI_Art_Arcane.Right:SetVertexColor(r, b, g, a)

	if _G['SUI_StatusBar_Left'] then
		_G['SUI_StatusBar_Left'].bg:SetVertexColor(r, b, g, a)
		_G['SUI_StatusBar_Left'].overlay:SetVertexColor(r, b, g, a)
	end
	if _G['SUI_StatusBar_Right'] then
		_G['SUI_StatusBar_Right'].bg:SetVertexColor(r, b, g, a)
		_G['SUI_StatusBar_Right'].overlay:SetVertexColor(r, b, g, a)
	end
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Arcane, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Arcane, 'visibility')
	end
end

function module:CreateArtwork()
	if Arcane_ActionBarPlate then
		return
	end

	local BarBGSettings = {
		name = 'Arcane',
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Barbg',
		TexCoord = {0.07421875, 0.92578125, 0.359375, 0.6796875},
		alpha = .5
	}

	local plate = CreateFrame('Frame', 'Arcane_ActionBarPlate', SUI_Art_Arcane)
	plate:SetSize(1002, 139)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetAllPoints(SUI_BottomAnchor)

	for i = 1, 4 do
		plate['BG' .. i] = Artwork_Core:CreateBarBG(BarBGSettings, i, Arcane_ActionBarPlate)
		if UnitFactionGroup('PLAYER') == 'Horde' then
			_G['Arcane_Bar' .. i .. 'BG']:SetVertexColor(1, 0, 0, .25)
		else
			_G['Arcane_Bar' .. i .. 'BG']:SetVertexColor(0, 0, 1, .25)
		end
	end
	plate.BG1:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -110, 70)
	plate.BG2:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -110, 25)
	plate.BG3:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 110, 70)
	plate.BG4:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 110, 25)

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', SpartanUI, 'TOPLEFT', 10, -10)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetSize(2, 2)
	artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_Arcane_Left', 'BORDER')
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Art_Left')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_Arcane_Right', 'BORDER')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Art_Right')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetScale(.75)
end
