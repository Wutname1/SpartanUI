local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------
module.Trays = {}
module.StatusBarSettings = {
	bars = {
		'War_StatusBar_Left',
		'War_StatusBar_Right'
	},
	War_StatusBar_Left = {
		bgImg = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = -16},
		MaxWidth = 48
	},
	War_StatusBar_Right = {
		bgImg = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
		Grow = 'RIGHT',
		size = {370, 20},
		TooltipSize = {350, 100},
		TooltipTextSize = {330, 80},
		texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
		GlowPoint = {x = 16},
		MaxWidth = 48
	}
}
local CurScale
local petbattle = CreateFrame('Frame')

-- Misc Framework stuff
function module:updateScale()
	if (not SUI.DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar('gxResolution'), '(%d+).-(%d+)')
		if (tonumber(width) / tonumber(height) > 4 / 3) then
			SUI.DB.scale = 0.92
		else
			SUI.DB.scale = 0.78
		end
	end
	if SUI.DB.scale ~= CurScale then
		if (SUI.DB.scale ~= Artwork_Core:round(War_SpartanUI:GetScale())) then
			War_SpartanUI:SetScale(SUI.DB.scale)
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
		War_SpartanUI.Left:SetAlpha(SUI.DB.alpha)
		War_SpartanUI.Right:SetAlpha(SUI.DB.alpha)
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

	module.Trays.left:ClearAllPoints()
	module.Trays.right:ClearAllPoints()
	module.Trays.left:SetPoint('TOP', UIParent, 'TOP', -300, (Top * -1))
	module.Trays.right:SetPoint('TOP', UIParent, 'TOP', 300, (Top * -1))

	if BT4BarBagBar then
		if not SUI.DB.Styles.War.MovedBars.BT4BarPetBar then
			BT4BarPetBar:ClearAllPoints()
			BT4BarPetBar:SetPoint('TOPLEFT', module.Trays.left, 'TOPLEFT', 50, -2)
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarStanceBar then
			BT4BarStanceBar:ClearAllPoints()
			BT4BarStanceBar:SetPoint('TOPRIGHT', module.Trays.left, 'TOPRIGHT', -50, -2)
		end

		if not SUI.DB.Styles.War.MovedBars.BT4BarMicroMenu then
			BT4BarMicroMenu:ClearAllPoints()
			BT4BarMicroMenu:SetPoint('TOPLEFT', module.Trays.right, 'TOPLEFT', 50, -2)
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarBagBar then
			BT4BarBagBar:ClearAllPoints()
			BT4BarBagBar:SetPoint('TOPRIGHT', module.Trays.right, 'TOPRIGHT', -50, -2)
		end
	end

	War_ActionBarPlate:ClearAllPoints()
	War_ActionBarPlate:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, offset)
end

