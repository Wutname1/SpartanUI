local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Fel");
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
	if (not name) then return; end
	local description = " ";
	for i = 1,GetNumFactions() do
		if name == GetFactionInfo(i) then
			_,description = GetFactionInfo(i)
		end
	end
	return description;
end


-- Misc Framework stuff
function module:updateScale()
	if (not DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"),"(%d+).-(%d+)");
		if (tonumber(width) / tonumber(height) > 4/3) then DB.scale = 0.92;
		else DB.scale = 0.78; end
	end
	if DB.scale ~= CurScale then
		if (DB.scale ~= Artwork_Core:round(Fel_SpartanUI:GetScale())) then
			Fel_SpartanUI:SetScale(DB.scale);
		end
		CurScale = DB.scale
	end
end;

function module:updateAlpha()
	if DB.alpha then
		Fel_SpartanUI.Left:SetAlpha(DB.alpha);
		Fel_SpartanUI.Right:SetAlpha(DB.alpha);
	end
	-- Update Action bar backgrounds
	for i = 1,4 do
		if DB.Styles.Fel.Artwork["bar"..i].enable then
			_G["Fel_Bar"..i]:Show()
			_G["Fel_Bar"..i]:SetAlpha(DB.Styles.Fel.Artwork["bar"..i].alpha)
		else
			_G["Fel_Bar"..i]:Hide()
		end
		if DB.Styles.Fel.Artwork.Stance.enable then
			_G["Fel_StanceBar"]:Show()
			_G["Fel_StanceBar"]:SetAlpha(DB.Styles.Fel.Artwork.Stance.alpha)
		else
			_G["Fel_StanceBar"]:Hide()
		end
		if DB.Styles.Fel.Artwork.MenuBar.enable then
			_G["Fel_MenuBar"]:Show()
			_G["Fel_MenuBar"]:SetAlpha(DB.Styles.Fel.Artwork.MenuBar.alpha)
		else
			_G["Fel_MenuBar"]:Hide()
		end
	end
end;

function module:updateOffset()
	local offset = 0
	if not DB.yoffsetAuto then
		offset = max(DB.yoffset,1);
	else
		for i = 1,4 do -- FuBar Offset
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "BOTTOMLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		for i = 1,100 do -- Chocolate Bar Offset
			if (_G["ChocolateBar"..i] and _G["ChocolateBar"..i]:IsVisible()) then
				local bar = _G["ChocolateBar"..i];
				local point = bar:GetPoint(1);
				--if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
				if point == "RIGHT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end-- bottom bars
			end
		end
		TitanBarOrder = {[1]="AuxBar2", [2]="AuxBar"} -- Bottom 2 Bar names
		for i=1,2 do -- Titan Bar Offset
			if (_G["Titan_Bar__Display_"..TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i].."_Show")) then
				local PanelScale = TitanPanelGetVar("Scale") or 1
				local bar = _G["Titan_Bar__Display_"..TitanBarOrder[i]]
				titan = titan + (PanelScale * bar:GetHeight());
			end
		end
		
		offset = max(fubar + titan + ChocolateBar,1);
	end
	if offset ~= 0 then
		Fel_SpartanUI.Left:ClearAllPoints()
		Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 0, DB.yoffset)
		
		Fel_ActionBarPlate:ClearAllPoints()
		Fel_ActionBarPlate:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, DB.yoffset+6)
	end
	DB.yoffset = offset
	
end

--	Module Calls
function module:TooltipLoc(self, parent)
	if (parent == "UIParent") then
		tooltip:ClearAllPoints();
		tooltip:SetPoint("BOTTOMRIGHT","Fel_SpartanUI","TOPRIGHT",0,10);
	end
end

function module:BuffLoc(self, parent)
	BuffFrame:ClearAllPoints();
	BuffFrame:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
end

function module:SetupVehicleUI()
	if DBMod.Artwork.VehicleUI then
		petbattle:HookScript("OnHide", function() Fel_SpartanUI:Hide() Minimap:Hide()  end)
		petbattle:HookScript("OnShow", function() Fel_SpartanUI:Show() Minimap:Show()  end)
		RegisterStateDriver(petbattle, "visibility", "[petbattle] hide; show");
		RegisterStateDriver(Fel_SpartanUI, "visibility", "[overridebar][vehicleui] hide; show");
	end
