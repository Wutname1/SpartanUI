local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local addon = spartan:NewModule("FilmEffect");
local Container
local EffectList = {"vignette", "blur", "crisp"}

local FilmEffectEvent = function(self, event, ...)
	for k,v in ipairs(EffectList) do
		if not DBMod.FilmEffects.enable then
			Container[v]:Hide()
		elseif event == "CHAT_MSG_SYSTEM" then
			if (... == format(MARKED_AFK_MESSAGE,DEFAULT_AFK_MESSAGE)) and (DBMod.FilmEffects.Effects[v].afk) then
				Container[v]:Show()
			elseif (... == CLEARED_AFK) then
				Container[v]:Hide()
			end
		else
			if DBMod.FilmEffects.Effects[v].always then
				Container[v]:Show()
			else
				Container[v]:Hide()
			end
		end
	end
end

local function updateopts()
	local disabled = true
	if DBMod.FilmEffects.enable then disabled = false end
	for k,v in ipairs(EffectList) do
		spartan.opt.args["FilmEffects"].args[v .. "always"].disabled = disabled
		spartan.opt.args["FilmEffects"].args[v .. "AFK"].disabled = disabled
	end
end

function addon:OnInitialize()
	if DBMod.FilmEffects.Effects == nil then
		DBMod.FilmEffects = 
		{
			animationInterval = 0,
			enable = true,
			Effects = {
				vignette = {always = false, afk = true},
				blur = {always = false, afk = false},
				crisp = {always = false, afk = true}
			}
		}
	end
	
	spartan.opt.args["FilmEffects"].args["enable"] = {name=L["Film/Enabled"],type="toggle",order=1,width="full",
		get = function(info) updateopts(); return DBMod.FilmEffects.enable end,
		set = function(info,val)
			if InCombatLockdown() then spartan:Print("Please leave combat first.") return end
			DBMod.FilmEffects.enable = val; FilmEffectEvent(nil,nil,nil); updateopts();
			end
	}
	
	
	for k,v in ipairs(EffectList) do
		spartan.opt.args["FilmEffects"].args[v .. "Title"] = {name=v,type="header",order=k+1,width="full"}
		spartan.opt.args["FilmEffects"].args[v .. "always"] = {name="Always show",type="toggle",order=k + 1.2,
			get = function(info) return DBMod.FilmEffects.Effects[v].always end,
			set = function(info,val) if InCombatLockdown() then spartan:Print("Please leave combat first.") return end DBMod.FilmEffects.Effects[v].always = val; FilmEffectEvent(nil,nil,nil) end
		}
		spartan.opt.args["FilmEffects"].args[v .. "AFK"] = {name="Show if AFK",type="toggle",order=k + 1.4,
			get = function(info) if InCombatLockdown() then spartan:Print("Please leave combat first.") return end return DBMod.FilmEffects.Effects[v].afk end,
			set = function(info,val) DBMod.FilmEffects.Effects[v].afk = val; end
		}
	end
end

function addon:OnEnable()
		Container = CreateFrame("Frame", "FilmEffects", WorldFrame);
		-- Container:SetSize(1,1);
		Container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
		Container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0);
		Container:SetFrameStrata("BACKGROUND");
		Container:RegisterEvent("CHAT_MSG_SYSTEM");
		Container:RegisterEvent("PLAYER_ENTERING_WORLD");
		Container:SetScript("OnEvent", FilmEffectEvent);
		Container:SetScript("OnUpdate", function(self, elapsed) addon:Update(self, elapsed) end);
		
		Container.vignette = Container:CreateTexture("FE_Vignette", "OVERLAY")
		Container.vignette:SetAllPoints(UIParent)
		Container.vignette:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\vignette")
		Container.vignette:SetBlendMode("MOD")
		
		Container.vignette:Hide()
		
		--blur
		Container.blur = CreateFrame("Frame", "FG_Crispy", Container)
		Container.blur.layer1 = Container.blur:CreateTexture("FG_Fuzzy", "OVERLAY")
		Container.blur.layer2 = Container.blur:CreateTexture("FG_Fuggly", "OVERLAY")
		Container.blur.layer1:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Add")
		Container.blur.layer2:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Mod")
		Container.blur.layer1:SetBlendMode("ADD")
		Container.blur.layer2:SetBlendMode("MOD")
		Container.blur.layer1:SetAlpha(.2)
		Container.blur.layer2:SetAlpha(.05)
		Container.blur.layer1:SetAllPoints(UIParent)
		Container.blur.layer2:SetAllPoints(UIParent)
		Container.blur:Hide()
		
		--crisp
		-- local x, y = strmatch(({GetScreenResolutions()})[GetCurrentResolution()], "(%d+)x(%d+)")
		local i = 1
		local ix = 1
		local iy = 1
		local xLimit = math.floor((tonumber(Container:GetWidth()))/512 + 1)
		local yLimit = math.floor((tonumber(Container:GetHeight()))/512 + 1)
		local iLimit = xLimit * yLimit
		local intensity = 1
		Container.crisp = CreateFrame("Frame", "FG_Crispy", Container)
		while i <= iLimit do
			local nameAdd = "FG_"..ix.."_"..iy.."_Add"
			local nameMod = "FG_"..ix.."_"..iy.."_Mod"
			Container.crisp[nameAdd] = Container.crisp:CreateTexture(nameAdd, "OVERLAY")
			Container.crisp[nameMod] = Container.crisp:CreateTexture(nameMod, "OVERLAY")
			
			Container.crisp[nameAdd]:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Add")
			Container.crisp[nameMod]:SetTexture("Interface\\AddOns\\SpartanUI_FilmEffects\\media\\25ASA_Mod")
			
			Container.crisp[nameAdd]:SetSize(512,512)
			Container.crisp[nameMod]:SetSize(512,512)
			
			Container.crisp[nameAdd]:SetBlendMode("ADD")
			Container.crisp[nameMod]:SetBlendMode("MOD")
			Container.crisp[nameAdd]:SetAlpha(intensity * .45)
			Container.crisp[nameMod]:SetAlpha(intensity * .3)
			
			local father, anchor
			father = _G["FG_"..(ix-1).."_"..iy.."_Add"] or _G["FG_"..ix.."_"..(iy-1).."_Add"] or Container
			
			if _G["FG_"..(ix-1).."_"..iy.."_Add"] then
				anchor = "TOPRIGHT"
			elseif _G["FG_"..ix.."_"..(iy-1).."_Add"] then
				anchor = "BOTTOMLEFT"
			else
				anchor = "TOPLEFT"
			end
			
			Container.crisp[nameAdd]:SetPoint("TOPLEFT", father, anchor, 0, 0)
			Container.crisp[nameMod]:SetPoint("TOPLEFT", Container.crisp[nameAdd], "TOPLEFT", 0, 0)
			
			ix = ix + 1
			if ix > xLimit then
				ix = 1
				iy = iy + 1
			end
			i = i + 1
		end
		
		Container.crisp:Hide()
end
function addon:tmp()


end
function addon:Update(self, elapsed)
	DBMod.FilmEffects.animationInterval = DBMod.FilmEffects.animationInterval + elapsed
	if (DBMod.FilmEffects.animationInterval > (0.02)) then -- 50 FPS
		DBMod.FilmEffects.animationInterval = 0
		
		local yOfs = math.random(0, 256)
		local xOfs = math.random(-128, 0)
		
		if DBMod.FilmEffects.anim=="blur" or DBMod.FilmEffects.anim=="crisp" then
			Container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOfs, yOfs)
		end
	end
end

