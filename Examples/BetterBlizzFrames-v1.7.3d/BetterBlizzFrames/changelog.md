# BetterBlizzFrames 1.7.3d
## Retail
### Tweak
- Fix some lines from OCD Tweaks setting meant to fill gaps on PlayerFrame gaps still showing when using MiniFrame setting for PlayerFrame.
## MoP/Cata/Wrath
### Tweak
- Settings with checks for Dragonflight UI now only sends a chat message it might conflict with DFUI but does not turn the setting off unless specificaly mentioned.

# BetterBlizzFrames 1.7.3c
## MoP/Cata/Wrath
### Tweak
- Added check for Dragonflight UI before enabling OCD Tweaks and Class Color Frames to avoid conflicts. Will be turned off if DF UI is enabled (Use the settings in DF UI instead for those).
- SettingsPanel now resets to its default location between reloads as intended. If you really dont want to be able to drag-and-move this at all then type /run BetterBlizzFramesDB.dontMoveSettingsPanel = true

# BetterBlizzFrames 1.7.3b
## Retail
### Bugfix
- Fix "Color FrameTexture" setting not working properly for Target ToT and Focus ToT
## Cata/Wrath
### Bugfix
- Fix new Format Numbers lua file missing reference in the toc file on Wrath/Cata causing lua errors

# BetterBlizzFrames 1.7.3
## Retail
### New
- Hide ActionBar1 (Misc) (Edit Mode wont let you)
### Bugfix
- Fix font settings for default PartyFrames' health & mana text not working.
- Fix issue with healthbar color + changed texture
## Mists of Pandaria
### New
- Format Numbers setting (under "All Frames" in /bbf). 
### Tweak
- Minor tweaks to Important Glow texture positions and some minor bugfixes with its size depending on settings.
## All versions
### Bugfix
- Fix some minor issues with castbar "ToT Offset" settings impacting both default castbar movement and with Aura Filtering enabled.


# BetterBlizzFrames 1.7.2d
## Retail
### Bugfix
- Fix errror in Format Numbers due to nil unit on dead check.

# BetterBlizzFrames 1.7.2b-c
## Retail
### Tweak
- Add missing AlternateFrameTexture (Shadow Priest etc) to "Color Frame Texture" setting.
### Bugfix
- Fix "Simple Castbar" setting for Player Castbar sometimes displaying text shadow texture again.
- Fix Format Numbers displaying numbers when unit was dead.
- Fix overlapping alternate manabar text with always show manabar for rdruid setting.
## Mists of Pandaria
### New
- Added Icon XY sliders for Player Castbar Icon
### Tweak
- Player Castbar Icon moved down 2 pixels to align properly with the castbar.
### Bugfix
- Bigger Healthbars: Fix TargetFrame/FocusFrame threat glow texture sometimes resetting to the smaller healthbar size texture.
- Fix "Color Level Text" not being displayed and toggled properly.


# BetterBlizzFrames 1.7.2
## Retail
### New
- New Player Castbar setting: "Simple Castbar". Hides the text background on the player castbar and moves the text up inside of the castbar.
### Bugfix
- Fix "Fade MicroMenu" setting fully hiding BagsBar. Also tweaked how it fades things a bit.
## Mists of Pandaria
### Tweak
- Dark Mode: Added Priest's Shadow Orbs background texture to dark mode.
- LossOfControl: Add missing some missing interrupts and fixed some durations. Thank you to Moonfirebeam & Jumpsuitpally for reporting <3
- Player CastingBar has had it's position moved up 9 pixels to match Blizzard's location for it. You might have to move it back down 9 pixels to fit your UI. Apologies for the inconvenience. It has also recieved a very minor tweak to its border size.
### Bugfix
- Buffs & Debuffs: Important Glow & Purge Glow had their positioned tweaked and fixed a bit.
- Fix "Hide Arena Frames" setting to not cause lua errors due to Blizzard changes in 11.1.7 (thats also active on classics)
- Fix background color on unitframes not being positioned correctly while using Bigger Healthbars and targeting a "minus" mob.



# BetterBlizzFrames 1.7.1l
## Retail
### Bugfix
- Fix some bugs with Cooldown Manager settings. Properly centers the "Tracked Buffs" bar and no longer shows some icons that should be hidden (like non-active buffs). Vertical layout however is still not properly supported.
- Fix "UnitFrame Background Color" setting not being positioned correctly on the FocusFrame.
## Cata/MoP
### Tweak
- Remove custom Dampening Display since Blizzard added it by default.
## All versions
### Tweak
- Dark Mode: Now colors Bartender4 oldschool ActionBar art as well.
### Bugfix
- Fix Queue Timer playing the alert sound for 5sec left when already accepted into the Dungeon.
- Classics: Fix an issue with font replacement causing it to not properly change font on everything it should.


# BetterBlizzFrames 1.7.1k
## Cata/MoP
### Bugfix
- Fix nil error due to a copypaste error between BetterBlizzCC & BetterBlizzFrames

# BetterBlizzFrames 1.7.1j
## All versions
### Tweak
- Dominos support for ActionBar Font Change & Hiding Macro/Hotkey Text.
- Classics: Added instructions on how to import custom fonts and textures to that section.
## Cata/MoP
### Tweak
- Blizzard added LossOfControl by default for MoP. The BBF version still has a few improvements but also limited to PvP only spells for the most part. So if the setting is enabled it will show the BBF version everywhere except for instanced PvE content.
### Bugfix
- Fix healthbar texture change not changing the name background texture of FocusFrame.
## Retail
### New
- Added Clasic Frames specific right-click subsetting for "Change UnitFrame HealthBar Texture" that also changes the name background texture.

# BetterBlizzFrames 1.7.1i
## Retail
### New
- Hide ActionBar Crafting Quality Icon setting.
- Dark Mode: Elite Texture, for Target/Focus Elite Texture. 
## Mists of Pandaria
### Tweak
- Added missing Eclipse Bar and Shadow Orbs to "Hide Player Resource" setting.

# BetterBlizzFrames 1.7.1h
## Retail
### Bugfix
- Fix typo in Aeghis profile import, making it impossible to enable the profile.
- Fix MicroMenu size (edit mode box) getting wild because of Move Queue Eye setting after changes from Blizzard in 11.1.7. Your MicroMenu might move slightly due to this new change.

# BetterBlizzFrames 1.7.1g
## Mists of Pandaria / Cata
### Bugfix
- Fix UnitFrame Number Font setting not working properly on all numbers.
## All versions
### Bugfix
- Fix Queue Timer's audio warnings when below 5 sec not playing for PvE queues.

# BetterBlizzFrames 1.7.1f
## Retail
### Bugfix
- Fix Hiding Arena Frames causing addon action blocked error. This may cause them to pop back up during combat, need more testing.

# BetterBlizzFrames 1.7.1e
## Retail
### Tweak
- Aeghis profile update

