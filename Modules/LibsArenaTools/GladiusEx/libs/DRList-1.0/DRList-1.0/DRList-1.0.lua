--[[
Name: DRList-1.0
Description: Diminishing returns categorization. Fork of outdated DRData-1.0.
Website: https://github.com/wardz/DRList-1.0/
Documentation: https://wardz.github.io/DRList-1.0/
Example Usage: https://github.com/wardz/DRList-1.0/wiki/Example-Usage
Dependencies: LibStub
License: MIT
]]

--- DRList-1.0
-- @module DRList-1.0
local MAJOR, MINOR = "DRList-1.0", 77 -- Don't forget to change this in Spells.lua aswell!
local Lib = assert(LibStub, MAJOR .. " requires LibStub."):NewLibrary(MAJOR, MINOR)
if not Lib then return end -- already loaded

local GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
local type = type

Lib.L = {}

-------------------------------------------------------------------------------
-- See CurseForge localization page if you'd like to help translate:
-- https://www.curseforge.com/wow/addons/drlist-1-0/localization
local L = Lib.L
L["DISARMS"] = "Disarms"
L["DISORIENTS"] = "Disorients"
L["INCAPACITATES"] = "Incapacitates"
L["KNOCKBACKS"] = "Knockbacks"
L["ROOTS"] = "Roots"
L["SILENCES"] = "Silences"
L["STUNS"] = "Stuns"
L["TAUNTS"] = "Taunts"
L["FEARS"] = "Fears"
L["RANDOM_ROOTS"] = "Random roots"
L["RANDOM_STUNS"] = "Random stuns"
L["OPENER_STUN"] = "Opener stuns"
L["HORROR"] = "Horrors"
L["SCATTERS"] = "Scatters"
L["DEEP_FREEZE_ROF"] = "DF/RoF Shared"
L["MIND_CONTROL"] = GetSpellName(605) or "Mind Control"
L["FROST_SHOCK"] = GetSpellName(15089) or "Frost Shock"
L["KIDNEY_SHOT"] = GetSpellName(408) or "Kidney Shot"
L["DEATH_COIL"] = GetSpellName(28412) or "Death Coil"
L["UNSTABLE_AFFLICTION"] = GetSpellName(31117) or "Unstable Affliction"
L["CHASTISE"] = GetSpellName(44041) or "Chastise"
L["COUNTERATTACK"] = GetSpellName(19306) or "Counterattack"
L["BIND_ELEMENTAL"] = GetSpellName(76780) or "Bind Elemental"
L["CYCLONE"] = GetSpellName(33786) or "Cyclone"
L["CHARGE"] = GetSpellName(100) or "Charge"

-- luacheck: push ignore 542
local locale = GetLocale()
if locale == "deDE" then
    L["FEARS"] = "Furchteffekte"
    L["KNOCKBACKS"] = "Rückstoßeffekte"
    L["ROOTS"] = "Bewegungsunfähigkeitseffekte"
    L["SILENCES"] = "Stilleeffekte"
    L["STUNS"] = "Betäubungseffekte"
    L["TAUNTS"] = "Spotteffekte"
elseif locale == "frFR" then
    L["FEARS"] = "Peurs"
    L["KNOCKBACKS"] = "Projections"
    L["ROOTS"] = "Immobilisations"
    L["SILENCES"] = "Silences"
    L["STUNS"] = "Etourdissements"
    L["TAUNTS"] = "Provocations"
elseif locale == "koKR" then
    L["DISORIENTS"] = "방향 감각 상실"
    L["INCAPACITATES"] = "행동 불가"
    L["KNOCKBACKS"] = "밀쳐내기"
    L["ROOTS"] = "이동 불가"
    L["SILENCES"] = "침묵"
    L["STUNS"] = "기절"
elseif locale == "ruRU" then
    L["DISARMS"] = "Разоружение"
    L["DISORIENTS"] = "Дезориентация"
    L["FEARS"] = "Опасения"
    L["INCAPACITATES"] = "Паралич"
    L["KNOCKBACKS"] = "Отбрасывание"
    L["RANDOM_ROOTS"] = "Случайные корни"
    L["RANDOM_STUNS"] = "Случайные оглушения"
    L["ROOTS"] = "Сковывание"
    L["SILENCES"] = "Немота"
    L["STUNS"] = "Оглушение"
    L["TAUNTS"] = "Насмешки"
