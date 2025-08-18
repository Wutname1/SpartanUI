local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")
local CT = LibStub("LibCooldownTracker-1.0")
local LCG = LibStub("LibCustomGlow-1.0")
local fn = LibStub("LibFunctional-1.0")

-- global functions
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local pairs, ipairs, select, type, unpack, wipe = pairs, ipairs, select, type, unpack, wipe
local min, max, ceil, floor, random = math.min, math.max, math.ceil, math.floor, math.random
local bor, lshift = bit.bor, bit.lshift
local GetTime, UnitExists, UnitFactionGroup, UnitClass, UnitRace = GetTime, UnitExists, UnitFactionGroup, UnitClass, UnitRace
local GetSpellDescription = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription

-- Spells to add to units in test mode
local TESTING_EXTRA_SPELLS = GladiusEx.IS_RETAIL and {336126} or {42292}

local GetDefaultSpells = GladiusEx.Data.DefaultCooldowns

local function MakeGroupDb(settings)
    local defaults = {
        cooldownsAttachTo = "Frame",
        cooldownsAnchor = "TOPLEFT",
        cooldownsRelativePoint = "BOTTOMLEFT",
        cooldownsOffsetX = 0,
        cooldownsOffsetY = 0,
        cooldownsBackground = {r = 0, g = 0, b = 0, a = 0},
        cooldownsGrow = "DOWNRIGHT",
        cooldownsPaddingX = 0,
        cooldownsPaddingY = 0,
        cooldownsSpacingX = 0,
        cooldownsSpacingY = 0,
        cooldownsPerColumn = 10,
        cooldownsMax = 10,
        cooldownsSize = 20,
        cooldownsCrop = true,
        cooldownsDetached = false,
        cooldownsLocked = false,
        cooldownsGroupByUnit = false,
        cooldownsTooltips = true,
        cooldownsSpells = {},
        cooldownsBorderSize = 1,
        cooldownsBorderAvailAlpha = 1,
        cooldownsBorderUsingAlpha = 1,
        cooldownsBorderCooldownAlpha = 0.2,
        cooldownsIconAvailAlpha = 1,
        cooldownsIconUsingAlpha = 1,
        cooldownsIconCooldownAlpha = 0.2,
        cooldownsCatPriority = {
            "pvp_trinket",
            "dispel",
            "mass_dispel",
            "immune",
            "interrupt",
            "silence",
            "stun",
            "knockback",
            "cc",
            "offensive",
            "defensive",
            "heal",
            "uncat"
        },
        cooldownsCatColors = {
            ["pvp_trinket"] = {r = 0, g = 0, b = 0},
            ["dispel"] = {r = 1, g = 1, b = 1},
            ["mass_dispel"] = {r = 1, g = 1, b = 1},
            ["immune"] = {r = 0, g = 0, b = 1},
            ["interrupt"] = {r = 1, g = 0, b = 1},
            ["silence"] = {r = 1, g = 0, b = 1},
            ["stun"] = {r = 0, g = 1, b = 1},
            ["knockback"] = {r = 0, g = 1, b = 1},
            ["cc"] = {r = 0, g = 1, b = 1},
            ["offensive"] = {r = 1, g = 0, b = 0},
            ["defensive"] = {r = 0, g = 1, b = 0},
            ["heal"] = {r = 0, g = 1, b = 0},
            ["uncat"] = {r = 1, g = 1, b = 1}
        },
        cooldownsHideTalentsUntilDetected = true,
        cooldownsOffCdScale = 1.5,
        cooldownsOffCdDuration = 0.3,
        cooldownsOnUseScale = 1.5,
        cooldownsOnUseDuration = 0.3,
        cooldownsEnableGlow = true,
        cooldownsShowDuration = true,
        cooldownsTrinketIcon = GladiusEx.IS_RETAIL and "gladiator" or "faction",
    }
    return fn.merge(defaults, settings or {})
end

local defaults = {
    num_groups = 2,
    group_table = {
        [1] = "group_1",
        [2] = "group_2"
    }
}

local g1_defaults =
    MakeGroupDb {
    cooldownsGroupId = 1,
    cooldownsBorderSize = 0,
    cooldownsPaddingX = 0,
    cooldownsPaddingY = 2,
    cooldownsSpacingX = 2,
    cooldownsSpacingY = 0,
    cooldownsSpells = GetDefaultSpells()[1]
}

local g2_defaults =
    MakeGroupDb {
    cooldownsGroupId = 2,
    cooldownsPerColumn = 2,
    cooldownsMax = 2,
    cooldownsSize = 42,
    cooldownsCrop = true,
    cooldownsTooltips = false,
    cooldownsBorderSize = 1,
    cooldownsBorderAvailAlpha = 1.0,
    cooldownsBorderUsingAlpha = 1.0,
    cooldownsBorderCooldownAlpha = 1.0,
    cooldownsIconAvailAlpha = 1.0,
    cooldownsIconUsingAlpha = 1.0,
    cooldownsIconCooldownAlpha = 1.0,
    cooldownsSpells = GetDefaultSpells()[2],
}

local Cooldowns =
    GladiusEx:NewGladiusExModule(
    "Cooldowns",
    fn.merge(
        defaults,
        {
            groups = {
                ["group_1"] = fn.merge(
                    g1_defaults,
                    {
                        cooldownsAttachTo = "Frame",
                        cooldownsAnchor = "TOPLEFT",
                        cooldownsRelativePoint = "BOTTOMLEFT",
                        cooldownsGrow = "DOWNRIGHT",
                        cooldownsOffsetY = -25
                    }
                ),
                ["group_2"] = fn.merge(
                    g2_defaults,
                    {
                        cooldownsAttachTo = "Frame",
                        cooldownsAnchor = "TOPLEFT",
                        cooldownsRelativePoint = "TOPRIGHT",
                        cooldownsGrow = "DOWNRIGHT",
                        cooldownsOffsetX = 5
                    }
                )
            }
        }
    ),
    fn.merge(
        defaults,
        {
            groups = {
                ["group_1"] = fn.merge(
                    g1_defaults,
                    {
                        cooldownsAttachTo = "Frame",
                        cooldownsAnchor = "TOPRIGHT",
                        cooldownsRelativePoint = "BOTTOMRIGHT",
                        cooldownsGrow = "DOWNLEFT"
                    }
                ),
                ["group_2"] = fn.merge(
                    g2_defaults,
                    {
                        cooldownsAttachTo = "Frame",
                        cooldownsAnchor = "TOPRIGHT",
                        cooldownsRelativePoint = "TOPLEFT",
                        cooldownsGrow = "DOWNLEFT"
                    }
                )
            }
        }
    )
)

local MAX_ICONS = 40

local unit_state = {}
function Cooldowns:GetGroupState(unit, group)
    local gu = unit_state[unit]
    if not gu then
        gu = {}
        unit_state[unit] = gu
    end

    local gs = gu[group]
    if not gs then
        gs = {}
        gu[group] = gs
    end
    return gs
end

function Cooldowns:MakeGroupId()
    -- not ideal, but should be good enough for its purpose
    return random(2 ^ 31 - 1)
end

function Cooldowns:GetNumGroups(unit)
    return self.db[unit].num_groups
end

function Cooldowns:GetGroupDB(unit, group)
    local k = self.db[unit].group_table[group]
    return self.db[unit].groups[k]
end

function Cooldowns:GetGroupById(unit, gid)
    for group = 1, self:GetNumGroups(unit) do
        local gdb = self:GetGroupDB(unit, group)
        if gdb.cooldownsGroupId == gid then
            return gdb, group
        end
    end
end

function Cooldowns:AddGroup(unit, groupdb)
    local group = self:GetNumGroups(unit) + 1
    self.db[unit].num_groups = group
    self.db[unit].groups["group_" .. groupdb.cooldownsGroupId] = groupdb
    self.db[unit].group_table[group] = "group_" .. groupdb.cooldownsGroupId
    return self:GetNumGroups(unit)
end

function Cooldowns:RemoveGroup(unit, group)
    local groupdb = self:GetGroupDB(unit, group)
    self.db[unit].num_groups = self:GetNumGroups(unit) - 1
    tremove(self.db[unit].group_table, group)
    self.db[unit].groups["group_" .. groupdb.cooldownsGroupId] = nil
end

local header_units = {["player"] = true, ["arena1"] = true}
local function IsHeaderUnit(unit)
    return header_units[unit]
end

local function GetHeaderUnit(unit)
    return GladiusEx:IsPartyUnit(unit) and "player" or "arena1"
end

function Cooldowns:OnEnable()
    CT.RegisterCallback(self, "LCT_CooldownUsed")
    CT.RegisterCallback(self, "LCT_CooldownsReset")
    CT.RegisterCallback(self, "LCT_CooldownDetected")
    CT.RegisterCallback(self, "LCT_CovenantDetected")
    self:RegisterEvent("UNIT_NAME_UPDATE")
    self:RegisterMessage("GLADIUS_SPEC_UPDATE")
end

function Cooldowns:OnDisable()
    for unit in pairs(unit_state) do
        self:Reset(unit)
    end

    CT.UnregisterAllCallbacks(self)
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
end

function Cooldowns:GetFrames(unit)
    local frames = {}
    for group = 1, self:GetNumGroups(unit) do
        local db = self:GetGroupDB(unit, group)
        if not db.cooldownsDetached then
            tinsert(frames, self:GetGroupState(unit, group).frame)
        end
    end
    return frames
end

function Cooldowns:OnProfileChanged()
    self.super.OnProfileChanged(self)
    self:SpellSortingChanged()
end

function Cooldowns:GetModuleAttachPoints(unit)
    local t = {}
    for group = 1, self:GetNumGroups(unit) do
        local db = self:GetGroupDB(unit, group)
        if not db.cooldownsDetached then
            t["Cooldowns_" .. db.cooldownsGroupId] =
                string.format(L["Cooldowns group %s"], db.name and '"' .. db.name .. '"' or group)
        end
    end
    return t
end

