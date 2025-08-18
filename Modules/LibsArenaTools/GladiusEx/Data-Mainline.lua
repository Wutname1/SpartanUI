GladiusEx.Data = {}

function GladiusEx.Data.DefaultAlertSpells()
	return {
		[GladiusEx:SafeGetSpellName(118)]      = cc,    -- Polymorph
		[GladiusEx:SafeGetSpellName(5782)]     = cc,    -- Fear
		[GladiusEx:SafeGetSpellName(51514)]    = cc,    -- Hex
		[GladiusEx:SafeGetSpellName(20066)]    = cc,    -- Repentance
		[GladiusEx:SafeGetSpellName(33786)]    = cc,    -- Cyclone
	}
end

function GladiusEx.Data.DefaultAuras()
	return {
		[GladiusEx:SafeGetSpellName(227723)] = true, -- Mana divining stone
		[GladiusEx:SafeGetSpellName(32727)] = true,  -- Arena Preparation #1
		[GladiusEx:SafeGetSpellName(32728)] = true,  -- Arena Preparation #2
	}
end

-- NOTE: this list can be modified from the ClassIcon module options, no need to edit it here
-- Nonetheless, if you think that we missed an important aura, please post it on the addon site at curse or wowace
function GladiusEx.Data.DefaultClassicon()
	return {
		-- Higher Number is More Priority
		-- Priority List by Bibimapi
-- Immunes I and Stealth (10)

    	[211317]        = 10, -- Archbishop Benedictus' Restitution
		[221527]				= 10,	-- Imprison (pvp tal)
		[GladiusEx:SafeGetSpellName(33786)]	= 10,	-- Cyclone
		[GladiusEx:SafeGetSpellName(605)]	= 10,	-- Mind Control
		[GladiusEx:SafeGetSpellName(196555)]	= 10,	-- Netherwalk
		[GladiusEx:SafeGetSpellName(186265)]	= 10,	-- Aspect of the Turtle
		[GladiusEx:SafeGetSpellName(45438)]	= 10,	-- Ice Block 
		[GladiusEx:SafeGetSpellName(642)]	= 10,	-- Divine Shield
		[GladiusEx:SafeGetSpellName(228050)]	= 10,	-- Guardian of the Forgotten Queen (party bubble)
		[27827]					= 10,	-- Spirit of Redemption
		[215769]				= 10,	-- Spirit of Redemption (pvp tal)
		[GladiusEx:SafeGetSpellName(269513)]	= 10,	-- Death from Above
		[46924]					= 10,	-- Bladestorm (fury)
		[227847]				= 10,	-- Bladestorm (arms)
		[147833]				= 10,	-- Intervene Spell Redirected to Warrior
		[320224]				= 10,	-- Podtender
		[327140]				= 10,	-- Forgeborne Reveries
		[199545]				= 10,	-- Steed of Glory (P pvp tal)
		[378464]				= 10,	-- Nullifying Shroud

		[GladiusEx:SafeGetSpellName(5215)]	= 10,	-- Prowl
		[199483]				= 10,	-- Camouflage
		[198158]				= 10,	-- Mass Invisibility
		[110960]				= 10,	-- Greater Invisibility 
		[32612]					= 10,	-- Invisibility (main)
		[GladiusEx:SafeGetSpellName(1784)]	= 10,	-- Stealth 
		[GladiusEx:SafeGetSpellName(11327)]	= 10,	-- Vanish
		[GladiusEx:SafeGetSpellName(58984)]	= 10,	-- Shadowmeld
		[GladiusEx:SafeGetSpellName(5384)]	= 10,	-- Feign Death
		[GladiusEx:SafeGetSpellName(207736)]	= 10,	-- Shadowy Duel
		[GladiusEx:SafeGetSpellName(377362)]    = 10,   -- Precognition

		[GladiusEx:SafeGetSpellName(167152)]	= 10,	-- Refreshment
		[GladiusEx:SafeGetSpellName(118358)]	= 10,	-- Drink1
		[GladiusEx:SafeGetSpellName(274914)]	= 10,	-- Drink2


  -- Breakable CC (9)

  [217832]				= 9,	-- Imprison
  [GladiusEx:SafeGetSpellName(99)]  	= 9,	-- Incapacitating Roar
  [GladiusEx:SafeGetSpellName(2637)]  	= 9,	-- Hibernate 
  [GladiusEx:SafeGetSpellName(3355)]  	= 9,	-- Freezing Trap 
  [GladiusEx:SafeGetSpellName(203337)]  	= 9,	-- Freezing Trap (S honor talent)
  [GladiusEx:SafeGetSpellName(213691)]  	= 9,	-- Scatter Shot
  [GladiusEx:SafeGetSpellName(118)]  	= 9,	-- Polymorph
  [GladiusEx:SafeGetSpellName(28272)]  	= 9,	-- Polymorph (pig)
  [GladiusEx:SafeGetSpellName(28271)]  	= 9,	-- Polymorph (turtle)
  [GladiusEx:SafeGetSpellName(61025)]  	= 9,	-- Polymorph (snake)
  [GladiusEx:SafeGetSpellName(61305)]  	= 9,	-- Polymorph (black cat)
  [GladiusEx:SafeGetSpellName(61721)]  	= 9,	-- Polymorph (rabbit)
  [GladiusEx:SafeGetSpellName(61780)]  	= 9,	-- Polymorph (turkey)
  [GladiusEx:SafeGetSpellName(126819)]  	= 9,	-- Polymorph (procupine)
  [GladiusEx:SafeGetSpellName(161353)]  	= 9,	-- Polymorph (bear cub)
  [GladiusEx:SafeGetSpellName(161354)]  	= 9,	-- Polymorph (monkey)
  [GladiusEx:SafeGetSpellName(161355)]  	= 9,	-- Polymorph (penguin)
  [GladiusEx:SafeGetSpellName(161372)]  	= 9,	-- Polymorph (peacock)
  [GladiusEx:SafeGetSpellName(277787)]  	= 9,	-- Polymorph (direhorn)
  [GladiusEx:SafeGetSpellName(277792)]  	= 9,	-- Polymorph (bumblebee)
  [82691]				  	= 9.1,	-- Ring of Frost
  [GladiusEx:SafeGetSpellName(115078)]  	= 9,	-- Paralysis
  [GladiusEx:SafeGetSpellName(20066)]  	= 9,	-- Repentance
  [200196]			  	= 9,	-- Holy Word: Chastise incap 
  [GladiusEx:SafeGetSpellName(1776)]  	= 9,	-- Gouge
  [GladiusEx:SafeGetSpellName(6770)]  	= 9,	-- Sap
  [GladiusEx:SafeGetSpellName(51514)]  	= 9,	-- Hex
		[GladiusEx:SafeGetSpellName(211004)]  	= 9,	-- Hex (spider)
		[GladiusEx:SafeGetSpellName(210873)]  	= 9,	-- Hex (raptor)
		[GladiusEx:SafeGetSpellName(211015)]  	= 9,	-- Hex (cockroach)
		[GladiusEx:SafeGetSpellName(211010)]  	= 9,	-- Hex (snake)
		[GladiusEx:SafeGetSpellName(196942)]  	= 9,	-- Hex (Voodoo Totem)
		[GladiusEx:SafeGetSpellName(277784)]  	= 9,	-- Hex (Wicker Mongrel)
		[GladiusEx:SafeGetSpellName(277778)]  	= 9,	-- Hex (Zandalari Tendonripper)
		[GladiusEx:SafeGetSpellName(269352)]  	= 9,	-- Hex (Skeletal Hatchling)
		[GladiusEx:SafeGetSpellName(107079)]  	= 9,	-- Quaking Palm
		[GladiusEx:SafeGetSpellName(207167)]  	= 9,	-- Blinding Sleet 
		[GladiusEx:SafeGetSpellName(207685)]  	= 9,	-- Sigil of Misery
		[GladiusEx:SafeGetSpellName(1513)]  	= 9,	-- Scare Beast
		[GladiusEx:SafeGetSpellName(31661)]  	= 9,	-- Dragon's Breath 
		[GladiusEx:SafeGetSpellName(198909)]  	= 9,	-- Song of Chi-ji 
		[GladiusEx:SafeGetSpellName(202274)]  	= 9,	-- Incendiary Brew
		[GladiusEx:SafeGetSpellName(105421)]  	= 9,	-- Blinding Light
		[GladiusEx:SafeGetSpellName(8122)]  	= 9,	-- Psychic Scream 
		[331866]			  	= 9,	-- Door of Shadows
		[GladiusEx:SafeGetSpellName(2094)]  	= 9,	-- Blind 
		[GladiusEx:SafeGetSpellName(118699)]  	= 9,	-- Fear
		[GladiusEx:SafeGetSpellName(130616)]  	= 9,	-- Fear (Horrify)
		[GladiusEx:SafeGetSpellName(5484)]  	= 9,	-- Howl of Terror
		[GladiusEx:SafeGetSpellName(6358)]  	= 9,	-- Seduction
		[GladiusEx:SafeGetSpellName(261589)]  	= 9,	-- Seduction (Grimoire talent)
		[GladiusEx:SafeGetSpellName(5246)]  	= 9,	-- Intimidating Shout 
		[GladiusEx:SafeGetSpellName(316593)]  	= 9,	-- Intimidating Shout (P talent)
		[GladiusEx:SafeGetSpellName(10326)]  	= 9,	-- Turn Evil (undead dk)
		[GladiusEx:SafeGetSpellName(9484)]  	= 9,	-- Shackle Undead (undead dk)
		[217832]			  	= 9,	-- Imprison (dispellable)
		[206961]			  	= 9,	-- Phearomones (legy)
		[324263]			  	= 9,	-- Sulfuric Emission (disorient)
		[339738]			  	= 9,	-- Dreamer's Mending
		[360806]			  	= 9,	-- Sleep Walk


		-- Stuns (8)

		[GladiusEx:SafeGetSpellName(108194)]  	= 8,	-- Asphyxiate (U/F)
		[GladiusEx:SafeGetSpellName(221562)]  	= 8,	-- Asphyxiate (B)
		[GladiusEx:SafeGetSpellName(91800)]  	= 8,	-- Gnaw
		[GladiusEx:SafeGetSpellName(91797)]  	= 8,	-- Gnaw (transformed)
		[GladiusEx:SafeGetSpellName(210141)]  	= 8,	-- Zombie Explosion
		[287254]			  	= 8,	-- Remorseless Winter
		[334693]			  	= 8,	-- Frostwyrm's Fury
		[325321]			  	= 8,	-- Soulshape (Wild Hunt's Charge)
		[332423]			  	= 8,	-- Sparkling Driftglobe Core
		[GladiusEx:SafeGetSpellName(179057)]  	= 8,	-- Chaos Nova 
		[GladiusEx:SafeGetSpellName(205630)]  	= 8,	-- Illidan's Grasp, primary effect
		[GladiusEx:SafeGetSpellName(208618)]  	= 8,	-- Illidan's Grasp, secondary effect
		[GladiusEx:SafeGetSpellName(211881)]  	= 8,	-- Fel Eruption
		[GladiusEx:SafeGetSpellName(203123)]  	= 8,	-- Maim
		[GladiusEx:SafeGetSpellName(5211)]  	= 8,	-- Mighty Bash 
		[163505]			  	= 8,	-- Rake (Stun from Prowl)
		[GladiusEx:SafeGetSpellName(202244)]  	= 8,	-- Overrun (G pvp tal stun)
		[GladiusEx:SafeGetSpellName(24394)]  	= 8,	-- Intimidation 
		[202346]			  	= 8,	-- Double Barrel
		[GladiusEx:SafeGetSpellName(119381)]  	= 8,	-- Leg Sweep
		[GladiusEx:SafeGetSpellName(853)]  	= 8,	-- Hammer of Justice
		[255941]			  	= 8,	-- Wake of Ashes (undead dk + pets)
		[200200]			  	= 8,	-- Holy word: Chastise stun
		[GladiusEx:SafeGetSpellName(64044)]  	= 8,	-- Psychic Horror
		[GladiusEx:SafeGetSpellName(1833)]  	= 8,	-- Cheap Shot 
		[GladiusEx:SafeGetSpellName(408)]  	= 8,	-- Kidney Shot 
		[GladiusEx:SafeGetSpellName(118345)]  	= 8,	-- Pulverize (Primal Elementalist) 
		[GladiusEx:SafeGetSpellName(118905)]  	= 8,	-- Capacitor Totem
		[GladiusEx:SafeGetSpellName(305485)]  	= 8,	-- Lightning Lasso 
		[GladiusEx:SafeGetSpellName(89766)]  	= 8,	-- Axe Toss
		[GladiusEx:SafeGetSpellName(30283)]  	= 8,	-- Shadowfury 
		[GladiusEx:SafeGetSpellName(132168)]  	= 8,	-- Shockwave 
		[GladiusEx:SafeGetSpellName(132169)]  	= 8,	-- Storm Bolt
		[GladiusEx:SafeGetSpellName(199085)]  	= 8,	-- Warpath
		[GladiusEx:SafeGetSpellName(20549)]  	= 8,	-- War Stomp
		[GladiusEx:SafeGetSpellName(255723)]  	= 8,	-- Bull Rush
		[GladiusEx:SafeGetSpellName(287712)]  	= 8,	-- Haymaker
		[GladiusEx:SafeGetSpellName(213491)]  	= 8,	-- Demonic Trample (Knockdown)
		[77505]				  	= 8,	-- Earthquake
		[GladiusEx:SafeGetSpellName(213688)]  	= 8,	-- Fel Cleave
		[GladiusEx:SafeGetSpellName(22703)]  	= 8,	-- Summon Infernal (stun)
		[323557]				= 8,	-- Ravenous Frenzy (self stun)
		[325886]				= 8,	-- Ancient Aftershock (initial) 
		[326062]				= 8,	-- Ancient Aftershock (main)


		-- Immunes II (7)

		[GladiusEx:SafeGetSpellName(212800)]  	= 7,	-- Blur
		[GladiusEx:SafeGetSpellName(48792)]  	= 7.1,	-- Icebound Fortitude
		[GladiusEx:SafeGetSpellName(48707)]  	= 7,	-- Anti-Magic Shell
		[206803]			  	= 7,	-- Rain from Above Initial
		[206804]			  	= 7,	-- Rain from Above Main
		[GladiusEx:SafeGetSpellName(198144)]  	= 7,	-- Ice Form 
		[GladiusEx:SafeGetSpellName(1022)]  	= 7,	-- Blessing of Protection
		[GladiusEx:SafeGetSpellName(213610)]  	= 7.1,	-- Holy Ward
		[329543]			  	= 7,	-- Divine Ascension Main
		[328530]			  	= 7,	-- Divine Ascension Initial
		[5277]				  	= 7,	-- Evasion
		[199027]			  	= 7,	-- Evasion2 post stealth
		[GladiusEx:SafeGetSpellName(409293)]  	= 7,	-- Burrow
		[GladiusEx:SafeGetSpellName(118038)]  	= 7,	-- Die by the Sword
		[GladiusEx:SafeGetSpellName(236321)]  	= 7,	-- War Banner 
		[323524]			  	= 7.1,	-- Ultimate Form (Fleshcraft cc immune)


		-- Defensives I (6.5)

		[GladiusEx:SafeGetSpellName(209426)]  	= 6.5,	-- Darkness
		[GladiusEx:SafeGetSpellName(198111)]  	= 6.5,	-- Temporal Shield
		[GladiusEx:SafeGetSpellName(116849)]  	= 6.5,	-- Life Cocoon 
		[125174]			  	= 6.5,	-- Touch of Karma (buff)
		[199448]			  	= 6.5,	-- Blessing of Sacrifice (pvp tal)
		[GladiusEx:SafeGetSpellName(232707)]  	= 6.5,	-- Ray of Hope (+)
		[GladiusEx:SafeGetSpellName(232708)]  	= 6.5,	-- Ray of Hope (-)
		[GladiusEx:SafeGetSpellName(47788)]  	= 6.5,	-- Guardian Spirit
		[GladiusEx:SafeGetSpellName(47585)]  	= 6.5,	-- Dispersion
		[45182]				  	= 6.5,	-- Cheat Death
		[116888]			  	= 6.5,	-- Purgatory
		[87023]				  	= 6.5,	-- Cauterize (duration)


		-- Immunes III (6)
		[GladiusEx:SafeGetSpellName(8178)]  	= 6.4,	-- Grounding Totem Effect



		[335255]			  	= 6.1,	-- Spell Reflection (legy)(party reflect)



		[GladiusEx:SafeGetSpellName(23920)]  	= 6,	-- Spell Reflection
		[GladiusEx:SafeGetSpellName(49039)]  	= 6,	-- Lichborne
		[GladiusEx:SafeGetSpellName(212704)]  	= 6,	-- The Beast Within
		[GladiusEx:SafeGetSpellName(248519)]  	= 6,	-- Interlope1 (bm pet redirect)
		[202248]			  	= 6,	-- Zen Meditation (spells redirected to monk)
		[GladiusEx:SafeGetSpellName(204018)]  	= 6,	-- Blessing of Spellwarding
		[GladiusEx:SafeGetSpellName(31224)]  	= 6,	-- Cloak of Shadows
		[GladiusEx:SafeGetSpellName(212295)]  	= 6,	-- Nether Ward
		[GladiusEx:SafeGetSpellName(18499)]  	= 6,	-- Berserker Rage
		[GladiusEx:SafeGetSpellName(317929)]  	= 6,	-- Concentration Aura (enhanced via Aura Mastery)


		-- Important I (5.5)

		[115176]			  	= 5.5,	-- Zen Meditation (cast)
		[205629]			  	= 5.5,	-- Demonic Trample (like freedom)
		[342246]			  	= 5.5,	-- Alter Time (Arcane)
		[110909]			  	= 5.5,	-- Alter Time (Fire Frost)
		[GladiusEx:SafeGetSpellName(209584)]  	= 5.5,	-- Zen Focus Tea
		[GladiusEx:SafeGetSpellName(213664)]  	= 5.5,	-- Nimble Brew 
		[GladiusEx:SafeGetSpellName(210256)]  	= 5.5,	-- Blessing of Sanctuary
		[GladiusEx:SafeGetSpellName(210294)]  	= 4,	-- Divine Favor
		[GladiusEx:SafeGetSpellName(289655)]  	= 5.5,	-- Holy Word: Concentration
		[GladiusEx:SafeGetSpellName(115192)]  	= 5.5,	-- Subterfuge
		[GladiusEx:SafeGetSpellName(290641)]  	= 5.5,	-- Ancestral Gift (pvp tal aura mastery)
		[GladiusEx:SafeGetSpellName(207498)]  	= 5.5,	-- Ancestral Protection Totem
		[256948]  				= 5.5,	-- Spatial Rift 
		[77606]				  	= 5.5,	-- Dark Simulacrum
		[325153]			  	= 5.5,	-- Exploding Keg (miss attacks)
		[GladiusEx:SafeGetSpellName(212150)]  	= 5.5,	-- Cheap Tricks
		[315443]				= 5.4,	-- Abomination Limb
		[323673]				= 5.5,	-- Mindgames


		-- Unbreakable CC and Roots (5)

		[GladiusEx:SafeGetSpellName(197214)]  	= 5,	-- Sundering 
		[GladiusEx:SafeGetSpellName(6789)]  	= 5,	-- Mortal Coil 
		[GladiusEx:SafeGetSpellName(47476)]  	= 5,	-- Strangulate 
		[GladiusEx:SafeGetSpellName(204490)]  	= 5,	-- Sigil of Silence
		[GladiusEx:SafeGetSpellName(81261)]  	= 5,	-- Solar Beam 
		[202933]			  	= 5,	-- Spider Sting 
		[217824]			  	= 5,	-- Shield of Virtue
		[317589]			  	= 5,	-- Mirrors of Torment
		[GladiusEx:SafeGetSpellName(15487)]  	= 5,	-- Silence
		[GladiusEx:SafeGetSpellName(1330)]  	= 5,	-- Garrote
		[204085]			  	= 5,	-- Deathchill (Chains of Ice)
		[233395]			  	= 5,	-- Deathchill (Remorseless Winter)
		[GladiusEx:SafeGetSpellName(339)]  	= 5,	-- Entangling Roots
		[GladiusEx:SafeGetSpellName(170855)]  	= 5,	-- Entangling Roots (ironbark)
		[GladiusEx:SafeGetSpellName(102359)]  	= 5,	-- Mass Entanglement 
		[117526]			  	= 5,	-- Binding Shot
		[162480]			  	= 5,	-- Steel Trap 
		[212638]			  	= 5,	-- Tracker's Net (miss atks)
		[GladiusEx:SafeGetSpellName(122)]  	= 5,	-- Frost Nova
		[GladiusEx:SafeGetSpellName(33395)]  	= 5,	-- Freeze (Water Elemental)
		[GladiusEx:SafeGetSpellName(198121)]  	= 5,	-- Frostbite
		[116706]			  	= 5,	-- Disable
		[GladiusEx:SafeGetSpellName(324382)]  	= 5,	-- Clash
		[GladiusEx:SafeGetSpellName(64695)]  	= 5,	-- Earthgrab Totem 
		[GladiusEx:SafeGetSpellName(285515)]  	= 5,	-- Surge of Power (frost shock root) 
		[GladiusEx:SafeGetSpellName(209749)]  	= 5,	-- Faerie Swarm
		[GladiusEx:SafeGetSpellName(233759)]  	= 5,	-- Grapple Weapon
		[GladiusEx:SafeGetSpellName(207777)]  	= 5,	-- Dismantle
		[GladiusEx:SafeGetSpellName(236077)]  	= 5,	-- Disarm 
		[GladiusEx:SafeGetSpellName(91807)]  	= 5,	-- Leap (pet transformed)
		[GladiusEx:SafeGetSpellName(45334)]  	= 5,	-- Immobilized (wild charge) 
		[GladiusEx:SafeGetSpellName(190925)]  	= 5,	-- Harpoon
		[GladiusEx:SafeGetSpellName(157997)]  	= 5,	-- Ice Nova
		[GladiusEx:SafeGetSpellName(228600)]  	= 5,	-- Glacial Spike
		[GladiusEx:SafeGetSpellName(87204)]  	= 5,	-- Sin and Punishment
		[198222]			  	= 5,	-- System Shock (pvp talent 90% slow) 
		[196364]			  	= 5,	-- Unstable Affliction Silence Effect
		[GladiusEx:SafeGetSpellName(105771)]  	= 5,	-- Charge root 
		[199042]			  	= 5,	-- Thunderclap root
		[201787]			  	= 5,	-- Turbo Fist
		[323996]			  	= 5,	-- The Hunt
		[339309]			  	= 5,	-- Everchill Brambles


		-- Defensives II (4.5)

		[GladiusEx:SafeGetSpellName(145629)]  	= 4.5,	-- Anti-Magic Zone
		[GladiusEx:SafeGetSpellName(198065)]  	= 4.5,	-- Prismatic Cloak
		[GladiusEx:SafeGetSpellName(102342)]  	= 4.5,	-- Ironbark
		[GladiusEx:SafeGetSpellName(61336)]  	= 4.5,	-- Survival Instincts
		[GladiusEx:SafeGetSpellName(202748)]  	= 4.5,	-- Survival Tactics 
		[113862]			  	= 4.5,	-- During/After Greater Invisibility (60% dmg reduc)
		[GladiusEx:SafeGetSpellName(122783)]  	= 4.5,	-- Diffuse Magic
		[GladiusEx:SafeGetSpellName(122278)]  	= 4.5,	-- Dampen Harm
		[6940]				  	= 4.5,	-- Blessing of Sacrifice
		[GladiusEx:SafeGetSpellName(31850)]  	= 4.5,	-- Ardent Defender
		[GladiusEx:SafeGetSpellName(86659)]  	= 4.5,	-- Guardian of Ancient Kings (P wall)
		[GladiusEx:SafeGetSpellName(33206)]  	= 4.5,	-- Pain Suppression
		[GladiusEx:SafeGetSpellName(81782)]  	= 4.5,	-- Power Word: Barrier
		[GladiusEx:SafeGetSpellName(108271)]  	= 4.5,	-- Astral Shift
		[GladiusEx:SafeGetSpellName(201633)]  	= 4.5,	-- Earthen Wall Totem
		[325174]			  	= 4.5,	-- Spirit Link Totem
		[GladiusEx:SafeGetSpellName(118337)]  	= 4.5,	-- Harden Skin (Earth Elementalist)
		[GladiusEx:SafeGetSpellName(104773)]  	= 4.5,	-- Unending Resolve
		[GladiusEx:SafeGetSpellName(871)]  	= 4.5,	-- Shield Wall
		[GladiusEx:SafeGetSpellName(184364)]  	= 4.5,	-- Enraged Regeneration
		[327037]			  	= 4.5,	-- Kindred Spirits (- 40% dmg taken)



		-- Important II (4)

		[GladiusEx:SafeGetSpellName(48265)]  	= 4,	-- Death's Advance
		[GladiusEx:SafeGetSpellName(212552)]  	= 4,	-- Wraith Walk
		[GladiusEx:SafeGetSpellName(188501)]  	= 4,	-- Spectral Sight 
		[GladiusEx:SafeGetSpellName(234084)]  	= 4,	-- Moon and Stars (kick reduction)
		[GladiusEx:SafeGetSpellName(29166)]  	= 4,	-- Innervate
		[305497]			  	= 4,	-- Thorns
		[GladiusEx:SafeGetSpellName(247563)]  	= 4,	-- Entangling Bark (iron bark roots)
		[102401]			  	= 4,	-- Wild Charge (human form)
		[GladiusEx:SafeGetSpellName(252071)]  	= 4,	-- Incarnation (1-time restealth buff)
		[GladiusEx:SafeGetSpellName(132158)]  	= 4,	-- Nature's Swiftness
		[GladiusEx:SafeGetSpellName(54216)]  	= 4,	-- Master's Call
		[GladiusEx:SafeGetSpellName(108839)]  	= 4,	-- Ice Floes
		[290500]			  	= 4,	-- Wind Waker
		[GladiusEx:SafeGetSpellName(201447)]  	= 4,	-- Ride the Wind
		[GladiusEx:SafeGetSpellName(202335)]  	= 4,	-- Double Barrel
		[1044]				  	= 4,	-- Blessing of Freedom
		[305395]			  	= 4,	-- Blessing of Freedom (P/R pvp tal)
		[199545] 			 	= 4,	-- Steed of Glory (P pvp tal)
		[215652]			  	= 4,	-- Shield of Virtue
		[GladiusEx:SafeGetSpellName(73325)]  	= 4,	-- Leap of Faith
		[322431]			  	= 4,	-- Thoughtsteal
		[322464]			  	= 4,	-- Thoughtsteal (Mage)
		[322463]				= 4,	-- Thoughtsteal (Warlock)
		[322457]				= 4,	-- Thoughtsteal (Paladin)
		[322459]				= 4,	-- Thoughtsteal (Shaman)
		[322460]				= 4,	-- Thoughtsteal (Priest)
		[GladiusEx:SafeGetSpellName(197003)]  	= 4,	-- Maneuverability
		[GladiusEx:SafeGetSpellName(221705)]  	= 4,	-- Casting Circle
		[GladiusEx:SafeGetSpellName(328774)]  	= 4,	-- Amplify Curse
		[198817]			  	= 4,	-- Sharpen Blade
		[122470]			  	= 4,	-- Touch of Karma (debuff)
		[199845]			  	= 4,	-- Psyfiend
		[GladiusEx:SafeGetSpellName(212183)]  	= 4,	-- Smoke Bomb
		[198819]			  	= 4,	-- Sharpen Blade (target)
		[GladiusEx:SafeGetSpellName(80240)]  	= 4,	-- Havoc
		[GladiusEx:SafeGetSpellName(1714)]  	= 4,	-- Curse of Tongues
		[GladiusEx:SafeGetSpellName(199954)]  	= 4,	-- Bane of Fragility
		[GladiusEx:SafeGetSpellName(34709)]  	= 4,	-- Shadow Sight (eye in arena)
		[330752]			  	= 4,	-- Phial of Serenity (immune to DoTs)
		[334722]			  	= 4,	-- Grip of the Everlasting (legy)
		[343249]			  	= 4,	-- Escape from Reality (legy)(port again)
		[332505]			  	= 4,	-- Soulsteel Clamps 1
		[332506]			  	= 4,	-- Soulsteel Clamps 2
		[339445]			  	= 4,	-- Norgannon's Sagacity
		[307871]			  	= 4,	-- Spear of Bastion


		-- Offensives I (3)

		[GladiusEx:SafeGetSpellName(51271)]  	= 3,	-- Pillar of Frost
		[GladiusEx:SafeGetSpellName(152279)]  	= 3,	-- Breath of Sindragosa 
		[162264]			  	= 3,	-- Metamorphosis (H)
		[GladiusEx:SafeGetSpellName(102560)]  	= 3,	-- Incarnation: Chosen of Elune
		[GladiusEx:SafeGetSpellName(102543)]  	= 3,	-- Incarnation: King of the Jungle
		[GladiusEx:SafeGetSpellName(102558)]  	= 3,	-- Incarnation: Guardian of Ursoc
		[GladiusEx:SafeGetSpellName(194223)]  	= 3,	-- Celestial Alignment
		[GladiusEx:SafeGetSpellName(106951)]  	= 3,	-- Berserk (feral)
		[GladiusEx:SafeGetSpellName(50334)]  	= 3,	-- Berserk (guardian)
		[GladiusEx:SafeGetSpellName(108292)]  	= 3,	-- Heart of the Wild (feral affinity)
		[GladiusEx:SafeGetSpellName(108291)]  	= 3,	-- Heart of the Wild (balance affinity)
		[GladiusEx:SafeGetSpellName(19574)]  	= 3,	-- Bestial Wrath
		[GladiusEx:SafeGetSpellName(288613)]  	= 3,	-- Trueshot 
		[GladiusEx:SafeGetSpellName(266779)]  	= 3,	-- Coordinated Assault 
		[GladiusEx:SafeGetSpellName(12042)]  	= 3,	-- Arcane Power
		[GladiusEx:SafeGetSpellName(12472)]  	= 3,	-- Icy Veins 
		[GladiusEx:SafeGetSpellName(190319)]  	= 3,	-- Combustion
		[GladiusEx:SafeGetSpellName(137639)]  	= 3,	-- SEF
		[247483]			  	= 3,	-- Tigereye Brew
		[GladiusEx:SafeGetSpellName(231895)]  	= 3,	-- Crusade
		[GladiusEx:SafeGetSpellName(31884)]  	= 3,	-- Avenging Wrath
		[GladiusEx:SafeGetSpellName(216331)]  	= 3,	-- Avenging Crusader
		[GladiusEx:SafeGetSpellName(185422)]  	= 3,	-- Shadow Dance
		[GladiusEx:SafeGetSpellName(13750)]  	= 3,	-- Adrenaline Rush 
		[GladiusEx:SafeGetSpellName(51690)]  	= 3,	-- Killing Spree
		[114050]  	= 3,	-- Ascendance ele
		[114051]  	= 3,	-- Ascendance enha
		[GladiusEx:SafeGetSpellName(204362)]  	= 3,	-- Heroism  
		[GladiusEx:SafeGetSpellName(204361)]  	= 3,	-- Bloodlust
		[GladiusEx:SafeGetSpellName(113858)]  	= 3,	-- Dark Soul: Instability
		[GladiusEx:SafeGetSpellName(113860)]  	= 3,	-- Dark Soul: Misery
		[GladiusEx:SafeGetSpellName(265273)]  	= 3,	-- Summon Demonic Tyrant
		[GladiusEx:SafeGetSpellName(107574)]  	= 3,	-- Avatar
		[GladiusEx:SafeGetSpellName(199261)]  	= 3,	-- Death Wish
		[GladiusEx:SafeGetSpellName(1719)]  	= 3,	-- Recklessness
		[GladiusEx:SafeGetSpellName(343142)]  	= 3,	-- Dreadblades
		[GladiusEx:SafeGetSpellName(79140)]  	= 3,	-- Vendetta
		[347765] 			 	= 3,	-- Fodder to the Flame
		[323764] 			 	= 3,	-- Convoke the Spirits
		[333100]			  	= 3,	-- Firestorm
		[340094] 			 	= 3,	-- Mark of the Master Assassin
		[345019] 			 	= 3.1,	-- Skulker's Wing


		-- Defensives III (2.5)

		[GladiusEx:SafeGetSpellName(81256)]  	= 2.5,	-- Dancing Rune Weapon (40% parry)
		[GladiusEx:SafeGetSpellName(55233)]  	= 2.5,	-- Vampiric Blood
		[GladiusEx:SafeGetSpellName(288977)]  	= 2.5,	-- Transfusion
		[GladiusEx:SafeGetSpellName(194679)]  	= 2.5,	-- Rune Tap
		[GladiusEx:SafeGetSpellName(219809)]  	= 2.5,	-- Tombstone (B massive absorb)
		[187827]			  	= 2.5,	-- Metamorphosis (V)
		[GladiusEx:SafeGetSpellName(263648)]  	= 2.5,	-- Soul Barrier (V big absorb)
		[GladiusEx:SafeGetSpellName(22812)]  	= 2.5,	-- Barkskin
		[GladiusEx:SafeGetSpellName(192081)]  	= 2.5,	-- Ironfur
		[GladiusEx:SafeGetSpellName(117679)]  	= 2.5,	-- Incarnation: Tree of Life
		[GladiusEx:SafeGetSpellName(22842)]  	= 2.5,	-- Frenzied Regen
		[GladiusEx:SafeGetSpellName(53480)]  	= 2.5,	-- Roar of Sacrifice
		[GladiusEx:SafeGetSpellName(272679)]  	= 2.5,	-- Survival of the Fittest
		[GladiusEx:SafeGetSpellName(243435)]  	= 2.5,	-- Fortifying Brew (M, W)
		[GladiusEx:SafeGetSpellName(120954)]  	= 2.5,	-- Fortifying Brew (B)
		[GladiusEx:SafeGetSpellName(322507)]  	= 2.5,	-- Celestial Brew
		[GladiusEx:SafeGetSpellName(498)]  	= 2.5,	-- Divine Protection
		[GladiusEx:SafeGetSpellName(199507)]  	= 2.5,	-- Spreading The Word
		[GladiusEx:SafeGetSpellName(205191)]  	= 2.5,	-- Eye for an Eye
		[GladiusEx:SafeGetSpellName(184662)]  	= 2.5,	-- Shield of Vengeance
		[GladiusEx:SafeGetSpellName(47536)]  	= 2.5,	-- Rapture
		[GladiusEx:SafeGetSpellName(109964)]  	= 2.5,	-- Spirit Shell
		[GladiusEx:SafeGetSpellName(1966)]  	= 2.5,	-- Feint
		[GladiusEx:SafeGetSpellName(114052)]  	= 2.5,	-- Ascendance resto
		[GladiusEx:SafeGetSpellName(108416)]  	= 2.5,	-- Dark Pact
		[GladiusEx:SafeGetSpellName(132413)]  	= 2.5,	-- Shadow Bulwark (Grimoire talent)
		[GladiusEx:SafeGetSpellName(97463)]  	= 2.5,	-- Rallying Cry
		[GladiusEx:SafeGetSpellName(12975)]  	= 2.5,	-- Last Stand
		[GladiusEx:SafeGetSpellName(132404)]  	= 2.5,	-- Shield Block
		[66]				  	= 2.5,	-- Invisibility (initial)
		[GladiusEx:SafeGetSpellName(291944)]  	= 2.5,	-- Regeneratin'
		[GladiusEx:SafeGetSpellName(20578)]  	= 2.5,	-- Cannibalize
		[GladiusEx:SafeGetSpellName(48743)]  	= 2.5,	-- Death Pact (big absorb+healing reduced)
		[334555]			  	= 2.5,	-- Vampiric Blood (legy)(party cd)
		[327071]			  	= 2.5,	-- Kindred Spirits (+ 30% healing received)
		[337984]			  	= 2.5,	-- Vital Accretion
		[335635]			  	= 2.5,	-- Unbreakable Will (legy)
		[330749]			  	= 2.5,	-- Phial of Serenity (Soulbind HoT)
		[336465]			  	= 2.5,	-- Overflowing Ember Mirror (20%wall)
		[344231]			  	= 2.5,	-- Sanguine Vintage (big absorb)
		[329849]			  	= 2.5,	-- Blood-Spattered Scale (big absorb)
		[311444]			  	= 2.5,	-- Darkmoon Deck: Indomitable (absorb 5 stacks)
		[344916]			  	= 2.5,	-- Tuft of Smoldering Plumage
		[344388]			  	= 2.5,	-- Bargast's Leash (25% redirect wall)
		[336866]			  	= 2.5,	-- Brimming Ember Shard (massive heal)
		[339516]			  	= 2.5,	-- Glimmerdust's Grand Design (big absorb)
		[334555]			  	= 2.5,	-- Vampiric Blood (legy)
 
		-- Offensives II (2)

		[GladiusEx:SafeGetSpellName(207289)]  	= 2,	-- Unholy Assault (old Frenzy)
		[GladiusEx:SafeGetSpellName(47568)]  	= 2,	-- Empower Rune Weapon
		[GladiusEx:SafeGetSpellName(202425)]  	= 2,	-- Warrior of Elune (3 instant Starfires)
		[GladiusEx:SafeGetSpellName(5217)]  	= 2,	-- Tiger's Fury
		[GladiusEx:SafeGetSpellName(260402)]  	= 2,	-- Double Tap
		[GladiusEx:SafeGetSpellName(186289)]  	= 2,	-- Aspect of the Eagle
		[GladiusEx:SafeGetSpellName(116014)]  	= 2,	-- Rune of Power 
		[GladiusEx:SafeGetSpellName(205025)]  	= 2,	-- Presence of Mind
		[GladiusEx:SafeGetSpellName(342242)]  	= 2,	-- Time Warp (tal proc)
		[206432]			  	= 2,	-- Burst of Cold (buffed Cone of Cold)
		[287504]			  	= 2,	-- Alpha Tiger (Tiger Palm burst window)
		[GladiusEx:SafeGetSpellName(105809)]  	= 2,	-- Holy Avenger
		[GladiusEx:SafeGetSpellName(194249)]  	= 2,	-- Void Eruption
		[GladiusEx:SafeGetSpellName(197871)]  	= 2,	-- Dark Archangel
		[GladiusEx:SafeGetSpellName(10060)]  	= 2,	-- Power Infusion
		[GladiusEx:SafeGetSpellName(322105)]  	= 2,	-- Shadow Covenant
		[GladiusEx:SafeGetSpellName(247776)]  	= 2,	-- Mind Trauma
		[GladiusEx:SafeGetSpellName(121471)]  	= 2,	-- Shadow Blades
		[198529]			  	= 2,	-- Plunder Armor
		[GladiusEx:SafeGetSpellName(221630)]  	= 2,	-- Tricks of the Trade
		[GladiusEx:SafeGetSpellName(213981)]  	= 2,	-- Cold Blood
		[GladiusEx:SafeGetSpellName(208963)]  	= 2,	-- Skyfury Totem
		[GladiusEx:SafeGetSpellName(320125)]  	= 2,	-- Echoing Shock
		[GladiusEx:SafeGetSpellName(210714)]  	= 2,	-- Icefury (frost shock dmg increased)
		[GladiusEx:SafeGetSpellName(191634)]  	= 2,	-- Stormkeeper (ele)
		[GladiusEx:SafeGetSpellName(320137)]  	= 2,	-- Stormkeeper (enh)
		[GladiusEx:SafeGetSpellName(51533)]  	= 2,	-- Feral Spirit
		[GladiusEx:SafeGetSpellName(215785)]  	= 2,	-- Hot Hand (enhance burst window)
		[GladiusEx:SafeGetSpellName(334320)]  	= 2,	-- Inevitable Demise (stacks to 50)
		[GladiusEx:SafeGetSpellName(344566)]  	= 2,	-- Rapid Contagion
		[GladiusEx:SafeGetSpellName(267218)]  	= 2,	-- Nether Portal
		[GladiusEx:SafeGetSpellName(262228)]  	= 2,	-- Deadly Calm
		[GladiusEx:SafeGetSpellName(273104)]  	= 2,	-- Fireblood
		[269651]			  	= 2,	-- Pyroclasm (casted Pyro deals 240% more dmg)
		[203285] 			 	= 2,	-- Flamecannon (buff dropped when mage moves)
		[327022]			  	= 2,	-- Kindred Spirits
		[333315]			  	= 2,	-- Sun King's Blessing
		[335903]  				= 2,	-- Doom Winds
		[325013]			  	= 2,	-- Boon of the Ascended


		-- Misc (1)

		[GladiusEx:SafeGetSpellName(329042)]  	= 1,	-- Roar of the Protector
		[GladiusEx:SafeGetSpellName(108294)]  	= 1,	-- Heart of the Wild (resto affinity)
		[GladiusEx:SafeGetSpellName(108293)]  	= 1,	-- Heart of the Wild (guardian affinity)
		[GladiusEx:SafeGetSpellName(212640)]  	= 1,	-- Mending Bandage 
		[GladiusEx:SafeGetSpellName(202162)]  	= 1,	-- Avert Harm (B pvp tal)
		[GladiusEx:SafeGetSpellName(157128)]  	= 1,	-- Saved by the Light
		[GladiusEx:SafeGetSpellName(19236)]  	= 1,	-- Desperate Prayer
		[GladiusEx:SafeGetSpellName(185311)]  	= 1,	-- Crimson Vial
		[GladiusEx:SafeGetSpellName(212198)]  	= 1,	-- Create: Crimson Vial (pvp talent)
		[2645]				  	= 1,	-- Ghost Wolf
		[GladiusEx:SafeGetSpellName(213871)]  	= 1,	-- Bodyguard
		[GladiusEx:SafeGetSpellName(386208)]  	= 1,	-- Defensive Stance
		[GladiusEx:SafeGetSpellName(191034)]  	= 1,	-- Starfall (cast while moving tal)
		[GladiusEx:SafeGetSpellName(31821)]  	= 1,	-- Aura Mastery 
		[GladiusEx:SafeGetSpellName(79206)]  	= 1,	-- Spiritwalkers Grace
		[GladiusEx:SafeGetSpellName(320763)]  	= 1,	-- Mana Tide Totem
		[GladiusEx:SafeGetSpellName(333889)]  	= 1,	-- Fel Domination
		[GladiusEx:SafeGetSpellName(1850)]  	= 1,	-- Dash
		[GladiusEx:SafeGetSpellName(252216)]  	= 1,	-- Tiger Dash
		[GladiusEx:SafeGetSpellName(186257)]  	= 1,	-- Aspect of the Cheetah
		[GladiusEx:SafeGetSpellName(203233)]  	= 1,	-- Aspect of the Cheetah (honor talent)
		[GladiusEx:SafeGetSpellName(116841)]  	= 1,	-- Tiger's Lust
		[GladiusEx:SafeGetSpellName(276111)]  	= 1,	-- Divine Steed
		[GladiusEx:SafeGetSpellName(36554)]  	= 1,	-- Shadowstep
		[GladiusEx:SafeGetSpellName(2983)]  	= 1,	-- Sprint
		[GladiusEx:SafeGetSpellName(206940)]  	= 1,	-- Mark of Blood
		[51399]				  	= 1,	-- Death Grip (on target debuff)
		[GladiusEx:SafeGetSpellName(206649)]  	= 1,	-- Eye of Leotheras
		[GladiusEx:SafeGetSpellName(127797)]  	= 1,	-- Ursol's Vortex
		[GladiusEx:SafeGetSpellName(50259)]  	= 1,	-- Wild Charge (cat form)
		[GladiusEx:SafeGetSpellName(200947)]  	= 1,	-- High Winds
		[GladiusEx:SafeGetSpellName(132951)]  	= 1.1,	-- Flare
		[GladiusEx:SafeGetSpellName(257284)]  	= 1,	-- Hunter's Mark
		[GladiusEx:SafeGetSpellName(41425)]  	= 1,	-- Hypothermia
		[GladiusEx:SafeGetSpellName(25771)]  	= 1,	-- Forbearance
		[198529]			  	= 1,	-- Plunder Armor (target)
		[GladiusEx:SafeGetSpellName(198688)]  	= 1,	-- Dagger in the Dark
		[GladiusEx:SafeGetSpellName(208997)]  	= 1,	-- Counterstrike Totem
		[GladiusEx:SafeGetSpellName(200587)]  	= 1,	-- Fel Fissure
		[GladiusEx:SafeGetSpellName(212580)]  	= 1,	-- Eye of the Observer
		[GladiusEx:SafeGetSpellName(236273)]  	= 1,	-- Duel
		[GladiusEx:SafeGetSpellName(206891)]  	= 1,	-- Taunt stacks
		[GladiusEx:SafeGetSpellName(702)]  	= 1,	-- Curse of Weakness
		[GladiusEx:SafeGetSpellName(234877)]  	= 1,	-- Bane of Shadows
		[GladiusEx:SafeGetSpellName(202797)]  	= 1,	-- Viper Sting
		[GladiusEx:SafeGetSpellName(202900)]  	= 1,	-- Scorpid Sting
		[115196]			  	= 1,	-- Shiv (slow)
		[GladiusEx:SafeGetSpellName(206647)]  	= 1,	-- Electrocute
		[GladiusEx:SafeGetSpellName(200548)]  	= 1,	-- Bane of Havoc
		[314791]			  	= 1,	-- Shifting Power
		[347037]			  	= 1,	-- Sepsis (1 stealth ability)
		[310143]			  	= 1.1,	-- Soulshape
		[323710]			  	= 1.1,	-- Abomination Limb (can't be pulled)
		[317009]			  	= 1,	-- Sinful Brand
		[308498]			  	= 1.1,	-- Resonating Arrow (no los)
		[344021]			  	= 1,	-- Keefer's Skyreach (legy)
		[337164]			  	= 1,	-- Odr, Shawl of the Ymirjar (legy)
  }
end


function GladiusEx.Data.DefaultCooldowns()
	return {
		{ -- group 1
			--[28730] = true, -- BloodElf/Arcane Torrent
			--[107079] = true, -- Pandaren/Quaking Palm
			--[69070] = true, -- Goblin/Rocket Jump
			--[7744] = true, -- Scourge/Will of the Forsaken

			[108194] = true, -- Death Knight/Asphyxiate (Frost & Unholy)
			[221562] = true, -- Death Knight/Asphyxiate (Blood)
			[49576] = true, -- Death Knight/Death Grip
			[48792] = true, -- Death Knight/Icebound Fortitude
			[49039] = true, -- Death Knight/Lichborne
			[47528] = true, -- Death Knight/Mind Freeze
			[51271] = true, -- Death Knight/Pillar of Frost
			[152279] = true, -- Death Knight/Breath of Sindragosa
			[305392] = true, -- Death Knight/Chill Streak
			[47476] = true, -- Death Knight/Strangulate
			[48707] = true, -- Death Knight/Anti-Magic Shell
			[51052] = true, -- Death Knight/Anti-Magic Zone
			[77606] = true, -- Death Knight/Dark Simulacrum
			[48743] = true, -- Death Knight/Death Pact
			[55233] = true, -- Death Knight/Vampiric Blood
			[47476] = true, -- Death Knight/Strangulate
			[63560] = true, -- Death Knight/Dark Transformation
			[315443] = true, -- Death Knight/Abomination Limb

			[191427] = true, -- Demon Hunter/Metamorphosis (Havoc)
			[187827] = true, -- Demon Hunter/Metamorphosis (Vengeance)
			[196555] = true, -- Demon Hunter/Netherwalk
			[196718] = true, -- Demon Hunter/Darkness
			[198589] = true, -- Demon Hunter/Blur
			[183752] = true, -- Demon Hunter/Disrupt
			[278326] = true, -- Demon Hunter/Consume Magic
			[217832] = true, -- Demon Hunter/Imprison
			[221527] = true, -- Demon Hunter/Imprison (Detainment)
			[179057] = true, -- Demon Hunter/Chaos Nova
			[205604] = true, -- Demon Hunter/Reverse Magic
			[203704] = true, -- Demon Hunter/Mana Break
			[202137] = true, -- Demon Hunter/Sigil of Silence
			[204021] = true, -- Demon Hunter/Fiery Brand
			[323639] = true, -- Demon Hunter/The Hunt

			[22812] = true, -- Druid/Barkskin
			[33786] = true, -- Druid/Cyclone (feral)
			[99] = true, -- Druid/Disorienting Roar
			[102280] = true, -- Druid/Displacer Beast
			[108288] = true, -- Druid/Heart of the Wild
			[102342] = true, -- Druid/Ironbark
			[102359] = true, -- Druid/Mass Entanglement
			[5211] = true, -- Druid/Mighty Bash
			[88423] = true, -- Druid/Nature's Cure
			[132158] = true, -- Druid/Nature's Swiftness
			[2782] = true, -- Druid/Remove Corruption
			[78675] = true, -- Druid/Solar Beam
			[132469] = true, -- Druid/Typhoon
			[102793] = true, -- Druid/Ursol's Vortex
			[106839] = true, -- Druid/Skull Bash

			[19574] = true, -- Hunter/Bestial Wrath
			[19263] = true, -- Hunter/Deterrence
			[781] = true, -- Hunter/Disengage
			[1499] = true, -- Hunter/Freezing Trap
			[19577] = true, -- Hunter/Intimidation
			[23989] = true, -- Hunter/Readiness
			[50519] = true, -- Hunter/Sonic Blast
			[121818] = true, -- Hunter/Stampede
			[19386] = true, -- Hunter/Wyvern Sting

			[108843] = true, -- Mage/Blazing Speed
			[1953] = true, -- Mage/Blink
			[235219] = true, -- Mage/Cold Snap. V: changed ID in legion
			[2139] = true, -- Mage/Counterspell
			[122] = true, -- Mage/Frost Nova
			[45438] = true, -- Mage/Ice Block

			[115450] = true, -- Monk/Detox
			[122783] = true, -- Monk/Diffuse Magic
			[113656] = true, -- Monk/Fists of Fury
			[115203] = true, -- Monk/Fortifying Brew
			[119381] = true, -- Monk/Leg Sweep
			[116849] = true, -- Monk/Life Cocoon
			[115078] = true, -- Monk/Paralysis
			[115310] = true, -- Monk/Revival
			[116844] = true, -- Monk/Ring of Peace
			[116705] = true, -- Monk/Spear Hand Strike
			[116680] = true, -- Monk/Thunder Focus Tea
			[116841] = true, -- Monk/Tiger's Lust
			[122470] = true, -- Monk/Touch of Karma

			[115750] = true, -- Paladin/Blinding Light
			[4987] = true, -- Paladin/Cleanse
			[31821] = true, -- Paladin/Devotion Aura
			[642] = true, -- Paladin/Divine Shield
			[853] = true, -- Paladin/Hammer of Justice
			[96231] = true, -- Paladin/Rebuke
			[20066] = true, -- Paladin/Repentance

			[19236] = true, -- Priest/Desperate Prayer
			[47585] = true, -- Priest/Dispersion
			[47788] = true, -- Priest/Guardian Spirit
			[73325] = true, -- Priest/Leap of Faith
			[33206] = true, -- Priest/Pain Suppression
			[8122] = true, -- Priest/Psychic Scream
			[527] = true, -- Priest/Purify
			[15487] = true, -- Priest/Silence
			[10060] = true, -- Priest/Power Infusion

			[13750] = true, -- Rogue/Adrenaline Rush
			[2094] = true, -- Rogue/Blind
			[31224] = true, -- Rogue/Cloak of Shadows
			[1766] = true, -- Rogue/Kick
			[137619] = true, -- Rogue/Marked for Death
			[121471] = true, -- Rogue/Shadow Blades
			[185313] = true, -- Rogue/Shadow Dance. V: changed ID in legion
			[76577] = true, -- Rogue/Smoke Bomb
			[1856] = true, -- Rogue/Vanish
			[79140] = true, -- Rogue/Vendetta

			[114049] = true, -- Shaman/Ascendance
			[51886] = true, -- Shaman/Cleanse Spirit
			[108280] = true, -- Shaman/Healing Tide Totem
			[51514] = true, -- Shaman/Hex
			[77130] = true, -- Shaman/Purify Spirit
			[113286] = true, -- Shaman/Solar Beam
			[98008] = true, -- Shaman/Spirit Link Totem
			[79206] = true, -- Shaman/Spiritwalker's Grace
			[51490] = true, -- Shaman/Thunderstorm
			[57994] = true, -- Shaman/Wind Shear

			[89766] = true, -- Warlock/Axe Toss
			[48020] = true, -- Warlock/Demonic Circle: Teleport
			[5484] = true, -- Warlock/Howl of Terror
			[6789] = true, -- Warlock/Mortal Coil
			[115781] = true, -- Warlock/Optical Blast
			[30283] = true, -- Warlock/Shadowfury
			[89808] = true, -- Warlock/Singe Magic
			[19647] = true, -- Warlock/Spell Lock
			[104773] = true, -- Warlock/Unending Resolve

			[107574] = true, -- Warrior/Avatar
			[118038] = true, -- Warrior/Die by the Sword
			[5246] = true, -- Warrior/Intimidating Shout
			[6552] = true, -- Warrior/Pummel
			[1719] = true, -- Warrior/Recklessness
			[871] = true, -- Warrior/Shield Wall
			[46968] = true, -- Warrior/Shockwave
			[23920] = true, -- Warrior/Spell Reflection
		},
		{ -- group 2
			[336126] = true, -- Gladiator's Medallion
			[336135] = true, -- Adaptation
			[336128] = true, -- Relentless
			[363117] = true, -- Fastidious Resolve
			[363121] = true, -- Echoing Resolve
		}
	}
end

function GladiusEx.Data.Interrupts()
	return {
	  [6552] = {duration=3},    -- [Warrior] Pummel
	  [96231] = {duration=3},   -- [Paladin] Rebuke
	  [231665] = {duration=3},  -- [Paladin] Avengers Shield
	  [147362] = {duration=3},  -- [Hunter] Countershot
	  [187707] = {duration=3},  -- [Hunter] Muzzle
	  [1766] = {duration=3},    -- [Rogue] Kick
	  [183752] = {duration=3},  -- [DH] Consume Magic
	  [47528] = {duration=3},   -- [DK] Mind Freeze
	  [91802] = {duration=2},   -- [DK] Shambling Rush
	  [57994] = {duration=2},   -- [Shaman] Wind Shear
	  [115781] = {duration=5},  -- [Warlock] Optical Blast
	  [19647] = {duration=5},   -- [Warlock] Spell Lock
	  [212619] = {duration=5},  -- [Warlock] Call Felhunter
	  [132409] = {duration=5},  -- [Warlock] Spell Lock
	  [171138] = {duration=5},  -- [Warlock] Shadow Lock
	  [2139] = {duration=5},    -- [Mage] Counterspell
	  [116705] = {duration=3},  -- [Monk] Spear Hand Strike
	  [106839] = {duration=3},  -- [Feral] Skull Bash
	  [93985] = {duration=3},   -- [Feral] Skull Bash
	  [97547] = {duration=4},   -- [Moonkin] Solar Beam
	  [351338] = {duration=4},  -- [Evoker] Quell
	}
end

function GladiusEx.Data.InterruptModifiers()
return {
    [GladiusEx:SafeGetSpellName(317920)] = 0.7, -- Concentration Aura
  }
end

function GladiusEx.Data.GetSpecializationInfoByID(id)
  return GetSpecializationInfoByID(id)
end

function GladiusEx.Data.GetNumSpecializationsForClassID(classID)
    return GetNumSpecializationsForClassID(classID)
end

function GladiusEx.Data.GetSpecializationInfoForClassID(classID, specIndex)
    return GetSpecializationInfoForClassID(classID, specIndex)
end

function GladiusEx.Data.GetArenaOpponentSpec(id)
    return GetArenaOpponentSpec(id)
end

function GladiusEx.Data.CountArenaOpponents()
    return GetNumArenaOpponentSpecs()
end

function GladiusEx.Data.GetNumArenaOpponentSpecs()
    return GetNumArenaOpponentSpecs()
end
