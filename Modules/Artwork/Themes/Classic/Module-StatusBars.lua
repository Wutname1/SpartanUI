local _, SUI
spartan = _G["SUI"]
local L = spartan.L;
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Classic");
----------------------------------------------------------------------------------------------------
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

function module:SetRepColors()
	local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
	if DB.RepBar.AutoDefined == true then
		local color = FACTION_BAR_COLORS[reaction] or FACTION_BAR_COLORS[7];
		SUI_ReputationBarFill:SetVertexColor	(color.r, color.g, color.b, 0.7);
		SUI_ReputationBarFillGlow:SetVertexColor(color.r, color.g, color.b, 0.2);
	else
        local r,b,g,a

		r = DB.RepBar.GainedRed
		b = DB.RepBar.GainedBlue
		g = DB.RepBar.GainedGreen
		a = DB.RepBar.GainedBrightness
		SUI_ReputationBarFill:SetVertexColor	(r, g, b, a);
		SUI_ReputationBarFillGlow:SetVertexColor(r, g, b, a);
	end

	-- Set Text if needed
	if DB.RepBar.text then
		SUI_ReputationBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100)
	else
		SUI_ReputationBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end


function module:SetXPColors()
	-- Set Gained Color
	if DB.XPBar.GainedColor ~= "Custom" then
		DB.XPBar.GainedRed 			= COLORS[DB.XPBar.GainedColor].r
		DB.XPBar.GainedBlue 		= COLORS[DB.XPBar.GainedColor].b
		DB.XPBar.GainedGreen 		= COLORS[DB.XPBar.GainedColor].g
		DB.XPBar.GainedBrightness	= COLORS[DB.XPBar.GainedColor].a
	end
    
    local r,b,g,a
	r = DB.XPBar.GainedRed
	b = DB.XPBar.GainedBlue
	g = DB.XPBar.GainedGreen
	a = DB.XPBar.GainedBrightness
	SUI_ExperienceBarFill:SetVertexColor	(r,g,b,a);
	SUI_ExperienceBarFillGlow:SetVertexColor(r,g,b,(a-.2));

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
	SUI_ExperienceBarLead:SetVertexColor	(r,g,b,a);
	SUI_ExperienceBarLeadGlow:SetVertexColor(r,g,b,(a+.1));

	-- Update Text if needed
	if DB.XPBar.text then
		SUI_ExperienceBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
	else
		SUI_ExperienceBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:UpdateAPBar()
	-- Set Text if needed
	if DB.APBar.text then
		local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
		local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent);
		local ratio = (xp/xpForNextPoint);
		SUI_ArtifactBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(xp), spartan:comma_value(xpForNextPoint), ratio*100)
	else
		SUI_ArtifactBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:EnableStatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame","SUI_StatusBarTooltip",SpartanUI,"SUI_StatusBars_TooltipTemplate");
		SUI_StatusBarTooltipHeader:SetJustifyH("LEFT");
		SUI_StatusBarTooltipText:SetJustifyH("LEFT");
		SUI_StatusBarTooltipText:SetJustifyV("TOP");
		spartan:FormatFont(SUI_StatusBarTooltipHeader, 12, "Core")
		spartan:FormatFont(SUI_StatusBarTooltipText, 10, "Core")
	end
	do -- experience bar
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -

		SUI_ExperienceBarPlate:SetTexCoord(0.17,0.97,0,1);
		
		SUI_ExperienceBar:SetScript("OnEvent",function()
			if DB.XPBar.enabled then SUI_ExperienceBar:Show(); else SUI_ExperienceBar:Hide(); end
			local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			if now == 0 then
				SUI_ExperienceBarFill:SetWidth(0.1);
				SUI_ExperienceBarFillGlow:SetWidth(.1);
				SUI_ExperienceBarLead:SetWidth(0.1);
			else
				SUI_ExperienceBarFill:SetWidth((now/goal)*400);
				rested = (rested/goal)*400;
				if (rested+SUI_ExperienceBarFill:GetWidth()) > 399 then rested = 400-SUI_ExperienceBarFill:GetWidth(); end
				if rested == 0 then rested = .001 end
				SUI_ExperienceBarLead:SetWidth(rested);
			end
			if DB.XPBar.text then
				SUI_ExperienceBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(now), spartan:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100))
			else
				SUI_ExperienceBarText:SetText("")
			end
			module:SetXPColors()
		end);
		local showXPTooltip = function()
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",SUI_ExperienceBar,"TOP",6,-1);
			local a = format("Level %s ",UnitLevel("player"))
			local b = format(XP_LEVEL_TEMPLATE, spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
			SUI_StatusBarTooltipHeader:SetText(a..b); -- Level 99 (9999 / 9999) 100% Experience
			local rested,text = GetXPExhaustion() or 0;
			if (rested > 0) then
				text = format(xptip1,format(xprest,(rested/UnitXPMax("player"))*100),200);
				SUI_StatusBarTooltipText:SetText(text); -- Rested (15%) - 200% of normal experience gained from monsters.
			else
				SUI_StatusBarTooltipText:SetText(format(xptip1,EXHAUST_TOOLTIP2,100)); -- You should rest at an Inn. 100% of normal experience gained from monsters.
			end
			tooltip:Show();
		end
		
		SUI_ExperienceBar:SetScript("OnEnter",function() if DB.XPBar.ToolTip == "hover" then showXPTooltip(); end end);
		SUI_ExperienceBar:SetScript("OnMouseDown",function() if DB.XPBar.ToolTip == "click" then showXPTooltip(); end end);
		SUI_ExperienceBar:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		SUI_ExperienceBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		SUI_ExperienceBar:RegisterEvent("PLAYER_XP_UPDATE");
		SUI_ExperienceBar:RegisterEvent("PLAYER_LEVEL_UP");
		
		module:SetXPColors();
	end
	do -- reputation bar
		SUI_ReputationBar:SetScript("OnEvent",function()
			if DB.RepBar.enabled then SUI_ReputationBar:Show(); else SUI_ReputationBar:Hide(); end
			local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
			if name then ratio = (current-low)/(high-low); end
			SUI_StatusBarTooltipHeader:SetText(name);
			if ratio == 0 then
				SUI_ReputationBarFill:SetWidth(0.1);
			else
				SUI_ReputationBarFill:SetWidth(ratio*400);
				module:SetRepColors()
			end
			
			if DB.RepBar.text then
				SUI_ReputationBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100)
			else
				SUI_ReputationBarText:SetText("")
			end
		end);
		local showRepTooltip = function()
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",SUI_ReputationBar,"TOP",-2,-1);
			local name,react,low,high,current,text,ratio = GetWatchedFactionInfo();
			if name then
				text = GetFactionDetails(name);
				ratio = (current-low)/(high-low);
				SUI_StatusBarTooltipHeader:SetText(format("%s ( %s / %s ) %d%% %s", name, spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100,_G["FACTION_STANDING_LABEL"..react]));
				SUI_StatusBarTooltipText:SetText("|cffffd200"..text.."|r");
			else
				SUI_StatusBarTooltipHeader:SetText(REPUTATION);
				SUI_StatusBarTooltipText:SetText(REPUTATION_STANDING_DESCRIPTION);
			end
			tooltip:Show();
		end
		
		SUI_ReputationBar:SetScript("OnEnter",function() if DB.RepBar.ToolTip == "hover" then showRepTooltip(); end end);
		SUI_ReputationBar:SetScript("OnMouseDown",function() if DB.RepBar.ToolTip == "click" then showRepTooltip(); end end);
		SUI_ReputationBar:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		SUI_ReputationBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		SUI_ReputationBar:RegisterEvent("UPDATE_FACTION");
		
		module:SetRepColors();
	end
	do -- Artifact Power bar
		SUI_ArtifactBar:SetScript("OnEvent",function()
			--Clear Text
			SUI_ArtifactBarText:SetText("")
			--Update if needed
			if HasArtifactEquipped() then
				local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
				-- local currentArtifactPurchasableTraits = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, xp);
				local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent);
				local ratio = (xp/xpForNextPoint);
				
				if ratio == 0 then
					SUI_ArtifactBarFill:SetWidth(0.1);
				else
					if (ratio*SUI_ArtifactBar:GetWidth()) > SUI_ArtifactBar:GetWidth() then
						SUI_ArtifactBarFill:SetWidth(SUI_ArtifactBar:GetWidth())
					else
						SUI_ArtifactBarFill:SetWidth(ratio*SUI_ArtifactBar:GetWidth());
					end
				end
				
				if DB.APBar.text then
					SUI_ArtifactBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(xp), spartan:comma_value(xpForNextPoint), ratio*100)
				else
					SUI_ArtifactBarText:SetText("")
				end
			end
		end);
		
		SUI_ArtifactBarFill:SetVertexColor()
		SUI_ArtifactBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		SUI_ArtifactBar:RegisterEvent("ARTIFACT_XP_UPDATE");
		SUI_ArtifactBar:RegisterEvent("UNIT_INVENTORY_CHANGED");
	end
end

function module:UpdateStatusBars()
	if DB.XPBar.enabled then SUI_ExperienceBar:Show(); else SUI_ExperienceBar:Hide(); end
	if DB.RepBar.enabled then SUI_ReputationBar:Show(); else SUI_ReputationBar:Hide(); end
	if DB.APBar.enabled then SUI_ArtifactBar:Show(); else SUI_ArtifactBar:Hide(); end
end