end

function module:RemoveVehicleUI()
	if DBMod.Artwork.VehicleUI then
		UnRegisterStateDriver(petbattle, "visibility");
		UnRegisterStateDriver(Fel_SpartanUI, "visibility");
	end
end

function module:InitArtwork()
	--if (Bartender4.db:GetCurrentProfile() == DB.Styles.Transparent.BartenderProfile or not Artwork_Core:BartenderProfileCheck(DB.Styles.Transparent.BartenderProfile,true)) then
	Artwork_Core:ActionBarPlates("Fel_ActionBarPlate");
	--end

	do -- create bar anchor
		plate = CreateFrame("Frame","Fel_ActionBarPlate",UIParent,"Fel_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND");
		plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
	end
	
	FramerateText:ClearAllPoints();
	FramerateText:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10);
end

function module:EnableArtwork()
	Fel_SpartanUI:SetFrameStrata("BACKGROUND");
	Fel_SpartanUI:SetFrameLevel(1);
	
	Fel_SpartanUI.Left = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Left", "BORDER")
	Fel_SpartanUI.Left:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 0, 0)
	Fel_SpartanUI.Left:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Left]])
	
	Fel_SpartanUI.Right = Fel_SpartanUI:CreateTexture("Fel_SpartanUI_Right", "BORDER")
	Fel_SpartanUI.Right:SetPoint("LEFT", Fel_SpartanUI.Left, "RIGHT", 0, 0)
	Fel_SpartanUI.Right:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Base_Bar_Right]])
	
	module:updateOffset();
	
	hooksecurefunc("UIParent_ManageFramePositions",function()
		TutorialFrameAlertButton:SetParent(Minimap);
		TutorialFrameAlertButton:ClearAllPoints();
		TutorialFrameAlertButton:SetPoint("CENTER",Minimap,"TOP",-2,30);
		CastingBarFrame:ClearAllPoints();
		CastingBarFrame:SetPoint("BOTTOM",Fel_SpartanUI,"TOP",0,90);
	end);
	
	MainMenuBarVehicleLeaveButton:HookScript("OnShow", function() 
		MainMenuBarVehicleLeaveButton:ClearAllPoints()
		MainMenuBarVehicleLeaveButton:SetPoint("LEFT",SUI_playerFrame,"RIGHT",15,0)
	end)
	
	Artwork_Core:MoveTalkingHeadUI()
	module:SetupVehicleUI();
	
	if (DB.MiniMap.AutoDetectAllowUse) or (DB.MiniMap.ManualAllowUse) then module:MiniMap() end

	module:updateScale();
	module:updateAlpha();
	module:StatusBars()
end

