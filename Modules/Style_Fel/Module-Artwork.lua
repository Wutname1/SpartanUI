local _G, SUI = _G, SUI
local L = SUI.L
local Artwork_Core = SUI:GetModule("Artwork_Core")
local module = SUI:GetModule("Style_Fel")
----------------------------------------------------------------------------------------------------
local CurScale
local petbattle = CreateFrame("Frame")
local apframe
local xpframe
local rframe
local tooltip
local FACTION_BAR_COLORS = {
	[1] = {r = 1,	g = 0.2,	b = 0},
	[2] = {r = 0.8,	g = 0.3,	b = 0},
	[3] = {r = 0.8,	g = 0.2,	b = 0},
	[4] = {r = 1,	g = 0.8,	b = 0},
	[5] = {r = 0,	g = 1,		b = 0.1},
	[6] = {r = 0,	g = 1,		b = 0.2},
	[7] = {r = 0,	g = 1,		b = 0.3},
	[8] = {r = 0,	g = 0.6,	b = 0.1},
};
local COLORS = {
	["Orange"]=	{r = 1,		g = 0.2,	b = 0,	a = .7},
	["Yellow"]=	{r = 1,		g = 0.8,	b = 0,	a = .7},
	["Green"]=	{r = 0,		g = 1,		b = .1,	a = .7},
	["Blue"]=	{r = 0,		g = .1,		b = 1,	a = .7},
	["Pink"]=	{r = 1,		g = 0,		b = .4,	a = .7},
	["Purple"]=	{r = 1,		g = 0,		b = 1,	a = .5},
	["Red"]=	{r = 1,		g = 0,		b = .08,a = .7},
	["Light_Blue"]=	{r = 0,	g = .5,		b = 1,	a = .7},
}
local GetFactionDetails = function(name)
	if (not name) then
		return
	end
	local description = " "
	for i = 1, GetNumFactions() do
		if name == GetFactionInfo(i) then
			_, description = GetFactionInfo(i)
		end
	end
	return description
end

-- Misc Framework stuff
function module:updateScale()
	if (not SUI.DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"), "(%d+).-(%d+)")
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
		if SUI.DB.Styles.Fel.Artwork["bar" .. i].enable then
			_G["Fel_Bar" .. i]:Show()
			_G["Fel_Bar" .. i]:SetAlpha(SUI.DB.Styles.Fel.Artwork["bar" .. i].alpha)
		else
			_G["Fel_Bar" .. i]:Hide()
		end
		if SUI.DB.Styles.Fel.Artwork.Stance.enable then
			_G["Fel_StanceBar"]:Show()
			_G["Fel_StanceBar"]:SetAlpha(SUI.DB.Styles.Fel.Artwork.Stance.alpha)
		else
			_G["Fel_StanceBar"]:Hide()
		end
		if SUI.DB.Styles.Fel.Artwork.MenuBar.enable then
			_G["Fel_MenuBar"]:Show()
			_G["Fel_MenuBar"]:SetAlpha(SUI.DB.Styles.Fel.Artwork.MenuBar.alpha)
		else
			_G["Fel_MenuBar"]:Hide()
		end
	end
end

function module:updateOffset()
	local fubar, ChocolateBar, titan, offset = 0, 0, 0, 0

	if not SUI.DB.yoffsetAuto then
		offset = max(SUI.DB.yoffset, 0)
	else
		for i = 1, 4 do -- FuBar Offset
			if (_G["FuBarFrame" .. i] and _G["FuBarFrame" .. i]:IsVisible()) then
				local bar = _G["FuBarFrame" .. i]
				local point = bar:GetPoint(1)
				if point == "BOTTOMLEFT" then
					fubar = fubar + bar:GetHeight()
				end
			end
		end
		for i = 1, 100 do -- Chocolate Bar Offset
			if (_G["ChocolateBar" .. i] and _G["ChocolateBar" .. i]:IsVisible()) then
				local bar = _G["ChocolateBar" .. i]
				local point = bar:GetPoint(1)
				--if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
				if point == "RIGHT" then
					ChocolateBar = ChocolateBar + bar:GetHeight()
				end
			 -- bottom bars
			end
		end
		TitanBarOrder = {[1] = "AuxBar2", [2] = "AuxBar"} -- Bottom 2 Bar names
		for i = 1, 2 do -- Titan Bar Offset
			if (_G["Titan_Bar__Display_" .. TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i] .. "_Show")) then
				local PanelScale = TitanPanelGetVar("Scale") or 1
				local bar = _G["Titan_Bar__Display_" .. TitanBarOrder[i]]
				titan = titan + (PanelScale * bar:GetHeight())
			end
		end

		offset = max(fubar + titan + ChocolateBar, 1)
		SUI.DB.yoffset = offset
	end

	Fel_SpartanUI.Left:ClearAllPoints()
	if SUI.DB.Styles.Fel.SubTheme == "War" then
		-- Fel_SpartanUI.Left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, offset)
		-- Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, offset)
		Fel_SpartanUI.Left:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, offset)
	else
		Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 0, offset)
	end

	Fel_ActionBarPlate:ClearAllPoints()
	Fel_ActionBarPlate:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, offset)
