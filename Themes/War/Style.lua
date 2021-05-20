local SUI, L = SUI, SUI.L
local print = SUI.print
local module = SUI:NewModule('Style_War')
local Artwork_Core = SUI:GetModule('Component_Artwork')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_War', SpartanUI)
module.Settings = {}
----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	-- Bartender 4 Settings
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.War = {
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,70',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,70',
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
		local factionGroup = select(1, UnitFactionGroup('player'))
		if frame then
			factionGroup = select(1, UnitFactionGroup(frame.unit)) or 'Neutral'
		end

		if factionGroup == 'Horde' or factionGroup == 'Alliance' then
			return 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\UnitFrames'
		end
		if position == 'bg' then
			return 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
		end

		return false
	end
	local TexCoordFunc = function(frame, position)
		local factionGroup = select(1, UnitFactionGroup('player'))
		if frame then
			factionGroup = select(1, UnitFactionGroup(frame.unit)) or 'Neutral'
		end

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
		skin = 'War',
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
	UnitFrames.FramePos.War = {
		['player'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-45,250'
	}
	module:CreateArtwork()
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'War') then
		module:Disable()
	else
		--Setup Sliding Trays
		module:SlidingTrays()

		hooksecurefunc(
			'UIParent_ManageFramePositions',
			function()
				if TutorialFrameAlertButton then
					TutorialFrameAlertButton:SetParent(Minimap)
					TutorialFrameAlertButton:ClearAllPoints()
					TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
				end
				CastingBarFrame:ClearAllPoints()
				CastingBarFrame:SetPoint('BOTTOM', SUI_Art_War, 'TOP', 0, 90)
			end
		)

		module:SetupVehicleUI()

		if SUI:IsModuleEnabled('Minimap') and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
			module:MiniMap()
		end
	end
end

function module:OnDisable()
	SUI_Art_War:Hide()
	UnregisterStateDriver(SUI_Art_War, 'visibility')
end

--	Module Calls
function module:TooltipLoc(_, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'SUI_Art_War', 'TOPRIGHT', 0, 10)
	end
end

function module:BuffLoc(_, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		SUI_Art_War:HookScript(
			'OnShow',
			function()
				Artwork_Core:trayWatcherEvents()
			end
		)
		RegisterStateDriver(SUI_Art_War, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_War, 'visibility')
	end
end

function module:CreateArtwork()
	if War_ActionBarPlate then
		return
	end

	local BarBGSettings = {
		name = 'War',
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Barbg',
		TexCoord = {0.07421875, 0.92578125, 0.359375, 0.6796875},
		alpha = .5
	}

	local plate = CreateFrame('Frame', 'War_ActionBarPlate', SUI_Art_War)
	plate:SetSize(1002, 139)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetAllPoints(SUI_BottomAnchor)

	for i = 1, 4 do
		plate['BG' .. i] = Artwork_Core:CreateBarBG(BarBGSettings, i, War_ActionBarPlate)
		if UnitFactionGroup('PLAYER') == 'Horde' then
			_G['War_Bar' .. i .. 'BG']:SetVertexColor(1, 0, 0, .25)
		else
			_G['War_Bar' .. i .. 'BG']:SetVertexColor(0, 0, 1, .25)
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

	artFrame.Left = artFrame:CreateTexture('SUI_Art_War_Left', 'BORDER')
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Left')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_War_Right', 'BORDER')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Right')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetScale(.75)
end

-- Artwork Stuff
function module:SlidingTrays()
	local Settings = {
		bg = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {.076171875, 0.92578125, 0, 0.18359375}
		},
		bgCollapsed = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.076171875, 0.92578125, 1, 0.92578125}
		},
		UpTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.3671875, 0.640625, 0.20703125, 0.25390625}
		},
		DownTex = {
			Texture = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.3671875, 0.640625, 0.25390625, 0.20703125}
		}
	}

	Artwork_Core:SlidingTrays(Settings)

	if BT4BarBagBar and BT4BarPetBar.position then
		BT4BarPetBar:position('TOPLEFT', 'SlidingTray_left', 'TOPLEFT', 50, -2)
		BT4BarStanceBar:position('TOPRIGHT', 'SlidingTray_left', 'TOPRIGHT', -50, -2)
		BT4BarMicroMenu:position('TOPLEFT', 'SlidingTray_right', 'TOPLEFT', 50, -2)
		BT4BarBagBar:position('TOPRIGHT', 'SlidingTray_right', 'TOPRIGHT', -100, -2)
	end
end

-- Minimap
function module:MiniMap()
	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -5)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()
	end
end
