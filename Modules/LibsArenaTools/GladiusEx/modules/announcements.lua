local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")

-- global functions
local strfind = string.find
local GetTime, UnitName, UnitClass = GetTime, UnitName, UnitClass
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local SendChatMessage = SendChatMessage
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetRealNumPartyMembers, GetRealNumRaidMembers, IsRaidLeader, IsRaidOfficer = GetRealNumPartyMembers, GetRealNumRaidMembers, IsRaidLeader, IsRaidOfficer

local Announcements = GladiusEx:NewGladiusExModule("Announcements", {
		drinks = true,
		health = true,
		resurrect = true,
		spec = true,
		healthThreshold = 25,
		dest = "party",
	})

function Announcements:OnEnable()
	-- register events
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- register messages
	self:RegisterMessage("GLADIUS_SPEC_UPDATE")

	-- table holding messages to throttle
	self.throttled = {}
end

function Announcements:PLAYER_ENTERING_WORLD()
	self.throttled = {}
end

function Announcements:OnDisable()
	self:UnregisterAllEvents()
end

local handled_units = {}

function Announcements:Reset(unit)
	handled_units[unit] = false
end

function Announcements:Show(unit)
	handled_units[unit] = true
end

function Announcements:IsHandledUnit(unit)
	return handled_units[unit]
end

function Announcements:GLADIUS_SPEC_UPDATE(event, unit)
	if not self:IsHandledUnit(unit) or not self.db[unit].spec then return end

	if GladiusEx.buttons[unit].specID then
		local class = UnitClass(unit) or LOCALIZED_CLASS_NAMES_MALE[GladiusEx.buttons[unit].class] or "??"
		local spec = select(2, GladiusEx.Data.GetSpecializationInfoByID(GladiusEx.buttons[unit].specID))
		self:Send(string.format(L["Enemy spec: %s (%s/%s)"], UnitName(unit) or unit, class, spec), 15, unit)
	end
end

function Announcements:UNIT_HEALTH(event, unit)
	if not self:IsHandledUnit(unit) or not self.db[unit].health then return end

	local healthPercent = math.floor((UnitHealth(unit) / UnitHealthMax(unit)) * 100)
	if healthPercent < self.db[unit].healthThreshold then
		self:Send(string.format(L["LOW HEALTH: %s (%s)"], UnitName(unit), UnitClass(unit)), 10, unit)
	end
end

local DRINK_SPELL = 57073
function Announcements:UNIT_AURA(event, unit)
	if not self:IsHandledUnit(unit) or not self.db[unit].drinks then return end

	for i = 1, 40 do
		local name, _, _, _, _, _, _, _, _, spellID = GladiusEx.UnitBuff(unit, i, "HELPFUL")
		if not name then break end
		if spellID == DRINK_SPELL then
			self:Send(string.format(L["DRINKING: %s (%s)"], UnitName(unit), UnitClass(unit)), 2, unit)
			break
		end
	end
end

local RES_SPELLS = {
	-- V: removed SafeGetSpellName() for BfA, need to make sure it's ok
	[2008] = true,   -- Ancestral Spirit (shaman)
	[8342] = true,   -- Defibrillate (item: Goblin Jumper Cables)
	[22999] = true,  -- Defibrillate (item: Goblin Jumper Cables XL)
	[54732] = true,  -- Defibrillate (item: Gnomish Army Knife)
	[61999] = true,  -- Raise Ally (death knight)
	[20484] = true,  -- Rebirth (druid)
	[7328] = true,   -- Redemption (paladin)
	[2006] = true,   -- Resurrection (priest)
	[115178] = true, -- Resuscitate (monk)
	[50769] = true,  -- Revive (druid)
	[982] = true,    -- Revive Pet (hunter)
	[20707] = true,  -- Soulstone (warlock)
}

function Announcements:UNIT_SPELLCAST_START(event, unit, lineID, spell)
	if not self:IsHandledUnit(unit) or not self.db[unit].resurrect then return end

	if RES_SPELLS[spell] then
		self:Send(string.format(L["RESURRECTING: %s (%s)"], UnitName(unit), UnitClass(unit)), 2, unit)
	end
end