function Cooldowns:GetModuleAttachFrame(unit, point)
    local gid = string.match(point, "^Cooldowns_(%d+)$")
    if not gid then
        return nil
    end

    local group, gidx = self:GetGroupById(unit, tonumber(gid))
    if not group then
        return nil
    end

    -- self:CreateGroupFrame(unit, group)

    return self:GetGroupState(unit, gidx).frame
end

function Cooldowns:UNIT_NAME_UPDATE(event, unit)
    -- hopefully at this point the opponent's faction is known
    if GladiusEx:IsHandledUnit(unit) then
        self:UpdateIcons(unit)
    end
end

function Cooldowns:GLADIUS_SPEC_UPDATE(event, unit)
    self:UpdateIcons(unit)
end

function Cooldowns:LCT_CooldownsReset(event, unit)
    self:UpdateIcons(unit)
end

function Cooldowns:LCT_CooldownUsed(event, unit, spellid)
    self:UpdateIcons(unit)
end

function Cooldowns:LCT_CooldownDetected(event, unit, spellid)
    self:UpdateIcons(unit)
end

function Cooldowns:LCT_CovenantDetected(event, unit, covenant)
    if GladiusEx:IsHandledUnit(unit) then
        GladiusEx.buttons[unit].covenant = covenant
        self:UpdateIcons(unit)
    end
end

local function CooldownFrame_Pulse(frame, duration, scale)
    if OmniCC then
        OmniCC.FX:Run(frame, "pulse")
        return
    end

    local ag = frame.icon_frame:CreateAnimationGroup()

    local cdAnim = ag:CreateAnimation("Scale")
    cdAnim:SetScale(scale, scale)
    cdAnim:SetDuration(duration)
    cdAnim:SetSmoothing("IN")

    local texture = frame.icon_frame:CreateTexture()
    texture:SetTexture([[Interface/Cooldown/star4]])
    texture:SetAlpha(0)
    texture:SetAllPoints()
    texture:SetBlendMode("ADD")

    local sfAg = texture:CreateAnimationGroup()

    local alpha1 = sfAg:CreateAnimation("Alpha")
    alpha1:SetFromAlpha(0)
    alpha1:SetToAlpha(1)
    alpha1:SetDuration(0)
    alpha1:SetOrder(1)

    local scale1 = sfAg:CreateAnimation("Scale")
    scale1:SetScale(1.5, 1.5)
    scale1:SetDuration(0)
    scale1:SetOrder(1)

    local scale2 = sfAg:CreateAnimation("Scale")
    scale2:SetScale(0, 0)
    scale2:SetDuration(duration)
    scale2:SetOrder(2)

    local rotation2 = sfAg:CreateAnimation("Rotation")
    rotation2:SetDegrees(90)
    rotation2:SetDuration(duration)
    rotation2:SetOrder(2)

    ag:Play()
    sfAg:Play()
end

local function CooldownFrame_OnUpdate(frame)
    local tracked = frame.tracked
    local now = GetTime()
    local db = Cooldowns:GetGroupDB(frame.unit, frame.group)

    if tracked and (not tracked.charges_detected or not tracked.charges or tracked.charges <= 0) then
        if
            tracked.used_start and
                ((not tracked.used_end and not tracked.cooldown_start) or (tracked.used_end and tracked.used_end > now))
         then
            -- using
            if frame.state == 0 then
                if tracked.used_end then
                    if db.cooldownsEnableGlow then
                        LCG.ButtonGlow_Start(frame)
                    end
                    frame.cooldown:SetReverse(true)
                    frame.cooldown:Show()
                    if db.cooldownsShowDuration then
                        CooldownFrame_Set(frame.cooldown, tracked.used_start, tracked.used_end - tracked.used_start, 1)
                    else
                        CooldownFrame_Set(
                            frame.cooldown,
                            tracked.cooldown_start,
                            tracked.cooldown_end - tracked.cooldown_start,
                            1
                        )
                    end

                    -- Just got used CD: pulse to show usage
                    -- We somehow end up in that piece of code often, so for the whole duration of the effect,
                    -- tag a boolean.
                    if not frame.pulsing then
                        frame.pulsing = true
                        CooldownFrame_Pulse(frame, db.cooldownsOnUseDuration, db.cooldownsOnUseScale)
                    end
                else
                    frame.cooldown:Hide()
                end
                local a = db.cooldownsIconUsingAlpha
                local ab = db.cooldownsBorderUsingAlpha
                frame:SetBackdropBorderColor(frame.color.r, frame.color.g, frame.color.b, ab)
                frame.icon_frame:SetAlpha(a)
                frame.state = 1
            end
            return
        end

        if tracked.used_start and not tracked.cooldown_start and frame.spelldata.active_until_cooldown_start then
            -- waiting to be used (cold blood)
            if frame.state ~= 2 then
                local a = db.cooldownsIconUsingAlpha
                local ab = db.cooldownsBorderUsingAlpha
                frame:SetBackdropBorderColor(frame.color.r, frame.color.g, frame.color.b, ab)
                frame.icon_frame:SetAlpha(a)
                frame.cooldown:Hide()
                frame.state = 2
            end
            return
        end

        if tracked.cooldown_end and tracked.cooldown_end > now then
            -- in cooldown
            if frame.state ~= 3 then
                frame.cooldown:SetReverse(false)
                CooldownFrame_Set(
                    frame.cooldown,
                    tracked.cooldown_start,
                    tracked.cooldown_end - tracked.cooldown_start,
                    1
                )
                local a = db.cooldownsIconCooldownAlpha
                local ab = db.cooldownsBorderCooldownAlpha
                frame:SetBackdropBorderColor(frame.color.r, frame.color.g, frame.color.b, ab)
                frame.icon_frame:SetAlpha(a)
                frame.cooldown:Show()
                frame.state = 3
                frame.pulsing = false
                LCG.ButtonGlow_Stop(frame)
            end
            return
        end

        if frame.state == 3 and db.cooldownsOffCdScale and db.cooldownsOffCdScale ~= 1 then -- was on CD
            LCG.ButtonGlow_Stop(frame)
            -- Just got off CD: pulse to show CD is over
            CooldownFrame_Pulse(frame, db.cooldownsOffCdDuration, db.cooldownsOffCdScale)
        end
    end

    -- not on cooldown or being used
    LCG.ButtonGlow_Stop(frame)
    if
        frame.tracked and frame.tracked.charges_detected and frame.tracked.charges and frame.tracked.max_charges and
            frame.tracked.charges < frame.tracked.max_charges
     then
        -- show the charge cooldown
        frame.cooldown:SetReverse(false)
        CooldownFrame_Set(
            frame.cooldown,
            tracked.cooldown_start,
            tracked.cooldown_end - tracked.cooldown_start,
            1,
            frame.tracked.charges,
            frame.tracked.max_charges
        )
        frame.cooldown:Show()
    else
        CooldownFrame_Set(frame.cooldown, 0, 0, 0)
    end
    local a = Cooldowns:GetGroupDB(frame.unit, frame.group).cooldownsIconAvailAlpha
    local ab = Cooldowns:GetGroupDB(frame.unit, frame.group).cooldownsBorderAvailAlpha
    frame:SetBackdropBorderColor(frame.color.r, frame.color.g, frame.color.b, ab)
    frame.icon_frame:SetAlpha(a)
    frame:SetScript("OnUpdate", nil)
    frame.tracked = nil
end

local unit_sortscore = {}
function Cooldowns:SpellSortingChanged()
    -- remove cached sorting info from spells
    unit_sortscore = {}
end

local function GetSpellSortScore(unit, group, spellid)
    local db = Cooldowns:GetGroupDB(unit, group)

    local group_sortscore = unit_sortscore[unit]
    if not group_sortscore then
        group_sortscore = {}
        unit_sortscore[unit] = group_sortscore
    end

    local sortscore = group_sortscore[group]
    if not sortscore then
        sortscore = {}
        group_sortscore[group] = sortscore
    end

    local spelldata = CT:GetCooldownData(spellid)
    if not spelldata then
        return 0
    end

    if spelldata.replaces then
        spellid = spelldata.replaces
        spelldata = CT:GetCooldownData(spelldata.replaces)
    end
    if not spelldata then
        return 0
    end

    if sortscore[spellid] then
        return sortscore[spellid]
    end

    local cat_priority = db.cooldownsCatPriority

    local score = 0
    local value = 2 ^ 30
    local uncat_score = 0

    for i = 1, #cat_priority do
        local key = cat_priority[i]
        if key == "uncat" then
            uncat_score = value
        end
        if spelldata[key] then
            score = score + value
        end
        value = value / 2
    end
    if score == 0 then
        score = uncat_score
    end

    -- use the decimal part to sort by name. will probably fail in some locales.
    local len = min(4, spelldata.name:len())
    local max = 256 ^ len
    local sum = 0
    for i = 1, len do
        sum = bor(lshift(sum, 8), spelldata.name:byte(i))
    end
    score = score + (max - sum) / max

    sortscore[spellid] = score

    return score
end

function Cooldowns:UpdateIcons(unit)
    for group = 1, self:GetNumGroups(unit) do
        self:UpdateGroupIcons(unit, group)
    end
end

local function GetUnitInfo(unit)
    local specID, class, race, covenant
    if GladiusEx:IsTesting(unit) then
        specID = GladiusEx.testing[unit].specID
        class = GladiusEx.testing[unit].unitClass
        race = GladiusEx.testing[unit].unitRace
        covenant = GladiusEx.testing[unit].covenant
    elseif GladiusEx.buttons[unit] then
        specID = GladiusEx.buttons[unit].specID
        class = GladiusEx.buttons[unit].class or select(2, UnitClass(unit))
        race = select(2, UnitRace(unit))
        covenant = GladiusEx.buttons[unit].covenant
    end
    return specID, class, race, covenant
end

local function GetUnitFaction(unit)
    if GladiusEx:IsTesting(unit) then
        return (UnitFactionGroup("player") == "Alliance" and GladiusEx:IsPartyUnit(unit)) and "Alliance" or "Horde"
    else
        return UnitFactionGroup(unit)
    end