# BetterBlizzFrames 1.7.1d
## All versions
### New:
- Hide CompactRaidFrame Border setting. Tldr: lets you keep Blizzards "Border" setting on for a thin border around each party member but remove the thick border surrounding all of them.
### Tweak
- Dark Mode now also darkens RaidFrame Border.
- Names on frames should now have identical width as default names.
- Party Castbars no longer shows pet castbars
## Mists of Pandaria & Cataclysm
### New
- Mmarkers profile added.
### Tweak
- More tweaks to Loss of Control. Now always prioritizes stuns/horrifies over other CC regardless of duration and if other hard CC is active it puts that on the smaller side icon.
## The War Within
### Tweak
- "Hide Dragon" setting now also hides Dragon while using Classic Frames setting.
### Bugfix
- Fix Arena Names group member update not working properly in starting room on group member updates
## All classic versions
### Bugfix:
- Fix Debuff Aura Filtering not positioning debuffs correctly.


# BetterBlizzFrames 1.7.1c
## MoP & Cata
### Tweak:
- Added few more absorb spells to absorb trackers while Blizzards searches for their lost Absorb API
- Tweaked "Purgeable" buff filter to show all Magic regardless if you had "Always show purgeable texture" enabled or not.
### Bugfix:
- Fix missing Solar Beam ID and some interractions between Solar Beam Interrupt and Silence duration.
- Fix Loss of Control showing up when getting "Interrupted" on things like First Aid Bandages etc.
- Fix missing queue timer settings on MoP/Cata.

# BetterBlizzFrames 1.7.1b
## MoP & Cata
### Bugfix:
- Fix Solar Beam not showing on Loss of Control due to having no duration. That is now accounted for and shows proper duration.

# BetterBlizzFrames 1.7.1
## MoP & Cata
### New:
- "Icon Only" mode for Loss of Control. Right click "Enable Loss of Control" to toggle on/off.
- MoP PvP Whitelist import button in Buffs & Debuffs aura section!
- Hide Totem Timer Text (Misc. MoP specific.)
- TotemFrame scale setting (Misc. MoP specific)
### Tweaks:
- Updated "Stealth Indicator" in Misc to work for Cata/MoP.
- Loss of Control tester is now working for Cata/MoP.
- Few more missing auras for Loss of Control added.
- Add TotemFrame borders to dark mode.
- Fix some party/pet castbar issues on Cata/MoP
## All versions
### Bugfix
- Changed Race Indicator to use Race ID's instead so its both easier and works properly on non-english clients.

# BetterBlizzFrames 1.7.0g
# MoP & Cata
- Minor tweaks & bugfixes

# BetterBlizzFrames 1.7.0f
# MoP & Cata
- More tweaks to Loss of Control frame.
- Added missing CC to Loss of Control frame.
- Added setting to hide background on Monk Chi Resource.
- Added "Raise Castbar Strata" setting to misc.
- Added Shadow Priest Orbs to Resource Scale/Position settings.
- Fixed Monk Resource being almost impossible to move.
- Fix Legacy Combo Point support for Arcane Mage staying active when not specced Arcane.

# BetterBlizzFrames 1.7.0e
# MoP & Cata
- Fix oopsie in LoC.

# BetterBlizzFrames 1.7.0d
# MoP & Cata
- More tweaks and spells to Loss of Control frame.

# BetterBlizzFrames 1.7.0b & 1.7.0c
## MoP & Cata
- Fix some issues with Loss of Control frame.

# BetterBlizzFrames 1.7.0
## Mists of Pandaria & Cata
- Lots of Retail features brought to MoP and Cata and fixed some things.
### New:
- Loss of Control feature (on by default) which is very similar to retail but with a few improvements like showing what you are interrupted on and a 2nd icon to keep viewing your lockout duration during a different CC.
- BBF adds Dampening stack count on Debuff in Arena.
- Hide Arena Frames fixed for Cata/MoP
- Queue Timer added for Cata/MoP
- Legacy Combo Points settings (position & size etc) added for Cata/MoP
- Move and scale resource added for Cata/MoP
- BBF fixes missing Purge texture on TargetFrame for Druids with Symbiosis on Shaman (With aura settings enabled)
- BBF makes Astral Power always show on Druid's Eclipse bar.
### Bugfix:
- Fix "Always show purge texture" causing enrage dispel effects to not glow.
- Fix Print Spell IDs setting in Buffs & Debuffs section.
### Note:
- Very many changes behind the scenes so possible I've missed a bug or two and forgot to mention smth in notes. Please report if you encounter bugs.


# BetterBlizzFrames 1.6.9b
## Retail
### Tweak:
- Cooldown Manager settings now properly supports Vertical layout.
## All versions
### Bugfix:
- Fix an issue causing the Important Aura Glow appear to flicker on auras when Important, Pandemic and Dark Mode: Auras were all enabled.



# BetterBlizzFrames 1.6.9
## Mop Beta
- MoP Classic now loads Cata files. This is not fully updated to MoP and will more than likely require tweaks. Please bugreport so I can fix.
## Retail
### New:
- Healer Indicator setting: Adds a cross icon on Target/Focus if they are a healer and also changes portrait to healer icon. Settings for both in Advanced Settings.
### Tweak:
- Cooldown Manager: Now supports centering and re-arranging on the "Tracked Buffs" bar as well.
- Added a missing Solar Beam Spell ID to the "Interrupt CD Color" castbar setting and also added Priests Silence back to it.
### Bugfix:
- Fixed a couple of issues with the Cooldown Manager settings. Please Bugreport if you run into more issues.
- Fix "Format Numbers" setting still showing numbers when the "Dead" text is showing on a dead unit.



# BetterBlizzFrames 1.6.8e
## Retail
### Tweak:
- Skip "OCD Tweaks" setting if EasyFrames is enabled (not needed)
- "Hide Level: Always" now also hides the Skull texture for bosses etc.
### Bugfix:
- Fix Castbar Interrupt Color's "Soon Highlight Spark" Position on Evoker Empowered Casts.
## Classic & Cata
### Tweak:
- Slight tweak to "Bigger Healthbar" setting because with some size combinations the healthbar showed a few pixels outside of the frame border.


# BetterBlizzFrames 1.6.8d
## All versions
### Tweak:
- If "Class Color Health" is enabled in BBF and BetterBlizzPlates' "NPC Color" is enabled the Target/Focus healthbars will now be colored their BBP Nameplate Color as well.
- UnitFrame Background Color (Misc) now supports EasyFrames.
### Bugfix:
- Fix Arcane Mage Charges not being moveable with "Move Resource" setting due to it being missing after some code cleanup.
- Fix DarkMode setting affecting ActionBars without that part enabled when the dark value was set to 0.

## Retail
### Tweak:
- Quick Hide Castbar setting now also works on sArena castbars.
- Aeghis profile update.
- Tweaks to Interrupt spell list for Castbar Interrupt Color.
### Bugfix:
- Fix inconsistencies for Castbar Interrupt Color.