end

--	Module Calls
function module:TooltipLoc(self, parent)
	if (parent == "UIParent") then
		tooltip:ClearAllPoints()
		tooltip:SetPoint("BOTTOMRIGHT", "Fel_SpartanUI", "TOPRIGHT", 0, 10)
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints()
	BuffFrame:SetPoint("TOPRIGHT", -13, -13 - (SUI.DB.BuffSettings.offset))
end

function module:SetupVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		petbattle:HookScript(
			"OnHide",
			function()
				Fel_SpartanUI:Hide()
				Minimap:Hide()
			end
		)
		petbattle:HookScript(
			"OnShow",
			function()
				Fel_SpartanUI:Show()
				Minimap:Show()
			end
		)
		RegisterStateDriver(petbattle, "visibility", "[petbattle] hide; show")
		RegisterStateDriver(Fel_SpartanUI, "visibility", "[overridebar][vehicleui] hide; show")
	end
end

function module:RemoveVehicleUI()
	if SUI.DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(petbattle, "visibility")
		UnRegisterStateDriver(Fel_SpartanUI, "visibility")
	end
end

function module:InitArtwork()
	--if (Bartender4.db:GetCurrentProfile() == SUI.DB.Styles.Transparent.BartenderProfile or not Artwork_Core:BartenderProfileCheck(SUI.DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates("Fel_ActionBarPlate")
	--end

	do -- create bar anchor
		plate = CreateFrame("Frame", "Fel_ActionBarPlate", UIParent, "Fel_ActionBarsTemplate")
		plate:SetFrameStrata("BACKGROUND")
		plate:SetFrameLevel(1)
		plate:SetPoint("BOTTOM")
	end

	FramerateText:ClearAllPoints()
	FramerateText:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
end

function module:EnableArtwork()
	Fel_SpartanUI:SetFrameStrata("BACKGROUND")
	Fel_SpartanUI:SetFrameLevel(1)

	-- Fel_SpartanUI.Harambe = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Harambe", "BORDER")
	-- Fel_SpartanUI.Harambe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	-- Fel_SpartanUI.Harambe:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	-- Fel_SpartanUI.Harambe:SetTexture([[interface\addons\SpartanUI_Artwork\Themes\harambe\glory]])
	-- Fel_SpartanUI.Harambe:SetAlpha(.45)

	Fel_SpartanUI.Left = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Left", "BORDER")
	Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 0, 0)

	Fel_SpartanUI.Right = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Right", "BORDER")
	Fel_SpartanUI.Right:SetPoint("LEFT", Fel_SpartanUI.Left, "RIGHT", 0, 0)

	if SUI.DB.Styles.Fel.SubTheme == "Digital" then
		Fel_SpartanUI.Left:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Base_Bar_Left]])
		Fel_SpartanUI.Right:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Base_Bar_Right]])
		Fel_Bar1BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar2BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar3BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar4BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_MenuBarBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_StanceBarBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
	elseif SUI.DB.Styles.Fel.SubTheme == "War" then
		Fel_SpartanUI.Left:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\War\Art]])
		Fel_SpartanUI.Left:ClearAllPoints()
		Fel_SpartanUI.Left:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
		-- Fel_SpartanUI.Right:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\War\Base_Bar_Horde]])
		Fel_Bar1BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar2BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar3BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_Bar4BG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_MenuBarBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
		Fel_StanceBarBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Fel-Box]])
	else
		Fel_SpartanUI.Left:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Left]])
		Fel_SpartanUI.Right:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Right]])
	end
	module:updateOffset()

	hooksecurefunc(
		"UIParent_ManageFramePositions",
		function()
			TutorialFrameAlertButton:SetParent(Minimap)
			TutorialFrameAlertButton:ClearAllPoints()
			TutorialFrameAlertButton:SetPoint("CENTER", Minimap, "TOP", -2, 30)
			CastingBarFrame:ClearAllPoints()
			CastingBarFrame:SetPoint("BOTTOM", Fel_SpartanUI, "TOP", 0, 90)
		end
	)

	MainMenuBarVehicleLeaveButton:HookScript(
		"OnShow",
		function()
			MainMenuBarVehicleLeaveButton:ClearAllPoints()
			MainMenuBarVehicleLeaveButton:SetPoint("LEFT", SUI_playerFrame, "RIGHT", 15, 0)
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

-- Status Bars
local SetXPColors = function(self)
	local FrameName = self:GetName()
	-- Set Gained Color
	if SUI.DB.StatusBars.XPBar.GainedColor ~= "Custom" then
		SUI.DB.StatusBars.XPBar.GainedRed = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].r
		SUI.DB.StatusBars.XPBar.GainedBlue = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].b
		SUI.DB.StatusBars.XPBar.GainedGreen = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].g
		SUI.DB.StatusBars.XPBar.GainedBrightness = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].a
	end

	local r, b, g, a
	r = SUI.DB.StatusBars.XPBar.GainedRed
	b = SUI.DB.StatusBars.XPBar.GainedBlue
	g = SUI.DB.StatusBars.XPBar.GainedGreen
	a = SUI.DB.StatusBars.XPBar.GainedBrightness
	_G[FrameName .. "Fill"]:SetVertexColor(r, g, b, a)
	_G[FrameName .. "FillGlow"]:SetVertexColor(r, g, b, (a - .2))

	-- Set Rested Color
	if SUI.DB.StatusBars.XPBar.RestedMatchColor then
		SUI.DB.StatusBars.XPBar.RestedRed = SUI.DB.StatusBars.XPBar.GainedRed
		SUI.DB.StatusBars.XPBar.RestedBlue = SUI.DB.StatusBars.XPBar.GainedBlue
		SUI.DB.StatusBars.XPBar.RestedGreen = SUI.DB.StatusBars.XPBar.GainedGreen
		SUI.DB.StatusBars.XPBar.RestedBrightness = 1
		SUI.DB.StatusBars.XPBar.RestedColor = SUI.DB.StatusBars.XPBar.GainedColor
	elseif SUI.DB.StatusBars.XPBar.RestedColor ~= "Custom" then
		SUI.DB.StatusBars.XPBar.RestedRed = COLORS[SUI.DB.StatusBars.XPBar.RestedColor].r
		SUI.DB.StatusBars.XPBar.RestedBlue = COLORS[SUI.DB.StatusBars.XPBar.RestedColor].b
		SUI.DB.StatusBars.XPBar.RestedGreen = COLORS[SUI.DB.StatusBars.XPBar.RestedColor].g
		SUI.DB.StatusBars.XPBar.RestedBrightness = COLORS[SUI.DB.StatusBars.XPBar.RestedColor].a
	end
	r = SUI.DB.StatusBars.XPBar.RestedRed
	b = SUI.DB.StatusBars.XPBar.RestedBlue
	g = SUI.DB.StatusBars.XPBar.RestedGreen
	a = SUI.DB.StatusBars.XPBar.RestedBrightness
	_G[FrameName .. "Lead"]:SetVertexColor(r, g, b, a)
	_G[FrameName .. "LeadGlow"]:SetVertexColor(r, g, b, (a + .1))