elseif locale == "esES" or locale == "esMX" then
    L["DISARMS"] = "Desarmar"
    L["DISORIENTS"] = "Desorientar"
    L["FEARS"] = "Miedos"
    L["INCAPACITATES"] = "Incapacitar"
    L["KNOCKBACKS"] = "Derribos"
    L["RANDOM_ROOTS"] = "Raíces aleatorias"
    L["RANDOM_STUNS"] = "Aturdir aleatorio"
    L["ROOTS"] = "Raíces"
    L["SILENCES"] = "Silencios"
    L["STUNS"] = "Aturdimientos"
    L["TAUNTS"] = "Provocaciones"
elseif locale == "zhCN" then
    L["DISARMS"] = "缴械"
    L["DISORIENTS"] = "迷惑"
    L["FEARS"] = "恐惧"
    L["INCAPACITATES"] = "瘫痪"
    L["KNOCKBACKS"] = "击退"
    L["RANDOM_ROOTS"] = "随机定身"
    L["RANDOM_STUNS"] = "随机眩晕"
    L["ROOTS"] = "定身"
    L["SILENCES"] = "沉默"
    L["STUNS"] = "昏迷"
    L["TAUNTS"] = "嘲讽"
elseif locale == "zhTW" then
    L["DISARMS"] = "繳械"
    L["DISORIENTS"] = "迷惑"
    L["FEARS"] = "恐懼"
    L["INCAPACITATES"] = "癱瘓"
    L["KNOCKBACKS"] = "擊退"
    L["RANDOM_ROOTS"] = "隨機定身"
    L["RANDOM_STUNS"] = "隨機昏迷"
    L["ROOTS"] = "定身"
    L["SILENCES"] = "沉默"
    L["STUNS"] = "昏迷"
    L["TAUNTS"] = "嘲諷"
end
-- luacheck: pop
-------------------------------------------------------------------------------

-- Check what game version we're running
Lib.gameExpansion = ({
    [WOW_PROJECT_MAINLINE] = "retail",
    [WOW_PROJECT_CLASSIC] = "classic",
    [WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5] = "tbc",
    [WOW_PROJECT_WRATH_CLASSIC or 11] = "wotlk",
    [WOW_PROJECT_CATACLYSM_CLASSIC or 14] = "cata",
    [WOW_PROJECT_MISTS_CLASSIC or 19] = "mop",
})[WOW_PROJECT_ID] or "mop" -- Fallback to "mop" for unknown IDs (likely a new Classic expansion build)

-- How long it takes for a DR to expire, in seconds.
Lib.resetTimes = {
    retail = {
        ["default"] = 18.5, -- Static 18 sec (+0.5 latency) reset time for most categories
        ["npc"] = 20, -- Against mobs it seems to still be dynamic, set it to max
        ["knockback"] = 10.5, -- Knockbacks are immediately immune and only DRs for 10s
    },

    classic = {
        ["default"] = 20, -- Classic has dynamic reset between 15s and 20s, set it to max
        ["npc"] = 20,
    },

    tbc = {
        ["default"] = 20,
        ["npc"] = 20,
    },

    wotlk = {
        ["default"] = 20,
        ["npc"] = 20,
    },

    cata = {
        ["default"] = 20,
        ["npc"] = 20,
    },

    mop = {
        ["default"] = 20,
        ["npc"] = 20,
        ["knockback"] = 10.5,
    },
}

