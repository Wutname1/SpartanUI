local SUI, L = SUI, SUI.L
local print, error = SUI.print, SUI.Error
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Digital')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Digital', SpartanUI)
module.Settings = {}
local CurScale
local petbattle = CreateFrame('Frame')
local StatusBarSettings = {
	bars = {
		'Digital_StatusBar_Left',
		'Digital_StatusBar_Right'
	},
	Digital_StatusBar_Left = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
		size = {370, 20},
		TooltipSize = {400, 100},
		TooltipTextSize = {380, 90},
		texCords = {0.150390625, 1, 0, 1},
		GlowPoint = {x = -10},
		MaxWidth = 32,
		bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
		texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
	},
	Digital_StatusBar_Right = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\status-plate-exp',
		Grow = 'RIGHT',
		size = {370, 20},
		TooltipSize = {400, 100},
		TooltipTextSize = {380, 90},
		texCords = {0.150390625, 1, 0, 1},
		GlowPoint = {x = 10},
		MaxWidth = 35,
		bgTooltip = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
		texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
	}
}

----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Digital = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_ActionBarAnchor,BOTTOM,707,193'
	}

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Digital = {
		bg = {
			path = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
			TexCoord = {0.0234375, 0.9765625, 0.265625, 0.7734375},
			PVPAlpha = .4
		}
	}

	module:CreateArtwork()
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style ~= 'Digital') then
		module:Disable()
	else
		module:EnableArtwork()
	end
end

function module:OnDisable()
	artFrame:Hide()
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
		RegisterStateDriver(SUI_Art_Digital, 'visibility', '[overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(petbattle, 'visibility')
		UnregisterStateDriver(SUI_Art_Digital, 'visibility')
		UnregisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:CreateArtwork()
	plate = CreateFrame('Frame', 'Digital_ActionBarPlate', SpartanUI, 'Digital_ActionBarsTemplate')
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
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\Base_Bar_Left')
	-- artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_War_Right', 'BORDER')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\Base_Bar_Right')
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
			CastingBarFrame:SetPoint('BOTTOM', SUI_Art_Digital, 'TOP', 0, 90)
		end
	)

	module:SetupVehicleUI()

	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end

	module:StatusBars()
end

function module:StatusBars()
	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(StatusBarSettings)

	-- Position the StatusBars
	StatusBars.bars.Digital_StatusBar_Left:SetPoint('BOTTOMRIGHT', SUI_Art_Digital, 'BOTTOM', -100, 0)
	StatusBars.bars.Digital_StatusBar_Right:SetPoint('BOTTOMLEFT', SUI_Art_Digital, 'BOTTOM', 100, 0)
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

	SUI:GetModule('Component_Minimap'):ShapeChange('circle')

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
			Minimap:SetPoint('CENTER', SUI_Art_Digital, 'CENTER', 0, 54)
			SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