end
local SetRepColors = function(self)
	local FrameName = self:GetName()
	local ratio, name, reaction, low, high, current = 0, GetWatchedFactionInfo()
	if SUI.DB.StatusBars.RepBar.AutoDefined == true then
		local color = FACTION_BAR_COLORS[reaction] or FACTION_BAR_COLORS[7]
		_G[FrameName .. "Fill"]:SetVertexColor(color.r, color.g, color.b, 0.7)
		_G[FrameName .. "FillGlow"]:SetVertexColor(color.r, color.g, color.b, 0.2)
	else
		local r, b, g, a
		r = SUI.DB.StatusBars.RepBar.GainedRed
		b = SUI.DB.StatusBars.RepBar.GainedBlue
		g = SUI.DB.StatusBars.RepBar.GainedGreen
		a = SUI.DB.StatusBars.RepBar.GainedBrightness
		_G[FrameName .. "Fill"]:SetVertexColor(r, g, b, a)
		_G[FrameName .. "FillGlow"]:SetVertexColor(r, g, b, a)
	end
end

local updateText = function(self, side)
	local FrameName = self:GetName()
	-- Reset graphically to avoid issues
	_G[FrameName .. "Fill"]:SetWidth(0.1)
	_G[FrameName .. "FillGlow"]:SetWidth(.1)
	_G[FrameName .. "Lead"]:SetWidth(0.1)
	--Reset Text
	_G[FrameName .. "Text"]:SetText("")

	if (SUI.DB.StatusBars[side] == "xp") then
		local level, rested, now, goal = UnitLevel("player"), GetXPExhaustion() or 0, UnitXP("player"), UnitXPMax("player")
		if now ~= 0 then
			_G[FrameName .. "Fill"]:SetWidth((now / goal) * self:GetWidth())
			rested = (rested / goal) * 400
			if (rested + _G[FrameName .. "Fill"]:GetWidth()) > 399 then
				rested = self:GetWidth() - _G[FrameName .. "Fill"]:GetWidth()
			end
			if rested == 0 then
				rested = .001
			end
			_G[FrameName .. "Lead"]:SetWidth(rested)
		end
		if SUI.DB.StatusBars.XPBar.text then
			_G[FrameName .. "Text"]:SetFormattedText(
				"( %s / %s ) %d%%",
				SUI:comma_value(now),
				SUI:comma_value(goal),
				(UnitXP("player") / UnitXPMax("player") * 100)
			)
		else
			_G[FrameName .. "Text"]:SetText("")
		end
		SetXPColors(self)
	elseif (SUI.DB.StatusBars[side] == "rep") then
		local ratio, name, reaction, low, high, current = 0, GetWatchedFactionInfo()
		if name then
			ratio = (current - low) / (high - low)
		end
		if ratio == 0 then
			_G[FrameName .. "Fill"]:SetWidth(0.1)
		else
			_G[FrameName .. "Fill"]:SetWidth(ratio * self:GetWidth())
		end
		if SUI.DB.StatusBars.RepBar.text then
			_G[FrameName .. "Text"]:SetFormattedText(
				"( %s / %s ) %d%%",
				SUI:comma_value(current - low),
				SUI:comma_value(high - low),
				ratio * 100
			)
		else
			_G[FrameName .. "Text"]:SetText("")
		end
		SetRepColors(self)
	elseif (SUI.DB.StatusBars[side] == "ap") then
		_G[FrameName .. "Text"]:SetText("")
		if HasArtifactEquipped() and not C_ArtifactUI.IsEquippedArtifactMaxed() then
			local _, _, name, _, xp, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
			local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier)
			if xpForNextPoint == 0 then
				return
			end
			local ratio = (xp / xpForNextPoint)
			if ratio == 0 then
				_G[FrameName .. "Fill"]:SetWidth(0.1)
			else
				if (ratio * self:GetWidth()) > self:GetWidth() then
					_G[FrameName .. "Fill"]:SetWidth(self:GetWidth())
				else
					_G[FrameName .. "Fill"]:SetWidth(ratio * self:GetWidth())
				end
			end
			if SUI.DB.StatusBars.APBar.text then
				_G[FrameName .. "Text"]:SetFormattedText(
					"( %s / %s ) %d%%",
					SUI:comma_value(xp),
					SUI:comma_value(xpForNextPoint),
					ratio * 100
				)
			else
				_G[FrameName .. "Text"]:SetText("")
			end
			_G[FrameName .. "Fill"]:SetVertexColor(1, 0.8, 0, 0.7)
		end
	elseif (SUI.DB.StatusBars[side] == "az") then
		_G[FrameName .. "Text"]:SetText("")
		if C_AzeriteItem.HasActiveAzeriteItem() then
			local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
			if (not azeriteItemLocation) then
				return
			end
			-- local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation);
			local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
			local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
			local xpToNextLevel = totalLevelXP - xp
			local ratio = (xp / totalLevelXP)
			if ratio == 0 then
				_G[FrameName .. "Fill"]:SetWidth(0.1)
			else
				if (ratio * self:GetWidth()) > self:GetWidth() then
					_G[FrameName .. "Fill"]:SetWidth(self:GetWidth())
				else
					_G[FrameName .. "Fill"]:SetWidth(ratio * self:GetWidth())
				end
			end

			if SUI.DB.StatusBars.AzeriteBar.text then
				_G[FrameName .. "Text"]:SetFormattedText(
					"( %s / %s ) %d%%",
					SUI:comma_value(xp),
					SUI:comma_value(xpToNextLevel),
					ratio * 100
				)
			else
				_G[FrameName .. "Text"]:SetText("")
			end
		end
	elseif (SUI.DB.StatusBars[side] == "honor") then
		if SUI.DB.StatusBars.HonorBar.text then
			local itemID,
				altItemID,
				name,
				icon,
				xp,
				pointsSpent,
				quality,
				HonorAppearanceID,
				appearanceModID,
				itemAppearanceID,
				altItemAppearanceID,
				altOnTop = C_HonorUI.GetEquippedHonorInfo()
			local xpForNextPoint = C_HonorUI.GetCostForPointAtRank(pointsSpent)
			local ratio = (xp / xpForNextPoint)
			_G[FrameName .. "Text"]:SetFormattedText(
				"( %s / %s ) %d%%",
				SUI:comma_value(xp),
				SUI:comma_value(xpForNextPoint),
				ratio * 100
			)
		else
			_G[FrameName .. "Text"]:SetText("")
		end
	end
