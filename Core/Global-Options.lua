local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local module = spartan:NewModule("Options");
---------------------------------------------------------------------------
local ModsLoaded =  {
	Artwork = nil,
	PlayerFrames = nil,
	PartyFrames = nil,
	RaidFrames = nil,
	SpinCam = nil,
	FilmEffects = nil
}

function module:OnInitialize()
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_Artwork")
	ModsLoaded.Artwork = enabled
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_PlayerFrames")
	ModsLoaded.PlayerFrames = enabled
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_PartyFrames")
	ModsLoaded.PartyFrames = enabled
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_RaidFrames")
	ModsLoaded.RaidFrames = enabled
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_SpinCam")
	ModsLoaded.SpinCam = enabled
	local name, title, notes, enabled,loadable = GetAddOnInfo("SpartanUI_FilmEffects")
	ModsLoaded.FilmEffects = enabled
	
	spartan.opt.args["General"].args["SuiVersion"] = {name = "SpartanUI "..L["Version"]..": "..spartan.SpartanVer,order=1,type = "header"};
	if (spartan.SpartanVer ~= spartan.CurseVersion) then
		spartan.opt.args["General"].args["CurseVersion"] = {name = "Build "..spartan.CurseVersion,order=1.1,type = "header"};
	end

	spartan.opt.args["General"].args["style"] = {name = L["StyleSettings"], type = "group",order = 100,
		args = {
			description = {type="header",name=L["OverallStyle"],order=1},
			OverallStyle = { name = "", type = "group", inline=true,order=10, args = {
				Classic = {name = "Classic", type="execute",
					image=function() return "interface\\addons\\SpartanUI_Artwork\\Themes\\Classic\\Images\\base-center", 120, 60 end,
					-- imageCoords=function() return {0,1,0,1} end,
					func = function() DBMod.Artwork.Style = "Classic"; newtheme = spartan:GetModule("Style_Classic") newtheme:SetupProfile(); ReloadUI(); end
				},
			}},
			PlayerFrames = {type="group",name=L["PlayerFrames"],order=100,args = {
			}},
			
			PartyFrames = {type="group",name=L["PartyFrames"],order=200,args = {
			}},
			
			RaidFrames = {type="group",name=L["RaidFrames"],order=300,args = {
			}},
			
		}
	};
	spartan.opt.args["General"].args["font"] = {name = L["FontSizeStyle"], type = "group",order = 200,
		args = {
			a = {name=L["GFontSet"],type="header"},
			b = {name = L["FontType"], type="select",
				values = {["SpartanUI"]="Cognosis",["SUI4"]="NotoSans",["SUI4cn"]="NotoSans (zhCN)",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Primary.Face; end,
				set = function(info,val) DB.font.Primary.Face = val; end
			},
			c = {name = L["FontStyle"], type="select",
				values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
				get = function(info) return DB.font.Primary.Type; end,
				set = function(info,val) DB.font.Primary.Type = val; end
			},
			d = {name = L["AdjFontSize"], type="range",width="double",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Primary.Size; end,
				set = function(info,val) DB.font.Primary.Size = val; end
			},
			z = {name = L["AplyGlobal"].." "..L["AllSet"], type="execute",width="double",
				func = function()
					DB.font.Core.Face = DB.font.Primary.Face;
					DB.font.Core.Type = DB.font.Primary.Type;
					DB.font.Core.Size = DB.font.Primary.Size;
					DB.font.Player.Face = DB.font.Primary.Face;
					DB.font.Player.Type = DB.font.Primary.Type;
					DB.font.Player.Size = DB.font.Primary.Size;
					DB.font.Party.Face = DB.font.Primary.Face;
					DB.font.Party.Type = DB.font.Primary.Type;
					DB.font.Party.Size = DB.font.Primary.Size;
					DB.font.Raid.Face = DB.font.Primary.Face;
					DB.font.Raid.Type = DB.font.Primary.Type;
					DB.font.Raid.Size = DB.font.Primary.Size;
					spartan:FontRefresh("Core");
					spartan:FontRefresh("Player");
					spartan:FontRefresh("Party");
					spartan:FontRefresh("Raid");
				end
			},
		
			Core = {name = L["CoreSet"],type = "group",
				args = {
					CFace = {name = L["FontType"], type="select", order = 1,
						values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
						get = function(info) return DB.font.Core.Face; end,
						set = function(info,val) DB.font.Core.Face = val; spartan:FontRefresh("Core") end
					},
					COutline = {name = L["FontStyle"], type="select", order = 2,
						values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
						get = function(info) return DB.font.Core.Type; end,
						set = function(info,val) DB.font.Core.Type = val; spartan:FontRefresh("Core") end
					},
					CSize = {name = L["AdjFontSize"], type="range", order = 3,width="full",
						min=-3,max=3,step=1,
						get = function(info) return DB.font.Core.Size; end,
						set = function(info,val) DB.font.Core.Size = val; spartan:FontRefresh("Core") end
					}
				}
			},
			Player = {name = L["PlayerSet"],type = "group",
				disabled = function(info) if not spartan:GetModule("PlayerFrames", true) then return true end end,
				args = {
					PlFace = {name = L["FontType"], type="select", order = 1,
						values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
						get = function(info) return DB.font.Player.Face; end,
						set = function(info,val) DB.font.Player.Face = val; spartan:FontRefresh("Player") end
					},
					PlOutline = {name = L["FontStyle"], type="select", order = 2,
						values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
						get = function(info) return DB.font.Player.Type; end,
						set = function(info,val) DB.font.Player.Type = val; spartan:FontRefresh("Player") end
					},
					PlSize = {name = L["AdjFontSize"], type="range", order = 3,width="full",
						min=-3,max=3,step=1,
						get = function(info) return DB.font.Player.Size; end,
						set = function(info,val) DB.font.Player.Size = val; spartan:FontRefresh("Player") end
					}
				}
			},
			Party = {name = L["PartySet"],type = "group",
				disabled = function(info) if not spartan:GetModule("PartyFrames", true) then return true end end,
				args = {
					PaFace = {name = L["FontType"], type="select", order = 1,
						values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
						get = function(info) return DB.font.Party.Face; end,
						set = function(info,val) DB.font.Party.Face = val; spartan:FontRefresh("Party") end
					},
					PaOutline = {name = L["FontStyle"], type="select", order = 2,
						values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
						get = function(info) return DB.font.Party.Type; end,
						set = function(info,val) DB.font.Party.Type = val; spartan:FontRefresh("Party") end
					},
					PaSize = {name = L["AdjFontSize"], type="range", order = 3,width="full",
						min=-3,max=3,step=1,
						get = function(info) return DB.font.Party.Size; end,
						set = function(info,val) DB.font.Party.Size = val; spartan:FontRefresh("Party") end
					}
				}
			},
			raid = {name = L["RaidSet"],type = "group",
				disabled = function(info) if not spartan:GetModule("RaidFrames", true) then return true end end,
				args = {
					RFace = {name = L["FontType"], type="select", order = 1,
						values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
						get = function(info) return DB.font.Raid.Face; end,
						set = function(info,val) DB.font.Raid.Face = val; spartan:FontRefresh("Raid") end
					},
					ROutline = {name = L["FontStyle"], type="select", order = 2,
						values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
						get = function(info) return DB.font.Raid.Type; end,
						set = function(info,val) DB.font.Raid.Type = val; spartan:FontRefresh("Raid") end
					},
					RSize = {name = L["AdjFontSize"], type="range", order = 3,width="full",
						min=-3,max=3,step=1,
						get = function(info) return DB.font.Raid.Size; end,
						set = function(info,val) DB.font.Raid.Size = val; spartan:FontRefresh("Raid") end
					}
				}
			},
		}
	};
	spartan.opt.args["General"].args["Help"] = {name = "Help", type = "group", order = 900,
		args = {
			ResetDB			= {name = L["ResetDatabase"], type = "execute", width= "double",order=1, func = function() spartan.db:ResetDB(); ReloadUI(); end},
			ResetArtwork	= {name = "Reset ActionBars", type = "execute", width= "double",order=2, func = function() DBMod.Artwork.FirstLoad = true; spartan:GetModule("Style_"..DBMod.Artwork.Style):SetupProfile(); ReloadUI(); end},
			
			navigationissues = {name="Have a Question?",type="description",order = 100,fontSize="large"},
			navigationissues2 = {name="    -|cff6666FF http://faq.spartanui.net/",type="description",order = 101,fontSize="medium"},
			
			bugsandfeatures = {name="Bugs & Feature Requests:",type="description",order = 200,fontSize="large"},
			bugsandfeatures2 = {name="     -|cff6666FF http://bugs.spartanui.net/",type="description",order = 201,fontSize="medium"},
			bugsandfeatures3 = {name="     -|cff6666FF http://wow.curseforge.com/addons/spartan-ui/tickets/",type="description",order = 202,fontSize="medium"},
			
			
			line = {name="",type="header",order = 900},
			description = {name="Providing the below string can assist in helping you when you are having issues",type="description",order = 901,fontSize="large"},
			dataDump = {name="Export",type="input",multiline=10,width="full",order=990,get = function(info) return module:enc(module:ExportData()) end},
			description = {name="This string contains your Spec, Region, SpartanUI Settings, and a list of running addons.",type="description",order = 999,fontSize="small"},
			}
		}
	
	spartan.opt.args["General"].args["ModSetting"] = {name = "Modules", type = "group", order = 800,
		args = {
			description = {type="description",name="Here you can enable and disable the modules contained in or related to SpartanUI",order=1,fontSize="medium"},
			Artwork = {name = "Artwork",type = "toggle",order=10,
				get = function(info) return ModsLoaded.Artwork end,
				set = function(info,val)
					if ModsLoaded.Artwork then ModsLoaded.Artwork = false else ModsLoaded.Artwork = true end
					if ModsLoaded.Artwork then EnableAddOn("SpartanUI_Artwork") else DisableAddOn("SpartanUI_Artwork") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			PlayerFrames = {name = "Player Frames",type = "toggle",order=20,
				get = function(info) return ModsLoaded.PlayerFrames end,
				set = function(info,val)
					if ModsLoaded.PlayerFrames then ModsLoaded.PlayerFrames = false else ModsLoaded.PlayerFrames = true end
					if ModsLoaded.PlayerFrames then EnableAddOn("SpartanUI_PlayerFrames") else DisableAddOn("SpartanUI_PlayerFrames") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			PartyFrames = {name = "Party Frames",type = "toggle",order=30,
				get = function(info) return ModsLoaded.PartyFrames end,
				set = function(info,val)
					if ModsLoaded.PartyFrames then ModsLoaded.PartyFrames = false else ModsLoaded.PartyFrames = true end
					if ModsLoaded.PartyFrames then EnableAddOn("SpartanUI_PartyFrames") else DisableAddOn("SpartanUI_PartyFrames") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			RaidFrames = {name = "Raid Frames",type = "toggle",order=40,
				get = function(info) return ModsLoaded.RaidFrames end,
				set = function(info,val)
					if ModsLoaded.RaidFrames then ModsLoaded.RaidFrames = false else ModsLoaded.RaidFrames = true end
					if ModsLoaded.RaidFrames then EnableAddOn("SpartanUI_RaidFrames") else DisableAddOn("SpartanUI_RaidFrames") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			SpinCam = {name = "Spin Cam",type = "toggle",order=50,
				get = function(info) return ModsLoaded.SpinCam end,
				set = function(info,val)
					if ModsLoaded.SpinCam then ModsLoaded.SpinCam = false else ModsLoaded.SpinCam = true end
					if ModsLoaded.SpinCam then EnableAddOn("SpartanUI_SpinCam") else DisableAddOn("SpartanUI_SpinCam") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			FilmEffects = {name = "Film Effects",type = "toggle",order=60,
				get = function(info) return ModsLoaded.FilmEffects end,
				set = function(info,val)
					if ModsLoaded.FilmEffects then ModsLoaded.FilmEffects = false else ModsLoaded.FilmEffects = true end
					if ModsLoaded.FilmEffects then EnableAddOn("SpartanUI_FilmEffects") else DisableAddOn("SpartanUI_FilmEffects") end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			},
			Styles = {name = "Styles",type = "group",order=100,inline=true,args={}},
			Reload = {name = "ReloadUI", type = "execute",order=200,disabled=true, func = function() spartan:reloadui(); end},
		}
	}

	for i = 1, GetNumAddOns() do
		local name, title, notes, enabled,loadable = GetAddOnInfo(i)
		ModsLoaded[name] = enabled
		
		if (string.match(name, "SpartanUI_Style_")) then
			spartan.opt.args["General"].args["ModSetting"].args["Styles"].args[string.sub(name, 9)] = {
			name = string.sub(name, 17),type = "toggle",order=40,
				get = function(info) return ModsLoaded[name] end,
				set = function(info,val)
					if ModsLoaded[name] then ModsLoaded[name] = false else ModsLoaded[name] = true end
					if ModsLoaded[name] then EnableAddOn(name) else DisableAddOn(name) end
					spartan.opt.args["General"].args["ModSetting"].args["Reload"].disabled = false;
				end,
			}
		end
		
	end
end

function module:OnEnable()
	
	if not spartan:GetModule("Artwork_Core", true) then
		spartan.opt.args["General"].args["style"].args["OverallStyle"].disabled = true
	end
end

function module:ExportData()
	--Get Character Data
    CharData = {
		Region = GetCurrentRegion(),
		PlayerName = UnitName("player"),
		PlayerLevel = UnitLevel("player"),
		ActiveSpec = GetSpecializationInfo(GetSpecialization())
	}
	
	--Generate List of Addons
	AddonsInstalled = {}
	
	for i = 1, GetNumAddOns() do
		local name, title, notes, enabled,loadable = GetAddOnInfo(i)
		if enabled == true then
			AddonsInstalled[i] = name
		end
	end
	
	return "$SUI." .. spartan.SpartanVer .. "-" .. spartan.CurseVersion
		.. "$C." .. module:FlatenTable(CharData)
		.. "$DB." .. module:FlatenTable(DB)
		.. "$DBMod." .. module:FlatenTable(DBMod)
		.. "$Addons." .. module:FlatenTable(AddonsInstalled)
end

function module:FlatenTable(input)
	returnval = ""
	for key,value in pairs(input) do
		if (type(value) == "table") then
			returnval = returnval .. key .. "= {" .. module:FlatenTable(value) .. "},"
		elseif (type(value) ~= "string") then
			returnval = returnval .. key .. "=" .. tostring(value) .. ","
		else
			returnval = returnval .. key .. "=" .. value .. ","
		end
	end
	return returnval
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
-- encoding
function module:enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
 
-- decoding
function module:dec(data)

    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(7-i) or 0) end
        return string.char(c)
    end))
end
