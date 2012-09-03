local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("ActionBars");
----------------------------------------------------------------------------------------------------
local default, plate = {
	popup1 = {anim = true, alpha = 1, enable = 1},
	popup2 = {anim = true, alpha = 1, enable = 1},
	bar1 = {alpha = 1, enable = 1},
	bar2 = {alpha = 1, enable = 1},
	bar3 = {alpha = 1, enable = 1},
	bar4 = {alpha = 1, enable = 1},
	bar5 = {alpha = 1, enable = 1},
	bar6 = {alpha = 1, enable = 1},
};

local UpdateSettings = function()
	DB.ActionBars = DB.ActionBars or {};
	for key,val in pairs(default) do
		if (not DB.ActionBars[key]) then DB.ActionBars[key] = val; end
		setmetatable(DB.ActionBars[key],{__index = default[key]});
	end
end;

local SetupProfile = function()
	UpdateSettings();
end;

local BartenderProfileCheck = function(Input,Report)
	local profiles, r = Bartender4.db:GetProfiles(), false
	for k,v in pairs(profiles) do if v == Input then r = true end end
	if Report then if r ~= true then addon:Print(Input.." Profile not found, generating one.") end end
	return r
end

-- Debug function to ease code testing while in-game
function p()
end

local SetupBartender = function()
	if (not select(4, GetAddOnInfo("Bartender4"))) then return; end
	local standard = "SpartanUI 3.0.2";
	local settings = { -- actual settings being inserted into our custom profile
			ActionBars = {
				actionbars = { -- following settings are bare minimum, so that anything not defined is retained between resets
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "SUI_ActionBarPlate",	x=0,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 1
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "SUI_ActionBarPlate",	x=0,	y=-4,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 2
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "SUI_ActionBarPlate",	x=-402,	y=36,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 3
					{enabled = true,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "SUI_ActionBarPlate",	x=-402,	y=-4,	scale = 0.85,	growHorizontal="RIGHT"}}, -- 4
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "LEFT",		parent = "SUI_ActionBarPlate",	x=-135,	y=36,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 5
					{enabled = true,	buttons = 12,	rows = 3,	padding = 4,	skin = {Zoom = true},	position = {point = "RIGHT",	parent = "SUI_ActionBarPlate",	x=3,	y=36,	scale = 0.80,	growHorizontal="RIGHT"}}, -- 6
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "SUI_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 7
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "SUI_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 8
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "SUI_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}}, -- 9
					{enabled = false,	buttons = 12,	rows = 1,	padding = 3,	skin = {Zoom = true},	position = {					parent = "SUI_ActionBarPlate",					scale = 0.85,	growHorizontal="RIGHT"}} -- 10
				}
			},
			BagBar		= {	enabled = true, padding = 0, 		position = {point = "TOPRIGHT",		parent = "SUI_ActionBarPlate",	x=-6,	y=-2,	scale = 0.70,	growHorizontal="LEFT"},		rows = 1, onebag = false, keyring = true},
			MicroMenu	= {	enabled = true,	padding = -3,		position = {point = "TOPLEFT",		parent = "SUI_ActionBarPlate",	x=603,	y=0,	scale = 0.80,	growHorizontal="RIGHT"}},
			PetBar		= {	enabled = true, padding = 1, 		position = {point = "TOPLEFT",		parent = "SUI_ActionBarPlate",	x=5,	y=-6,	scale = 0.70,	growHorizontal="RIGHT"},	rows = 1, skin = {Zoom = true}},
			StanceBar	= {	enabled = true,	padding = 1, 		position = {point = "TOPRIGHT",		parent = "SUI_ActionBarPlate",	x=-605,	y=-2,	scale = 0.85,	growHorizontal="LEFT"},		rows = 1},
			MultiCast	= {	enabled = true,						position = {point = "TOPRIGHT",		parent = "SUI_ActionBarPlate",	x=-777,	y=-4,	scale = 0.75}},
			Vehicle		= {	enabled = true,	padding = 3,		position = {point = "LEFT",			parent = "SUI_ActionBarPlate",	x=364,	y=-1,	scale = 0.85}},
			ExtraActionBar = {	enabled = true,					position = {point = "CENTER",		parent = "SUI_ActionBarPlate",	x=-32,y=240}},
			BlizzardArt	= {	enabled = false,	},
		};
	
	local lib = LibStub("LibWindow-1.1",true);
	if not lib then return; end
	function lib.RegisterConfig(frame, storage, names)
		if not lib.windowData[frame] then
			lib.windowData[frame] = {}
		end
		lib.windowData[frame].names = names
		lib.windowData[frame].storage = storage
		local parent = frame:GetParent();
		if (storage.parent) then
			frame:SetParent(storage.parent);
			if storage.parent == "SUI_ActionBarPlate" then
				frame:SetFrameStrata("LOW");
			end
		elseif (parent and parent:GetName() == "SUI_ActionBarPlate") then
			frame:SetParent(UIParent);
		end
	end
	SetupProfile = function() -- apply default settings into a custom BT4 profile
		UpdateSettings();
		-- New check for updating old profiles
		if ( not DB.ActionBars.SpartanUI_Version) then
			DB.ActionBars.SpartanUI_Version = GetAddOnMetadata("SpartanUI", "Version");
			-- Update Blizzard Art Bar settings on the standard profile
			if BartenderProfileCheck(standard,false) then
				for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
					if v.db and v.db.profile then
						-- Fixup Blizzard Art Bar
						v.db.profile["BlizzardArt"] = module:MergeData(v.db.profile["BlizzardArt"],settings["BlizzardArt"])
						-- Fixup Vehicle Bar
						v.db.profile["Vehicle"] = module:MergeData(v.db.profile["Vehicle"],settings["Vehicle"])
					end
				end
			end
		end
		--print("Using this profile: "..Bartender4.db:GetCurrentProfile())
		-- Checking for the standard Profile
		if (not BartenderProfileCheck(standard,true)) then DB.ActionBars.Bartender4 = false end
		-- Fixup setting profile to standard if standard profile exist
		if DB.ActionBars.Bartender4 then if profile == standard then Bartender4.db:SetProfile(standard) end return; end
		Bartender4.db:SetProfile(standard);
		for k,v in LibStub("AceAddon-3.0"):IterateModulesOfAddon(Bartender4) do -- for each module (BagBar, ActionBars, etc..)
			if settings[k] and v.db.profile then
				v.db.profile = module:MergeData(v.db.profile,settings[k])
			end
		end
		Bartender4:UpdateModuleConfigs(); -- run ApplyConfig for all modules, so that the new settings are applied
		if BartenderProfileCheck(standard,false) then addon:Print(standard.." Profile generated in Bartender.") end
		DB.ActionBars.Bartender4 = true;
	end
	-- Can't use UpdateInterval, due to the way this need to be working -- could this behavior be changed? - Maybe a securehoocfunc on the unlocking
	plate:HookScript("OnUpdate",function(self,...)
		if (InCombatLockdown()) then return; end
		if (Bartender4.db:GetCurrentProfile() == standard) or (Bartender4.db:GetCurrentProfile() == newtest) then
			if Bartender4.Locked then return; end
			addon:Print("The ability to unlock your bars is disabled when using the SpartanUI Default profile in Bartender4. Please change profiles to enable this functionality.");
			--Bartender4:Lock();
		end
	end);
