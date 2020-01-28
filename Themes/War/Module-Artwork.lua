local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------

local CurScale, plate
local petbattle = CreateFrame('Frame')

function module:updateAlpha()
	-- Update Action bar backgrounds
	for i = 1, 4 do
		if SUI.DB.Styles.War.Artwork['bar' .. i].enable then
			_G['War_Bar' .. i]:Show()
			_G['War_Bar' .. i]:SetAlpha(SUI.DB.Styles.War.Artwork['bar' .. i].alpha)
		else
			_G['War_Bar' .. i]:Hide()
		end
	end
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
	if SUI.DBMod.Artwork.VehicleUI then
		petbattle:HookScript(
			'OnHide',
			function()
				SUI_Art_War:Hide()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Hide()
				end
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				SUI_Art_War:Show()
				if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
					Minimap:Show()
				end
			end
		)
		SUI_Art_War:HookScript(
			'OnShow',
			function()
				Artwork_Core:trayWatcherEvents()
			end
		)
		RegisterStateDriver(SUI_Art_War, 'visibility', '[overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnregisterStateDriver(SUI_Art_War, 'visibility')
	end
end

function module:CreateArtwork()
	plate = CreateFrame('Frame', 'War_ActionBarPlate', SpartanUI, 'War_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', SpartanUI, 'TOPLEFT', 10, -10)

	--Setup the Bottom Artwork
	local artFrame = CreateFrame('Frame', 'SUI_Art_War', SpartanUI)
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetPoint('BOTTOMLEFT', 0, 153)
	artFrame:SetPoint('BOTTOMRIGHT', 0, 153)

	artFrame.Left = artFrame:CreateTexture('SUI_Art_War_Left', 'BORDER')
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Left')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame, 'BOTTOM')
	artFrame.Left:SetScale(.75)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_War_Right', 'BORDER')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Right')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame, 'BOTTOM')
	artFrame.Right:SetScale(.75)
end

function module:EnableArtwork()
	--Setup Sliding Trays
	module:SlidingTrays()
	if BT4BarBagBar and BT4BarPetBar.position then
		BT4BarPetBar:position('TOPLEFT', module.Trays.left, 'TOPLEFT', 50, -2)
		BT4BarStanceBar:position('TOPRIGHT', module.Trays.left, 'TOPRIGHT', -50, -2)
		BT4BarMicroMenu:position('TOPLEFT', module.Trays.right, 'TOPLEFT', 50, -2)
		BT4BarBagBar:position('TOPRIGHT', module.Trays.right, 'TOPRIGHT', -100, -2)
	end

	-- Setup the bar BG
	local barBG = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Barbg-' .. UnitFactionGroup('Player')
	if barBG then
		for i = 1, 4 do
			_G['War_Bar' .. i .. 'BG']:SetTexture(barBG)
			_G['War_Bar' .. i .. 'BG']:SetAlpha(.25)
		end
	end

	War_ActionBarPlate:ClearAllPoints()
	War_ActionBarPlate:SetPoint('BOTTOM', SpartanUI, 'BOTTOM', 0, offset)

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

	if SUI.DB.EnabledComponents.Minimap and ((SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse)) then
		module:MiniMap()
	end

	module:StatusBars()
	module:updateScale()
	module:updateAlpha()
end

function module:StatusBars()
	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(module.StatusBarSettings)

	StatusBars.bars.StatusBar_Left:SetAlpha(.9)
	StatusBars.bars.StatusBar_Right:SetAlpha(.9)

	-- Position the StatusBars
	StatusBars.bars.StatusBar_Left:SetPoint('BOTTOMRIGHT', War_ActionBarPlate, 'BOTTOM', -100, 0)
	StatusBars.bars.StatusBar_Right:SetPoint('BOTTOMLEFT', War_ActionBarPlate, 'BOTTOM', 100, 0)
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

	module.Trays = Artwork_Core:SlidingTrays(Settings)
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