-- Status Bars
function module:SetXPColors()
	-- Set Gained Color
	if DB.StatusBars.XPBar.GainedColor ~= "Custom" then
		DB.StatusBars.XPBar.GainedRed 			= COLORS[DB.StatusBars.XPBar.GainedColor].r
		DB.StatusBars.XPBar.GainedBlue 		= COLORS[DB.StatusBars.XPBar.GainedColor].b
		DB.StatusBars.XPBar.GainedGreen 		= COLORS[DB.StatusBars.XPBar.GainedColor].g
		DB.StatusBars.XPBar.GainedBrightness	= COLORS[DB.StatusBars.XPBar.GainedColor].a
	end
    
    local r,b,g,a
	r = DB.StatusBars.XPBar.GainedRed
	b = DB.StatusBars.XPBar.GainedBlue
	g = DB.StatusBars.XPBar.GainedGreen
	a = DB.StatusBars.XPBar.GainedBrightness
	Fel_ExperienceBarFill:SetVertexColor	(r,g,b,a);
	Fel_ExperienceBarFillGlow:SetVertexColor(r,g,b,(a-.2));

	-- Set Rested Color
	if DB.StatusBars.XPBar.RestedMatchColor then
		DB.StatusBars.XPBar.RestedRed 			= DB.StatusBars.XPBar.GainedRed
		DB.StatusBars.XPBar.RestedBlue 		= DB.StatusBars.XPBar.GainedBlue
		DB.StatusBars.XPBar.RestedGreen 		= DB.StatusBars.XPBar.GainedGreen
		DB.StatusBars.XPBar.RestedBrightness	= 1
		DB.StatusBars.XPBar.RestedColor		= DB.StatusBars.XPBar.GainedColor
	elseif DB.StatusBars.XPBar.RestedColor ~= "Custom" then
		DB.StatusBars.XPBar.RestedRed 			= COLORS[DB.StatusBars.XPBar.RestedColor].r
		DB.StatusBars.XPBar.RestedBlue 		= COLORS[DB.StatusBars.XPBar.RestedColor].b
		DB.StatusBars.XPBar.RestedGreen 		= COLORS[DB.StatusBars.XPBar.RestedColor].g
		DB.StatusBars.XPBar.RestedBrightness	= COLORS[DB.StatusBars.XPBar.RestedColor].a
	end
	r = DB.StatusBars.XPBar.RestedRed
	b = DB.StatusBars.XPBar.RestedBlue
	g = DB.StatusBars.XPBar.RestedGreen
	a = DB.StatusBars.XPBar.RestedBrightness
	Fel_ExperienceBarLead:SetVertexColor	(r,g,b,a);
	Fel_ExperienceBarLeadGlow:SetVertexColor(r,g,b,(a+.1));

	-- Update Text if needed
	if DB.StatusBars.XPBar.text then Fel_ExperienceBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100)) else Fel_ExperienceBarText:SetText("") end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:SetRepColors()
	local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
	
	if DB.StatusBars.RepBar.enabled and not Fel_ReputationBar:IsVisible() then
		Fel_ReputationBar:Show();
	elseif not DB.StatusBars.RepBar.enabled then
		Fel_ReputationBar:Hide();
		return
	end
	if DB.StatusBars.RepBar.AutoDefined == true then
		local color = FACTION_BAR_COLORS[reaction] or FACTION_BAR_COLORS[7];
		Fel_ReputationBarFill:SetVertexColor	(color.r, color.g, color.b, 0.7);
		Fel_ReputationBarFillGlow:SetVertexColor(color.r, color.g, color.b, 0.2);
	else
        local r,b,g,a

		r = DB.StatusBars.RepBar.GainedRed
		b = DB.StatusBars.RepBar.GainedBlue
		g = DB.StatusBars.RepBar.GainedGreen
		a = DB.StatusBars.RepBar.GainedBrightness
		Fel_ReputationBarFill:SetVertexColor	(r, g, b, a);
		Fel_ReputationBarFillGlow:SetVertexColor(r, g, b, a);
	end

	-- Set Text if needed
	if DB.StatusBars.RepBar.text then
		Fel_ReputationBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100)
	else
		Fel_ReputationBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:UpdateAPBar()
	-- Set Text if needed
	if DB.StatusBars.APBar.text then
		local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
		local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent);
		local ratio = (xp/xpForNextPoint);
		Fel_ArtifactBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(xp), spartan:comma_value(xpForNextPoint), ratio*100)
	else
		Fel_ArtifactBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:UpdateHonorBar()
	-- Set Text if needed
	if DB.StatusBars.HonorBar.text then
		local itemID, altItemID, name, icon, xp, pointsSpent, quality, HonorAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_HonorUI.GetEquippedHonorInfo();
		local xpForNextPoint = C_HonorUI.GetCostForPointAtRank(pointsSpent);
		local ratio = (xp/xpForNextPoint);
		Fel_HonorBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(xp), spartan:comma_value(xpForNextPoint), ratio*100)
	else
		Fel_HonorBarText:SetText("")
	end
	-- Update Visibility
	module:UpdateStatusBars()
end

