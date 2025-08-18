local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")
local fn = LibStub("LibFunctional-1.0")
local LD = LibStub("LibDispellable-1.0")
local MSQ = LibStub("Masque", true)
local MSQ_Buffs
local MSQ_Debuffs
if MSQ then
	MSQ_Buffs = MSQ:Group("GladiusEx", L["Buffs"])
	MSQ_Debuffs = MSQ:Group("GladiusEx", L["Debuffs"])
end

-- global functions
local strfind = string.find
local pairs, select = pairs, select
local tinsert, tsort, tremove = table.insert, table.sort, table.remove
local band = bit.band
local ceil, floor, max, min = math.ceil, math.floor, math.max, math.min

local FILTER_TYPE_DISABLED = 0
local FILTER_TYPE_WHITELIST = 1
local FILTER_TYPE_BLACKLIST = 2

local FILTER_WHAT_BUFFS = 2
local FILTER_WHAT_DEBUFFS = 4
local FILTER_WHAT_BOTH = 6

local GetDefaultAuras = GladiusEx.Data.DefaultAuras

local defaults = {
	aurasBuffs = true,
	aurasBuffsOnlyDispellable = false,
	aurasBuffsOnlyMine = false,
	aurasBuffsSpacingX = 0,
	aurasBuffsSpacingY = 0,
	aurasBuffsPerRow = 9,
	aurasBuffsMaxRows = 2,
	aurasBuffsSize = 12,
	aurasBuffsEnlargeMine = true,
	aurasBuffsEnlargeScale = 2,
	aurasBuffsOffsetX = 0,
	aurasBuffsOffsetY = 0,
	aurasBuffsTooltips = true,
	aurasBuffsShowSwipe = true,
	aurasBuffsSwipeReversed = false,
	aurasBuffsSwipeColor = { r = 0, g = 0, b = 0, a = 0.8 },

	aurasDebuffs = true,
	aurasDebuffsOnlyDispellable = false,
	aurasDebuffsOnlyMine = false,
	aurasDebuffsSpacingX = 0,
	aurasDebuffsSpacingY = 0,
	aurasDebuffsPerRow = 9,
	aurasDebuffsMaxRows = 2,
	aurasDebuffsSize = 12,
	aurasDebuffsEnlargeMine = true,
	aurasDebuffsEnlargeScale = 2,
	aurasDebuffsOffsetX = 0,
	aurasDebuffsOffsetY = 0,
	aurasDebuffsTooltips = true,
	aurasDebuffsShowSwipe = true,
	aurasDebuffsSwipeReversed = false,
	aurasDebuffsSwipeColor = { r = 0, g = 0, b = 0, a = 0.8 },

	aurasFilterType = FILTER_TYPE_BLACKLIST,
	aurasFilterWhat = FILTER_WHAT_BOTH,
	aurasFilterAuras = GetDefaultAuras(),

	aurasPrioFirst = true,
	aurasPrioList = {},
}

local Auras = GladiusEx:NewGladiusExModule("Auras",
	fn.merge(defaults, {
		aurasBuffsAttachTo = "Frame",
		aurasBuffsAnchor = "BOTTOMLEFT",
		aurasBuffsRelativePoint = "TOPLEFT",
		aurasBuffsGrow = "UPRIGHT",

		aurasDebuffsAttachTo = "Frame",
		aurasDebuffsAnchor = "BOTTOMRIGHT",
		aurasDebuffsRelativePoint = "TOPRIGHT",
		aurasDebuffsGrow = "UPLEFT",
	}),
	fn.merge(defaults, {
		aurasBuffsAttachTo = "Frame",
		aurasBuffsAnchor = "BOTTOMRIGHT",
		aurasBuffsRelativePoint = "TOPRIGHT",
		aurasBuffsGrow = "UPLEFT",

		aurasDebuffsAttachTo = "Frame",
		aurasDebuffsAnchor = "BOTTOMLEFT",
		aurasDebuffsRelativePoint = "TOPLEFT",
		aurasDebuffsGrow = "UPRIGHT",
	}))

function Auras:OnEnable()
	self:RegisterEvent("UNIT_AURA", "UpdateUnitAuras")

	self.buffFrame = self.buffFrame or {}
	self.debuffFrame = self.debuffFrame or {}
end

function Auras:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.debuffFrame) do
		self.debuffFrame[unit]:Hide()
	end

	for unit in pairs(self.buffFrame) do
		self.buffFrame[unit]:Hide()
	end
end

function Auras:GetFrames(unit)
	local frames = {}
	if self.db[unit].aurasBuffs then tinsert(frames, self.buffFrame[unit]) end
	if self.db[unit].aurasDebuffs then tinsert(frames, self.debuffFrame[unit]) end
	return frames
end

function Auras:GetModuleAttachPoints(unit)
	return {
		["Buffs"] = L["Buffs"],
		["Debuffs"] = L["Debuffs"],
	}
end

function Auras:GetModuleAttachFrame(unit, point)
	if point == "Buffs" then
		if not self.buffFrame[unit] then
			self:CreateFrame(unit)
		end
		return self.buffFrame[unit]
	else
		if not self.debuffFrame[unit] then
			self:CreateFrame(unit)
		end
		return self.debuffFrame[unit]
	end
end

function Auras:IsAuraFiltered(unit, name, what)
	if self.db[unit].aurasFilterType == FILTER_TYPE_DISABLED then
		return true
	elseif band(self.db[unit].aurasFilterWhat, what) ~= what then
		return true
	elseif self.db[unit].aurasFilterType == FILTER_TYPE_WHITELIST then
		return self.db[unit].aurasFilterAuras[name]
	elseif self.db[unit].aurasFilterType == FILTER_TYPE_BLACKLIST then
		return not self.db[unit].aurasFilterAuras[name]
	end
