local SUI = SUI
local module = SUI:NewModule('Component_CombatLog')
local L = SUI.L
----------------------------------------------------------------------------------------------------
local CombatLog_Watcher = CreateFrame('Frame')

function module:OnInitialize()
	local Defaults = {
		alwayson = false,
		announce = true,

		raidmythic = true,
		raidheroic = true,
		raidnormal = true,
		raidlfr = false,
		raidlegacy = false,

		mythicplus = true,
		mythicdungeon = false,
		heroicdungeon = false,
		normaldungeon = false,
		
		loggingActive = false,
		FirstLaunch = true
	}
	if not SUI.DB.CombatLog then
		SUI.DB.CombatLog = Defaults
	else
		SUI.DB.CombatLog = SUI:MergeData(SUI.DB.CombatLog, Defaults, false)
	end
end

function module.ZONE_CHANGED_NEW_AREA()
	module:LogCheck('ZONE_CHANGED_NEW_AREA')
end

function module.CHALLENGE_MODE_START()
	module:LogCheck('CHALLENGE_MODE_START')
end

-- This is used to keep loggin turned on if the user /reloads
function module.PLAYER_ENTERING_WORLD()
	if (SUI.DB.CombatLog.loggingActive) then
		LoggingCombat(true)
	else
		SUI.DB.CombatLog.loggingActive = false
	end
end

function module:OnEnable()
	module:Options()
	module:FirstLaunch()

	CombatLog_Watcher:SetScript(
		'OnEvent',
		function(_, event)
			if not SUI.DB.EnabledComponents.CombatLog then
				return
			end

			if module[event] then
				module[event]()
			end
		end
	)
	CombatLog_Watcher:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	CombatLog_Watcher:RegisterEvent('CHALLENGE_MODE_START')
	CombatLog_Watcher:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function module:OnDisable()
	CombatLog_Watcher = nil
end

function module:announce(msg)
    SUI.DB.CombatLog.logging = true
	if (SUI.DB.CombatLog.announce) then
		SUI:Print('Combat logging enabled - ' .. msg .. ' detected')
	end
end

function module:LogCheck(event)
	local _, type, difficulty, _, maxPlayers = GetInstanceInfo()
	if (alwayson) then
		module:announce('Always on')
		LoggingCombat(true)
	elseif (raidmythic) and type == 'raid' and difficulty == 16 then
		-- 16 - 20-player Mythic Raid Instance
		module:announce('Mythic Raid')
		LoggingCombat(true)
	elseif (raidheroic) and type == 'raid' and difficulty == 15 then
		-- 15 - 10-30-player Heroic Raid Instance
		module:announce('Heroic Raid')
		LoggingCombat(true)
	elseif (raidnormal) and type == 'raid' and difficulty == 14 then
		-- 14 - 10-30-player Normal Raid Instance
		module:announce('Normal Raid')
		LoggingCombat(true)
	elseif (raidlfr) and type == 'raid' and difficulty == 17 then
		-- 17 - 10-30-player Raid Finder Instance
		module:announce('Raid Finder')
		LoggingCombat(true)
	elseif (normaldungeon) and type == 'party' and difficulty == 1 and maxPlayers == 5 then
		-- 1 - 5-player Instance, filtering Garrison
		module:announce('Normal Dungeon')
		LoggingCombat(true)
	elseif (heroicdungeon) and type == 'party' and difficulty == 2 and maxPlayers == 5 then
		-- 2 - 5-player Heroic Instance, filtering Garrison
		module:announce('Heroic Dungeon')
		LoggingCombat(true)
	elseif (mythicdungeon) and type == 'party' and difficulty == 23 and maxPlayers == 5 then
		-- 23 - Mythic 5-player Instance, filtering Garrison
		module:announce('Mythic Dungeon')
		LoggingCombat(true)
	elseif (mythicplus) and event == 'CHALLENGE_MODE_START' then
		-- 8 - Mythic+ Mode Instance
		module:announce('Mythic+ Dungeon')
		LoggingCombat(true)
	elseif
		(raidlegacy) and type == 'raid' and
			(difficulty == 3 or difficulty == 4 or difficulty == 5 or difficulty == 6 or difficulty == 7 or difficulty == 9)
	 then
		-- 3-9 is legacy raid difficulties
		module:announce('Legacy Raid')
		LoggingCombat(true)
	else
		LoggingCombat(false)
		SUI.DB.CombatLog.logging = false
	end