end;

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

function module:OnInitialize()
	do -- create bar plate and masks
		plate = CreateFrame("Frame","SUI_ActionBarPlate",SpartanUI,"SUI_ActionBarsTemplate");
		plate:SetFrameStrata("BACKGROUND"); plate:SetFrameLevel(1);
		plate:SetPoint("BOTTOM");
		
		plate.mask1 = CreateFrame("Frame","SUI_Popup1Mask",SpartanUI,"SUI_Popup1MaskTemplate");
		plate.mask1:SetFrameStrata("MEDIUM"); plate.mask1:SetFrameLevel(0);
		plate.mask1:SetPoint("BOTTOM",SUI_Popup1,"BOTTOM");
		
		plate.mask2 = CreateFrame("Frame","SUI_Popup2Mask",SpartanUI,"SUI_Popup2MaskTemplate");
		plate.mask2:SetFrameStrata("MEDIUM"); plate.mask2:SetFrameLevel(0);
		plate.mask2:SetPoint("BOTTOM",SUI_Popup2,"BOTTOM");
	end
	addon.optionsGeneral.args["backdrop"] = {
		name = "ActionBar Settings",
		desc = "configure actionbar backdrops",
		type = "group", args = {
			Allalpha = {name = "Alpha for all bars", type="range", order = 15,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.Allalpha; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].alpha,DB.ActionBars.Allalpha = val,val; end end
			},
			Allenable = {name = "Enable all bars", type="toggle", order= 16,
				get = function(info) return DB.ActionBars.Allenable; end,
				set = function(info,val) for i = 1,6 do DB.ActionBars["bar"..i].enable,DB.ActionBars.Allenable = val,val; end end
			},
			bar1alpha = {name = "Alpha for bar 1", type="range", order = 1,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar1.alpha; end,
				set = function(info,val) if DB.ActionBars.bar1.enable == true then DB.ActionBars.bar1.alpha = val end end
			},
			bar1enable = {name = "Enable bar 1", type="toggle", order= 2,
				get = function(info) return DB.ActionBars.bar1.enable; end,
				set = function(info,val) DB.ActionBars.bar1.enable = val end
			},
			bar2alpha = {name = "Alpha for bar 2", type="range", order = 3,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar2.alpha; end,
				set = function(info,val) if DB.ActionBars.bar2.enable == true then DB.ActionBars.bar2.alpha = val end end
			},
			bar2enable = {name = "Enable bar 2", type="toggle", order= 4,
				get = function(info) return DB.ActionBars.bar2.enable; end,
				set = function(info,val) DB.ActionBars.bar2.enable = val end
			},
			bar3alpha = {name = "Alpha for bar 3", type="range", order = 5,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar3.alpha; end,
				set = function(info,val) if DB.ActionBars.bar3.enable == true then DB.ActionBars.bar3.alpha = val end end
			},
			bar3enable = {name = "Enable bar 3", type="toggle", order= 6,
				get = function(info) return DB.ActionBars.bar3.enable; end,
				set = function(info,val) DB.ActionBars.bar3.enable = val end
			},
			bar4alpha = {name = "Alpha for bar 4", type="range", order = 7,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar4.alpha; end,
				set = function(info,val) if DB.ActionBars.bar4.enable == true then DB.ActionBars.bar4.alpha = val end end
			},
			bar4enable = {name = "Enable bar 4", type="toggle", order= 8,
				get = function(info) return DB.ActionBars.bar4.enable; end,
				set = function(info,val) DB.ActionBars.bar4.enable = val end
			},
			bar5alpha = {name = "Alpha for bar 5", type="range", order = 9,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar5.alpha; end,
				set = function(info,val) if DB.ActionBars.bar5.enable == true then DB.ActionBars.bar5.alpha = val end end
			},
			bar5enable = {name = "Enable bar 5", type="toggle", order= 10,
				get = function(info) return DB.ActionBars.bar5.enable; end,
				set = function(info,val) DB.ActionBars.bar5.enable = val end
			},
			bar6alpha = {name = "Alpha for bar 6", type="range", order = 11,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.bar6.alpha; end,
				set = function(info,val) if DB.ActionBars.bar6.enable == true then DB.ActionBars.bar6.alpha = val end end
			},
			bar6enable = {name = "Enable bar 6", type="toggle", order= 12,
				get = function(info) return DB.ActionBars.bar6.enable; end,
				set = function(info,val) DB.ActionBars.bar6.enable = val end
			},
			reset = {
				type = "execute",
				name = "Reset ActionBars",
				desc = "resets all ActionBar options to default",
				order= 99,
				width= "full",
				func = function()
					if (InCombatLockdown()) then 
						addon:Print(ERR_NOT_IN_COMBAT);
					else
						DB.ActionBars = {};
						SetupProfile();
						addon:Print("ActionBar Options Reset");
					end
				end
			}
		}
	};
	addon.optionsGeneral.args["popup"] = {
		name = "Popup Animations",
		desc = "Toggle popup bar animations",
		type = "group", args = {
			popup1anim = {	name = "Animate left popup",	type="toggle",	order=1, width="full",
				get = function(info) return DB.ActionBars.popup1.anim; end,
				set = function(info,val) DB.ActionBars.popup1.anim = val; end
			},
			popup1alpha = {	name = "Alpha left popup",		type="range",	order=2,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.popup1.alpha; end,
				set = function(info,val) if DB.ActionBars.popup1.enable == true then DB.ActionBars.popup1.alpha = val end end
			},
			popup1enable = {name = "Enable left popup",		type="toggle",	order=3,
				get = function(info) return DB.ActionBars.popup1.enable; end,
				set = function(info,val) DB.ActionBars.popup1.enable = val end
			},
			popup2anim = {	name = "Animate right popup",	type="toggle",	order=4, width="full",
				get = function(info) return DB.ActionBars.popup2.anim; end,
				set = function(info,val) DB.ActionBars.popup2.anim = val; end
			},
			popup2alpha = {	name = "Alpha right popup",		type="range",	order=5,
				min=0, max=100, step=1,
				get = function(info) return DB.ActionBars.popup2.alpha; end,
				set = function(info,val) if DB.ActionBars.popup2.enable == true then DB.ActionBars.popup2.alpha = val end end
			},
			popup2enable = {name = "Enable right popup",	type="toggle",	order=6,
				get = function(info) return DB.ActionBars.popup2.enable; end,
				set = function(info,val) DB.ActionBars.popup2.enable = val end
			}
		}
	};
	SetupBartender();