end

local player_units = {
	["player"] = true,
	["vehicle"] = true,
	["pet"] = true
}

local function GetTestAura(index, buff)
  local spellID = buff and 21562 or 589
  local name, icon = nil
  if C_Spell and C_Spell.GetSpellTexture then
	name = C_Spell.GetSpellName(spellID)
	icon = C_Spell.GetSpellTexture(spellID)
  else
	local name, _, icon = GetSpellInfo(spellID)
  end
	local count, dispelType, duration, caster, isStealable, shouldConsolidate = 1, "Magic", 3600 * index, "player", false, false
	local expires = GetTime() + duration
	return name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
end

-- V: Temporary hack.
--    LibDispellable-1.0 relies on IsSpellKnown() to detect dispels,
--    but because of a Blizzard API bug, IsSpellKnown(115450) returns false on MW monks.
--    Instead, use IsPlayerSpell (could also use IsSpellKnownOrOverridesKnown).
local function CanDispel(unit, buffs, dispelType, spellID)
	if (buffs and not UnitCanAttack("player", unit)) or (not buffs and not UnitCanAssist("player", unit)) then
		return false
	end
	-- TODO update LibDispellable
	-- TODO handle the *other* evoker dispels
	local hasMonkDispel = IsPlayerSpell(115450)
	local hasEvokerDispel = IsPlayerSpell(360823)
	local hasShamanDispel = IsPlayerSpell(378773)
	local hasDispel = hasMonkDispel or hasEvokerDispel or hasShamanDispel
	if buffs and hasDispel and dispelType == "Magic" then
		return true
	end
	return LD:CanDispel(unit, buffs, dispelType, spellID)
end

