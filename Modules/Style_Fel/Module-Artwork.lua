local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Artwork_Core')
local module = SUI:GetModule('Style_Fel')
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
		if (SUI.DB.scale ~= Artwork_Core:round(Fel_SpartanUI:GetScale())) then
			Fel_SpartanUI:SetScale(SUI.DB.scale)
		end
		CurScale = SUI.DB.scale
	end
end

function module:updateAlpha()
	if SUI.DB.alpha then
		Fel_SpartanUI.Left:SetAlpha(SUI.DB.alpha)
		Fel_SpartanUI.Right:SetAlpha(SUI.DB.alpha)
	end
	-- Update Action bar backgrounds
	for i = 1, 4 do
		if SUI.DB.Styles.Fel.Artwork['bar' .. i].enable then
			_G['Fel_Bar' .. i]:Show()
			_G['Fel_Bar' .. i]:SetAlpha(SUI.DB.Styles.Fel.Artwork['bar' .. i].alpha)
		else
			_G['Fel_Bar' .. i]:Hide()
		end
		if SUI.DB.Styles.Fel.Artwork.Stance.enable then
			_G['Fel_StanceBar']:Show()
			_G['Fel_StanceBar']:SetAlpha(SUI.DB.Styles.Fel.Artwork.Stance.alpha)
		else
			_G['Fel_StanceBar']:Hide()
		end
		if SUI.DB.Styles.Fel.Artwork.MenuBar.enable then
			_G['Fel_MenuBar']:Show()
			_G['Fel_MenuBar']:SetAlpha(SUI.DB.Styles.Fel.Artwork.MenuBar.alpha)
		else
			_G['Fel_MenuBar']:Hide()
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

	Fel_ActionBarPlate:ClearAllPoints()
	Fel_ActionBarPlate:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, offset)
end

--	Module Calls
function module:TooltipLoc(_, parent)
	if (parent == 'UIParent') then
		tooltip:ClearAllPoints()
		tooltip:SetPoint('BOTTOMRIGHT', 'Fel_SpartanUI', 'TOPRIGHT', 0, 10)
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
				Fel_SpartanUI:Hide()
				Minimap:Hide()
			end
		)
		petbattle:HookScript(
			'OnShow',
			function()
				Fel_SpartanUI:Show()
				Minimap:Show()
			end
		)
		RegisterStateDriver(petbattle, 'visibility', '[petbattle] hide; show')
		RegisterStateDriver(Fel_SpartanUI, 'visibility', '[overridebar][vehicleui] hide; show')
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(petbattle, 'visibility')
		UnRegisterStateDriver(Fel_SpartanUI, 'visibility')
	end
end

function module:InitArtwork()
	Artwork_Core:ActionBarPlates('Fel_ActionBarPlate')

	plate = CreateFrame('Frame', 'Fel_ActionBarPlate', UIParent, 'Fel_ActionBarsTemplate')
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetPoint('BOTTOM')

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -10)
end

