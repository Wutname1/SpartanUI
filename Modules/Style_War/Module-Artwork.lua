local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
local module = SUI:GetModule('Style_War')
----------------------------------------------------------------------------------------------------
module.Trays = {}
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
		if SUI.DB.Styles.War.Artwork.Stance.enable then
			_G['War_StanceBar']:Show()
			_G['War_StanceBar']:SetAlpha(SUI.DB.Styles.War.Artwork.Stance.alpha)
		else
			_G['War_StanceBar']:Hide()
		end
		if SUI.DB.Styles.War.Artwork.MenuBar.enable then
			_G['War_MenuBar']:Show()
			_G['War_MenuBar']:SetAlpha(SUI.DB.Styles.War.Artwork.MenuBar.alpha)
		else
			_G['War_MenuBar']:Hide()
		end
	end
end

function module:updateOffset()
	local fubar, ChocolateBar, titan = 0, 0, 0

	if not SUI.DB.yoffsetAuto then
		offset = max(SUI.DB.yoffset, 0)
	else
		for i = 1, 4 do -- FuBar Offset
			if (_G['FuBarFrame' .. i] and _G['FuBarFrame' .. i]:IsVisible()) then
				local bar = _G['FuBarFrame' .. i]
				local point = bar:GetPoint(1)
				if point == 'BOTTOMLEFT' then
					fubar = fubar + bar:GetHeight()
				end
			end
		end

		for i = 1, 100 do -- Chocolate Bar Offset
			if (_G['ChocolateBar' .. i] and _G['ChocolateBar' .. i]:IsVisible()) then
				local bar = _G['ChocolateBar' .. i]
				local point = bar:GetPoint(1)
				if point == 'RIGHT' then
					ChocolateBar = ChocolateBar + bar:GetHeight()
				end
			end
		end

		TitanBarOrder = {[1] = 'AuxBar2', [2] = 'AuxBar'} -- Bottom 2 Bar names

		for i = 1, 2 do
			if (_G['Titan_Bar__Display_' .. TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i] .. '_Show')) then
				local PanelScale = TitanPanelGetVar('Scale') or 1
				titan = titan + (PanelScale * _G['Titan_Bar__Display_' .. TitanBarOrder[i]]:GetHeight())
			end
		end

		offset = max(fubar + titan + ChocolateBar, 1)
		SUI.DB.yoffset = offset
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
				Minimap:Hide()
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				War_SpartanUI:Show()
				Minimap:Show()
			end
		)
		RegisterStateDriver(petbattle, 'visibility', '[petbattle] hide; show')
		RegisterStateDriver(War_SpartanUI, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(petbattle, 'visibility')
		UnRegisterStateDriver(War_SpartanUI, 'visibility')
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
	War_SpartanUI:SetFrameStrata('BACKGROUND')
	War_SpartanUI:SetFrameLevel(1)

	War_SpartanUI.Left = War_SpartanUI:CreateTexture('War_SpartanUI_Left', 'BORDER')
	War_SpartanUI.Left:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', 0, 0)

	War_SpartanUI.Right = War_SpartanUI:CreateTexture('War_SpartanUI_Right', 'BORDER')
	War_SpartanUI.Right:SetPoint('LEFT', War_SpartanUI.Left, 'RIGHT', 0, 0)
	local barBG

	War_SpartanUI.Left:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Base_Bar_Left.tga')
	War_SpartanUI.Right:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Base_Bar_Right.tga')
	barBG = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\Barbg-' .. UnitFactionGroup('Player')

	War_SpartanUI.Left:SetScale(.75)
	War_SpartanUI.Right:SetScale(.75)

	for i = 1, 4 do
		_G['War_Bar' .. i .. 'BG']:SetAlpha(.25)
	end
	module:SlidingTrays()

	if barBG then
		for i = 1, 4 do
			_G['War_Bar' .. i .. 'BG']:SetTexture(barBG)
		end

		War_MenuBarBG:SetTexture(barBG)
		War_StanceBarBG:SetTexture(barBG)
	end

	module:updateOffset()

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
			MainMenuBarVehicleLeaveButton:SetPoint('LEFT', SUI_playerFrame, 'RIGHT', 15, 0)
		end
	)

	Artwork_Core:MoveTalkingHeadUI()
	module:SetupVehicleUI()

	if (SUI.DB.MiniMap.AutoDetectAllowUse) or (SUI.DB.MiniMap.ManualAllowUse) then
		module:MiniMap()
	end

	module:updateScale()
	module:updateAlpha()
	module:StatusBars()
