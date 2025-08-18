local interruptSpells = {
    [1766] = 5,  -- Kick (Rogue)
    [2139] = 6,  -- Counterspell (Mage)
    [6552] = 4,  -- Pummel (Warrior)
    [132409] = 6, -- Spell Lock (Warlock)
    [19647] = 6, -- Spell Lock (Warlock, pet)
    [47528] = 4,  -- Mind Freeze (Death Knight)
    [57994] = 3,  -- Wind Shear (Shaman)
    [91807] = 2,  -- Shambling Rush (Death Knight)
    [96231] = 4,  -- Rebuke (Paladin)
    [93985] = 4,  -- Skull Bash (Druid)
    [116705] = 4, -- Spear Hand Strike (Monk)
    [147362] = 3, -- Counter Shot (Hunter)
    [31935] = 3,  -- Avenger's Shield (Paladin)
    [78675] = 5, -- Solar Beam
    [113286] = 5, -- Solar Beam (Symbiosis)
    [26679] = 5, 	-- Deadly Throw (Rogue) (4-6 sec interrupt depending on combos(3-5))

	[33871] = 8, 	-- Shield Bash (Warrior)
	[24259] = 6, 	-- Spell Lock (Warlock)
	[43523] = 5,	-- Unstable Affliction (Warlock)
	--[16979] = 4, 	-- Feral Charge (Druid)
    [119911] = 6, -- Optical Blast (Warlock Observer)
    [115781] = 6, -- Optical Blast (Warlock Observer)
    [102060] = 4, -- Disrupting Shout
    [26090] = 2, -- Pummel (Gorilla)
    [50479] = 2, -- Nethershock
    [97547] = 5, -- Solar Beam
}

-- Buffs that reduce interrupt duration
local spellLockReducer = {
    [317920] = 0.7, -- Concentration Aura
    [234084] = 0.5, -- Moon and Stars
    [383020] = 0.5, -- Tranquil Air
}

