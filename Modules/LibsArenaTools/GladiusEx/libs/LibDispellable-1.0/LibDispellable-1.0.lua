--[[
LibDispellable-1.0 - Test whether the player can really dispell a buff or debuff, given its talents.
Copyright (C) 2009-2013 Adirelle (adirelle@gmail.com)

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.
    * Redistribution of a stand alone version is strictly prohibited without
      prior written authorization from the LibDispellable project manager.
    * Neither the name of the LibDispellable authors nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local MAJOR, MINOR = "LibDispellable-1.0", 30
assert(LibStub, MAJOR.." requires LibStub")
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- ----------------------------------------------------------------------------
-- Event dispatcher
-- ----------------------------------------------------------------------------

if not lib.eventFrame then
	lib.eventFrame = CreateFrame("Frame")
	lib.eventFrame:SetScript('OnEvent', function() return lib:UpdateSpells() end)
	lib.eventFrame:RegisterEvent('SPELLS_CHANGED')
end

-- ----------------------------------------------------------------------------
-- Data
-- ----------------------------------------------------------------------------

lib.buff = lib.buff or {}
lib.debuff = lib.debuff or {}
lib.specialIDs = wipe(lib.specialIDs or {})
lib.spells = lib.spells or {}

-- Spells that do not have a dispel type according to Blizzard API
-- but that can be dispelled anyway.
lib.specialIDs[144351] = "Magic" -- Mark of Arrogance (Sha of Pride encounter)

-- ----------------------------------------------------------------------------
-- Detect available dispel skills
-- ----------------------------------------------------------------------------

local function CheckSpell(spellID, pet)
	return IsSpellKnown(spellID, pet) and spellID or nil
end

function lib:UpdateSpells()
	wipe(self.buff)
	wipe(self.debuff)

	local _, class = UnitClass("player")

	if class == "DEMONHUNTER" then
		self.debuff.Magic = CheckSpell(205604) -- Reverse Magic (PvP)

	elseif class == "DRUID" then
		local cure = CheckSpell(88423) -- Nature's Cure
		local corruption = cure or CheckSpell(2782) -- Remove Corruption
		self.debuff.Magic = cure
		self.debuff.Curse = corruption
		self.debuff.Poison = corruption

	elseif class == "HUNTER" then
		local mendingBandage = CheckSpell(212640) -- Mending Bandage (PvP)
		self.debuff.Disease = mendingBandage
		self.debuff.Poison = mendingBandage

	elseif class == "MAGE" then
		self.buff.Magic = CheckSpell(30449) -- Spellsteal

	elseif class == "MONK" then
		local mwDetox = CheckSpell(115450) -- Detox (Mistweaver)
		local detox = mwDetox or CheckSpell(218164) -- Detox (Brewmaster or Windwalker)
		self.debuff.Magic = mwDetox
		self.debuff.Disease = detox
		self.debuff.Poison = detox

	elseif class == "PALADIN" then
		local cleanse = CheckSpell(4987) -- Cleanse
		local toxins = cleanse or CheckSpell(213644) -- Cleanse Toxins
		self.debuff.Magic = cleanse
		self.debuff.Poison = toxins
		self.debuff.Disease = toxins

	elseif class == "PRIEST" then
		local purify = CheckSpell(527) -- Purify
		local disease = purify or CheckSpell(213634) -- Purify Disease
		self.debuff.Magic = purify
		self.debuff.Disease = disease
		self.buff.Magic = CheckSpell(528) -- Dispel Magic

	elseif class == "SHAMAN" then
		local purify = CheckSpell(77130) -- Purify Spirit
		local cleanse = purify or CheckSpell(51886) -- Cleanse Spirit
		self.debuff.Magic = purify
		self.debuff.Curse = cleanse
		self.buff.Magic = CheckSpell(370) -- Purge

	elseif class == "WARLOCK" then
		self.buff.Magic = CheckSpell(171021, true) -- Torch Magic (Infernal)
		self.debuff.Magic = CheckSpell(89808, true) or CheckSpell(212623) -- Singe Magic (Imp) / (PvP)
	end

	wipe(self.spells)
	if self.buff.Magic then
		self.spells[self.buff.Magic] = 'offensive'
	end
	for dispelType, id in pairs(self.debuff) do
		self.spells[id] = 'defensive'
	end

end

--- Get the actual dispel mechanism of an aura, including special cases.
-- @name LibDispellable:GetDispelType
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @return dispelType (string) The actual dispel mechanism
function lib:GetDispelType(dispelType, spellID)
	if spellID and lib.specialIDs[spellID] then
		return lib.specialIDs[spellID]
	elseif dispelType and dispelType ~= "none" and dispelType ~= "" then
		return dispelType
	end
end

--- Check if an aura can be dispelled by anyone.
-- @name LibDispellable:IsDispellable
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @return boolean True if the aura can be dispelled in some way
function lib:IsDispellable(dispelType, spellID)
	return self:GetDispelType(dispelType, spellID) ~= nil
end

--- Check which player spell can be used to dispel an aura.
-- @name LibDispellable:GetDispelSpell
-- @param dispelType (string) The dispel mechanism as returned by UnitAura
-- @param spellID (number) The spell ID
-- @param isBuff (boolean) True if the spell is a buff, false if it is a debuff.
-- @return number The spell ID of the dispel, or nil if the player cannot dispel it.
function lib:GetDispelSpell(dispelType, spellID, isBuff)
	local actualDispelType = self:GetDispelType(dispelType, spellID)
	return actualDispelType and self[isBuff and "buff" or "debuff"][actualDispelType]
end

--- Test if the player can dispel the given aura on the given unit.
-- @name LibDispellable:CanDispel
-- @param unit (string) The unit id.
-- @param isBuff (boolean) True if the spell is a buff.
-- @param dispelType (string) The dispel mechanism, as returned by UnitAura.
-- @param spellID (number) The aura spell ID, as returned by UnitAura, used to test enrage effects.
-- @return boolean true if the player knows a spell to dispel the aura.
-- @return number The spell ID of the spell to dispel, or nil.
function lib:CanDispel(unit, isBuff, dispelType, spellID)
	if (isBuff and not UnitCanAttack("player", unit)) or (not isBuff and not UnitCanAssist("player", unit))then
		return false
	end
	local spell = lib:GetDispelSpell(dispelType, spellID, isBuff)
	return not not spell, spell or nil
end

-- ----------------------------------------------------------------------------
-- Iterators
-- ----------------------------------------------------------------------------

local function noop() end

local function buffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura = UnitBuff(unit, index)
		local spell = lib:GetDispelSpell(dispelType, spellID, true)
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura
		end
	until not name
end

local function allBuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura = UnitBuff(unit, index)
		if lib:IsDispellable(dispelType, spellID) then
			return index, lib:GetDispelSpell(dispelType, spellID, true), name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura
		end
	until not name
end

local function debuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitDebuff(unit, index)
		local spell = lib:GetDispelSpell(dispelType, spellID, false)
		if spell then
			return index, spell, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
		end
	until not name
end

local function allDebuffIterator(unit, index)
	repeat
		index = index + 1
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitDebuff(unit, index)
		if lib:IsDispellable(dispelType, spellID) then
			return index, lib:GetDispelSpell(dispelType, spellID, false), name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
		end
	until not name
end

--- Iterate through unit (de)buffs that can be dispelled by the player.
-- @name LibDispellable:IterateDispellableAuras
-- @param unit (string) The unit to scan.
-- @param buffs (boolean) true to test buffs instead of debuffs (offensive dispel).
-- @param allDispellable (boolean) Include auras that can be dispelled even if the player cannot.
-- @return A triplet usable in the "in" part of a for ... in ... do loop.
-- @usage
--   for index, spellID, name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff in LibDispellable:IterateDispellableAuras("target", true) do
--     print("Can dispel", name, "on target using", GetSpellInfo(spellID))
--   end
function lib:IterateDispellableAuras(unit, buffs, allDispellable)
	if buffs and UnitCanAttack("player", unit) and (allDispellable or next(self.buff)) then
		return (allDispellable and allBuffIterator or buffIterator), unit, 0
	elseif not buffs and UnitCanAssist("player", unit) and (allDispellable or next(self.debuff)) then
		return (allDispellable and allDebuffIterator or debuffIterator), unit, 0
	else
		return noop
	end
end

--- Test if the given spell can be used to dispel something on the given unit.
-- @name LibDispellable:CanDispelWith
-- @param unit (string) The unit to check.
-- @param spellID (number) The spell to use.
-- @return true if the
-- @usage
--   if LibDispellable:CanDispelWith('focus', 4987) then
--     -- Tell the user that Cleanse (id 4987) could be used to dispel something from the focus
--   end
function lib:CanDispelWith(unit, spellID)
	for index, spell in self:IterateDispellableAuras(unit, UnitCanAttack("player", unit)) do
		if spell == spellID then
			return true
		end
	end
	return false
end

--- Test if player can dispel anything.
-- @name LibDispellable:HasDispel
-- @return boolean true if the player has any spell that can be used to dispel something.
function lib:HasDispel()
	return next(self.spells)
end

--- Get an iterator of the dispel spells.
-- @name LibDispellable:IterateDispelSpells
-- @return a (iterator, data, index) triplet usable in for .. in loops.
--  Each iteration returns a spell id and the general dispel type: "offensive" or "debuff"
function lib:IterateDispelSpells()
	return next, self.spells, nil
end

-- Initialization
if IsLoggedIn() then
	lib:UpdateSpells()
end