--	Module Calls
function module:TooltipLoc(_, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'War_SpartanUI', 'TOPRIGHT', 0, 10)
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
				War_SpartanUI:Hide()
				if SUI.DB.EnabledComponents.Minimap and (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
					Minimap:Hide()
				end
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				War_SpartanUI:Show()
				if SUI.DB.EnabledComponents.Minimap and (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
					Minimap:Show()
				end
			end
		)
		War_SpartanUI:HookScript(
			'OnShow',
			function()
				Artwork_Core:trayWatcherEvents()
			end
		)
		RegisterStateDriver(petbattle, 'visibility', '[petbattle] hide; show')
		RegisterStateDriver(War_SpartanUI, 'visibility', '[overridebar][vehicleui] hide; show')
		RegisterStateDriver(SpartanUI, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(petbattle, 'visibility')
		UnRegisterStateDriver(War_SpartanUI, 'visibility')
		UnRegisterStateDriver(SpartanUI, 'visibility')
	end
end

function module:InitArtwork()
	Artwork_Core:ActionBarPlates(
		'War_ActionBarPlate',
		{
			'BarBagBar',
			'BarStanceBar',
			'BarPetBar',
			'BarMicroMenu'
		}
	)

	plate = CreateFrame('Frame', 'War_ActionBarPlate', UIParent, 'War_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -10)
end

function module:EnableArtwork()
	--Setup the Bottom Artwork
	War_SpartanUI:SetFrameStrata('BACKGROUND')
	War_SpartanUI:SetFrameLevel(1)

	War_SpartanUI.Left = War_SpartanUI:CreateTexture('War_SpartanUI_Left', 'BORDER')
	War_SpartanUI.Left:SetPoint('BOTTOMRIGHT', War_ActionBarPlate, 'BOTTOM', 0, 0)

	War_SpartanUI.Right = War_SpartanUI:CreateTexture('War_SpartanUI_Right', 'BORDER')
	War_SpartanUI.Right:SetPoint('LEFT', War_SpartanUI.Left, 'RIGHT', 0, 0)

	War_SpartanUI.Left:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Base_Bar_Left.tga')
	War_SpartanUI.Right:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Base_Bar_Right.tga')

	-- Inital Scaling
	War_SpartanUI.Left:SetScale(.75)
	War_SpartanUI.Right:SetScale(.75)

	--Setup Sliding Trays
	module:SlidingTrays()

	-- Setup the bar BG
	local barBG = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Barbg-' .. UnitFactionGroup('Player')
	if barBG then
		for i = 1, 4 do
			_G['War_Bar' .. i .. 'BG']:SetTexture(barBG)
			_G['War_Bar' .. i .. 'BG']:SetAlpha(.25)
		end
	end

	Artwork_Core:updateOffset()

	hooksecurefunc(
		'UIParent_ManageFramePositions',
		function()
			TutorialFrameAlertButton:SetParent(Minimap)
			TutorialFrameAlertButton:ClearAllPoints()
			TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint('BOTTOM', War_SpartanUI, 'TOP', 0, 90)
		end
	)

	MainMenuBarVehicleLeaveButton:HookScript(
		'OnShow',
		function()
			MainMenuBarVehicleLeaveButton:ClearAllPoints()
			MainMenuBarVehicleLeaveButton:SetPoint('BOTTOM', War_SpartanUI.Left, 'TOPRIGHT', 0, 20)
		end
	)

	Artwork_Core:MoveTalkingHeadUI()
	module:SetupVehicleUI()

	if SUI.DB.EnabledComponents.Minimap and (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
		module:MiniMap()
	end

	module:StatusBars()
	module:updateScale()
	module:updateAlpha()
end

function module:StatusBars()
	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(module.StatusBarSettings)

	StatusBars.bars.War_StatusBar_Left:SetAlpha(.9)
	StatusBars.bars.War_StatusBar_Right:SetAlpha(.9)

	-- Position the StatusBars
	StatusBars.bars.War_StatusBar_Left:SetPoint('BOTTOMRIGHT', War_ActionBarPlate, 'BOTTOM', -100, 0)
	StatusBars.bars.War_StatusBar_Right:SetPoint('BOTTOMLEFT', War_ActionBarPlate, 'BOTTOM', 100, 0)
end

-- Artwork Stuff
function module:SlidingTrays()
	local Settings = {
		bg = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {.076171875, 0.92578125, 0, 0.18359375}
		},
		bgCollapsed = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.076171875, 0.92578125, 1, 0.92578125}
		},
		UpTex = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.3671875, 0.640625, 0.20703125, 0.25390625}
		},
		DownTex = {
			Texture = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'),
			TexCoord = {0.3671875, 0.640625, 0.25390625, 0.20703125}
		}
	}

	module.Trays = Artwork_Core:SlidingTrays(Settings)
end

-- Bartender Stuff
function module:SetupProfile()
	Artwork_Core:SetupProfile()
end

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

-- Minimap
function module:MiniMapUpdate()
	if Minimap.BG then
		Minimap.BG:ClearAllPoints()
	end

	Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\minimap1')
	Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 0, 3)
	Minimap.BG:SetAlpha(.75)
	-- Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\minimap2')
	-- Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', -7, 5)
	Minimap.BG:SetSize(256, 256)
	Minimap.BG:SetBlendMode('ADD')
end

module.Settings.MiniMap = {
	size = {
		156,
		156
	},
	TextLocation = 'BOTTOM',
	coordsLocation = 'BOTTOM',
	coords = {
		TextColor = {1, .82, 0, 1}
	}
}

function module:MiniMap()
	Minimap:SetParent(War_SpartanUI)

	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -5)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()
	end

	QueueStatusFrame:ClearAllPoints()
	QueueStatusFrame:SetPoint('BOTTOM', War_SpartanUI, 'TOP', 0, 100)

	Minimap.BG = Minimap:CreateTexture(nil, 'BACKGROUND')

	module.Settings.MiniMap.TextLocation = 'TOP'
	module.Settings.MiniMap.Anchor = {
		'CENTER',
		War_SpartanUI.Left,
		'RIGHT',
		0,
		5
	}
	SUI:GetModule('Component_Minimap'):ShapeChange('circle')

	module:MiniMapUpdate()

	Minimap.coords:SetTextColor(1, .82, 0, 1)
	Minimap.coords:SetShadowColor(0, 0, 0, 1)
	Minimap.coords:SetScale(1.2)

	War_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetParent(UIParent)
			Minimap:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -20, -20)
			-- SUI:GetModule('Component_Minimap'):ShapeChange('square')
		end
	)

	War_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', War_SpartanUI.Left, 'RIGHT', 0, 5)
			Minimap:SetParent(War_SpartanUI)
			-- SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