local interruptEvents = {
    ["SPELL_INTERRUPT"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_AURA_APPLIED"] = true, -- For Deadly Throw
}

local spellList = {
    -- *** Incapacitate Effects ***
    [2637]   = "Asleep", -- Hibernate
    [3355]   = "Frozen", -- Freezing Trap Effect
    [19386]  = "Asleep", -- Wyvern Sting
    [118]    = "Polymorphed", -- Polymorph
    [28271]  = "Polymorphed", -- Polymorph: Turtle
    [28272]  = "Polymorphed", -- Polymorph: Pig
    [61025]  = "Polymorphed", -- Polymorph: Serpent
    [61721]  = "Polymorphed", -- Polymorph: Rabbit
    [61780]  = "Polymorphed", -- Polymorph: Turkey
    [61305]  = "Polymorphed", -- Polymorph: Black Cat
    [82691]  = "Frozen", -- Ring of Frost
    [115078] = "Incapacitated", -- Paralysis
    [20066]  = "Incapacitated", -- Repentance
    [9484]   = "Shackled", -- Shackle Undead
    [1776]   = "Gouged", -- Gouge
    [6770]   = "Sapped", -- Sap
    [76780]  = "Incapacitated", -- Bind Elemental
    [51514]  = "Hexed", -- Hex
    [710]    = "Incapacitated", -- Banish
    [107079] = "Incapacitated", -- Quaking Palm (Racial)

    -- *** Disorient Effects ***
    --[99]     = "Disoriented", -- Disorienting Roar (MoP only, 30sec debuff in cata)
    [19503]  = "Disoriented", -- Scatter Shot
    [31661]  = "Disoriented", -- Dragon's Breath
    [123393] = "Disoriented", -- Glyph of Breath of Fire
    [88625]  = "Disoriented", -- Holy Word: Chastise
    [105421] = "Disoriented", -- Blinding Light

    -- *** Controlled Stun Effects ***
    [108194] = "Stunned", -- Asphyxiate
    [91800]  = "Stunned", -- Gnaw (Ghoul)
    [91797]  = "Stunned", -- Monstrous Blow (Dark Transformation Ghoul)
    [115001] = "Stunned", -- Remorseless Winter
    [102795] = "Stunned", -- Bear Hug
    [5211]   = "Stunned", -- Mighty Bash
    [9005]   = "Stunned", -- Pounce
    [22570]  = "Stunned", -- Maim
    [113801] = "Stunned", -- Bash (Treants)
    [117526] = "Stunned", -- Binding Shot
    [24394]  = "Stunned", -- Intimidation
    [126246] = "Stunned", -- Lullaby (Crane pet) -- TODO: verify category
    [126423] = "Stunned", -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
    [126355] = "Stunned", -- Quill (Porcupine pet) -- TODO: verify category
    [90337]  = "Stunned", -- Bad Manner (Monkey)
    [56626]  = "Stunned", -- Sting (Wasp)
    [50519]  = "Stunned", -- Sonic Blast
    [118271] = "Stunned", -- Combustion
    [44572]  = "Stunned", -- Deep Freeze
    [119392] = "Stunned", -- Charging Ox Wave
    [122242] = "Stunned", -- Clash
    [120086] = "Stunned", -- Fists of Fury
    [119381] = "Stunned", -- Leg Sweep
    [115752] = "Stunned", -- Blinding Light (Glyphed)
    [853]    = "Stunned", -- Hammer of Justice
    [110698] = "Stunned", -- Hammer of Justice (Symbiosis)
    [119072] = "Stunned", -- Holy Wrath
    [105593] = "Stunned", -- Fist of Justice
    [408]    = "Stunned", -- Kidney Shot
    [1833]   = "Stunned", -- Cheap Shot
    [118345] = "Stunned", -- Pulverize (Primal Earth Elemental)
    [118905] = "Stunned", -- Static Charge (Capacitor Totem)
    [89766]  = "Stunned", -- Axe Toss (Felguard)
    [22703]  = "Stunned", -- Inferno Effect
    [30283]  = "Stunned", -- Shadowfury
    [132168] = "Stunned", -- Shockwave
    [107570] = "Stunned", -- Storm Bolt
    [20549]  = "Stunned", -- War Stomp (Racial)
    [7922]   = "Stunned", -- Charge Stun
    [58861]  = "Stunned", -- Bash (Spirit Wolves)
    [12809]  = "Stunned", -- Concussion Blow
    [60995]  = "Stunned", -- Demon Charge
    [47481]  = "Stunned", -- Gnaw (Pet variant)
    [85388]  = "Stunned", -- Throwdown
    [20253]  = "Stunned", -- Intercept
    [30153]  = "Stunned", -- Pursuit
    [6572]   = "Stunned", -- Ravage
    [39796]  = "Stunned", -- Stoneclaw Stun
    [34510]  = "Stunned", -- Stun (proc)
    [12355]  = "Stunned", -- Impact
    [23454]  = "Stunned", -- Stun (generic)
    [132169] = "Stunned", -- Storm Bolt
    [96201] = "Stunned", -- Web Wrap
    [122057] = "Stunned", -- Clash
    [15618] = "Stunned", -- Snap Kick
    [127361] = "Stunned", -- Bear Hug
    [102546]  = "Stunned", -- Pounce
    --[19577]  = "Stunned", -- Intimidation (?)

    -- *** Non-controlled Stun Effects ***
    [113953] = "Stunned", -- Paralysis
    [118895] = "Stunned", -- Dragon Roar
    [77505]  = "Stunned", -- Earthquake
    [100]    = "Stunned", -- Charge
    [118000] = "Stunned", -- Dragon Roar

    -- *** Fear Effects ***
    [113004] = "Feared", -- Intimidating Roar (Symbiosis)
    [113056] = "Feared", -- Intimidating Roar (Symbiosis 2)
    [1513]   = "Feared", -- Scare Beast
    [10326]  = "Feared", -- Turn Evil
    [145067] = "Feared", -- Turn Evil (Evil is a Point of View)
    [1450679] ="Feared", -- Turn Evil
    [8122]   = "Feared", -- Psychic Scream
    [113792] = "Feared", -- Psychic Terror (Psyfiend)
    [2094]   = "Blinded", -- Blind (Fear DR)
    [5782]   = "Feared", -- Fear
    [130616] = "Feared", -- Fear
    [118699] = "Feared", -- Fear 2
    [5484]   = "Feared", -- Howl of Terror
    [115268] = "Seduced", -- Mesmerize (Shivarra)
    [6358]   = "Seduced", -- Seduction (Succubus)
    [104045] = "Feared", -- Sleep (Metamorphosis) -- TODO: verify this is the correct category
    [5246]   = "Feared", -- Intimidating Shout
    [20511]  = "Feared", -- Intimidating Shout (secondary targets
    [87204] = "Feared",  -- Sin and Punishment

    -- *** Controlled Root Effects ***
    [96294]  = "Rooted", -- Chains of Ice (Chilblains Root)
    [339]    = "Rooted", -- Entangling Roots
    [113275] = "Rooted", -- Entangling Roots (Symbiosis)
    [102359] = "Rooted", -- Mass Entanglement
    [19975]  = "Rooted", -- Nature's Grasp
    [128405] = "Rooted", -- Narrow Escape
    --[53148]  = "Rooted", -- Charge (Tenacity pet)
    [90327]  = "Rooted", -- Lock Jaw (Dog)
    [54706]  = "Rooted", -- Venom Web Spray (Silithid)
    [50245]  = "Rooted", -- Pin (Crab)
    [4167]   = "Rooted", -- Web (Spider)
    [33395]  = "Rooted", -- Freeze (Water Elemental)
    [122]    = "Rooted", -- Frost Nova
    [110693] = "Rooted", -- Frost Nova (Symbiosis)
    [116706] = "Rooted", -- Disable
    [87194]  = "Rooted", -- Glyph of Mind Blast
    [114404] = "Rooted", -- Void Tendrils
    [115197] = "Rooted", -- Partial Paralysis
    [63685]  = "Rooted", -- Freeze (Frost Shock)
    [107566] = "Rooted", -- Staggering Shout
    [113770] = "Rooted", -- Entangling Roots
    [105771] = "Rooted", -- Warbringer
    [53148] = "Rooted", -- Charge
    [136634] = "Rooted", -- Narrow Escape
    --[127797] = "Rooted", -- Ursol's Vortex
    [81210] = "Rooted", -- Net
    [91807] = "Rooted",   -- Shambling Rush

    -- *** Non-controlled Root Effects ***
    [64803]  = "Rooted", -- Entrapment
    [111340] = "Rooted", -- Ice Ward
    [123407] = "Rooted", -- Spinning Fire Blossom
    [64695]  = "Rooted", -- Earthgrab Totem
    [25999]  = "Rooted", -- Boar Charge
    [19306]  = "Rooted", -- Counterattack
    [115757] = "Rooted", -- Frost Nova (alt?)
    [35963]  = "Rooted", -- Improved Wing Clip
    [19185]  = "Rooted", -- Entrapment (Hunter talent version)
    [23694]  = "Rooted", -- Improved Hamstring
    [135373] = "Rooted", -- Entrapment
    [45334]  = "Rooted", -- Immobilized

    -- *** Disarm Weapon Effects ***
    [50541]  = "Disarmed", -- Clench (Scorpid)
    [91644]  = "Disarmed", -- Snatch (Bird of Prey)
    [117368] = "Disarmed", -- Grapple Weapon
    [126458] = "Disarmed", -- Grapple Weapon (Symbiosis)
    [137461] = "Disarmed", -- Ring of Peace (Disarm effect)
    [64058]  = "Disarmed", -- Psychic Horror (Disarm Effect)
    [51722]  = "Disarmed", -- Dismantle
    [118093] = "Disarmed", -- Disarm (Voidwalker/Voidlord)
    [676]    = "Disarmed", -- Disarm
    [15752]  = "Disarmed", -- Disarm (Warrior talent)
    [14251]  = "Disarmed", -- Riposte
    [142896] = "Disarmed", -- Disarmed

    -- *** Silence Effects ***
    -- [108194] = "Silenced", -- Asphyxiate (TODO: check silence id)
    [47476]  = "Silenced", -- Strangulate
    [114238] = "Silenced", -- Glyph of Fae Silence
    [34490]  = "Silenced", -- Silencing Shot
    [102051] = "Silenced+", -- Frostjaw
    [55021]  = "Silenced", -- Counterspell
    [137460] = "Silenced", -- Ring of Peace (Silence effect)
    [116709] = "Silenced", -- Spear Hand Strike
    [31935]  = "Silenced", -- Avenger's Shield
    [15487]  = "Silenced", -- Silence
    [1330]   = "Silenced", -- Garrote
    [24259]  = "Silenced", -- Spell Lock
    [115782] = "Silenced", -- Optical Blast (Observer)
    [18498]  = "Silenced", -- Silenced - Gag Order
    [50613]  = "Silenced", -- Arcane Torrent (Racial, Runic Power)
    [28730]  = "Silenced", -- Arcane Torrent (Racial, Mana)
    [25046]  = "Silenced", -- Arcane Torrent (Racial, Energy)
    [69179]  = "Silenced", -- Arcane Torrent (Racial, Rage)
    [80483]  = "Silenced", -- Arcane Torrent (Racial, Focus)
    [18469]  = "Silenced", -- Improved Counterspell (Mage)
    [18425]  = "Silenced", -- Improved Kick (Rogue)
    [43523]  = "Silenced", -- Unstable Affliction (Silence effect)
    [106839] = "Silenced", -- Skull Bash (Feral)
    [147362] = "Silenced", -- Countershot (Hunter)
    [171138] = "Silenced", -- Shadow Lock (Warlock)
    [183752] = "Silenced", -- Consume Magic (Demon Hunter)
    [187707] = "Silenced", -- Muzzle (Hunter)
    [212619] = "Silenced", -- Call Felhunter (Warlock)
    [231665] = "Silenced", -- Avenger's Shield (Ret/Prot Paladin)
    [351338] = "Silenced", -- Quell (Evoker)
    [97547]  = "Silenced", -- Solar Beam
    [78675] =  "Silenced", -- Solar Beam
    [113286] = "Silenced", -- Solar Beam
    [81261] =  "Silenced", -- Solar Beam
    [142895] = "Silenced", -- Ring of Peace(?) Silence
    [31117]  = "Silenced", -- Unstable Affliction

    -- *** Horror Effects ***
    [64044]  = "Horrified", -- Psychic Horror
    [137143] = "Horrified", -- Blood Horror
    [6789]   = "Horrified", -- Death Coil

    -- *** Mind Control Effects ***
    [605]   = "Mind Controlled", -- Dominate Mind
    [13181] = "Mind Controlled", -- Gnomish Mind Control Cap (Item)
    [67799] = "Mind Controlled", -- Mind Amplification Dish (Item)

    -- *** Spells that DRs with itself only ***
    [33786]  = "Cycloned", -- Cyclone
    [113506] = "Cycloned", -- Cyclone (Symbiosis)


    -- ##########################
    -- Cata Bonus Ones, mop above, needs verifying
    -- ##########################
    -- *** Incapacitate Effects ***
    [49203] = "Incapacitated", -- Hungering Cold

    -- *** Controlled Stun Effects ***
    [93433] = "Stunned", -- Burrow Attack (Worm)
    [83046] = "Stunned", -- Improved Polymorph (Rank 1)
    [83047] = "Stunned", -- Improved Polymorph (Rank 2)
    --[2812]  = "Stunned", -- Holy Wrath
    --[88625] = "Stunned", -- Holy Word: Chastise
    [93986] = "Stunned", -- Aura of Foreboding
    [54786] = "Stunned", -- Demon Leap
    [46968] = "Stunned", -- Shockwave

    -- *** Non-controlled Stun Effects ***
    [85387] = "Stunned", -- Aftermath
    [15283] = "Stunned", -- Stunning Blow (Weapon Proc)
    [56]    = "Stunned", -- Stun (Weapon Proc)

    -- *** Fear Effects ***
    [5134]  = "Feared", -- Flash Bomb Fear (Item)

    -- *** Controlled Root Effects ***
    [96293] = "Rooted", -- Chains of Ice (Chilblains Rank 1)
    [87193] = "Rooted", -- Paralysis
    [39965] = "Rooted", -- Frost Grenade (Item)
    [55536] = "Rooted", -- Frostweave Net (Item)

    -- *** Non-controlled Root Effects ***
    [47168] = "Rooted", -- Improved Wing Clip
    [83301] = "Rooted", -- Improved Cone of Cold (Rank 1)
    [83302] = "Rooted", -- Improved Cone of Cold (Rank 2)
    [55080] = "Rooted", -- Shattered Barrier (Rank 1)
    [83073] = "Rooted", -- Shattered Barrier (Rank 2)
    [50479] = "Silenced", -- Nether Shock (Nether Ray)
    [86759] = "Silenced", -- Silenced - Improved Kick (Rank 2)

    [13327] = "Incapacitated", -- Reckless Charge (Item)
    [4064]  = "Incapacitated", -- Rough Copper Bomb (Item)
    [4065]  = "Incapacitated", -- Large Copper Bomb (Item)
    [4066]  = "Incapacitated", -- Small Bronze Bomb (Item)
    [4067]  = "Incapacitated", -- Big Bronze Bomb (Item)
    [4068]  = "Incapacitated", -- Iron Grenade (Item)
    [12421] = "Incapacitated", -- Mithril Frag Bomb (Item)
    [4069]  = "Incapacitated", -- Big Iron Bomb (Item)
    [12562] = "Incapacitated", -- The Big One (Item)
    [12543] = "Incapacitated", -- Hi-Explosive Bomb (Item)
    [19769] = "Incapacitated", -- Thorium Grenade (Item)
    [19784] = "Incapacitated", -- Dark Iron Bomb (Item)
    [30216] = "Incapacitated", -- Fel Iron Bomb (Item)
    [30461] = "Incapacitated", -- The Bigger One (Item)
    [30217] = "Incapacitated", -- Adamantite Grenade (Item)
    [67769] = "Incapacitated", -- Cobalt Frag Bomb (Item)
    [67890] = "Incapacitated", -- Cobalt Frag Bomb (Item, Frag Belt)
    [54466] = "Incapacitated", -- Saronite Grenade (Item)

    [13099] = "Rooted", -- Net-o-Matic
    [13119] = "Rooted", -- Net-o-Matic
    [13120] = "Rooted", -- Net-o-Matic
    [13138] = "Rooted", -- Net-o-Matic
    [13139] = "Rooted", -- Net-o-Matic
    [16566] = "Rooted", -- Net-o-Matic
    [52825] = "Rooted", -- Swoop
    [1090] = "Asleep", -- Magic Dust
    [835] = "Stunned", -- Tidal Charm
    [15753] = "Stunned", -- Linken's Boomerang Stun
    [13237] = "Stunned", -- Goblin Mortar trinket
    [18798] = "Stunned", -- Freezing Band
    [32752] = "Stunned", -- Summoning Disorientation
    [50318] = "Silenced", -- Serenity Dust (moth pet silence)

}

local hardCCSet = {
    ["Stunned"] = true,
    ["Feared"] = true,
    ["Horrified"] = true,
    ["Cycloned"] = true,
    ["Incapacitated"] = true,
    ["Mind Controlled"] = true,
    ["Disoriented"] = true,
    ["Polymorphed"] = true,
    ["Hexed"] = true,
    ["Frozen"] = true,
    ["Blinded"] = true,
    ["Seduced"] = true,
    ["Asleep"] = true,
    ["Shackled"] = true,
    ["Gouged"] = true,
    ["Sapped"] = true,
}

local function isHardCC(type)
    return hardCCSet[type]
end

-- Poor and quick implementation of LoC frame before MoP Beta finally added native. Meant to improve later but ya know..
function BBF.SetupLoCFrame()
    if not BetterBlizzFramesDB.enableLoCFrame then return end
    if not BBF.isMoP then
        spellList[2812]  = "Stunned" -- Holy Wrath
        spellList[64346] = "Disarmed" -- Fiery Payback (Fire Mage Disarm)
        spellList[19482] = "Stunned" -- War Stomp Doom Guard Stun
        --spellList[20170]  = "Stunned" -- Seal of Justice (proc)
    else
        spellList[99] = "Disoriented" -- Disorienting Roar (MoP only, 30sec debuff in cata)
    end
    local f = CreateFrame("Frame")

    local parentFrame = CreateFrame("Frame", "BBFLossOfControlParentFrame", UIParent)
    parentFrame:SetScale(BetterBlizzFramesDB.lossOfControlScale or 1)

    local iconOnlyMode = BetterBlizzFramesDB.lossOfControlIconOnly

    -- === Frame Creation ===
    local frame = CreateFrame("Frame", "BBFLossOfControlFrame", parentFrame, "BackdropTemplate")
    frame:SetSize(256, 58)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    frame:Hide()

    if LossOfControlFrame then
        LossOfControlFrame:SetScale(BetterBlizzFramesDB.lossOfControlScale or 1)
        --LossOfControlFrame:ClearAllPoints()
        --LossOfControlFrame:SetPoint("CENTER", UIParent, "CENTER", BetterBlizzCCDB.xPos or 0, BetterBlizzCCDB.yPos or 0)
    end

    -- === Pop-In Animation with Overshoot + Bounce ===
    frame.fadeInScale = frame:CreateAnimationGroup()

    -- Fade In
    frame.fadeIn = frame.fadeInScale:CreateAnimation("Alpha")
    frame.fadeIn:SetFromAlpha(0)
    frame.fadeIn:SetToAlpha(1)
    frame.fadeIn:SetDuration(0.10)
    frame.fadeIn:SetOrder(1)
    frame.fadeIn:SetSmoothing("OUT")

    -- First scale: overshoot (larger than normal)
    frame.scaleOvershoot = frame.fadeInScale:CreateAnimation("Scale")
    frame.scaleOvershoot:SetScaleFrom(0.85, 0.85)
    frame.scaleOvershoot:SetScaleTo(1.1, 1.1) -- slight overshoot
    frame.scaleOvershoot:SetDuration(0.08)
    frame.scaleOvershoot:SetOrder(1)
    frame.scaleOvershoot:SetSmoothing("OUT")

    -- Second scale: settle back to normal
    frame.scaleSettle = frame.fadeInScale:CreateAnimation("Scale")
    frame.scaleSettle:SetScaleFrom(1.1, 1.1)
    frame.scaleSettle:SetScaleTo(1, 1)
    frame.scaleSettle:SetDuration(0.07)
    frame.scaleSettle:SetOrder(2)
    frame.scaleSettle:SetSmoothing("IN")

    frame.fadeInScale:SetToFinalAlpha(true)

    -- === Fade-Out + Shrink Animation ===
    frame.fadeOutShrink = frame:CreateAnimationGroup()

    frame.fadeOut = frame.fadeOutShrink:CreateAnimation("Alpha")
    frame.fadeOut:SetFromAlpha(1)
    frame.fadeOut:SetToAlpha(0)
    frame.fadeOut:SetDuration(0.07)
    frame.fadeOut:SetOrder(1)
    frame.fadeOut:SetSmoothing("IN")

    frame.scaleDown = frame.fadeOutShrink:CreateAnimation("Scale")
    frame.scaleDown:SetScaleFrom(1, 1)
    frame.scaleDown:SetScaleTo(0.85, 0.85)
    frame.scaleDown:SetDuration(0.07)
    frame.scaleDown:SetOrder(1)
    frame.scaleDown:SetSmoothing("IN")

    frame.fadeOutShrink:SetToFinalAlpha(false)

    -- Hide the frame after animation ends
    frame.fadeOutShrink:SetScript("OnFinished", function()
        frame:Hide()
        frame:SetAlpha(1)
        frame:SetScale(1)
        frame.duration = nil
        frame.expiration = nil
        frame.lockedBy = nil
        frame.returnEarly = nil
    end)



    -- === Red Lines ===
    frame.RedLineTop = frame:CreateTexture(nil, "BACKGROUND")
    frame.RedLineTop:SetTexture("Interface\\Cooldown\\Loc-RedLine")
    frame.RedLineTop:SetSize(iconOnlyMode and 70 or 236, 27)
    frame.RedLineTop:SetPoint("BOTTOM", frame, "TOP")

    frame.RedLineBottom = frame:CreateTexture(nil, "BACKGROUND")
    frame.RedLineBottom:SetTexture("Interface\\Cooldown\\Loc-RedLine")
    frame.RedLineBottom:SetSize(iconOnlyMode and 70 or 236, 27)
    frame.RedLineBottom:SetPoint("TOP", frame, "BOTTOM")
    frame.RedLineBottom:SetTexCoord(0, 1, 1, 0)

    -- === Background ===
    frame.blackBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.blackBg:SetTexture("Interface\\Cooldown\\loc-shadowbg")
    frame.blackBg:SetPoint("TOPLEFT", frame.RedLineTop, "BOTTOMLEFT")
    frame.blackBg:SetPoint("BOTTOMRIGHT", frame.RedLineBottom, "TOPRIGHT")

    -- === Icon ===
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetSize(48, 48)
    frame.Icon:SetPoint("CENTER", frame, "CENTER", iconOnlyMode and 0 or -70, 0)

    if BetterBlizzFramesDB.showCooldownOnLoC or iconOnlyMode then
        frame.Icon.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        frame.Icon.Cooldown:SetAllPoints(frame.Icon)
    end

    -- === Secondary Icon (e.g. root/silence/disarm) ===
    -- Create the cooldown frame
    frame.SecondaryIcon = CreateFrame("Frame", nil, frame)
    frame.SecondaryIcon:SetSize(35, 35)
    frame.SecondaryIcon:SetPoint("RIGHT", frame.Icon, "LEFT", -4, 0)

    frame.SecondaryIcon.Cooldown = CreateFrame("Cooldown", nil, frame.SecondaryIcon, "CooldownFrameTemplate")
    frame.SecondaryIcon.Cooldown:SetAllPoints(frame.SecondaryIcon)

    local cooldownSwipe = frame.SecondaryIcon:GetRegions()
    if cooldownSwipe then
        cooldownSwipe:SetAllPoints(frame.SecondaryIcon)
    end

    -- Add your own icon on top
    frame.SecondaryIcon.icon = frame.SecondaryIcon:CreateTexture(nil, "ARTWORK")
    frame.SecondaryIcon.icon:SetAllPoints()
    frame.SecondaryIcon.icon:SetTexture(nil)

    -- === School Text for Main Icon ===
    frame.Icon.SchoolText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.Icon.SchoolText:SetPoint("BOTTOM", frame.Icon, "BOTTOM", 0, 1)
    frame.Icon.SchoolText:SetJustifyH("CENTER")
    frame.Icon.SchoolText:SetTextColor(1, 1, 1)
    frame.Icon.SchoolText:SetFont("Interface/Addons/BetterBlizzPlates/media/Prototype.ttf", 11, "OUTLINE")

    -- === School Text for Secondary Icon ===
    frame.SecondaryIcon.SchoolText = frame.SecondaryIcon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.SecondaryIcon.SchoolText:SetPoint("BOTTOM", frame.SecondaryIcon, "BOTTOM", 0, 1)
    frame.SecondaryIcon.SchoolText:SetJustifyH("CENTER")
    frame.SecondaryIcon.SchoolText:SetTextColor(1, 1, 1)
    frame.SecondaryIcon.SchoolText:SetFont("Interface/Addons/BetterBlizzPlates/media/Prototype.ttf", 9, "OUTLINE")
    frame.SecondaryIcon.SchoolText:SetDrawLayer("OVERLAY", 7) -- ensures it's above cooldown

    -- === CC Type Text ===
    frame.AbilityName = frame:CreateFontString(nil, "ARTWORK", "MovieSubtitleFont")
    frame.AbilityName:SetPoint("TOPLEFT", frame.Icon, "TOPRIGHT", 5, -4)
    frame.AbilityName:SetSize(0, 20)

    -- === Time Left ===
    frame.TimeLeft = CreateFrame("Frame", nil, frame)
    frame.TimeLeft:SetSize(200, 20)
    frame.TimeLeft:SetPoint("TOPLEFT", frame.AbilityName, "BOTTOMLEFT")

    frame.TimeLeft.NumberText = frame.TimeLeft:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    frame.TimeLeft.NumberText:SetPoint("LEFT", frame.TimeLeft, "LEFT", 0, -3)
    frame.TimeLeft.NumberText:SetShadowOffset(2, -2)
    frame.TimeLeft.NumberText:SetTextColor(1, 1, 1)

    frame.AbilityName:SetShown(not iconOnlyMode)
    frame.TimeLeft:SetShown(not iconOnlyMode)

    local LossOfControlFrameAlphaBg = BetterBlizzFramesDB.hideLossOfControlFrameBg and 0 or 0.6
    local LossOfControlFrameAlphaLines = BetterBlizzFramesDB.hideLossOfControlFrameLines and 0 or 1
    --frame:SetScale(BetterBlizzFramesDB.lossOfControlScale or 1)
    frame.blackBg:SetAlpha(LossOfControlFrameAlphaBg)
    frame.RedLineTop:SetAlpha(LossOfControlFrameAlphaLines)
    frame.RedLineBottom:SetAlpha(LossOfControlFrameAlphaLines)

    if LossOfControlFrame then
        LossOfControlFrame.blackBg:SetAlpha(LossOfControlFrameAlphaBg)
        LossOfControlFrame.RedLineTop:SetAlpha(LossOfControlFrameAlphaLines)
        LossOfControlFrame.RedLineBottom:SetAlpha(LossOfControlFrameAlphaLines)
    end

    local function GetSchoolInfo(school)
        local schoolNames = {
            -- Single schools
            [1]   = {"Physical",     0.85, 0.65, 0.45},
            [2]   = {"Holy",         1.00, 0.95, 0.60},
            [4]   = {"Fire",         1.00, 0.35, 0.10},
            [8]   = {"Nature",       0.30, 0.85, 0.30},
            [16]  = {"Frost",        0.45, 0.70, 1.00},
            [32]  = {"Shadow",       0.50, 0.25, 0.75},
            [64]  = {"Arcane",       0.80, 0.60, 1.00},

            -- Dual/multi schools
            [3]   = {"Holystrike",   1.00, 0.85, 0.50}, -- Holy + Physical
            [5]   = {"Flamestrike",  1.00, 0.45, 0.10}, -- Fire + Physical
            [6]   = {"Holyfire",     1.00, 0.65, 0.30}, -- Holy + Fire
            [9]   = {"Stormstrike",  0.40, 0.80, 1.00}, -- Nature + Physical
            [10]  = {"Holystorm",    0.90, 0.90, 0.60}, -- Holy + Nature
            [12]  = {"Firestorm",    1.00, 0.55, 0.10}, -- Fire + Nature
            [17]  = {"Froststrike",  0.50, 0.75, 1.00}, -- Frost + Physical
            [18]  = {"Holyfrost",    0.80, 0.90, 1.00}, -- Holy + Frost
            [20]  = {"Frostfire",    0.80, 0.45, 1.00}, -- Fire + Frost
            [24]  = {"Froststorm",   0.50, 0.80, 1.00}, -- Frost + Nature
            [28]  = {"Spellfrost",   0.60, 0.70, 1.00}, -- Arcane + Frost
            [33]  = {"Shadowstrike", 0.65, 0.25, 0.60}, -- Shadow + Physical
            [34]  = {"Twilight",     0.70, 0.40, 0.85}, -- Shadow + Holy
            [36]  = {"Shadowflame",  0.80, 0.30, 0.60}, -- Shadow + Fire
            [40]  = {"Shadowstorm",  0.50, 0.30, 0.85}, -- Shadow + Nature
            [48]  = {"Shadowfrost",  0.55, 0.40, 0.85}, -- Shadow + Frost
            [65]  = {"Spellstrike",  0.90, 0.60, 1.00}, -- Arcane + Physical
            [66]  = {"Divine",       1.00, 0.85, 0.55}, -- Holy + Arcane
            [96]  = {"Spellshadow",  0.75, 0.45, 0.85}, -- Arcane + Shadow
            [124] = {"Elemental",    0.95, 0.60, 0.20}, -- Fire + Frost + Nature
            [126] = {"Chromatic",    0.95, 0.95, 1.00}, -- All elemental schools
            [127] = {"Magic",        0.90, 0.90, 1.00}, -- Generic catch-all magic

            -- Extra
            [200] = {"Astral",       0.50, 0.85, 1.00}, -- Arcane + Nature
            [201] = {"Chaos",        1.00, 0.15, 0.15}, -- All schools incl. Physical
            [202] = {"Chimeric",     0.95, 0.55, 0.85}, -- Arcane + Fire + Frost
            [203] = {"Cosmic",       0.80, 0.80, 1.00}, -- Arcane + Holy + Nature + Shadow
            [204] = {"Radiant",      1.00, 0.70, 0.40}, -- Fire + Holy
            [205] = {"Volcanic",     1.00, 0.40, 0.20}, -- Fire + Nature
            [206] = {"Plague",       0.55, 0.80, 0.40}, -- Shadow + Nature
        }

        return unpack(schoolNames[school] or {"Interrupted", 1, 1, 1})
    end


    -- === Aura Scan Logic ===
    local function checkAuras()
        local mainHardCC, secondHardCC, silence, disarm, root
        local interrupt = frame.interruptData
        local now = GetTime()

        local function getAuraData()
            for i = 1, 40 do
                local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HARMFUL")
                if not aura then break end

                local spellID = aura.spellId
                local ccType = spellList[spellID]
                local remaining = aura.expirationTime and (aura.expirationTime - now) or 0
                local duration = aura.duration or 0

                if ccType == "Silenced" and duration == 0 then
                    frame.silenceFallbacks = frame.silenceFallbacks or {}

                    local fallback = frame.silenceFallbacks[spellID]
                    if not fallback or fallback.expirationTime <= now then
                        local solarBeamDuration = 8.1  -- Only Solar Beam afaik. Leeway of 0.1
                        fallback = {
                            startTime = now,
                            duration = solarBeamDuration,
                            expirationTime = now + solarBeamDuration,
                        }
                        frame.silenceFallbacks[spellID] = fallback
                    end

                    duration = fallback.duration
                    aura.expirationTime = fallback.expirationTime
                    remaining = fallback.expirationTime - now
                end


                if remaining > 0 then
                    local auraData = {
                        icon = aura.icon,
                        type = ccType,
                        duration = duration,
                        expiration = aura.expirationTime,
                        remaining = remaining,
                        spellID = spellID
                    }

                    if isHardCC(ccType) then
                        if ccType == "Stunned" or ccType == "Horrified" then
                            -- Always prefer stuns and horrify as primary
                            local isSameType = (mainHardCC and mainHardCC.type == ccType)
                            if not mainHardCC or not isSameType or remaining > mainHardCC.remaining then
                                if mainHardCC and not (mainHardCC.type == "Stunned" or mainHardCC.type == "Horrified") then
                                    secondHardCC = mainHardCC
                                end
                                mainHardCC = auraData
                            end
                        elseif not mainHardCC then
                            mainHardCC = auraData
                        elseif auraData.spellID ~= mainHardCC.spellID then
                            if not secondHardCC or auraData.remaining > secondHardCC.remaining then
                                secondHardCC = auraData
                            end
                        end
                    elseif ccType == "Silenced" or ccType == "Silenced+" then
                        if not silence or remaining > silence.remaining then
                            silence = auraData
                        end
                    elseif ccType == "Disarmed" then
                        if not disarm or remaining > disarm.remaining then
                            disarm = auraData
                        end
                    elseif ccType == "Rooted" then
                        if not root or remaining > root.remaining then
                            root = auraData
                        end
                    end
                end
            end
        end

        getAuraData()

        -- Clear interrupt if expired
        if interrupt and interrupt.expiration <= now then
            frame.interruptData = nil
            interrupt = nil
        end

        -- === Priority Logic ===
        local main, secondary
        local fullCC = mainHardCC

        if fullCC then
            main = fullCC
            if interrupt and silence then
                secondary = (silence.remaining > interrupt.remaining) and silence or interrupt
            elseif interrupt then
                secondary = interrupt
            elseif secondHardCC then
                secondary = secondHardCC
            else
                secondary = interrupt or silence or disarm or root
            end
        elseif interrupt and silence then
            if silence.remaining > interrupt.remaining then
                main = silence
                secondary = interrupt
            else
                main = interrupt
                secondary = silence
            end
        elseif interrupt then
            main = interrupt
            secondary = silence or disarm or root
        elseif silence then
            main = silence
            secondary = disarm or root
        elseif disarm then
            main = disarm
            secondary = root
        elseif root then
            main = root
            secondary = nil
        end


        -- Assign to frame
        frame.mainCC = main
        frame.secondaryCC = secondary

        -- === Main Display ===
        if main then
            if frame.fadeOutShrink:IsPlaying() then
                frame.fadeOutShrink:Stop()
            end

            frame.Icon:SetTexture(main.icon)
            if frame.Icon.Cooldown then
                frame.Icon.Cooldown:SetCooldown(main.expiration - main.duration, main.duration)
            end

            local r, g, b = 1, 0.819, 0
            if main.type == "Silenced" and interrupt then
                frame.AbilityName:SetText("Silenced+")
                _, r, g, b = GetSchoolInfo(interrupt.school)
            elseif main == interrupt then
                frame.AbilityName:SetText("Interrupted")
                _, r, g, b = GetSchoolInfo(interrupt.school)
            else
                frame.AbilityName:SetText(main.type or "unknown")
            end
            frame.AbilityName:SetTextColor(r, g, b)

            frame.duration = main.duration
            frame.expiration = main.expiration
            frame.lockedBy = main.spellID

            if not frame:IsShown() then
                frame:SetAlpha(0)
                frame:SetScale(0.85)
                frame:Show()
                frame.fadeInScale:Stop()
                frame.fadeInScale:Play()
            end

            if main == interrupt or (main.type == "Silenced" and interrupt) then
                local name, r, g, b = GetSchoolInfo(interrupt.school)
                frame.Icon.SchoolText:SetText(name)
                frame.Icon.SchoolText:SetTextColor(r, g, b)
            else
                frame.Icon.SchoolText:SetText("")
            end
        else
            -- Leeway check: don't hide too early if interrupt about to become main
            if interrupt and (interrupt.expiration - now) > 0.2 then
                -- wait
            else
                if not frame.fadeOutShrink:IsPlaying() then
                    frame.fadeOutShrink:Stop()
                    frame.fadeOutShrink:Play()
                end
            end
            frame.Icon.SchoolText:SetText("")
        end

        -- === Secondary Display ===
        if secondary then
            frame.SecondaryIcon.icon:SetTexture(secondary.icon)
            frame.SecondaryIcon.Cooldown:SetCooldown(secondary.expiration - secondary.duration, secondary.duration)
            frame.SecondaryIcon:Show()

            if interrupt and (secondary == interrupt or secondary == silence) then
                local name, r, g, b = GetSchoolInfo(interrupt.school)
                frame.SecondaryIcon.SchoolText:SetText(name)
                frame.SecondaryIcon.SchoolText:SetTextColor(r, g, b)
            else
                frame.SecondaryIcon.SchoolText:SetText("")
            end
        else
            frame.SecondaryIcon:Hide()
            frame.SecondaryIcon.SchoolText:SetText("")
        end

        if frame.silenceFallbacks then
            for spellID, fallback in pairs(frame.silenceFallbacks) do
                if fallback.expirationTime <= now then
                    frame.silenceFallbacks[spellID] = nil
                end
            end
        end
    end

    -- === Event Registration ===
    f:SetScript("OnEvent", function()
        if frame.returnEarly then return end
        checkAuras()
    end)
    f:RegisterUnitEvent("UNIT_AURA", "player")

    -- === Timer Update ===
    frame:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if self.expiration and not self.returnEarly then
            local timeLeft = self.expiration - now

            if timeLeft <= 0 then
                checkAuras()
            else
                self.TimeLeft.NumberText:SetText(string.format("%.1f seconds", timeLeft))

                -- ⛏ Check if secondary interrupt has expired
                if self.interruptData and self.secondaryCC == self.interruptData and self.interruptData.expiration <= now then
                    self.interruptData = nil
                    checkAuras()
                end
            end
        end
    end)



    -- === Interrupt Tracking ===
    frame.interruptWatcher = CreateFrame("Frame")
    frame.interruptWatcher:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame.interruptWatcher:SetScript("OnEvent", function()
        local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, spellName, _, _, _, school = CombatLogGetCurrentEventInfo()

        if not interruptEvents[event] then return end
        if destGUID ~= UnitGUID("player") then return end

        local duration = interruptSpells[spellID]
        if not duration then return end

        if event ~= "SPELL_INTERRUPT" then
            -- Check if the unit was casting or channeling AND if it was interruptible
            local _, _, _, _, _, _, notInterruptibleChannel = UnitChannelInfo("player")

            local ccData
            local schoolName = GetSchoolInfo(school) or ""
            if schoolName == "Interrupted" then
                for i = 1, C_LossOfControl.GetActiveLossOfControlDataCount() do
                    local cc = C_LossOfControl.GetActiveLossOfControlData(i)
                    if cc and cc.locType == "SCHOOL_INTERRUPT" then
                        ccData = cc
                        break
                    end
                end
                if ccData then
                    school = ccData.lockoutSchool
                    duration = ccData.duration
                else
                    return
                end
            end -- avoid showing on casts like first aid etc
            if not ccData and notInterruptibleChannel ~= false then -- nil when not channeling
                return
            end
        end

        -- Reduce duration based on active buffs
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, auraSpellID = UnitBuff("player", i)
            if not name then break end
            local mult = spellLockReducer[auraSpellID]
            if mult then
                duration = duration * mult
            end
        end

        -- Store interrupt data for aura scan logic
        local schoolName = GetSchoolInfo(school)

        local now = GetTime()
        local expirationTime = now + duration
        local remaining = expirationTime - now

        frame.interruptData = {
            icon = C_Spell.GetSpellTexture(spellID),
            type = schoolName or "Interrupted",
            duration = duration,
            expiration = expirationTime,
            expirationTime = expirationTime,
            remaining = remaining,
            spellID = spellID,
            school = school
        }


        checkAuras() -- force update

    end)

    if BBF.isMoP then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:Hide()

        local function ShowOriginalLoC(showOg)
            if showOg then
                LossOfControlFrame:SetParent(UIParent)
                BBFLossOfControlParentFrame:SetParent(f)
                BBFLossOfControlFrame.returnEarly = true
            else
                LossOfControlFrame:SetParent(f)
                BBFLossOfControlParentFrame:SetParent(UIParent)
                BBFLossOfControlFrame.returnEarly = nil
            end
        end

        f:SetScript("OnEvent", function(_, event, arg1)
            local _, instanceType = IsInInstance()
            if instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
                ShowOriginalLoC(true)
            else
                ShowOriginalLoC(false)
            end
        end)
    end
end