# BetterBlizzFrames 1.6.8c
## Retail
### Tweak
- Added a safe check for Buffs & Debuffs filtering so it wont error if Blizzards BuffFrame.auraInfo is missing. This missing is highly unexpected and I have no idea why/how it can even be missing. Temporary workaround so addon loads normally with Buff Filtering enabled until I can figure out why this is. For the extremely few affected (1?) Buff Filtering on Player Auras won't work, but it wont error now and addon functions normally.



# BetterBlizzFrames 1.6.8b
## Retail
### New:
- Interrupt CD Color (Castbars) now has a subsetting that also enables it on Arena Frames (Blizzard, Gladius, GladiusEx, sArena)
### Tweaks:
- Removed temp OmniCC fix since it has been fixed.
- Removed "Disable AddOn Profiler" since it has been restricted by Blizzard.
### Bugfix:
- Fix Target & Focus Castbar x & y position settings getting reset to 0 when opening the GUI with "Detach Castbar" setting enabled.



# BetterBlizzFrames 1.6.8
## Retail
### New:
- Cooldown Manager Tweaks: New section with settings for Blizzards new "Cooldown Manager" feature. These settings will let you hide, change the priority/position, and center the icons. Early version.
- Temporary OmniCC Fix setting in Misc (Duplicate CD Timer, from a Blizzard change).
### Tweak:
- Changed color on Legacy Combo Points with dark mode enabled a little.
### Bugfix:
- Fix Class Color Health setting causing some npcs that were hostile to show as neutral.



# BetterBlizzFrames 1.6.7f
## Retail
### Tweak:
- Fix a healthbar color function running on login unintentionally potentially causing issues in combination with other color addons.


# BetterBlizzFrames 1.6.7e
## All versions:
### Bugfix:
- Fix Pet Castbar not being created unless Party Castbars were enabled.
## Retail:
### Bugfix:
- Fix issue with healthbar colors when combining class color, TRP3 color and retexturing healthbars.
## Classic Era & Cata:
### Bugfix:
- Fix text position on pet castbar


# BetterBlizzFrames 1.6.7d
## All versions:
### New:
- "Only show last name of NPCs" setting (Misc).
## Retail:
### Tweak:
- Format numbers setting now also formats billions. 12766 M -> 12.8 B
- Made Class Color FrameTexture setting compatible with dark mode setting (if enabled), so that when no class color is available it darkens the frame instead of its original color.
## Classic Era/SoD
### Bugfix:
- Fix Player Castbar Spark being smaller and out of position due to it being different than the Cataclysm one and requiring tweaks.




# BetterBlizzFrames 1.6.7c
## Retail
### New:
- Class Color FrameTexture (General, All Frames) - Class colors the border texture on Player/Target/FocusFrame.
- TRP3 Color FrameTexture (Misc)
### Bugfix:
- Fix hiding Monk Resource causing lua error on zone change loading screens.



# BetterBlizzFrames 1.6.7b
## Retail
### New:
- More TRP3 Stuff: TRP3 Healthbar Color, First & Last Name options, Name color option.
### Tweak:
- Added missing Dominos StanceButtons and PetActionButtons to Dark Mode.
- Made Classic Castbar options color uninterruptible castbars on Target/Focus/Party gray as well.
- StatusBar Text Format setting now also works with "NONE" as StatusText (for mouseover)
### Bugfix:
- Fix Dark Mode darkening all of the textures in Legacy Combo Points and not just the background like intended.
- Fix names not being moved properly in combination with EasyFrames
## Cata
### Tweak:
- Removed old coloring of heal prediction on TargetFrame since Blizzard have now fixed it and it is not needed.


# BetterBlizzFrames 1.6.7
## Retail
### New:
- Hide Resource Tooltip - Hide resource frame mouseover tooltip. (General, PlayerFrame)
- Support for TRP3 Names (Misc)
### Tweak:
- Improved AddonList setting now also adds a "Hide unloaded dependency AddOns" checkbox on the AddonList that sorts unloaded dependency addons down with the other disabled addons.
- Tweaked "Legacy Combo Points" position when using Retail Frames. If you have these settings then you will have to tweak your settings slightly due to this.
### Bugfix:
- Fix issue with Classic Frames setting showing TargetFrame Elite Texture (and some other things) above ToT Frame.
- Fix Party Castbar setting hiding during Test Mode when adjusting settings.

## Classic & Cata
### Tweak:
- Added tweak to "OCD Tweaks" setting so it does not warp the bag menu textures when used together with Dominos due to Dominos changing this.



# BetterBlizzFrames 1.6.6
## Retail
### New:
- Arena Optimizer (Misc): Tune some CVars when entering Arena, and back again when you leave, to boost FPS slightly during Arena.
### Tweak:
- Made the retail elite textures available for PlayerFrame's "Elite Texture" setting while Classic Frames setting is enabled. Now 7 different options total for Classic Frames.
- "Hide Prestige Badge" and "Hide PvP Icon" is now 1 combined setting.
- Buffs & Debuffs: "Increase Aura Frame Strata" setting is now enabled by default.
- Legacy Combo Points "Show Always" now also affects the more classes setting.
- Added "Blizzard CF" texture which is the old default texture. Use this in combination with Classic Frames if you want as similar as old Classic Frames as possible.
### Bugfix:
- Fix Buffs & Debuffs setting "Increase Aura Frame Strata" not showing auras above ToT frames when Classic Frames was enabled.



# BetterBlizzFrames 1.6.5l
## Retail
### Bugfix:
- Fix the "UnitFrame Background Color" setting causing the background made to overlap Portrait texture on Target/Focus.
- Fix naming typo in some of the druid manabar stuff causing a lua error.


# BetterBlizzFrames 1.6.5k
## Retail
### Tweak:
- "Hide Objective Tracker during Arena" is now checked by default.
### Bugfix:
- Fix ToT HealthBar Texture being too small when Classic Frames + Re-texture setting with "Blizzard" texture. I reverted this change to "Blizzard" texture, if you are looking for the default texture please use "Blizzard DF".


# BetterBlizzFrames 1.6.5j
- Skipped.

## Classic & Cata
### New:
- Added "Hide Resource/Power" setting for PlayerFrame (ComboPoints, Runes, etc)


# BetterBlizzFrames 1.6.5i
## Retail
### Tweak:
- Classic Frames: Pixel position tweaks to group indicator. Made Warlock Shards' Border slightly darker to match the UnitFrame texture (only if Dark Mode is not already selected)
- Added Legacy Combo Points to Dark Mode.
- Added duration to show on Sanctified Ground and Absolute Serenity auras with aura settings enabled.
- Added ToT & PetFrame to "UnitFrame Background Color" setting.
### Bugfix:
- Fix Class Color "Skip Self" option showing health as white and not green when texture replacement setting is on.
- Fix default party frames not getting retextured with retexture setting
- Fix oversight on Player Classic Castbar setting not coloring the castbar gray during uninterruptible state.



