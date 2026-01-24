local SUI, L = SUI, SUI.L
---@class SUI.Theme.Digital : SUI.Theme.StyleBase
local module = SUI:NewModule('Style.Digital')
local artFrame = CreateFrame('Frame', 'SUI_Art_Digital', SpartanUI)
module.Settings = {}

----------------------------------------------------------------------------------------------------
function module:OnInitialize()
	local BarHandler = SUI.Handlers.BarSystem
	BarHandler.BarPosition.BT4.Digital = {
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-285,175',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-607,177',
		['MultiCastActionBarFrame'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-661,191',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,310,151',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,661,174',
	}

	if SUI.UF then
		---@type SUI.Style.Settings.UnitFrames
		local ufsettings = {
			artwork = {
				bg = {
					path = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\BarBG',
					TexCoord = { 0.0234375, 0.9765625, 0.265625, 0.7734375 },
					PVPAlpha = 0.4,
				},
			},
			displayName = 'Digital',
			setup = {
				image = 'Interface\\AddOns\\SpartanUI\\images\\setup\\Style_Frames_Digital',
			},
		}
		SUI.UF.Style:Register('Digital', ufsettings)
	end

	---@type SUI.Style.Settings.Minimap
	local minimapSettings = SUI.IsRetail
			and {
				-- Retail Digital theme settings
				size = { 180, 180 },
				position = 'CENTER,SUI_Art_Digital,CENTER,0,54',
				elements = {
					background = {
						texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\Minimap',
						position = { 'TOPLEFT,Minimap,TOPLEFT,-38,41', 'BOTTOMRIGHT,Minimap,BOTTOMRIGHT,47,-44' },
					},
				},
			}
		or {
			-- Classic client Digital theme settings
			size = { 140, 140 },
			position = 'CENTER,SUI_Art_Digital,CENTER,0,54',
			background = {
				texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Digital\\Images\\Minimap',
				position = { 'TOPLEFT,Minimap,TOPLEFT,-38,41', 'BOTTOMRIGHT,Minimap,BOTTOMRIGHT,47,-44' },
			},
		}
	SUI.Minimap:Register('Digital', minimapSettings)

	local statusBarModule = SUI:GetModule('Artwork.StatusBars') ---@type SUI.Module.Artwork.StatusBars
	---@type SUI.Style.Settings.StatusBars
	local StatusBarsSettings = {
		bgTexture = 'Interface\\AddOns\\SpartanUI\\Themes\\Tribal\\Images\\StatusBar',
		size = { 370, 20 },
		tooltip = {
			texture = 'Interface\\AddOns\\SpartanUI\\Themes\\Fel\\Images\\Fel-Box',
			textureCoords = { 0.03125, 0.96875, 0.2578125, 0.7578125 },
		},
		texCords = { 0.150390625, 1, 0, 1 },
		MaxWidth = 32,
	}
	statusBarModule:RegisterStyle('Digital', { Left = SUI:CopyTable({}, StatusBarsSettings), Right = SUI:CopyTable({}, StatusBarsSettings) })

	module:CreateArtwork()
end

function module:OnEnable()
	if SUI.DB.Artwork.Style ~= 'Digital' then
		module:Disable()
	else
		module:EnableArtwork()
	end
end

function module:OnDisable()
	UnregisterStateDriver(SUI_Art_Digital, 'visibility')
	SUI_Art_Digital:Hide()
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
end

function module:EnableArtwork()
	module:SetupVehicleUI()
end
