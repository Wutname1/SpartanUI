local SUI, L, print = SUI, SUI.L, SUI.print
local module = SUI:NewModule('InterruptAnnouncer') ---@type SUI.Module
module.Displayname = L['Interrupt announcer']
----------------------------------------------------------------------------------------------------
local lastTime, lastSpellID = nil, nil

local function printFormattedString(t, sid, spell, ss, ssid, inputstring)
	local msg = inputstring or module.DB.text
	local DBChannel = module.DB.announceLocation or 'SELF'
	local spelllink = C_Spell.GetSpellLink(sid)

	msg = msg:gsub('%%t', t):gsub('%%cl', CombatLog_String_SchoolString(ss)):gsub('%%spell', spelllink):gsub('%%sl', spelllink):gsub('%%myspell', C_Spell.GetSpellLink(ssid))
	if DBChannel ~= 'SELF' then
		if DBChannel == 'SMART' then
			if IsInGroup(2) then
				SendChatMessage(msg, 'INSTANCE_CHAT')
				return
			elseif IsInRaid() then
				SendChatMessage(msg, 'RAID')
				return
			elseif IsInGroup(1) then
				SendChatMessage(msg, 'PARTY')
				return
			end
		else
			if DBChannel == 'RAID' or DBChannel == 'INSTANCE_CHAT' then
				if IsInGroup(2) then
					-- We are in a raid with instance chat
					SendChatMessage(msg, 'INSTANCE_CHAT')
					return
				elseif IsInRaid() then
					-- We are in a manual Raid
					SendChatMessage(msg, 'RAID')
					return
				end
			elseif DBChannel == 'PARTY' and IsInGroup(1) then
				SendChatMessage(msg, 'PARTY')
				return
			end
		end
	end

	print(msg)
end

