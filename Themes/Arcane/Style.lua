local SUI, L = SUI, SUI.L
---@class SUI.Theme.Arcane : SUI.Theme.StyleBase
local module = SUI:NewModule('Style.Arcane')
local unpack = unpack
module.Settings = {}
local Artwork_Core = SUI:GetModule('Artwork') ---@type SUI.Module.Artwork
local artFrame = CreateFrame('Frame', 'SUI_Art_Arcane', SpartanUI)
----------------------------------------------------------------------------------------------------
local function Options()
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = 0.5,
				get = function(info)
					if not SUI.DB.Styles.Arcane.Color.Art then return { 1, 1, 1, 1 } end
					return unpack(SUI.DB.Styles.Arcane.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Arcane.Color.Art = { r, b, g, a }
					module:SetColor()
				end,
			},
			ColorEnabled = {
				name = L['Color enabled'],
				type = 'toggle',
				order = 0.6,
				get = function(info)
					if SUI.DB.Styles.Arcane.Color.Art then
						return true
					else
						return false
					end
				end,
				set = function(info, val)
					if val then
						SUI.DB.Styles.Arcane.Color.Art = { 1, 1, 1, 1 }
						module:SetColor()
					else
						SUI.DB.Styles.Arcane.Color.Art = false
						module:SetColor()
					end
				end,
			},
		},
	}
end

function module:OnInitialize()
	-- Bartender 4 Settings
	local BarHandler = SUI.Handlers.BarSystem
	BarHandler.BarPosition.BT4.Arcane = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,175',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-607,177',
		['MultiCastActionBarFrame'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,310,151',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,661,174',
	}

	-- Unitframes Settings
	---@type SUI.Style.Settings.UnitFrames
	local RedUFSettings = {
		displayName = 'Arcane red',
		artwork = {
			top = {
				heightScale = 0.225,
				yScale = -0.09,
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0.533203125, 1, 0, 0.19921875 },
			},
			bg = {
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0.533203125, 1, 0.46484375, 0.75 },
			},
			bottom = {
				heightScale = 0.075,
				-- yScale = 0.0223,
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0.533203125, 1, 0.374, 0.403 },
			},
		},
	}
	SUI.UF.Style:Register('ArcaneRed', RedUFSettings)

	---@type SUI.Style.Settings.Minimap
	local minimapSettings = {
		size = { 156, 156 },
		position = 'CENTER,SUI_Art_Arcane_Left,RIGHT,0,20',
		elements = {
			background = {
				texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\minimap',
			},
		},
	}
	SUI.Minimap:Register('Arcane', minimapSettings)

	---@type SUI.Style.Settings.UnitFrames
	local BlueUFSettings = {
		displayName = 'Arcane blue',
		artwork = {
			top = {
				heightScale = 0.225,
				yScale = -0.09,
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0, 0.458984375, 0, 0.19921875 },
			},
			bg = {
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0, 0.458984375, 0.46484375, 0.75 },
			},
			bottom = {
				heightScale = 0.075,
				-- yScale = 0,
				path = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\UnitFrames',
				TexCoord = { 0, 0.458984375, 0.374, 0.403 },
			},
		},
	}
	SUI.UF.Style:Register('Arcane', BlueUFSettings)

	local statusBarModule = SUI:GetModule('Artwork.StatusBars') ---@type SUI.Module.Artwork.StatusBars
	---@type SUI.Style.Settings.StatusBars
	local StatusBarsSettings = {
		bgTexture = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\StatusBar',
		alpha = 0.9,
		size = { 370, 20 },
		texCords = { 0.0546875, 0.9140625, 0.5555555555555556, 0 },
		MaxWidth = 48,
	}
	statusBarModule:RegisterStyle('Arcane', { Left = SUI:CopyTable({}, StatusBarsSettings), Right = SUI:CopyTable({}, StatusBarsSettings) })

	module:CreateArtwork()
end

function module:OnEnable()
	if SUI.DB.Artwork.Style ~= 'Arcane' then
		module:Disable()
	else
		hooksecurefunc('UIParent_ManageFramePositions', function()
			if TutorialFrameAlertButton then
				TutorialFrameAlertButton:SetParent(Minimap)
				TutorialFrameAlertButton:ClearAllPoints()
				TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			end
			if CastingBarFrame then
				CastingBarFrame:ClearAllPoints()
				CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Arcane, 'TOP', 0, 90)
			end
		end)

		if SUI.DB.Styles.Arcane.Color.Art then module:SetColor() end
		Options()
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
	if SUI.DB.Artwork.VehicleUI then RegisterStateDriver(SUI_Art_Arcane, 'visibility', '[overridebar][vehicleui] hide; show') end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then UnregisterStateDriver(SUI_Art_Arcane, 'visibility') end
end

function module:CreateArtwork()
	if Arcane_ActionBarPlate then return end

	local BarBGSettings = {
		name = 'Arcane',
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Barbg',
		TexCoord = { 0.07421875, 0.92578125, 0.359375, 0.6796875 },
		alpha = 0.5,
	}

	local plate = CreateFrame('Frame', 'Arcane_ActionBarPlate', SUI_Art_Arcane)
	plate:SetSize(1002, 139)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetAllPoints(SUI_BottomAnchor)

	for i = 1, 4 do
		plate['BG' .. i] = Artwork_Core:CreateBarBG(BarBGSettings, i, Arcane_ActionBarPlate)
		if UnitFactionGroup('PLAYER') == 'Horde' then
			_G['Arcane_Bar' .. i .. 'BG']:SetVertexColor(1, 0, 0, 0.25)
		else
			_G['Arcane_Bar' .. i .. 'BG']:SetVertexColor(0, 0, 1, 0.25)
		end
	end
	plate.BG1:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -110, 70)
	plate.BG2:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -110, 25)
	plate.BG3:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 110, 70)
	plate.BG4:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 110, 25)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetSize(2, 2)
	artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_Arcane_Left', 'BORDER')
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Art_Left')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetScale(0.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_Arcane_Right', 'BORDER')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Arcane\\Images\\Art_Right')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetScale(0.75)
end
