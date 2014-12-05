local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceConfig = LibStub("AceConfig-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");
local module = spartan:NewModule("Options");
---------------------------------------------------------------------------

function module:OnInitialize()
	spartan.opt.args["General"].args["SuiVersion"] = {name = "SpartanUI "..L["Version"]..": "..SpartanVer,order=1,type = "header"};
	if (SpartanVer ~= CurseVersion) then
		spartan.opt.args["General"].args["CurseVersion"] = {name = "Build "..CurseVersion,order=1.1,type = "header"};
	end
	spartan.opt.args["General"].args["reset"] = {name = L["ResetDatabase"],type = "execute",order=999,
		desc = L["ResetDatabaseDesc"],
		func = function()
			if (InCombatLockdown()) then 
				spartan:Print(ERR_NOT_IN_COMBAT);
			else
				spartan.db:ResetDB();
				ReloadUI();
			end
		end
	};
	spartan.opt.args["General"].args["font"] = {name = L["FontSizeStyle"], type = "group",
		args = {
			line0 = {name=L["GFontSet"],type="header",order=20},
			GFace = {name = L["FontType"], type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Primary.Face; end,
				set = function(info,val) DB.font.Primary.Face = val; end
			},
			GOutline = {name = L["FontStyle"], type="select", order = 2,
				values = {["normal"]=L["normal"], ["monochrome"]=L["monochrome"], ["outline"]=L["outline"], ["thickoutline"]=L["thickoutline"]},
				get = function(info) return DB.font.Primary.Type; end,
				set = function(info,val) DB.font.Primary.Type = val; end
			},
			GSize = {name = L["AdjFontSize"], type="range", order = 3,width="double",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Primary.Size; end,
				set = function(info,val) DB.font.Primary.Size = val; end
			},
			line1 = {name="",type="header",order=20},
			ApplyToCore = {name = L["AplyGlobal"].." "..L["CoreSet"], type="execute", order = 21,
				func = function()
					DB.font.Core.Face = DB.font.Primary.Face;
					DB.font.Core.Type = DB.font.Primary.Type;
					DB.font.Core.Size = DB.font.Primary.Size;
					spartan:FontRefresh("Core");
				end
			},
			ApplyToPlayer = {name = L["AplyGlobal"].." "..L["PlayerSet"], type="execute", order = 22,
				disabled = function(info) if not spartan:GetModule("PlayerFrames", true) then return true end end,
				func = function()
					DB.font.Player.Face = DB.font.Primary.Face;
					DB.font.Player.Type = DB.font.Primary.Type;
					DB.font.Player.Size = DB.font.Primary.Size;
					spartan:FontRefresh("Player");
				end
			},
			ApplyToParty = {name = L["AplyGlobal"].." "..L["PartySet"], type="execute", order = 23,
				disabled = function(info) if not spartan:GetModule("PartyFrames", true) then return true end end,
				func = function()
					DB.font.Party.Face = DB.font.Primary.Face;
					DB.font.Party.Type = DB.font.Primary.Type;
					DB.font.Party.Size = DB.font.Primary.Size;
					spartan:FontRefresh("Party");
				end
			},
			ApplyToRaid = {name = L["AplyGlobal"].." "..L["RaidSet"], type="execute", order = 24,
				disabled = function(info) if not spartan:GetModule("RaidFrames", true) then return true end end,
				func = function()
					DB.font.Raid.Face = DB.font.Primary.Face;
					DB.font.Raid.Type = DB.font.Primary.Type;
					DB.font.Raid.Size = DB.font.Primary.Size;
					spartan:FontRefresh("Raid");
				end
			},
			ApplyToAll = {name = L["AplyGlobal"].." "..L["AllSet"], type="execute", order = 28,width="double",
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
end