function module:StatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame","Fel_StatusBarTooltip",SpartanUI,"Fel_StatusBars_TooltipTemplate");
		spartan:FormatFont(Fel_StatusBarTooltipHeader, 10, "Core")
		spartan:FormatFont(Fel_StatusBarTooltipText, 8, "Core")
	end
	do -- experience bar
		Fel_ExperienceBar:SetScript("OnEvent",function()
			if DB.StatusBars.XPBar.enabled and not Fel_ExperienceBar:IsVisible() then
				Fel_ExperienceBar:Show();
			elseif not DB.StatusBars.XPBar.enabled then
				Fel_ExperienceBar:Hide();
				return
			end
			
			local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			if now == 0 then
				Fel_ExperienceBarFill:SetWidth(0.1);
				Fel_ExperienceBarFillGlow:SetWidth(.1);
				Fel_ExperienceBarLead:SetWidth(0.1);
			else
				Fel_ExperienceBarFill:SetWidth((now/goal)*Fel_ExperienceBar:GetWidth());
				rested = (rested/goal)*Fel_ExperienceBar:GetWidth();
				if (rested+Fel_ExperienceBarFill:GetWidth()) > (Fel_ExperienceBar:GetWidth()-1) then rested = Fel_ExperienceBar:GetWidth()-Fel_ExperienceBarFill:GetWidth(); end
				if rested == 0 then rested = .001 end
				Fel_ExperienceBarLead:SetWidth(rested);
			end
			if DB.StatusBars.XPBar.text then
				Fel_ExperienceBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(now), spartan:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100))
			else
				Fel_ExperienceBarText:SetText("")
			end
			module:SetXPColors()
		end);
		local showXPTooltip = function()
			local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
			local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
			local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",Fel_ExperienceBar,"TOP",6,-1);
			local a = format("Level %s ",UnitLevel("player"))
			local b = format(XP_LEVEL_TEMPLATE, spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
			Fel_StatusBarTooltipHeader:SetText(a..b); -- Level 99 (9999 / 9999) 100% Experience
			local rested,text = GetXPExhaustion() or 0;
			if (rested > 0) then
				text = format(xptip1,format(xprest,(rested/UnitXPMax("player"))*100),200);
				Fel_StatusBarTooltipText:SetText(text); -- Rested (15%) - 200% of normal experience gained from monsters.
			else
				Fel_StatusBarTooltipText:SetText(format(xptip1,EXHAUST_TOOLTIP2,100)); -- You should rest at an Inn. 100% of normal experience gained from monsters.
			end
			tooltip:Show();
		end
		
		Fel_ExperienceBar:SetScript("OnEnter",function() if DB.StatusBars.XPBar.ToolTip == "hover" then showXPTooltip(); end end);
		Fel_ExperienceBar:SetScript("OnMouseDown",function() if DB.StatusBars.XPBar.ToolTip == "click" then showXPTooltip(); end end);
		Fel_ExperienceBar:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		Fel_ExperienceBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		Fel_ExperienceBar:RegisterEvent("PLAYER_XP_UPDATE");
		Fel_ExperienceBar:RegisterEvent("PLAYER_LEVEL_UP");
		
		module:SetXPColors();
	end
	do -- reputation bar
		Fel_ReputationBar:SetScript("OnEvent",function()
			local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
			if name then ratio = (current-low)/(high-low); end
			Fel_StatusBarTooltipHeader:SetText(name);
			if ratio == 0 then
				Fel_ReputationBarFill:SetWidth(0.1);
			else
				Fel_ReputationBarFill:SetWidth(ratio*Fel_ReputationBar:GetWidth());
			end
			module:SetRepColors()
			
			if DB.StatusBars.RepBar.text then
				Fel_ReputationBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100)
			else
				Fel_ReputationBarText:SetText("")
			end
		end);
		local showRepTooltip = function()
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",Fel_ReputationBar,"TOP",-2,-1);
			local name,react,low,high,current,text,ratio = GetWatchedFactionInfo();
			if name then
				text = GetFactionDetails(name);
				ratio = (current-low)/(high-low);
				Fel_StatusBarTooltipHeader:SetText(format("%s ( %s / %s ) %d%% %s", name, spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100,_G["FACTION_STANDING_LABEL"..react]));
				Fel_StatusBarTooltipText:SetText("|cffffd200"..text.."|r");
			else
				Fel_StatusBarTooltipHeader:SetText(REPUTATION);
				Fel_StatusBarTooltipText:SetText(REPUTATION_STANDING_DESCRIPTION);
			end
			tooltip:Show();
		end
		
		Fel_ReputationBar:SetScript("OnEnter",function() if DB.StatusBars.RepBar.ToolTip == "hover" then showRepTooltip(); end end);
		Fel_ReputationBar:SetScript("OnMouseDown",function() if DB.StatusBars.RepBar.ToolTip == "click" then showRepTooltip(); end end);
		Fel_ReputationBar:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		Fel_ReputationBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		Fel_ReputationBar:RegisterEvent("UPDATE_FACTION");
		
		module:SetRepColors();
	end
	do -- Artifact Power bar
		Fel_ArtifactBar:SetScript("OnEvent",function()
			--Clear Text
			Fel_ArtifactBarText:SetText("")
			--Update if needed
			if HasArtifactEquipped() then
				local itemID, altItemID, name, icon, xp, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo();
				-- local currentArtifactPurchasableTraits = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, xp);
				local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent);
				local ratio = (xp/xpForNextPoint);
				
				if ratio == 0 then
					Fel_ArtifactBarFill:SetWidth(0.1);
				else
					if (ratio*Fel_ArtifactBar:GetWidth()) > Fel_ArtifactBar:GetWidth() then
						Fel_ArtifactBarFill:SetWidth(Fel_ArtifactBar:GetWidth())
					else
						Fel_ArtifactBarFill:SetWidth(ratio*Fel_ArtifactBar:GetWidth());
					end
				end
				
				if DB.StatusBars.APBar.text then
					Fel_ArtifactBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(xp), spartan:comma_value(xpForNextPoint), ratio*100)
				end
			end
		end);
		
		Fel_ArtifactBarFill:SetVertexColor(1,0.8,0,.7)
		Fel_ArtifactBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		Fel_ArtifactBar:RegisterEvent("ARTIFACT_XP_UPDATE");
		Fel_ArtifactBar:RegisterEvent("UNIT_INVENTORY_CHANGED");
	end
	do -- Honor bar
		Fel_HonorBar:SetScript("OnEvent",function(self)
			local current = UnitHonor("player");
			local max = UnitHonorMax("player");

			local level = UnitHonorLevel("player");
			local levelmax = GetMaxPlayerHonorLevel();
			
			
			-- if DB.StatusBars.RepBar.text then
				-- Fel_ReputationBarText:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(current-low), spartan:comma_value(high-low), ratio*100)
			-- else
				-- Fel_ReputationBarText:SetText("")
			-- end
			
			
			if (level == levelmax) then
				-- Force the bar to full for the max level
				Fel_HonorBarFill:SetWidth(Fel_HonorBar:GetWidth());
			else
				local ratio = current/max;
				if ratio == 0 then
					Fel_HonorBarFill:SetWidth(0.1);
				else
					Fel_HonorBarFill:SetWidth(ratio*Fel_ReputationBar:GetWidth());
				end
			end
			
			-- local exhaustionStateID = GetHonorRestState();
			-- if (exhaustionStateID == 1) then
				-- Fel_HonorBarLead:SetWidth(rested);
			-- else
				-- Fel_HonorBarLead:SetWidth(0.1);
			-- end
		end)
		
		Fel_HonorBar:RegisterEvent("PLAYER_ENTERING_WORLD");
		Fel_HonorBar:RegisterEvent("HONOR_XP_UPDATE");
		Fel_HonorBar:RegisterEvent("HONOR_LEVEL_UPDATE");
		Fel_HonorBar:RegisterEvent("HONOR_PRESTIGE_UPDATE");
	end
	module:UpdateStatusBars()
