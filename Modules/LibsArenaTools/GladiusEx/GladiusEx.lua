GladiusEx = LibStub("AceAddon-3.0"):NewAddon("GladiusEx", "AceEvent-3.0")

GladiusEx.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
GladiusEx.IS_TBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
GladiusEx.IS_WOTLKC = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
GladiusEx.IS_CATAC = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
GladiusEx.IS_MOPC = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
GladiusEx.IS_CLASSIC = GladiusEx.IS_TBCC or GladiusEx.IS_WOTLKC or GladiusEx.IS_CATAC or GladiusEx.IS_MOPC

GladiusEx.IS_PRE_MOP = GladiusEx.IS_TBCC or GladiusEx.IS_WOTLKC or GladiusEx.IS_CATAC
GladiusEx.IS_PRE_WOD = GladiusEx.IS_PRE_MOP or GladiusEx.IS_MOPC

local LGIST = GladiusEx.IS_RETAIL and LibStub:GetLibrary("LibGroupInSpecT-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local RC = LibStub("LibRangeCheck-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local fn = LibStub("LibFunctional-1.0")

local function InternalUnpackAuraData(auraData)
  if not auraData then
    return nil
  end
  return auraData.name,
    auraData.icon,
    auraData.applications,
    auraData.dispelName,
    auraData.duration,
    auraData.expirationTime,
    auraData.sourceUnit,
    auraData.isStealable,
    auraData.nameplateShowPersonal,
    auraData.spellId,
    auraData.canApplyAura,
    auraData.isBossAura,
    auraData.isFromPlayerOrPlayerPet,
    auraData.nameplateShowAll,
    auraData.timeMod,
    auraData.points and unpack(auraData.points) or nil
end

GladiusEx.UnitAura = UnitAura or function(unitToken, index, filter)
  local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
  if not auraData then
    return nil
  end

  return AuraUtil.UnpackAuraData(auraData)
end

GladiusEx.UnitBuff = UnitBuff or function(unitToken, index, filter)
  local auraData = C_UnitAuras.GetBuffDataByIndex(unitToken, index, filter)
  if not auraData then
    return nil
  end

  return AuraUtil.UnpackAuraData(auraData)
end

GladiusEx.UnitDebuff = UnitDebuff or function(unitToken, index, filter)
  local auraData = C_UnitAuras.GetDebuffDataByIndex(unitToken, index, filter)
  if not auraData then
    return nil
  end

  -- K: Why can we not use AuraUtil.UnpackAuraData for debuffs?
  return InternalUnpackAuraData(auraData)
end

-- upvalues
local select, type, pairs, tonumber, wipe = select, type, pairs, tonumber, wipe
local strfind, strmatch = string.find, string.match
local max, abs, floor, ceil = math.max, math.abs, math.floor, math.ceil
local UnitIsDeadOrGhost, UnitGUID, UnitExists = UnitIsDeadOrGhost, UnitGUID, UnitExists
local InCombatLockdown = InCombatLockdown
local GetNumGroupMembers = GetNumArenaOpponents, GetNumArenaOpponentSpecs, GetNumGroupMembers

local arena_units = {
    ["arena1"] = true,
    ["arena2"] = true,
    ["arena3"] = true,
    ["arena4"] = true,
    ["arena5"] = true
}

local party_units = {
    ["player"] = true,
    ["party1"] = true,
    ["party2"] = true,
    ["party3"] = true,
    ["party4"] = true
}

GladiusEx.party_units = party_units
GladiusEx.arena_units = arena_units

local anchor_width = 260
local anchor_height = 40

local STATE_NORMAL = 0
local STATE_DEAD = 1
local STATE_STEALTH = 2
local RANGE_UPDATE_INTERVAL = 1 / 5

-- debugging output
local log_frame
local log_table
local logging = false
local function log(...)
	if not GladiusEx:IsDebugging() then return end
	if not log_frame then
		log_frame = CreateFrame("ScrollingMessageFrame", "GladiusExLogFrame")

		log_frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -50)
		log_frame:SetFrameStrata("LOW")

		log_frame:SetScript("OnMouseWheel", FloatingChatFrame_OnMouseScroll)
		log_frame:EnableMouseWheel(true)

		log_frame:SetSize(500, 500)
		log_frame:SetFont(STANDARD_TEXT_FONT, 9, "NONE")
		log_frame:SetShadowColor(0, 0, 0, 1)
		log_frame:SetShadowOffset(1, -1)
		log_frame:SetFading(false)
		log_frame:SetJustifyH("LEFT")
		log_frame:SetIndentedWordWrap(true)
		log_frame:SetMaxLines(10000)
		log_frame:SetBackdropColor(1, 1, 1, 0.2)
		log_frame.starttime = GetTime()

		log_frame:SetScale(1)
	end
	local p = ...
	if p == "ENABLE LOGGING" then
		GladiusEx.db.base.log = GladiusEx.db.base.log or {}
		log_table = { date("%c", time()) }
		table.insert(GladiusEx.db.base.log, log_table)
		logging = true
		log_frame.starttime = GetTime()
	elseif p == "DISABLE LOGGING" then
		logging = false
	end

	local msg = string.format("[%.1f] %s", GetTime() - log_frame.starttime, strjoin(" ", tostringall(...)))

	if logging then
		table.insert(log_table, msg)
	end

	log_frame:AddMessage(msg)
end

function GladiusEx:IsDebugging()
	return self.db.base.debug
end

function GladiusEx:SetDebugging(enabled)
	self.db.base.debug = enabled
end

function GladiusEx:Log(...)
	log(...)
end

function GladiusEx:Debug(...)
	print("|cff33ff99GladiusEx|r:", ...)
end

function GladiusEx:Print(...)
	print("|cff33ff99GladiusEx|r:", ...)
end

-- Module prototype
local modulePrototype = {}

function modulePrototype:GetAttachType()
	return "Widget"
end

function modulePrototype:GetFrames(unit)
	if self.frame and self.frame[unit] then
		return { self.frame[unit] }
	end
end

function modulePrototype:GetOtherAttachPoints(unit)
	return GladiusEx:GetAttachPoints(unit, self)
end

function modulePrototype:InitializeDB(name, defaults)
	local dbi = GladiusEx.dbi:RegisterNamespace(name, { profile = defaults })
	dbi.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	dbi.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	dbi.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	return dbi
end

function modulePrototype:OnInitialize()
	self.dbi_arena = self:InitializeDB(self:GetName(), self.defaults_arena)
	self.dbi_party = self:InitializeDB("party_" .. self:GetName(), self.defaults_party)
	self.db = setmetatable({}, {
		__index = function(t, k)
			local v
			k = strmatch(k, "^(.+)target$") or strmatch(k, "^(.+)pet(.+)$") or k
			if k == "target" or k == "pet" or k == "party" or GladiusEx:IsPartyUnit(k) then
				v = self.dbi_party.profile
			elseif k == "arena" or GladiusEx:IsArenaUnit(k) then
				v = self.dbi_arena.profile
			else
				error("Bad module DB usage: not an unit (" .. tostring(k) .. ")", 2)
			end
			rawset(t, k, v)
			return v
		end
	})
end

function modulePrototype:OnProfileChanged()
	wipe(self.db)
end

function modulePrototype:IsUnitEnabled(unit)
	return GladiusEx:IsModuleEnabled(unit, self:GetName())
end

