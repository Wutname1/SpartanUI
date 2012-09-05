local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("FontSettings");
---------------------------------------------------------------------------
local FontItems = {Primary={},Core={},Party={},Player={},Raid={}}
local FontItemsSize = {Primary={},Core={},Party={},Player={},Raid={}}

function module:OnInitialize()
	addon.optionsFont.args["Primary"] = {name = "Global",type = "group",order=1,
		args = {
			GFace = {name = "Font Type", type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Primary.Face; end,
				set = function(info,val) DB.font.Primary.Face = val; end
			},
			GOutline = {name = "Font Style", type="select", order = 2,
				values = {["normal"]="normal", ["monochrome"]="monochrome", ["outline"]="outline", ["thickoutline"]="thickoutline"},
				get = function(info) return DB.font.Primary.Type; end,
				set = function(info,val) DB.font.Primary.Type = val; end
			},
			GSize = {name = "Adjust Font Size", type="range", order = 3,width="double",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Primary.Size; end,
				set = function(info,val) DB.font.Primary.Size = val; end
			},
			line = {name="",type="header",order=20},
			ApplyToCore = {name = "Apply Global to Core", type="execute", order = 21,
				func = function()
					DB.font.Core.Face = DB.font.Primary.Face;
					DB.font.Core.Type = DB.font.Primary.Type;
					DB.font.Core.Size = DB.font.Primary.Size;
					addon:FontRefresh("Core");
				end
			},
			ApplyToPlayer = {name = "Apply Global to Player", type="execute", order = 22,
				func = function()
					DB.font.Player.Face = DB.font.Primary.Face;
					DB.font.Player.Type = DB.font.Primary.Type;
					DB.font.Player.Size = DB.font.Primary.Size;
					addon:FontRefresh("Player");
				end
			},
			ApplyToParty = {name = "Apply Global to Party", type="execute", order = 23,
				func = function()
					DB.font.Party.Face = DB.font.Primary.Face;
					DB.font.Party.Type = DB.font.Primary.Type;
					DB.font.Party.Size = DB.font.Primary.Size;
					addon:FontRefresh("Party");
				end
			},
			ApplyToRaid = {name = "Apply Global to Raid", type="execute", order = 24,
				func = function()
					DB.font.Raid.Face = DB.font.Primary.Face;
					DB.font.Raid.Type = DB.font.Primary.Type;
					DB.font.Raid.Size = DB.font.Primary.Size;
					addon:FontRefresh("Raid");
				end
			},
			ApplyToAll = {name = "Apply Global to All", type="execute", order = 28,width="double",
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
					addon:FontRefresh("Core");
					addon:FontRefresh("Player");
					addon:FontRefresh("Party");
					addon:FontRefresh("Raid");
				end
			}
		}
	}
	addon.optionsFont.args["Core"] = {name = "Core Settings",type = "group",order=2,
		args = {
			CFace = {name = "Font Type", type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Core.Face; end,
				set = function(info,val) DB.font.Core.Face = val; addon:FontRefresh("Core") end
			},
			COutline = {name = "Font Style", type="select", order = 2,
				values = {["normal"]="normal", ["monochrome"]="monochrome", ["outline"]="outline", ["thickoutline"]="thickoutline"},
				get = function(info) return DB.font.Core.Type; end,
				set = function(info,val) DB.font.Core.Type = val; addon:FontRefresh("Core") end
			},
			CSize = {name = "Adjust Font Size", type="range", order = 3,width="full",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Core.Size; end,
				set = function(info,val) DB.font.Core.Size = val; addon:FontRefresh("Core") end
			}
		}
	}
	addon.optionsFont.args["Player"] = {name = "Player Settings",type = "group",order=3,
		args = {
			PlFace = {name = "Font Type", type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Player.Face; end,
				set = function(info,val) DB.font.Player.Face = val; addon:FontRefresh("Player") end
			},
			PlOutline = {name = "Font Style", type="select", order = 2,
				values = {["normal"]="normal", ["monochrome"]="monochrome", ["outline"]="outline", ["thickoutline"]="thickoutline"},
				get = function(info) return DB.font.Player.Type; end,
				set = function(info,val) DB.font.Player.Type = val; addon:FontRefresh("Player") end
			},
			PlSize = {name = "Adjust Font Size", type="range", order = 3,width="full",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Player.Size; end,
				set = function(info,val) DB.font.Player.Size = val; addon:FontRefresh("Player") end
			}
		}
	}
	addon.optionsFont.args["Party"] = {name = "Party Settings",type = "group",order=4,
		args = {
			PaFace = {name = "Font Type", type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Party.Face; end,
				set = function(info,val) DB.font.Party.Face = val; addon:FontRefresh("Party") end
			},
			PaOutline = {name = "Font Style", type="select", order = 2,
				values = {["normal"]="normal", ["monochrome"]="monochrome", ["outline"]="outline", ["thickoutline"]="thickoutline"},
				get = function(info) return DB.font.Party.Type; end,
				set = function(info,val) DB.font.Party.Type = val; addon:FontRefresh("Party") end
			},
			PaSize = {name = "Adjust Font Size", type="range", order = 3,width="full",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Party.Size; end,
				set = function(info,val) DB.font.Party.Size = val; addon:FontRefresh("Party") end
			}
		}
	}
	addon.optionsFont.args["Raid"] = {name = "Raid Settings",type = "group",order=5,
		args = {
			RFace = {name = "Font Type", type="select", order = 1,
				values = {["SpartanUI"]="SpartanUI",["FrizQuadrata"]="Friz Quadrata",["ArialNarrow"]="Arial Narrow",["Skurri"]="Skurri",["Morpheus"]="Morpheus"},
				get = function(info) return DB.font.Raid.Face; end,
				set = function(info,val) DB.font.Raid.Face = val; addon:FontRefresh("Raid") end
			},
			ROutline = {name = "Font Style", type="select", order = 2,
				values = {["normal"]="normal", ["monochrome"]="monochrome", ["outline"]="outline", ["thickoutline"]="thickoutline"},
				get = function(info) return DB.font.Raid.Type; end,
				set = function(info,val) DB.font.Raid.Type = val; addon:FontRefresh("Raid") end
			},
			RSize = {name = "Adjust Font Size", type="range", order = 3,width="full",
				min=-3,max=3,step=1,
				get = function(info) return DB.font.Raid.Size; end,
				set = function(info,val) DB.font.Raid.Size = val; addon:FontRefresh("Raid") end
			}
		}
	}