function Auras:UpdateUnitAuras(event, unit)
	if not self.buffFrame[unit] and not self.debuffFrame[unit] then return end

	-- local st = debugprofilestop()
	local ntests = 0
	local testing = GladiusEx:IsTesting(unit)
	local aurasBuffsOnlyMine
	local aurasBuffsOnlyDispellable
	local icon_index
	local auraFrame
	local aurasBuffsMax
	local aurasBuffsPerRow
	local aurasBuffsMaxRows
	local aurasBuffsGrow
	local aurasBuffsSize
	local aurasBuffsSpacingX
	local aurasBuffsSpacingY
	local aurasBuffsEnlargeMine
	local aurasBuffsEnlargeScale
	local showSwipe
	local swipeReversed
	local swipeColor

	local function set_aura(index, buff)
		local aura_frame = auraFrame[icon_index]
		local name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
		if testing then
			name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = GetTestAura(index, buff)
		elseif buff then
			name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = GladiusEx.UnitBuff(unit, index)
		else
			name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = GladiusEx.UnitDebuff(unit, index)
		end

		aura_frame.unit = unit
		aura_frame.aura_index = index
		aura_frame.aura_buff = buff

		-- icon
		aura_frame.icon:SetTexture(icon)

    -- stealable
    if isStealable then
      aura_frame.stealable:Show()
    else
      aura_frame.stealable:Hide()
    end

		-- cooldown
		if duration > 0 then
			CooldownFrame_Set(aura_frame.cooldown, expires - duration, duration, 1)
			aura_frame.cooldown:Show()
		else
			CooldownFrame_Set(aura_frame.cooldown, 0, 0, 0)
			aura_frame.cooldown:Hide()
		end

		-- cooldown swipe
		aura_frame.cooldown:SetSwipeTexture("")
		aura_frame.cooldown:SetDrawSwipe(showSwipe)
		aura_frame.cooldown:SetReverse(swipeReversed)
		aura_frame.cooldown:SetSwipeColor(swipeColor.r, swipeColor.g, swipeColor.b, swipeColor.a)

		-- stacks
		aura_frame.count:SetText(count > 1 and count or nil)

		-- border
		local color = DebuffTypeColor[dispelType] or (not buff and DebuffTypeColor["none"])
		if color then
			aura_frame.border:SetVertexColor(color.r, color.g, color.b)
			aura_frame.border:Show()
		else
			aura_frame.border:Hide()
		end

		-- show
		aura_frame:Show()
		icon_index = icon_index + 1
		return icon_index > aurasBuffsMax
	end

	local function scan(buffs)
		local filter = buffs and "HELPFUL" or "HARMFUL"
		local filter_what = buffs and FILTER_WHAT_BUFFS or FILTER_WHAT_DEBUFFS

		local enlarged = {}
		local normal = {}
		local i = 1
		while not testing or i < 40 do
			local name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
			if testing then
				name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = GetTestAura(i, buffs)
			else
				name, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = GladiusEx.UnitAura(unit, i, filter)
			end

			if not name then break end

			if self:IsAuraFiltered(unit, name, filter_what) and
				(not aurasBuffsOnlyMine or player_units[caster]) and
				(not aurasBuffsOnlyDispellable or CanDispel(unit, buffs, dispelType, spellID)) then

				if aurasBuffsEnlargeMine and ((testing and i <= 2) or (not testing and player_units[caster])) then
					tinsert(enlarged, i)
				else
					tinsert(normal, i)
				end
			end
			i = i + 1
		end

		-- sort auras
		if not testing then
			local prioFirst = self.db[unit].aurasPrioFirst
			local ordering = {}
			for i, aura in pairs(self.db[unit].aurasPrioList) do
				ordering[aura] = i
			end
			local function aura_compare(a, b)
				local namea, _, _, _, _, dura = GladiusEx.UnitAura(unit, a, filter)
				local nameb, _, _, _, _, durb = GladiusEx.UnitAura(unit, b, filter)
				local ordera = ordering[namea]
				local orderb = ordering[nameb]
				if ordera and not orderb then
					return not prioFirst
				end
				if orderb and not ordera then
					return prioFirst
				end
				if ordera and orderb then
					if prioFirst then
						return ordera > orderb
					else
						return ordera < orderb
					end
				end

				if dura == 0 then return false end
				if durb == 0 then return true end
				return dura < durb
			end
			tsort(enlarged, aura_compare)
			tsort(normal, aura_compare)
		end

		local area_width = 36 * aurasBuffsPerRow + aurasBuffsSpacingX * (aurasBuffsPerRow - 1)
		local area_height = 36 * ceil(aurasBuffsMax / aurasBuffsPerRow) + (aurasBuffsSpacingY * (ceil(aurasBuffsMax / aurasBuffsPerRow) - 1))
		local spacing_x = aurasBuffsSpacingX
		local spacing_y = aurasBuffsSpacingY
		local squares = {}

		local function collision(x, y, size)
			ntests = ntests + 1
			local x2, y2 = x + size, y + size
			if x2 > area_width or y2 > area_height then
				return true
			end
			for i = 1, #squares do
				local sq = squares[i]
				local c = (y2 > sq.y) and (y < sq.y2) and (x < sq.x2) and (x2 > sq.x)
				if c then
					return true
				end
			end
			return false
		end

		local function place_square(size)
			local x = 0
			local y = 0
			local sq_info

			local function add()
				sq_info = {
					x = x,
					y = y,
					x2 = x + size,
					y2 = y + size,
				}
				tinsert(squares, sq_info)
			end

			local best_x, best_y
			local function try_position()
				if not best_x or best_y > y then
					if not collision(x, y, size) then
						best_x = x
						best_y = y
					end
				end
			end

			if #squares == 0 then
				-- place first one at 0, 0
				try_position()
			else
				-- try +x of all squares
				for i = 1, #squares do
					local sq = squares[i]
					x = sq.x2 + spacing_x
					y = sq.y
					try_position()
				end
				-- try +y of all squares
				for i = 1, #squares do
					local sq = squares[i]
					x = sq.x
					y = sq.y2 + spacing_y
					try_position()
				end
			end
			if best_x then
				x = best_x
				y = best_y
				add()
				return sq_info
			end
			return nil
		end

		local normal_size = 36
		local enlarged_size = normal_size * aurasBuffsEnlargeScale

		local grow_rel, x_sign, y_sign
		if aurasBuffsGrow == "DOWNRIGHT" then
			grow_rel, x_sign, y_sign = "TOPLEFT", 1, -1
		elseif aurasBuffsGrow == "DOWNLEFT" then
			grow_rel, x_sign, y_sign = "TOPRIGHT", -1, -1
		elseif aurasBuffsGrow == "UPRIGHT" then
			grow_rel, x_sign, y_sign = "BOTTOMLEFT", 1, 1
		elseif aurasBuffsGrow == "UPLEFT" then
			grow_rel, x_sign, y_sign = "BOTTOMRIGHT", -1, 1
		end

		-- place enlarged auras
		for i = 1, #enlarged do
			local aura_index = enlarged[i]
			local aura_frame = auraFrame[icon_index]
			local this_scale

			local sq_info = place_square(enlarged_size)
			if sq_info then
				this_scale = aurasBuffsEnlargeScale
			else
				-- not enough space for an enlarged icon, try with normal size
				sq_info = place_square(normal_size)
				if not sq_info then return end
				this_scale = 1
			end

			aura_frame:SetScale(this_scale)
			aura_frame:SetPoint(grow_rel, auraFrame, grow_rel, sq_info.x / this_scale * x_sign, sq_info.y / this_scale * y_sign)

			if set_aura(aura_index, buffs) then return end
		end

		-- place normal auras
		for i = 1, #normal do
			local aura_index = normal[i]
			local aura_frame = auraFrame[icon_index]
			local sq_info = place_square(normal_size)
			if not sq_info then return end

			aura_frame:SetScale(1)
			aura_frame:SetPoint(grow_rel, auraFrame, grow_rel, sq_info.x * x_sign, sq_info.y * y_sign)

			if set_aura(aura_index, buffs) then return end
		end
	end

	local function hide_unused()
		-- hide unused aura frames
		for i = icon_index, 40 do
			if not auraFrame[i]:IsShown() then break end
			auraFrame[i]:Hide()
		end
	end

	-- buffs
	if self.db[unit].aurasBuffs then
		icon_index = 1
		auraFrame = self.buffFrame[unit]
		aurasBuffsMax = min(40, self.db[unit].aurasBuffsPerRow * self.db[unit].aurasBuffsMaxRows)
		aurasBuffsPerRow = self.db[unit].aurasBuffsPerRow
		aurasBuffsMaxRows = self.db[unit].aurasBuffsMaxRows
		aurasBuffsGrow = self.db[unit].aurasBuffsGrow
		aurasBuffsSize = self.db[unit].aurasBuffsSize
		aurasBuffsSpacingX = self.db[unit].aurasBuffsSpacingX
		aurasBuffsSpacingY = self.db[unit].aurasBuffsSpacingY
		aurasBuffsEnlargeMine = self.db[unit].aurasBuffsEnlargeMine
		aurasBuffsEnlargeScale = self.db[unit].aurasBuffsEnlargeScale
		aurasBuffsOnlyMine = GladiusEx:IsPartyUnit(unit) and self.db[unit].aurasBuffsOnlyMine
		aurasBuffsOnlyDispellable = GladiusEx:IsArenaUnit(unit) and self.db[unit].aurasBuffsOnlyDispellable
		showSwipe = self.db[unit].aurasBuffsShowSwipe
		swipeReversed = self.db[unit].aurasBuffsSwipeReversed
		swipeColor = self.db[unit].aurasBuffsSwipeColor

		scan(true)
		hide_unused()
	end

	-- debuffs
	if self.db[unit].aurasDebuffs then
		icon_index = 1
		auraFrame = self.debuffFrame[unit]
		aurasBuffsMax = min(40, self.db[unit].aurasDebuffsPerRow * self.db[unit].aurasDebuffsMaxRows)
		aurasBuffsPerRow = self.db[unit].aurasDebuffsPerRow
		aurasBuffsMaxRows = self.db[unit].aurasDebuffsMaxRows
		aurasBuffsGrow = self.db[unit].aurasDebuffsGrow
		aurasBuffsSize = self.db[unit].aurasDebuffsSize
		aurasBuffsSpacingX = self.db[unit].aurasDebuffsSpacingX
		aurasBuffsSpacingY = self.db[unit].aurasDebuffsSpacingY
		aurasBuffsEnlargeMine = self.db[unit].aurasDebuffsEnlargeMine
		aurasBuffsEnlargeScale = self.db[unit].aurasDebuffsEnlargeScale
		aurasBuffsOnlyMine = GladiusEx:IsArenaUnit(unit) and self.db[unit].aurasDebuffsOnlyMine
		aurasBuffsOnlyDispellable = GladiusEx:IsPartyUnit(unit) and self.db[unit].aurasDebuffsOnlyDispellable
		showSwipe = self.db[unit].aurasDebuffsShowSwipe
		swipeReversed = self.db[unit].aurasDebuffsSwipeReversed
		swipeColor = self.db[unit].aurasDebuffsSwipeColor

		scan(false)
		hide_unused()
	end

	-- local tt = debugprofilestop() - st
	-- if tt >= 1 then
	-- 	print(unit, ": tests done: ", ntests, "time:", tt)
	-- end