end

local spell_list = {}
local unit_sorted_spells = {}
local function GetCooldownList(unit, group)
    local db = Cooldowns:GetGroupDB(unit, group)

    local specID, class, race, covenant = GetUnitInfo(unit)

    -- generate list of valid cooldowns for this unit
    wipe(spell_list)
    for spellid, spelldata in CT:IterateCooldowns(class, specID, race, covenant) do
        -- check if the spell is enabled by the user
        if db.cooldownsSpells[spellid] or (spelldata.replaces and db.cooldownsSpells[spelldata.replaces]) then
            local tracked = CT:GetUnitCooldownInfo(unit, spellid)
            local detected = tracked and tracked.detected
            -- check if the spell has a cooldown valid for an arena, and check if it is a talent that has not yet been detected
            if
                (not spelldata.cooldown or spelldata.cooldown < 600) and
                    -- Do NOT show all covenant spells if HideTalentsUntilDetected is false
                    (not (spelldata.talent or spelldata.item or spelldata.pvp_trinket or spelldata.pet) or detected or
                        not db.cooldownsHideTalentsUntilDetected)
             then
                -- check if the spell requires an aura (XXX unused atm?)
                if not spelldata.requires_aura or AuraUtil.FindAuraByName(spelldata.requires_aura_name, unit, "HELPFUL") then
                    if spelldata.replaces then
                        -- remove replaced spell if detected
                        spell_list[spelldata.replaces] = false
                    end
                    -- do not overwrite if this spell has been replaced
                    if spell_list[spellid] == nil then
                        spell_list[spellid] = true
                    end
                end
            end
        end
    end

    -- add a trinket if we're in testing mode
    if GladiusEx:IsTesting(unit) then
        for i = 1, #TESTING_EXTRA_SPELLS do
            if db.cooldownsSpells[TESTING_EXTRA_SPELLS[i]] then
                spell_list[TESTING_EXTRA_SPELLS[i]] = true
            end
        end
    end

    -- sort spells
    unit_sorted_spells[unit] = unit_sorted_spells[unit] or {}
    unit_sorted_spells[unit][group] = unit_sorted_spells[unit][group] or {}
    local sorted_spells = unit_sorted_spells[unit][group]
    wipe(sorted_spells)
    for spellid, valid in pairs(spell_list) do
        if valid then
            tinsert(sorted_spells, spellid)
        end
    end

    tsort(
        sorted_spells,
        function(a, b)
            return GetSpellSortScore(unit, group, a) > GetSpellSortScore(unit, group, b)
        end
    )

    return sorted_spells
end

local function GetPvPTrinketIcon(unit, db)
    local selected = db.cooldownsTrinketIcon or (GladiusEx.IS_RETAIL and "gladiator" or "faction")
    local faction = UnitFactionGroup(unit) or "Alliance" -- default if unknown
    local data = CT:GetCooldownData(GladiusEx.IS_RETAIL and 336126 or 42292)

    if selected == "gladiator" and GladiusEx.IS_RETAIL then
        return data.icon_gladiator
    elseif selected == "faction" then
        return faction == "Horde" and data.icon_horde or data.icon_alliance
    elseif selected == "faction_wotlk" then
        return faction == "Horde" and data.icon_horde_wotlk or data.icon_alliance_wotlk
    elseif selected == "horde" then
        return data.icon_horde
    elseif selected == "alliance" then
        return data.icon_alliance
    elseif selected == "horde_wotlk" then
        return data.icon_horde_wotlk
    elseif selected == "alliance_wotlk" then
        return data.icon_alliance_wotlk
    end

    -- fallback to "faction" style
    return GladiusEx.IS_RETAIL and data.icon_gladiator or (faction == "Horde" and data.icon_horde or data.icon_alliance)
end

local function UpdateGroupIconFrames(unit, group, sorted_spells)

    local gs = Cooldowns:GetGroupState(unit, group)
    local db = Cooldowns:GetGroupDB(unit, group)

    local cat_priority = db.cooldownsCatPriority
    local border_colors = db.cooldownsCatColors
    local cooldownsPerColumn = db.cooldownsPerColumn

    local sidx = 1
    local shown = 0
    for i = 1, #sorted_spells do
        local icon_unit = type(sorted_spells[i]) == "table" and sorted_spells[i][1] or unit
        local spellid = type(sorted_spells[i]) == "table" and sorted_spells[i][2] or sorted_spells[i]
        local faction = GetUnitFaction(icon_unit)
        local spelldata = CT:GetCooldownData(spellid)
        local tracked = CT:GetUnitCooldownInfo(icon_unit, spellid)
        local frame = gs.frame[sidx]

        -- icon
        local icon
        if spelldata.pvp_trinket then
            icon = GetPvPTrinketIcon(unit, db, spelldata)
        else
            icon = spelldata.icon
        end

        -- set border color
        local color
        for i = 1, #cat_priority do
            local key = cat_priority[i]
            if spelldata[key] then
                color = border_colors[key]
                break
            end
        end

        -- charges
        local charges
        if spelldata.charges then
            charges = (tracked and tracked.charges) or spelldata.charges
        elseif tracked and tracked.charges_detected then
            charges = tracked.charges or spelldata.opt_charges
        end

        -- update frame state
        frame.unit = icon_unit
        frame.spellid = spellid
        frame.spelldata = spelldata
        frame.state = 0
        frame.tracked = tracked
        frame.color = color or border_colors["uncat"]

        frame.icon:SetTexture(icon)
        frame:SetScript("OnUpdate", CooldownFrame_OnUpdate)
        frame.count:SetText(charges)
        frame:Show()

        sidx = sidx + 1
        shown = shown + 1
        if sidx > #gs.frame or shown >= db.cooldownsMax then
            break
        end
    end

    -- hide unused icons
    for i = sidx, #gs.frame do
        gs.frame[i]:Hide()
    end
end

function Cooldowns:UpdateGroupIcons(unit, group)
    local gs = self:GetGroupState(unit, group)
    local db = Cooldowns:GetGroupDB(unit, group)

    -- get spells lists
    local sorted_spells = GetCooldownList(unit, group)

    -- update icon frames
    if db.cooldownsDetached then
        local header_unit = GetHeaderUnit(unit)
        local header_gs = self:GetGroupState(header_unit, group)

        -- save detached group spells
        local index = GladiusEx:GetUnitIndex(unit)
        header_gs.unit_spells = header_gs.unit_spells or {}
        header_gs.unit_spells[index] = sorted_spells
        header_gs.unit_spells[index].unit = unit

        -- make list of the spells of all the units
        local detached_spells = {}
        for i = 1, 5 do
            local us = header_gs.unit_spells[i]
            if us then
                local dunit = us.unit
                for j = 1, #us do
                    tinsert(detached_spells, {dunit, us[j]})
                end
            end
        end

        -- sort the list
        if not db.cooldownsGroupByUnit then
            tsort(
                detached_spells,
                function(a, b)
                    return GetSpellSortScore(unit, group, a[2]) > GetSpellSortScore(unit, group, b[2])
                end
            )
        end

        if not header_gs.frame then
            return
        end

        UpdateGroupIconFrames(header_unit, group, detached_spells)
    else
        if not gs.frame then
            return
        end
        UpdateGroupIconFrames(unit, group, sorted_spells)
    end
end

local function CreateCooldownFrame(name, parent)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")

    frame.icon_frame = CreateFrame("Frame", nil, frame)
    frame.icon_frame:SetAllPoints()

    frame.icon = frame.icon_frame:CreateTexture(nil, "BACKGROUND") -- bg
    frame.icon:SetPoint("CENTER")

    frame.cooldown = CreateFrame("Cooldown", name .. "Cooldown", frame.icon_frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetReverse(true)
    frame.cooldown:Hide()

    frame.count = frame.icon_frame:CreateFontString(nil, "OVERLAY")
    frame.count:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusEx.db.base.globalFont), 10, "OUTLINE")
    frame.count:SetTextColor(1, 1, 1, 1)
    frame.count:SetPoint("BOTTOMRIGHT", 2, 0)
    frame.count:Show()

    return frame
end

function Cooldowns:CreateFrame(unit)
    for group = 1, self:GetNumGroups(unit) do
        self:CreateGroupFrame(unit, group)
    end
end

function Cooldowns:CreateGroupFrame(unit, group)
    local button = GladiusEx.buttons[unit]
    if not button then
        return
    end

    local gs = self:GetGroupState(unit, group)

    -- create cooldown frame
    if not gs.frame then
        gs.frame = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. "frame" .. unit, button, "BackdropTemplate")
        gs.frame:EnableMouse(false)

        for i = 1, MAX_ICONS do
            gs.frame[i] = CreateCooldownFrame("GladiusEx" .. self:GetName() .. "frameIcon" .. i .. unit, gs.frame)
            gs.frame[i]:SetScript("OnUpdate", CooldownFrame_OnUpdate)
            gs.frame[i].group = group
        end
    end
end

local function UpdateCooldownFrame(frame, size, border_size, crop)
    frame:SetSize(size, size)
    if border_size ~= 0 then
        frame:SetBackdrop({edgeFile = [[Interface\ChatFrame\ChatFrameBackground]], edgeSize = border_size})
        frame.icon:SetSize(size - border_size * 2, size - border_size * 2)
    else
        frame:SetBackdrop(nil)
        frame.icon:SetSize(size, size)
    end

    if crop then
        local n = 5
        frame.icon:SetTexCoord(n / 64, 1 - n / 64, n / 64, 1 - n / 64)
    else
        frame.icon:SetTexCoord(0, 1, 0, 1)
    end
end

function Cooldowns:SaveAnchorPosition(unit, group)
    local db = self:GetGroupDB(unit, group)
    local gs = self:GetGroupState(unit, group)
    local anchor = gs.anchor
    local scale = anchor:GetEffectiveScale() or 1
    db.cooldownsAnchorX = (anchor:GetLeft() or 0) * scale
    db.cooldownsAnchorY = (anchor:GetTop() or 0) * scale
end