end

function module:Options()
	SUI.opt.args['ModSetting'].args['CombatLog'] = {
		type = 'group',
		name = L['Combat logging'],
		args = {
			alwayson = {
				name = L['Always on'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.CombatLog.alwayson
				end,
				set = function(info, val)
					SUI.DB.CombatLog.alwayson = val
				end
			},
			announce = {
				name = L['Announce logging in chat'],
				type = 'toggle',
				width = 'double',
				order = 5,
				get = function(info)
					return SUI.DB.CombatLog.announce
				end,
				set = function(info, val)
					SUI.DB.CombatLog.announce = val
				end
			},
			raid = {
				name = L['Raid settings'],
				type = 'group',
				inline = true,
				order = 10,
				width = 'full',
				args = {
					raidlegacy = {
						name = L['Legacy raids'],
						type = 'toggle',
						order = 0,
						get = function(info)
							return SUI.DB.CombatLog.raidlegacy
						end,
						set = function(info, val)
							SUI.DB.CombatLog.raidlegacy = val
						end
					},
					raidlfr = {
						name = L['Looking for raid'],
						type = 'toggle',
						order = 2,
						get = function(info)
							return SUI.DB.CombatLog.raidlfr
						end,
						set = function(info, val)
							SUI.DB.CombatLog.raidlfr = val
						end
					},
					raidnormal = {
						name = L['Normal'],
						type = 'toggle',
						order = 4,
						get = function(info)
							return SUI.DB.CombatLog.raidnormal
						end,
						set = function(info, val)
							SUI.DB.CombatLog.raidnormal = val
						end
					},
					raidheroic = {
						name = L['Heroic'],
						type = 'toggle',
						order = 6,
						get = function(info)
							return SUI.DB.CombatLog.raidheroic
						end,
						set = function(info, val)
							SUI.DB.CombatLog.raidheroic = val
						end
					},
					raidmythic = {
						name = L['Mythic'],
						type = 'toggle',
						order = 8,
						get = function(info)
							return SUI.DB.CombatLog.raidmythic
						end,
						set = function(info, val)
							SUI.DB.CombatLog.raidmythic = val
						end
					}
				}
			},
			dungeons = {
				name = L['Dungeon settings'],
				type = 'group',
				inline = true,
				order = 20,
				width = 'full',
				args = {
					normaldungeon = {
						name = L['Normal'],
						type = 'toggle',
						order = 0,
						get = function(info)
							return SUI.DB.CombatLog.normaldungeon
						end,
						set = function(info, val)
							SUI.DB.CombatLog.normaldungeon = val
						end
					},
					heroicdungeon = {
						name = L['Heroic'],
						type = 'toggle',
						order = 2,
						get = function(info)
							return SUI.DB.CombatLog.heroicdungeon
						end,
						set = function(info, val)
							SUI.DB.CombatLog.heroicdungeon = val
						end
					},
					mythicdungeon = {
						name = L['Mythic'],
						type = 'toggle',
						order = 4,
						get = function(info)
							return SUI.DB.CombatLog.mythicdungeon
						end,
						set = function(info, val)
							SUI.DB.CombatLog.mythicdungeon = val
						end
					},
					mythicplus = {
						name = L['Mythic+'],
						type = 'toggle',
						order = 6,
						get = function(info)
							return SUI.DB.CombatLog.mythicplus
						end,
						set = function(info, val)
							SUI.DB.CombatLog.mythicplus = val
						end
					}
				}
			}
		}
	}
end

function module:FirstLaunch()
	local PageData = {
		ID = 'CombatLog',
		Name = L['Combat logging'],
		SubTitle = L['Combat logging'],
		Desc1 = L['Automatically turn on combat logging when entering a zone.'],
		Desc2 = L['Combat log will be Automatically enabled, for easy uploading to websites such as Warcraftlogs.'],
		RequireDisplay = SUI.DB.CombatLog.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			if not SUI.DB.EnabledComponents.CombatLog then
				window.Skip:Click()
			end

			--Container
			local cLog = CreateFrame('Frame', nil)
			cLog:SetParent(SUI_Win)
			cLog:SetAllPoints(SUI_Win)

			-- Setup checkboxes
			cLog.options = {}
			cLog.options.alwayson = StdUi:Checkbox(cLog, L['Always on'], nil, 20)
			cLog.options.announce = StdUi:Checkbox(cLog, L['Announce logging in chat'], nil, 20)

			cLog.options.raidmythic = StdUi:Checkbox(cLog, L['Mythic'], 150, 20)
			cLog.options.raidheroic = StdUi:Checkbox(cLog, L['Heroic'], 150, 20)
			cLog.options.raidnormal = StdUi:Checkbox(cLog, L['Normal'], 150, 20)
			cLog.options.raidlfr 	= StdUi:Checkbox(cLog, L['Looking for raid'], 150, 20)
			cLog.options.raidlegacy = StdUi:Checkbox(cLog, L['Legacy raids'], 150, 20)

			cLog.options.mythicplus = StdUi:Checkbox(cLog, L['Mythic+'], 150, 20)
			cLog.options.mythicdungeon = StdUi:Checkbox(cLog, L['Mythic'], 150, 20)
			cLog.options.heroicdungeon = StdUi:Checkbox(cLog, L['Heroic'], 150, 20)
			cLog.options.normaldungeon = StdUi:Checkbox(cLog, L['Normal'], 150, 20)
			
			-- Create Labels
			cLog.modEnabled = StdUi:Checkbox(cLog, L['Module enabled'], nil, 20)
			cLog.lblRaid = StdUi:Label(cLog, L['Raid settings'], 13)
			cLog.lblDungeon = StdUi:Label(cLog, L['Dungeon settings'], 13)

			-- Positioning
			StdUi:GlueTop(cLog.modEnabled, SUI_Win, 0, -10)
			StdUi:GlueBelow(cLog.options.alwayson, cLog.modEnabled, -100, -5)
			StdUi:GlueRight(cLog.options.announce, cLog.options.alwayson, 5, 0)
			
			-- Raid Settings
			StdUi:GlueTop(cLog.lblRaid, cLog.modEnabled, -150, -80)
			StdUi:GlueBelow(cLog.options.raidmythic, cLog.lblRaid, 0, -5)
			StdUi:GlueRight(cLog.options.raidheroic, cLog.options.raidmythic, 5, 0)
			StdUi:GlueRight(cLog.options.raidnormal, cLog.options.raidheroic, 5, 0)
			
			StdUi:GlueBelow(cLog.options.raidlfr, cLog.options.raidmythic, 0, -5)
			StdUi:GlueRight(cLog.options.raidlegacy, cLog.options.raidlfr, 5, 0)


			--Dungeon Settings
			StdUi:GlueBelow(cLog.lblDungeon, cLog.options.raidlfr, 0, -20)
			StdUi:GlueBelow(cLog.options.mythicplus, cLog.lblDungeon, 0, -5)
			StdUi:GlueRight(cLog.options.mythicdungeon, cLog.options.mythicplus, 5, 0)
			StdUi:GlueRight(cLog.options.heroicdungeon, cLog.options.mythicdungeon, 5, 0)
			
			StdUi:GlueBelow(cLog.options.normaldungeon, cLog.options.mythicplus, 0, -5)


			-- Defaults
			cLog.modEnabled:SetChecked(SUI.DB.EnabledComponents.CombatLog)
			for key, object in pairs(cLog.options) do
				object:SetChecked(SUI.DB.CombatLog[key])
			end

			cLog.modEnabled:HookScript('OnClick', function()
				for _, object in pairs(cLog.options) do
					if cLog.modEnabled:GetChecked() then
						object:Enable()
					else
						object:Disable()
					end
				end
			end)

			SUI_Win.cLog = cLog
		end,
		Next = function()
			local window = SUI:GetModule('SetupWizard').window
			local cLog = window.content.cLog
			SUI.DB.EnabledComponents.CombatLog = cLog.modEnabled:GetChecked()

			for key, object in pairs(cLog.options) do
				SUI.DB.CombatLog[key] = object:GetChecked()
			end

			SUI.DB.CombatLog.FirstLaunch = false
		end,
		Skip = function()
			SUI.DB.CombatLog.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end