end

local function CreateAuraFrame(name, parent)
	local frame = CreateFrame("Button", name, parent, "GladiusExAuraFrame")
	frame.icon = _G[name .. "Icon"]
	frame.border = _G[name .. "Border"]
	frame.cooldown = _G[name .. "Cooldown"]
	frame.count = _G[name .. "Count"]
  frame.stealable = _G[name .. "Stealable"]
	frame.ButtonData = {
		Highlight = false
	}
	return frame
end

function Auras:CreateFrame(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create buff frame
	if not self.buffFrame[unit] and self.db[unit].aurasBuffs then
		self.buffFrame[unit] = CreateFrame("Frame", nil, button)
		self.buffFrame[unit].parent = CreateFrame("Frame", nil, self.buffFrame[unit])

		for i = 1, 40 do
			self.buffFrame[unit][i] = CreateAuraFrame("GladiusEx" .. self:GetName() ..  unit .. "Buff" .. i, self.buffFrame[unit].parent)
			self.buffFrame[unit][i]:Hide()

			if MSQ_Buffs then
				MSQ_Buffs:AddButton(self.buffFrame[unit][i], self.buffFrame[unit][i].ButtonData)
			end
		end
	end

	-- create debuff frame
	if not self.debuffFrame[unit] and self.db[unit].aurasDebuffs then
		self.debuffFrame[unit] = CreateFrame("Frame", nil, button)
		self.debuffFrame[unit].parent = CreateFrame("Frame", nil, self.debuffFrame[unit])

		for i = 1, 40 do
			self.debuffFrame[unit][i] = CreateAuraFrame("GladiusEx" .. self:GetName() .. unit .. "Debuff" .. i, self.debuffFrame[unit].parent)
			self.debuffFrame[unit][i]:Hide()

			if MSQ_Debuffs then
				MSQ_Debuffs:AddButton(self.debuffFrame[unit][i], self.debuffFrame[unit][i].ButtonData)
			end
		end
	end
end

local function UpdateAuraFrame(frame)
	frame:SetButtonState("NORMAL", true)
	frame:SetNormalTexture("")
	frame:SetHighlightTexture("")
	frame.cooldown:SetReverse(true)
end

local function Aura_OnEnter(self)
	if self.aura_index then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.aura_buff then
			GameTooltip:SetUnitBuff(self.unit, self.aura_index)
		else
			GameTooltip:SetUnitDebuff(self.unit, self.aura_index)
		end
	end
end

local function Aura_OnLeave(self)
	GameTooltip:Hide()
end

local function UpdateAuraGroup(
	auraFrame, unit,
	aurasBuffsAttachTo,
	aurasBuffsAnchor,
	aurasBuffsRelativePoint,
	aurasBuffsOffsetX,
	aurasBuffsOffsetY,
	aurasBuffsPerRow,
	aurasBuffsMaxRows,
	aurasBuffsGrow,
	aurasBuffsSize,
	aurasBuffsSpacingX,
	aurasBuffsSpacingY,
	aurasBuffsTooltips)

	-- auraFrame:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 16 })
	-- auraFrame:SetBackdropColor(0,1,0,1)

	-- anchor point
	local parent = GladiusEx:GetAttachFrame(unit, aurasBuffsAttachTo)
	auraFrame:ClearAllPoints()
	auraFrame:SetPoint(aurasBuffsAnchor, parent, aurasBuffsRelativePoint, aurasBuffsOffsetX, aurasBuffsOffsetY)
	auraFrame:SetFrameLevel(60)

	-- size
	local aurasBuffsMax = min(40, aurasBuffsPerRow * aurasBuffsMaxRows)
	auraFrame:SetWidth(aurasBuffsSize * aurasBuffsPerRow + aurasBuffsSpacingX * (aurasBuffsPerRow - 1))
	auraFrame:SetHeight(aurasBuffsSize * ceil(aurasBuffsMax / aurasBuffsPerRow) + (aurasBuffsSpacingY * (ceil(aurasBuffsMax / aurasBuffsPerRow) - 1)))
	auraFrame.parent:SetScale(aurasBuffsSize / 36)

	-- icon points
	local anchor, parent, relativePoint, offsetX, offsetY

	local start, startAnchor = 1, auraFrame
	for i = 1, 40 do
		auraFrame[i]:ClearAllPoints()
		if aurasBuffsTooltips then
			auraFrame[i]:EnableMouse(true)
			auraFrame[i]:SetScript("OnEnter", Aura_OnEnter)
			auraFrame[i]:SetScript("OnLeave", Aura_OnLeave)
		else
			auraFrame[i]:EnableMouse(false)
			auraFrame[i]:SetScript("OnEnter", nil)
			auraFrame[i]:SetScript("OnLeave", nil)
		end
		UpdateAuraFrame(auraFrame[i])
	end
