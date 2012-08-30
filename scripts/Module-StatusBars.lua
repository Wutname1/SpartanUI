local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("StatusBars");
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

function module:OnInitialize()
	addon.optionsGeneral.args["XPBar"] = {
		name = "XP Bar Settings",
		desc = "configure XP Bar Settings",
		type = "group", args = {
			header1 = {name="Gained XP Bar Settings",type="header",order=0},
			GainedColor = {name="Gained Color",type="select",style="dropdown",order=1,width="full",
				values = {
					["Custom"]	= "Custom",
					["Orange"]	= "Orange",
					["Yellow"]	= "Yellow",
					["Green"]	= "Green",
					["Pink"]	= "Pink",
					["Purple"]	= "Purple",
					["Blue"]	= "Blue",
					["Red"]	= "Red",
					["Light_Blue"]	= "Light Blue",
				},
				get = function(info) return DB.XPBar.GainedColor; end,
				set = function(info,val) DB.XPBar.GainedColor = val; module:SetXPColors(); end
			},
			GainedRed = {name="Red",type="range",order=2,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedRed*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedRed = (val/100); module:SetXPColors();
				end
			},
			GainedGreen = {name="Green",type="range",order=3,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedGreen*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedGreen = (val/100);  module:SetXPColors();
				end
			},
			GainedBlue = {name="Blue",type="range",order=4,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedBlue*100); end,
				set = function(info,val)
					if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedBlue = (val/100); module:SetXPColors();
				end
			},
			GainedBrightness = {name="Brightness",type="range",order=5,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.GainedBrightness*100); end,
				set = function(info,val) if (DB.XPBar.GainedColor ~= "Custom") then DB.XPBar.GainedColor = "Custom"; end DB.XPBar.GainedBrightness = (val/100); module:SetXPColors(); end
			},
			header2 = {name="Rested XP Bar Settings",type="header",order=10},
			RestedColor = {name="Rested Color",type="select",style="dropdown",order=11,width="full",
				values = {
					["Custom"]	= "Custom",
					["Orange"]	= "Orange",
					["Yellow"]	= "Yellow",
					["Green"]	= "Green",
					["Pink"]	= "Pink",
					["Purple"]	= "Purple",
					["Blue"]	= "Blue",
					["Red"]	= "Red",
					["Light_Blue"]	= "Light Blue",
				},
				get = function(info) return DB.XPBar.RestedColor; end,
				set = function(info,val) DB.XPBar.RestedColor = val; module:SetXPColors(); end
			},
			RestedRed = {name="Red",type="range",order=12,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedRed*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedRed = (val/100); module:SetXPColors();
				end
			},
			RestedGreen = {name="Green",type="range",order=13,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedGreen*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedGreen = (val/100); module:SetXPColors();
				end
			},
			RestedBlue = {name="Blue",type="range",order=14,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedBlue*100); end,
				set = function(info,val)
					if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedBlue = (val/100); module:SetXPColors();
				end
			},
			RestedBrightness = {name="Brightness",type="range",order=15,
				min=0,max=100,step=1,
				get = function(info) return (DB.XPBar.RestedBrightness*100); end,
				set = function(info,val) if (DB.XPBar.RestedColor ~= "Custom") then DB.XPBar.RestedColor = "Custom"; end DB.XPBar.RestedBrightness = (val/100); module:SetXPColors(); end
			},
			RestedMatchColor = {name="Match Rested Color",type="toggle",order=21,
				get = function(info) return DB.XPBar.RestedMatchColor; end,
				set = function(info,val) DB.XPBar.RestedMatchColor = val; module:SetXPColors(); end
			}
		}
	}
	addon.optionsGeneral.args["RepBar"] = {
		name = "Rep Bar Settings",
		desc = "configure Rep Bar Settings",
		type = "group", args = {
			AutoDefined = {name="Let Spartan decide",type="toggle",order=1,desc="The color will change based on yoru standing, red being hated, green being friendly",
			width="full",
				get = function(info) return DB.RepBar.AutoDefined; end,
				set = function(info,val) DB.RepBar.AutoDefined = val; module:SetRepColors(); end
			},
			GainedColor = {name="Color",type="select",style="dropdown",order=2,width="full",
				values = {
					["AUTO"]	= "AUTO",
					["Custom"]	= "Custom",
					["Orange"]	= "Orange",
					["Yellow"]	= "Yellow",
					["Green"]	= "Green",
					["Pink"]	= "Pink",
					["Purple"]	= "Purple",
					["Blue"]	= "Blue",
					["Red"]	= "Red",
					["Light_Blue"]	= "Light Blue",
				},
				get = function(info) return DB.RepBar.GainedColor; end,
				set = function(info,val) DB.RepBar.GainedColor = val; if val == "AUTO" then DB.RepBar.AutoDefined = true end module:SetRepColors(); end
			},
			GainedRed = {name="Red",type="range",order=3,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedRed*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedRed = (val/100); module:SetRepColors();
				end
			},
			GainedGreen = {name="Green",type="range",order=4,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedGreen*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedGreen = (val/100);  module:SetRepColors();
				end
			},
			GainedBlue = {name="Blue",type="range",order=5,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedBlue*100); end,
				set = function(info,val)
					if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedBlue = (val/100); module:SetRepColors();
				end
			},
			GainedBrightness = {name="Brightness",type="range",order=6,
				min=0,max=100,step=1,
				get = function(info) return (DB.RepBar.GainedBrightness*100); end,
				set = function(info,val) if (DB.RepBar.AutoDefined) then return end if (DB.RepBar.GainedColor ~= "Custom") then DB.RepBar.GainedColor = "Custom"; end DB.RepBar.GainedBrightness = (val/100); module:SetRepColors(); end
			}
		}
	}