-- List of all DR categories, english -> localized.
Lib.categoryNames = {
    --- @table categoryNames.retail
    retail = {
        ["disorient"] = L.DISORIENTS,
        ["incapacitate"] = L.INCAPACITATES,
        ["silence"] = L.SILENCES,
        ["stun"] = L.STUNS,
        ["root"] = L.ROOTS,
        ["disarm"] = L.DISARMS,
        ["taunt"] = L.TAUNTS,
        ["knockback"] = L.KNOCKBACKS,
    },

    --- @table categoryNames.classic
    classic = {
        ["incapacitate"] = L.INCAPACITATES,
        ["stun"] = L.STUNS,
        ["root"] = L.ROOTS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["random_root"] = L.RANDOM_ROOTS,
        ["fear"] = L.FEARS,
        ["mind_control"] = L.MIND_CONTROL,
        ["frost_shock"] = L.FROST_SHOCK,
        ["kidney_shot"] = L.KIDNEY_SHOT,
    },

    --- @table categoryNames.tbc
    tbc = {
        ["disorient"] = L.DISORIENTS,
        ["incapacitate"] = L.INCAPACITATES,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["random_root"] = L.RANDOM_ROOTS,
        ["root"] = L.ROOTS,
        ["disarm"] = L.DISARMS,
        ["fear"] = L.FEARS,
        ["scatter"] = L.SCATTERS,
        ["mind_control"] = L.MIND_CONTROL,
        ["kidney_shot"] = L.KIDNEY_SHOT,
        ["death_coil"] = L.DEATH_COIL,
        ["unstable_affliction"] = L.UNSTABLE_AFFLICTION,
        ["chastise"] = L.CHASTISE,
        ["counterattack"] = L.COUNTERATTACK,
    },

    --- @table categoryNames.wotlk
    wotlk = {
        ["incapacitate"] = L.INCAPACITATES,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["random_root"] = L.RANDOM_ROOTS,
        ["root"] = L.ROOTS,
        ["disarm"] = L.DISARMS,
        ["fear"] = L.FEARS,
        ["scatter"] = L.SCATTERS,
        ["silence"] = L.SILENCES,
        ["horror"] = L.HORROR,
        ["mind_control"] = L.MIND_CONTROL,
        ["cyclone"] = L.CYCLONE,
        ["charge"] = L.CHARGE,
        ["opener_stun"] = L.OPENER_STUN,
        ["counterattack"] = L.COUNTERATTACK,
        ["taunt"] = L.TAUNTS,
    },

    --- @table categoryNames.cata
    cata = {
        ["incapacitate"] = L.INCAPACITATES,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["random_root"] = L.RANDOM_ROOTS,
        ["root"] = L.ROOTS,
        ["disarm"] = L.DISARMS,
        ["fear"] = L.FEARS,
        ["scatter"] = L.SCATTERS,
        ["silence"] = L.SILENCES,
        ["horror"] = L.HORROR,
        ["mind_control"] = L.MIND_CONTROL,
        ["cyclone"] = L.CYCLONE,
        ["counterattack"] = L.COUNTERATTACK,
        ["bind_elemental"] = L.BIND_ELEMENTAL,
        ["deep_freeze_rof"] = L.DEEP_FREEZE_ROF,
        ["taunt"] = L.TAUNTS,
    },

    --- @table categoryNames.mop
    mop = {
        ["disorient"] = L.DISORIENTS,
        ["incapacitate"] = L.INCAPACITATES,
        ["silence"] = L.SILENCES,
        ["disarm"] = L.DISARMS,
        ["fear"] = L.FEARS,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["root"] = L.ROOTS,
        ["random_root"] = L.RANDOM_ROOTS,
        ["horror"] = L.HORROR,
        ["cyclone"] = L.CYCLONE,
        ["knockback"] = L.KNOCKBACKS,
        ["mind_control"] = L.MIND_CONTROL,
        ["taunt"] = L.TAUNTS,
    },
}

-- Categories that have DR against normal mobs.
Lib.categoriesPvE = {
    retail = {
        ["taunt"] = L.TAUNTS,
        ["stun"] = L.STUNS,
    },

    classic = {
        ["stun"] = L.STUNS,
        ["kidney_shot"] = L.KIDNEY_SHOT,
    },

    tbc = {
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["kidney_shot"] = L.KIDNEY_SHOT,
    },

    wotlk = {
        ["taunt"] = L.TAUNTS,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["opener_stun"] = L.OPENER_STUN,
    },

    cata = {
        ["taunt"] = L.TAUNTS,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["cyclone"] = L.CYCLONE,
    },

    mop = {
        ["taunt"] = L.TAUNTS,
        ["stun"] = L.STUNS,
        ["random_stun"] = L.RANDOM_STUNS,
        ["cyclone"] = L.CYCLONE,
    },
}

