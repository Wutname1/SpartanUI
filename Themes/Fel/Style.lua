local SUI, L = SUI, SUI.L
local print, error = SUI.print, SUI.Error
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Fel')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Fel', SpartanUI)
module.Settings = {}
local CurScale
local petbattle = CreateFrame('Frame')
----------------------------------------------------------------------------------------------------
local InitRan = false

local function Options()
	SUI.opt.args.Artwork.args.Fel = {
		name = 'Fel style',
		type = 'group',
		order = 10,
		args = {
			MinimapEngulfed = {
				name = L['Douse the flames'],
				type = 'toggle',
				order = .1,
				desc = L['Is it getting hot in here?'],
				get = function(info)
					return (SUI.DB.Styles.Fel.Minimap.Engulfed ~= true or false)
				end,
				set = function(info, val)
					SUI.DB.Styles.Fel.Minimap.Engulfed = (val ~= true or false)
					module:MiniMapUpdate()
				end
			}
		}
	}
end

function module:OnInitialize()
	-- BarHandler
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Fel = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,707,193'
	}

	-- Unitframes
	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Fel = {
		top = {
			-- path = 'Interface\\Scenarios\\LegionInvasion',
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
end

--	Module Calls
function module:BuffLoc(_, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		petbattle:HookScript(
			'OnHide',
			function()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Hide()
				end
				artFrame:Hide()
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Show()
				end
				artFrame:Show()
			end
		)
		RegisterStateDriver(petbattle, 'visibility', '[petbattle] hide; show')
		RegisterStateDriver(SUI_Art_Fel, 'visibility', '[overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(petbattle, 'visibility')
		UnregisterStateDriver(SUI_Art_Fel, 'visibility')
		UnregisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:CreateArtwork()
	plate = CreateFrame('Frame', 'Fel_ActionBarPlate', SpartanUI, 'Fel_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:ClearAllPoints()
	plate:SetAllPoints(SUI_ActionBarAnchor)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetPoint('BOTTOMLEFT')
	artFrame:SetPoint('TOPRIGHT', SpartanUI, 'BOTTOMRIGHT', 0, 153)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_War_Left', 'BORDER')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM', 0, 0)
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Base_Bar_Left')
	-- artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_War_Right', 'BORDER')
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

	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end
end

-- Minimap
function module:MiniMapUpdate()
	if Minimap.Background then
		Minimap.Background:ClearAllPoints()
	end

	if SUI.DB.Styles.Fel.Minimap.Engulfed then
		Minimap.Background:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Engulfed')
		Minimap.Background:SetPoint('CENTER', Minimap, 'CENTER', 7, 37)
		Minimap.Background:SetSize(330, 330)
		Minimap.Background:SetBlendMode('ADD')
	else
		Minimap.Background:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Minimap-Calmed')
		Minimap.Background:SetPoint('CENTER', Minimap, 'CENTER', 5, -1)
		Minimap.Background:SetSize(256, 256)
		Minimap.Background:SetBlendMode('ADD')
	end
end

function module:MiniMap()
	SUI:GetModule('Component_Minimap'):ShapeChange('circle')

	module:MiniMapUpdate()

	artFrame:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			SUI:GetModule('Component_Minimap'):ShapeChange('square')
		end
	)

	artFrame:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', SUI_Art_Fel, 'CENTER', 0, 54)
			SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