end

function module:SetRepColors()
	local name,reaction,low,high,current = GetWatchedFactionInfo();
	if DB.RepBar.AutoDefined == true then
		local color = FACTION_BAR_COLORS[reaction] or FACTION_BAR_COLORS[7];
		SUI_ReputationBarFill:SetVertexColor	(color.r, color.g, color.b, 0.7);
		SUI_ReputationBarFillGlow:SetVertexColor(color.r, color.g, color.b, 0.2);
		SUI_ReputationBarLead:SetVertexColor	(color.r, color.g, color.b, 0.7);
		SUI_ReputationBarLeadGlow:SetVertexColor(color.r, color.g, color.b, 0.2);
	else
		r = DB.RepBar.GainedRed
		b = DB.RepBar.GainedBlue
		g = DB.RepBar.GainedGreen
		a = DB.RepBar.GainedBrightness
		SUI_ReputationBarFill:SetVertexColor	(r, g, b, a);
		SUI_ReputationBarFillGlow:SetVertexColor(r, g, b, a);
		SUI_ReputationBarLead:SetVertexColor	(r, g, b, a);
		SUI_ReputationBarLeadGlow:SetVertexColor(r, g, b, a);
	end
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
end


function module:OnEnable()
	do -- experience bar
		xpframe = CreateFrame("Frame","SUI_ExperienceBar",SpartanUI,"SUI_StatusBars_XPTemplate");
		xpframe:SetPoint("BOTTOMRIGHT","SpartanUI","BOTTOM",-80,0);
		module:SetXPColors()
		xpframe:SetScript("OnEvent",function()
			local level,rested,now,goal = UnitLevel("player"),GetXPExhaustion() or 0,UnitXP("player"),UnitXPMax("player");
			if now == 0 then
				SUI_ExperienceBarFill:SetWidth(0.1);
				SUI_ExperienceBarFillGlow:SetWidth(.1);
			else
				SUI_ExperienceBarFill:SetWidth((now/goal)*400);
				rested = (rested/goal)*400;
				if rested > 400 then rested = 400-((now/goal)*400); end
				SUI_ExperienceBarFillGlow:SetWidth(rested);
			end
			-- Making some stuff ready for changing color on exp if rested.
			module:SetXPColors()
		end);
		xpframe:RegisterEvent("PLAYER_ENTERING_WORLD");
		xpframe:RegisterEvent("PLAYER_XP_UPDATE");
		xpframe:RegisterEvent("PLAYER_LEVEL_UP");
		
		xpframe:SetFrameStrata("BACKGROUND");
		xpframe:SetFrameLevel(2);
	end
	do -- reputation bar
		repframe = CreateFrame("Frame","SUI_ReputationBar",SpartanUI,"SUI_StatusBars_RepTemplate");
		repframe:SetPoint("BOTTOMLEFT",SpartanUI,"BOTTOM",78,0);
		
		module:SetRepColors()
		repframe:SetScript("OnEvent",function()
			local ratio,name,reaction,low,high,current = 0,GetWatchedFactionInfo();
			if name then ratio = (current-low)/(high-low); end
			if ratio == 0 then
				SUI_ReputationBarFill:SetWidth(0.1);
			else
				SUI_ReputationBarFill:SetWidth(ratio*400);
				module:SetRepColors()
			end
		end);
		repframe:RegisterEvent("PLAYER_ENTERING_WORLD");
		repframe:RegisterEvent("UPDATE_FACTION");
		repframe:RegisterEvent("PLAYER_LEVEL_UP");
		repframe:RegisterEvent("CVAR_UPDATE");
		
		repframe:SetFrameStrata("BACKGROUND");
		repframe:SetFrameLevel(2);
	end
end