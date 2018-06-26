local _G, SUI = _G, SUI
local L = SUI.L;
local Artwork_Core = SUI:GetModule("Artwork_Core");
local module = SUI:GetModule("Style_Classic");
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

local SetXPColors = function(self)
	local FrameName = self:GetName();
	-- Set Gained Color
	if SUI.DB.StatusBars.XPBar.GainedColor ~= "Custom" then
		SUI.DB.StatusBars.XPBar.GainedRed 			= COLORS[SUI.DB.StatusBars.XPBar.GainedColor].r
		SUI.DB.StatusBars.XPBar.GainedBlue 			= COLORS[SUI.DB.StatusBars.XPBar.GainedColor].b
		SUI.DB.StatusBars.XPBar.GainedGreen 		= COLORS[SUI.DB.StatusBars.XPBar.GainedColor].g
		SUI.DB.StatusBars.XPBar.GainedBrightness	= COLORS[SUI.DB.StatusBars.XPBar.GainedColor].a
	end
	
	local r,b,g,a
	r = SUI.DB.StatusBars.XPBar.GainedRed
	b = SUI.DB.StatusBars.XPBar.GainedBlue
	g = SUI.DB.StatusBars.XPBar.GainedGreen
	a = SUI.DB.StatusBars.XPBar.GainedBrightness
	_G[FrameName.."Fill"]:SetVertexColor	(r,g,b,a);
	_G[FrameName.."FillGlow"]:SetVertexColor(r,g,b,(a-.2));

	-- Set Rested Color
	if SUI.DB.StatusBars.XPBar.RestedMatchColor then
		SUI.DB.StatusBars.XPBar.RestedRed 			= SUI.DB.StatusBars.XPBar.GainedRed
		SUI.DB.StatusBars.XPBar.RestedBlue 			= SUI.DB.StatusBars.XPBar.GainedBlue
		SUI.DB.StatusBars.XPBar.RestedGreen 		= SUI.DB.StatusBars.XPBar.GainedGreen
		SUI.DB.StatusBars.XPBar.RestedBrightness	= 1
		SUI.DB.StatusBars.XPBar.RestedColor		= SUI.DB.StatusBars.XPBar.GainedColor
	elseif SUI.DB.StatusBars.XPBar.RestedColor ~= "Custom" then
		SUI.DB.StatusBars.XPBar.RestedRed 			= COLORS[SUI.DB.StatusBars.XPBar.RestedColor].r
		SUI.DB.StatusBars.XPBar.RestedBlue 			= COLORS[SUI.DB.StatusBars.XPBar.RestedColor].b
		SUI.DB.StatusBars.XPBar.RestedGreen 		= COLORS[SUI.DB.StatusBars.XPBar.RestedColor].g
		SUI.DB.StatusBars.XPBar.RestedBrightness	= COLORS[SUI.DB.StatusBars.XPBar.RestedColor].a
	end
	r = SUI.DB.StatusBars.XPBar.RestedRed
	b = SUI.DB.StatusBars.XPBar.RestedBlue
	g = SUI.DB.StatusBars.XPBar.RestedGreen
	a = SUI.DB.StatusBars.XPBar.RestedBrightness
	_G[FrameName.."Lead"]:SetVertexColor	(r,g,b,a);
	_G[FrameName.."LeadGlow"]:SetVertexColor(r,g,b,(a+.1));
end
local SetRepColors = function(self)
	local FrameName = self:GetName();
	local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
	if SUI.DB.StatusBars.RepBar.AutoDefined == true then
		local color = FACTION_BAR_COLORS[reaction] or FACTION_BAR_COLORS[7];
		_G[FrameName.."Fill"]:SetVertexColor	(color.r, color.g, color.b, 0.7);
		_G[FrameName.."FillGlow"]:SetVertexColor(color.r, color.g, color.b, 0.2);
	else
		local r,b,g,a
		r = SUI.DB.StatusBars.RepBar.GainedRed
		b = SUI.DB.StatusBars.RepBar.GainedBlue
		g = SUI.DB.StatusBars.RepBar.GainedGreen
		a = SUI.DB.StatusBars.RepBar.GainedBrightness
		_G[FrameName.."Fill"]:SetVertexColor	(r, g, b, a);
		_G[FrameName.."FillGlow"]:SetVertexColor(r, g, b, a);
	end