end

function addon:FormatFont(element, size, Module)
	--Set Font Outline
	flags = ""
	if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
	if DB.font[Module].Type == "outline" then flags = flags.."outline " end
	if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
	--Set Size
	sizeFinal = size + DB.font[Module].Size;
	--Create Font
	if DB.font[Module].Face == "SpartanUI" then
		element:SetFont("Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf", sizeFinal, flags)
	elseif DB.font[Module].Face == "FrizQuadrata" then
		element:SetFont("Fonts\\FRIZQT__.TTF", sizeFinal, flags)
	elseif DB.font[Module].Face == "ArialNarrow" then
		element:SetFont("Fonts\\ARIALN.TTF", sizeFinal, flags)
	elseif DB.font[Module].Face == "Skurri" then
		element:SetFont("Fonts\\skurri.TTF", sizeFinal, flags)
	elseif DB.font[Module].Face == "Morpheus" then
		element:SetFont("Fonts\\MORPHEUS.TTF", sizeFinal, flags)
	end
	--Add Item to the Array
	local count = 0
	for _ in pairs(FontItems[Module]) do count = count + 1 end
	FontItems[Module][count+1]=element
	FontItemsSize[Module][count+1]=size
end

function addon:FontRefresh(Module)
	for a,b in pairs(FontItems[Module]) do
		--Set Font Outline
		flags = ""
		if DB.font[Module].Type == "monochrome" then flags = flags.."monochrome " end
		if DB.font[Module].Type == "outline" then flags = flags.."outline " end
		if DB.font[Module].Type == "thickoutline" then flags = flags.."thickoutline " end
		--Set Size
		size = FontItemsSize[Module][a] + DB.font[Module].Size;
		--Update Font
		if DB.font[Module].Face == "SpartanUI" then
			b:SetFont("Interface\\AddOns\\SpartanUI\\media\\font-cognosis.ttf", size, flags)
		elseif DB.font[Module].Face == "FrizQuadrata" then
			b:SetFont("Fonts\\FRIZQT__.TTF", size, flags)
		elseif DB.font[Module].Face == "ArialNarrow" then
			b:SetFont("Fonts\\ARIALN.TTF", size, flags)
		elseif DB.font[Module].Face == "Skurri" then
			b:SetFont("Fonts\\skurri.TTF", size, flags)
		elseif DB.font[Module].Face == "Morpheus" then
			b:SetFont("Fonts\\MORPHEUS.TTF", size, flags)
		end
	end
end

function module:OnEnable()

end