end

function module:StatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame", "Fel_StatusBarTooltip", SpartanUI, "Fel_StatusBars_TooltipTemplate")
		Fel_StatusBarTooltipHeader:SetJustifyH("LEFT")
		Fel_StatusBarTooltipText:SetJustifyH("LEFT")
		Fel_StatusBarTooltipText:SetJustifyV("TOP")
		SUI:FormatFont(Fel_StatusBarTooltipHeader, 12, "Core")
		SUI:FormatFont(Fel_StatusBarTooltipText, 10, "Core")
	end

	local showXPTooltip = function(self)
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1, "\n", " ") -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% " .. COMBAT_XP_GAIN -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26 .. " (%d%%) -" -- Rested (%d%%) -
		local a = format("Level %s ", UnitLevel("player"))
		local b =
			format(
			XP_LEVEL_TEMPLATE,
			SUI:comma_value(UnitXP("player")),
			SUI:comma_value(UnitXPMax("player")),
			(UnitXP("player") / UnitXPMax("player") * 100)
		)
		Fel_StatusBarTooltipHeader:SetText(a .. b) -- Level 99 (9999 / 9999) 100% Experience
		local rested, text = GetXPExhaustion() or 0
		if (rested > 0) then
			text = format(xptip1, format(xprest, (rested / UnitXPMax("player")) * 100), 200)
			Fel_StatusBarTooltipText:SetText(text) -- Rested (15%) - 200% of normal experience gained from monsters.
		else
			Fel_StatusBarTooltipText:SetText(format(xptip1, EXHAUST_TOOLTIP2, 100)) -- You should rest at an Inn. 100% of normal experience gained from monsters.
		end
		tooltip:Show()
	end
	local showRepTooltip = function(self)
		local name, react, low, high, current, text, ratio = GetWatchedFactionInfo()
		if name then
			text = GetFactionDetails(name)
			ratio = (current - low) / (high - low)
			Fel_StatusBarTooltipHeader:SetText(
				format(
					"%s ( %s / %s ) %d%% %s",
					name,
					SUI:comma_value(current - low),
					SUI:comma_value(high - low),
					ratio * 100,
					_G["FACTION_STANDING_LABEL" .. react]
				)
			)
			Fel_StatusBarTooltipText:SetText("|cffffd200" .. text .. "|r")
		else
			Fel_StatusBarTooltipHeader:SetText(REPUTATION)
			Fel_StatusBarTooltipText:SetText(REPUTATION_STANDING_DESCRIPTION)
		end
		tooltip:Show()
	end
	local showAPTooltip = function(self)
		local FrameName = self:GetName()
		if HasArtifactEquipped() and not C_ArtifactUI.IsEquippedArtifactMaxed() then
			local _, _, name, _, xp, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
			local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier)
			if xpForNextPoint == 0 then
				return
			end
			local ratio = (xp / xpForNextPoint)

			Fel_StatusBarTooltipHeader:SetText(name)
			Fel_StatusBarTooltipText:SetFormattedText(
				"( %s / %s ) %d%%",
				SUI:comma_value(xp),
				SUI:comma_value(xpForNextPoint),
				ratio * 100
			)
		else
			Fel_StatusBarTooltipHeader:SetText("No Artifact equiped")
			Fel_StatusBarTooltipText:SetText("")
		end
		tooltip:Show()
	end
	local showAzeriteTooltip = function(self)
		if C_AzeriteItem.HasActiveAzeriteItem() then
			local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
			if (not azeriteItemLocation) then
				return
			end
			local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation)
			local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
			local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
			local xpToNextLevel = totalLevelXP - xp
			local ratio = (xp / totalLevelXP)
			Fel_StatusBarTooltipHeader:SetText(
				AZERITE_POWER_TOOLTIP_TITLE:format(currentLevel, xpToNextLevel),
				HIGHLIGHT_FONT_COLOR:GetRGB()
			)
			Fel_StatusBarTooltipText:SetText(AZERITE_POWER_TOOLTIP_BODY:format(azeriteItem:GetItemName()))
		end
		tooltip:Show()
	end

	Fel_StatusBar_LeftPlate:SetTexCoord(0.17, 0.97, 0, 1)
	Fel_StatusBar_Left:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Left:RegisterEvent("ARTIFACT_XP_UPDATE")
	Fel_StatusBar_Left:RegisterEvent("UNIT_INVENTORY_CHANGED")
	Fel_StatusBar_Left:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Left:RegisterEvent("PLAYER_XP_UPDATE")
	Fel_StatusBar_Left:RegisterEvent("PLAYER_LEVEL_UP")
	Fel_StatusBar_Left:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Left:RegisterEvent("UPDATE_FACTION")
	Fel_StatusBar_Left:SetScript(
		"OnEnter",
		function(self)
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOM", Fel_StatusBar_Left, "TOP", -2, -1)
			if SUI.DB.StatusBars.left == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "hover" then
				showRepTooltip(self)
			end
			if SUI.DB.StatusBars.left == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "hover" then
				showXPTooltip(self)
			end
			if SUI.DB.StatusBars.left == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "hover" then
				showAPTooltip(self)
			end
			if SUI.DB.StatusBars.left == "az" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "click" then
				showAzeriteTooltip(self)
			end
		end
	)
	Fel_StatusBar_Left:SetScript(
		"OnMouseDown",
		function(self)
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOM", Fel_StatusBar_Left, "TOP", -2, -1)
			if SUI.DB.StatusBars.left == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "click" then
				showRepTooltip(self)
			end
			if SUI.DB.StatusBars.left == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "click" then
				showXPTooltip(self)
			end
			if SUI.DB.StatusBars.left == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "click" then
				showAPTooltip(self)
			end
			if SUI.DB.StatusBars.left == "az" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "click" then
				showAzeriteTooltip(self)
			end
		end
	)
	Fel_StatusBar_Left:SetScript(
		"OnLeave",
		function()
			tooltip:Hide()
			tooltip:ClearAllPoints()
		end
	)
	Fel_StatusBar_Left:SetScript(
		"OnEvent",
		function(self)
			updateText(self, "left")
		end
	)

	Fel_StatusBar_Right:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Right:RegisterEvent("ARTIFACT_XP_UPDATE")
	Fel_StatusBar_Right:RegisterEvent("UNIT_INVENTORY_CHANGED")
	Fel_StatusBar_Right:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Right:RegisterEvent("PLAYER_XP_UPDATE")
	Fel_StatusBar_Right:RegisterEvent("PLAYER_LEVEL_UP")
	Fel_StatusBar_Right:RegisterEvent("PLAYER_ENTERING_WORLD")
	Fel_StatusBar_Right:RegisterEvent("UPDATE_FACTION")
	Fel_StatusBar_Right:SetScript(
		"OnEnter",
		function(self)
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOM", Fel_StatusBar_Right, "TOP", -2, -1)
			if SUI.DB.StatusBars.right == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "hover" then
				showRepTooltip(self)
			end
			if SUI.DB.StatusBars.right == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "hover" then
				showXPTooltip(self)
			end
			if SUI.DB.StatusBars.right == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "hover" then
				showAPTooltip(self)
			end
			if SUI.DB.StatusBars.right == "az" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "click" then
				showAzeriteTooltip(self)
			end
		end
	)
	Fel_StatusBar_Right:SetScript(
		"OnMouseDown",
		function(self)
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOM", Fel_StatusBar_Right, "TOP", -2, -1)
			if SUI.DB.StatusBars.right == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "click" then
				showRepTooltip(self)
			end
			if SUI.DB.StatusBars.right == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "click" then
				showXPTooltip(self)
			end
			if SUI.DB.StatusBars.right == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "click" then
				showAPTooltip(self)
			end
			if SUI.DB.StatusBars.right == "az" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "click" then
				showAzeriteTooltip(self)
			end
		end
	)
	Fel_StatusBar_Right:SetScript(
		"OnLeave",
		function()
			tooltip:Hide()
			tooltip:ClearAllPoints()
		end
	)
	Fel_StatusBar_Right:SetScript(
		"OnEvent",
		function(self)
			updateText(self, "right")
		end
	)
	module:UpdateStatusBars()
