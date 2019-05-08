local SUI = SUI
local module = SUI:NewModule('Component_InterruptAnnouncer')
local L = SUI.L
module.DisplayName = 'Interrupt announcer'
----------------------------------------------------------------------------------------------------
local InterruptAnnouncer_Watcher = CreateFrame('Frame')

local function printFormattedString(t, sid, sn, ss, ssid)
	local msg = SUI.DB.InterruptAnnouncer.text
	local ChatChannel = SUI.DB.InterruptAnnouncer.announceLocation

	msg =
		msg:gsub('%%t', t):gsub('%%sn', sn):gsub('%%sc', CombatLog_String_SchoolString(ss)):gsub('%%sl', GetSpellLink(sid)):gsub(
		'%%ys',
		GetSpellLink(ssid)
	)
	if ChatChannel == 'SELF' then
		SUI:Print(msg)
	else
		if not IsInGroup(2) then
			if IsInRaid() then
				if ChatChannel == 'INSTANCE_CHAT' then
					ChatChannel = 'RAID'
				end
			elseif IsInGroup(1) then
				if ChatChannel == 'INSTANCE_CHAT' then
					ChatChannel = 'PARTY'
				end
			end
		elseif IsInGroup(2) then
			if ChatChannel == 'RAID' then
				ChatChannel = 'INSTANCE_CHAT'
			end
			if ChatChannel == 'PARTY' then
				ChatChannel = 'INSTANCE_CHAT'
			end
		end

		if ChatChannel == 'SMART' then
			ChatChannel = 'RAID'
			if ChatChannel == 'RAID' and not IsInRaid() then
				ChatChannel = 'PARTY'
			end

			if ChatChannel == 'PARTY' and not IsInGroup(1) then
				ChatChannel = 'SAY'
			end

			if ChatChannel == 'INSTANCE_CHAT' and not IsInGroup(2) then
				ChatChannel = 'SAY'
			end

			if ChatChannel == 'CHANNEL' and ec == 0 then
				ChatChannel = 'SAY'
			end
		end

		SendChatMessage(msg, ChatChannel, nil, ec)
	end
end

function module:OnInitialize()
	local Defaults = {
		active = {
			always = false,
			inBG = false,
			inRaid = true,
			inParty = true,
			inArena = true,
			outdoors = false
		},
		FirstLaunch = true,
		announceLocation = 'SMART',
		text = 'Interupted %t %spell'
	}
	if not SUI.DB.InterruptAnnouncer then
		SUI.DB.EnabledComponents.InterruptAnnouncer = false
		SUI.DB.InterruptAnnouncer = Defaults
	else
		SUI.DB.InterruptAnnouncer = SUI:MergeData(SUI.DB.InterruptAnnouncer, Defaults, false)
	end
end

function module:COMBAT_LOG_EVENT_UNFILTERED()
	local continue = false
	local inInstance, instanceType = IsInInstance()
	if instanceType == 'arena' and options.inArena then
		continue = true
	elseif inInstance and instanceType == 'party' and options.inParty then
		continue = true
	elseif instanceType == 'pvp' and options.inBG then
		continue = true
	elseif instanceType == 'raid' and options.inRaid then
		continue = true
	elseif (instanceType == 'none' or (not inInstance and instanceType == 'party')) and options.outdoors then
		continue = true
	end

	local _, eventType, _, sourceGUID, _, _, _, _, destName, _, _, sourceID, _, _, spellID, spellName, spellSchool =
		CombatLogGetCurrentEventInfo()
	if
		continue and
			(eventType == 'SPELL_INTERRUPT' and
				(sourceGUID == UnitGUID('player') or (sourceGUID == UnitGUID('pet') and options.includePets)))
	 then
		printFormattedString(destName, spellID, spellName, spellSchool, sourceID)
	end
end

function module:OnEnable()
	module:Options()

	InterruptAnnouncer_Watcher:SetScript(
		'OnEvent',
		function(_, event)
			if not SUI.DB.EnabledComponents.InterruptAnnouncer then
				return
			end

			if module[event] then
				module[event]()
			end
		end
	)
	InterruptAnnouncer_Watcher:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
end