end

function module:OnEnable()
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
				if (DB.ActionBars) then
					for b = 1,6 do -- for each backdrop
						if DB.ActionBars["bar"..b].enable then -- backdrop enabled
							_G["SUI_Bar"..b]:SetAlpha(DB.ActionBars["bar"..b].alpha/100 or 1); -- apply alpha
						else -- backdrop disabled
							_G["SUI_Bar"..b]:SetAlpha(0);
						end
					end
					for p = 1,2 do -- for each popup
						if (DB.ActionBars["popup"..p].enable) then -- popup enabled
							_G["SUI_Popup"..p]:SetAlpha(DB.ActionBars["popup"..p].alpha/100 or 1); -- apply alpha
							if DB.ActionBars["popup"..p].anim == true then --- animation enabled
								_G["SUI_Popup"..p.."MaskBG"]:SetAlpha(1);
							else -- animation disabled
								_G["SUI_Popup"..p.."MaskBG"]:SetAlpha(0);
							end
						else -- popup disabled
							_G["SUI_Popup"..p]:SetAlpha(0);
							_G["SUI_Popup"..p.."MaskBG"]:SetAlpha(0);
						end
					end
					if (MouseIsOver(SUI_Popup1Mask)) then -- popup1 animation
						SUI_Popup1MaskBG:Hide();
						SUI_Popup2MaskBG:Show();
					elseif (MouseIsOver(SUI_Popup2Mask)) then -- popup2 animation
						SUI_Popup2MaskBG:Hide();
						SUI_Popup1MaskBG:Show();
					else -- animation at rest
						SUI_Popup1MaskBG:Show();
						SUI_Popup2MaskBG:Show();
					end
				end
				self.TimeSinceLastUpdate = 0
			end
		end);
	end
	do -- modify strata / levels of backdrops
		for i = 1,6 do
			_G["SUI_Bar"..i]:SetFrameStrata("BACKGROUND");
			_G["SUI_Bar"..i]:SetFrameLevel(3);
		end
		for i = 1,2 do
			_G["SUI_Popup"..i]:SetFrameStrata("BACKGROUND");
			_G["SUI_Popup"..i]:SetFrameLevel(3);
		end
	end
	SetupProfile();
	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1,4 do
			_G["CharacterBag"..(i-1).."Slot"]:SetScale(1.25);
		end
	end
end