GladiusEx:SetDefaultModulePrototype(modulePrototype)
GladiusEx:SetDefaultModuleLibraries("AceEvent-3.0")
GladiusEx:SetDefaultModuleState(false)

function GladiusEx:NewGladiusExModule(name, defaults_arena, defaults_party, ...)
	local module = self:NewModule(name, ...)
	module.super = modulePrototype
	module.defaults_arena = defaults_arena
	module.defaults_party = defaults_party or defaults_arena
	return module
end

function GladiusEx:GetAttachPoints(unit, skip)
	-- get module list for frame anchor
	local t = { ["Frame"] = L["Frame"] }
	for name, m in GladiusEx:IterateModules() do
		if m ~= skip and self:IsModuleEnabled(unit, name) then
			local points = m.GetModuleAttachPoints and m:GetModuleAttachPoints(unit)
			if points then
				for point, name  in pairs(points) do
					t[point] = name
				end
			end
		end
	end

	return t
end

function GladiusEx:GetAttachFrame(unit, point, nodefault)
	-- get parent frame
	if point == "Frame" then
		return self.buttons[unit]
	else
		for name, m in self:IterateModules() do
			if self:IsModuleEnabled(unit, name) then
				local points = m.GetModuleAttachPoints and m:GetModuleAttachPoints(unit)
				if points and points[point] then
					local f = m:GetModuleAttachFrame(unit, point)
					return f or (not nodefault and self.buttons[unit])
				end
			end
		end
	end
	-- default to frame
	return not nodefault and self.buttons[unit]
end

function GladiusEx:OnInitialize()
	-- init db+
	self.dbi = LibStub("AceDB-3.0"):New("GladiusExDB", self.defaults, true)
	self.dbi_arena = self.dbi:RegisterNamespace("arena", { profile = self.defaults_arena })
	self.dbi_party = self.dbi:RegisterNamespace("party", { profile = self.defaults_party })
	self.db = setmetatable({}, {
		__index = function(t, k)
			local v
			if k == "party" or GladiusEx:IsPartyUnit(k) then
				v = self.dbi_party.profile
			elseif k == "arena" or GladiusEx:IsArenaUnit(k) then
				v = self.dbi_arena.profile
			elseif k == "base" then
				v = self.dbi.profile
			else
				error("Bad DB usage: not an unit (" .. tostring(k) .. ")", 2)
			end
			rawset(t, k, v)
			return v
		end
	})

	-- libsharedmedia
	LSM:Register("statusbar", "Minimalist (GladiusEx)", [[Interface\Addons\GladiusEx\media\Minimalist]])
	LSM:Register("statusbar", "Wglass (GladiusEx)", [[Interface\Addons\GladiusEx\media\Wglass]])
	LSM:Register("font", "Designosaur (GladiusEx)", [[Interface\Addons\GladiusEx\media\Designosaur-Regular.ttf]])
	LSM:Register("font", "Designosaur Italic (GladiusEx)", [[Interface\Addons\GladiusEx\media\Designosaur-Italic.ttf]])

	-- test environment
	self.test = false
	self.testing = setmetatable({}, {
		__index = function(t, k)
				if not self.db.base.testUnits[k] then k = "arena1" end
				return self.db.base.testUnits[k]
			end
		})

	-- buttons
	self.buttons = {}

	-- debugging code for finding unused locale strings
	--[[
	setmetatable(L, {})
	local myl = fn.clone(L)
	local myl_count = fn.clone(L)
	for k in pairs(myl_count) do
		myl_count[k] = 0
	end

	wipe(L)
	setmetatable(L, {
		__index = function(self, k, v)
			myl_count[k] = myl_count[k] + 1
			return "!" .. tostring(myl[k])
		end
		})

	function GladiusEx:PrintUnused()
		local l = {}
		for k, v in pairs(myl_count) do
			if v == 0 then
				tinsert(l, k)
			end
		end
		l = fn.filter(l, function(k)
				if k:match("Tag$") or k:match(":short$") then
					return false
				end
				return true
			end)
		l = fn.sort(l)
		print(table.concat(l, "\n"))
	end
	]]
end

function GladiusEx:IsModuleEnabled(unit, name)
	return self.db[unit].modules[name]
end

function GladiusEx:CheckEnableDisableModule(name)
	local mod = self:GetModule(name)

	-- hide module if it is being disabled
	if mod:IsEnabled() and mod.Reset then
		if not self:IsModuleEnabled("party", name) then
			for unit, button in pairs(self.buttons) do
				if self:IsPartyUnit(unit) then
					mod:Reset(unit)
				end
			end
		end
		if not self:IsModuleEnabled("arena", name) then
			for unit, button in pairs(self.buttons) do
				if self:IsArenaUnit(unit) then
					mod:Reset(unit)
				end
			end
		end
	end

	if self:IsModuleEnabled("party", name) or self:IsModuleEnabled("arena", name) then
		self:EnableModule(name)
	else
		self:DisableModule(name)
	end
end

function GladiusEx:EnableModules()
	for module_name in self:IterateModules() do
		self:CheckEnableDisableModule(module_name)
	end
end

function GladiusEx:OnEnable()
    -- create frames
    -- anchor & background
    self.party_parent = CreateFrame("Frame", "GladiusExPartyFrame", UIParent)
    self.arena_parent = CreateFrame("Frame", "GladiusExArenaFrame", UIParent)
    self.party_parent:Hide()
    self.arena_parent:Hide()

    self.arena_anchor, self.arena_background = self:CreateAnchor("arena")
    self.party_anchor, self.party_background = self:CreateAnchor("party")

    -- update roster
    self:UpdateAllGUIDs()

    -- update range checkers
    self:UpdateRangeCheckers()

    -- enable modules
    self:EnableModules()

    -- init options
    self:SetupOptions()

    -- register the appropriate events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")
    if not GladiusEx.IS_PRE_MOP then
        self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
    else
        self:RegisterEvent("UNIT_AURA")
        self:RegisterEvent("UNIT_SPELLCAST_START")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_PET", "UpdateUnitGUID")
    self:RegisterEvent("UNIT_PORTRAIT_UPDATE", "UpdateUnitGUID")
    if LGIST then
        LGIST.RegisterCallback(self, "GroupInSpecT_Update")
    end
    RC.RegisterCallback(self, RC.CHECKERS_CHANGED, "UpdateRangeCheckers")
    self.dbi.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.dbi.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.dbi.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
end

local first_run = false
function GladiusEx:CheckFirstRun()
	if first_run then return end
	first_run = true
	-- display help message
	if (not self.db.base.locked and not self.db.arena.x["arena1"] and not self.db.arena.y["arena1"] and not self.db.arena.x["anchor_arena"] and not self.db.arena.y["anchor_arena"]) then
		self:Print(L["Welcome to GladiusEx!"])
		self:Print(L["First run has been detected, displaying test frame"])
		self:Print(L["Valid slash commands are:"])
		self:Print("/gex ui")
		self:Print("/gex test 2-5")
		self:Print("/gex show")
		self:Print("/gex hide")
		self:Print("/gex reset")
		self:Print(L["** If this is not your first run please lock or move the frame to prevent this from happening **"])

		self:SetTesting(3)
	elseif self:IsDebugging() then
		self:SetTesting(3)
	end
end

function GladiusEx:OnDisable()
	self:UnregisterAllEvents()
	LGIST.UnregisterAllEvents(self)
	self.dbi.UnregisterAllEvents(self)
	self:HideFrames()
end

