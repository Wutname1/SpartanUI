local SUI = SUI
local module = SUI:NewModule('Component_InterruptAnnouncer', 'AceEvent-3.0')
local L = SUI.L
module.DisplayName = 'Interrupt announcer'
----------------------------------------------------------------------------------------------------
local lastTime, lastSpellID = nil, nil

local function printFormattedString(t, sid, spell, ss, ssid)
	local msg = SUI.DB.InterruptAnnouncer.text
	local ChatChannel = SUI.DB.InterruptAnnouncer.announceLocation

	msg =
		msg:gsub('%%t', t):gsub('%%cl', CombatLog_String_SchoolString(ss)):gsub('%%spell', GetSpellLink(sid)):gsub(
		'%%myspell',
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
		always = false,
		inBG = false,
		inRaid = true,
		inParty = true,
		inArena = true,
		outdoors = false,
		includePets = true,
		FirstLaunch = true,
		announceLocation = 'SMART',
		text = 'Interrupted %t %spell'
	}
	if not SUI.DB.InterruptAnnouncer then
		SUI.DB.InterruptAnnouncer = Defaults
	else
		SUI.DB.InterruptAnnouncer = SUI:MergeData(SUI.DB.InterruptAnnouncer, Defaults, false)
	end
end

local function COMBAT_LOG_EVENT_UNFILTERED()
	if not SUI.DB.EnabledComponents.InterruptAnnouncer then
		return
	end

	local continue = false
	local inInstance, instanceType = IsInInstance()
	if instanceType == 'arena' and SUI.DB.InterruptAnnouncer.inArena then
		continue = true
	elseif inInstance and instanceType == 'party' and SUI.DB.InterruptAnnouncer.inParty then
		continue = true
	elseif instanceType == 'pvp' and SUI.DB.InterruptAnnouncer.inBG then
		continue = true
	elseif instanceType == 'raid' and SUI.DB.InterruptAnnouncer.inRaid then
		continue = true
	elseif (instanceType == 'none' or (not inInstance and instanceType == 'party')) and SUI.DB.InterruptAnnouncer.outdoors then
		continue = true
	end

	local timeStamp, eventType, _, sourceGUID, _, _, _, _, destName, _, _, sourceID, _, _, spellID, spellName, spellSchool =
		CombatLogGetCurrentEventInfo()

	-- Check if time and ID was same as last
	-- Note: This is to prevent flooding announcements on AoE taunts.
	if timeStamp == lastTime and spellID == lastSpellID then
		return
	end

	-- Update last time and ID
	lastTime, lastSpellID = timeStamp, spellID

	if
		(continue or SUI.DB.InterruptAnnouncer.alwayson) and eventType == 'SPELL_INTERRUPT' and
			(sourceGUID == UnitGUID('player') or (sourceGUID == UnitGUID('pet') and SUI.DB.InterruptAnnouncer.includePets))
	 then
		printFormattedString(destName, spellID, spellName, spellSchool, sourceID)
	end
end

function module:OnEnable()
	module:Options()
	module:FirstLaunch()

	module:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', COMBAT_LOG_EVENT_UNFILTERED)
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
					return SUI.DB.InterruptAnnouncer.alwayson
				end,
				set = function(info, val)
					SUI.DB.InterruptAnnouncer.alwayson = val
				end
			},
			active = {
				name = L['Active when in'],
				type = 'group',
				inline = true,
				order = 100,
				args = {
					inBG = {
						name = L['Battleground'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.inBG
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.inBG = val
						end
					},
					inRaid = {
						name = L['Raid'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.inRaid
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.inRaid = val
						end
					},
					inParty = {
						name = L['Party'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.inParty
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.inParty = val
						end
					},
					inArena = {
						name = L['Arena'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.inArena
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.inArena = val
						end
					},
					outdoors = {
						name = L['Outdoors'],
						type = 'toggle',
						order = 1,
						get = function(info)
							return SUI.DB.InterruptAnnouncer.outdoors
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.outdoors = val
						end
					}
				}
			},
			includePets = {
				name = L['Include pets'],
				type = 'toggle',
				order = 1,
				get = function(info)
					return SUI.DB.InterruptAnnouncer.includePets
				end,
				set = function(info, val)
					SUI.DB.InterruptAnnouncer.includePets = val
				end
			},
			announceLocation = {
				name = L['Announce location'],
				type = 'select',
				order = 200,
				values = {
					['INSTANCE_CHAT'] = L['Instance chat'],
					['PARTY'] = L['Party'],
					['RAID'] = L['Raid'],
					['SAY'] = L['Say'],
					['SELF'] = L['Self'],
					['SMART'] = L['Smart']
				},
				get = function(info)
					return SUI.DB.InterruptAnnouncer.announceLocation
				end,
				set = function(info, val)
					SUI.DB.InterruptAnnouncer.announceLocation = val
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
						name = '- %t - ' .. L['Target that was interrupted'],
						type = 'description',
						order = 11,
						fontSize = 'small'
					},
					c = {
						name = '- %spell - ' .. L['Spell link of spell interrupted'],
						type = 'description',
						order = 12,
						fontSize = 'small'
					},
					d = {
						name = '- %cl - ' .. L['Spell class'],
						type = 'description',
						order = 14,
						fontSize = 'small'
					},
					f = {
						name = '- %myspell - ' .. L['Spell you used to interrupt'],
						type = 'description',
						order = 15,
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
							return SUI.DB.InterruptAnnouncer.text
						end,
						set = function(info, value)
							SUI.DB.InterruptAnnouncer.text = value
						end
					}
				}
			}
		}
	}