function Cooldowns:CreateGroupAnchor(unit, group)
    local db = self:GetGroupDB(unit, group)
    local gs = self:GetGroupState(unit, group)

    -- anchor
    local anchor =
        CreateFrame(
        "Frame",
        "GladiusEx" .. self:GetName() .. unit .. "Group" .. group .. "Anchor",
        UIParent,
        "BackdropTemplate"
    )
    anchor:SetScript(
        "OnMouseDown",
        function(f, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    -- center horizontally
                    anchor:ClearAllPoints()
                    anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, f:GetBottom())
                    self:SaveAnchorPosition(unit, group)
                elseif IsAltKeyDown() then
                    -- center vertically
                    anchor:ClearAllPoints()
                    anchor:SetPoint("LEFT", UIParent, "LEFT", f:GetLeft(), 0)
                    self:SaveAnchorPosition(unit, group)
                end
            elseif button == "RightButton" then
                GladiusEx:ShowOptionsDialog()
            end
        end
    )

    anchor:SetScript(
        "OnDragStart",
        function(f)
            anchor:StartMoving()
        end
    )

    anchor:SetScript(
        "OnDragStop",
        function(f)
            anchor:StopMovingOrSizing()
            self:SaveAnchorPosition(unit, group)
        end
    )

    anchor.text = anchor:CreateFontString(nil, "OVERLAY")
    anchor.text2 = anchor:CreateFontString(nil, "OVERLAY")

    gs.anchor = anchor
end

function Cooldowns:UpdateGroupAnchor(unit, group)
    local db = self:GetGroupDB(unit, group)
    local gs = self:GetGroupState(unit, group)

    if not gs.anchor then
        self:CreateGroupAnchor(unit, group)
    end

    local anchor = gs.anchor

    -- update anchor
    local anchor_width = 200
    local anchor_height = 40

    anchor:ClearAllPoints()
    anchor:SetSize(anchor_width, anchor_height)
    anchor:SetScale(GladiusEx.db[unit].frameScale)

    if not db.cooldownsAnchorX or not db.cooldownsAnchorY then
        anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        local eff = anchor:GetEffectiveScale()
        anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.cooldownsAnchorX / eff, db.cooldownsAnchorY / eff)
    end

    anchor:SetBackdrop(
        {
            edgeFile = [[Interface\Buttons\WHITE8X8]],
            edgeSize = GladiusEx:AdjustPixels(anchor, max(1, floor(GladiusEx.db[unit].frameScale + 0.5))),
            bgFile = [[Interface\Buttons\WHITE8X8]],
            tile = true,
            tileSize = 8
        }
    )
    anchor:SetBackdropColor(0, 0, 0, 1)
    anchor:SetBackdropBorderColor(1, 1, 1, 1)
    anchor:SetFrameLevel(200)
    anchor:SetFrameStrata("MEDIUM")

    anchor:SetClampedToScreen(true)
    anchor:EnableMouse(true)
    anchor:SetMovable(true)
    anchor:RegisterForDrag("LeftButton")

    -- anchor texts
    anchor.text:SetPoint("TOP", anchor, "TOP", 0, -7)
    anchor.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    anchor.text:SetTextColor(1, 1, 1, 1)
    anchor.text:SetShadowOffset(1, -1)
    anchor.text:SetShadowColor(0, 0, 0, 1)
    anchor.text:SetText(
        string.format(L["Group %i anchor (%s)"], group, GladiusEx:IsPartyUnit(unit) and L["Party"] or L["Arena"])
    )

    anchor.text2:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 7)
    anchor.text2:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    anchor.text2:SetTextColor(1, 1, 1, 1)
    anchor.text2:SetShadowOffset(1, -1)
    anchor.text2:SetShadowColor(0, 0, 0, 1)
    anchor.text2:SetText(L["Lock the group to hide"])

    anchor:Hide()
end

local function UpdateCooldownGroup(
    unit,
    cooldownFrame,
    cooldownBackground,
    cooldownParent,
    cooldownAnchor,
    cooldownRelativePoint,
    cooldownOffsetX,
    cooldownOffsetY,
    cooldownPerColumn,
    cooldownGrow,
    cooldownSize,
    cooldownBorderSize,
    cooldownPaddingX,
    cooldownPaddingY,
    cooldownSpacingX,
    cooldownSpacingY,
    cooldownMax,
    cooldownCrop,
    cooldownTooltips)
    -- anchor point
    local parent = cooldownParent

    -- local xo, yo = GladiusEx:AdjustFrameOffset(parent, cooldownRelativePoint)
    local xo, yo = 0, 0
    cooldownPaddingX = GladiusEx:AdjustPositionOffset(parent, cooldownPaddingX)
    cooldownPaddingY = GladiusEx:AdjustPositionOffset(parent, cooldownPaddingY)
    cooldownSpacingX = GladiusEx:AdjustPositionOffset(parent, cooldownSpacingX)
    cooldownSpacingY = GladiusEx:AdjustPositionOffset(parent, cooldownSpacingY)
    cooldownOffsetX = GladiusEx:AdjustPositionOffset(parent, cooldownOffsetX) + xo
    cooldownOffsetY = GladiusEx:AdjustPositionOffset(parent, cooldownOffsetY) + yo
    cooldownSize = GladiusEx:AdjustPositionOffset(parent, cooldownSize)
    cooldownBorderSize = GladiusEx:AdjustPixels(parent, cooldownBorderSize)

    cooldownFrame:ClearAllPoints()
    cooldownFrame:SetPoint(cooldownAnchor, parent, cooldownRelativePoint, cooldownOffsetX, cooldownOffsetY)
    cooldownFrame:SetFrameLevel(61)

    -- size
    cooldownFrame:SetWidth(
        cooldownSize * cooldownPerColumn + cooldownSpacingX * (cooldownPerColumn - 1) + cooldownPaddingX * 2
    )
    cooldownFrame:SetHeight(
        cooldownSize * ceil(cooldownMax / cooldownPerColumn) +
            (cooldownSpacingY * (ceil(cooldownMax / cooldownPerColumn) - 1)) +
            cooldownPaddingY * 2
    )

    -- backdrop
    cooldownFrame:SetBackdrop({bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 16})
    cooldownFrame:SetBackdropColor(
        cooldownBackground.r,
        cooldownBackground.g,
        cooldownBackground.b,
        cooldownBackground.a
    )

    -- icon points
    local anchor, parent, relativePoint, offsetX, offsetY

    -- grow anchor
    local grow1, grow2, grow3, startRelPoint
    if cooldownGrow == "DOWNRIGHT" then
        grow1, grow2, grow3, startRelPoint = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT"
    elseif cooldownGrow == "DOWNLEFT" then
        grow1, grow2, grow3, startRelPoint = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT"
    elseif cooldownGrow == "UPRIGHT" then
        grow1, grow2, grow3, startRelPoint = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT"
    elseif cooldownGrow == "UPLEFT" then
        grow1, grow2, grow3, startRelPoint = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"
    end

    local grow_left = string.find(cooldownGrow, "LEFT")
    local grow_down = string.find(cooldownGrow, "DOWN")

    local start, startAnchor = 1, cooldownFrame
    for i = 1, #cooldownFrame do
        if cooldownMax >= i then
            if start == 1 then
                anchor, parent, relativePoint = grow1, startAnchor, startRelPoint
                offsetX = i == 1 and (grow_left and -cooldownPaddingX or cooldownPaddingX) or 0
                offsetY =
                    i == 1 and (grow_down and -cooldownPaddingY or cooldownPaddingY) or
                    (grow_down and -cooldownSpacingY or cooldownSpacingY)
            else
                anchor, parent, relativePoint = grow1, cooldownFrame[i - 1], grow3
                offsetX = grow_left and -cooldownSpacingX or cooldownSpacingX
                offsetY = 0
            end

            if start == cooldownPerColumn then
                start = 0
                startAnchor = cooldownFrame[i - cooldownPerColumn + 1]
                startRelPoint = grow2
            end

            start = start + 1
        end

        cooldownFrame[i]:ClearAllPoints()
        cooldownFrame[i]:SetPoint(anchor, parent, relativePoint, offsetX, offsetY)

        if cooldownTooltips then
            cooldownFrame[i]:SetScript(
                "OnEnter",
                function(self)
                    if self.spellid then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetSpellByID(self.spellid)
                    end
                end
            )
            cooldownFrame[i]:SetScript(
                "OnLeave",
                function(self)
                    GameTooltip:Hide()
                end
            )
            cooldownFrame[i]:EnableMouse(true)
        else
            cooldownFrame[i]:SetScript("OnEnter", nil)
            cooldownFrame[i]:SetScript("OnLeave", nil)
            cooldownFrame[i]:EnableMouse(false)
        end

        UpdateCooldownFrame(cooldownFrame[i], cooldownSize, cooldownBorderSize, cooldownCrop)
    end
end

function Cooldowns:Update(unit)
    for group = 1, self:GetNumGroups(unit) do
        self:UpdateGroup(unit, group)
    end
    -- hide excess groups after one is deleted
    local group_state = unit_state[unit] and unit_state[unit] or {}
    for group = self:GetNumGroups(unit) + 1, #group_state do
        if group_state[group].frame then
            group_state[group].frame:Hide()
        end
        if group_state[group].anchor then
            group_state[group].anchor:Hide()
        end
    end
end

function Cooldowns:Refresh(unit)
    self:UpdateIcons(unit)
end