function GladiusEx:OnProfileChanged(event, database, newProfileKey)
	-- update frame and modules on profile change
	wipe(self.db)

	self:SetupOptions()
	self:EnableModules()
	self:UpdateFrames()

	-- make sure that party is shown/hidden if its enabled state changed in the new profile
	if GladiusEx:IsArenaShown() then
		GladiusEx:HideFrames()
		GladiusEx:ShowFrames()
	end
end

function GladiusEx:SetTesting(count)
	self.test = count

	self:UpdateFrames()

	if count then
		self:ShowFrames()
	else
		self:HideFrames()
	end
end

function GladiusEx:IsTesting(unit)
    if not self.test then
        return false
    elseif unit then
        return not UnitExists(unit)
    else
        return self.test
    end
end

function GladiusEx:GetArenaSize(minVal)
    if self:IsTesting() then
        log("GetArenaSize => testing")
        return self:IsTesting()
    end

    local widget_number = 0
    if GladiusEx.IS_PRE_MOP and not self:IsTesting() and IsActiveBattlefieldArena() then
        for _, widget in pairs(C_UIWidgetManager.GetAllWidgetsBySetID(1)) do
            local text = C_UIWidgetManager.GetIconAndTextWidgetVisualizationInfo(widget.widgetID).text
            local n = tonumber(string.match(text, "%d"))
            if n > widget_number then
                widget_number = n
            end
        end
    end

    -- try to guess the current arena size
    local guess =
        max(
        minVal or 0,
        2,
        widget_number,
        GetNumArenaOpponents(),
        GladiusEx.Data.GetNumArenaOpponentSpecs() and GladiusEx.Data.GetNumArenaOpponentSpecs() or 0,
        GetNumGroupMembers(LE_PARTY_CATEGORY_HOME),
        GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE)
    )

    log(
        "GetArenaSize",
        minVal,
        GetNumArenaOpponents(),
        GladiusEx.Data.GetNumArenaOpponentSpecs() and GladiusEx.Data.GetNumArenaOpponentSpecs() or 0,
        GetNumGroupMembers(LE_PARTY_CATEGORY_HOME),
        GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE),
        " => ",
        guess
    )

    -- In Retail, Solo Shuffle sometimes returns 4
    if guess == 4 then
        guess = 3
    end

    return guess
end

function GladiusEx:UpdatePartyFrames()
	if InCombatLockdown() then
		self:QueueUpdate()
		return
	end
	local group_members = self.arena_size

	log("UpdatePartyFrames", group_members)
	self:UpdateAnchor("party")

	for i = 1, 5 do
		local unit = i == 1 and "player" or ("party" .. (i - 1))
		if group_members >= i then
			self:UpdateUnit(unit)
			self:UpdateUnitState(unit, false)
			self:ShowUnit(unit)

			if not self:IsTesting() and not UnitExists(unit) then
				self:SoftHideUnit(unit)
			end

			-- test environment
			if self:IsTesting(unit) then
				self:TestUnit(unit)
			else
				self:RefreshUnit(unit)
			end
		else
			self:HideUnit(unit)
		end
	end
	if self.db.base.hideSelf then
		self:HideUnit("player")
	end

	self:UpdateBackground("party")
end

function GladiusEx:UpdateArenaFrames()
	if InCombatLockdown() then
		self:QueueUpdate()
		return
	end

	local numOpps = self.arena_size

	log("UpdateArenaFrames:", numOpps, GetNumArenaOpponents(), GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0)

	self:UpdateAnchor("arena")

	for i = 1, 5 do
		local unit = "arena" .. i
		if numOpps >= i then
			self:UpdateUnit(unit)
			self:UpdateUnitState(unit, self.buttons[unit].unit_state == STATE_STEALTH)
			self:ShowUnit(unit)

			-- test environment
			if self:IsTesting(unit) then
				self:TestUnit(unit)
			else
				self:RefreshUnit(unit)
			end
		else
			self:HideUnit(unit)
		end
	end

	self:UpdateBackground("arena")
end

function GladiusEx:UpdateFrames()
	log("UpdateFrames")

	if not self:IsPartyShown() and not self:IsArenaShown() then return end

	if not self.arena_size then
		self:CheckArenaSize()
		return -- CheckArenaSize will call us back
	end

	self:UpdatePartyFrames()
	self:UpdateArenaFrames()

	if not InCombatLockdown() then
		self:ClearUpdateQueue()
	end
end

function GladiusEx:CheckArenaSize(unit)
	local min_size = 0
	if unit then
		min_size = self:GetUnitIndex(unit)
	end

	local size = self:GetArenaSize(min_size)

	log("CheckArenaSize", unit, unit and UnitName(unit) or "none", min_size, size)

	if self.arena_size ~= size then
		log("Arena size change detected", self.arena_size, " => ", size)
		self.arena_size = size
		self:UpdateFrames()
		return true
	end
end

function GladiusEx:ShowFrames()
	if InCombatLockdown() then
		self:QueueUpdate()
	end

	local function show_anchor(anchor_type)
		if self.db[anchor_type].groupButtons then
			local anchor, background = self:GetAnchorFrames(anchor_type)
			background:Show()

			if not self.db.base.locked then
				anchor:Show()
			end
		end
	end

	if self.db.base.showArena then
		show_anchor("arena")
		self.arena_parent:Show()
	end

	if self.db.base.showParty then
		show_anchor("party")
		self.party_parent:Show()
	end

	local updated = self:CheckArenaSize()
	if not updated then
		-- refresh buttons
		for unit in pairs(self.buttons) do
			self:RefreshUnit(unit)
		end
	end
end

function GladiusEx:HideFrames()
	if InCombatLockdown() then
		self:QueueUpdate()
	end

	-- hide frames instead of just setting alpha to 0
	for unit, button in pairs(self.buttons) do
		-- reset spec data
		button.class = nil
		button.specID = nil
		button.unit_state = nil
		button.covenant = nil

		-- hide frame
		self:HideUnit(unit)
	end

	self.arena_parent:Hide()
	self.party_parent:Hide()
	self.arena_size = 0
end

function GladiusEx:IsPartyShown()
	return self.party_parent:IsShown()
end

function GladiusEx:IsArenaShown()
	return self.arena_parent:IsShown()
end

function GladiusEx:PLAYER_ENTERING_WORLD()
	local instanceType = select(2, IsInInstance())

	-- check if we are entering or leaving an arena
	if instanceType == "arena" then
		self:SetTesting(false)
		-- self:ShowFrames()
		self:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
		log("ENABLE LOGGING")
	else
		self:CheckFirstRun()

		if not self:IsTesting() then
			self:HideFrames()
		end
		if logging then log("DISABLE LOGGING") end
	end
end

function GladiusEx:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
    if InCombatLockdown() then
        return -- Combat doesnt end immediately when solo shuffle round ends so this would trigger a lua error if ran on the first events.
    end
    self:CheckArenaSize()
    self:ShowFrames()

    local numOpps = GladiusEx.Data.CountArenaOpponents()
    for i = 1, numOpps do
        local specID = GladiusEx.Data.GetArenaOpponentSpec(i)
        local unitid = "arena" .. i

        if (not GladiusEx.IS_PRE_MOP and specID and specID > 0) or GladiusEx.IS_PRE_MOP then
            self:ShowUnit(unitid)
            self:UpdateUnit(unitid)

            -- update spec after UpdateUnit so that it can (maybe) create button
            self:UpdateUnitSpecialization(unitid, specID)
            self:UpdateUnitState(unitid, true)
            self:RefreshUnit(unitid)
        end
    end
    self:UpdateFrames()
