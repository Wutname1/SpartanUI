--[[--------------------------------------------------------------------
	oUF_Phanx
	Fully-featured PVE-oriented layout for oUF.
	Copyright (c) 2008-2014 Phanx. All rights reserved.
	See the accompanying README and LICENSE files for more information.
	http://www.wowinterface.com/downloads/info13993-oUF_Phanx.html
	http://www.curse.com/addons/wow/ouf-phanx
------------------------------------------------------------------------
	Element to highlight oUF frames by dispellable debuff type.
	Originally based on oUF_DebuffHighlight by Ammo.
	Some code adapted from LibDispellable-1.0 by Adirelle.

	You may embed this module in your own layout, but please do not
	distribute it as a standalone plugin.

	Usage:
	frame.DispelHighlight = frame.Health:CreateTexture(nil, "OVERLAY")
	frame.DispelHighlight:SetAllPoints(frame.Health:GetStatusBarTexture())

	Options:
	frame.DispelHighlight.filter = true
	frame.DispelHighlight.PreUpdate = function(element) end
	frame.DispelHighlight.PostUpdate = function(element, debuffType, canDispel)
	frame.DispelHighlight.Override = function(element, debuffType, canDispel)
----------------------------------------------------------------------]]

if select(4, GetAddOnInfo("oUF_DebuffHighlight")) then return end

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "DispelHighlight element requires oUF")

local _, playerClass = UnitClass("player")

local colors = { -- these are nicer than DebuffTypeColor
	["Curse"] = { 0.8, 0, 1 },
	["Disease"] = { 0.8, 0.6, 0 },
	["Enrage"] = { 1.0, 0.2, 0.6 },
	["Invulnerability"] = { 1, 1, 0.4 },
	["Magic"] = { 0, 0.8, 1 },
	["Poison"] = { 0, 0.8, 0 },
}
oUF.colors.debuff = colors

local INVULNERABILITY_EFFECTS = {
	-- Player abilities
	[642]   = true, -- Divine Shield
	[1022]  = true, -- Hand of Protection
	[45438] = true, -- Ice Block
	-- NPC abilities
	[38916] = true, -- Diplomatic Immunity
}

local DefaultDispelPriority = { Curse = 2, Disease = 4, Magic = 1, Poison = 3 }
local ClassDispelPriority = { Curse = 3, Disease = 1, Magic = 4, Poison = 2 }

local canDispel, canPurge, canShatter, canSteal, canTranq, noDispels = {}
local debuffTypeCache = {}

local Update, ForceUpdate, Enable, Disable

function Update(self, event, unit)
	if unit ~= self.unit then return end
	local element = self.DispelHighlight
	-- print("DispelHighlight Update", event, unit)

	local debuffType, dispellable

	if not noDispels and UnitCanAssist("player", unit) then
		for i = 1, 40 do
			local name, _, _, _, type = UnitDebuff(unit, i)
			if not name then break end
			-- print("UnitDebuff", unit, i, tostring(name), tostring(type))
			if type and (not debuffType or ClassDispelPriority[type] > ClassDispelPriority[debuffType]) then
				-- print("debuffType", type)
				debuffType = type
				dispellable = canDispel[type]
			end
		end
	elseif (canSteal or canPurge or canTranq) and UnitCanAttack("player", unit) then
		for i = 1, 40 do
			local name, _, _, _, type, _, _, _, stealable, _, id = UnitBuff(unit, i)
			if not name then break end

			if canShatter and INVULNERABILITY_EFFECTS[id] then
				type = "Invulnerability"
			elseif type == "" then
				type = "Enrage"
			end

			if (canSteal and stealable) or (canPurge and type == "Magic") or (canTranq and type == "Enrage") or (type == "Invulnerability") then
				-- print("debuffType", type)
				debuffType = type
				dispellable = true
				break
			end
		end
	end

	if debuffTypeCache[unit] == debuffType then return end

	-- print("UpdateDispelHighlight", unit, tostring(debuffTypeCache[unit]), "==>", tostring(debuffType))
	debuffTypeCache[unit] = debuffType

	if element.Override then
		element:Override(debuffType, dispellable)
		return
	end

	if element.PreUpdate then
		element:PreUpdate()
	end

	if debuffType and (dispellable or not element.filter) then
		element:SetVertexColor(unpack(colors[debuffType]))
		element:Show()
	else
		element:Hide()
	end

	if element.PostUpdate then
		element:PostUpdate(debuffType, dispellable)
	end
end