end

function module:StatusBars()
	local Settings = {
		bars = {
			'War_StatusBar_Left',
			'War_StatusBar_Right'
		},
		War_StatusBar_Left = {
			bgImg = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
			size = {370, 20},
			TooltipSize = {250, 65},
			TooltipTextSize = {225, 40},
			texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
			GlowPoint = {x = -16},
			MaxWidth = 48
		},
		War_StatusBar_Right = {
			bgImg = 'Interface\\AddOns\\SpartanUI_Style_War\\Images\\StatusBar-' .. UnitFactionGroup('Player'),
			Grow = 'RIGHT',
			size = {370, 20},
			TooltipSize = {250, 65},
			TooltipTextSize = {225, 40},
			texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0},
			GlowPoint = {x = 16},
			MaxWidth = 48
		}
	}

	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(Settings)

	StatusBars.bars.War_StatusBar_Left:SetAlpha(.9)
	StatusBars.bars.War_StatusBar_Right:SetAlpha(.9)

	-- Position the StatusBars
	StatusBars.bars.War_StatusBar_Left:SetPoint('BOTTOMRIGHT', War_SpartanUI, 'BOTTOM', -100, 0)
	StatusBars.bars.War_StatusBar_Right:SetPoint('BOTTOMLEFT', War_SpartanUI, 'BOTTOM', 100, 0)
end

local SetBarVisibility = function(side, state)
	if side == 'left' and state == 'hide' then
		-- BT4BarStanceBar
		if not SUI.DB.Styles.War.MovedBars.BT4BarStanceBar then
			_G['BT4BarStanceBar']:Hide()
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarPetBar then
			_G['BT4BarPetBar']:Hide()
		end
	elseif side == 'right' and state == 'hide' then
		if not SUI.DB.Styles.War.MovedBars.BT4BarBagBar then
			_G['BT4BarBagBar']:Hide()
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarMicroMenu then
			_G['BT4BarMicroMenu']:Hide()
		end
	end

	if side == 'left' and state == 'show' then
		-- BT4BarStanceBar
		if not SUI.DB.Styles.War.MovedBars.BT4BarStanceBar then
			_G['BT4BarStanceBar']:Show()
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarPetBar then
			_G['BT4BarPetBar']:Show()
		end
	elseif side == 'right' and state == 'show' then
		if not SUI.DB.Styles.War.MovedBars.BT4BarBagBar then
			_G['BT4BarBagBar']:Show()
		end
		if not SUI.DB.Styles.War.MovedBars.BT4BarMicroMenu then
			_G['BT4BarMicroMenu']:Show()
		end
	end
end

local CollapseToggle = function(self)
	if SUI.DB.Styles.War.SlidingTrays[self.side].collapsed then
		SUI.DB.Styles.War.SlidingTrays[self.side].collapsed = false
		module.Trays[self.side].expanded:Show()
		module.Trays[self.side].collapsed:Hide()
		SetBarVisibility(self.side, 'show')
	else
		SUI.DB.Styles.War.SlidingTrays[self.side].collapsed = true
		module.Trays[self.side].expanded:Hide()
		module.Trays[self.side].collapsed:Show()
		SetBarVisibility(self.side, 'hide')
	end
end

