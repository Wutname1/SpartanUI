local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('Component_TauntWatcher', 'AceEvent-3.0')
module.Displayname = L['Taunt watcher']
module.description = 'Notify you or your party when others taunt'
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
local lastTimeStamp, lastSpellID, lastspellName = 0, 0, ''

local function printFormattedString(who, target, sid, failed)
	local msg = module.DB.text
	local ChatChannel = module.DB.announceLocation

	msg = msg:gsub('%%what', target):gsub('%%who', who):gsub('%%spell', GetSpellLink(sid))
	if failed then
		msg = msg .. ' and it failed horribly.'
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
	if (SUI.IsClassic or SUI.IsBCC) then
		TauntsList = {
			-- Warrior taunt
			'Taunt',
			-- Warrior improved taunt
			'Improved Taunt',
			-- Druid Growl ranks
			'Challenging Roar',
			'Growl'
		}
	end
	local defaults = {
		profile = {
			active = {
				always = false,
				inBG = false,
				inRaid = true,
				inParty = true,
				inArena = true,
				outdoors = false
			},
			failures = true,
			FirstLaunch = true,
			announceLocation = 'SELF',
			text = '%who taunted %what!'
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('TauntWatcher', defaults)
	module.DB = module.Database.profile

	-- Migrate old settings
	if SUI.DB.TauntWatcher then
		print('Taunt watcher DB Migration')
		module.DB = SUI:MergeData(module.DB, SUI.DB.TauntWatcher, true)
		SUI.DB.TauntWatcher = nil
	end
end

function module:COMBAT_LOG_EVENT_UNFILTERED()
	if SUI.DB.DisabledComponents.TauntWatcher or module.Override then
		return
	end

	local timeStamp, subEvent, _, _, srcName, _, _, _, dstName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	-- Check if we have been here before
	if
		(SUI.IsRetail and timeStamp == lastTimeStamp and spellID == lastSpellID) or
			(SUI.IsClassic and timeStamp == lastTimeStamp and spellName == lastspellName) or
			(SUI.IsClassic and type(spellName) ~= 'string')
	 then
		return
	end

	-- Print the taunt
	if (SUI.IsRetail and SUI:isInTable(TauntsList, spellID)) or (SUI.IsClassic and SUI:isInTable(TauntsList, spellName)) then
		local continue = false
		local inInstance, instanceType = IsInInstance()
		if instanceType == 'arena' and module.DB.active.inArena then
			continue = true
		elseif inInstance and instanceType == 'party' and module.DB.active.inParty then
			continue = true
		elseif instanceType == 'pvp' and module.DB.active.inBG then
			continue = true
		elseif instanceType == 'raid' and module.DB.active.inRaid then
			continue = true
		elseif (instanceType == 'none' or (not inInstance and instanceType == 'party')) and module.DB.outdoors then
			continue = true
		end

		if not (continue or module.DB.active.alwayson) then
			return
		end

		if subEvent == 'SPELL_AURA_APPLIED' then
			printFormattedString(srcName, dstName, spellID)
		elseif subEvent == 'SPELL_MISSED' and module.DB.failures then
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
	module:SetupWizard()

	module:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
end

function module:Options()
	SUI.opt.args['ModSetting'].args['TauntWatcher'] = {
		type = 'group',
		name = L['Taunt watcher'],
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		args = {
			alwayson = {
				name = L['Always on'],
				type = 'toggle',
				width = 'full',
				order = 1,
				get = function(info)
					return module.DB.active.alwayson
				end,
				set = function(info, val)
					module.DB.active.alwayson = val
				end
			},
			active = {
				name = L['Active'],
				type = 'group',
				inline = true,
				order = 100,
				get = function(info)
					return module.DB.active[info[#info]]
				end,
				set = function(info, val)
					module.DB.active[info[#info]] = val
				end,
				args = {
					inBG = {
						name = L['Battleground'],
						type = 'toggle',
						order = 1
					},
					inRaid = {
						name = L['Raid'],
						type = 'toggle',
						order = 1
					},
					inParty = {
						name = L['Party'],
						type = 'toggle',
						order = 1
					},
					inArena = {
						name = L['Arena'],
						type = 'toggle',
						order = 1
					},
					outdoors = {
						name = L['Outdoor'],
						type = 'toggle',
						order = 1
					}
				}
			},
			failures = {
				name = L['Annnounce failed taunts'],
				type = 'toggle',
				width = 'full',
				order = 150
			},
			announceLocation = {
				name = L['Announce location'],
				type = 'select',
				order = 200,
				values = {
					['INSTANCE_CHAT'] = 'Instance chat',
					['RAID'] = 'Raid',
					['PARTY'] = 'Party',
					['SMART'] = 'SMART',
					['SAY'] = 'Say',
					['SELF'] = 'No chat'
				}
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
						name = '- %who - ' .. L['Player/Pet that taunted'],
						type = 'description',
						order = 11,
						fontSize = 'small'
					},
					b2 = {
						name = '- %what - ' .. L['Name of mob taunted'],
						type = 'description',
						order = 12,
						fontSize = 'small'
					},
					c = {
						name = '- %spell - ' .. L['Spell link of spell used to taunt'],
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
							return module.DB.text
						end,
						set = function(info, value)
							module.DB.text = value
						end
					}
				}
			}
		}
	}
end

function module:SetupWizard()
	local PageData = {
		ID = 'TauntWatcher',
		name = L['Taunt watcher'],
		SubTitle = 'Taunt watcher',
		RequireDisplay = module.DB.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			local TauntWatch = CreateFrame('Frame', nil)
			TauntWatch:SetParent(SUI_Win)
			TauntWatch:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('TauntWatcher') or module.Override then
				TauntWatch.lblDisabled = StdUi:Label(TauntWatch, 'Disabled', 20)
				TauntWatch.lblDisabled:SetPoint('CENTER', TauntWatch)
			else
				local items = {
					{text = L['Instance chat'], value = 'INSTANCE_CHAT'},
					{text = L['Raid'], value = 'RAID'},
					{text = L['Party'], value = 'PARTY'},
					{text = L['Say'], value = 'SAY'},
					{text = L['Smart'], value = 'SMART'},
					{text = L['Self'], value = 'SELF'}
				}

				TauntWatch.announceLocation = StdUi:Dropdown(TauntWatch, 190, 20, items, module.DB.announceLocation)
				TauntWatch.announceLocation.OnValueChanged = function(self, value)
					module.DB.announceLocation = value
				end

				-- Create Labels
				TauntWatch.modEnabled = StdUi:Checkbox(TauntWatch, L['Module enabled'], nil, 20)
				TauntWatch.lblActive = StdUi:Label(TauntWatch, L['Active when in'], 13)
				TauntWatch.lblAnnouncelocation = StdUi:Label(TauntWatch, L['Announce location'], 13)

				-- Setup checkboxes
				TauntWatch.options = {}
				TauntWatch.options.alwayson = StdUi:Checkbox(TauntWatch, L['Always on'], 120, 20)

				TauntWatch.options.inBG = StdUi:Checkbox(TauntWatch, L['Battleground'], 120, 20)
				TauntWatch.options.inRaid = StdUi:Checkbox(TauntWatch, L['Raid'], 120, 20)
				TauntWatch.options.inParty = StdUi:Checkbox(TauntWatch, L['Party'], 120, 20)
				TauntWatch.options.inArena = StdUi:Checkbox(TauntWatch, L['Arena'], 120, 20)
				TauntWatch.options.outdoors = StdUi:Checkbox(TauntWatch, L['Outdoors'], 120, 20)

				-- Positioning
				StdUi:GlueTop(TauntWatch.modEnabled, SUI_Win, 0, -10)
				StdUi:GlueBelow(TauntWatch.lblAnnouncelocation, TauntWatch.modEnabled, -100, -20)
				StdUi:GlueRight(TauntWatch.announceLocation, TauntWatch.lblAnnouncelocation, 5, 0)

				-- Active location Positioning
				StdUi:GlueBelow(TauntWatch.lblActive, TauntWatch.lblAnnouncelocation, -80, -20)

				StdUi:GlueBelow(TauntWatch.options.inBG, TauntWatch.lblActive, 30, 0)
				StdUi:GlueRight(TauntWatch.options.inArena, TauntWatch.options.inBG, 0, 0)
				StdUi:GlueRight(TauntWatch.options.outdoors, TauntWatch.options.inArena, 0, 0)

				StdUi:GlueBelow(TauntWatch.options.inRaid, TauntWatch.options.inBG, 0, 0)
				StdUi:GlueRight(TauntWatch.options.inParty, TauntWatch.options.inRaid, 0, 0)

				-- Announce text
				TauntWatch.lblAnnouncetext = StdUi:Label(TauntWatch, L['Announce text:'], 13)
				TauntWatch.lblvariable1 = StdUi:Label(TauntWatch, '%who - ' .. L['Player/Pet that taunted'], 13)
				TauntWatch.lblvariable2 = StdUi:Label(TauntWatch, '%what - ' .. L['Name of mob taunted'], 13)

				TauntWatch.tbAnnounceText = StdUi:SimpleEditBox(TauntWatch, 300, 24, module.DB.text)

				StdUi:GlueBelow(TauntWatch.lblAnnouncetext, TauntWatch.lblActive, 0, -80)
				StdUi:GlueBelow(TauntWatch.lblvariable1, TauntWatch.lblAnnouncetext, 15, -5, 'LEFT')
				StdUi:GlueBelow(TauntWatch.lblvariable2, TauntWatch.lblvariable1, 0, -5, 'LEFT')
				if SUI.IsClassic then
					StdUi:GlueBelow(TauntWatch.tbAnnounceText, TauntWatch.lblvariable2, -15, -5, 'LEFT')
				else
					TauntWatch.lblvariable3 = StdUi:Label(TauntWatch, '%spell - ' .. L['Spell link of spell used to taunt'], 13)
					StdUi:GlueBelow(TauntWatch.lblvariable3, TauntWatch.lblvariable2, 0, -5, 'LEFT')
					StdUi:GlueBelow(TauntWatch.tbAnnounceText, TauntWatch.lblvariable3, -15, -5, 'LEFT')
				end

				-- Defaults
				TauntWatch.modEnabled:SetChecked(SUI:IsModuleEnabled('TauntWatcher'))
				for key, object in pairs(TauntWatch.options) do
					object:SetChecked(module.DB.active[key])
				end

				TauntWatch.modEnabled:HookScript(
					'OnClick',
					function()
						for _, object in pairs(TauntWatch.options) do
							if TauntWatch.modEnabled:GetChecked() then
								SUI:EnableModule(module)
							else
								SUI:DisableModule(module)
							end
						end
					end
				)
			end

			SUI_Win.TauntWatch = TauntWatch
		end,
		Next = function()
			if SUI:IsModuleEnabled('TauntWatcher') and (not module.Override) then
				local window = SUI:GetModule('SetupWizard').window
				local TauntWatch = window.content.TauntWatch

				for key, object in pairs(TauntWatch.options) do
					module.DB[key] = object:GetChecked()
				end
				module.DB.text = TauntWatch.tbAnnounceText:GetText()
			end
			module.DB.FirstLaunch = false
		end,
		Skip = function()
			module.DB.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end
