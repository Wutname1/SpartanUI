local _G, SUI = _G, SUI
local L = SUI.L
local addon = SUI:NewModule("FilmEffect");
local Container
local EffectList = {"vignette", "blur", "crisp"}

local FilmEffectEvent = function(self, event, ...)
	for k,v in ipairs(EffectList) do
		if not SUI.DBMod.FilmEffects.enable then
			Container[v]:Hide()
		elseif event == "CHAT_MSG_SYSTEM" then
			if (... == format(MARKED_AFK_MESSAGE,DEFAULT_AFK_MESSAGE)) and (SUI.DBMod.FilmEffects.Effects[v].afk) then
				Container[v]:Show()
			elseif (... == CLEARED_AFK) then
				Container[v]:Hide()
			end
		else
			if SUI.DBMod.FilmEffects.Effects[v].always then
				Container[v]:Show()
			else
				Container[v]:Hide()
			end
		end
	end
end

local function updateopts()
	local disabled = true
	if SUI.DBMod.FilmEffects.enable then disabled = false end
	for k,v in ipairs(EffectList) do
		SUI.opt.args["ModSetting"].args["FilmEffects"].args[v .. "always"].disabled = disabled
		SUI.opt.args["ModSetting"].args["FilmEffects"].args[v .. "AFK"].disabled = disabled
	end
end

function addon:OnInitialize()
	if SUI.DBMod.FilmEffects.Effects == nil then
		SUI.DBMod.FilmEffects = 
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
	
	SUI.opt.args["ModSetting"].args["FilmEffects"] = {
		name = L["Film Effects"],
		type = "group",
		args = {
			enable = {
			name=L["Enable Film Effects"],
			type="toggle",
			order=1,
			width="full",
			get = function(info) updateopts(); return SUI.DBMod.FilmEffects.enable end,
			set = function(info,val)
				if InCombatLockdown() then SUI:Print(L["Please leave combat first."]) return end
				SUI.DBMod.FilmEffects.enable = val; FilmEffectEvent(nil,nil,nil); updateopts();
				end
			}
		}
	}
	
	
	for k,v in ipairs(EffectList) do
		SUI.opt.args["ModSetting"].args["FilmEffects"].args[v .. "Title"] = {name=v,type="header",order=k+1,width="full"}
		SUI.opt.args["ModSetting"].args["FilmEffects"].args[v .. "always"] = {name=L["Always show"],type="toggle",order=k + 1.2,
			get = function(info) return SUI.DBMod.FilmEffects.Effects[v].always end,
			set = function(info,val) if InCombatLockdown() then SUI:Print(L["Please leave combat first."]) return end SUI.DBMod.FilmEffects.Effects[v].always = val; FilmEffectEvent(nil,nil,nil) end
		}
		SUI.opt.args["ModSetting"].args["FilmEffects"].args[v .. "AFK"] = {name=L["Show if AFK"],type="toggle",order=k + 1.4,
			get = function(info) if InCombatLockdown() then SUI:Print(L["Please leave combat first."]) return end return SUI.DBMod.FilmEffects.Effects[v].afk end,
			set = function(info,val) SUI.DBMod.FilmEffects.Effects[v].afk = val; end
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

function addon:Update(self, elapsed)
	SUI.DBMod.FilmEffects.animationInterval = SUI.DBMod.FilmEffects.animationInterval + elapsed
	if (SUI.DBMod.FilmEffects.animationInterval > (0.02)) then -- 50 FPS
		SUI.DBMod.FilmEffects.animationInterval = 0
		
		local yOfs = math.random(0, 256)
		local xOfs = math.random(-128, 0)
		
		if SUI.DBMod.FilmEffects.anim=="blur" or SUI.DBMod.FilmEffects.anim=="crisp" then
			Container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", xOfs, yOfs)
		end
	end
end