end

local updateText = function(self, side)
	local FrameName = self:GetName();
	-- Reset graphically to avoid issues
	_G[FrameName.."Fill"]:SetWidth(0.1);
	_G[FrameName.."FillGlow"]:SetWidth(.1);
	_G[FrameName.."Lead"]:SetWidth(0.1);
	--Reset Text
	_G[FrameName.."Text"]:SetText("")
	
	if (SUI.DB.StatusBars[side] == "xp") then
		local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
		if now ~= 0 then
			_G[FrameName.."Fill"]:SetWidth((now/goal)*self:GetWidth());
			rested = (rested/goal)*400;
			if (rested+_G[FrameName.."Fill"]:GetWidth()) > 399 then rested = self:GetWidth()-_G[FrameName.."Fill"]:GetWidth(); end
			if rested == 0 then rested = .001 end
			_G[FrameName.."Lead"]:SetWidth(rested);
		end
		if SUI.DB.StatusBars.XPBar.text then
			_G[FrameName.."Text"]:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(now), SUI:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100))
		else
			_G[FrameName.."Text"]:SetText("")
		end
		SetXPColors(self);
	elseif (SUI.DB.StatusBars[side] == "rep") then
		local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
		if name then ratio = (current-low)/(high-low); end
		if ratio == 0 then
			_G[FrameName.."Fill"]:SetWidth(0.1);
		else
			_G[FrameName.."Fill"]:SetWidth(ratio*self:GetWidth());
		end
		if SUI.DB.StatusBars.RepBar.text and current ~= high then
			_G[FrameName.."Text"]:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(current-low), SUI:comma_value(high-low), ratio*100)
		else
			_G[FrameName.."Text"]:SetText("")
		end
		SetRepColors(self);
	elseif (SUI.DB.StatusBars[side] == "az") then
		_G[FrameName.."Text"]:SetText("")
		print("a")
		if C_AzeriteItem.HasActiveAzeriteItem() then
			local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem(); 
			print("b")
			if (not azeriteItemLocation) then 
				return; 
			end
			print("c")
			-- local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation); 
			local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
			local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation); 
			local xpToNextLevel = totalLevelXP - xp;
			local ratio = (xp / totalLevelXP)
			if ratio == 0 then
				_G[FrameName.."Fill"]:SetWidth(0.1);
			else
				if (ratio*self:GetWidth()) > self:GetWidth() then
					_G[FrameName.."Fill"]:SetWidth(self:GetWidth())
				else
					_G[FrameName.."Fill"]:SetWidth(ratio*self:GetWidth());
				end
			end
			
			if SUI.DB.StatusBars.AzeriteBar.text then
				_G[FrameName.."Text"]:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(xp), SUI:comma_value(xpToNextLevel), ratio*100)
			else
				_G[FrameName.."Text"]:SetText("")
			end
			
		end
	elseif (SUI.DB.StatusBars[side] == "ap") then
		_G[FrameName.."Text"]:SetText("")
		if HasArtifactEquipped() and not C_ArtifactUI.IsEquippedArtifactMaxed() then
			local _, _, name, _, xp, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo();
			local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
			local ratio = (xp/xpForNextPoint);
			if ratio == 0 then
				_G[FrameName.."Fill"]:SetWidth(0.1);
			else
				if (ratio*self:GetWidth()) > self:GetWidth() then
					_G[FrameName.."Fill"]:SetWidth(self:GetWidth())
				else
					_G[FrameName.."Fill"]:SetWidth(ratio*self:GetWidth());
				end
			end
			if SUI.DB.StatusBars.APBar.text then
				_G[FrameName.."Text"]:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(xp), SUI:comma_value(xpForNextPoint), ratio*100)
			else
				_G[FrameName.."Text"]:SetText("")
			end
			_G[FrameName.."Fill"]:SetVertexColor(1, 0.8, 0, 0.7);
		end
	elseif (SUI.DB.StatusBars[side] == "honor") then
		if SUI.DB.StatusBars.HonorBar.text then
			local itemID, altItemID, name, icon, xp, pointsSpent, quality, HonorAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_HonorUI.GetEquippedHonorInfo();
			local xpForNextPoint = C_HonorUI.GetCostForPointAtRank(pointsSpent);
			local ratio = (xp/xpForNextPoint);
			_G[FrameName.."Text"]:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(xp), SUI:comma_value(xpForNextPoint), ratio*100)
		else
			_G[FrameName.."Text"]:SetText("")
		end
	end
