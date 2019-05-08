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
end