-- Sends an announcement
-- Param unit is only used for class coloring of messages
function Announcements:Send(msg, throttle, unit)
	-- only send announcements inside arenas
	if select(2, IsInInstance()) ~= "arena" then return end

	-- throttling
	if not self.throttled then
		self.throttled = {}
	end

	if throttle and throttle > 0 then
		if not self.throttled[msg] then
			self.throttled[msg] = GetTime() + throttle
		elseif self.throttled[msg] < GetTime() then
			self.throttled[msg] = nil
		else
			return
		end
	end

	local color = unit and RAID_CLASS_COLORS[UnitClass(unit)] or { r = 0, g = 1, b = 0 }
	local dest = self.db[unit].dest

	if dest == "self" then
		GladiusEx:Print(msg)
	end

	-- change destination to party if not raid leader/officer.
	if dest == "rw" and not IsRaidLeader() and not IsRaidOfficer() and GetNumGroupMembers() > 0 then
		dest = "party"
	end

	-- party chat
	if (dest == "party") and (GetNumGroupMembers() > 0) then
		SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY")

	-- say
	elseif dest == "say" then
		SendChatMessage(msg, "SAY")

	-- raid warning
	elseif dest == "rw" then
		SendChatMessage(msg, "RAID_WARNING")

	-- floating combat text
	elseif dest == "fct" and IsAddOnLoaded("Blizzard_CombatText") then
		CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, color.r, color.g, color.b)

	-- MikScrollingBattleText
	elseif dest == "msbt" and IsAddOnLoaded("MikScrollingBattleText") then
		MikSBT.DisplayMessage(msg, MikSBT.DISPLAYTYPE_NOTIFICATION, false, color.r * 255, color.g * 255, color.b * 255)

	-- xCT
	elseif dest == "xct" and IsAddOnLoaded("xCT") then
		ct.frames[3]:AddMessage(msg, color.r * 255, color.g * 255, color.b * 255)

	-- xCT+
	elseif dest == "xctplus" and IsAddOnLoaded("xCT+") then
		xCT_Plus:AddMessage("general", msg, {color.r, color.g, color.b})

	-- Scrolling Combat Text
	elseif dest == "sct" and IsAddOnLoaded("sct") then
		SCT:DisplayText(msg, color, nil, "event", 1)

	-- Parrot
	elseif dest == "parrot" and IsAddOnLoaded("parrot") then
		Parrot:ShowMessage(msg, "Notification", false, color.r, color.g, color.b)
	end
end

function Announcements:GetOptions(unit)
	local destValues = {
		["self"] = L["Self"],
		["party"] = L["Party"],
		["say"] = L["Say"],
		["rw"] = L["Raid Warning"],
		["fct"] = L["Blizzard's Floating Combat Text"],
		["sct"] = "Scrolling Combat Text",
		["msbt"] = "MikScrollingBattleText",
		["parrot"] = "Parrot",
		["xct"] = "xCT",
		["xctplus"] = "xCT+"
	}

	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				options = {
					type = "group",
					name = L["Options"],
					inline = true,
					order = 1,
					args = {
						dest = {
							type = "select",
							name = L["Destination"],
							desc = L["Choose how your announcements are displayed"],
							values = destValues,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						healthThreshold = {
							type = "range",
							name = L["Low health threshold"],
							desc = L["Choose how low an enemy must be before low health is announced"],
							disabled = function() return not self:IsUnitEnabled(unit) or not self.db[unit].health end,
							min = 1,
							max = 100,
							step = 1,
							order = 10,
						},
					},
				},
				announcements = {
					type = "group",
					name = L["Announcement toggles"],
					inline = true,
					order = 5,
					args = {
						drinks = {
							type = "toggle",
							name = L["Drinking"],
							desc = L["Announces when enemies sit down to drink"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						health = {
							type = "toggle",
							name = L["Low health"],
							desc = L["Announces when an enemy drops below a certain health threshold"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 30,
						},
						resurrect = {
							type = "toggle",
							name = L["Resurrection"],
							desc = L["Announces when an enemy tries to resurrect a teammate"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 40,
						},
						spec = {
							type = "toggle",
							name = L["Spec detection"],
							desc = L["Announces when the spec of an enemy was detected"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 40,
						},
					},
				},
			},
		}
	}
end
	