end

function module:FirstLaunch()
	local PageData = {
		ID = 'InterruptAnnouncer',
		Name = L['Interrupt announcer'],
		SubTitle = L['Interrupt announcer'],
		RequireDisplay = SUI.DB.InterruptAnnouncer.FirstLaunch,
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi
			if not SUI.DB.EnabledComponents.InterruptAnnouncer then
				window.Skip:Click()
			end

			--Container
			local IAnnounce = CreateFrame('Frame', nil)
			IAnnounce:SetParent(SUI_Win)
			IAnnounce:SetAllPoints(SUI_Win)

			-- Setup checkboxes
			IAnnounce.options = {}
			IAnnounce.options.alwayson = StdUi:Checkbox(IAnnounce, L['Always on'], 120, 20)

			IAnnounce.options.inBG = StdUi:Checkbox(IAnnounce, L['Battleground'], 120, 20)
			IAnnounce.options.inRaid = StdUi:Checkbox(IAnnounce, L['Raid'], 120, 20)
			IAnnounce.options.inParty = StdUi:Checkbox(IAnnounce, L['Party'], 120, 20)
			IAnnounce.options.inArena = StdUi:Checkbox(IAnnounce, L['Arena'], 120, 20)
			IAnnounce.options.outdoors = StdUi:Checkbox(IAnnounce, L['Outdoors'], 120, 20)

			local items = {
				{text = L['Instance chat'], value = 'INSTANCE_CHAT'},
				{text = L['Raid'], value = 'RAID'},
				{text = L['Party'], value = 'PARTY'},
				{text = L['Say'], value = 'SAY'},
				{text = L['Smart'], value = 'SMART'},
				{text = L['Self'], value = 'SELF'}
			}

			IAnnounce.announceLocation = StdUi:Dropdown(IAnnounce, 190, 20, items, SUI.DB.InterruptAnnouncer.announceLocation)
			IAnnounce.announceLocation.OnValueChanged = function(self, value)
				SUI.DB.InterruptAnnouncer.announceLocation = value
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
			IAnnounce.lblAnnouncetext = StdUi:Label(TauntWatch, L['Announce text:'], 13)
			IAnnounce.lblvariable1 = StdUi:Label(TauntWatch, '%t - ' .. L['Target that was interrupted'], 13)
			IAnnounce.lblvariable2 = StdUi:Label(TauntWatch, '%spell - ' .. L['Spell link of spell interrupted'], 13)
			IAnnounce.lblvariable3 = StdUi:Label(TauntWatch, '%cl - ' .. L['Spell class'], 13)
			IAnnounce.lblvariable4 = StdUi:Label(TauntWatch, '%myspell - ' .. L['Spell you used to interrupt'], 13)
			IAnnounce.tbAnnounceText = StdUi:SimpleEditBox(TauntWatch, 300, 24, SUI.DB.InterruptAnnouncer.text)

			StdUi:GlueBelow(IAnnounce.lblAnnouncetext, IAnnounce.lblActive, 0, -80)
			StdUi:GlueBelow(IAnnounce.lblvariable1, IAnnounce.lblAnnouncetext, 15, -5, 'LEFT')
			StdUi:GlueBelow(IAnnounce.lblvariable2, IAnnounce.lblvariable1, 0, -5, 'LEFT')
			StdUi:GlueBelow(IAnnounce.lblvariable3, IAnnounce.lblvariable2, 0, -5, 'LEFT')
			StdUi:GlueBelow(IAnnounce.lblvariable4, IAnnounce.lblvariable3, 0, -5, 'LEFT')
			StdUi:GlueBelow(IAnnounce.tbAnnounceText, IAnnounce.lblvariable4, -15, -5, 'LEFT')

			-- Defaults
			IAnnounce.modEnabled:SetChecked(SUI.DB.EnabledComponents.InterruptAnnouncer)
			for key, object in pairs(IAnnounce.options) do
				object:SetChecked(SUI.DB.InterruptAnnouncer[key])
			end

			IAnnounce.modEnabled:HookScript(
				'OnClick',
				function()
					for _, object in pairs(IAnnounce.options) do
						if IAnnounce.modEnabled:GetChecked() then
							object:Enable()
						else
							object:Disable()
						end
					end
				end
			)

			SUI_Win.IAnnounce = IAnnounce
		end,
		Next = function()
			local window = SUI:GetModule('SetupWizard').window
			local IAnnounce = window.content.IAnnounce
			SUI.DB.EnabledComponents.InterruptAnnouncer = IAnnounce.modEnabled:GetChecked()

			for key, object in pairs(IAnnounce.options) do
				SUI.DB.InterruptAnnouncer[key] = object:GetChecked()
			end
			SUI.DB.InterruptAnnouncer.text = IAnnounce.tbAnnounceText:GetValue()
			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end,
		Skip = function()
			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end
