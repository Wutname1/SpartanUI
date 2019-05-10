local SUI = SUI
local module = SUI:NewModule('Component_InterruptAnnouncer')
local L = SUI.L
module.DisplayName = 'Interrupt announcer'
----------------------------------------------------------------------------------------------------
local lastTime, lastSpellID = nil, nil

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
		always = false,
		inBG = false,
		inRaid = true,
		inParty = true,
		inArena = true,
		outdoors = false,
		includePets = true,
		FirstLaunch = true,
		announceLocation = 'SMART',
		text = 'Interupted %t %spell'
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
		continue and
			(eventType == 'SPELL_INTERRUPT' and
				(sourceGUID == UnitGUID('player') or (sourceGUID == UnitGUID('pet') and SUI.DB.InterruptAnnouncer.includePets)))
	 then
		printFormattedString(destName, spellID, spellName, spellSchool, sourceID)
	end
end

function module:OnEnable()
	module:Options()
	module:FirstLaunch()

	SUI:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', COMBAT_LOG_EVENT_UNFILTERED)
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
							return SUI.DB.InterruptAnnouncer.inBG
						end,
						set = function(info, val)
							SUI.DB.InterruptAnnouncer.inBG = val
						end
					},
					inRaid = {
						name = 'Raid',
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
						name = 'Party',
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
						name = 'Arena',
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
						name = 'Outdoor',
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
				name = 'includePets',
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
				name = 'Announce location',
				type = 'select',
				order = 200,
				values = {
					['INSTANCE_CHAT'] = 'Instance chat',
					['RAID'] = 'Raid',
					['PARTY'] = 'Party',
					['SMART'] = 'SMART',
					['SAY'] = 'Say',
					['SELF'] = 'Self'
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
			local IAnnounce = CreateFrame('Frame', nil)
			IAnnounce:SetParent(SUI_Win)
			IAnnounce:SetAllPoints(SUI_Win)

			-- Setup checkboxes
			IAnnounce.options = {}
			IAnnounce.options.alwayson = StdUi:Checkbox(IAnnounce, L['Always on'], nil, 20)

			IAnnounce.options.inBG = StdUi:Checkbox(IAnnounce, L['Announce logging in chat'], nil, 20)
			IAnnounce.options.inRaid = StdUi:Checkbox(IAnnounce, L['Mythic'], 150, 20)
			IAnnounce.options.inParty = StdUi:Checkbox(IAnnounce, L['Heroic'], 150, 20)
			IAnnounce.options.inArena = StdUi:Checkbox(IAnnounce, L['Normal'], 150, 20)
			IAnnounce.options.outdoors = StdUi:Checkbox(IAnnounce, L['Looking for raid'], 150, 20)

			local items = {
				{text = 'Instance chat', value = 'INSTANCE_CHAT'},
				{text = 'Raid', value = 'RAID'},
				{text = 'Party', value = 'PARTY'},
				{text = 'Say', value = 'SAY'},
				{text = 'Smart', value = 'SMART'},
				{text = 'Self', value = 'SELF'}
			}

			IAnnounce.announceLocation = StdUi:Dropdown(IAnnounce, 190, 20, items, SUI.DB.InterruptAnnouncer.announceLocation)
			IAnnounce.announceLocation.OnValueChanged = function(self, value)
				SUI.DB.InterruptAnnouncer.announceLocation = value
			end

			-- Create Labels
			IAnnounce.modEnabled = StdUi:Checkbox(IAnnounce, L['Module enabled'], nil, 20)
			IAnnounce.lblActive = StdUi:Label(IAnnounce, 'Active settings', 13)
			IAnnounce.lblAnnouncelocation = StdUi:Label(IAnnounce, L['Announce location'], 13)

			-- Positioning
			StdUi:GlueTop(IAnnounce.modEnabled, SUI_Win, 0, -10)
			StdUi:GlueBelow(IAnnounce.options.alwayson, IAnnounce.modEnabled, -100, -5)
			StdUi:GlueRight(IAnnounce.announceLocation, IAnnounce.options.alwayson, 5, 0)

			-- Active locations
			StdUi:GlueTop(IAnnounce.options.inBG, IAnnounce.modEnabled, -150, -80)
			StdUi:GlueBelow(IAnnounce.options.inRaid, IAnnounce.options.inBG, 0, -5)
			StdUi:GlueRight(IAnnounce.options.inParty, IAnnounce.options.inRaid, 5, 0)
			StdUi:GlueRight(IAnnounce.options.inArena, IAnnounce.options.inParty, 5, 0)

			StdUi:GlueBelow(IAnnounce.options.outdoors, IAnnounce.options.inRaid, 0, -5)

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
			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end,
		Skip = function()
			SUI.DB.InterruptAnnouncer.FirstLaunch = false
		end
	}
	local SetupWindow = SUI:GetModule('SetupWizard')
	SetupWindow:AddPage(PageData)
end