end

function GladiusEx:UpdateUnitSpecialization(unit, specID)
    if not self.buttons[unit] then
        return
    end

    if not specID or specID < 1 then
        return
    end

    local _, _, _, _, _, class = GladiusEx.Data.GetSpecializationInfoByID(specID)

    specID = (specID and specID > 0) and specID or nil

    if self.buttons[unit].specID ~= specID then
        self.buttons[unit].class = class
        self.buttons[unit].specID = specID

        -- TODO safer to reset covenant?
        self:SendMessage("GLADIUS_SPEC_UPDATE", unit)
    end
end

function GladiusEx:CheckOpponentSpecialization(unit)
    local id = strmatch(unit, "^arena(%d+)$")
    if id then
        local specID = GladiusEx.Data.GetArenaOpponentSpec(tonumber(id))

        if not specID and GladiusEx.IS_CLASSIC then
			
			-- K: TBC healer / hybrid mana pools are too similar to use this method
			if not GladiusEx.IS_TBCC then
				specID = self:FindSpecByPower(unit)
			end
			
			if not specID then
				specID = self:FindSpecByAuras(unit)
			end
        end

        self:UpdateUnitSpecialization(unit, specID)
    end
end

function GladiusEx:FindSpecByPower(unit)
	local _, class = UnitClass(unit)
	local specID
	if class then
		local mana = UnitPowerMax(unit, 0)
		local limit = GladiusEx.Data.SpecManaLimit
		if mana then
			if class == "PALADIN" and mana > limit then
				specID = 65 -- Holy
			elseif class == "DRUID" and mana < limit then
				specID = 103 -- Feral
			elseif class == "SHAMAN" and mana < limit then
				specID = 263 -- Enhancement
			end
		end
	end
	
	return specID
end

function GladiusEx:FindSpecByAuras(unit)
    local i = 1
    while true do
        local n, _, _, _, _, _, unitCaster, _, _, spellID = GladiusEx.UnitAura(unit, i, "HELPFUL")
        if not n then
            break
        end
        if unitCaster ~= nil then
            local unitPet = string.gsub(unit, "pet", "")
            unitPet = unitPet == "" and "player" or unitPet
            if UnitIsUnit(unitPet, unitCaster) then
                local specID = GladiusEx.Data.SpecBuffs[spellID]
                if specID then
                    return specID
                end
            end
        end
        i = i + 1
    end
end

function GladiusEx:FindSpecBySpell(unit, spellID, spellName)
    return GladiusEx.Data.SpecSpells[spellID] or GladiusEx.Data.SpecSpells[spellName]
end

function GladiusEx:UNIT_AURA(event, unit)
    if not self.buttons[unit] or self.buttons[unit].specID then
        return
    end
    local specID = self:FindSpecByAuras(unit)
    if not specID then
        return
    end
    self:UpdateUnitSpecialization(unit, specID)
end

function GladiusEx:UNIT_SPELLCAST_START(event, unit)
    if not self.buttons[unit] or self.buttons[unit].specID then
        return
    end
    local spellName, _, _, _, _, _, _, _, spellID = UnitCastingInfo(unit)
    local specID = self:FindSpecBySpell(unit, spellID, spellName)
    if not specID then
        return
    end
    self:UpdateUnitSpecialization(unit, specID)
end

function GladiusEx:UNIT_SPELLCAST_CHANNEL_START(event, unit)
    if not self.buttons[unit] or self.buttons[unit].specID then
        return
    end
    local spellName, _, _, _, _, _, _, _, spellID = UnitChannelInfo(unit)
    local specID = self:FindSpecBySpell(unit, spellID, spellName)
    if not specID then
        return
    end
    self:UpdateUnitSpecialization(unit, specID)
end

function GladiusEx:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID)
    if not self.buttons[unit] or self.buttons[unit].specID then
        return
    end
    local specID = self:FindSpecBySpell(unit, spellID)
    if not specID then
        return
    end
    self:UpdateUnitSpecialization(unit, specID)
end

function GladiusEx:ARENA_OPPONENT_UPDATE(event, unit, type)
	log("ARENA_OPPONENT_UPDATE", unit, type)
	-- ignore pets
	if not self:IsArenaUnit(unit) then return end

	if type == "seen" then
		self:ShowUnit(unit)
		self:CheckOpponentSpecialization(unit)
		self:UpdateUnitState(unit, false)
		self:CheckArenaSize(unit)
	elseif type == "unseen" or type == "destroyed" then
		self:UpdateUnitState(unit, true)
	elseif type == "cleared" then
		if not self:IsTesting() then
			self:SoftHideUnit(unit)
		end
	end
	self:RefreshUnit(unit)
end

function GladiusEx:GROUP_ROSTER_UPDATE()
	if self:IsArenaShown() or self:IsPartyShown() then
		self:UpdateAllGUIDs()
		local u = self:CheckArenaSize()
		if not u and self:IsPartyShown() then
			self:UpdatePartyFrames()
		end
	end
end

function GladiusEx:QueueUpdate()
	self.update_pending = true
	log("Update Queued")
end

function GladiusEx:IsUpdatePending()
	return self.update_pending
end

function GladiusEx:ClearUpdateQueue()
	self.update_pending = false
end

function GladiusEx:PLAYER_REGEN_ENABLED()
	if self:IsUpdatePending() then
		self:UpdateFrames()
	end
end

function GladiusEx:UNIT_NAME_UPDATE(event, unit)
	if not self:IsHandledUnit(unit) then return end

	self:UpdateUnitGUID(event, unit)
	self:CheckArenaSize(unit)
	self:UpdateUnitState(unit)
	self:RefreshUnit(unit)
end

local guid_to_unitid = {}

function GladiusEx:GetUnitIdByGUID(guid)
	return guid_to_unitid[guid]
end

function GladiusEx:UpdateAllGUIDs()
	for unit in pairs(party_units) do self:UpdateUnitGUID("UpdateAllGUIDs", unit) end
	for unit in pairs(arena_units) do self:UpdateUnitGUID("UpdateAllGUIDs", unit) end
end

function GladiusEx:UpdateUnitGUID(event, unit)
	if self:IsHandledUnit(unit) then
		-- find and delete old reference to that unit
		for guid, unitid in pairs(guid_to_unitid) do
			if unitid == unit then
				guid_to_unitid[guid] = nil
				break
			end
		end
		-- add guid
		local guid = UnitGUID(unit)
		if guid then
			guid_to_unitid[guid] = unit
		end
	end
end

function GladiusEx:UNIT_HEALTH(event, unit)
	if not self.buttons[unit] then return end

	self:UpdateUnitState(unit, false)
end

local range_check
function GladiusEx:UpdateRangeCheckers()
	range_check = RC:GetSmartMinChecker(40)
end


local function FrameRangeChecker_OnUpdate(f, elapsed)
	f.elapsed = f.elapsed + elapsed

	if f.elapsed >= RANGE_UPDATE_INTERVAL then
		f.elapsed = 0
		local unit = f.unit

		if GladiusEx:IsTesting(unit) then
			f:SetAlpha(1)
		end

		if not UnitExists(unit) then
			-- should probably remove the OnUpdate handler here
			return
		end

		if range_check(unit) then
			f:SetAlpha(1)
		else
			f:SetAlpha(GladiusEx.db[unit].oorAlpha)
		end
	end