# BetterBlizzFrames 1.6.5h
## Retail
### Tweak:
- Edit Mode Alpha slider is now top right inside the Edit Mode Window for better visibility.
- More schizo pixel tweaks to Classic Frames setting.
### Bugfix:
- Fix wrong boolean in hide/show level frame on ClassicFrames setting causing it to hide lvl without the setting enabled.


# BetterBlizzFrames 1.6.5g
## Retail
### New:
- Player Elite Frame setting.
### Tweaks:
- A few minor pixel tweaks to Classic Frames.
- Classic Frames: If Hide LvL is selected it now also fixes the Glow texture and uses a better texture.
- Legacy Combo Points default position updated for Retail UnitFrames.
- "Mini-Frame" settings now work with Classic Frames setting as well.
- "UnitFrame Background Color" setting position tweaked to work with Classic Frames
### Bugfix:
- Fix absorb texture not showing properly with texture swap enabled.
- Classic Frames: Fix Reputation Color (color behind Name) on Target/FocusFrame staying hidden after targeting a minus mob.


# BetterBlizzFrames 1.6.5f
## Retail
### New:
- "Disable Addon Profiling" setting. Should improve performance a tiny bit. (Misc)
### Tweak:
- "Remove AddonList Categories" is now "Improved AddonList". It now in addition to removing categories sorts enabled addons at the top and disabled addons at the bottom for better overview.
- "Hide PvP Timer" is now a default enabled setting. Eyesore (5m timer text on PlayerFrame for no reason)
- Minor pixel position tweaks to some Classic stuff that was off
### Bugfix:
- Fix Dark Mode not coloring Druid Combo Points on login when not in cat form (due to them not existing yet). Added a listener that colors them as soon as they exist.


# BetterBlizzFrames 1.6.5e
## Retail
### New:
- Druid: Show Mana while in Cat/Bear (as resto) (Misc)
### Tweak:
- I've decided to make both Druid: Show mana while in Cat/Bear (as resto) and Druid: Show combo points in normal form on by default. I believe they are so close to core features and something that should already exist that I want them on by default. They can of course still be turned off in Misc.
### Bugfix:
- Fix Legacy Combo Points not turning off after disabling the setting. (Will require a re-toggle for affected users)
- Fix "Always show druid combo points" not working due to a last second typo.



# BetterBlizzFrames 1.6.5d
## Retail
### New:
- Added support for more classes with resources to work with legacy combo points.
- Added sliders to adjust legacy combo point frame position and scale.
- Added optional Legacy Combo Points Class Color setting for the non-standard classes.
### Tweaks:
- Minor tweaks to Classic Frames setting for position/scale of some class resources.
### Bugfix:
- Fix Druid Blue Combos not working due to a mistake after introducing the legacy combo points as well.
- Fix ToT frame texture being being jank when both "Classic Frames" and "Hide Shadow" settings were enabled. Not intended to be run together, now "Hide Shadow" does not get run with Classic Frames enabled.



# BetterBlizzFrames 1.6.5c
### New:
- Blue Legacy Combo Points (Overcharged & Berserk)
### Tweak:
- Add missing spell to Interrupt Indicator: Axe Toss (Demo Warlock)
### Bugfix:
- Fix Player Level Text color being reset back to default on loading screens with color setting on.
- Fix Aura Sorting becoming wonky on Target/FocusFrame from a change a few patches ago.
- Fix "Move Resource" not working if class subsetting of "Move Resource to TargetFrame" was enabled even though "Move Resource to TargetFrame" was unchecked.

# BetterBlizzFrames 1.6.5b
- Minor tweaks and fixes

# BetterBlizzFrames 1.6.5
## Retail
### New:
- ClassicFrames setting. A super lightweight ClassicFrames option. Turn UnitFrames (Player, Target, Focus, ToT, Party) into the old Classic look. (General)
- New setting: Hide Mana Feedback, setting that hides the animation when you lose/gain mana/energy for instant feedback (General)
- New setting: Hide Full Mana FX, setting that hides the glowing animation on the right side of your manabar when you are full mana/energy (General)
- New setting: Player: Hide Health Loss Animation.
- New setting: Show Druid combo points in normal form when you have active combo points.
- Font Color settings in Font & Textures section.
- Reduce Edit Mode Glow: Change the transparancy of the blue select alpha in Edit Mode so you can actually see where you move stuff (Misc)
- New "Legacy Combo Points" setting that enables the old combo points with a CVar (and fixes their positioning)
- Legacy Combo Points: Show Always setting.
- Hide Pet Hit Indicator
### Tweaks:
- Paladins Holy Power and Legacy Combo Points now also supported for "Instant Combo Points" setting.
- Aura Filtering now also shows duration on auras Power Word: Barrier, Earthen Wall and Grounding Totem in addition to Smoke Bomb.
- Dark Mode: Tooltip option now also colors the background black and not just the borders.
- New font used in GUI and tiny makeover to fit some more settings and have it look a tiny bit less messy.
- Texture changing now also effects default party frames
- HealthBar texture change now also changes the textures of Heal Prediction/Absorb textures on the bar.
- Tweaks to interrupt list for interrupt color, only counting pure kicks again.
- Add default Party Frames to Format Numbers setting.
- Aeghis profile update
### Bugfix:
- Fix Classic Castbar Non-Interruptible Border positioning getting messed up without icon scale at 1
### Note:
- Accidentally released the alpha version of 1.6.4 as main release version on CurseForge. There were some minor bugs that was not intended to be released but nothing that would cause issues. I've bumped the version number to 1.6.5 now just to avoid confusion.



# BetterBlizzFrames 1.6.4a
## Retail
- Alpha version of 1.6.5, skipped



# BetterBlizzFrames 1.6.3e
## Retail
- New sub setting to "ActionBar Cooldown Fix for CC" to always hide CC duration from ActionBars
- Fix "ActionBar Cooldown Fix for CC" causing a nil error due to some macros.



# BetterBlizzFrames 1.6.3d
## Retail
- Tweaks to "ActionBar Cooldown Fix for CC" to work with macros properly.


# BetterBlizzFrames 1.6.3c
## Retail
- Tweaks to the new "ActionBar Cooldown Fix for CC" setting. Should be more efficient and reliable now.
- Fixed up some typos relying on my other addon BetterBlizzPlates, instead the addon itself BetterBlizzFrames. Who named these...



# BetterBlizzFrames 1.6.3b
## All versions
- Fix "Hide Error Frame" setting only hides actual errors and not quest progress text etc.
## Classic Era
- Fix typo causing lua error
## Retail
- Remove castbar strata setting after more testing and updated "Raise TargetFrame Level" setting. They essentially had the same purpose. This setting will see more tweaks.





