local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Transparent");
----------------------------------------------------------------------------------------------------
local xpframe, repframe;
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
	if (not name) then return; end
	local description = " ";
	for i = 1,GetNumFactions() do
		if name == GetFactionInfo(i) then
			_,description = GetFactionInfo(i)
		end
	end
	return description;
end

function module:InitStatusBars()
end

function module:SetXPColors()
	-- Set Gained Color
	if DB.XPBar.GainedColor ~= "Custom" then
		DB.XPBar.GainedRed 			= COLORS[DB.XPBar.GainedColor].r
		DB.XPBar.GainedBlue 		= COLORS[DB.XPBar.GainedColor].b
		DB.XPBar.GainedGreen 		= COLORS[DB.XPBar.GainedColor].g
		DB.XPBar.GainedBrightness	= COLORS[DB.XPBar.GainedColor].a
	end
	r = DB.XPBar.GainedRed
	b = DB.XPBar.GainedBlue
	g = DB.XPBar.GainedGreen
	a = DB.XPBar.GainedBrightness
	Transparent_ExperienceBarFill:SetVertexColor	(r,g,b,a);
	Transparent_ExperienceBarFillGlow:SetVertexColor(r,g,b,(a-.3));

	-- Set Rested Color
	if DB.XPBar.RestedMatchColor then
		DB.XPBar.RestedRed 			= DB.XPBar.GainedRed
		DB.XPBar.RestedBlue 		= DB.XPBar.GainedBlue
		DB.XPBar.RestedGreen 		= DB.XPBar.GainedGreen
		DB.XPBar.RestedBrightness	= 1
		DB.XPBar.RestedColor		= DB.XPBar.GainedColor
	elseif DB.XPBar.RestedColor ~= "Custom" then
		DB.XPBar.RestedRed 			= COLORS[DB.XPBar.RestedColor].r
		DB.XPBar.RestedBlue 		= COLORS[DB.XPBar.RestedColor].b
		DB.XPBar.RestedGreen 		= COLORS[DB.XPBar.RestedColor].g
		DB.XPBar.RestedBrightness	= COLORS[DB.XPBar.RestedColor].a
	end
	r = DB.XPBar.RestedRed
	b = DB.XPBar.RestedBlue
	g = DB.XPBar.RestedGreen
	a = DB.XPBar.RestedBrightness
	Transparent_ExperienceBarLead:SetVertexColor	(r,g,b,a);
	Transparent_ExperienceBarLeadGlow:SetVertexColor(r,g,b,(a+.2));

	-- Update Text if needed
	if DB.XPBar.text then xpframe.Text:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100)) else xpframe.Text:SetText("") end
end

function module:EnableStatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame","Transparent_StatusBarTooltip",Transparent_SpartanUI,"Transparent_StatusBars_TooltipTemplate");
		Transparent_StatusBarTooltipHeader:SetJustifyH("LEFT");
		Transparent_StatusBarTooltipText:SetJustifyH("LEFT");
		Transparent_StatusBarTooltipText:SetJustifyV("TOP");
		spartan:FormatFont(Transparent_StatusBarTooltipHeader, 12, "Core")
		spartan:FormatFont(Transparent_StatusBarTooltipText, 10, "Core")
	end
	do -- experience bar
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -

		xpframe = CreateFrame("Frame","Transparent_ExperienceBar",Transparent_SpartanUI,"Transparent_StatusBars_XPTemplate");
		xpframe:SetPoint("BOTTOMRIGHT","Transparent_SpartanUI","BOTTOM",-100,0);
		
		xpframe:SetScript("OnEvent",function()
			if DB.XPBar.enabled and not xpframe:IsVisible() then xpframe:Show(); elseif not DB.XPBar.enabled then xpframe:Hide(); end
			local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			if now == 0 then
				Transparent_ExperienceBarFill:SetWidth(0.1);
				Transparent_ExperienceBarFillGlow:SetWidth(.1);
				Transparent_ExperienceBarLead:SetWidth(0.1);
			else
				Transparent_ExperienceBarFill:SetWidth((now/goal)*400);
				rested = (rested/goal)*400;
				if (rested+Transparent_ExperienceBarFill:GetWidth()) > 399 then rested = 400-Transparent_ExperienceBarFill:GetWidth(); end
				if rested == 0 then rested = .001 end
				Transparent_ExperienceBarLead:SetWidth(rested);
			end
			if DB.XPBar.text then xpframe.Text:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(now), spartan:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100)) else xpframe.Text:SetText("") end
			module:SetXPColors()
		end);
		local showXPTooltip = function()
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",xpframe,"TOP",6,-1);
			local a = format("Level %s ",UnitLevel("player"))
			local b = format(XP_LEVEL_TEMPLATE, spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
			Transparent_StatusBarTooltipHeader:SetText(a..b); -- Level 99 (9999 / 9999) 100% Experience
			local rested,text = GetXPExhaustion() or 0;
			if (rested > 0) then
				text = format(xptip1,format(xprest,(rested/UnitXPMax("player"))*100),200);
				Transparent_StatusBarTooltipText:SetText(text); -- Rested (15%) - 200% of normal experience gained from monsters.
			else
				Transparent_StatusBarTooltipText:SetText(format(xptip1,EXHAUST_TOOLTIP2,100)); -- You should rest at an Inn. 100% of normal experience gained from monsters.
			end
			tooltip:Show();
		end
		
		xpframe.Text = xpframe:CreateFontString();
		spartan:FormatFont(xpframe.Text, 10, "Core")
		xpframe.Text:SetDrawLayer("OVERLAY");
		xpframe.Text:SetSize(250, 10);
		xpframe.Text:SetJustifyH("MIDDLE"); xpframe.Text:SetJustifyV("MIDDLE");
		xpframe.Text:SetPoint("TOP",xpframe,"TOP",0,0);
		
		xpframe:SetScript("OnEnter",function() if DB.XPBar.ToolTip == "hover" then showXPTooltip(); end end);
		xpframe:SetScript("OnMouseDown",function() if DB.XPBar.ToolTip == "click" then showXPTooltip(); end end);
		xpframe:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		xpframe:RegisterEvent("PLAYER_ENTERING_WORLD");
		xpframe:RegisterEvent("PLAYER_XP_UPDATE");
		xpframe:RegisterEvent("PLAYER_LEVEL_UP");
		
		xpframe:SetFrameStrata("BACKGROUND");
		xpframe:SetFrameLevel(2);
		module:SetXPColors();
	end
end