-- Successive diminished durations
Lib.diminishedDurations = {
    retail = {
        -- Decreases by 50%, immune at the 4th application
        ["default"] = { 0.50, 0.25 },
        -- Decreases by 35%, immune at the 5th application
        ["taunt"] = { 0.65, 0.42, 0.27 },
        -- Immediately immune
        ["knockback"] = {},
    },

    classic = {
        ["default"] = { 0.50, 0.25 },
    },

    tbc = {
        ["default"] = { 0.50, 0.25 },
    },

    wotlk = {
        ["default"] = { 0.50, 0.25 },
        ["taunt"] = { 0.65, 0.42, 0.27 },
    },

    cata = {
        ["default"] = { 0.50, 0.25 },
        ["taunt"] = { 0.65, 0.42, 0.27 },
    },

    mop = {
        ["default"] = { 0.50, 0.25 },
        ["taunt"] = { 0.65, 0.42, 0.27 },
        ["knockback"] = {},
    },
}

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

--- Get table of all spells that have DR.
-- Key is the spellID, and value is the unlocalized DR category string.
-- Value is instead a table of strings for spells that have shared DRs.
-- Tables are read-only. Copy them if you need to modify data.
-- @see GetCategoryBySpellID
-- @treturn table {number=string|table}
function Lib:GetSpells()
    return Lib.spellList
end

--- Get table of all DR categories.
-- Key is unlocalized name used for API functions, value is localized name used for UI.
-- Tables are read-only. Copy them if you need to modify data.
-- Note: You might want to ignore the 'taunt' category if your addon only tracks player DRs.
-- @treturn table {string=string}
function Lib:GetCategories()
    return Lib.categoryNames[Lib.gameExpansion]
end

--- Get table of all categories that DRs in PvE.
-- Key is unlocalized name used for API functions, value is localized name used for UI.
-- Tables are read-only. Copy them if you need to modify data.
-- Note: In retail, some special mobs have DR on all categories, you need to check for this manually;
-- see UnitClassification() and UnitIsQuestBoss(). Player pets have DR on all categories.
-- @treturn table {string=string}
function Lib:GetPvECategories()
    return Lib.categoriesPvE[Lib.gameExpansion]
end

--- Get the default DR reset time value or a category specific reset time.
-- Passing in the category is now recommended as reset times may differ between categories.
-- @usage local expirationTime = GetTime() + DRList:GetResetTime("stun") -- Compare against GetTime() later on
-- @usage C_Timer.After(DRList:GetResetTime("stun"), function() print("DR finished") end)
-- @tparam[opt="default"] string category Unlocalized category name, or "npc" for PvE timer.
-- @treturn number Reset time in seconds
function Lib:GetResetTime(category)
    return Lib.resetTimes[Lib.gameExpansion][category or "default"] or Lib.resetTimes[Lib.gameExpansion].default
end

--- Get DR category by spellID.
-- This is the primary function to check if a spell/debuff has a DR. See wiki for full example usage.
-- @usage
-- local category, categories = DRList:GetCategoryBySpellID(1234)
-- if not category then return end
-- if categories then for i = 1, #categories do print(categories[i]) end else print(category) end
-- @tparam number spellID Debuff spellId
-- @treturn ?string The unlocalized category name.
-- @treturn ?{string,...} Read-only array with multiple categories if spellID has any shared DR categories. (Note: array includes main category too)
function Lib:GetCategoryBySpellID(spellID)
    local category = Lib.spellList[spellID]
    if category and type(category) == "table" then -- Shared DRs
        return category[1], category -- Return the first element as the main category (for backward compatibility)
    end

    return category
end

--- Get localized category name.
-- @tparam string category Unlocalized category name
-- @treturn ?string|nil The localized category name
function Lib:GetCategoryLocalization(category)
    return Lib.categoryNames[Lib.gameExpansion][category]
end