function Cooldowns:UpdateGroup(unit, group)
    local db = self:GetGroupDB(unit, group)
    local gs = self:GetGroupState(unit, group)

    if not db.cooldownsDetached or IsHeaderUnit(unit) then
        -- create frame
        self:CreateGroupFrame(unit, group)

        -- update anchor
        if db.cooldownsDetached then
            self:UpdateGroupAnchor(unit, group)
            if db.cooldownsLocked then
                gs.anchor:Hide()
            else
                gs.anchor:Show()
            end
        elseif gs.anchor then
            gs.anchor:Hide()
        end

        -- update cooldown frame
        UpdateCooldownGroup(
            unit,
            gs.frame,
            db.cooldownsBackground,
            db.cooldownsDetached and gs.anchor or GladiusEx:GetAttachFrame(unit, db.cooldownsAttachTo),
            db.cooldownsAnchor,
            db.cooldownsRelativePoint,
            db.cooldownsOffsetX,
            db.cooldownsOffsetY,
            db.cooldownsPerColumn,
            db.cooldownsGrow,
            db.cooldownsSize,
            db.cooldownsBorderSize,
            db.cooldownsPaddingX,
            db.cooldownsPaddingY,
            db.cooldownsSpacingX,
            db.cooldownsSpacingY,
            db.cooldownsMax,
            db.cooldownsCrop,
            db.cooldownsTooltips
        )
    elseif gs.frame then
        gs.frame:SetSize(0, 0)
    end

    -- update icons
    self:UpdateGroupIcons(unit, group)

    -- hide group
    if gs.frame then
        gs.frame:Hide()
    end
end

local ct_registered = {}

function Cooldowns:Show(unit)
    for group = 1, self:GetNumGroups(unit) do
        local gs = self:GetGroupState(unit, group)
        local db = self:GetGroupDB(unit, group)

        if not ct_registered[unit] then
            CT:RegisterUnit(unit)
            ct_registered[unit] = true
        end

        if gs.frame and (not db.cooldownsDetached or IsHeaderUnit(unit)) then
            gs.frame:Show()
        end
    end
end

function Cooldowns:Reset(unit)
    for group = 1, self:GetNumGroups(unit) do
        local gs = self:GetGroupState(unit, group)
        local db = self:GetGroupDB(unit, group)

        if ct_registered[unit] then
            CT:UnregisterUnit(unit)
            ct_registered[unit] = false
        end

        if db.cooldownsDetached then
            local header_gs = self:GetGroupState(GetHeaderUnit(unit), group)
            if header_gs.unit_spells then
                local index = GladiusEx:GetUnitIndex(unit)
                header_gs.unit_spells[index] = nil
            end
        end

        if gs.frame then
            -- hide cooldown frame
            gs.frame:Hide()
        end
    end
end

function Cooldowns:Test(unit)
    self:UpdateIcons(unit)
end

function Cooldowns:GetOptions(unit)
    local options = {}

    options.sep = {
        type = "description",
        name = "",
        width = "full",
        order = 1
    }
    options.addgroup = {
        type = "execute",
        name = L["Add cooldowns group"],
        desc = L["Add cooldowns group"],
        func = function()
            local gdb =
                MakeGroupDb(
                {
                    cooldownsGroupId = self:MakeGroupId(),
                    cooldownsSpells = {[42292] = true}
                }
            )
            local group_idx = self:AddGroup(unit, gdb)
            options["group" .. group_idx] = self:MakeGroupOptions(unit, group_idx)
            GladiusEx:UpdateFrames()
        end,
        disabled = function()
            return not self:IsUnitEnabled(unit)
        end,
        order = 2
    }

    --[[
	options.help = {
		type = "group",
		name = L["Help"],
		order = 3,
		args = {
		}
	}
	]]
    -- setup groups
    for group = 1, self:GetNumGroups(unit) do
        options["group" .. group] = self:MakeGroupOptions(unit, group)
    end

    return options
end

local FormatSpellDescription

function Cooldowns:GetGroupName(unit, group)
    local groupName = self:GetGroupDB(unit, group).name
    if not groupName or groupName == "" then
        return L["Group"] .. " " .. group
    end
    return groupName
end