end

function GladiusEx:UpdateUnitState(unit, stealth)
	if not self.buttons[unit] then return end

	if UnitIsDeadOrGhost(unit) then
		self.buttons[unit].unit_state = STATE_DEAD
		self.buttons[unit]:SetScript("OnUpdate", nil)
		self.buttons[unit]:SetAlpha(self.db[unit].deadAlpha)
	elseif stealth then
		self.buttons[unit].unit_state = STATE_STEALTH
		self.buttons[unit]:SetScript("OnUpdate", nil)
		self.buttons[unit]:SetAlpha(self.db[unit].stealthAlpha)
	else
		self.buttons[unit].unit_state = STATE_NORMAL
		self.buttons[unit]:SetScript("OnUpdate", FrameRangeChecker_OnUpdate)
		FrameRangeChecker_OnUpdate(self.buttons[unit], RANGE_UPDATE_INTERVAL + 1)
	end
end

function GladiusEx:GroupInSpecT_Update(event, guid, unit, info)
	for u, _ in pairs(party_units) do
		if UnitGUID(u) == guid then
			self:UpdateUnitSpecialization(u, info.global_spec_id)
			break
		end
	end
end

function GladiusEx:CheckUnitSpecialization(unit)
    if not LGIST or not LGIST.GetCachedInfo then
        return
    end
    local info = LGIST:GetCachedInfo(UnitGUID(unit))

    if info then
        self:UpdateUnitSpecialization(unit, info.global_spec_id)
    else
        LGIST:Rescan(UnitGUID(unit))
    end
end

function GladiusEx:IsHandledUnit(unit)
	return arena_units[unit] or party_units[unit]
end

function GladiusEx:IsArenaUnit(unit)
	return arena_units[unit]
end

function GladiusEx:IsPartyUnit(unit)
	return party_units[unit]
end

function GladiusEx:TestUnit(unit)
	if not self:IsHandledUnit(unit) then return end

	-- test modules
	for n, m in self:IterateModules() do
		if self:IsModuleEnabled(unit, n) and m.Test then
			m:Test(unit)
		end
	end

	-- lower secure frame in test mode so we can move the frame
	self.buttons[unit]:SetFrameStrata("LOW")
	self.buttons[unit].secure:SetFrameStrata("BACKGROUND")
end

function GladiusEx:RefreshUnit(unit)
	if not self.buttons[unit] or self:IsTesting(unit) then return end

	-- refresh modules
	for n, m in self:IterateModules() do
		if self:IsModuleEnabled(unit, n) and m.Refresh then
			m:Refresh(unit)
		end
	end
end

function GladiusEx:ShowUnit(unit)
	log("ShowUnit", unit)
	if not self.buttons[unit] then return end

	-- show modules
	for n, m in self:IterateModules() do
		if self:IsModuleEnabled(unit, n) and m.Show then
			m:Show(unit)
		end
	end

	-- show button
	self.buttons[unit]:SetAlpha(1)
	if not self.buttons[unit]:IsShown() then
		if not InCombatLockdown() then
			self.buttons[unit]:Show()
		else
			self:QueueUpdate()
			log("ShowUnit: tried to show, but InCombatLockdown")
		end
	end

	-- update spec
	if self:IsPartyUnit(unit) and not self.buttons[unit].specID then
		self:CheckUnitSpecialization(unit)
	end
end

function GladiusEx:SoftHideUnit(unit)
	log("SoftHideUnit", unit)
	if not self.buttons[unit] then return end

	-- hide modules
	for n, m in self:IterateModules() do
		if self:IsModuleEnabled(unit, n) then
			if m.Reset then
				m:Reset(unit)
			end
		end
	end

	-- hide the button
	self.buttons[unit]:SetAlpha(0)
end

function GladiusEx:HideUnit(unit)
	log("HideUnit", unit)
	if not self.buttons[unit] then return end

	self:SoftHideUnit(unit)

	if InCombatLockdown() then
		self:QueueUpdate()
	else
		self.buttons[unit]:Hide()
	end
end

function GladiusEx:CreateUnit(unit)
	local button = CreateFrame("Frame", "GladiusExButtonFrame" .. unit, self:IsArenaUnit(unit) and self.arena_parent or self.party_parent, "BackdropTemplate")
	self.buttons[unit] = button
	button.elapsed = 0
	button.unit = unit

	button:SetClampedToScreen(true)
	button:EnableMouse(true)
	button:SetMovable(true)

	button:RegisterForDrag("LeftButton")

	local drag_anchor_type = self:GetUnitAnchorType(unit)
	local drag_anchor_frame = self:GetUnitAnchor(unit)

	button:SetScript("OnMouseDown", function(f, button)
		if button == "RightButton" then
			self:ShowOptionsDialog()
		end
	end)

	button:SetScript("OnDragStart", function(f)
		if not InCombatLockdown() and not self.db.base.locked then
			local f = self.db[unit].groupButtons and drag_anchor_frame or f
			f:StartMoving()
		end
	end)

	button:SetScript("OnDragStop", function(f)
		local f = self.db[unit].groupButtons and drag_anchor_frame or f
		f:StopMovingOrSizing()

		if self.db[unit].groupButtons then
			self:SaveAnchorPosition(drag_anchor_type)
		else
			local scale = f:GetEffectiveScale()
			self.db[unit].x[unit] = f:GetLeft() * scale
			self.db[unit].y[unit] = f:GetTop() * scale
		end
	end)

	-- hide
	button:SetAlpha(0)
	button:Hide()

	-- secure button
	button.secure = CreateFrame("Button", "GladiusExSecureButton" .. unit, button, "SecureActionButtonTemplate")
	button.secure:SetAllPoints()
	button.secure:SetAttribute("unit", unit)
	button.secure:RegisterForClicks("AnyDown", "AnyUp")
	--this should be managed via the Clicks module
	--button.secure:SetAttribute("*type1", "target")
	--button.secure:SetAttribute("*type2", "focus")

	-- clique support
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[button.secure] = true
end

function GladiusEx:SaveAnchorPosition(anchor_type)
	local anchor = self:GetAnchorFrames(anchor_type)
	local scale = anchor:GetEffectiveScale() or 1
	self.db[anchor_type].x["anchor_" .. anchor_type] = (anchor:GetLeft() or 0) * scale
	self.db[anchor_type].y["anchor_" .. anchor_type] = (anchor:GetTop() or 0) * scale
	-- save all unit positions so that they stay at the same place if the buttons are ungrouped
	for unit, button in pairs(self.buttons) do
		self.db[unit].x[unit] = (button:GetLeft() or 0) * scale
		self.db[unit].y[unit] = (button:GetTop() or 0) * scale
	end
end