function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self)
	local element = self.DispelHighlight
	if not element then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	self:RegisterEvent("UNIT_AURA", Update)

	if element.GetTexture and not element:GetTexture() then
		element:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	end

	return true
end

local function Disable(self)
	local element = self.DispelHighlight
	if not element then return end

	self:UnregisterEvent("UNIT_AURA", Update)

	element:Hide()
end

oUF:AddElement("DispelHighlight", Update, Enable, Disable)

------------------------------------------------------------------------

local function SortByPriority(a, b)
	return ClassDispelPriority[a] > ClassDispelPriority[b]
end

local f = CreateFrame("Frame")
f:RegisterEvent("SPELLS_CHANGED")
f:SetScript("OnEvent", function(self, event)
	wipe(canDispel)

	-- print("DispelHighlight", event, "Checking capabilities...")

	if playerClass == "DEATHKNIGHT" then
		for i = 1, GetNumGlyphSockets() do
			local enabled, _, _, id = GetGlyphSocketInfo(i)
			if id == 58631 then
				canPurge = true -- Glyph of Icy Touch
				break
			end
		end

	elseif playerClass == "DRUID" then
		canDispel.Curse   = IsPlayerSpell(88423) or IsPlayerSpell(2782) -- Remove Corruption
		canDispel.Magic   = IsPlayerSpell(88423) -- Nature's Cure
		canDispel.Poison  = canDispel.Curse
		canTranq = IsPlayerSpell(2908) -- Soothe

	elseif playerClass == "HUNTER" then
		canPurge          = IsPlayerSpell(19801) -- Tranquilizing Shot
		canTranq          = canPurge

	elseif playerClass == "MAGE" then
		canDispel.Curse   = IsPlayerSpell(475) -- Remove Curse
		canSteal          = IsPlayerSpell(30449) -- Spellsteal

	elseif playerClass == "MONK" then
		canDispel.Disease = IsPlayerSpell(115450) -- Detox
		canDispel.Magic   = IsPlayerSpell(115451) -- Internal Medicine
		canDispel.Poison  = canDispel.Disease

	elseif playerClass == "PALADIN" then
		canDispel.Disease = IsPlayerSpell(4987) -- Cleanse
		canDispel.Magic   = IsPlayerSpell(53551) -- Sacred Cleansing
		canDispel.Poison  = canDispel.Disease

	elseif playerClass == "PRIEST" then
		canDispel.Disease = IsPlayerSpell(527) -- Purify
		canDispel.Magic   = IsPlayerSpell(527) or IsPlayerSpell(32375) -- Mass Dispel
		canPurge          = IsPlayerSpell(528) -- Dispel Magic

	elseif playerClass == "ROGUE" then
		canTranq          = IsPlayerSpell(5938) -- Shiv

	elseif playerClass == "SHAMAN" then
		canDispel.Curse   = IsPlayerSpell(51886) -- Cleanse Spirit (upgrades to Purify Spirit)
		canDispel.Magic   = IsPlayerSpell(77130) -- Purify Spirit
		canPurge          = IsPlayerSpell(370) -- Purge

	elseif playerClass == "WARLOCK" then
		canDispel.Magic   = IsPlayerSpell(115276, true) or IsPlayerSpell(89808, true) -- Sear Magic (Fel Imp) or Singe Magic (Imp)
		canPurge          = IsPlayerSpell(19505, true) -- Devour Magic (Felhunter)

	elseif playerClass == "WARRIOR" then
		canPurge          = IsPlayerSpell(23922) -- Shield Slam
		canShatter        = IsPlayerSpell(64382) -- Shattering Throw
	end

	wipe(ClassDispelPriority)
	for type, priority in pairs(DefaultDispelPriority) do
		ClassDispelPriority[1 + #ClassDispelPriority] = type
		ClassDispelPriority[type] = (canDispel[type] and 10 or 5) - priority
	end
	table.sort(ClassDispelPriority, SortByPriority)

	noDispels = not next(canDispel)
--[[
	for i, v in ipairs(ClassDispelPriority) do
		print("Can dispel " .. v .. "?", canDispel[v] and "YES" or "NO")
	end
	print("Can purge?", canPurge and "YES" or "NO")
	print("Can shatter?", canShatter and "YES" or "NO")
	print("Can steal?", canSteal and "YES" or "NO")
	print("Can tranquilize?", canTranq and "YES" or "NO")
]]
	for i = 1, #oUF.objects do
		local object = oUF.objects[i]
		if object.DispelHighlight and object:IsShown() then
			Update(object, event, object.unit)
		end
	end
end)