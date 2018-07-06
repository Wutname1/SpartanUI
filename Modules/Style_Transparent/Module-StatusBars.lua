local SUI = SUI
local module = SUI:GetModule("Style_Transparent")
----------------------------------------------------------------------------------------------------
local xpframe

local COLORS = {
	["Orange"] = {r = 1, g = 0.2, b = 0, a = .7},
	["Yellow"] = {r = 1, g = 0.8, b = 0, a = .7},
	["Green"] = {r = 0, g = 1, b = .1, a = .7},
	["Blue"] = {r = 0, g = .1, b = 1, a = .7},
	["Pink"] = {r = 1, g = 0, b = .4, a = .7},
	["Purple"] = {r = 1, g = 0, b = 1, a = .5},
	["Red"] = {r = 1, g = 0, b = .08, a = .7},
	["Light_Blue"] = {r = 0, g = .5, b = 1, a = .7}
}

function module:InitStatusBars()
end

function module:SetXPColors()
	-- Set Gained Color
	if SUI.DB.StatusBars.XPBar.GainedColor ~= "Custom" then
		SUI.DB.StatusBars.XPBar.GainedRed = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].r
		SUI.DB.StatusBars.XPBar.GainedBlue = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].b
		SUI.DB.StatusBars.XPBar.GainedGreen = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].g
		SUI.DB.StatusBars.XPBar.GainedBrightness = COLORS[SUI.DB.StatusBars.XPBar.GainedColor].a
	end
	r = SUI.DB.StatusBars.XPBar.GainedRed
	b = SUI.DB.StatusBars.XPBar.GainedBlue
	g = SUI.DB.StatusBars.XPBar.GainedGreen
	a = SUI.DB.StatusBars.XPBar.GainedBrightness
	Transparent_ExperienceBarFill:SetVertexColor(r, g, b, a)
	Transparent_ExperienceBarFillGlow:SetVertexColor(r, g, b, (a - .3))

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
	Transparent_ExperienceBarLead:SetVertexColor(r, g, b, a)
	Transparent_ExperienceBarLeadGlow:SetVertexColor(r, g, b, (a + .2))

	-- Update Text if needed
	if SUI.DB.StatusBars.XPBar.text then
		xpframe.Text:SetFormattedText(
			"( %s / %s ) %d%%",
			SUI:comma_value(UnitXP("player")),
			SUI:comma_value(UnitXPMax("player")),
			(UnitXP("player") / UnitXPMax("player") * 100)
		)
	else
		xpframe.Text:SetText("")
	end
end

function module:EnableStatusBars()
	do -- create the tooltip
		tooltip =
			CreateFrame("Frame", "Transparent_StatusBarTooltip", Transparent_SpartanUI, "Transparent_StatusBars_TooltipTemplate")
		Transparent_StatusBarTooltipHeader:SetJustifyH("LEFT")
		Transparent_StatusBarTooltipText:SetJustifyH("LEFT")
		Transparent_StatusBarTooltipText:SetJustifyV("TOP")
		SUI:FormatFont(Transparent_StatusBarTooltipHeader, 12, "Core")
		SUI:FormatFont(Transparent_StatusBarTooltipText, 10, "Core")
	end
	do -- experience bar
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1, "\n", " ") -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% " .. COMBAT_XP_GAIN -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26 .. " (%d%%) -" -- Rested (%d%%) -

		xpframe =
			CreateFrame("Frame", "Transparent_ExperienceBar", Transparent_SpartanUI, "Transparent_StatusBars_XPTemplate")
		xpframe:SetPoint("BOTTOMRIGHT", "Transparent_SpartanUI", "BOTTOM", -100, 0)

		xpframe:SetScript(
			"OnEvent",
			function()
				if SUI.DB.StatusBars.XPBar.enabled and not xpframe:IsVisible() then
					xpframe:Show()
				elseif not SUI.DB.StatusBars.XPBar.enabled then
					xpframe:Hide()
				end
				local _, rested, now, goal = UnitLevel("player"), GetXPExhaustion() or 0, UnitXP("player"), UnitXPMax("player")
				if now == 0 then
					Transparent_ExperienceBarFill:SetWidth(0.1)
					Transparent_ExperienceBarFillGlow:SetWidth(.1)
					Transparent_ExperienceBarLead:SetWidth(0.1)
				else
					Transparent_ExperienceBarFill:SetWidth((now / goal) * 400)
					rested = (rested / goal) * 400
					if (rested + Transparent_ExperienceBarFill:GetWidth()) > 399 then
						rested = 400 - Transparent_ExperienceBarFill:GetWidth()
					end
					if rested == 0 then
						rested = .001
					end
					Transparent_ExperienceBarLead:SetWidth(rested)
				end
				if SUI.DB.StatusBars.XPBar.text then
					xpframe.Text:SetFormattedText(
						"( %s / %s ) %d%%",
						SUI:comma_value(now),
						SUI:comma_value(goal),
						(UnitXP("player") / UnitXPMax("player") * 100)
					)
				else
					xpframe.Text:SetText("")
				end
				module:SetXPColors()
			end
		)
		local showXPTooltip = function()
			tooltip:ClearAllPoints()
			tooltip:SetPoint("BOTTOM", xpframe, "TOP", 6, -1)
			local a = format("Level %s ", UnitLevel("player"))
			local b =
				format(
				XP_LEVEL_TEMPLATE,
				SUI:comma_value(UnitXP("player")),
				SUI:comma_value(UnitXPMax("player")),
				(UnitXP("player") / UnitXPMax("player") * 100)
			)
			Transparent_StatusBarTooltipHeader:SetText(a .. b) -- Level 99 (9999 / 9999) 100% Experience
			local rested, text = GetXPExhaustion() or 0
			if (rested > 0) then
				text = format(xptip1, format(xprest, (rested / UnitXPMax("player")) * 100), 200)
				Transparent_StatusBarTooltipText:SetText(text) -- Rested (15%) - 200% of normal experience gained from monsters.
			else
				Transparent_StatusBarTooltipText:SetText(format(xptip1, EXHAUST_TOOLTIP2, 100)) -- You should rest at an Inn. 100% of normal experience gained from monsters.
			end
			tooltip:Show()
		end

		xpframe.Text = xpframe:CreateFontString()
		SUI:FormatFont(xpframe.Text, 10, "Core")
		xpframe.Text:SetDrawLayer("OVERLAY")
		xpframe.Text:SetSize(250, 10)
		xpframe.Text:SetJustifyH("MIDDLE")
		xpframe.Text:SetJustifyV("MIDDLE")
		xpframe.Text:SetPoint("TOP", xpframe, "TOP", 0, 0)

		xpframe:SetScript(
			"OnEnter",
			function()
				if SUI.DB.StatusBars.XPBar.ToolTip == "hover" then
					showXPTooltip()
				end
			end
		)
		xpframe:SetScript(
			"OnMouseDown",
			function()
				if SUI.DB.StatusBars.XPBar.ToolTip == "click" then
					showXPTooltip()
				end
			end
		)
		xpframe:SetScript(
			"OnLeave",
			function()
				tooltip:Hide()
			end
		)

		xpframe:RegisterEvent("PLAYER_ENTERING_WORLD")
		xpframe:RegisterEvent("PLAYER_XP_UPDATE")
		xpframe:RegisterEvent("PLAYER_LEVEL_UP")

		xpframe:SetFrameStrata("BACKGROUND")
		xpframe:SetFrameLevel(2)
		module:SetXPColors()
	end
end