function GladiusEx:CreateAnchor(anchor_type)
	-- background
	local background = CreateFrame("Frame", "GladiusExButtonBackground" .. anchor_type, anchor_type == "party" and self.party_parent or self.arena_parent, "BackdropTemplate")
	background:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 8 })
	background:SetFrameStrata("BACKGROUND")

	-- anchor
	local anchor = CreateFrame("Frame", "GladiusExButtonAnchor" .. anchor_type, anchor_type == "party" and self.party_parent or self.arena_parent, "BackdropTemplate")
	anchor:SetScript("OnMouseDown", function(f, button)
		if button == "LeftButton" then
			if IsShiftKeyDown() then
				-- center horizontally
				anchor:ClearAllPoints()
				anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, f:GetBottom())
				self:SaveAnchorPosition(anchor_type)
			elseif IsAltKeyDown() then
				-- center vertically
				anchor:ClearAllPoints()
				anchor:SetPoint("LEFT", UIParent, "LEFT", f:GetLeft(), 0)
				self:SaveAnchorPosition(anchor_type)
			elseif IsControlKeyDown() then
				local other_anchor = self:GetAnchorFrames(anchor_type == "party" and "arena" or "party")
				if self.db[anchor_type].growDirection == "UP" or self.db[anchor_type].growDirection == "DOWN" or self.db[anchor_type].growDirection == "VCENTER" then
					-- set same y as the other anchor
					anchor:ClearAllPoints()
					anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", anchor:GetLeft(), other_anchor:GetTop())
				else
					-- set same x as the other anchor
					anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", other_anchor:GetLeft(), anchor:GetTop())
				end
				self:SaveAnchorPosition(anchor_type)
			end
		elseif button == "RightButton" then
			self:ShowOptionsDialog()
		end
	end)

	anchor:SetScript("OnDragStart", function(f)
		if not InCombatLockdown() and not self.db.base.locked then
			anchor:StartMoving()
		end
	end)

	anchor:SetScript("OnDragStop", function(f)
		anchor:StopMovingOrSizing()
		self:SaveAnchorPosition(anchor_type)
	end)

	anchor.text = anchor:CreateFontString("GladiusExButtonAnchorText", "OVERLAY")
	anchor.text2 = anchor:CreateFontString("GladiusExButtonAnchorText2", "OVERLAY")

	background.background_type = anchor_type
	anchor.anchor_type = anchor_type

	anchor:Hide()
	background:Hide()

	return anchor, background
end

function GladiusEx:GetUnitIndex(unit)
	local unit_index
	if unit == "player" or unit == "playerpet" then
		unit_index = 1
	else
		local utype, n = strmatch(unit, "^(%a+)(%d+)$")
		if utype == "party" or utype == "partypet" then
			unit_index = tonumber(n) + 1
		elseif utype == "arena" or utype == "arenapet" then
			unit_index = tonumber(n)
		else
			assert(false, "Unknown unit " .. tostring(unit))
		end
	end
	return unit_index
end

function GladiusEx:GetUnitAnchorType(unit)
	return self:IsArenaUnit(unit) and "arena" or "party"
end

function GladiusEx:GetUnitAnchor(unit)
	return self:IsArenaUnit(unit) and self.arena_anchor or self.party_anchor
end

function GladiusEx:GetWidgetsBounds(unit)
	local button = self.buttons[unit]

	if button then
		return button.wleft, button.wright, button.wtop, button.wbottom
	end
end

function GladiusEx:UpdateUnitPosition(unit)
	local button = self.buttons[unit]

	local left, right, top, bottom = self:GetWidgetsBounds(unit)

	button:ClearAllPoints()

	if self.db[unit].groupButtons then
		local unit_index = self:GetUnitIndex(unit) - 1
		local num_frames = self.arena_size
		local anchor = self:GetUnitAnchor(unit)
		local frame_width = button.frame_width
		local frame_height = button.frame_height
		local real_width = frame_width + abs(left) + abs(right)
		local real_height = frame_height + abs(top) + abs(bottom)
		local margin_x = (real_width + self.db[unit].margin) * unit_index
		local margin_y = (real_height + self.db[unit].margin) * unit_index

		if self.db[unit].growDirection == "UP" then
			button:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", abs(left), margin_y + abs(bottom))
		elseif self.db[unit].growDirection == "DOWN" then
			button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", abs(left), -margin_y - abs(top))
		elseif self.db[unit].growDirection == "VCENTER" then
			local offset = (real_height * (num_frames - 1) + self.db[unit].margin * (num_frames - 1)) / 2
			button:SetPoint("LEFT", anchor, "LEFT", abs(left), offset - margin_y + abs(bottom) / 2 - abs(top) / 2)
		elseif self.db[unit].growDirection == "LEFT" then
			button:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", -margin_x - abs(right), -abs(top))
		elseif self.db[unit].growDirection == "RIGHT" then
			button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", margin_x + abs(left), -abs(top))
		elseif self.db[unit].growDirection == "HCENTER" then
			local offset = (real_width * (num_frames - 1) + self.db[unit].margin * (num_frames - 1) - abs(left) + abs(right)) / 2
			button:SetPoint("TOP", anchor, "BOTTOM", -offset + margin_x, -abs(top))
		end
	else
		local x, y = self.db[unit].x[unit], self.db[unit].y[unit]
		if x and y then
			local eff = button:GetEffectiveScale()
			button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db[unit].x[unit] / eff, self.db[unit].y[unit] / eff)
		else
			button:SetPoint("CENTER", UIParent, "CENTER")
		end
	end
end

function GladiusEx:GetBarWidth(unit)
	return self:AdjustPositionOffset(self.buttons[unit], self.db[unit].barWidth)
	-- return self.db[unit].barWidth
end

function GladiusEx:GetBarsHeight(unit)
	return self:AdjustPositionOffset(self.buttons[unit], self.db[unit].barsHeight)
	-- return self.db[unit].barsHeight
end

local perfect_scale
function GladiusEx:GetPerfectScale()
	if not perfect_scale then
		perfect_scale = 768 / GetScreenHeight()
	end
	return perfect_scale
end

function GladiusEx:AdjustPixels(frame, size)
	while not frame.GetEffectiveScale do frame = frame:GetParent() end
	local frameScale = frame:GetEffectiveScale()
	local perfectScale = self:GetPerfectScale()
	local size_adjusted = size / (frameScale / perfectScale)
	return size_adjusted
end

function GladiusEx:AdjustPositionOffset(frame, p, pos)
	while not frame.GetEffectiveScale do frame = frame:GetParent() end
	local frameScale = frame:GetEffectiveScale()
	local perfectScale = self:GetPerfectScale()
	local pp = p * frameScale / perfectScale
	local pa = pos and (ceil(pp) - pp) or (pp - floor(pp))
	if pa > 0.5 then pa = pa - 1 end
	return p + pa * perfectScale / frameScale
end

function GladiusEx:AdjustFrameOffset(frame, relative_point)
	local x, y
	local ax, ay

	if strfind(relative_point, "LEFT") then
		x = frame:GetLeft() or 0
		ax = self:AdjustPositionOffset(frame, x, true) - x
	else
		x = frame:GetRight() or 0
		ax = x - self:AdjustPositionOffset(frame, x, false)
	end
	if strfind(relative_point, "TOP") then
		y = frame:GetTop() or 0
		ay = y - self:AdjustPositionOffset(frame, y, false)
	else
		y = frame:GetBottom() or 0
		ay = self:AdjustPositionOffset(frame, y, true) - y
	end

	return ax, ay
end