# BetterBlizzFrames 1.6.3
## The War Within
### New:
- ActionBar Cooldown Fix for CC, enable to have your ActionBar cooldowns show their proper duration while youre cced. By default if a CD is lower than the duration of the CC youre in it will not show, potentially baiting you to trinket kick while kick still has 3 sec CD etc.
- Add "Show Purge Texture on Player Buffs" setting (Buffs & Debuffs)
- Raise TargetFrame Level setting (Misc)
- Raise Castbar Stratas setting (Misc)
### Tweak:
- Kalvish profile update
- Tweak to "Remove AddonList Categories" setting to be more reliable.
### Bugfix:
- Even more bugfixes for some classes "Move Resource to TargetFrame" setting.




# BetterBlizzFrames 1.6.2b
### Bugfix:
- Fix missing variable on focus castbar for castbar interrupt color




# BetterBlizzFrames 1.6.2
## The War Within
### New:
- Move Resource setting (Misc). Lets you move Resource freely. (Not wrapped around TargetFrame like the existing setting, which still is there)
- Remove AddonList Categories setting (Misc)
- Kalvish profile (www.twitch.tv/kalvish)
### Tweak:
- Castbar Interrupt Color setting now also now also puts a green line exactly where your interrupt gets ready.
- Blacklisting auras that are already in the blacklist but with a "Show Mine" tag now overwrites it and removes the tag instead of notifying about duplicate.
- "Reset BBF" button moved to show in Advanced Settings section.



# BetterBlizzFrames 1.6.1
## The War Within
### New:
- Instant Combo Points setting (in Misc). Remove combo points animations for instant feedback on Rogue, Druid, Monk and Arcane Mage.
### Tweak:
- Add more auras to to PvP Whitelist. Thanks to Zwacky for gathering the ids.

## Classic Era & Cata
### Tweak:
- Moving BuffFrame/DebuffFrame is now optional but on by default. Depending on your addons BetterBlizzFrames might've taken control over other things moving it.
- Added TempEnchants (Weapon Enchants etc) to Masque frames.
### Bugfix:
- Fix issues with name not showing on default party frames sometimes.




# BetterBlizzFrames 1.6.0i
## The War Within
### Bugfix:
- Another tweak to "Move Resource to TargetFrame" setting that should hopefully make it not bug out when Blizzard have not created the combopoints in time.



# BetterBlizzFrames 1.6.0h
## The War Within
- Added Smoke Bomb ID's to PvP Whitelist. Not sure why I didn't have these included before but I feel theyre important enough. This whitelist is still meant as complimentary to all auras and not meant to be a pure whitelist.
- Nahj profile update

# BetterBlizzFrames 1.6.0g
## All versions
- Remove Skip GUI setting, now on by default.

## Retail
- Move Resource to TargetFrame setting fixed for some classes with unique power.

## Classics
- New Intro screen with profiles for new users.
- Darkmode: Add Minimap texture around Clock Time to be colored as well.
- Fix typo causing lua errors for people without hide realm name on




# BetterBlizzFrames 1.6.0f
## The War Within
- Adding Mage Barriers to Whitelist now only Glows/Enlarges if they are specced into Overpowered Barriers. (This can be turned off with /run BetterBlizzFramesDB.opBarriersOn = false)
- Added Ancient of Lore, Prismatic Barrier Immunity & Bloodstones Haste buff to PvP Whitelist Preset.

## The War Within, Classic Era & Cataclysm
- Fix some default party frame name stuff



# BetterBlizzFrames 1.6.0e
- Added new pvp auras to whitelist preset and removed the ones purged by Blizzard.
- Fix issue with deleting a spell from whitelist/blacklist that no longer has any valid spell information because of removal from Blizzard.
- Fix Monk Combo Points not getting moved to TargetFrame with the setting for that on.
- Potential fix for rare issue with rogue combo points sometimes not being in proper order with the move to targetframe setting.
- Fix frame name issues with EasyFrames



# BetterBlizzFrames 1.6.0d
- Add a new setting for Arena Names to chose between Party1 or SpecName for Party units. (Right-click Show Spec Names)



# BetterBlizzFrames 1.6.0c
- Update Arena Names logic to no longer require Details to get spec names
- Fix missing logic for hiding role icon on default party frames
- Fix old function name in GUI related to hiding role icons causing a lua error when clicked.
- Fix moving of Filtered Buffs Icon potentially causing lua error on Classic versions.



# BetterBlizzFrames 1.6.0b
- Fix Hide Names not working on Era
- Fix aura issues from Buff Filtering on Classic versions after update
- Add missing ToT frames to retexture unitframes setting
- Fix class color names not recoloring when arena names are in effect
- Fix a missing if statement causing some of the new texture logic to go through and color healthbars unintentionally
- Fix name position when using DragonflightUI & EasyFrames
- Fix non-english names having font issues (squares) with default font
- Fix Arena Names with Spec Name + Arena ID showing "Frost Arena 1" instead of "Frost 1"
- Change player aura filtering setting to just hide Buff/Debuff Frame if Show Buff or Show Debuff is unselected. This will stop it from doing a lot of unneccesary filter logic.
- Fix Filtered Buffs Icon causing a lua error on Classic versions due to Blizzard just removing a function that still exists on Retail..
- Fix Arena Names only accounting for party and arena units and others when Hide Realm Name setting was not on.
- Fix Arena Names to again always show friendly units as Party 1 and Party 2 or your own name trumping Spec Names (Its more clear this way imo).
- Fix default party frame names being hidden due to some missing logic.
- Added Dwarf and Dark Iron Dwarf to racial indicator
- Added "Show Race Icon" setting to Racial Indicator. Previously only showed Spell icon for the racial (Shadowmeld etc)

# BetterBlizzFrames 1.6.0
## The War Within, Cata & Era
### Important Note:
- Some of the Buffs & Debuffs sorting settings are now enabled by default. Because of this they may have turned on for you, please double check your aura settings in the Buffs & Debuffs section.
### New:
- Aeghis Profile (www.twitch.tv/aeghis)
- UnitFrame & RaidFrame texture swap
- Font settings
- New: UnitFrame Background Color (Misc)
- Skip GUI setting, on by default.
- Search functionality is now on Classic versions as well.
### Tweaks:
- Overshields setting updated to look identical to Retail for both Classic Era and Cataclysm
- Hide Level setting now hides the circle texture around the level when using ClassiFrames addon or on Classic version of the game.
- Fix OCD Tweaks settings for Classic Era and tweaked a few things on retail.
- Aura filter settings on Classic versions updated to the more optimized version thats been on retail awhile.
- Added missing Touch of Karma buff to the pvp whitelist.
- Filter toggle keybind/function now on classic versions as well.

## The War Within
### New stuff:
- Move Resource to Target setting now also has a setting to drag Resource/ComboPoints to wherever you want.
- Resource/ComboPoints Scale setting in Misc
- Moveable FPS Counter & Outline FPS Font (Misc)
- CompactPartyFrame Scale Setting
### Bugfix:
- Fix Shield Border on Uninteruptible casts for Classic Castbars settings not always wrapping around the castbar perfectly.
- Fix Format Number setting sometimes causing lua errors for certain classes with Alternate Power.
- Fix Alternative Frame Texture & Alternative ManaBar not being hidden with the Mini-Frame settings in Misc. Also slight adjustments due to new name settings.