end

function Auras:Update(unit)
	-- create frame
	self:CreateFrame(unit)

	-- update buff frame
	if self.db[unit].aurasBuffs then
		UpdateAuraGroup(self.buffFrame[unit], unit,
			self.db[unit].aurasBuffsAttachTo,
			self.db[unit].aurasBuffsAnchor,
			self.db[unit].aurasBuffsRelativePoint,
			self.db[unit].aurasBuffsOffsetX,
			self.db[unit].aurasBuffsOffsetY,
			self.db[unit].aurasBuffsPerRow,
			self.db[unit].aurasBuffsMaxRows,
			self.db[unit].aurasBuffsGrow,
			self.db[unit].aurasBuffsSize,
			self.db[unit].aurasBuffsSpacingX,
			self.db[unit].aurasBuffsSpacingY,
			self.db[unit].aurasBuffsTooltips)
		if MSQ_Buffs then
			MSQ_Buffs:ReSkin()
		end
	end
	-- hide
	if self.buffFrame[unit] then
		self.buffFrame[unit]:Hide()
	end

	-- update debuff frame
	if self.db[unit].aurasDebuffs then
		UpdateAuraGroup(self.debuffFrame[unit], unit,
			self.db[unit].aurasDebuffsAttachTo,
			self.db[unit].aurasDebuffsAnchor,
			self.db[unit].aurasDebuffsRelativePoint,
			self.db[unit].aurasDebuffsOffsetX,
			self.db[unit].aurasDebuffsOffsetY,
			self.db[unit].aurasDebuffsPerRow,
			self.db[unit].aurasDebuffsMaxRows,
			self.db[unit].aurasDebuffsGrow,
			self.db[unit].aurasDebuffsSize,
			self.db[unit].aurasDebuffsSpacingX,
			self.db[unit].aurasDebuffsSpacingY,
			self.db[unit].aurasDebuffsTooltips)
		if MSQ_Debuffs then
			MSQ_Debuffs:ReSkin()
		end
	end
	-- hide
	if self.debuffFrame[unit] then
		self.debuffFrame[unit]:Hide()
	end
end

function Auras:Show(unit)
	-- show buff frame
	if self.db[unit].aurasBuffs and self.buffFrame[unit] then
		self.buffFrame[unit]:Show()
	end

	-- show debuff frame
	if self.db[unit].aurasDebuffs and self.debuffFrame[unit] then
		self.debuffFrame[unit]:Show()
	end
end

function Auras:Reset(unit)
	if self.buffFrame[unit] then
		-- hide buff frame
		self.buffFrame[unit]:Hide()

		for i = 1, 40 do
			self.buffFrame[unit][i]:Hide()
		end
	end

	if self.debuffFrame[unit] then
		-- hide debuff frame
		self.debuffFrame[unit]:Hide()

		for i = 1, 40 do
			self.debuffFrame[unit][i]:Hide()
		end
	end
end

function Auras:Refresh(unit)
	self:UpdateUnitAuras("Refresh", unit)
end

function Auras:Test(unit)
	self:UpdateUnitAuras("Test", unit)
end

local function HasAuraEditBox()
	return not not LibStub("AceGUI-3.0").WidgetVersions["Aura_EditBox"]
end

