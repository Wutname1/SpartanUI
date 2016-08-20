local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Fel");
----------------------------------------------------------------------------------------------------
local CurScale
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
		RegisterStateDriver(Fel_SpartanUI, "visibility", "[petbattle][overridebar][vehicleui] hide; show");
	end
end

function module:RemoveVehicleUI()
	if DBMod.Artwork.VehicleUI then
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
	Fel_ExperienceBarFill:SetVertexColor	(r,g,b,a);
	Fel_ExperienceBarFillGlow:SetVertexColor(r,g,b,(a-.2));

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
	Fel_ExperienceBarLead:SetVertexColor	(r,g,b,a);
	Fel_ExperienceBarLeadGlow:SetVertexColor(r,g,b,(a+.1));

	-- Update Text if needed
	if DB.XPBar.text then xpframe.Text:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100)) else xpframe.Text:SetText("") end
end

function module:StatusBars()
	do -- create the tooltip
		tooltip = CreateFrame("Frame","Fel_StatusBarTooltip",SpartanUI,"Fel_StatusBars_TooltipTemplate");
		spartan:FormatFont(Fel_StatusBarTooltipHeader, 10, "Core")
		spartan:FormatFont(Fel_StatusBarTooltipText, 8, "Core")
	end
	do -- experience bar
		local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
		local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -

		xpframe = CreateFrame("Frame","Fel_ExperienceBar",SpartanUI,"Fel_StatusBar_Template");
		xpframe:SetPoint("BOTTOMRIGHT",SpartanUI_Fel,"BOTTOM",-100,0);
		
		xpframe:SetScript("OnEvent",function()
			if DB.XPBar.enabled and not xpframe:IsVisible() then xpframe:Show(); elseif not DB.XPBar.enabled then xpframe:Hide(); end
			local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			if now == 0 then
				Fel_ExperienceBarFill:SetWidth(0.1);
				Fel_ExperienceBarFillGlow:SetWidth(.1);
				Fel_ExperienceBarLead:SetWidth(0.1);
			else
				Fel_ExperienceBarFill:SetWidth((now/goal)*400);
				rested = (rested/goal)*400;
				if (rested+Fel_ExperienceBarFill:GetWidth()) > 399 then rested = 400-Fel_ExperienceBarFill:GetWidth(); end
				if rested == 0 then rested = .001 end
				Fel_ExperienceBarLead:SetWidth(rested);
			end
			if DB.XPBar.text then
				xpframe.Text:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(now), spartan:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100))
			else
				xpframe.Text:SetText("")
			end
			module:SetXPColors()
		end);
		local showXPTooltip = function()
			tooltip:ClearAllPoints();
			tooltip:SetPoint("BOTTOM",xpframe,"TOP",6,-1);
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
		
		xpframe.Text = xpframe:CreateFontString();
		spartan:FormatFont(xpframe.Text, 8, "Core")
		xpframe.Text:SetDrawLayer("OVERLAY");
		xpframe.Text:SetSize(xpframe:GetWidth(), xpframe:GetHeight());
		xpframe.Text:SetJustifyH("MIDDLE");
		xpframe.Text:SetJustifyV("MIDDLE");
		xpframe.Text:SetPoint("TOP",xpframe,"TOP",0,1);
		
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
	do -- Reputation bar
		-- local xptip1 = string.gsub(EXHAUST_TOOLTIP1,"\n"," "); -- %s %d%% of normal experience gained from monsters. (replaced single breaks with space)
		-- local XP_LEVEL_TEMPLATE = "( %s / %s ) %d%% "..COMBAT_XP_GAIN; -- use Global Strings and regex to make the level string work in any locale
		-- local xprest = TUTORIAL_TITLE26.." (%d%%) -"; -- Rested (%d%%) -

		repframe = CreateFrame("Frame","Fel_RepFrame",SpartanUI,"Fel_StatusBar_Template");
		repframe:SetPoint("BOTTOMLEFT",SpartanUI_Fel,"BOTTOM",100,0);
		
		-- repframe:SetScript("OnEvent",function()
			-- if DB.XPBar.enabled and not repframe:IsVisible() then repframe:Show(); elseif not DB.XPBar.enabled then repframe:Hide(); end
			-- local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			-- if now == 0 then
				-- Fel_RepFrameFill:SetWidth(0.1);
				-- Fel_RepFrameFillGlow:SetWidth(.1);
				-- Fel_RepFrameLead:SetWidth(0.1);
			-- else
				-- Fel_RepFrameFill:SetWidth((now/goal)*400);
				-- rested = (rested/goal)*400;
				-- if (rested+Fel_RepFrameFill:GetWidth()) > 399 then rested = 400-Fel_RepFrameFill:GetWidth(); end
				-- if rested == 0 then rested = .001 end
				-- Fel_RepFrameLead:SetWidth(rested);
			-- end
			-- if DB.XPBar.text then
				-- repframe.Text:SetFormattedText("( %s / %s ) %d%%", spartan:comma_value(now), spartan:comma_value(goal),(UnitXP("player")/UnitXPMax("player")*100))
			-- else
				-- repframe.Text:SetText("")
			-- end
			-- module:SetXPColors()
		-- end);
		-- local showXPTooltip = function()
			-- tooltip:ClearAllPoints();
			-- tooltip:SetPoint("BOTTOM",repframe,"TOP",6,-1);
			-- local a = format("Level %s ",UnitLevel("player"))
			-- local b = format(XP_LEVEL_TEMPLATE, spartan:comma_value(UnitXP("player")), spartan:comma_value(UnitXPMax("player")), (UnitXP("player")/UnitXPMax("player")*100))
			-- Fel_StatusBarTooltipHeader:SetText(a..b); -- Level 99 (9999 / 9999) 100% Experience
			-- local rested,text = GetXPExhaustion() or 0;
			-- if (rested > 0) then
				-- text = format(xptip1,format(xprest,(rested/UnitXPMax("player"))*100),200);
				-- Fel_StatusBarTooltipText:SetText(text); -- Rested (15%) - 200% of normal experience gained from monsters.
			-- else
				-- Fel_StatusBarTooltipText:SetText(format(xptip1,EXHAUST_TOOLTIP2,100)); -- You should rest at an Inn. 100% of normal experience gained from monsters.
			-- end
			-- tooltip:Show();
		-- end
		
		repframe.Text = repframe:CreateFontString();
		spartan:FormatFont(repframe.Text, 8, "Core")
		repframe.Text:SetDrawLayer("OVERLAY");
		repframe.Text:SetSize(repframe:GetWidth(), repframe:GetHeight());
		repframe.Text:SetJustifyH("MIDDLE");
		repframe.Text:SetJustifyV("MIDDLE");
		repframe.Text:SetPoint("TOP",repframe,"TOP",0,1);
		
		-- repframe:SetScript("OnEnter",function() if DB.XPBar.ToolTip == "hover" then showXPTooltip(); end end);
		-- repframe:SetScript("OnMouseDown",function() if DB.XPBar.ToolTip == "click" then showXPTooltip(); end end);
		-- repframe:SetScript("OnLeave",function() tooltip:Hide(); end);
		
		-- repframe:RegisterEvent("PLAYER_ENTERING_WORLD");
		-- repframe:RegisterEvent("PLAYER_XP_UPDATE");
		-- repframe:RegisterEvent("PLAYER_LEVEL_UP");
		
		repframe:SetFrameStrata("BACKGROUND");
		repframe:SetFrameLevel(2);
		repframe:Hide()
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