## Classic Era
### New stuff:
- Added misc setting that is on by default: Makes it so Hunters popping feign death in raid does not show as dead. Less Hardcore Heart Attacks.
### Bugfix:
- All absorb settings fixed and updated.

### Note
- May have missed some other minor bugfixes in the patch notes, and may have introduced new ones. Please keep reporting bugs, however minor.






# BetterBlizzFrames 1.5.9b
## The War Within
### Tweak:
- Add AlternatePowerBar to Format Numbers
### Bugfix:
- Fix oopsie with "Hide Shadow" setting not hiding it on PlayerFrame after introducing the "Mirror TargetFrame" setting.
## Cataclysm
### Bugfix:
- Fix Buffs & Debuffs setting "Always show purge texture" not working.

# BetterBlizzFrames 1.5.9
## The War Within
### New stuff:
- Snupy profile (www.twitch.tv/snupy)
- PlayerFrame: Mirror TargetFrame (Makes PlayerFrame symmetrical and round like TargetFrame is) (Experimental)
- Classic Castbars setting
### Tweak:
- Overshields now supported for ClassicFrames addon.
- Few more auras in the blacklist preset.
- Hide Role Icon, Hide Names and Hide Realm Names (for Party) is now active in raid as well. (The name stuff still needs a rework when I get time)
### Note:
- I wanted to push a few more new features but it will have to wait until I have had more time developing and testing them.

# BetterBlizzFrames 1.5.8
## The War Within
### New stuff:
- General: "Hide shadow" setting that hides the dark texture behind names on Player, Target, Focus, ToT & Pet.
- Misc: Hide ActionBar Big Proc Glow
- Misc: Hide ActionBar Cast Animation
- Misc: UIWidgetPowerBarFrame scale setting (Dragonflying charges, also ahcievements etc I think? idk I just PvP)
### Tweak:
- Removed a few purgeable auras accidentally added to the pvp blacklist. Purgeable auras can be useful info so should not be hidden.
- Hide XP & Honor Bar setting now shows them when you opener character panel.
- Minor tweaks to evoker normal castbar setting (changed the spark texture as well to be like default)
- Purgeable Buff filter now also activates if "Always show purge texture" is enabled. Used to only follow Blizzard logic requiring a purge ability.
- Mini adjustment to Mini-Frame settings. Hopefully better now?
### Bugfix:
- Fix Darkmode setting missing some Dominos Actionbars.
## Cataclysm
### Tweak:
- Update to 4.4.1 Settings API Support
### Bugfix:
- Fix issue with a Blizzard update resetting the OCD settings new ActionButton HotKey Width.

# BetterBlizzFrames 1.5.7
## The War Within
### New stuff:
- Search feature! Top right SearchBox that normally searches Blizzard settings has now been hijacked and will search BetterBlizzFrames settings instead if you have the BBF settings open. (WIP)
- Hide Resource/Power setting now has individual class settings. Access them by rightclicking the checkbox.
- Misc: Hide Talking Heads setting.
- Misc: Hide XP & Honor Bar setting.
- Misc: Mini-TargetFrame setting.
- Misc: Mini-PlayerFrame setting.
### Tweak:
- The "Normal Evoker Empowered Castbar" setting now also makes sArena castbars normal.
- Nahj profile update
- Tweak Pandemic Timers to never go below base duration (Rot and Decay refresh caused wrong timings)
### Bugfix:
- Fix an issue with the red threat border overlapping auras with ClassicFrames addon.
- Fix issue with the new Misc settings for Queue Status Eye from last patch making the eye unclickable with the settings on.
- Fix/improve the Fade Out Micromenu setting being a bit wonky.
- Fix rare issue with QueueTimer displaying wrong accept timer for PvE.
- Fix issue with QueueTimer stopping updating on queue pop if also queued for PvP same time.

# BetterBlizzFrames 1.5.6
## The War Within
### New stuff:
- Misc: Move Queue Status Eye
- Misc: Fade out Micro Menu
- Misc: Hide BagsBar
### Tweak:
- Pandemic Glow for auras that have a pandemic effect is now properly glowing when 30% of their duration is left instead of a flat 5 sec like it was before. For non-pandemic auras the default timer is still 5sec. For UA and Agony if their refresh talents are picked the Pandemic Glow will first be orange when it enters that range and then turn red when it also enters the 30% window.

# BetterBlizzFrames 1.5.5b
## The War Within
### Bugfix:
- Fixed an issue with the function that checks whether aura lists are in the old format. This issue caused the system to mistakenly treat new lists as old ones, preventing them from importing correctly.

# BetterBlizzFrames 1.5.5
## The War Within
### New stuff:
- Hide Hit Indicator setting, hides inc dmg/healing numbers on PlayerFrame portrait.
### Tweak:
- "Full Profile" export strings can now be imported in the other import windows and will then only import that portion of the profile.
- Added a missing line texture on the left of ChatFrame to "Hide ChatFrame Buttons".
- Add a few more spell ids to blacklist preset.
- Updated Nahj profile.
### Bugfix:
- Improved Queue Timer for PvE queues. Should now stay accurate between reloads etc.
- Added a fake duration to Temp Enchants (Blizzard API is ass) to avoid errors when "Less than one min" filter is selected for Player.
- Fix FocusFrame Castbar Extra ToT Offset not being active on the frame.
- Fix some unintended changes to Overshields on PlayerFrame, TargetFrame & FocusFrame.
- Fix issue with Absorb Indicator not displaying on login/reload.
- Fixed Druid Blue ComboPoints not getting activated if Druid was not in catform during login/reload.

# BetterBlizzFrames 1.5.4b
## The War Within
### Tweak:
- Typing in aura lists input field now searches in the list as well.
- Added more auras to the pvp preset for aura blacklist and whitelist. (Remember this can be re-imported as it will merge your with your current settings and only add new auras)
- PSA: These presets can be found in the Import/Export section.
### Bugfix:
- Fix "Hide TotemFrame" setting.

# BetterBlizzFrames 1.5.4
## The War Within
### New stuff:
- You can now set a keybind to toggle all filters on/off to view all unfiltered auras momentarily. Or macro `/run BBF.ToggleFilterOverride()`
- Queue Timer: Display the amount of time you have to accept PvP and PvE queues ala SafeQueue.
- Misc: Minimize Objective Frame Better: Hides the objectives header as well when clicking the minimize button. (on by default)
- Misc: Surrender over Leave: Makes typing /afk in arena Surrender instead of Leaving so you don't lose honor/conquest gain.
- You can now "merge" aura list imports with your current list instead of chosing one or the other. Only new auras will be added doing this and you will not lose your settings on the current auras.
- Show Druid Overcharge charges on PlayerFrame combo points.
### Tweak:
- Nahj profile update
- Smokebomb timer on Player Debuffs now works without Player Debuff filtering on.
- Large restructure of aura lists that should both be cleaner and have better performance.
- Absorb Indicator now says millions instead of thousands. 7300k -> 7.3m
- General performance tweaks
### Bugfix:
- Fix default purge glow not scaling properly with enlarged/compacted auras
- Added missing smokebomb spell id to player debuffs for timer
- Fix issue with BBF Filter Icon potentially saving bad position data and causing lua error on next reload/login.
- Fix rare issue causing checkbox settings not to save for some people.
- Added some missing stop casting events to the Castbar Quick Hide setting.

