local SUI = SUI
local module = SUI:NewModule('Component_TauntWatcher', 'AceEvent-3.0')
local L = SUI.L
module.DisplayName = 'Taunt watcher'
----------------------------------------------------------------------------------------------------
local TauntsList = {
	--Warrior
	355, --Taunt
	--Death Knight
	51399, --Death Grip for Blood (49576 is now just the pull effect)
	56222, --Dark Command
	--Paladin
	62124, --Hand of Reckoning
	--Druid
	6795, --Growl
	--Hunter
	20736, --Distracting Shot
	--Monk
	115546, --Provoke
	--Demon Hunter
	185245, --Torment
	--Paladin
	204079 --Final Stand
}
local lastTimeStamp, lastSpellID = 0, 0

local function printFormattedString(who, target, sid, failed)
	local msg = SUI.DB.TauntWatcher.text
	local ChatChannel = SUI.DB.TauntWatcher.announceLocation

	msg = msg:gsub('%%what', target):gsub('%%who', who):gsub('%%spell', GetSpellLink(sid))
	if failed then
		msg = msg + ' and it failed horribly.'
	end

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
end

function module:COMBAT_LOG_EVENT_UNFILTERED()
	if not SUI.DB.EnabledComponents.TauntWatcher then
		return
	end

	local timeStamp, subEvent, _, _, srcName, _, _, _, dstName, _, _, spellID = CombatLogGetCurrentEventInfo()
	-- Check if we have been here before
	if timeStamp == lastTimeStamp and spellID == lastSpellID then
		return
	end

	-- Print the taunt
	if SUI:isInTable(TauntsList, spellID) then
		local continue = false
		local inInstance, instanceType = IsInInstance()
		if instanceType == 'arena' and SUI.DB.TauntWatcher.active.inArena then
			continue = true
		elseif inInstance and instanceType == 'party' and SUI.DB.TauntWatcher.active.inParty then
			continue = true
		elseif instanceType == 'pvp' and SUI.DB.TauntWatcher.active.inBG then
			continue = true
		elseif instanceType == 'raid' and SUI.DB.TauntWatcher.active.inRaid then
			continue = true
		elseif (instanceType == 'none' or (not inInstance and instanceType == 'party')) and SUI.DB.TauntWatcher.outdoors then
			continue = true
		end

		if not (continue or SUI.DB.TauntWatcher.active.alwayson) then
			return
		end

		if subEvent == 'SPELL_AURA_APPLIED' then
			printFormattedString(srcName, dstName, spellID)
		elseif subEvent == 'SPELL_MISSED' then
			printFormattedString(srcName, dstName, spellID, true)
		else
			return
		end
		-- Update last time and ID
		lastTimeStamp, lastSpellID = timeStamp, spellID
	end
end

function module:OnDisable()
	module:UnregisterAllEvents()
end

function module:OnEnable()
	module:Options()

	module:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
end

function module:Options()
	SUI.opt.args['ModSetting'].args['TauntWatcher'] = {
		type = 'group',
		name = 'Taunt watcher',
		args = {
			alwayson = {
				name = L['Always on'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.TauntWatcher.active.alwayson
				end,
				set = function(info, val)
					SUI.DB.TauntWatcher.active.alwayson = val
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
							return SUI.DB.TauntWatcher.active.inBG
						end,
						set = function(info, val)
							SUI.DB.TauntWatcher.active.inBG = val
						end
					},
					inRaid = {
						name = 'Raid',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.TauntWatcher.active.inRaid
						end,
						set = function(info, val)
							SUI.DB.TauntWatcher.active.inRaid = val
						end
					},
					inParty = {
						name = 'Party',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.TauntWatcher.active.inParty
						end,
						set = function(info, val)
							SUI.DB.TauntWatcher.active.inParty = val
						end
					},
					inArena = {
						name = 'Arena',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.TauntWatcher.active.inArena
						end,
						set = function(info, val)
							SUI.DB.TauntWatcher.active.inArena = val
						end
					},
					outdoors = {
						name = 'Outdoor',
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.TauntWatcher.active.outdoors
						end,
						set = function(info, val)
							SUI.DB.TauntWatcher.active.outdoors = val
						end
					}
				}
			},
			announceLocation = {3
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
					return SUI.DB.TauntWatcher.announceLocation
				end,
				set = function(info, val)
					SUI.DB.TauntWatcher.announceLocation = val
					RaidFrames:UpdateText()
				end
			},
			TextInfo = {
				name = '',
				type = 'group',
				inline = true,
				order = 300,
				args = {
					a = {
						name = L['Text variables:'],
						type = 'description',
						order = 10,
						fontSize = 'large'
					},
					b = {
						name = '- %who - ' .. L['Target that was interrupted'],
						type = 'description',
						order = 11,
						fontSize = 'small'
					},
					b2 = {
						name = '- %what - ' .. L['Target that was interrupted'],
						type = 'description',
						order = 12,
						fontSize = 'small'
					},
					c = {
						name = '- %spell - ' .. L['Spell link of spell interrupted'],
						type = 'description',
						order = 13,
						fontSize = 'small'
					},
					h = {
						name = '',
						type = 'description',
						order = 499,
						fontSize = 'medium'
					},
					text = {
						name = L['Announce text:'],
						type = 'input',
						order = 501,
						width = 'full',
						get = function(info)
							return SUI.DB.TauntWatcher.text
						end,
						set = function(info, value)
							SUI.DB.TauntWatcher.text = value
						end
					}
				}
			}
		}
	}
end