function module:Options()
	SUI.opt.args['ModSetting'].args['InterruptAnnouncer'] = {
		type = 'group',
		name = L['Interrupt announcer'],
		args = {
			alwayson = {
				name = L['Always on'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.InterruptAnnouncer.active.alwayson
				end,
				set = function(info, val)
					SUI.DB.InterruptAnnouncer.active.alwayson = val
				end
			},
			active = {
				name = 'Active',
				type = 'group',
				inline = true,
				order = 100,
				args = {
					inBG = {
						name = 'Battleground',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.active.inBG
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.active.inBG = val
						end
					},
					inRaid = {
						name = 'Raid',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.active.inRaid
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.active.inRaid = val
						end
					},
					inParty = {
						name = 'Party',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.active.inParty
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.active.inParty = val
						end
					},
					inArena = {
						name = 'Arena',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.active.inArena
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.active.inArena = val
						end
					},
					outdoors = {
						name = 'Outdoor',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.active.outdoors
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.active.outdoors = val
						end
					}
				}
			},
			announceLocation = {
				name = 'Announce location',
				type = 'select',
				order = 200,
				values = {
					['SMART'] = 'Instance chat',
					['INSTANCE_CHAT'] = 'Instance chat',
					['RAID'] = 'Raid',
					['PARTY'] = 'Party',
					['SMART'] = 'SMART',
					['SAY'] = 'Say',
					['SELF'] = 'No chat'
				},
				get = function(info)
					return SUI.DB.InterruptAnnouncer.announceLocation
				end,
				set = function(info, val)
					SUI.DB.InterruptAnnouncer.announceLocation = val
					RaidFrames:UpdateText()
				end
			}
		}
	}
end

function module:FirstLaunch()
	local PageData = {
		ID = 'InterruptAnnouncer',
		Name = L['Interrupt announcer'],
		SubTitle = L['Interrupt announcer'],
		-- Desc1 = L['Automatically turn on combat logging when entering a zone.'],
		RequireDisplay = SUI.DB.InterruptAnnouncer.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			if not SUI.DB.EnabledComponents.InterruptAnnouncer then
				window.Skip:Click()
			end

			--Container
			local cLog = CreateFrame('Frame', nil)
			cLog:SetParent(SUI_Win)
			cLog:SetAllPoints(SUI_Win)

			-- Setup checkboxes
			cLog.options = {}
			cLog.options.alwayson = StdUi:Checkbox(cLog, L['Always on'], nil, 20)

			cLog.options.inBG = StdUi:Checkbox(cLog, L['Announce logging in chat'], nil, 20)
			cLog.options.inRaid = StdUi:Checkbox(cLog, L['Mythic'], 150, 20)
			cLog.options.inParty = StdUi:Checkbox(cLog, L['Heroic'], 150, 20)
			cLog.options.inArena = StdUi:Checkbox(cLog, L['Normal'], 150, 20)
			cLog.options.outdoors = StdUi:Checkbox(cLog, L['Looking for raid'], 150, 20)

			local items = {
				{text = 'Instance chat', value = 'INSTANCE_CHAT'},
				{text = 'RAID', value = 'RAID'},
				{text = 'PARTY', value = 'PARTY'},
				{text = 'SAY', value = 'SAY'},
				{text = 'SMART', value = 'SMART'},
				{text = 'No chat', value = 'SELF'}
			}

			cLog.options.announceLocation =
				StdUi:Dropdown(cLog, 190, 20, items, SUI.DB.EnabledComponents.InterruptAnnouncer.announceLocation)

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
			cLog.modEnabled:SetChecked(SUI.DB.EnabledComponents.InterruptAnnouncer)
			for key, object in pairs(cLog.options) do
				object:SetChecked(SUI.DB.InterruptAnnouncer[key])
			end

			cLog.modEnabled:HookScript(
				'OnClick',
				function()
					for _, object in pairs(cLog.options) do
						if cLog.modEnabled:GetChecked() then
							object:Enable()
						else
							object:Disable()
						end
					end
				end
			)

			SUI_Win.cLog = cLog
		end,
		Next = function()
			local window = SUI:GetModule('SetupWizard').window
			local cLog = window.content.cLog
			SUI.DB.EnabledComponents.InterruptAnnouncer = cLog.modEnabled:GetChecked()

			for key, object in pairs(cLog.options) do
				SUI.DB.InterruptAnnouncer[key] = object:GetChecked()
			end

			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end,
		Skip = function()
			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end