end

function module:UpdateStatusBars()
	-- XP
	if DB.StatusBars.left == "xp" or DB.StatusBars.right == "xp" then
		Fel_ExperienceBar:Show();
		if DB.StatusBars.right == "xp" then 
			Fel_ExperienceBar:ClearAllPoints()
			Fel_ExperienceBar:SetPoint("BOTTOMLEFT", Fel_ActionBarPlate, "BOTTOM", 110, 0)
		end
	else
		Fel_ExperienceBar:Hide();
	end
	--Rep
	if DB.StatusBars.left == "rep" or DB.StatusBars.right == "rep" then
		Fel_ReputationBar:Show();
		if DB.StatusBars.right == "rep" then 
			Fel_ReputationBar:ClearAllPoints()
			Fel_ReputationBar:SetPoint("BOTTOMLEFT", Fel_ActionBarPlate, "BOTTOM", 110)
		end
	else
		Fel_ReputationBar:Hide();
	end
	--Artifact Power
	if DB.StatusBars.left == "ap" or DB.StatusBars.right == "ap" then
		Fel_ArtifactBar:Show();
		if DB.StatusBars.right == "ap" then 
			-- Fel_ArtifactBar:ClearAllPoints()
			-- Fel_ArtifactBar:SetPoint("BOTTOMLEFT", Fel_ActionBarPlate, "BOTTOM", 110)
		else
			Fel_ArtifactBar:SetPoint("BOTTOMRIGHT", Fel_ActionBarPlate, "BOTTOM", -110)
		end
	else
		Fel_ArtifactBar:Hide();
	end
	--Honor
	if DB.StatusBars.left == "honor" or DB.StatusBars.right == "honor" then
		Fel_HonorBar:Show();
		if DB.StatusBars.right == "honor" then 
			Fel_HonorBar:ClearAllPoints()
			Fel_HonorBar:SetPoint("BOTTOMLEFT", Fel_ActionBarPlate, "BOTTOM", 110)
		end
	else
		Fel_HonorBar:Hide();
	end