end

function module:UpdateStatusBars()
	if SUI.DB.StatusBars.left ~= "disabled" then
		Fel_StatusBar_Left:Show()
		updateText(Fel_StatusBar_Left, "left")
	else
		Fel_StatusBar_Left:Hide()
	end
	if SUI.DB.StatusBars.right ~= "disabled" then
		Fel_StatusBar_Right:Show()
		updateText(Fel_StatusBar_Right, "left")
	else
		Fel_StatusBar_Right:Hide()
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
function module:MiniMap()
	Minimap:SetSize(156, 156)

	Minimap:ClearAllPoints()
	if SUI.DB.Styles.Fel.SubTheme == "War" then
		Minimap:SetPoint("CENTER", Fel_SpartanUI.Left, "CENTER", 0, -10)
	else
		Minimap:SetPoint("CENTER", Fel_SpartanUI.Left, "RIGHT", 0, -10)
	end
	Minimap:SetParent(Fel_SpartanUI)

	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints()
		Minimap.ZoneText:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -5)
		Minimap.ZoneText:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -5)
		Minimap.ZoneText:Hide()
		MinimapZoneText:Show()

		Minimap.coords:SetTextColor(1, .82, 0, 1)
	end

	-- Minimap.coords:Hide()

	QueueStatusFrame:ClearAllPoints()
	QueueStatusFrame:SetPoint("BOTTOM", Fel_SpartanUI, "TOP", 0, 100)

	Minimap.FelUpdate = function(self)
		if self.FelBG then
			self.FelBG:ClearAllPoints()
		end

		if SUI.DB.Styles.Fel.SubTheme == "Digital" then
			self.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Minimap]])
			self.FelBG:SetPoint("CENTER", self, "CENTER", 5, -1)
			self.FelBG:SetSize(256, 256)
			self.FelBG:SetBlendMode("ADD")
		else
			if SUI.DB.Styles.Fel.Minimap.Engulfed then
				self.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Engulfed]])
				self.FelBG:SetPoint("CENTER", self, "CENTER", 7, 37)
				self.FelBG:SetSize(330, 330)
				self.FelBG:SetBlendMode("ADD")
			else
				self.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Calmed]])
				self.FelBG:SetPoint("CENTER", self, "CENTER", 5, -1)
				self.FelBG:SetSize(256, 256)
				self.FelBG:SetBlendMode("ADD")
			end
		end
	end

	Minimap.FelBG = Minimap:CreateTexture(nil, "BACKGROUND")

	if SUI.DB.Styles.Fel.SubTheme == "Digital" then
		Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Digital\Minimap]])
		Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 5, -1)
		Minimap.FelBG:SetSize(256, 256)
		Minimap.FelBG:SetBlendMode("ADD")
	else
		if SUI.DB.Styles.Fel.Minimap.Engulfed then
			Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Engulfed]])
			Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 7, 37)
			Minimap.FelBG:SetSize(330, 330)
			Minimap.FelBG:SetBlendMode("ADD")
		else
			Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Calmed]])
			Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 5, -1)
			Minimap.FelBG:SetSize(256, 256)
			Minimap.FelBG:SetBlendMode("ADD")
		end
	end

	--Shape Change
	local shapechange = function(shape)
		if shape == "square" then
			Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")

			Minimap.overlay = Minimap:CreateTexture(nil, "OVERLAY")
			Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay")
			Minimap.overlay:SetAllPoints(Minimap)
			Minimap.overlay:SetBlendMode("ADD")

			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
			Minimap.FelBG:Hide()
		else
			Minimap:SetMaskTexture("Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay")
			MiniMapTracking:ClearAllPoints()
			MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, -5)
			if Minimap.overlay then
				Minimap.overlay:Hide()
			end
			Minimap.FelBG:Show()
		end
	end

	Fel_SpartanUI:HookScript(
		"OnHide",
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetParent(UIParent)
			Minimap:SetPoint("TOP", UIParent, "TOP", 0, -20)
			shapechange("square")
		end
	)

	Fel_SpartanUI:HookScript(
		"OnShow",
		function(this, event)
			Minimap:ClearAllPoints()
			Minimap:SetPoint("CENTER", Fel_SpartanUI, "CENTER", 0, 54)
			Minimap:SetParent(Fel_SpartanUI)
			shapechange("circle")
		end
	)
end