function module:EnableArtwork()
	Fel_SpartanUI:SetFrameStrata('BACKGROUND')
	Fel_SpartanUI:SetFrameLevel(1)

	Fel_SpartanUI.Left = Fel_SpartanUI:CreateTexture('Fel_SpartanUI_Left', 'BORDER')
	Fel_SpartanUI.Left:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOM', 0, 0)

	Fel_SpartanUI.Right = Fel_SpartanUI:CreateTexture('Fel_SpartanUI_Right', 'BORDER')
	Fel_SpartanUI.Right:SetPoint('LEFT', Fel_SpartanUI.Left, 'RIGHT', 0, 0)
	local barBG

	if SUI.DB.Styles.Fel.SubTheme == 'Digital' then
		Fel_SpartanUI.Left:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Digital\\Base_Bar_Left')
		Fel_SpartanUI.Right:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Digital\\Base_Bar_Right')
		barBG = 'Interface\\AddOns\\SpartanUI_Style_Fel\\Digital\\Fel-Box'
	elseif SUI.DB.Styles.Fel.SubTheme == 'War' then
		Fel_SpartanUI.Left:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\Base_Bar_Left.tga')
		Fel_SpartanUI.Right:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\Base_Bar_Right.tga')
		barBG = 'Interface\\AddOns\\SpartanUI_Style_Fel\\War\\Barbg-' .. UnitFactionGroup('Player')

		Fel_SpartanUI.Left:SetScale(.75)
		Fel_SpartanUI.Right:SetScale(.75)

		for i = 1, 4 do
			_G['Fel_Bar' .. i .. 'BG']:SetAlpha(.25)
		end
		module:SlidingTrays()
	else
		Fel_SpartanUI.Left:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Base_Bar_Left')
		Fel_SpartanUI.Right:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Base_Bar_Right')
	end

	if barBG then
		for i = 1, 4 do
			_G['Fel_Bar' .. i .. 'BG']:SetTexture(barBG)
		end

		Fel_MenuBarBG:SetTexture(barBG)
		Fel_StanceBarBG:SetTexture(barBG)
	end

	module:updateOffset()

	hooksecurefunc(
		'UIParent_ManageFramePositions',
		function()
			TutorialFrameAlertButton:SetParent(Minimap)
			TutorialFrameAlertButton:ClearAllPoints()
			TutorialFrameAlertButton:SetPoint('CENTER', Minimap, 'TOP', -2, 30)
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint('BOTTOM', Fel_SpartanUI, 'TOP', 0, 90)
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
			'Fel_StatusBar_Left',
			'Fel_StatusBar_Right'
		},
		Fel_StatusBar_Left = {
			bgImg = 'Interface\\AddOns\\SpartanUI_Artwork\\Themes\\Classic\\Images\\status-plate-exp',
			size = {370, 20},
			TooltipSize = {250, 65},
			TooltipTextSize = {225, 40},
			texCords = {0.150390625, 1, 0, 1},
			GlowPoint = {x = -10},
			MaxWidth = 32,
			bgTooltip = 'Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Fel-Box',
			texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
		},
		Fel_StatusBar_Right = {
			bgImg = 'Interface\\AddOns\\SpartanUI_Artwork\\Themes\\Classic\\Images\\status-plate-exp',
			Grow = 'RIGHT',
			size = {370, 20},
			TooltipSize = {250, 65},
			TooltipTextSize = {225, 40},
			texCords = {0.150390625, 1, 0, 1},
			GlowPoint = {x = 10},
			MaxWidth = 35,
			bgTooltip = 'Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Fel-Box',
			texCordsTooltip = {0.03125, 0.96875, 0.2578125, 0.7578125}
		}
	}

	if SUI.DB.Styles.Fel.SubTheme == 'War' then
		Settings.Fel_StatusBar_Left.bgImg =
			'Interface\\AddOns\\SpartanUI_Style_Fel\\War\\StatusBar-' .. UnitFactionGroup('Player')
		Settings.Fel_StatusBar_Left.GlowPoint = {x = -16}
		Settings.Fel_StatusBar_Left.MaxWidth = 18
		Settings.Fel_StatusBar_Left.texCords = {0.0546875, 0.9140625, 0.5555555555555556, 0}
		Settings.Fel_StatusBar_Left.bgTooltip = nil

		Settings.Fel_StatusBar_Right.bgImg = Settings.Fel_StatusBar_Left.bgImg
		Settings.Fel_StatusBar_Right.GlowPoint = {x = 16}
		Settings.Fel_StatusBar_Right.MaxWidth = 48
		Settings.Fel_StatusBar_Right.texCords = Settings.Fel_StatusBar_Left.texCords
		Settings.Fel_StatusBar_Right.bgTooltip = nil
	end

	local StatusBars = SUI:GetModule('Artwork_StatusBars')
	StatusBars:Initalize(Settings)

	if SUI.DB.Styles.Fel.SubTheme == 'War' then
		StatusBars.bars.Fel_StatusBar_Left:SetAlpha(.9)
		StatusBars.bars.Fel_StatusBar_Right:SetAlpha(.9)
	end

	-- Position the StatusBars
	StatusBars.bars.Fel_StatusBar_Left:SetPoint('BOTTOMRIGHT', Fel_SpartanUI, 'BOTTOM', -100, 0)
	StatusBars.bars.Fel_StatusBar_Right:SetPoint('BOTTOMLEFT', Fel_SpartanUI, 'BOTTOM', 100, 0)
end

