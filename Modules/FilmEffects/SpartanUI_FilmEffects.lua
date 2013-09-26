local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local addon = spartan:NewModule("FilmEffect");

function addon:OnInitialize()
	spartan.optionsFilmEffects.args["enable"] = {name=L["Film/Enabled"],type="toggle",order=1,width="full",
		get = function(info) return DBMod.FilmEffects.enable end,
		set = function(info,val) DBMod.FilmEffects.enable = val if val ~= true then addon:FilmEffectDisable() end end
	}
	spartan.optionsFilmEffects.args["anim"] = {name=L["Film/Effect"],type="select",order=5,width="full",
		style="dropdown",values={[""]="",["Vignette"] = L["Film/Vignette"],["blur"]=L["Film/Blur"],["crisp"]=L["Film/Crisp"]},
		get = function(info) return DBMod.FilmEffects.anim end,
		set = function(info,val) if (val == "") then addon:FilmEffectDisable(); elseif (DBMod.FilmEffects.enable) then DBMod.FilmEffects.anim = val; addon:FilmEffect() end end
	}
end

function addon:OnEnable()
		f = CreateFrame("Frame", "FilmEffects", WorldFrame);
		f:SetHeight(64); f:SetWidth(64);
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -128, 256);
		f:SetFrameStrata("BACKGROUND");
		f:RegisterEvent("PLAYER_ENTERING_WORLD");
		f:SetScript("OnEvent",function() addon:FilmEffect() end);
		f:SetScript("OnUpdate", function(self, elapsed) addon:Update(self, elapsed) end);
--		addon:FilmEffect()
end
function addon:FilmEffectDisable()
	
	if FE_Vignette then FE_Vignette:Hide(); end
	if FG_Fuzzy then FG_Fuzzy:Hide(); end
	if FG_Fuggly then FG_Fuggly:Hide(); end
	if FG_Crispy then FG_Crispy:Hide(); end
	DBMod.FilmEffects.anim = ""
end

function addon:FilmEffect()
	if DBMod.FilmEffects.anim=="Vignette" then
		local t = f:CreateTexture("FE_Vignette", "OVERLAY")
		t:SetAllPoints(UIParent)
		t:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\vignette")
		t:SetBlendMode("MOD")
	end
	
	if DBMod.FilmEffects.anim=="blur" then
		if not FG_Fuzzy then
			local t = f:CreateTexture("FG_Fuzzy", "OVERLAY")
			local t2 = f:CreateTexture("FG_Fuggly", "OVERLAY")
			t:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Add")
			t2:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Mod")
			t:SetBlendMode("ADD")
			t2:SetBlendMode("MOD")
			t:SetAlpha(.2)
			t2:SetAlpha(.05)
			
			local resolution =({GetScreenResolutions()})[GetCurrentResolution()];
			local x, y = strmatch(resolution, "(%d+)x(%d+)")
			
			t:SetHeight((tonumber(y))+256)
			t:SetWidth((tonumber(x))+256)
			t2:SetHeight((tonumber(y))+256)
			t2:SetWidth((tonumber(x))+256)
			
			t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
			t2:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
			DBMod.FilmEffects.animateGrainFuzzy = true
		else
			if FG_Fuzzy:IsVisible() then
				FG_Fuzzy:Hide()
				FG_Fuggly:Hide()
				DBMod.FilmEffects.animateGrainFuzzy = nil
			else
				FG_Fuzzy:Show()
				FG_Fuggly:Show()
				DBMod.FilmEffects.animateGrainFuzzy = true
			end
		end
	end
	
	if DBMod.FilmEffects.anim=="crisp" then
		if not _G["FG_1_1_Add"] then
			local resolution =({GetScreenResolutions()})[GetCurrentResolution()];
			local x, y = strmatch(resolution, "(%d+)x(%d+)")
			
			local i = 1
			local ix = 1
			local iy = 1
			local xLimit = math.floor((tonumber(x))/512 + 1)
			local yLimit = math.floor((tonumber(y))/512 + 1)
			local iLimit = xLimit * yLimit
			local intensity = 1
			
			local fatherF = CreateFrame("Frame", "FG_Crispy", f)
			while i <= iLimit do
				local nameAdd = "FG_"..ix.."_"..iy.."_Add"
				local nameMod = "FG_"..ix.."_"..iy.."_Mod"
				local t = fatherF:CreateTexture(nameAdd, "OVERLAY")
				local t2 = fatherF:CreateTexture(nameMod, "OVERLAY")
				
				t:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Add")
				t2:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Mod")
				
				t:SetWidth(512)
				t:SetHeight(512)
				t2:SetWidth(512)
				t2:SetHeight(512)
				
				t:SetBlendMode("ADD")
				t2:SetBlendMode("MOD")
				t:SetAlpha(intensity * .45)
				t2:SetAlpha(intensity * .3)
				
				local father, anchor
				father = _G["FG_"..(ix-1).."_"..iy.."_Add"] or _G["FG_"..ix.."_"..(iy-1).."_Add"] or f
				
				if _G["FG_"..(ix-1).."_"..iy.."_Add"] then
					anchor = "TOPRIGHT"
				elseif _G["FG_"..ix.."_"..(iy-1).."_Add"] then
					anchor = "BOTTOMLEFT"
				else
					anchor = "TOPLEFT"
				end
				
				t:SetPoint("TOPLEFT", father, anchor, 0, 0)
				t2:SetPoint("TOPLEFT", t, "TOPLEFT", 0, 0)
				
				ix = ix + 1
				if ix > xLimit then
					ix = 1
					iy = iy + 1
				end
				i = i + 1
			end
			DBMod.FilmEffects.animateGrainCrispy = true
		else
			if FG_Crispy:IsVisible() then
				FG_Crispy:Hide()
				DBMod.FilmEffects.animateGrainCrispy = nil
			else
				FG_Crispy:Show()
				DBMod.FilmEffects.animateGrainCrispy = true
			end
		end
	end
	
end

function addon:Update(self, elapsed)
	DBMod.FilmEffects.animationInterval = DBMod.FilmEffects.animationInterval + elapsed
	if (DBMod.FilmEffects.animationInterval > (0.02)) then -- 50 FPS
		DBMod.FilmEffects.animationInterval = 0
		
		local yOfs = math.random(0, 256)
		local xOfs = math.random(-128, 0)
		
		if DBMod.FilmEffects.anim=="blur" or DBMod.FilmEffects.anim=="crisp" then
			f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOfs, yOfs)
		end
	end
end