function GladiusEx:UpdateUnit(unit)
	if not self:IsHandledUnit(unit) then return end

	log("UpdateUnit", unit)

	if InCombatLockdown() then
		self:QueueUpdate()
		return
	end

	-- create
	if not self.buttons[unit] then
		self:CreateUnit(unit)
	end

	local button = self.buttons[unit]
	local backdrop_color = self.db[unit].backdropColor
	button:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 16 })
	button:SetBackdropColor(backdrop_color.r, backdrop_color.g, backdrop_color.b, backdrop_color.a)

	-- the frame needs to be anchored somewhere to be able to compute positions
	button:ClearAllPoints()
	button:SetPoint("CENTER", UIParent, "CENTER")

	local bars_width = self:GetBarWidth(unit)
	local bars_height = self:GetBarsHeight(unit)
	local border_size = self:AdjustPixels(button, self.db[unit].borderSize)
	local mod_margin = self:AdjustPixels(button, self.db[unit].modMargin)

	-- update mods
	local mods = fn.filter(fn.from_iterator(function(n, m) return m end, self:IterateModules()), function(m) return self:IsModuleEnabled(unit, m:GetName()) end)
	local bar_mods = fn.sort(fn.filter(mods, function(m) return m:GetAttachType(unit) == "Bar" end), function(a, b) return a:GetBarOrder(unit) < b:GetBarOrder(unit) end)
	-- get and sort in-frame top to bottom
	local point_order = {
		["TOP"] = 1,
		["LEFT"] = 2,
		["RIGHT"] = 3,
		["BOTTOM"] = 4,
	}
	local inframe_mods = fn.sort(fn.filter(mods, function(m) return m:GetAttachType(unit) == "InFrame" end), function(a, b) return point_order[a:GetAttachPoint(unit)] < point_order[b:GetAttachPoint(unit)] end)
	local widget_mods = fn.filter(mods, function(m) return m:GetAttachType(unit) == "Widget" end)

	-- calculate inframe mods size
	local left, right, top, bottom = 0, 0, 0, 0
	local h_count, v_count = 0, 0
	fn.each(inframe_mods, function(m)
		local point = m:GetAttachPoint(unit)
		local size = m:GetAttachSize(unit)
		if point == "LEFT" then
			left = left + size
			h_count = h_count + 1
		elseif point == "RIGHT" then
			right = right + size
			h_count = h_count + 1
		elseif point == "TOP" then
			top = top + size
			v_count = v_count + 1
		elseif point == "BOTTOM" then
			bottom = bottom + size
			v_count = v_count + 1
		end
	end)

	-- update button size
	local frame_width = bars_width + left + right + border_size * 2 + h_count * mod_margin
	local frame_height = bars_height + top + bottom + border_size * 2 + v_count * mod_margin
	button.frame_width = frame_width
	button.frame_height = frame_height
	button:SetScale(self.db[unit].frameScale)
	button:SetSize(frame_width, frame_height)

	-- update inframe mods
	fn.each(inframe_mods, function(m)
		local point = m:GetAttachPoint(unit)
		local size = m:GetAttachSize(unit)
		m:Update(unit)
		local mf = m.frame[unit]
		mf:ClearAllPoints()
		if point == "LEFT" then
			mf:SetPoint("TOPLEFT", border_size, -top - border_size - (top > 0 and mod_margin or 0))
			mf:SetSize(size, bars_height)
		elseif point == "RIGHT" then
			mf:SetPoint("TOPRIGHT", -border_size, -top - border_size - (top > 0 and mod_margin or 0))
			mf:SetSize(size, bars_height)
		elseif point == "TOP" then
			mf:SetPoint("TOPLEFT", border_size, -border_size)
			mf:SetPoint("TOPRIGHT", -border_size, border_size)
			mf:SetHeight(size)
		elseif point == "BOTTOM" then
			mf:SetPoint("BOTTOMLEFT", border_size, border_size)
			mf:SetPoint("BOTTOMRIGHT", -border_size, border_size)
			mf:SetHeight(size)
		end
	end)

	-- update bars
	local bar_height_diff = fn.reduce(bar_mods, function(r, m) return r + m:GetBarHeight(unit) end, 0)
	local std_bar_height = (bars_height - bar_height_diff - mod_margin * (#bar_mods - 1)) / #bar_mods
	local bar_y = -top - border_size - (top > 0 and mod_margin or 0)
	local bar_x = left + border_size + (left > 0 and mod_margin or 0)
	fn.each(bar_mods, function(m)
		m:Update(unit)
		local mf = m.frame[unit]
		local bar_height = std_bar_height + m:GetBarHeight(unit)
		mf:ClearAllPoints()
		mf:SetPoint("TOPLEFT", button, "TOPLEFT", bar_x, bar_y)
		mf:SetSize(bars_width, bar_height)
		bar_y = bar_y - bar_height - mod_margin
	end)

	-- update widgets
	local wleft, wright, wtop, wbottom = 0, 0, 0, 0
	fn.each(widget_mods, function(m)
		if m.Update then m:Update(unit) end
		-- calculate widget bounds
		local mframes = m:GetFrames(unit)
		if mframes then
			fn.each(mframes, function(mf)
				if mf then
					local mscale = mf:GetScale()
					local mleft = (button:GetLeft() or 0) - (mf:GetLeft() or 0) * mscale
					local mright = (mf:GetRight() or 0) * mscale - (button:GetRight() or 0)
					local mtop = (mf:GetTop() or 0) * mscale - (button:GetTop() or 0)
					local mbottom = (button:GetBottom() or 0) - (mf:GetBottom() or 0) * mscale
					wleft = max(mleft, wleft)
					wright = max(mright, wright)
					wtop = max(mtop, wtop)
					wbottom = max(mbottom, wbottom)
				end
			end)
		end
	end)

	button.wleft = wleft
	button.wright = wright
	button.wtop = wtop
	button.wbottom = wbottom

	-- update position
	self:UpdateUnitPosition(unit)

	-- show the secure frame
	if self:IsTesting() and not self.db.base.locked then
		button.secure:Hide()
	else
		button.secure:Show()
	end

	button:SetFrameStrata("LOW")
	button.secure:SetFrameStrata("MEDIUM")
end

function GladiusEx:GetAnchorFrames(anchor_type)
	local anchor = anchor_type == "party" and self.party_anchor or self.arena_anchor
	local background = anchor_type == "party" and self.party_background or self.arena_background
	return anchor, background
end

function GladiusEx:UpdateAnchor(anchor_type)
	local anchor, background = self:GetAnchorFrames(anchor_type)

	-- anchor
	anchor:ClearAllPoints()
	anchor:SetSize(anchor_width, anchor_height)
	anchor:SetScale(self.db[anchor_type].frameScale)
	if (not self.db[anchor_type].x and not self.db[anchor_type].y) or (not self.db[anchor_type].x["anchor_" .. anchor.anchor_type] and not self.db[anchor_type].y["anchor_" .. anchor.anchor_type]) then
		if anchor.anchor_type == "party" then
			anchor:SetPoint("CENTER", UIParent, "CENTER", -300, 0)
		else
			anchor:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
		end
	else
		local eff = anchor:GetEffectiveScale()
		anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db[anchor_type].x["anchor_" .. anchor.anchor_type] / eff, self.db[anchor_type].y["anchor_" .. anchor.anchor_type] / eff)
	end

	anchor:SetBackdrop({
		edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = self:AdjustPixels(anchor, max(1, floor(self.db[anchor_type].frameScale + 0.5))),
		bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 8,
	})
	anchor:SetBackdropColor(0, 0, 0, 1)
	anchor:SetBackdropBorderColor(1, 1, 1, 1)
	anchor:SetFrameLevel(200)
	anchor:SetFrameStrata("MEDIUM")

	--anchor:SetClampedToScreen(true) -- https://github.com/slaren/GladiusEx/issues/19
	anchor:EnableMouse(true)
	anchor:SetMovable(true)
	anchor:RegisterForDrag("LeftButton")

	-- anchor texts
	anchor.text:SetPoint("TOP", anchor, "TOP", 0, -7)
	anchor.text:SetPoint("LEFT")
	anchor.text:SetPoint("RIGHT")
	anchor.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
	anchor.text:SetTextColor(1, 1, 1, 1)
	anchor.text:SetShadowOffset(1, -1)
	anchor.text:SetShadowColor(0, 0, 0, 1)
	anchor.text:SetText(anchor.anchor_type == "party" and L["GladiusEx Party Anchor - click to move"] or L["GladiusEx Enemy Anchor - click to move"])

	anchor.text2:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 7)
	anchor.text2:SetPoint("LEFT")
	anchor.text2:SetPoint("RIGHT")
	anchor.text2:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
	anchor.text2:SetTextColor(1, 1, 1, 1)
	anchor.text2:SetShadowOffset(1, -1)
	anchor.text2:SetShadowColor(0, 0, 0, 1)
	anchor.text2:SetText(L["Lock the frames to hide"])

	if self.db[anchor_type].groupButtons and not self.db.base.locked then
		anchor:Show()
	else
		anchor:Hide()
	end