end

function module:EnableStatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame","SUI_StatusBarTooltip",SpartanUI,"SUI_StatusBars_TooltipTemplate");
		SUI_StatusBarTooltipHeader:SetJustifyH("LEFT");
		SUI_StatusBarTooltipText:SetJustifyH("LEFT");
		SUI_StatusBarTooltipText:SetJustifyV("TOP");
		SUI:FormatFont(SUI_StatusBarTooltipHeader, 12, "Core")
		SUI:FormatFont(SUI_StatusBarTooltipText, 10, "Core")
	end

	local showXPTooltip = function(self)
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -
		local a = format("Level %s ",UnitLevel("player"))
		local b = format(XP_LEVEL_TEMPLATE, SUI:comma_value(UnitXP("player")), SUI:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
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
	local showRepTooltip = function(self)
		local name,react,low,high,current,text,ratio = GetWatchedFactionInfo();
		if name then
			text = GetFactionDetails(name);
			ratio = (current-low)/(high-low);
			SUI_StatusBarTooltipHeader:SetText(format("%s ( %s / %s ) %d%% %s", name, SUI:comma_value(current-low), SUI:comma_value(high-low), ratio*100,_G["FACTION_STANDING_LABEL"..react]));
			SUI_StatusBarTooltipText:SetText("|cffffd200"..text.."|r");
		else
			SUI_StatusBarTooltipHeader:SetText(REPUTATION);
			SUI_StatusBarTooltipText:SetText(REPUTATION_STANDING_DESCRIPTION);
		end
		tooltip:Show();
	end
	local showAPTooltip = function(self)
		local FrameName = self:GetName();
		if HasArtifactEquipped() then
			local _, _, name, _, xp, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo();
			local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent, artifactTier);
			local ratio = (xp/xpForNextPoint);
			
			SUI_StatusBarTooltipHeader:SetText(name);							
			SUI_StatusBarTooltipText:SetFormattedText("( %s / %s ) %d%%", SUI:comma_value(xp), SUI:comma_value(xpForNextPoint), ratio*100)
		else
			SUI_StatusBarTooltipHeader:SetText("No Artifact equiped");
			SUI_StatusBarTooltipText:SetText("")
		end
		tooltip:Show();
	end
	local showAzeriteTooltip = function(self)
		print("a")
		if C_AzeriteItem.HasActiveAzeriteItem() then
			local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem(); 
			if (not azeriteItemLocation) then 
				print("b")
				return; 
			end
			print("c")
			-- local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation); 
			local xp, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
			local currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation); 
			local xpToNextLevel = totalLevelXP - xp;
			local ratio = (xp / totalLevelXP)
			print("d")
			SUI_StatusBarTooltipHeader:SetText(ARTIFACT_POWER_TOOLTIP_TITLE:format(BreakUpLargeNumbers(arfifactTickParent.totalXP, true), BreakUpLargeNumbers(arfifactTickParent.xp, true), BreakUpLargeNumbers(arfifactTickParent.xpForNextPoint, true)), HIGHLIGHT_FONT_COLOR:GetRGB());
			SUI_StatusBarTooltipText:SetText(ARTIFACT_POWER_TOOLTIP_BODY:format(arfifactTickParent.numPointsAvailableToSpend), nil, nil, nil, true);
		print("e")
		end
		tooltip:Show();
	end
	
	SUI_StatusBar_LeftPlate:SetTexCoord(0.17,0.97,0,1);
	SUI_StatusBar_Left:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED");
	SUI_StatusBar_Left:RegisterEvent("PLAYER_ENTERING_WORLD");
	SUI_StatusBar_Left:RegisterEvent("ARTIFACT_XP_UPDATE");
	SUI_StatusBar_Left:RegisterEvent("UNIT_INVENTORY_CHANGED");
	SUI_StatusBar_Left:RegisterEvent("PLAYER_XP_UPDATE");
	SUI_StatusBar_Left:RegisterEvent("PLAYER_LEVEL_UP");
	SUI_StatusBar_Left:RegisterEvent("UPDATE_FACTION");
	SUI_StatusBar_Left:RegisterEvent("CVAR_UPDATE");
	SUI_StatusBar_Left:SetScript("OnEnter",function(self)
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOM",SUI_StatusBar_Left,"TOP",-2,-1);
		if SUI.DB.StatusBars.left == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "hover" then showRepTooltip(self); end
		if SUI.DB.StatusBars.left == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "hover" then showXPTooltip(self); end
		if SUI.DB.StatusBars.left == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "hover" then showAPTooltip(self); end
		if SUI.DB.StatusBars.left == "AzeriteBar" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "hover" then showAzeriteTooltip(self); end
	end);
	SUI_StatusBar_Left:SetScript("OnMouseDown",function(self)
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOM",SUI_StatusBar_Left,"TOP",-2,-1);
		if SUI.DB.StatusBars.left == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "click" then showRepTooltip(self); end
		if SUI.DB.StatusBars.left == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "click" then showXPTooltip(self); end
		if SUI.DB.StatusBars.left == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "click" then showAPTooltip(self); end
		if SUI.DB.StatusBars.left == "AzeriteBar" and SUI.DB.StatusBars.AzeriteBar.ToolTip == "click" then showAzeriteTooltip(self); end
	end);
	SUI_StatusBar_Left:SetScript("OnLeave",function() tooltip:Hide(); tooltip:ClearAllPoints(); end);
	SUI_StatusBar_Left:SetScript("OnEvent",function(self) updateText(self, "left") end)
		
	SUI_StatusBar_Right:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED");
	SUI_StatusBar_Right:RegisterEvent("PLAYER_ENTERING_WORLD");
	SUI_StatusBar_Right:RegisterEvent("ARTIFACT_XP_UPDATE");
	SUI_StatusBar_Right:RegisterEvent("UNIT_INVENTORY_CHANGED");
	SUI_StatusBar_Right:RegisterEvent("PLAYER_XP_UPDATE");
	SUI_StatusBar_Right:RegisterEvent("PLAYER_LEVEL_UP");
	SUI_StatusBar_Right:RegisterEvent("UPDATE_FACTION");
	SUI_StatusBar_Right:RegisterEvent("CVAR_UPDATE");
	SUI_StatusBar_Right:SetScript("OnEnter",function(self)
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOM",SUI_StatusBar_Right,"TOP",-2,-1);
		if SUI.DB.StatusBars.right == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "hover" then showRepTooltip(self); end
		if SUI.DB.StatusBars.right == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "hover" then showXPTooltip(self); end
		if SUI.DB.StatusBars.right == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "hover" then showAPTooltip(self); end
		if SUI.DB.StatusBars.right == "AzeriteBar" and SUI.DB.StatusBars.APBar.ToolTip == "hover" then showAzeriteTooltip(self); end
	end);
	SUI_StatusBar_Right:SetScript("OnMouseDown",function(self)
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOM",SUI_StatusBar_Right,"TOP",-2,-1);
		if SUI.DB.StatusBars.right == "rep" and SUI.DB.StatusBars.RepBar.ToolTip == "click" then showRepTooltip(self); end
		if SUI.DB.StatusBars.right == "xp" and SUI.DB.StatusBars.XPBar.ToolTip == "click" then showXPTooltip(self); end
		if SUI.DB.StatusBars.right == "ap" and SUI.DB.StatusBars.APBar.ToolTip == "click" then showAPTooltip(self); end
		if SUI.DB.StatusBars.right == "AzeriteBar" and SUI.DB.StatusBars.APBar.ToolTip == "click" then showAzeriteTooltip(self); end
	end);
	SUI_StatusBar_Right:SetScript("OnLeave",function() tooltip:Hide(); tooltip:ClearAllPoints(); end);
	SUI_StatusBar_Right:SetScript("OnEvent",function(self) updateText(self, "right") end)
	module:UpdateStatusBars()
end

function module:UpdateStatusBars()
	if SUI.DB.StatusBars.left ~= "disabled" then SUI_StatusBar_Left:Show(); updateText(SUI_StatusBar_Left, "left") else SUI_StatusBar_Left:Hide(); end
	if SUI.DB.StatusBars.right ~= "disabled" then SUI_StatusBar_Right:Show(); updateText(SUI_StatusBar_Right, "left") else SUI_StatusBar_Right:Hide(); end
end
