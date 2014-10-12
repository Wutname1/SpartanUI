local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = addon:GetModule("Artwork_Core");
local module = addon:GetModule("Artwork_Transparent");
----------------------------------------------------------------------------------------------------
local ProfileName = "SpartanUI 3.3.0 - Transparent";
local BartenderSettings = { -- actual settings being inserted into our custom profile
	ActionBars = {
		actionbars = { -- following settings are bare minimum, so that anything not defined is retained between resets
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "Transparent_ActionBarPlate",	x=0,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "Transparent_ActionBarPlate",	x=0,	y=-4,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "Transparent_ActionBarPlate",	x=-402,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
			{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "Transparent_ActionBarPlate",	x=-402,	y=-4,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
			{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "Transparent_ActionBarPlate",	x=-135,	y=36,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
			{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "Transparent_ActionBarPlate",	x=3,	y=36,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
			{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "Transparent_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}} -- 10
		}
	},
	BagBar			= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true, padding = 0, 		position = {point = "TOPRIGHT",		parent = "Transparent_ActionBarPlate",	x=-6,	y=-2,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
	MicroMenu		= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true,	padding = -3,		position = {point = "TOPLEFT",		parent = "Transparent_ActionBarPlate",	x=603,	y=0,	scale = 0.80,	growHorizontal="RIGHT"}},
	PetBar			= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true, padding = 1, 		position = {point = "TOPLEFT",		parent = "Transparent_ActionBarPlate",	x=5,	y=-6,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
	StanceBar		= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true,	padding = 1, 		position = {point = "TOPRIGHT",		parent = "Transparent_ActionBarPlate",	x=-605,	y=-2,	scale = 0.85,	growHorizontal="LEFT"},		rows = 1},
	MultiCast		= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true,						position = {point = "TOPRIGHT",		parent = "Transparent_ActionBarPlate",	x=-777,	y=-4,	scale = 0.75}},
	Vehicle			= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = false,	padding = 3,	position = {point = "CENTER",		parent = "Transparent_ActionBarPlate",	x=-15,	y=213,	scale = 0.85}},
	ExtraActionBar	= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = true,						position = {point = "CENTER",		parent = "Transparent_ActionBarPlate",	x=-32,	y=240}},
	BlizzardArt		= {	fadeoutalpha = 0,	version = 3,	fadeout = true,	enabled = false,	},
};

local default, plate = {
	popup1 = {alpha = 1, enable = 1},
	popup2 = {alpha = 1, enable = 1},
	bar1 = {alpha = 1, enable = 1},
	bar2 = {alpha = 1, enable = 1},
	bar3 = {alpha = 1, enable = 1},
	bar4 = {alpha = 1, enable = 1},
	bar5 = {alpha = 1, enable = 1},
	bar6 = {alpha = 1, enable = 1},
};

function module:SetupProfile()
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	print("Using this profile: "..Bartender4.db:GetCurrentProfile())
	
	-- Checking for our Profile
	if (not module:BartenderProfileCheck(ProfileName,true)) then DB.ActionBars.Bartender4 = false end
	
	-- Set to our Profile
	if DB.ActionBars.Bartender4 then
		if Bartender4.db:GetCurrentProfile() ~= ProfileName then Bartender4.db:SetProfile(ProfileName) end return;
	end
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = module:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
	Bartender4:UpdateModuleConfigs(); -- run ApplyConfig for all modules, so that the new BartenderSettings are applied
	if module:BartenderProfileCheck(ProfileName,false) then addon:Print(ProfileName.." "..L["BartenderProfileCreated"]) end
	DB.ActionBars.Bartender4 = true;
	-- Can't use UpdateInterval, due to the way this need to be working -- could this behavior be changed? - Maybe a securehoocfunc on the unlocking
	plate:HookScript("OnUpdate",function(self,...)
		if (InCombatLockdown()) then return; end
		if (Bartender4.db:GetCurrentProfile() == ProfileName) or (Bartender4.db:GetCurrentProfile() == newtest) then
			if Bartender4.Locked then return; end
			addon:Print(L["BartenderProfileLocked"]);
			Bartender4:Lock();
		end
	end);
end;
function module:CreateProfile()
	--Exit if Bartender4 is not loaded
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	
	print("Using this profile: "..Bartender4.db:GetCurrentProfile())
	
	-- Checking for our Profile
	if (not module:BartenderProfileCheck(ProfileName,true)) then DB.ActionBars.Bartender4 = false end
	
	-- Set to our Profile
	if DB.ActionBars.Bartender4 then
		if Bartender4.db:GetCurrentProfile() ~= ProfileName then Bartender4.db:SetProfile(ProfileName) end return;
	end
	
	--Load the Profile Data
	for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
		if BartenderSettings[k] and v.db.profile then
			v.db.profile = module:MergeData(v.db.profile,BartenderSettings[k])
		end
	end
end

function module:BartenderProfileCheck(Input,Report)
	local profiles, r = Bartender4.db:GetProfiles(), false
	for k,v in pairs(profiles) do
		if v == Input then r = true end
	end
	if (Report) and (r ~= true) then
		addon:Print(Input.." "..L["BartenderProfileCheckFail"])
	end
	return r
end

function module:MergeData(target,source)
	if type(target) ~= "table" then target = {} end
	for k,v in pairs(source) do
		if type(v) == "table" then
			target[k] = self:MergeData(target[k], v);
		else
			target[k] = v;
		end
	end
	return target;
end

function module:InitActionBars()
	--Transparent_PopTemplateBG:SetVertexColor(0,.8,.9,.7)
	
	Bartender4.db:SetProfile(ProfileName);
	Artwork_Core:ActionBarPlates("Transparent_ActionBarPlate");
	do -- create bar plate and masks
		plate = CreateFrame("Frame","Transparent_ActionBarPlate",Transparent_SpartanUI,"Transparent_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND"); plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
	end
end

function module:EnableActionBars()
	do -- create base module frames
		-- Fix CPU leak, use UpdateInterval
		plate.UpdateInterval = 0.5
		plate.TimeSinceLastUpdate = 0
		plate:HookScript("OnUpdate",function(self,...) -- backdrop and popup visibility changes (alpha, animation, hide/show)
			local elapsed = select(1,...)
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
			if (self.TimeSinceLastUpdate > self.UpdateInterval) then
				-- Debug
--				print(self.TimeSinceLastUpdate)
				if (DB.ActionBars.bar1) then
					for b = 1,6 do -- for each backdrop
						if DB.ActionBars["bar"..b].enable then -- backdrop enabled
							_G["Transparent_Bar"..b]:SetAlpha(DB.ActionBars["bar"..b].alpha/100 or 1); -- apply alpha
							_G["Transparent_Bar"..b.."BG"]:SetVertexColor(nil, nil, nil, nil)
							_G["Transparent_Bar"..b.."BG"]:SetVertexColor(0,.8,.9,.7)
						else -- backdrop disabled
							_G["Transparent_Bar"..b]:SetAlpha(0);
						end
					end
					for p = 1,2 do -- for each popup
						if (DB.ActionBars["popup"..p].enable) then -- popup enabled
							_G["Transparent_Popup"..p]:SetAlpha((DB.ActionBars["popup"..p].alpha/100)/4 or 1); -- apply alpha
							_G["Transparent_Popup"..p.."BG"]:SetVertexColor(nil, nil, nil, nil)
							_G["Transparent_Popup"..p.."BG"]:SetVertexColor(0,.8,.9,.7)
						end
					end
				end
				self.TimeSinceLastUpdate = 0
			end
		end);
	end
	do -- modify strata / levels of backdrops
		for i = 1,6 do
			_G["Transparent_Bar"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Bar"..i]:SetFrameLevel(3);
		end
		for i = 1,2 do
			_G["Transparent_Popup"..i]:SetFrameStrata("BACKGROUND");
			_G["Transparent_Popup"..i]:SetFrameLevel(3);
		end
	end
	module:SetupProfile();
	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1,4 do
			_G["CharacterBag"..(i-1).."Slot"]:SetScale(1.25);
		end
	end
end