function module:OnInitialize()
	local defaults = {
		profile = {
			always = false,
			inBG = false,
			inRaid = true,
			inParty = true,
			selfInterrupt = true,
			inArena = true,
			outdoors = false,
			includePets = true,
			FirstLaunch = true,
			announceLocation = 'SMART',
			text = 'Interrupted %t %spell',
		},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('InterruptAnnouncer', defaults)
	module.DB = module.Database.profile
end

local function COMBAT_LOG_EVENT_UNFILTERED()
	if SUI:IsModuleDisabled('InterruptAnnouncer') then return end

	local continue = false
	local inInstance, instanceType = IsInInstance()
	if instanceType == 'arena' and module.DB.inArena then
		continue = true
	elseif inInstance and instanceType == 'party' and module.DB.inParty then
		continue = true
	elseif instanceType == 'pvp' and module.DB.inBG then
		continue = true
	elseif instanceType == 'raid' and module.DB.inRaid then
		continue = true
	elseif (instanceType == 'none' or (not inInstance and instanceType == 'party')) and module.DB.outdoors then
		continue = true
	end

	local timeStamp, eventType, _, sourceGUID, _, _, _, destGUID, destName, _, _, sourceID, _, _, spellID, spellName, spellSchool = CombatLogGetCurrentEventInfo()

	-- Check if time and ID was same as last
	-- Note: This is to prevent flooding announcements on AoE taunts.
	if timeStamp == lastTime and spellID == lastSpellID then return end

	-- Update last time and ID
	lastTime, lastSpellID = timeStamp, spellID

	if (continue or module.DB.alwayson) and eventType == 'SPELL_INTERRUPT' and (sourceGUID == UnitGUID('player') or (sourceGUID == UnitGUID('pet') and module.DB.includePets)) then
		if destGUID == UnitGUID('player') and module.DB.selfInterrupt then
			printFormattedString(destName, spellID, spellName, spellSchool, sourceID, 'I have hurt myself in confustion while casting %spell and can no longer cast.')
		else
			printFormattedString(destName, spellID, spellName, spellSchool, sourceID)
		end
	end
end

function module:OnEnable()
	module:Options()
	module:FirstLaunch()

	module:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', COMBAT_LOG_EVENT_UNFILTERED)
end

function module:Options()
	SUI.opt.args['Modules'].args['InterruptAnnouncer'] = {
		type = 'group',
		name = L['Interrupt announcer'],
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			alwayson = {
				name = L['Always on'],
				type = 'toggle',
				order = 1,
			},
			active = {
				name = L['Active when in'],
				type = 'group',
				inline = true,
				order = 100,
				get = function(info)
					return module.DB[info[#info]]
				end,
				set = function(info, val)
					module.DB[info[#info]] = val
				end,
				args = {
					inBG = {
						name = L['Battleground'],
						type = 'toggle',
						order = 1,
					},
					inRaid = {
						name = L['Raid'],
						type = 'toggle',
						order = 1,
					},
					inParty = {
						name = L['Party'],
						type = 'toggle',
						order = 1,
					},
					inArena = {
						name = L['Arena'],
						type = 'toggle',
						order = 1,
					},
					outdoors = {
						name = L['Outdoors'],
						type = 'toggle',
						order = 1,
					},
				},
			},
			selfInterrupt = {
				name = L['Include self'],
				type = 'toggle',
				order = 1,
			},
			includePets = {
				name = L['Include pets'],
				type = 'toggle',
				order = 2,
			},
			announceLocation = {
				name = L['Announce location'],
				type = 'select',
				order = 200,
				values = {
					['INSTANCE_CHAT'] = L['Instance chat'],
					['PARTY'] = L['Party'],
					['RAID'] = L['Raid'],
					['SELF'] = L['Self'],
					['SMART'] = L['Smart'],
				},
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
						fontSize = 'large',
					},
					b = {
						name = '- %t - ' .. L['Target that was interrupted'],
						type = 'description',
						order = 11,
						fontSize = 'small',
					},
					c = {
						name = '- %spell - ' .. L['Spell link of spell interrupted'],
						type = 'description',
						order = 12,
						fontSize = 'small',
					},
					d = {
						name = '- %cl - ' .. L['Spell class'],
						type = 'description',
						order = 14,
						fontSize = 'small',
					},
					f = {
						name = '- %myspell - ' .. L['Spell you used to interrupt'],
						type = 'description',
						order = 15,
						fontSize = 'small',
					},
					h = {
						name = '',
						type = 'description',
						order = 499,
						fontSize = 'medium',
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
						end,
					},
				},
			},
		},
	}
end

function module:FirstLaunch()
	local PageData = {
		ID = 'InterruptAnnouncer',
		Name = L['Interrupt announcer'],
		SubTitle = L['Interrupt announcer'],
		RequireDisplay = module.DB.FirstLaunch,
		Display = function()
			local SUI_Win = SUI.Setup.window.content
			local StdUi = SUI.StdUi

			--Container
			local IAnnounce = CreateFrame('Frame', nil)
			IAnnounce:SetParent(SUI_Win)
			IAnnounce:SetAllPoints(SUI_Win)

			if SUI:IsModuleDisabled('InterruptAnnouncer') then
				IAnnounce.lblDisabled = StdUi:Label(IAnnounce, 'Disabled', 20)
				IAnnounce.lblDisabled:SetPoint('CENTER', IAnnounce)
			else
				-- Setup checkboxes
				IAnnounce.options = {}
				IAnnounce.options.alwayson = StdUi:Checkbox(IAnnounce, L['Always on'], 120, 20)

				IAnnounce.options.inBG = StdUi:Checkbox(IAnnounce, L['Battleground'], 120, 20)
				IAnnounce.options.inRaid = StdUi:Checkbox(IAnnounce, L['Raid'], 120, 20)
				IAnnounce.options.inParty = StdUi:Checkbox(IAnnounce, L['Party'], 120, 20)
				IAnnounce.options.inArena = StdUi:Checkbox(IAnnounce, L['Arena'], 120, 20)
				IAnnounce.options.outdoors = StdUi:Checkbox(IAnnounce, L['Outdoors'], 120, 20)

				local items = {
					{ text = L['Instance chat'], value = 'INSTANCE_CHAT' },
					{ text = L['Raid'], value = 'RAID' },
					{ text = L['Party'], value = 'PARTY' },
					{ text = L['Smart'], value = 'SMART' },
					{ text = L['Self'], value = 'SELF' },
				}

				IAnnounce.announceLocation = StdUi:Dropdown(IAnnounce, 190, 20, items, module.DB.announceLocation)
				IAnnounce.announceLocation.OnValueChanged = function(self, value)
					module.DB.announceLocation = value
				end

				-- Create Labels
				IAnnounce.modEnabled = StdUi:Checkbox(IAnnounce, L['Module enabled'], nil, 20)
				IAnnounce.lblActive = StdUi:Label(IAnnounce, L['Active when in'], 13)
				IAnnounce.lblAnnouncelocation = StdUi:Label(IAnnounce, L['Announce location'], 13)

				-- Positioning
				StdUi:GlueTop(IAnnounce.modEnabled, SUI_Win, 0, -10)
				StdUi:GlueBelow(IAnnounce.lblAnnouncelocation, IAnnounce.modEnabled, -100, -20)
				StdUi:GlueRight(IAnnounce.announceLocation, IAnnounce.lblAnnouncelocation, 5, 0)

				-- Active locations
				StdUi:GlueBelow(IAnnounce.lblActive, IAnnounce.lblAnnouncelocation, -80, -20)

				StdUi:GlueBelow(IAnnounce.options.inBG, IAnnounce.lblActive, 30, 0)
				StdUi:GlueRight(IAnnounce.options.inArena, IAnnounce.options.inBG, 0, 0)
				StdUi:GlueRight(IAnnounce.options.outdoors, IAnnounce.options.inArena, 0, 0)

				StdUi:GlueBelow(IAnnounce.options.inRaid, IAnnounce.options.inBG, 0, 0)
				StdUi:GlueRight(IAnnounce.options.inParty, IAnnounce.options.inRaid, 0, 0)

				-- text display
				IAnnounce.lblAnnouncetext = StdUi:Label(IAnnounce, L['Announce text:'], 13)
				IAnnounce.lblvariable1 = StdUi:Label(IAnnounce, '%t - ' .. L['Target that was interrupted'], 13)
				IAnnounce.lblvariable2 = StdUi:Label(IAnnounce, '%spell - ' .. L['Spell link of spell interrupted'], 13)
				IAnnounce.lblvariable3 = StdUi:Label(IAnnounce, '%cl - ' .. L['Spell class'], 13)
				IAnnounce.lblvariable4 = StdUi:Label(IAnnounce, '%myspell - ' .. L['Spell you used to interrupt'], 13)
				IAnnounce.tbAnnounceText = StdUi:SimpleEditBox(IAnnounce, 300, 24, module.DB.text)

				StdUi:GlueBelow(IAnnounce.lblAnnouncetext, IAnnounce.lblActive, 0, -80)
				StdUi:GlueBelow(IAnnounce.lblvariable1, IAnnounce.lblAnnouncetext, 15, -5, 'LEFT')
				StdUi:GlueBelow(IAnnounce.lblvariable2, IAnnounce.lblvariable1, 0, -5, 'LEFT')
				StdUi:GlueBelow(IAnnounce.lblvariable3, IAnnounce.lblvariable2, 0, -5, 'LEFT')
				StdUi:GlueBelow(IAnnounce.lblvariable4, IAnnounce.lblvariable3, 0, -5, 'LEFT')
				StdUi:GlueBelow(IAnnounce.tbAnnounceText, IAnnounce.lblvariable4, -15, -5, 'LEFT')

				-- Defaults
				IAnnounce.modEnabled:SetChecked(SUI:IsModuleEnabled('InterruptAnnouncer'))
				for key, object in pairs(IAnnounce.options) do
					object:SetChecked(module.DB[key])
				end

				IAnnounce.modEnabled:HookScript('OnClick', function()
					for _, object in pairs(IAnnounce.options) do
						if IAnnounce.modEnabled:GetChecked() then
							object:Enable()
						else
							object:Disable()
						end
					end
				end)
			end

			SUI_Win.IAnnounce = IAnnounce
		end,
		Next = function()
			if SUI:IsModuleEnabled('CombatLog') then
				local window = SUI.Setup.window
				local IAnnounce = window.content.IAnnounce
				if not IAnnounce.modEnabled:GetChecked() then SUI:DisableModule(module) end

				for key, object in pairs(IAnnounce.options) do
					module.DB[key] = object:GetChecked()
				end
				module.DB.text = IAnnounce.tbAnnounceText:GetText()
			end
			module.DB.FirstLaunch = false
		end,
		Skip = function()
			module.DB.FirstLaunch = false
		end,
	}
	SUI.Setup:AddPage(PageData)
end