end

function GladiusEx:GetOppositeUnit(unit)
	return unit == "player" and "arena1" or "player"
end

function GladiusEx:UpdateBackground(anchor_type)
	local anchor, background = self:GetAnchorFrames(anchor_type)

	-- background
	local unit = background.background_type == "party" and "player" or "arena1"
	local left, right, top, bottom = self:GetWidgetsBounds(unit)
	local frame_width = self.buttons[unit].frame_width
	local frame_height = self.buttons[unit].frame_height

	local num_frames = self.arena_size
	local width, height = self.db[anchor_type].backgroundPadding * 2, self.db[anchor_type].backgroundPadding * 2
	local real_frame_width = frame_width + abs(right) + abs(left)
	local real_frame_height = frame_height + abs(top) + abs(bottom)
	if self.db[anchor_type].growDirection == "UP" or self.db[anchor_type].growDirection == "DOWN" or self.db[anchor_type].growDirection == "VCENTER" then
		width = width + real_frame_width
		height = height + real_frame_height * num_frames + self.db[anchor_type].margin * (num_frames - 1)
	else
		width = width + real_frame_width * num_frames + self.db[anchor_type].margin * (num_frames - 1)
		height = height + real_frame_height
	end

	background:ClearAllPoints()
	background:SetSize(width, height)
	background:SetScale(self.db[anchor_type].frameScale)

	if self.db[anchor_type].growDirection == "UP" then
		background:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -self.db[anchor_type].backgroundPadding, -self.db[anchor_type].backgroundPadding)
	elseif self.db[anchor_type].growDirection == "DOWN" then
		background:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -self.db[anchor_type].backgroundPadding, self.db[anchor_type].backgroundPadding)
	elseif self.db[anchor_type].growDirection == "VCENTER" then
		background:SetPoint("LEFT", anchor, "LEFT", -self.db[anchor_type].backgroundPadding, 0)
	elseif self.db[anchor_type].growDirection == "LEFT" then
		background:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", self.db[anchor_type].backgroundPadding, self.db[anchor_type].backgroundPadding)
	elseif self.db[anchor_type].growDirection == "RIGHT" then
		background:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -self.db[anchor_type].backgroundPadding, self.db[anchor_type].backgroundPadding)
	elseif self.db[anchor_type].growDirection == "HCENTER" then
		background:SetPoint("TOP", anchor, "BOTTOM", 0, self.db[anchor_type].backgroundPadding)
	end

	background:SetBackdropColor(self.db[anchor_type].backgroundColor.r, self.db[anchor_type].backgroundColor.g, self.db[anchor_type].backgroundColor.b, self.db[anchor_type].backgroundColor.a)

	if self.db[anchor_type].groupButtons then
		background:Show()
	else
		background:Hide()
	end
end

-- FontStrings with OUTLINE look blurry, so instead we do our own for the
-- cheap, cheap cost of only 9 times more FontStrings.
-- This returns a FontString-like object that renders the outlines
-- by creating several more FontStrings around the around the one.
function GladiusEx:CreateSuperFS(fsparent, layer)
	if not self.db.base.superFS then
		return fsparent:CreateFontString(nil, layer)
	end

	local superfs = {}

	function superfs:ApplyAll(func, ...)
		for i = 1, #self.fs do
			self.fs[i][func](self.fs[i], ...)
		end
	end

	local function AddWrapperAll(func)
		superfs[func] = fn.bind_nth(superfs.ApplyAll, 2, func)
	end

	local function AddWrapperOne(func)
		superfs[func] = function(self, ...)
			return self.fs[1][func](self.fs[1], ...)
		end
	end

	AddWrapperAll("ClearAllPoints")
	AddWrapperAll("Hide")
	AddWrapperAll("SetFormattedText")
	AddWrapperAll("SetJustifyH")
	AddWrapperAll("SetJustifyV")
	AddWrapperAll("SetShadowColor")
	AddWrapperAll("SetShadowOffset")
	AddWrapperAll("SetAlpha")
	AddWrapperAll("SetText")
	AddWrapperAll("SetTextColor")
	AddWrapperAll("SetWordWrap")
	AddWrapperAll("Show")
	AddWrapperOne("GetFont")

	superfs.fs = {}

	function superfs:SetPoint(point, parent, relative, offsetx, offsety)
		self.fs[1]:SetPoint(point, parent, relative, offsetx or 0, offsety or 0)
		self:UpdatePoints(point, parent, relative, offsetx or 0, offsety or 0)
	end

	function superfs:SetFont(font, size, flags)
		local i = 1
		local w = (flags == "OUTLINE" and 1) or (flags == "THICKOUTLINE" and 2) or 0
		local count = ((w * 2) + 1) ^ 2

		-- create first one last so that it is the last one rendered
		for i = count, 1, -1 do
			if not self.fs[i] then
				self.fs[i] = fsparent:CreateFontString(nil, layer)
			end
			self.fs[i]:SetFont(font, size)
			self.fs[i]:Show()
			i = i + 1
		end

		for i = count + 1, #self.fs do
			self.fs[i]:Hide()
		end

		self.w = w
		self.count = count
	end

	function superfs:UpdatePoints(point, parent, relative, offsetx, offsety)
		local i = 2
		local w = self.w
		local wp = GladiusEx:AdjustPixels(parent, 1)
		local wp_x = wp
		local wp_y = wp
		for x = -w, w do
			for y = -w, w do
				if not (x == 0 and y == 0) then
					self.fs[i]:SetPoint(point, parent, relative, offsetx + wp_x * x, offsety + wp_y * y)
					self.fs[i]:SetTextColor(0, 0, 0, 1)
					i = i + 1
				end
			end
		end
	end

	return superfs
end

-- Returns the spellid if the spell doesn't exist, so that it doesn't break tables
function GladiusEx:SafeGetSpellName(spellid)
	local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellid) or GetSpellInfo(spellid)
	if not name then
		geterrorhandler()("GladiusEx: invalid spellid " .. tostring(spellid))
		return tostring(spellid)
	end
	return name
end

-- Returns whether a castGUID is "empty" (nil, zero, full of zero, etc.)
-- BLIZZBUG: The castGUID here is 0 when you phase in while an unit is already casting.
-- (from Resike/Z-Perl2)
function GladiusEx:IsValidCastGUID(guid)
	return guid ~= nil and guid ~= 0 and guid ~= "0" and guid ~= "0-0-0-0-0-0000000000"
end