function Auras:GetOptions(unit)
	local options
	options = {
		buffs = {
			type = "group",
			name = L["Buffs"],
			order = 1,
			args = {
				aurasBuffs = {
					type = "toggle",
					name = L["Show Buffs"],
					desc = L["Toggle aura buffs"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 0,
				},
				aurasBuffsOnlyDispellable = {
					type = "toggle",
					name = L["Show only dispellable"],
					disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
					hidden = function() return GladiusEx:IsPartyUnit(unit) end,
					order = 14,
				},
				aurasBuffsOnlyMine = {
					type = "toggle",
					name = L["Show only mine"],
					disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
					hidden = function() return GladiusEx:IsArenaUnit(unit) end,
					order = 14.1,
				},
				aurasBuffsTooltips = {
					type = "toggle",
					name = L["Show tooltips"],
					desc = L["Toggle if the auras should show the aura tooltip when hovered"],
					disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
					order = 15,
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 20,
					args = {
						aurasBuffsSize = {
							type = "range",
							name = L["Icon size"],
							desc = L["Size of the aura icons"],
							min = 10, max = 100, step = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						aurasBuffsEnlargeMine = {
							type = "toggle",
							name = L["Enlarge mine"],
							desc = L["Toggle if your auras should be enlarged"],
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 6,
						},
						aurasBuffsEnlargeScale = {
							type = "range",
							name = L["Enlarged scale"],
							desc = L["Scale of the enlarged auras"],
							min = 1, max = 3, bigStep = 0.05, isPercent = true,
							disabled = function() return not self.db[unit].aurasBuffsEnlargeMine or not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						aurasBuffsSpacingY = {
							type = "range",
							name = L["Vertical spacing"],
							desc = L["Vertical spacing of the icons"],
							min = 0, max = 30, step = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 15,
						},
						aurasBuffsSpacingX = {
							type = "range",
							name = L["Horizontal spacing"],
							desc = L["Horizontal spacing of the icons"],
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							min = 0, max = 30, step = 1,
							order = 20,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 25,
						},
						aurasBuffsPerRow = {
							type = "range",
							name = L["Auras per row"],
							desc = L["Number of auras per row"],
							min = 1, max = 40, step = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 30,
						},
						aurasBuffsMaxRows = {
							type = "range",
							name = L["Number of rows"],
							desc = L["Max number of rows"],
							min = 1, softMax = 10, step = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 31,
						},
					},
				},
				appearence = {
					type = "group",
					name = L["Appearance"],
					desc = L["Appearance settings"],
					inline = true,
					order = 25,
					args = {
						aurasBuffsShowSwipe = {
							type = "toggle",
							name = L["Show swipe"],
							desc = L["Show cooldown swipe on buffs"],
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						aurasBuffsSwipeReversed = {
							type = "toggle",
							name = L["Reverse swipe"],
							desc = L["Reverse swipe animation"],
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) or not self.db[unit].aurasBuffsShowSwipe end,
							order = 2,
						},
						aurasBuffsSwipeColor = {
							type = "color",
              hasAlpha = true,
							name = L["Swipe color"],
							desc = L["Cooldown swipe color on buffs"],
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) or not self.db[unit].aurasBuffsShowSwipe end,
							order = 3,
						},
					}
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 30,
					args = {
						aurasBuffsAttachTo = {
							type = "select",
							name = L["Attach to"],
							desc = L["Attach to the given frame"],
							values = function() return self:GetOtherAttachPoints(unit) end,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						aurasBuffsPosition = {
							type = "select",
							name = L["Position"],
							desc = L["Position of the frame"],
							values = GladiusEx:GetGrowSimplePositions(),
							get = function()
								return GladiusEx:GrowSimplePositionFromAnchor(
									self.db[unit].aurasBuffsAnchor,
									self.db[unit].aurasBuffsRelativePoint,
									self.db[unit].aurasBuffsGrow)
							end,
							set = function(info, value)
								self.db[unit].aurasBuffsAnchor, self.db[unit].aurasBuffsRelativePoint =
									GladiusEx:AnchorFromGrowSimplePosition(value, self.db[unit].aurasBuffsGrow)
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return GladiusEx.db.base.advancedOptions end,
							order = 6,
						},
						aurasBuffsGrow = {
							type = "select",
							name = L["Grow direction"],
							desc = L["Grow direction of the icons"],
							values = {
								["UPLEFT"] = L["Up left"],
								["UPRIGHT"] = L["Up right"],
								["DOWNLEFT"] = L["Down left"],
								["DOWNRIGHT"] = L["Down right"],
							},
							set = function(info, value)
								if not GladiusEx.db.base.advancedOptions then
									self.db[unit].aurasBuffsAnchor, self.db[unit].aurasBuffsRelativePoint =
										GladiusEx:AnchorFromGrowDirection(
											self.db[unit].aurasBuffsAnchor,
											self.db[unit].aurasBuffsRelativePoint,
											self.db[unit].aurasBuffsGrow,
											value)
								end
								self.db[unit].aurasBuffsGrow = value
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 8,
						},
						aurasBuffsAnchor = {
							type = "select",
							name = L["Anchor"],
							desc = L["Anchor of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 10,
						},
						aurasBuffsRelativePoint = {
							type = "select",
							name = L["Relative point"],
							desc = L["Relative point of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						aurasBuffsOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the frame"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						aurasBuffsOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset of the frame"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].aurasBuffs or not self:IsUnitEnabled(unit) end,
							order = 25,
						},
					},
				},
			},
		},
		debuffs = {
			type = "group",
			name = L["Debuffs"],
			order = 2,
			args = {
				aurasDebuffs = {
					type = "toggle",
					name = L["Show Debuffs"],
					desc = L["Toggle aura debuffs"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 5,
				},
				aurasDebuffsOnlyDispellable = {
					type = "toggle",
					name = L["Show only dispellable"],
					disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
					hidden = function() return GladiusEx:IsArenaUnit(unit) end,
					order = 14,
				},
				aurasDebuffsOnlyMine = {
					type = "toggle",
					name = L["Show only mine"],
					disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
					hidden = function() return GladiusEx:IsPartyUnit(unit) end,
					order = 14.1,
				},
				aurasDebuffsTooltips = {
					type = "toggle",
					name = L["Show tooltips"],
					desc = L["Toggle if the auras should show the aura tooltip when hovered"],
					disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
					order = 15,
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 20,
					args = {
						aurasDebuffsSize = {
							type = "range",
							name = L["Icon size"],
							desc = L["Size of the icons"],
							min = 10, max = 100, step = 1,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						aurasDebuffsEnlargeMine = {
							type = "toggle",
							name = L["Enlarge mine"],
							desc = L["Toggle if your auras should be enlarged"],
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 6,
						},
						aurasDebuffsEnlargeScale = {
							type = "range",
							name = L["Enlarged scale"],
							desc = L["Scale of the enlarged auras"],
							min = 1, max = 3, bigStep = 0.05, isPercent = true,
							disabled = function() return not self.db[unit].aurasDebuffsEnlargeMine or not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						aurasDebuffsSpacingY = {
							type = "range",
							name = L["Vertical spacing"],
							desc = L["Vertical spacing of the icons"],
							min = 0, max = 30, step = 1,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 15,
						},
						aurasDebuffsSpacingX = {
							type = "range",
							name = L["Horizontal spacing"],
							desc = L["Horizontal spacing of the icons"],
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							min = 0, max = 30, step = 1,
							order = 20,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 25,
						},
						aurasDebuffsPerRow = {
							type = "range",
							name = L["Auras per row"],
							desc = L["Number of auras per row"],
							min = 1, max = 40, step = 1,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 30,
						},
						aurasDebuffsMaxRows = {
							type = "range",
							name = L["Number of rows"],
							desc = L["Max number of rows"],
							min = 1, softMax = 10, step = 1,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 31,
						},
					},
				},
				appareance = {
					type = "group",
					name = L["Appearance"],
					desc = L["Appearance settings"],
					inline = true,
					order = 25,
					args = {
						aurasDebuffsShowSwipe = {
							type = "toggle",
							name = L["Show swipe"],
							desc = L["Show cooldown swipe on debuffs"],
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						aurasDebuffsSwipeReversed = {
							type = "toggle",
							name = L["Reverse swipe"],
							desc = L["Reverse swipe animation"],
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) or not self.db[unit].aurasDebuffsShowSwipe end,
							order = 2,
						},
						aurasDebuffsSwipeColor = {
							type = "color",
              hasAlpha = true,
							name = L["Swipe color"],
							desc = L["Cooldown swipe color on debuffs"],
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) or not self.db[unit].aurasDebuffsShowSwipe end,
							order = 3,
						},
					}
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 30,
					args = {
						aurasDebuffsAttachTo = {
							type = "select",
							name = L["Attach to"],
							desc = L["Attach to the given frame"],
							values = function() return self:GetOtherAttachPoints(unit) end,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						aurasDebuffsPosition = {
							type = "select",
							name = L["Position"],
							desc = L["Position of the frame"],
							values = GladiusEx:GetGrowSimplePositions(),
							get = function()
								return GladiusEx:GrowSimplePositionFromAnchor(
									self.db[unit].aurasDebuffsAnchor,
									self.db[unit].aurasDebuffsRelativePoint,
									self.db[unit].aurasDebuffsGrow)
							end,
							set = function(info, value)
								self.db[unit].aurasDebuffsAnchor, self.db[unit].aurasDebuffsRelativePoint =
									GladiusEx:AnchorFromGrowSimplePosition(value, self.db[unit].aurasDebuffsGrow)
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return GladiusEx.db.base.advancedOptions end,
							order = 6,
						},
						aurasDebuffsGrow = {
							type = "select",
							name = L["Grow direction"],
							desc = L["Grow direction of the icons"],
							values = {
								["UPLEFT"] = L["Up left"],
								["UPRIGHT"] = L["Up right"],
								["DOWNLEFT"] = L["Down left"],
								["DOWNRIGHT"] = L["Down right"],
							},
							set = function(info, value)
								if not GladiusEx.db.base.advancedOptions then
									self.db[unit].aurasDebuffsAnchor, self.db[unit].aurasDebuffsRelativePoint =
										GladiusEx:AnchorFromGrowDirection(
											self.db[unit].aurasDebuffsAnchor,
											self.db[unit].aurasDebuffsRelativePoint,
											self.db[unit].aurasDebuffsGrow,
											value)
								end
								self.db[unit].aurasDebuffsGrow = value
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 9,
						},
						aurasDebuffsAnchor = {
							type = "select",
							name = L["Anchor"],
							desc = L["Anchor of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 10,
						},
						aurasDebuffsRelativePoint = {
							type = "select",
							name = L["Relative point"],
							desc = L["Relative point of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						aurasDebuffsOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						aurasDebuffsOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset"],
							disabled = function() return not self.db[unit].aurasDebuffs or not self:IsUnitEnabled(unit) end,
							softMin = -100, softMax = 100, bigStep = 1,
							order = 25,
						},
					},
				},
			},
		},
		filters = {
			type = "group",
			name = L["Filters"],
			childGroups = "tree",
			order = 3,
			args = {
				aurasFilterType = {
					type = "select",
					style = "radio",
					name = L["Filter type"],
					desc = L["Filter type"],
					values = {
						[FILTER_TYPE_DISABLED] = L["Disabled"],
						[FILTER_TYPE_WHITELIST] = L["Whitelist"],
						[FILTER_TYPE_BLACKLIST] = L["Blacklist"],
					},
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 1,
				},
				aurasFilterWhat = {
					type = "select",
					style = "radio",
					name = L["Apply filter to"],
					desc = L["What auras to filter"],
					values = {
						[FILTER_WHAT_BUFFS] = L["Buffs"],
						[FILTER_WHAT_DEBUFFS] = L["Debuffs"],
						[FILTER_WHAT_BOTH] = L["Both"],
					},
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 2,
				},
				newAura = {
					type = "group",
					name = L["Add new aura filter"],
					desc = L["Add new aura filter"],
					inline = true,
					order = 3,
					args = {
						name = {
							type = "input",
							dialogControl = HasAuraEditBox() and "Aura_EditBox" or nil,
							name = L["Name"],
							desc = L["Name of the aura"],
							get = function() return self.newAuraName or "" end,
							set = function(info, value) self.newAuraName = ((C_Spell and C_Spell.GetSpellName) and C_Spell.GetSpellName(value) or GetSpellInfo(value)) or value end,
							disabled = function() return not self:IsUnitEnabled(unit) or self.db[unit].aurasFilterType == FILTER_TYPE_DISABLED end,
							order = 1,
						},
						add = {
							type = "execute",
							name = L["Add new aura filter"],
							func = function(info)
								self.db[unit].aurasFilterAuras[self.newAuraName] = true
								options.filters.args[self.newAuraName] = self:SetupAuraOptions(options, unit, self.newAuraName)
								self.newAuraName = nil
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) or not self.newAuraName or self.db[unit].aurasFilterType == FILTER_TYPE_DISABLED end,
							order = 3,
						},
					},
				},
			},
		},
		order = {
			type = "group",
			name = L["Ordering"],
			childGroups = "tree",
			order = 4,
			args = {
				aurasPrioFirst = {
					type = "toggle",
					name = L["Higher prio first"],
					desc = L["Show buffs with a higher priority level at the beginning"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 0,
				},
				newAuraOrder = {
					type = "group",
					name = L["Add new aura order"],
					desc = L["Add new aura order"],
					inline = true,
					order = 3,
					args = {
						name = {
							type = "input",
							dialogControl = HasAuraEditBox() and "Aura_EditBox" or nil,
							name = L["Name"],
							desc = L["Name of the aura"],
							get = function() return self.newAuraOrderName or "" end,
							set = function(info, value) self.newAuraOrderName = (C_Spell and C_Spell.GetSpellName(value) or GetSpellInfo(value)) or value end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						add = {
							type = "execute",
							name = L["Add new aura filter"],
							func = function(info)
								local name = self.newAuraOrderName
								if fn.contains(self.db[unit].aurasPrioList, name) then
									return -- already there
								end
								tinsert(self.db[unit].aurasPrioList, name)
								options.order.args[name] = self:SetupAuraOrderOptions(options, unit, name)
								self.newAuraOrderName = nil
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
						},
					},
				}
			},
		},
	}

	-- setup auras
	for aura, v in pairs(self.db[unit].aurasFilterAuras) do
		-- v is false for deleted values
		if v then
			options.filters.args[tostring(aura)] = self:SetupAuraOptions(options, unit, aura)
		end
	end

  -- setup aura ordering
  local ordered
  for i, aura in pairs(self.db[unit].aurasPrioList) do
    options.order.args[tostring(aura)] = self:SetupAuraOrderOptions(options, unit, aura)
  end

	return options
end

function Auras:SetupAuraOrderOptions(options, unit, aura)

	local function GetIdx(override_aura)
		return select(2, fn.find_first_of(self.db[unit].aurasPrioList, override_aura or aura))
	end

	local function IsEdge()
		local idx = GetIdx()
		return idx == 1 or idx == #self.db[unit].aurasPrioList
	end

	return {
		type = "group",
		name = aura,
		desc = aura,
		order = function ()
			return 100 + GetIdx()
		end,
		disabled = function() return not self:IsUnitEnabled(unit) end,
		args = {
			up = {
				type = "execute",
				name = L["Up"],
				func = function(info)
					local idx = GetIdx()
					local newIdx = idx - 1
					self.db[unit].aurasPrioList[idx] = self.db[unit].aurasPrioList[newIdx]
					self.db[unit].aurasPrioList[newIdx] = aura

					GladiusEx:UpdateFrames()
				end,
				order = 1,
				disabled = function() return GetIdx() == 1 end,
			},
			down = {
				type = "execute",
				name = L["Down"],
				func = function(info)
					local idx = GetIdx()
					local newIdx = idx + 1
					self.db[unit].aurasPrioList[idx] = self.db[unit].aurasPrioList[newIdx]
					self.db[unit].aurasPrioList[newIdx] = aura

					GladiusEx:UpdateFrames()
				end,
				order = 2,
				disabled = function() return GetIdx() == #self.db[unit].aurasPrioList end,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				func = function(info)
					tremove(self.db[unit].aurasPrioList, GetIdx())
					options.order.args[aura] = nil

					GladiusEx:UpdateFrames()
				end,
				order = 3,
				disabled = function() return not self:IsUnitEnabled(unit) end,
			},
		}
  }
end

function Auras:SetupAuraOptions(options, unit, aura)
	local function setAura(info, value)
		if (info[#(info)] == "name") then
			local old_name = info[#(info) - 1]

			-- create new aura
			self.db[unit].aurasFilterAuras[value] = true
			options.filters.args[value] = self:SetupAuraOptions(options, unit, value)

			-- delete old aura
			self.db[unit].aurasFilterAuras[old_name] = false
			options.filters.args[old_name] = nil
		else
			self.db[unit].aurasFilterAuras[info[#(info) - 1]] = value
		end

		GladiusEx:UpdateFrames()
	end

	local function getAura(info)
		if (info[#(info)] == "name") then
			return info[#(info) - 1]
		else
			return self.db[unit].aurasFilterAuras[info[#(info) - 1]]
		end
	end

	return {
		type = "group",
		name = aura,
		desc = tostring(aura),
		get = getAura,
		set = setAura,
		disabled = function() return not self:IsUnitEnabled(unit) end,
		args = {
			name = {
				type = "input",
				dialogControl = HasAuraEditBox() and "Aura_EditBox" or nil,
				name = L["Name"],
				desc = L["Name of the aura"],
				disabled = function() return not self:IsUnitEnabled(unit)  or self.db[unit].aurasFilterType == FILTER_TYPE_DISABLED end,
				order = 1,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				func = function(info)
					local aura = info[#(info) - 1]
					-- very important: set to false so that they're not removed
					-- see https://github.com/slaren/GladiusEx/issues/10
					self.db[unit].aurasFilterAuras[aura] = false
					options.filters.args[aura] = nil

					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self:IsUnitEnabled(unit) or self.db[unit].aurasFilterType == FILTER_TYPE_DISABLED end,
				order = 3,
			},
		},
	}
end