function Cooldowns:MakeGroupOptions(unit, group)
    local function getOption(info)
        return (info.arg and self:GetGroupDB(unit, group)[info.arg] or self:GetGroupDB(unit, group)[info[#info]])
    end

    local function setOption(info, value)
        local key = info[#info]
        self:GetGroupDB(unit, group)[key] = value
        GladiusEx:UpdateFrames()
    end

    -- pre-declare so that the name can be updated
    local group_options
    group_options = {
        type = "group",
        name = self:GetGroupName(unit, group),
        childGroups = "tab",
        order = 10 + group,
        hidden = function()
            return self:GetNumGroups(unit) < group
        end,
        get = getOption,
        set = setOption,
        args = {
            general = {
                type = "group",
                name = L["General"],
                order = 1,
                args = {
                    widget = {
                        type = "group",
                        name = L["Widget"],
                        desc = L["Widget settings"],
                        inline = true,
                        order = 1,
                        args = {
                            cooldownsBackground = {
                                type = "color",
                                name = L["Background color"],
                                desc = L["Color of the frame background"],
                                hasAlpha = true,
                                get = function(info)
                                    return GladiusEx:GetColorOption(self:GetGroupDB(unit, group), info)
                                end,
                                set = function(info, r, g, b, a)
                                    return GladiusEx:SetColorOption(self:GetGroupDB(unit, group), info, r, g, b, a)
                                end,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 1
                            },
                            name = {
                                type = "input",
                                name = L["Group name"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                set = function(info, value)
                                    for groupIdx = 1, self:GetNumGroups(unit) do
                                        local name = self:GetGroupName(unit, groupIdx)
                                        if group ~= groupIdx and value == name then
                                            GladiusEx:Print("Duplicated group name!")
                                            return
                                        end
                                    end

                                    setOption(info, value)
                                    group_options.name = self:GetGroupName(unit, group)
                                end,
                                order = 2
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 13
                            },
                            cooldownsCrop = {
                                type = "toggle",
                                name = L["Crop borders"],
                                desc = L["Toggle if the icon borders should be cropped or not"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 14
                            },
                            cooldownsTooltips = {
                                type = "toggle",
                                name = L["Show tooltips"],
                                desc = L["Toggle if the icons should show the spell tooltip when hovered"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 15
                            },
                            trinketIcon = {
                                type = "select",
                                name = L["PvP Trinket Icon"],
                                desc = L["Choose the PvP trinket icon style to display"],
                                order = 16,
                                style = "dropdown",
                                values = function()
                                    local data = CT:GetCooldownData(GladiusEx.IS_RETAIL and 336126 or 42292)
                                    local v = {
                                        ["alliance_wotlk"] = string.format("|T%s:16:16:0:0|t %s", data.icon_alliance_wotlk, L["Alliance (WotLK)"]),
                                        ["horde_wotlk"] = string.format("|T%s:16:16:0:0|t %s", data.icon_horde_wotlk, L["Horde (WotLK)"]),
                                        ["faction_wotlk"] = string.format("|T%s:16:16:0:0|t|T%s:16:16:0:0|t %s", data.icon_alliance_wotlk, data.icon_horde_wotlk, L["Faction (WotLK)"]),
                                        ["alliance"] = string.format("|T%s:16:16:0:0|t %s", data.icon_alliance, L["Alliance (Classic)"]),
                                        ["horde"] = string.format("|T%s:16:16:0:0|t %s", data.icon_horde, L["Horde (Classic)"]),
                                        ["faction"] = string.format("|T%s:16:16:0:0|t|T%s:16:16:0:0|t %s", data.icon_alliance, data.icon_horde, L["Faction (Classic)"]),
                                    }

                                    if GladiusEx.IS_RETAIL and data.icon_gladiator then
                                        v["gladiator"] = string.format("|T%s:16:16:0:0|t %s", data.icon_gladiator, L["Gladiator (Retail)"])
                                    end

                                    return v
                                end,
                                get = function()
                                    return Cooldowns:GetGroupDB(unit, group).cooldownsTrinketIcon or "faction"
                                end,
                                set = function(info, value)
                                    Cooldowns:GetGroupDB(unit, group).cooldownsTrinketIcon = value
                                    GladiusEx:UpdateFrames()
                                end,
                                disabled = function()
                                    return not Cooldowns:IsUnitEnabled(unit)
                                end,
                            },
                            sep2 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 18
                            },
                            cooldownsPerColumn = {
                                type = "range",
                                name = L["Icons per column"],
                                desc = L["Number of icons per column"],
                                min = 1,
                                max = MAX_ICONS,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 19
                            },
                            cooldownsMax = {
                                type = "range",
                                name = L["Icons max"],
                                desc = L["Number of max icons"],
                                min = 1,
                                max = MAX_ICONS,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 20
                            },
                            sep3 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 23
                            },
                            remgroup = {
                                type = "execute",
                                name = L["Remove this cooldowns group"],
                                desc = L["Remove this cooldowns group"],
                                width = "double",
                                func = function()
                                    self:RemoveGroup(unit, group)
                                    GladiusEx:UpdateFrames()
                                end,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 244
                            }
                        }
                    },
                    icon_transparency = {
                        type = "group",
                        name = L["Icon transparency"],
                        desc = L["Icon transparency settings"],
                        inline = true,
                        order = 1.1,
                        args = {
                            cooldownsIconAvailAlpha = {
                                type = "range",
                                name = L["Available"],
                                desc = L["Alpha of the icon while the spell is not on cooldown"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 1
                            },
                            cooldownsIconUsingAlpha = {
                                type = "range",
                                name = L["Active"],
                                desc = L["Alpha of the icon while the spell is being used"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 2
                            },
                            cooldownsIconCooldownAlpha = {
                                type = "range",
                                name = L["On cooldown"],
                                desc = L["Alpha of the icon while the spell is on cooldown"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 3
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 4
                            }
                        }
                    },
                    border_transparency = {
                        type = "group",
                        name = L["Border transparency"],
                        desc = L["Border transparency settings"],
                        inline = true,
                        order = 1.2,
                        args = {
                            cooldownsBorderAvailAlpha = {
                                type = "range",
                                name = L["Available"],
                                desc = L["Alpha of the icon border while the spell is not on cooldown"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 1
                            },
                            cooldownsBorderUsingAlpha = {
                                type = "range",
                                name = L["Active"],
                                desc = L["Alpha of the icon border while the spell is being used"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 2
                            },
                            cooldownsBorderCooldownAlpha = {
                                type = "range",
                                name = L["On cooldown"],
                                desc = L["Alpha of the icon border while the spell is on cooldown"],
                                min = 0,
                                max = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 3
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 4
                            }
                        }
                    },
                    animation = {
                        type = "group",
                        name = L["Animation"],
                        desc = L["Animation settings on event"],
                        inline = true,
                        order = 1.5,
                        args = {
                            cooldownsOnUseScale = {
                                type = "range",
                                name = L["On-use scale"],
                                desc = L["The size the the icon should scale up to when the cooldown gets used"],
                                min = 1,
                                max = 5,
                                step = 0.5,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 10
                            },
                            cooldownsOnUseDuration = {
                                type = "range",
                                name = L["On-use scale duration"],
                                desc = L["How long should the scale animation last"],
                                min = 0,
                                max = 3,
                                step = 0.1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 11
                            },
                            cooldownsOffCdScale = {
                                type = "range",
                                name = L["Off-cooldown scale"],
                                desc = L["The size the the icon should scale up to when the cooldown goes off CD"],
                                min = 1,
                                max = 5,
                                step = 0.5,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 20
                            },
                            cooldownsOffCdDuration = {
                                type = "range",
                                name = L["Off-cooldown scale duration"],
                                desc = L["How long should the scale animation last"],
                                min = 0,
                                max = 3,
                                step = 0.1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 21
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 4
                            },
                            cooldownsEnableGlow = {
                                type = "toggle",
                                name = L["Glow cooldowns that are in active use"],
                                desc = L["Show a glow around the cooldown icon during the cooldown duration"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 30
                            },
                            sep2 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 4
                            }
                        }
                    },
                    size = {
                        type = "group",
                        name = L["Size"],
                        desc = L["Size settings"],
                        inline = true,
                        order = 2,
                        args = {
                            cooldownsSize = {
                                type = "range",
                                name = L["Icon size"],
                                desc = L["Size of the cooldown icons"],
                                min = 1,
                                softMin = 10,
                                softMax = 100,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 5
                            },
                            cooldownsBorderSize = {
                                type = "range",
                                name = L["Icon border size"],
                                desc = L["Size of the cooldown icon borders"],
                                min = 0,
                                softMin = 0,
                                softMax = 10,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 6
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 13
                            },
                            cooldownsPaddingY = {
                                type = "range",
                                name = L["Vertical padding"],
                                desc = L["Vertical padding of the icons"],
                                min = 0,
                                softMax = 30,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 15
                            },
                            cooldownsPaddingX = {
                                type = "range",
                                name = L["Horizontal padding"],
                                desc = L["Horizontal padding of the icons"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                min = 0,
                                softMax = 30,
                                step = 1,
                                order = 20
                            },
                            sep2 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 23
                            },
                            cooldownsSpacingY = {
                                type = "range",
                                name = L["Vertical spacing"],
                                desc = L["Vertical spacing of the icons"],
                                min = 0,
                                softMax = 30,
                                step = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 25
                            },
                            cooldownsSpacingX = {
                                type = "range",
                                name = L["Horizontal spacing"],
                                desc = L["Horizontal spacing of the icons"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                min = 0,
                                softMax = 30,
                                step = 1,
                                order = 30
                            }
                        }
                    },
                    position = {
                        type = "group",
                        name = L["Position"],
                        desc = L["Position settings"],
                        inline = true,
                        order = 4,
                        args = {
                            cooldownsDetached = {
                                type = "toggle",
                                name = L["Detached group"],
                                desc = L[
                                    "Detach the group from the unit frames, showing the cooldowns of all the units and allowing you to move it freely"
                                ],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 1
                            },
                            cooldownsLocked = {
                                type = "toggle",
                                name = L["Locked"],
                                desc = L["Toggle if the detached group can be moved"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit) or
                                        not self:GetGroupDB(unit, group).cooldownsDetached
                                end,
                                order = 2
                            },
                            cooldownsGroupByUnit = {
                                type = "toggle",
                                name = L["Group by unit"],
                                desc = L["Toggle if the cooldowns in the detached group should be grouped by unit"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit) or
                                        not self:GetGroupDB(unit, group).cooldownsDetached
                                end,
                                order = 3
                            },
                            sep = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 9
                            },
                            cooldownsAttachTo = {
                                type = "select",
                                name = L["Attach to"],
                                desc = L["Attach to the given frame"],
                                values = function()
                                    return self:GetOtherAttachPoints(unit)
                                end,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                hidden = function()
                                    return self:GetGroupDB(unit, group).cooldownsDetached
                                end,
                                order = 10
                            },
                            cooldownsPosition = {
                                type = "select",
                                name = L["Position"],
                                desc = L["Position of the frame"],
                                values = GladiusEx:GetGrowSimplePositions(),
                                get = function()
                                    return GladiusEx:GrowSimplePositionFromAnchor(
                                        self:GetGroupDB(unit, group).cooldownsAnchor,
                                        self:GetGroupDB(unit, group).cooldownsRelativePoint,
                                        self:GetGroupDB(unit, group).cooldownsGrow
                                    )
                                end,
                                set = function(info, value)
                                    self:GetGroupDB(unit, group).cooldownsAnchor,
                                        self:GetGroupDB(unit, group).cooldownsRelativePoint =
                                        GladiusEx:AnchorFromGrowSimplePosition(
                                        value,
                                        self:GetGroupDB(unit, group).cooldownsGrow
                                    )
                                    GladiusEx:UpdateFrames()
                                end,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                hidden = function()
                                    return GladiusEx.db.base.advancedOptions
                                end,
                                order = 11
                            },
                            cooldownsGrow = {
                                type = "select",
                                name = L["Grow direction"],
                                desc = L["Grow direction of the icons"],
                                values = {
                                    ["UPLEFT"] = L["Up left"],
                                    ["UPRIGHT"] = L["Up right"],
                                    ["DOWNLEFT"] = L["Down left"],
                                    ["DOWNRIGHT"] = L["Down right"]
                                },
                                set = function(info, value)
                                    if not GladiusEx.db.base.advancedOptions then
                                        self:GetGroupDB(unit, group).cooldownsAnchor,
                                            self:GetGroupDB(unit, group).cooldownsRelativePoint =
                                            GladiusEx:AnchorFromGrowDirection(
                                            self:GetGroupDB(unit, group).cooldownsAnchor,
                                            self:GetGroupDB(unit, group).cooldownsRelativePoint,
                                            self:GetGroupDB(unit, group).cooldownsGrow,
                                            value
                                        )
                                    end
                                    self:GetGroupDB(unit, group).cooldownsGrow = value
                                    GladiusEx:UpdateFrames()
                                end,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 13
                            },
                            sep2 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 17
                            },
                            cooldownsAnchor = {
                                type = "select",
                                name = L["Anchor"],
                                desc = L["Anchor of the frame"],
                                values = GladiusEx:GetPositions(),
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                hidden = function()
                                    return not GladiusEx.db.base.advancedOptions
                                end,
                                order = 20
                            },
                            cooldownsRelativePoint = {
                                type = "select",
                                name = L["Relative point"],
                                desc = L["Relative point of the frame"],
                                values = GladiusEx:GetPositions(),
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                hidden = function()
                                    return not GladiusEx.db.base.advancedOptions
                                end,
                                order = 25
                            },
                            sep3 = {
                                type = "description",
                                name = "",
                                width = "full",
                                order = 27
                            },
                            cooldownsOffsetX = {
                                type = "range",
                                name = L["Offset X"],
                                desc = L["X offset of the frame"],
                                softMin = -100,
                                softMax = 100,
                                bigStep = 1,
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 30
                            },
                            cooldownsOffsetY = {
                                type = "range",
                                name = L["Offset Y"],
                                desc = L["Y offset of the frame"],
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                softMin = -100,
                                softMax = 100,
                                bigStep = 1,
                                order = 35
                            }
                        }
                    }
                }
            },
            category_options = {
                type = "group",
                name = L["Category"],
                order = 2,
                args = {}
            },
            cooldowns = {
                type = "group",
                name = function()
                    local count = 0
                    local cooldownsSpells = self:GetGroupDB(unit, group).cooldownsSpells
                    for spellid in pairs(CT:GetCooldownsData()) do
                        if cooldownsSpells[spellid] then
                            count = count + 1
                        end
                    end
                    return string.format("%s [%i]", L["Cooldowns"], count)
                end,
                order = 3,
                args = {
                    cooldownsHideTalentsUntilDetected = {
                        type = "toggle",
                        name = L["Hide talents until detected"],
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        width = "double",
                        order = nil
                    },
                    enableall = {
                        type = "execute",
                        name = L["Enable all"],
                        desc = L["Enable all the spells"],
                        func = function()
                            for spellid, spelldata in pairs(CT:GetCooldownsData()) do
                                if type(spelldata) == "table" then
                                    self:GetGroupDB(unit, group).cooldownsSpells[spellid] = true
                                end
                            end
                            GladiusEx:UpdateFrames()
                        end,
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 0.2
                    },
                    disableall = {
                        type = "execute",
                        name = L["Disable all"],
                        desc = L["Disable all the spells"],
                        func = function()
                            for spellid, spelldata in pairs(CT:GetCooldownsData()) do
                                if type(spelldata) == "table" then
                                    self:GetGroupDB(unit, group).cooldownsSpells[spellid] = false
                                end
                            end
                            GladiusEx:UpdateFrames()
                        end,
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 0.5
                    },
                    copyfromother = {
                        type = "execute",
                        name = GladiusEx:IsArenaUnit(unit) and L["Copy from party"] or L["Copy from arena"],
                        desc = L[
                            "Copy cooldown spells from the " ..
                                (GladiusEx:IsArenaUnit(unit) and "party" or "arena") ..
                                    " with the same cooldown group name"
                        ],
                        func = function()
                            local name = self:GetGroupName(unit, group)
                            local opp = GladiusEx:GetOppositeUnit(unit)
                            -- find the samely-named group in the "other side"
                            for opp_group = 1, self:GetNumGroups(opp) do
                                local opp_name = self:GetGroupName(opp, opp_group)
                                if opp_name == name then
                                    -- TODO copy, rather than this aliasing
                                    local opp_db = self:GetGroupDB(opp, opp_group)
                                    self:GetGroupDB(unit, group).cooldownsSpells = opp_db.cooldownsSpells
                                    GladiusEx:UpdateFrames()
                                    return
                                end
                            end
                            GladiusEx:Print(L["No matching group"])
                        end,
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 0.7
                    },
                    preracesep = {
                        type = "group",
                        name = "",
                        order = 2,
                        args = {}
                    },
                    preitemsep = {
                        type = "group",
                        name = "",
                        order = 4,
                        args = {}
                    }
                }
            }
        }
    }

    -- fill category list
    local pargs = group_options.args.category_options.args
    for i = 1, #(self:GetGroupDB(unit, group).cooldownsCatPriority) do
        local cat = self:GetGroupDB(unit, group).cooldownsCatPriority[i]
        local option = {
            type = "group",
            name = L["cat:" .. cat],
            order = function()
                for i = 1, #(self:GetGroupDB(unit, group).cooldownsCatPriority) do
                    if self:GetGroupDB(unit, group).cooldownsCatPriority[i] == cat then
                        return i
                    end
                end
            end,
            args = {
                header = {
                    type = "description",
                    name = L["cat:" .. cat],
                    order = 1
                },
                color = {
                    type = "color",
                    name = L["Color"],
                    desc = L["Border color for spells in this category"],
                    get = function()
                        local c = self:GetGroupDB(unit, group).cooldownsCatColors[cat]
                        return c.r, c.g, c.b
                    end,
                    set = function(info, r, g, b)
                        self:GetGroupDB(unit, group).cooldownsCatColors[cat] = {r = r, g = g, b = b}
                        GladiusEx:UpdateFrames()
                    end,
                    disabled = function()
                        return not self:IsUnitEnabled(unit)
                    end,
                    order = 2
                },
                sep = {
                    type = "description",
                    name = "",
                    width = "full",
                    order = 5
                },
                moveup = {
                    type = "execute",
                    name = L["Up"],
                    desc = L["Increase the priority of spells in this category"],
                    func = function()
                        for i = 1, #self:GetGroupDB(unit, group).cooldownsCatPriority do
                            if self:GetGroupDB(unit, group).cooldownsCatPriority[i] == cat then
                                if i ~= 1 then
                                    local tmp = self:GetGroupDB(unit, group).cooldownsCatPriority[i - 1]
                                    self:GetGroupDB(unit, group).cooldownsCatPriority[i - 1] =
                                        self:GetGroupDB(unit, group).cooldownsCatPriority[i]
                                    self:GetGroupDB(unit, group).cooldownsCatPriority[i] = tmp

                                    self:SpellSortingChanged()
                                    GladiusEx:UpdateFrames()
                                end
                                return
                            end
                        end
                    end,
                    disabled = function()
                        return not self:IsUnitEnabled(unit)
                    end,
                    order = 10
                },
                movedown = {
                    type = "execute",
                    name = L["Down"],
                    desc = L["Decrease the priority of spells in this category"],
                    func = function()
                        for i = 1, #self:GetGroupDB(unit, group).cooldownsCatPriority do
                            if self:GetGroupDB(unit, group).cooldownsCatPriority[i] == cat then
                                if i ~= #self:GetGroupDB(unit, group).cooldownsCatPriority then
                                    local tmp = self:GetGroupDB(unit, group).cooldownsCatPriority[i + 1]
                                    self:GetGroupDB(unit, group).cooldownsCatPriority[i + 1] =
                                        self:GetGroupDB(unit, group).cooldownsCatPriority[i]
                                    self:GetGroupDB(unit, group).cooldownsCatPriority[i] = tmp

                                    self:SpellSortingChanged()
                                    GladiusEx:UpdateFrames()
                                end
                                return
                            end
                        end
                    end,
                    disabled = function()
                        return not self:IsUnitEnabled(unit)
                    end,
                    order = 11
                },
                enableall = {
                    type = "execute",
                    name = L["Enable all"],
                    desc = L["Enable all the spells in this category"],
                    func = function()
                        for spellid, spelldata in pairs(CT:GetCooldownsData()) do
                            if type(spelldata) == "table" then
                                if spelldata[cat] then
                                    self:GetGroupDB(unit, group).cooldownsSpells[spellid] = true
                                end
                            end
                        end
                        GladiusEx:UpdateFrames()
                    end,
                    disabled = function()
                        return not self:IsUnitEnabled(unit)
                    end,
                    order = 20
                },
                disableall = {
                    type = "execute",
                    name = L["Disable all"],
                    desc = L["Disable all the spells in this category"],
                    func = function()
                        for spellid, spelldata in pairs(CT:GetCooldownsData()) do
                            if type(spelldata) == "table" then
                                if spelldata[cat] then
                                    self:GetGroupDB(unit, group).cooldownsSpells[spellid] = false
                                end
                            end
                        end
                        GladiusEx:UpdateFrames()
                    end,
                    disabled = function()
                        return not self:IsUnitEnabled(unit)
                    end,
                    order = 21
                }
            }
        }
        pargs[cat] = option
    end

    -- fill spell list
    local function getSpell(info)
        return self:GetGroupDB(unit, group).cooldownsSpells[info.arg]
    end

    local function setSpell(info, value)
        self:GetGroupDB(unit, group).cooldownsSpells[info.arg] = value
        GladiusEx:UpdateFrames()
    end

    local args = group_options.args.cooldowns.args
    for spellid, spelldata in pairs(CT:GetCooldownsData()) do
        if type(spelldata) == "table" and (not spelldata.cooldown or spelldata.cooldown < 600) and not spelldata.hidden then
            local cats = {}
            if spelldata.pvp_trinket then
                tinsert(cats, L["cat:pvp_trinket"])
            end
            if spelldata.cc then
                tinsert(cats, L["cat:cc"])
            end
            if spelldata.offensive then
                tinsert(cats, L["cat:offensive"])
            end
            if spelldata.defensive then
                tinsert(cats, L["cat:defensive"])
            end
            if spelldata.silence then
                tinsert(cats, L["cat:silence"])
            end
            if spelldata.interrupt then
                tinsert(cats, L["cat:interrupt"])
            end
            if spelldata.dispel then
                tinsert(cats, L["cat:dispel"])
            end
            if spelldata.mass_dispel then
                tinsert(cats, L["cat:mass_dispel"])
            end
            if spelldata.heal then
                tinsert(cats, L["cat:heal"])
            end
            if spelldata.knockback then
                tinsert(cats, L["cat:knockback"])
            end
            if spelldata.stun then
                tinsert(cats, L["cat:stun"])
            end
            if spelldata.immune then
                tinsert(cats, L["cat:immune"])
            end
            if spelldata.covenant then
                tinsert(cats, L["cat:covenant"])
            end
            -- specID takes category precedence over talent, so specify it to make it clear
            if spelldata.specID and spelldata.talent then
                tinsert(cats, L["cat:talent"])
            end
            local catstr
            if #cats > 0 then
                catstr = "|cff7f7f7f(" .. strjoin(", ", unpack(cats)) .. ")|r"
            end

            if GladiusEx:IsDebugging() then
                local basecd = GetSpellBaseCooldown(spellid)
                if basecd and basecd / 1000 ~= spelldata.cooldown then
                    local str =
                        string.format(
                        "%s: |T%s:20|t %s [%ss/Base: %ss] %s",
                        spelldata.class or "??",
                        spelldata.icon,
                        spelldata.name,
                        spelldata.cooldown or "??",
                        basecd and basecd / 1000 or "??",
                        catstr or ""
                    )
                    if not self.debuglog then
                        self.debuglog = {}
                    end
                    if not self.debuglog[str] then
                        self.debuglog[str] = true
                    end
                end
            end

            local cdstr = spelldata.cooldown and "[" .. spelldata.cooldown .. "s]" or ""
            local namestr = string.format(L[" |T%s:20|t %s %s %s"], spelldata.icon, spelldata.name, cdstr, catstr or "")

            local function MakeSpellDesc()
                local spelldesc = FormatSpellDescription(spellid)
                local extradesc = {}
                if spelldata.duration then
                    table.insert(extradesc, string.format(L["Duration: %is"], spelldata.duration))
                end
                if spelldata.replaces then
                    table.insert(extradesc, string.format(L["Replaces: %s"], C_Spell and C_Spell.GetSpellName(spelldata.replaces) or GetSpellInfo(spelldata.replaces)))
                end
                if spelldata.requires_aura then
                    table.insert(
                        extradesc,
                        string.format(L["Required aura: %s"], C_Spell and C_Spell.GetSpellName(spelldata.requires_aura) or GetSpellInfo(spelldata.requires_aura))
                    )
                end
                if spelldata.sets_cooldown then
                    table.insert(
                        extradesc,
                        string.format(
                            L["Shared cooldown: %s (%is)"],
                            C_Spell and C_Spell.GetSpellName(spelldata.sets_cooldown.spellid) or GetSpellInfo(spelldata.sets_cooldown.spellid),
                            spelldata.sets_cooldown.cooldown
                        )
                    )
                end
                if spelldata.sets_cooldowns then
                    for i = 1, #spelldata.sets_cooldowns do
                        local cd = spelldata.sets_cooldowns[i]
                        table.insert(
                            extradesc,
                            string.format(L["Shared cooldown: %s (%is)"], C_Spell and C_Spell.GetSpellName(cd.spellid) or GetSpellInfo(cd.spellid), cd.cooldown)
                        )
                    end
                end
                if spelldata.cooldown_starts_on_aura_fade then
                    table.insert(extradesc, L["Cooldown starts when aura fades"])
                end
                if spelldata.cooldown_starts_on_dispel then
                    table.insert(extradesc, L["Cooldown starts on dispel"])
                end
                if spelldata.resets then
                    table.insert(
                        extradesc,
                        string.format(
                            L["Resets: %s"],
                            table.concat(fn.sort(fn.map(spelldata.resets, C_Spell and C_Spell.GetSpellName or GetSpellInfo)), ", ")
                        )
                    )
                end
                if spelldata.charges then
                    table.insert(extradesc, string.format(L["Charges: %i"], spelldata.charges))
                end
                if spelldata.covenant then
                    table.insert(extradesc, string.format(L["Covenant: %s"], spelldata.covenant))
                end
                if #extradesc > 0 then
                    spelldesc = spelldesc .. "\n|cff9f9f9f" .. table.concat(fn.sort(extradesc), "\n|cff9f9f9f")
                end
                return spelldesc
            end

            local spellconfig = {
                type = "toggle",
                name = namestr,
                desc = GladiusEx:IsDebugging() and MakeSpellDesc() or MakeSpellDesc,
                descStyle = "inline",
                width = "full",
                arg = spellid,
                get = getSpell,
                set = setSpell,
                disabled = function()
                    return not self:IsUnitEnabled(unit)
                end,
                order = spelldata.name:byte(1) * 0xff + spelldata.name:byte(2)
            }
            if spelldata.class then
                local ico =
                    spelldata.class == "DEATHKNIGHT" and [[Interface\ICONS\Spell_DEATHKNIGHT_classicon]] or
                    [[Interface\ICONS\ClassIcon_]] .. spelldata.class
                if not args[spelldata.class] then
                    args[spelldata.class] = {
                        type = "group",
                        name = LOCALIZED_CLASS_NAMES_MALE[spelldata.class],
                        icon = ico,
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 1,
                        args = {}
                    }
                end

                if spelldata.specID then
                    -- spec
                    for _, specID in ipairs(spelldata.specID) do
                        if not args[spelldata.class].args["spec" .. specID] then
                            local _, name, description, icon, role, class =
                                GladiusEx.Data.GetSpecializationInfoByID(specID)
                            args[spelldata.class].args["spec" .. specID] = {
                                type = "group",
                                name = name or "",
                                icon = icon or "",
                                disabled = function()
                                    return not self:IsUnitEnabled(unit)
                                end,
                                order = 3 + specID,
                                args = {}
                            }
                        end
                        args[spelldata.class].args["spec" .. specID].args["spell" .. spellid] = spellconfig
                    end
                elseif spelldata.talent then
                    -- talent
                    if not args[spelldata.class].args.talents then
                        args[spelldata.class].args.talents = {
                            type = "group",
                            name = L["Talent"],
                            disabled = function()
                                return not self:IsUnitEnabled(unit)
                            end,
                            order = 2,
                            args = {}
                        }
                    end
                    args[spelldata.class].args.talents.args["spell" .. spellid] = spellconfig
                elseif spelldata.pet then
                    -- pet
                    if not args[spelldata.class].args.pets then
                        args[spelldata.class].args.pets = {
                            type = "group",
                            name = L["Pet"],
                            disabled = function()
                                return not self:IsUnitEnabled(unit)
                            end,
                            order = 1000,
                            args = {}
                        }
                    end
                    args[spelldata.class].args.pets.args["spell" .. spellid] = spellconfig
                else
                    -- baseline
                    if not args[spelldata.class].args.base then
                        args[spelldata.class].args.base = {
                            type = "group",
                            name = "Baseline",
                            disabled = function()
                                return not self:IsUnitEnabled(unit)
                            end,
                            order = 1,
                            args = {}
                        }
                    end
                    args[spelldata.class].args.base.args["spell" .. spellid] = spellconfig
                end
            elseif spelldata.race then
                -- racial
                if not args[spelldata.race] then
                    args[spelldata.race] = {
                        type = "group",
                        name = spelldata.race,
                        icon = function()
                            return [[Interface\CHARACTERFRAME\TEMPORARYPORTRAIT]] ..
                                (random(0, 1) == 0 and "-FEMALE-" or "-MALE-") .. spelldata.race
                        end,
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 3,
                        args = {}
                    }
                end
                args[spelldata.race].args["spell" .. spellid] = spellconfig
            elseif spelldata.item then
                -- item
                if not args.items then
                    args.items = {
                        type = "group",
                        name = L["Items"],
                        icon = [[Interface\Icons\Trade_Engineering]],
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 5,
                        args = {}
                    }
                end
                args.items.args["spell" .. spellid] = spellconfig
            elseif spelldata.pvp_trinket then
                -- pvp trinket
                if not args.pvp_trinket then
                    args.pvp_trinket = {
                        type = "group",
                        name = "PVP Trinket",
                        disabled = function()
                            return not self:IsUnitEnabled(unit)
                        end,
                        order = 15,
                        args = {}
                    }
                end
                args.pvp_trinket.args["spell" .. spellid] = spellconfig
            else
                GladiusEx:Print("Bad spelldata for", spellid, ": could not find type")
            end
        end
    end

    if GladiusEx:IsDebugging() and self.debuglog and not self.debuglog_printed then
        fn.each(fn.sort(fn.keys(self.debuglog)), fn.bind(GladiusEx.Log, GladiusEx))
        self.debuglog_printed = true
    end

    return group_options
end

-- Follows a ridiculous parser for GetSpellDescription()
local function parse_desc(desc)
    local input = desc
    local output = ""
    local pos = 1
    local char

    local emit,
        read,
        unread,
        read_number,
        read_until,
        read_choice,
        read_muldiv,
        read_if,
        read_spelldesc,
        read_id,
        read_tag

    emit = function(c)
        output = output .. c
    end

    read = function(n)
        if pos > #input then
            return nil
        end
        n = n or 1
        local str = string.sub(input, pos, pos + n - 1)
        pos = pos + n
        return str
    end

    unread = function()
        pos = pos - 1
    end

    read_number = function()
        local accum = ""
        while true do
            local ch = read()
            if ch and ch:match("%d") then
                accum = accum .. ch
            else
                if ch then
                    unread()
                end
                return tonumber(accum)
            end
        end
    end

    read_until = function(u)
        local accum = ""
        while true do
            local char = read()
            if not char or char == u then
                return accum
            else
                accum = accum .. char
            end
        end
    end

    read_choice = function()
        local c1 = read_until(":")
        local c2 = read_until(";")
        return string.format("%s or %s", c1, c2)
    end

    read_muldiv = function()
        read_until(";")
        return read_tag()
    end

    read_if = function()
        local op
        while true do
            local id = read()
            if id == "!" or id == "?" then
                id = read()
            end
            local id2 = read_number()
            op = read()
            if op ~= "&" and op ~= "|" then
                break
            end
        end

        if op == "[" then
            local c1 = parse_desc(read_until("]"))
            op = read()
            local c2
            if op == "[" then
                c2 = parse_desc(read_until("]"))
            elseif op ~= nil then
                unread()
                c2 = read_tag()
            end
            if c1 == c2 then
                return c1
            elseif c1 == "" then
                return string.format("[%s]", c2)
            elseif c2 == "" then
                return string.format("[%s]", c1)
            else
                return string.format("{[%s] or [%s]}", c1, c2)
            end
        else
            assert(false, "read_if: op " .. op)
        end
    end

    read_spelldesc = function()
        local op = read(9)
        local spellid = read_number()
        if op == "spelldesc" then
            return FormatSpellDescription(spellid)
        elseif op == "spellicon" then
            local icon = C_Spell and C_Spell.GetSpellTexture(spellid) or GetSpellInfo(spellid)
            return string.format("|T%s:24|t", icon)
        elseif op == "spellname" then
            local name = C_Spell and C_Spell.GetSpellName(spellid) or GetSpellInfo(spellid)
            return name
        else
            assert(op, "op failed me once again")
        end
    end

    read_id = function()
        unread()
        local id = read_number()
        return read_tag()
    end

    local op_table = {
        ["0"] = read_id,
        ["1"] = read_id,
        ["2"] = read_id,
        ["3"] = read_id,
        ["4"] = read_id,
        ["5"] = read_id,
        ["6"] = read_id,
        ["7"] = read_id,
        ["8"] = read_id,
        ["9"] = read_id,
        ["{"] = function()
            read_until("}")
            return "?"
        end, -- expr
        ["<"] = function()
            read_until(">")
            return "?"
        end, -- variable name
        ["g"] = read_choice, -- gender
        ["G"] = read_choice, -- gender
        ["l"] = read_choice, -- singular/plural
        ["L"] = read_choice, -- singular/plural
        ["?"] = read_if, -- if
        ["*"] = read_muldiv,
        ["/"] = read_muldiv,
        ["@"] = read_spelldesc, -- spelldesc
        ["m"] = function()
            read()
            return "?"
        end, -- followed by a single digit, ends there
        ["M"] = function()
            read()
            return "?"
        end, -- like m
        ["a"] = function()
            read()
            return "?"
        end, -- like m
        ["A"] = function()
            read()
            return "?"
        end, -- like m
        ["o"] = function()
            read()
            return "?"
        end, -- like m
        ["s"] = function()
            read()
            return "?"
        end, -- like m
        ["t"] = function()
            read()
            return "?"
        end, -- like m
        ["T"] = function()
            read()
            return "?"
        end, -- like m
        ["x"] = function()
            read()
            return "?"
        end, -- like m
        ["d"] = function()
            return "?"
        end, -- ends there
        ["D"] = function()
            return "?"
        end, -- same as d
        ["i"] = function()
            return "?"
        end, -- same as d
        ["u"] = function()
            return "?"
        end, -- same as d
        ["n"] = function()
            return "?"
        end -- same as d
    }

    read_tag = function()
        local op = read()
        assert(op, "op could not be read")

        local fn = op_table[op]
        assert(fn, "no fn for " .. tostring(op))

        return fn(op)
    end

    while true do
        local ch = read()
        if not ch then
            break
        elseif ch == "$" then
            emit(read_tag())
        else
            emit(ch)
        end
    end

    return output
end

FormatSpellDescription = function(spellid)
    local text = GetSpellDescription(spellid)

    if GladiusEx:IsDebugging() then
        text = parse_desc(text)
    else
        pcall(
            function()
                text = parse_desc(text)
            end
        )
    end
    return text
end
