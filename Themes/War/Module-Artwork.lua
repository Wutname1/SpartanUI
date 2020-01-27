local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local UnitFrames = SUI:GetModule('Component_UnitFrames')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------
module.Trays = {}
module.StatusBarSettings = {
	bars = {
		'StatusBar_Left',
		'StatusBar_Right'
	},
	StatusBar_Left = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = -16},
		MaxWidth = 48
	},
	StatusBar_Right = {
		bgImg = 'Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		Grow = 'RIGHT',
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = 16},
		MaxWidth = 48
	}
}
local CurScale, plate
local petbattle = CreateFrame('Frame')

-- Misc Framework stuff
function module:updateScale()
	if (not SUI.DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local Resolution = ''
		if select(4, GetBuildInfo()) >= 70000 then
			Resolution = GetCVar('gxWindowedResolution')
		else
			Resolution = GetCVar('gxResolution')
		end

		local width, height = string.match(Resolution, '(%d+).-(%d+)')
		if (tonumber(width) / tonumber(height) > 4 / 3) then
			SUI.DB.scale = 0.92
		else
			SUI.DB.scale = 0.78
		end
	end
	if SUI.DB.scale ~= CurScale then
		if (SUI.DB.scale ~= SUI:round(SUI_Art_War:GetScale())) then
			SUI_Art_War:SetScale(SUI.DB.scale)
		end
		local StatusBars = SUI:GetModule('Artwork_StatusBars')
		for _, key in ipairs(module.StatusBarSettings.bars) do
			StatusBars.bars[key]:SetScale(SUI.DB.scale)
		end

		CurScale = SUI.DB.scale
	end
end

function module:updateAlpha()
	if SUI.DB.alpha then
		SUI_Art_War.Left:SetAlpha(SUI.DB.alpha)
		SUI_Art_War.Right:SetAlpha(SUI.DB.alpha)
	end
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

function module:updateOffset(Top, offset)
	if InCombatLockdown() then
		return
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

function module:InitArtwork()
	plate = CreateFrame('Frame', 'War_ActionBarPlate', SpartanUI, 'War_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', SpartanUI, 'TOPLEFT', 10, -10)

	--Setup the Bottom Artwork
	SUI_Art_War:SetFrameStrata('BACKGROUND')
	SUI_Art_War:SetFrameLevel(1)

	SUI_Art_War.Left = SUI_Art_War:CreateTexture('SUI_Art_War_Left', 'BORDER')
	SUI_Art_War.Left:SetPoint('BOTTOMRIGHT', War_ActionBarPlate, 'BOTTOM', 0, 0)

	SUI_Art_War.Right = SUI_Art_War:CreateTexture('SUI_Art_War_Right', 'BORDER')
	SUI_Art_War.Right:SetPoint('LEFT', SUI_Art_War.Left, 'RIGHT', 0, 0)

	SUI_Art_War.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Left.tga')
	SUI_Art_War.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\War\\Images\\Base_Bar_Right.tga')

	-- Inital Scaling
	SUI_Art_War.Left:SetScale(.75)
	SUI_Art_War.Right:SetScale(.75)

	-- Setup Frame posistions
	UnitFrames.FramePos['War'] = {
		['player'] = 'BOTTOMRIGHT,UIParent,BOTTOM,-45,250'
	}
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

	MainMenuBarVehicleLeaveButton:HookScript(
		'OnShow',
		function()
			MainMenuBarVehicleLeaveButton:ClearAllPoints()
			MainMenuBarVehicleLeaveButton:SetPoint('BOTTOM', SUI_Art_War.Left, 'TOPRIGHT', 0, 20)
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


	-- SUI:GetModule('Component_Minimap'):ShapeChange('circle')
end
