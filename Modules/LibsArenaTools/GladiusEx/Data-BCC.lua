GladiusEx.Data = {}

function GladiusEx.Data.DefaultAlertSpells()
  return {}
end

function GladiusEx.Data.DefaultAuras()
	return {}
end

function GladiusEx.Data.DefaultClassicon()
	return {
		-- Higher Number is More Priority
		-- Priority List by Bibimapi
		-- Immunes I and Stealth (10)

		[GladiusEx:SafeGetSpellName(33786)]	= 10,	-- Cyclone
		[GladiusEx:SafeGetSpellName(605)]	  = 10,	-- Mind Control
		[GladiusEx:SafeGetSpellName(45438)]	= 10,	-- Ice Block 
		[GladiusEx:SafeGetSpellName(642)]	  = 10,	-- Divine Shield
		[GladiusEx:SafeGetSpellName(27827)]	= 10,	-- Spirit of Redemption
		[GladiusEx:SafeGetSpellName(34692)] = 10, -- The Beast Within

		[GladiusEx:SafeGetSpellName(5215)]	= 10,	-- Prowl
		[GladiusEx:SafeGetSpellName(32612)]	= 10,	-- Invisibility (main)
		[GladiusEx:SafeGetSpellName(1784)]	= 10,	-- Stealth 
		[GladiusEx:SafeGetSpellName(11327)]	= 10,	-- Vanish
		[GladiusEx:SafeGetSpellName(5384)]	= 10,	-- Feign Death

		[GladiusEx:SafeGetSpellName(44166)]	= 10,	-- Refreshment
		[GladiusEx:SafeGetSpellName(27089)]	= 10,	-- Drink1
		[GladiusEx:SafeGetSpellName(46755)]	= 10,	-- Drink2
		[GladiusEx:SafeGetSpellName(23920)] = 10,	-- Spell Reflection
		[GladiusEx:SafeGetSpellName(31224)]	= 10,	-- Cloak of Shadows


		-- Breakable CC (9)

		[GladiusEx:SafeGetSpellName(2637)]  	= 9,	-- Hibernate 
		[GladiusEx:SafeGetSpellName(3355)]  	= 9,	-- Freezing Trap 
		[GladiusEx:SafeGetSpellName(37506)]  	= 9,	-- Scatter Shot
		[GladiusEx:SafeGetSpellName(118)]  	  = 9.1,	-- Polymorph
		[GladiusEx:SafeGetSpellName(28272)]  	= 9.1,	-- Polymorph (pig)
		[GladiusEx:SafeGetSpellName(28271)]  	= 9.1,	-- Polymorph (turtle
		[GladiusEx:SafeGetSpellName(20066)]  	= 9,	-- Repentance
		[GladiusEx:SafeGetSpellName(1776)]  	= 9,	-- Gouge
		[GladiusEx:SafeGetSpellName(6770)]  	= 9.1,	-- Sap
		[GladiusEx:SafeGetSpellName(1513)]  	= 9,	-- Scare Beast
		[GladiusEx:SafeGetSpellName(31661)]  	= 9,	-- Dragon's Breath 
		[GladiusEx:SafeGetSpellName(8122)]  	= 9,	-- Psychic Scream 
		[GladiusEx:SafeGetSpellName(2094)]  	= 9,	-- Blind 
		[GladiusEx:SafeGetSpellName(5782)]  	= 9,	-- Fear
		[GladiusEx:SafeGetSpellName(5484)]  	= 9,	-- Howl of Terror
		[GladiusEx:SafeGetSpellName(6358)]  	= 9,	-- Seduction
		[GladiusEx:SafeGetSpellName(5246)]  	= 9,	-- Intimidating Shout 
		[GladiusEx:SafeGetSpellName(22570)]  	= 9,	-- Maim
		[GladiusEx:SafeGetSpellName(19386)]   = 9,  -- Wyvern Sting


		-- Stuns (8)

		[GladiusEx:SafeGetSpellName(5211)]  = 8,	-- Bash 
		[GladiusEx:SafeGetSpellName(24394)] = 8,	-- Intimidation 
		[GladiusEx:SafeGetSpellName(853)]  	= 8,	-- Hammer of Justice
		[GladiusEx:SafeGetSpellName(1833)] 	= 8,	-- Cheap Shot 
		[GladiusEx:SafeGetSpellName(408)]  	= 8,	-- Kidney Shot 
		[GladiusEx:SafeGetSpellName(30283)] = 8,	-- Shadowfury 
		[GladiusEx:SafeGetSpellName(20549)] = 8,	-- War Stomp
		[GladiusEx:SafeGetSpellName(835)]   = 8,     -- Tidal Charm
		[GladiusEx:SafeGetSpellName(12809)] = 8,   -- Concussion Blow
		[GladiusEx:SafeGetSpellName(100)]   = 8,   -- Charge
		[GladiusEx:SafeGetSpellName(25275)] = 8,   -- Intercept
		[GladiusEx:SafeGetSpellName(28445)] = 8,  -- Concussive Shot

		-- Immunes II (7)

		[GladiusEx:SafeGetSpellName(1022)]  	= 7,	-- Blessing of Protection
		[GladiusEx:SafeGetSpellName(33206)]   = 7, -- Pain Suppression
		[GladiusEx:SafeGetSpellName(5277)]  	= 7,	-- Evasion


		-- Defensives I (6.5)
		[GladiusEx:SafeGetSpellName(3411)]    = 6.5,   -- Intervene
		[GladiusEx:SafeGetSpellName(45182)]	 	= 6.5,	 -- Cheat Death
		[GladiusEx:SafeGetSpellName(19263)]   = 6.5,   -- Deterrence

		-- Immunes III (6)

		[GladiusEx:SafeGetSpellName(18499)]  	= 6,	-- Berserker Rage

		-- Unbreakable CC and Roots (5)

		[GladiusEx:SafeGetSpellName(6789)]  	= 5,	-- Death Coil 
		[GladiusEx:SafeGetSpellName(15487)]  	= 5,	-- Silence
		[GladiusEx:SafeGetSpellName(27559)]  	= 3,	-- Silencing shot (3 second silence)
		[GladiusEx:SafeGetSpellName(1330)]  	= 5,	-- Garrote
		[GladiusEx:SafeGetSpellName(339)]  	  = 5,	-- Entangling Roots
		[GladiusEx:SafeGetSpellName(122)]   	= 5,	-- Frost Nova
		[GladiusEx:SafeGetSpellName(33395)]  	= 5,	-- Freeze (Water Elemental)
		[GladiusEx:SafeGetSpellName(676)]   	= 5,	-- Disarm 
		[GladiusEx:SafeGetSpellName(16979)]  	= 5,	-- Feral Charge
		[GladiusEx:SafeGetSpellName(44047)]   = 5,  -- Chastise
		[GladiusEx:SafeGetSpellName(26177)]   = 5,  -- Pet Charge

		-- Defensives II (4.5)

		[GladiusEx:SafeGetSpellName(6940)] 	= 4.5,	-- Blessing of Sacrifice
		[GladiusEx:SafeGetSpellName(871)]  	= 4.5,	-- Shield Wall



		-- Important II (4)

		[GladiusEx:SafeGetSpellName(29166)]  	= 4,	-- Innervate
		[GladiusEx:SafeGetSpellName(31842)]  	= 4,	-- Divine Illumination
		[GladiusEx:SafeGetSpellName(17116)]  	= 4,	-- Nature's Swiftness (Druid)
		[GladiusEx:SafeGetSpellName(16188)]  	= 4,	-- Nature's Swiftness (Shaman)
		[GladiusEx:SafeGetSpellName(16166)]  	= 4,	-- Elemental Mastery
		[GladiusEx:SafeGetSpellName(1044)]		= 4,	-- Blessing of Freedom
		[GladiusEx:SafeGetSpellName(34709)]  	= 4,	-- Shadow Sight (eye in arena)
		[GladiusEx:SafeGetSpellName(14751)]  	= 4,	-- Inner Focus

		-- Offensives I (3)

		[GladiusEx:SafeGetSpellName(19574)]  	= 3,	-- Bestial Wrath
		[GladiusEx:SafeGetSpellName(12042)]  	= 3,	-- Arcane Power
		[GladiusEx:SafeGetSpellName(12472)]  	= 3,	-- Icy Veins 
		[GladiusEx:SafeGetSpellName(29977)]  	= 3,	-- Combustion
		[GladiusEx:SafeGetSpellName(31884)]  	= 3,	-- Avenging Wrath
		[GladiusEx:SafeGetSpellName(13750)]  	= 3,	-- Adrenaline Rush 
		[GladiusEx:SafeGetSpellName(32182)]  	= 3,	-- Heroism  
		[GladiusEx:SafeGetSpellName(2825)]  	= 3,	-- Bloodlust
		[GladiusEx:SafeGetSpellName(13877)]  	= 3,	-- Blade Flurry 
		[GladiusEx:SafeGetSpellName(1719)]  	= 3,	-- Recklessness
		[GladiusEx:SafeGetSpellName(12292)]  	= 3,	-- Death Wish
		[GladiusEx:SafeGetSpellName(3045)]  	= 3,	-- Rapid Fire

		-- Defensives III (2.5)

		[GladiusEx:SafeGetSpellName(22812)]  	= 2.5,	-- Barkskin
		[GladiusEx:SafeGetSpellName(16689)]   = 2.5,   -- Nature's Grasp
		[GladiusEx:SafeGetSpellName(2651)]    = 2.5,    -- Elune's Grace
		[GladiusEx:SafeGetSpellName(22842)]  	= 2.5,	-- Frenzied Regen
		[GladiusEx:SafeGetSpellName(498)]  	  = 2.5,	-- Divine Protection
		[GladiusEx:SafeGetSpellName(12975)]  	= 2.5,	-- Last Stand
		[GladiusEx:SafeGetSpellName(38031)]  	= 2.5,	-- Shield Block
		[GladiusEx:SafeGetSpellName(66)]	   	= 2.5,	-- Invisibility (initial)
		[GladiusEx:SafeGetSpellName(20578)]  	= 2.5,	-- Cannibalize
		[GladiusEx:SafeGetSpellName(8178)]  	= 2.5,	-- Grounding Totem Effect
		[GladiusEx:SafeGetSpellName(8145)]    = 2.5,   -- Tremor Totem Passive
		[GladiusEx:SafeGetSpellName(6346)]    = 2.5,   -- Fear Ward
		[GladiusEx:SafeGetSpellName(30823)]   = 2.5,   -- Shamanistic Rage
		[GladiusEx:SafeGetSpellName(27273)]   = 2.5,     -- Sacrifice

		-- Offensives II (2)

		[GladiusEx:SafeGetSpellName(5217)]  	= 2,	-- Tiger's Fury
		[GladiusEx:SafeGetSpellName(12043)]  	= 2,	-- Presence of Mind
		[GladiusEx:SafeGetSpellName(10060)]  	= 2,	-- Power Infusion
		[GladiusEx:SafeGetSpellName(14177)]  	= 2,	-- Cold Blood
		[GladiusEx:SafeGetSpellName(12328)]  	= 2,	-- Sweeping Strikes

		-- Misc (1)

		[GladiusEx:SafeGetSpellName(2645)]		= 1,	-- Ghost Wolf
		[GladiusEx:SafeGetSpellName(12051)]   = 1,  -- Evocation
		[GladiusEx:SafeGetSpellName(16190)]  	= 1,	-- Mana Tide Totem
		[GladiusEx:SafeGetSpellName(18708)]  	= 1,	-- Fel Domination
		[GladiusEx:SafeGetSpellName(1850)]  	= 1,	-- Dash
		[GladiusEx:SafeGetSpellName(5118)]  	= 1,	-- Aspect of the Cheetah
		[GladiusEx:SafeGetSpellName(2983)]  	= 1,	-- Sprint
		[GladiusEx:SafeGetSpellName(36554)]  	= 1,	-- Shadowstep
		[GladiusEx:SafeGetSpellName(41425)]  	= 1,	-- Hypothermia
		[GladiusEx:SafeGetSpellName(25771)]  	= 1,	-- Forbearance
		[GladiusEx:SafeGetSpellName(3034)]  	= 1,	-- Viper Sting
		[GladiusEx:SafeGetSpellName(3043)]  	= 1,	-- Scorpid Sting
		[GladiusEx:SafeGetSpellName(25467)]  	= 1,	-- Devouring Plague
		[GladiusEx:SafeGetSpellName(2687)]  	= 1,	-- Bloodrage
		[GladiusEx:SafeGetSpellName(11426)]   = 1,  -- Ice Barrier
		[GladiusEx:SafeGetSpellName(1543)]    = 1,  -- Flare
  }
end

function GladiusEx.Data.DefaultCooldowns()
	return {
		{ -- group 1
			[22812] = true, -- Druid/Barkskin
			[33786] = true, -- Druid/Cyclone (feral)
			[99] = true, -- Druid/Disorienting Roar
			[16689] = true, -- Druid/Nature's Grasp
			[5211] = true, -- Druid/Bash
			[16979] = true, -- Druid/Feral Charge
			[17116] = true, -- Druid/Nature's Swiftness
			[29166] = true, -- Druid/Nature's Swiftness

			[19574] = true, -- Hunter/Bestial Wrath
			[19263] = true, -- Hunter/Deterrence
			[781] = true, -- Hunter/Disengage
			[1499] = true, -- Hunter/Freezing Trap
			[19577] = true, -- Hunter/Intimidation
			[23989] = true, -- Hunter/Readiness
			[19386] = true, -- Hunter/Wyvern Sting
			[19503] = true, -- Hunter/Scatter Shot
			[34490] = true, -- Hunter/Silencing Shot
			[26064] = true, -- Hunter/Shell Shield
			[3045] = true, -- Hunter/Rapid Fire

			[1953] = true, -- Mage/Blink
			[11958] = true, -- Mage/Cold Snap. V: changed ID in legion
			[2139] = true, -- Mage/Counterspell
			[122] = true, -- Mage/Frost Nova
			[45438] = true, -- Mage/Ice Block
			[12043] = true, -- Mage/Presence of Mind
			[12051] = true, -- Mage/Evocation
			[31661] = true, -- Mage/Dragon's Breath
			[11129] = true, -- Mage/Combustion
			[12472] = true, -- Mage/Icy Veins

			[4987] = true, -- Paladin/Cleanse
			[31821] = true, -- Paladin/Devotion Aura
			[642] = true, -- Paladin/Divine Shield
			[853] = true, -- Paladin/Hammer of Justice
			[20066] = true, -- Paladin/Repentance
			[1044] = true, -- Paladin/Blessing of Freedom
			[6940] = true, -- Paladin/Blessing of Sacrifice
			[31884] = true, -- Paladin/Avenging Wrath
			[31842] = true, -- Paladin/Divine Illumination
			[20925] = true, -- Paladin/Holy Shield
			[20216] = true, -- Paladin/Divine Favor
			[498] = true, -- Paladin/Divine Protection
			[1022] = true, -- Paladin/Blessing of Protection

			[19236] = true, -- Priest/Desperate Prayer
			[33206] = true, -- Priest/Pain Suppression
			[8122] = true, -- Priest/Psychic Scream
			[527] = true, -- Priest/Purify
			[15487] = true, -- Priest/Silence
			[10060] = true, -- Priest/Power Infusion
			[32548] = true, -- Priest/Symbols of Hope
			[34433] = true, -- Priest/Shadowfiend
			[14751] = true, -- Priest/Inner Focus
			[6346] = true, -- Priest/Fear Ward

			[13750] = true, -- Rogue/Adrenaline Rush
			[13877] = true, -- Rogue/Blade Furry
			[2094] = true, -- Rogue/Blind
			[31224] = true, -- Rogue/Cloak of Shadows
			[1766] = true, -- Rogue/Kick
			[1856] = true, -- Rogue/Vanish
			[14177] = true, -- Rogue/Cold Blood
			[36554] = true, -- Rogue/Shadowstep
			[5277] = true, -- Rogue/Evasion
			[2983] = true, -- Rogue/Sprint
			[14185] = true, -- Rogue/Preparation

			[5484] = true, -- Warlock/Howl of Terror
			[6789] = true, -- Warlock/Death Coil
			[30283] = true, -- Warlock/Shadowfury
			[19647] = true, -- Warlock/Spell Lock
			[19505] = true, -- Warlock/Devour Magic


			[5246] = true, -- Warrior/Intimidating Shout
			[6552] = true, -- Warrior/Pummel
			[1719] = true, -- Warrior/Recklessness
			[871] = true, -- Warrior/Shield Wall
			[23920] = true, -- Warrior/Spell Reflection
			[12292] = true, -- Warrior/Death Wish
			[3411] = true, -- Warrior/Intervene
			[100] = true, -- Warrior/Charge
			[20252] = true, -- Warrior/Intercept
			[12809] = true, -- Warrior/Concussion Blow
			[18499] = true, -- Warrior/Berserker Rage
			[676] = true, -- Warrior/Disarm
			[12975] = true, -- Warrior/Last Stand

      [16188] = true, -- Shaman/Nature's Swiftness
      [8177] = true, -- Shaman/Grounding Totem
      [30823] = true, -- Shaman/Shamanistic Rage
		},
		{ -- group 2
		[42292] = true, -- Trinket
		}
	}
end

function GladiusEx.Data.GetSpecializationInfoByID(id)
    if specData[id] == nil then
        return
    end
    return unpack(specData[id])
end

function GladiusEx.Data.GetNumSpecializationsForClassID(classID)
    return 3
end

function GladiusEx.Data.GetSpecializationInfoForClassID(classID, specIndex)
    local specID = classIDToSpecID[classID][specIndex]
    local _, name, desc, icon, role, classFile, className = GladiusEx.Data.GetSpecializationInfoByID(specID)
    return specID, name, desc, icon, role, classFile, className
end

function GladiusEx.Data.GetArenaOpponentSpec(id)
    local unit = "arena" .. id
    return GladiusEx.buttons[unit] and GladiusEx.buttons[unit].specID
end

function GladiusEx.Data.CountArenaOpponents()
    return GladiusEx:GetArenaSize(2)
end

function GladiusEx.Data.GetNumArenaOpponentSpecs()
    return nil
end

