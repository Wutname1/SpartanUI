local SUI, L = SUI, SUI.L
local print = SUI.print
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:NewModule('Style_Digital')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local artFrame = CreateFrame('Frame', 'SUI_Art_Digital', SpartanUI)
module.Settings = {}
local CurScale

----------------------------------------------------------------------------------------------------
local InitRan = false
function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Digital = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,192',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,340,191',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,707,193'
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
	UnregisterStateDriver(SUI_Art_Digital, 'visibility')
	SUI_Art_Digital:Hide()
end

--	Module Calls
function module:BuffLoc(_, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint('TOPRIGHT', -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Digital, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DB.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_Digital, 'visibility')
	end
end

function module:CreateArtwork()
	local plate = CreateFrame('Frame', 'Digital_ActionBarPlate', SpartanUI, 'Digital_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:ClearAllPoints()
	plate:SetAllPoints(SUI_BottomAnchor)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetSize(2, 2)
	artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

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
	module:SetupVehicleUI()

	if SUI:IsModuleEnabled('Minimap') and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
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