-- Artwork Stuff
function module:SlidingTrays()
	local trayIDs = {'left', 'right'}
	for _, key in ipairs(trayIDs) do
		local tray = CreateFrame('Frame', nil, UIParent)
		tray:SetFrameStrata('BACKGROUND')
		tray:SetSize(400, 45)

		tray.bg = tray:CreateTexture(nil, 'BACKGROUND')
		tray.bg:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\Trays-' .. UnitFactionGroup('Player'))
		tray.bg:SetAllPoints(tray)
		tray.bg:SetTexCoord(0.076171875, 0.92578125, 0, 0.18359375)

		tray.bgCollapsed = tray:CreateTexture(nil, 'BACKGROUND')
		tray.bgCollapsed:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\Trays-' .. UnitFactionGroup('Player'))
		tray.bgCollapsed:SetPoint('TOPLEFT', tray, 'BOTTOMLEFT')
		tray.bgCollapsed:SetPoint('TOPRIGHT', tray, 'BOTTOMRIGHT')
		tray.bgCollapsed:SetHeight(18)
		tray.bgCollapsed:SetTexCoord(0.076171875, 0.92578125, 1, 0.92578125)

		tray.bgCollapsed:Hide()
		
		module.Trays[key] = tray
	end

	module.Trays.left:SetAlpha(.8)
	module.Trays.right:SetAlpha(.8)
	
	module.Trays.left:SetPoint('TOP', UIParent, 'TOP', -300, 0)
	module.Trays.right:SetPoint('TOP', UIParent, 'TOP', 300, 0)

	if SUI.DB.Styles.Fel.SlidingTrays.left.collapsed then
		module.Trays.left:SetPoint('TOP', UIParent, 'TOP', 100, -45)
		module.Trays.left.bgCollapsed:Show()
	end
	if SUI.DB.Styles.Fel.SlidingTrays.right.collapsed then
		module.Trays.right:SetPoint('TOP', UIParent, 'TOP', 100, -45)
		module.Trays.right.bgCollapsed:Show()
	end
	
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

	if SUI.DB.Styles.Fel.SubTheme == 'Digital' then
		Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Digital\\Minimap')
		Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 5, -1)
		Minimap.BG:SetSize(256, 256)
		Minimap.BG:SetBlendMode('ADD')
	elseif SUI.DB.Styles.Fel.SubTheme == 'War' then
		Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\minimap1')
		Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 0, 3)
		Minimap.BG:SetAlpha(.75)
		-- Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\War\\minimap2')
		-- Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', -7, 5)
		Minimap.BG:SetSize(256, 256)
		Minimap.BG:SetBlendMode('ADD')
	else
		if SUI.DB.Styles.Fel.Minimap.Engulfed then
			Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Minimap-Engulfed')
			Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 7, 37)
			Minimap.BG:SetSize(330, 330)
			Minimap.BG:SetBlendMode('ADD')
		else
			Minimap.BG:SetTexture('Interface\\AddOns\\SpartanUI_Style_Fel\\Images\\Minimap-Calmed')
			Minimap.BG:SetPoint('CENTER', Minimap, 'CENTER', 5, -1)
			Minimap.BG:SetSize(256, 256)
			Minimap.BG:SetBlendMode('ADD')
		end
	end
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
	Minimap:SetParent(Fel_SpartanUI)

	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint('TOPLEFT', Minimap, 'BOTTOMLEFT', 0, -5)
		Minimap.ZoneText:SetPoint('TOPRIGHT', Minimap, 'BOTTOMRIGHT', 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()
	end

	QueueStatusFrame:ClearAllPoints()
	QueueStatusFrame:SetPoint('BOTTOM', Fel_SpartanUI, 'TOP', 0, 100)

	Minimap.BG = Minimap:CreateTexture(nil, 'BACKGROUND')

	if SUI.DB.Styles.Fel.SubTheme == 'War' then
		module.Settings.MiniMap.TextLocation = 'TOP'
		module.Settings.MiniMap.Anchor = {
			'CENTER',
			Fel_SpartanUI.Left,
			'RIGHT',
			0,
			5
		}
		SUI:GetModule('Component_Minimap'):ShapeChange('square')
	else
		module.Settings.MiniMap.Anchor = {
			'CENTER',
			Fel_SpartanUI.Left,
			'RIGHT',
			0,
			-10
		}
		SUI:GetModule('Component_Minimap'):ShapeChange('circle')
	end

	module:MiniMapUpdate()

	Minimap.coords:SetTextColor(1, .82, 0, 1)
	Minimap.coords:SetShadowColor(0, 0, 0, 1)
	Minimap.coords:SetScale(1.2)

	Fel_SpartanUI:HookScript(
		'OnHide',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetParent(UIParent)
			Minimap:SetPoint('TOP', UIParent, 'TOP', 0, -20)
			SUI:GetModule('Component_Minimap'):ShapeChange('square')
		end
	)

	Fel_SpartanUI:HookScript(
		'OnShow',
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint('CENTER', Fel_SpartanUI, 'CENTER', 0, 54)
			Minimap:SetParent(Fel_SpartanUI)
			SUI:GetModule('Component_Minimap'):ShapeChange('circle')
		end
	)
end
