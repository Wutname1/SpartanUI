local SUI = SUI
local module = SUI:NewModule('Component_TauntWatcher')
local L = SUI.L
module.DisplayName = 'Taunt watcher'
----------------------------------------------------------------------------------------------------


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
		text = '%t Taunted!'
	}
	if not SUI.DB.TauntWatcher then
		SUI.DB.EnabledComponents.TauntWatcher = false
		SUI.DB.TauntWatcher = Defaults
	else
		SUI.DB.TauntWatcher = SUI:MergeData(SUI.DB.TauntWatcher, Defaults, false)
	end
end

function module:COMBAT_LOG_EVENT_UNFILTERED()
	
end

function module:OnEnable()
	module:Options()

	TauntWatcher_Watcher:SetScript(
		'OnEvent',
		function(_, event)
			if not SUI.DB.EnabledComponents.TauntWatcher then
				return
			end

			if module[event] then
				module[event]()
			end
		end
	)
	TauntWatcher_Watcher:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
end


function module:Options()
	SUI.opt.args['ModSetting'].args['TauntWatcher'] = {
		type = 'group',
		name = L['Interrupt announcer'],
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
					return SUI.DB.TauntWatcher.announceLocation
				end,
				set = function(info, val)
					SUI.DB.TauntWatcher.announceLocation = val
					RaidFrames:UpdateText()
				end
			}
		}
	}
end