-- Artwork Stuff
function module:SlidingTrays()
	local trayIDs = {'left', 'right'}
	War_MenuBarBG:SetAlpha(0)
	War_StanceBarBG:SetAlpha(0)

	for _, key in ipairs(trayIDs) do
		local tray = CreateFrame('Frame', nil, UIParent)
		tray:SetFrameStrata('BACKGROUND')
		tray:SetAlpha(.8)
		tray:SetSize(400, 45)

		local expanded = CreateFrame('Frame', nil, tray)
		expanded:SetAllPoints()
		local collapsed = CreateFrame('Frame', nil, tray)
		collapsed:SetAllPoints()

		local bg = expanded:CreateTexture(nil, 'BACKGROUND', expanded)
		bg:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'))
		bg:SetAllPoints()
		bg:SetTexCoord(0.076171875, 0.92578125, 0, 0.18359375)

		local bgCollapsed = collapsed:CreateTexture(nil, 'BACKGROUND', collapsed)
		bgCollapsed:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'))
		bgCollapsed:SetPoint('TOPLEFT', tray)
		bgCollapsed:SetPoint('TOPRIGHT', tray)
		bgCollapsed:SetHeight(18)
		bgCollapsed:SetTexCoord(0.076171875, 0.92578125, 1, 0.92578125)

		local btnUp = CreateFrame('BUTTON', nil, expanded)
		local UpTex = expanded:CreateTexture()
		UpTex:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'))
		UpTex:SetTexCoord(0.3671875, 0.640625, 0.20703125, 0.25390625)
		UpTex:Hide()
		btnUp:SetSize(130, 9)
		UpTex:SetAllPoints(btnUp)
		btnUp:SetNormalTexture('')
		btnUp:SetHighlightTexture(UpTex)
		btnUp:SetPushedTexture('')
		btnUp:SetDisabledTexture('')
		btnUp:SetPoint('BOTTOM', tray, 'BOTTOM', 1, 2)

		local btnDown = CreateFrame('BUTTON', nil, collapsed)
		local DownTex = collapsed:CreateTexture()
		DownTex:SetTexture('Interface\\AddOns\\SpartanUI_Style_War\\Images\\Trays-' .. UnitFactionGroup('Player'))
		DownTex:SetTexCoord(0.3671875, 0.640625, 0.25390625, 0.20703125)
		DownTex:Hide()
		btnDown:SetSize(130, 9)
		DownTex:SetAllPoints(btnDown)
		btnDown:SetNormalTexture('')
		btnDown:SetHighlightTexture(DownTex)
		btnDown:SetPushedTexture('')
		btnDown:SetDisabledTexture('')
		btnDown:SetPoint('TOP', tray, 'TOP', 2, -6)

		btnUp.side = key
		btnDown.side = key
		btnUp:SetScript('OnClick', CollapseToggle)
		btnDown:SetScript('OnClick', CollapseToggle)

		expanded.bg = bg
		expanded.btnUp = btnUp

		collapsed.bgCollapsed = bgCollapsed
		collapsed.btnDown = btnDown

		tray.expanded = expanded
		tray.collapsed = collapsed

		if SUI.DB.Styles.War.SlidingTrays[key].collapsed then
			tray.expanded:Hide()
			SetBarVisibility(key, 'hide')
		else
			tray.collapsed:Hide()
		end
		module.Trays[key] = tray
	end

	module.Trays.left:SetPoint('TOP', UIParent, 'TOP', -300, 0)
	module.Trays.right:SetPoint('TOP', UIParent, 'TOP', 300, 0)

	-- _G['BT4BarStanceBar']:SetScript(
	-- 	'Hide',
	-- 	function ()
	-- 		if module.Trays.left.expanded:IsVisible() then

	-- 		end
	-- 	end
	-- )
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
	SUI:GetModule('Component_Minimap'):ShapeChange('square')

	module:MiniMapUpdate()

	Minimap.coords:SetTextColor(1, .82, 0, 1)
	Minimap.coords:SetShadowColor(0, 0, 0, 1)
	Minimap.coords:SetScale(1.2)

	War_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetParent(UIParent)
			Minimap:SetPoint('TOP', UIParent, 'TOP', 0, -20)
			SUI:GetModule('Component_Minimap'):ShapeChange('square')
		end
	)

	War_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', War_SpartanUI, 'CENTER', 0, 54)
			Minimap:SetParent(War_SpartanUI)
			SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