# BetterBlizzFrames 1.5.3c
## The War Within
### Tweak:
- Adapt "Hide reputation color" and "Hide rest glow" settings to work with ClassicFrames addon.
- Pandemic timer for Agony and Unstable Affliction is now 10s and 8s instead of the regular 5s if the talents are learned.
### Bugfix:
- Added a missing second Smoke Bomb spell id for displaying Smoke Bomb CD.
- Pandemic Glow should now properly hide darkmode border during its activation

# BetterBlizzFrames 1.5.3b
## The War Within & Cataclysm
### New stuff:
- Buffs & Debuffs: Ctrl+Alt Rightclick to blacklist aura with "Show Mine" tag already added.
### Bugfix:
- Fixed new blacklist setting "allow mine" accidentally missing the castByPlayer check.

## The War Within
### New stuff:
- New setting "Quick Hide Castbars": Hide target/focus castbars immediately when cast is finished.
### Bugfix:
- Hide level 80 text now definitely hides level 80 text.
- Fixed Player Aura Filtering making player auras go downwards regardless of settings. Also fixed debuffs in the same go. I mustve been sleep deprived.
- Fixed Party Castbars showing self castbar despite not set to.

# BetterBlizzFrames 1.5.3
## The War Within & Cataclysm
### New stuff:
- Added cooldown timer to Smoke Bomb debuffs to show the duration of Smoke Bomb. Buffs & Debuffs settings need to be on for this to be active.
- Add "Show Mine" checkbox for blacklisted auras.
- Add "Mount" filter for auras. (Needs testing, if you use this and see a mount NOT show up please lmk)

## The War Within
### Bugfix:
- Fix darkmode causing some errors on evoker class.

### Known issue:
- Buff filtering + Collapsed BuffFrame is not supported and will cause issues with positioning of buffs etc. Added a message in chat to mention this and I am working on it.

# BetterBlizzFrames 1.5.2b
## The War Within & Cata
### New stuff:
- Buffs & Debuffs: The filtered buffs icon is now moveable with ctrl+leftclick and you can also change which direction the hidden auras grow.
- Buffs & Debuffs: New setting to hide the duration text on Buff/Debuff cooldown spiral.

## The War Within
### Bugfix:
- Fix player buff filter lua erroring with the 1 min filter due to an oopsie.
- Fix Target & Focus "Only Mine" filters conflicting with "Under 1 Min" filters and causing it to show auras longer than 1min.
- Fix issue with SUI + Masque causing Duration text on player auras to be hidden (again >.<)

# BetterBlizzFrames 1.5.2
## The War Within & Cataclysm
### New stuff:
- Buffs & Debufs: Add cooldown spiral to Player Auras settings.
- Slash Command: You can now also add auras to aura whitelist/blacklist by typing /bbf whitelist/blacklist spellId/spellname. For example /bbf blacklist 113 or /bbf whitelist agony. Can also be shortened to wl/bl.

## The War Within
### Tweak:
- Updated Nahj & Magnusz profiles.
- Hide level 70 text is now Hide level 80 text.
- Dark Mode: Added XP & Honor bar. Added some missing actionbar separators. Fixed soulshards not always being colored.
- Buffs & Debuffs: The duration of Player Auras are now correctly layered above the Important Glow making it more readable.
### Bugfix:
- Fix "Hide party frames" setting not hiding the border around the healthbars.
- Fix missing support for Player Auras stacking left to right and bottom to top with filtering on.
- Fix friendly npcs target of target frames having a white healthbar when used together with the ClassicFrames addon and "Class color frames" setting.

## Cataclysm
### New stuff:
- Class Portraits setting.

## Shoutout
- Shoutout to small-time streamer sodapoppin for trying out the addon.

# BetterBlizzFrames 1.5.1b
## The War Within
### New stuff:
- Recolor Temp Max HP Loss (Player, Target, Focus, Party) to transparent red. (Misc section)
### Tweak:
- Add Ace3 tooltips to DarkMode: Tooltip

# BetterBlizzFrames 1.5.1
## The War Within & Cata
### New stuff:
- Custom Code: Added a section for custom code that runs at login. Made for smaller custom scripts that don't really fit the addon.
- Buffs & Debuffs: "Same Size" setting that makes all auras on target/focus frame the same size. (By default yours are a little bigger)
- Buffs & Debuffs: "Aura Stack Size" setting that lets you re-size the stack text on auras.
### Bugfix:
- Fix SUI + Masque causing Player aura durations to be hidden due to SUI moving them up and Masque overlaying it.

## The War Within
### Tweak:
- Dark Mode Objectives: Add the objective header from the addon "World Quest Tracker".

# BetterBlizzFrames 1.5.0c
## The War Within
### New stuff:
- "Hide Dragon" setting for Target & FocusFrame.
- "Dark Mode: Vigor" setting is now optional, on by default.
### Bugfix:
- Fix Vigor sometimes not being colored due to the frame not existing yet.

## Cata
### Tweak:
- OCD Tweak: Increased Hotkey text width slightly to allow some longer keybind text like it used to be before Blizzard messed up.
- OCD Tweak: Re-apply hotkey text width after instancing because of resets.

# BetterBlizzFrames 1.5.0b
## The War Within
### Bugfix:
- Fixed Target/Focus Castbar Icon reposition tweak meant only for ClassicFrames users being active for all.
- Fix party castbars sometimes showing when no party frame is displayed due to shitty blizzard api.

# BetterBlizzFrames 1.5.0
## The War Within
### New stuff:
- Misc: Hide UI Error Frame setting (Red text: "Not enough mana" etc)
- Dark Mode: Added Dark Mode settings for Game Tooltip, Objective Frame & Vigor
### Bugfix:
- Fix some issues with Party Castbars.
- Fixed an issue on first install where it was not able to get Player Castbar Scale and resulting in an error and causing mischief.
### Tweak:
- Adjusted default position of Target/Focus Castbar Icon when ClassicFrames is enabled. If you are using ClassicFrames you might have to tweak the position because of this.
- Skip moving Target/Focus castbar text when ClassicFrames is enabled so they look like ClassicFrames intend.

## Cata
### Bugfix:
- Fixed an issue where the arena minimap hide setting could cause Lua errors in Cataclysm due to attempts to show or hide the minimap while in combat, specifically when entering or leaving the arena during combat.