end

-- Bartender Stuff
function module:SetupProfile()
	Artwork_Core:SetupProfile()
end;

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

-- Minimap
function module:MiniMap()
	Minimap:SetSize(156, 156);
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",Fel_SpartanUI.Left,"RIGHT",0,-10);
	Minimap:SetParent(Fel_SpartanUI);
	
	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints();
		Minimap.ZoneText:SetPoint("TOPLEFT",Minimap,"BOTTOMLEFT",0,-5);
		Minimap.ZoneText:SetPoint("TOPRIGHT",Minimap,"BOTTOMRIGHT",0,-5);
		Minimap.ZoneText:Hide();
		MinimapZoneText:Show();
		
		Minimap.coords:SetTextColor(1,.82,0,1);
	end
	
	-- Minimap.coords:Hide()
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",Fel_SpartanUI,"TOP",0,100);
	
	Minimap.FelUpdate = function(self)
		if self.FelBG then self.FelBG:ClearAllPoints() end
		if DB.Styles.Fel.Minimap.Engulfed then
			self.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Engulfed]])
			self.FelBG:SetPoint("CENTER", self, "CENTER", 7, 37)
			self.FelBG:SetSize(330, 330)
			self.FelBG:SetBlendMode("ADD");
		else
			self.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Calmed]])
			self.FelBG:SetPoint("CENTER", self, "CENTER", 5, -1)
			self.FelBG:SetSize(256, 256)
			self.FelBG:SetBlendMode("ADD");
		end
	end
	
	Minimap.FelBG = Minimap:CreateTexture(nil, "BACKGROUND")
	if DB.Styles.Fel.Minimap.Engulfed then
		Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Engulfed]])
		Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 7, 37)
		Minimap.FelBG:SetSize(330, 330)
		Minimap.FelBG:SetBlendMode("ADD");
	else
		Minimap.FelBG:SetTexture([[Interface\AddOns\SpartanUI_Style_Fel\Images\Minimap-Calmed]])
		Minimap.FelBG:SetPoint("CENTER", Minimap, "CENTER", 5, -1)
		Minimap.FelBG:SetSize(256, 256)
		Minimap.FelBG:SetBlendMode("ADD");
	end
	
	--Shape Change
	local shapechange = function(shape)
		if shape == "square" then
			Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
			
			Minimap.overlay = Minimap:CreateTexture(nil,"OVERLAY");
			Minimap.overlay:SetTexture("Interface\\AddOns\\SpartanUI\\Media\\map-square-overlay");
			Minimap.overlay:SetAllPoints(Minimap);
			Minimap.overlay:SetBlendMode("ADD");
			
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",0,0)
			Minimap.FelBG:Hide()
		else
			Minimap:SetMaskTexture("Interface\\AddOns\\SpartanUI\\media\\map-circle-overlay")
			MiniMapTracking:ClearAllPoints();
			MiniMapTracking:SetPoint("TOPLEFT",Minimap,"TOPLEFT",-5,-5)
			if Minimap.overlay then Minimap.overlay:Hide() end
			Minimap.FelBG:Show()
		end
	end

	Fel_SpartanUI:HookScript("OnHide", function(this, event)
		Minimap:ClearAllPoints();
		Minimap:SetParent(UIParent);
		Minimap:SetPoint("TOP",UIParent,"TOP",0,-20);
		shapechange("square")
	end)
	
	Fel_SpartanUI:HookScript("OnShow", function(this, event)
		Minimap:ClearAllPoints();
		Minimap:SetPoint("CENTER",Fel_SpartanUI,"CENTER",0,54);
		Minimap:SetParent(Fel_SpartanUI);
		shapechange("circle")
	end)
	
end