--- Check if a category has DR against mobs.
-- Note: In retail, some special mobs have DR on all categories, you need to check for this manually;
-- see UnitClassification() and UnitIsQuestBoss(). Player pets have DR on all categories.
-- @tparam string category Unlocalized category name
-- @treturn bool
function Lib:IsPvECategory(category)
    return Lib.categoriesPvE[Lib.gameExpansion][category] and true or false -- make sure bool is always returned here
end

--- Get a specific diminished duration value.
-- Passing in the category is now recommended as diminished durations may differ between categories.
-- Any unknown categories (unless omitted or nil) will alway return 0 here, unlike NextDR().
-- @tparam number diminished How many times the DR has been applied so far
-- @tparam[opt="default"] string category Unlocalized category name
-- @usage local duration = DRList:GetNextDR(1, "stun") -- 0.50 (half aura duration)
-- @usage local duration = DRList:GetNextDR(2, "stun") -- 0.25 (quarter aura duration)
-- @usage local duration = DRList:GetNextDR(3, "stun") -- 0.00 (zero aura duration / immune)
-- @usage local duration = DRList:GetNextDR(1, "knockback") -- 0.00 (immediately immune)
-- @treturn number Diminished duration value or 0 for invalid arguments
function Lib:GetNextDR(diminished, category)
    local durations = Lib.diminishedDurations[Lib.gameExpansion][category or "default"]
    if not durations and Lib.categoryNames[Lib.gameExpansion][category] then
        -- Redirect to default only when a valid category is passed
        durations = Lib.diminishedDurations[Lib.gameExpansion]["default"]
    end

    return durations and durations[diminished] or 0
end

--- Get the next successive diminished duration value.
-- Same behavior as the DRData-1.0 version. Passing in the category is now recommended as durations may vary between categories.
-- @tparam number duration The current diminished duration value. Throws error if not a number.
-- @tparam[opt="default"] string category Unlocalized category name
-- @usage local duration = DRList:NextDR(0.50) -- returns 0.25 (quarter aura duration)
-- @usage
-- local duration = 1.0 -- initial full aura duration
-- duration = DRList:NextDR(duration, "stun") -- 0.50 (half aura duration)
-- duration = DRList:NextDR(duration, "stun") -- 0.25 (quarter aura duration)
-- duration = DRList:NextDR(duration, "stun") -- 0.00 (zero aura duration / immune)
-- @treturn number Diminished duration value
function Lib:NextDR(duration, category)
    local durations = Lib.diminishedDurations[Lib.gameExpansion][category or "default"] or Lib.diminishedDurations[Lib.gameExpansion].default

    for i = 1, #durations do
        if duration > durations[i] then
            return durations[i]
        end
    end

    return 0
end

do
    local next = _G.next

    local function CategoryIterator(category, index)
        local spellList, newCategory = Lib.spellList

        repeat
            index, newCategory = next(spellList, index)
            if index then
                if newCategory == category then
                    return index, category
                elseif type(newCategory) == "table" then
                    for i = 1, #newCategory do -- shared categories table
                        if newCategory[i] == category then
                            return index, category
                        end
                    end
                end
            end
        until not index
    end

    --- Iterate through the spells of a given category.
    -- Pass nil to iterate through all spells instead.
    -- Note: In classic this also iterates through every single spell rank. Check the spell names if you dont want duplicates.
    -- @tparam string|nil category Unlocalized category name
    -- @usage for spellID, category in DRList:IterateSpellsByCategory("root") do print(spellID) end
    -- @return Iterator function
    function Lib:IterateSpellsByCategory(category)
        if category then
            return CategoryIterator, category
        else
            return next, Lib.spellList
        end
    end
end

-- Keep same API as DRData-1.0 for easier transitions
Lib.GetCategoryName = Lib.GetCategoryLocalization
Lib.IsPVE = Lib.IsPvECategory
Lib.GetSpellCategory = Lib.GetCategoryBySpellID
Lib.IterateSpells = Lib.IterateSpellsByCategory
--Lib.IterateProviders = Lib.IterateSpellsByCategory -- OBSOLETE
--Lib.GetProviders = Lib.GetSpells() -- OBSOLETE
Lib.RESET_TIME = Lib.resetTimes[Lib.gameExpansion].default
Lib.pveDR = Lib.categoriesPvE[Lib.gameExpansion]