# BetterBlizzFrames 1.4.9
## The War Within & Cata
### New:
- You can now choose to skip coloring the PlayerFrame healthbar with "Skip self" next to "Class Color Frames".

## The War Within
### New:
- Class coloring now works with Classic Frames.
- Reputation color also works with Classic Frames.
### Bugfix:
- Updated Interrupt icon function to TWW.

# BetterBlizzFrames 1.4.8e
## The War Within't (Prepatch)
### New:
- Added aura settings to enable enlarged auras depending on friendly/enemy target/focus for retail as well (was already on cata).
### Tweaks:
- Made it so if the addon Classic Frames is enabled the un-interruptible shield around castbars don't get moved.

# BetterBlizzFrames 1.4.8d
## The War Within't (Prepatch)
- Fix target/focus frame dark mode aura borders and re-enabled them.
- Fix the fix for ObjectiveFrame not hiding properly. Delay was not enough as Blizzard now calls to show this frame all the time. Put a hook on it so now it works.

# BetterBlizzFrames 1.4.8c
## The War Within't (Prepatch)
- Fix Interrupt Icon setting due to Blizzard function now returning true/false instead of 1/0
- Tweak default Interrupt Icon position and reset y offset due to this.
- Add a slight delay to fix hiding objective frame etc when entering arena.

# BetterBlizzFrames 1.4.8b
## The War Within't (Prepatch)
- Added "Normal Size Game Menu" setting in Misc section. We're old boomers but we're not that old jesus.
- Fix "Center Names" setting not displaying name due to naming mistake after blizzard switchup.

# BetterBlizzFrames 1.4.8
## The War Within
- Updated to support TWW. Might some things I've missed that needs a quick rename fix. Please report errors.

# BetterBlizzFrames 1.4.7b:
## Retail
### Bugfix:
- Fixed Masque support for Player Castbar not properly adjusting
- Fixed Player Castbar settings resetting on some loading screens.

## Cata
### Tweak:
- OCD Tweaks: Fixed a Blizzard issue where on smaller resolutions (1080p and below?) combined with a small UI Scale would truncate all hotkey text on actionbars even though it is not needed.
- Removed Pet Actionbar fix as it has been fixed by Blizzard.
### Bugfix:
- Fix Masque support timing issue causing it not to be detected on login.
- Fix "Hide Objective Tracker" setting using retail name for frame accidentally.

# BetterBlizzFrames 1.4.7:
## Retail & Cata
### New stuff:
- Added Masque support for castbar icons.
### Tweaks:
- Misc: The "hide during arena" settings are no longer tied to the minimap setting.
### Bugfixes:
- Fix Interrupt Icon Size, x offset & y offset sliders (i forgor :x)
- Fix castbar spell names not being capped at max castbar width.

## Cata
### Tweak:
- OCD Tweak: Made it toggleable and improved icon zoom. Icon zoom is now optional (on by default). Toggle icon zoom on/off with right click.

## Retail
### Bugfix:
- Fix some aura stuff not scaling properly with Masque enabled for them

# BetterBlizzFrames 1.4.6f:
## Cata
### New Stuff:
- Combat Indicator: `Assume Pala Combat` setting. (Combat status while Guardian is out is bugged, crude workaround)

# BetterBlizzFrames 1.4.6e
## Cata
### New stuff:
- Pet ActionBar fix setting (blizz bug) in Misc section.
### Tweaks:
- More mini adjustments to OCD Tweaks. Yes I have a problem.

# BetterBlizzFrames 1.4.6d
## Cata
### Tweaks:
- Added Reputation XP Bar to OCD Tweaks & Darkmode

# BetterBlizzFrames 1.4.6c
## Cata
### Tweaks:
- Castbar hide border setting now also hides the "flash" border at end of a cast.
- Made sure absorb bar setting doesnt try to change frame level in combat to avoid lua error

# BetterBlizzFrames 1.4.6b
## Cata
### New stuff:
- Castbar hide text & border settings.

# BetterBlizzFrames 1.4.6
## Retail & Cata
### New stuff:
- Castbar Interrupt Icon setting in Castbars section.
### Bugfixes:
- Fix some castbar positioning issues with the "Buffs on Top: Castbar Reverse Movement" setting.

## Cata
### New stuff:
- Party Castbars: Hide borders setting
### Bugfixes:
- Fix castbar reverse movement with buffs on top
- Fixed some default castbar movement issues (No buff filtering enabled)
- Fix aura positioning when stacking upwards with buffs on top
- Make OCD setting skip actionbar stuff if bartender is enabled to avoid error
- 1 pixel adjustment to actionbar art in "OCD Tweaks" setting, true to its name.



1.4.5b:
- Cata
- Remove ToT adjustment cuz errors, need more testing


### BetterBlizzFrames 1.4.5

#### Retail & Cata:
- **Masque**: Split the single Aura category into Buffs & Debuffs.

#### Cata:
**New Features:**
- Added the **OCD Tweaks** setting for Cata.
- Added **Hide MultiGroupFrame** setting for the PlayerFrame.
- Properly updated **dark mode** for default action bars in Cata.

**Bugfixes & Tweaks:**
- Updated **Overshields** with more updates for better accuracy on damage taken.
- Fixed an issue where the **name background** would reappear when the hide setting was on.
- Fixed an issue where the **player name** could move out of position.
- Fixed **Arena Names** to rely on Details for spec names, because of the absence of the Blizzard function in Cata.
- Adjusted **Party Castbar borders** to account for height changes.

#### Retail:
**Bugfixes & Tweaks:**
- **Castbars** will no longer reset to white after being re-colored if **ClassicFrames** is on, allowing the classic castbars to maintain their intended appearance.
- The **Masque border on auras** falling under the "Other auras" category now scales correctly if the scale has been adjusted.

1.4.4:
Retail & Cata:
New stuff:
- Masque support for Player, Target & Focus Auras.
- Buffs & Debuffs: Increase Frame Strata setting.

Cata:
Bugfixes:
- Fixed Player Debuff filtering
- Fixed "Hide pet statusbar text"

Retail:
Bugfixes & Tweaks:
- Target & Focus names shortened a little bit to make it not overlap frame
- Fix layering issue with "Combo Points on TargetFrame" settings.


1.4.3:
Cata:
New stuff:
- Added scale sliders for Player, Target and Focus frames.
- Added "Name inside" option for bigger healthbars setting.

Bugfixes & Tweaks:
- Changed default TargetToT and FocusToT positions to be identical to default Cataclysm values (had retail values). Had to reset values because of this.
- Fixed darkmode not applying to focus tot
- Fixed hide aggro highlight setting to work with the multiple types of raid/party frames.

Retail:
- Shortened ToT name so it does not go outside of the frame texture.

Cataclysm 1.4.1e:
- Fixed logic with target/focus auras messing up with eachother after port from retail to cata.
- Fixed Name Bg setting on Player to only be the actual size of the name bg so color behind hp/mana doesnt get changed
- Fixed Player name to be above Leatrix Plus' version of Name Bg.