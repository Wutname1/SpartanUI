---@class SUI.UF
local UF = SUI.UF
local Auras = {}
UF.MonitoredBuffs = {}

-- Logger for debug output (uses LibAT Logger system)
local function GetLogger()
	if SUI.logger then
		return SUI.logger
	end
	-- Fallback if logger not available
	return {
		debug = function(_, msg)
			-- Silent fallback
		end,
		info = function(_, msg)
			SUI:Print(msg)
		end,
	}
end

-- Track which auras we've already logged to avoid spam
local loggedAuras = {}
local loggedAurasCount = 0
local MAX_LOGGED_AURAS = 100 -- Clear cache after this many entries to prevent memory leak
local secretValueLoggingEnabled = false -- Disabled by default to avoid log spam

-- Enable/disable secret value logging
-- Use: UF.Auras:EnableSecretLogging(true) or /run SUI.UF.Auras:EnableSecretLogging(true)
function Auras:EnableSecretLogging(enabled)
	secretValueLoggingEnabled = enabled
	loggedAuras = {} -- Clear cache when toggling
	loggedAurasCount = 0
	local status = enabled and 'ENABLED' or 'DISABLED'
	GetLogger():info('[UF.Auras] Secret value logging ' .. status .. '. Use /logs to view output.')
end

-- Diagnostic function to log whether aura properties are secret values
-- Logs once per unique aura (by auraInstanceID) to avoid spam
---@param data UnitAuraInfo
---@param unit UnitId
local function LogAuraSecretStatus(data, unit)
	-- Check if logging is enabled
	if not secretValueLoggingEnabled then
		return
	end

	if not SUI.IsRetail then
		return -- Only relevant for Retail
	end

	if not data then
		return
	end

	-- Get a unique key for this aura - auraInstanceID is always safe
	local auraKey = data.auraInstanceID
	if not auraKey then
		return -- No way to track uniqueness
	end

	-- Check if we already logged this aura
	if loggedAuras[auraKey] then
		return
	end

	-- Mark as logged
	loggedAuras[auraKey] = true
	loggedAurasCount = loggedAurasCount + 1

	-- Clear cache if it gets too large
	if loggedAurasCount > MAX_LOGGED_AURAS then
		loggedAuras = {}
		loggedAurasCount = 0
	end

	local logger = GetLogger()

	-- List of properties to check
	local propertiesToCheck = {
		'auraInstanceID',
		'name',
		'icon',
		'applications',
		'dispelName',
		'duration',
		'expirationTime',
		'sourceUnit',
		'isStealable',
		'nameplateShowPersonal',
		'spellId',
		'canApplyAura',
		'isBossAura',
		'isFromPlayerOrPlayerPet',
		'nameplateShowAll',
		'timeMod',
		'points',
		'isHarmful',
		'isHelpful',
		'isRaid',
		'isNameplateOnly',
		-- oUF-created properties (should always be safe)
		'isPlayerAura',
		'isHarmfulAura',
	}

	logger:info('[UF.Auras] === Secret Value Check for aura ID: ' .. tostring(auraKey) .. ' on ' .. tostring(unit) .. ' ===')

	for _, prop in ipairs(propertiesToCheck) do
		local value = data[prop]
		local isSecret = false
		local safeForDisplay = 'nil'

		if value ~= nil then
			-- Check if it's a secret value
			if issecretvalue and issecretvalue(value) then
				isSecret = true
				safeForDisplay = '<SECRET>'
			else
				-- Safe to display - convert to string
				if type(value) == 'table' then
					safeForDisplay = 'table[' .. #value .. ']'
				elseif type(value) == 'boolean' then
					safeForDisplay = value and 'true' or 'false'
				else
					safeForDisplay = tostring(value)
				end
			end
		end

		local status = isSecret and 'SECRET' or 'safe'
		logger:info('[UF.Auras]   ' .. prop .. ': ' .. status .. ' = ' .. safeForDisplay)
	end

	logger:info('[UF.Auras] === End Secret Value Check ===')
end

-- Export for use in other modules
Auras.LogAuraSecretStatus = LogAuraSecretStatus

---@param unit UnitId
---@param data UnitAuraInfo
---@param rules SUI.UF.Auras.Rules
function Auras:Filter(element, unit, data, rules)
	if not SUI.BlizzAPI.canaccesstable(data) then
		return true
	end

	-- Log secret value status for diagnostics (only logs once per aura)
	LogAuraSecretStatus(data, unit)

	if SUI.IsRetail then
		-- RETAIL: Boolean-only filtering to avoid secret value crashes
		-- Never access spellId, name, duration, or other potentially secret fields
		local match = false

		-- Source filters
		if rules.isFromPlayerOrPlayerPet and data.isFromPlayerOrPlayerPet then
			match = true
		end

		if rules.isBossAura and data.isBossAura then
			match = true
		end

		-- Type filters
		if rules.isHelpful and data.isHelpful then
			match = true
		end

		if rules.isHarmful and data.isHarmful then
			match = true
		end

		-- Special filters
		if rules.isStealable and data.isStealable then
			match = true
		end

		if rules.isRaid and data.isRaid then
			match = true
		end

		-- Nameplate filters
		if rules.nameplateShowPersonal and data.nameplateShowPersonal then
			match = true
		end

		if rules.nameplateShowAll and data.nameplateShowAll then
			match = true
		end

		if rules.isNameplateOnly and data.isNameplateOnly then
			match = true
		end

		if rules.canApplyAura and data.canApplyAura then
			match = true
		end

		return match
	else
		-- CLASSIC: Full filtering including whitelist/blacklist/duration
		---@param msg any
		local function debug(msg)
			if not UF.MonitoredBuffs[unit] then
				UF.MonitoredBuffs[unit] = {}
			end

			if spellIdNum and SUI:IsInTable(UF.MonitoredBuffs[unit], spellIdNum) then
				GetLogger():debug('[UF.Auras] ' .. tostring(msg))
			end
		end
		local ShouldDisplay = false
		element.displayReasons[data.spellId] = {}

		local function AddDisplayReason(reason)
			debug('Adding display reason ' .. reason)
			element.displayReasons[data.spellId][reason] = true
			ShouldDisplay = true
		end

		debug('----')
		debug(data.spellId)

		for k, v in pairs(rules) do
			-- debug(k)
			if data[k] then
				-- debug(data.name)
				if type(v) == 'table' then
					if SUI:IsInTable(v, data[k]) then
						if v[data[k]] then
							debug('Force show per rules')
							AddDisplayReason(k)
						else
							debug('Force hide per rules')
							return false
						end
					end
				elseif type(v) == 'boolean' then
					if v and v == data[k] then
						debug(k .. ' Not equal')
						AddDisplayReason(k)
					end
				end
			elseif k == 'whitelist' or k == 'blacklist' then
				-- WoW 12.0.0: Use string key for table lookups
				if v[data.spellId] then
					if k == 'whitelist' then
						AddDisplayReason(k)
						return true
					else
						debug('Blacklisted')
						return false
					end
				end
			else
				if k == 'isMount' and v then
					-- WoW 12.0.0: Use string key for table lookups
					if UF.MountIds[data.spellId] then
						AddDisplayReason(k)
						return true
					end
				elseif k == 'showPlayers' then
					if v == true and data.sourceUnit == 'player' then
						debug('Is casted by the player')
						AddDisplayReason(k)
						ShouldDisplay = true
					end
				end
			end
		end

		if rules.duration.enabled then
			local moreThanMax = data.duration > rules.duration.maxTime
			local lessThanMin = data.duration < rules.duration.minTime
			debug('Durration is ' .. data.duration)
			debug('Is More than ' .. rules.duration.maxTime .. ' = ' .. (moreThanMax and 'true' or 'false'))
			debug('Is Less than ' .. rules.duration.minTime .. ' = ' .. (lessThanMin and 'true' or 'false'))
			if ShouldDisplay and (not lessThanMin and not moreThanMax) and rules.duration.mode == 'include' then
				AddDisplayReason('duration')
			elseif ShouldDisplay and (lessThanMin or moreThanMax) and rules.duration.mode == 'exclude' then
				AddDisplayReason('duration')
			else
				debug('Durration check Failed, ShouldDisplay is now false')
				ShouldDisplay = false
			end
		else
			debug('Durration is not enabled')
		end
		debug('ShouldDisplay result ' .. (ShouldDisplay and 'true' or 'false'))
		debug('----')
		-- WoW 12.0.0: Use numeric value for table operations
		if spellIdNum and SUI:IsInTable(UF.MonitoredBuffs[unit], spellIdNum) then
			for i, v in ipairs(UF.MonitoredBuffs[unit]) do
				if v == spellIdNum then
					debug('Removed ' .. data.spellId .. ' from the list of monitored buffs for ' .. unit)
					table.remove(UF.MonitoredBuffs[unit], i)
					GetLogger():debug('[UF.Auras] ----')
				end
			end
		end

		return ShouldDisplay
	end
end

-- Priority tiers for aura sorting (higher = more important, shown first)
-- These are base priorities that get applied based on aura properties
local PRIORITY_BOSS = 100 -- Boss auras are highest priority
local PRIORITY_DISPELLABLE = 80 -- Dispellable debuffs (for healers)
local PRIORITY_PLAYER = 60 -- Player-cast auras
local PRIORITY_STEALABLE = 50 -- Stealable buffs (for offensive dispel)
local PRIORITY_RAID = 40 -- Raid-marked auras
local PRIORITY_OTHER = 20 -- Everything else

-- Helper to safely check if a value is a secret value (Retail WoW 12.0+)
-- Secret values cannot be used in boolean tests, comparisons, or arithmetic
local function IsSafeValue(value)
	-- issecretvalue is a global WoW API function
	if issecretvalue then
		return not issecretvalue(value)
	end
	return true -- Classic doesn't have secret values
end

-- Calculate priority for an aura based on its properties
-- RETAIL: Only uses safe values (isPlayerAura, isHarmfulAura created by oUF, auraInstanceID)
-- CLASSIC: Can use full aura properties
---@param data UnitAuraInfo
---@return number
function Auras:GetAuraPriority(data)
	if not data then
		return 0
	end

	local priority = PRIORITY_OTHER

	if SUI.IsRetail then
		-- RETAIL: Only use properties that oUF has pre-processed as safe
		-- isPlayerAura is safe - created by oUF using C_UnitAuras.IsAuraFilteredOutByInstanceID
		-- isHarmfulAura is safe - created by oUF from filter string
		if data.isPlayerAura then
			priority = PRIORITY_PLAYER
		end
		-- That's all we can safely test in Retail - other properties are secret values
	else
		-- CLASSIC: Full access to all aura properties
		-- Boss auras are highest priority
		if data.isBossAura then
			priority = PRIORITY_BOSS
		-- Player-cast auras
		elseif data.isPlayerAura or data.isFromPlayerOrPlayerPet then
			priority = PRIORITY_PLAYER
		-- Raid-flagged auras
		elseif data.isRaid then
			priority = PRIORITY_RAID
		end

		-- Boost priority for dispellable debuffs (important for healers)
		if data.isHarmfulAura and data.dispelName then
			priority = math.max(priority, PRIORITY_DISPELLABLE)
		end

		-- Boost priority for stealable buffs (important for mages/priests)
		if data.isStealable then
			priority = math.max(priority, PRIORITY_STEALABLE)
		end
	end

	return priority
end

-- Safely get a numeric value from aura data (handles secret values)
-- Returns fallback if value is nil, secret, or causes error
local function SafeGetNumber(data, field, fallback)
	if not data then
		return fallback
	end
	local value = data[field]
	if value == nil then
		return fallback
	end
	-- Check if it's a secret value
	if issecretvalue and issecretvalue(value) then
		return fallback
	end
	return value
end

-- Safely get a string value from aura data (handles secret values)
local function SafeGetString(data, field, fallback)
	if not data then
		return fallback
	end
	local value = data[field]
	if value == nil then
		return fallback
	end
	-- Check if it's a secret value
	if issecretvalue and issecretvalue(value) then
		return fallback
	end
	return value
end

-- Create a sort function for auras based on the specified mode
-- Mode can be: 'priority', 'time', 'name', or nil (default oUF behavior)
-- All sort functions are designed to be safe with Retail's secret values
---@param sortMode string
---@return function|nil
function Auras:CreateSortFunction(sortMode)
	if sortMode == 'priority' then
		return function(a, b)
			local priorityA = Auras:GetAuraPriority(a)
			local priorityB = Auras:GetAuraPriority(b)

			-- Higher priority first
			if priorityA ~= priorityB then
				return priorityA > priorityB
			end

			-- Same priority: player auras first (safe property created by oUF)
			if a.isPlayerAura ~= b.isPlayerAura then
				return a.isPlayerAura == true
			end

			-- Fallback to instance ID for stability (always safe - it's an integer)
			local idA = SafeGetNumber(a, 'auraInstanceID', 0)
			local idB = SafeGetNumber(b, 'auraInstanceID', 0)
			return idA < idB
		end
	elseif sortMode == 'time' then
		return function(a, b)
			-- Player auras first (safe property)
			if a.isPlayerAura ~= b.isPlayerAura then
				return a.isPlayerAura == true
			end

			-- Fallback to instance ID for stability
			local idA = SafeGetNumber(a, 'auraInstanceID', 0)
			local idB = SafeGetNumber(b, 'auraInstanceID', 0)
			return idA < idB
		end
	elseif sortMode == 'name' then
		return function(a, b)
			-- In Retail, name might be a secret value, so we can't sort by it
			-- Fall back to player auras first, then instance ID
			if a.isPlayerAura ~= b.isPlayerAura then
				return a.isPlayerAura == true
			end

			local idA = SafeGetNumber(a, 'auraInstanceID', 0)
			local idB = SafeGetNumber(b, 'auraInstanceID', 0)
			return idA < idB
		end
	end

	-- nil = use default oUF sorting
	return nil
end

-- Format duration for display (handles seconds, minutes, hours)
---@param duration number
---@return string
local function FormatDuration(duration)
	if duration >= 3600 then
		return string.format('%dh', math.floor(duration / 3600))
	elseif duration >= 60 then
		return string.format('%dm', math.floor(duration / 60))
	elseif duration >= 10 then
		return string.format('%d', math.floor(duration))
	else
		return string.format('%.1f', duration)
	end
end

-- OnUpdate handler for duration text
---@param button any
---@param elapsed number
local function DurationOnUpdate(button, elapsed)
	if not button.expiration or button.expiration == math.huge then
		if button.Duration then
			button.Duration:SetText('')
		end
		return
	end

	button.expiration = button.expiration - elapsed
	if button.expiration <= 0 then
		if button.Duration then
			button.Duration:SetText('')
		end
		return
	end

	if button.Duration and button.showDuration then
		-- Color based on remaining time
		if button.expiration < 5 then
			button.Duration:SetTextColor(1, 0.2, 0.2) -- Red for < 5s
		elseif button.expiration < 30 then
			button.Duration:SetTextColor(1, 1, 0.2) -- Yellow for < 30s
		else
			button.Duration:SetTextColor(1, 1, 1) -- White otherwise
		end
		button.Duration:SetText(FormatDuration(button.expiration))
	end
end

---@param elementName string
---@param button any
function Auras:PostCreateButton(elementName, button)
	button:SetScript('OnClick', function()
		Auras:OnClick(button, elementName)
	end)
	--Remove game cooldown text
	button.Cooldown:SetHideCountdownNumbers(true)

	-- Create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(button:GetFrameLevel() + 10)
	StringParent:SetAllPoints(button)

	-- Reposition count text
	if button.Count then
		button.Count:SetParent(StringParent)
		button.Count:ClearAllPoints()
		button.Count:SetPoint('BOTTOMRIGHT', button, 2, -2)
		button.Count:SetFont(SUI.Font:GetFont('UnitFrames'), 10, 'OUTLINE')
	end

	-- Create duration text
	local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
	Duration:SetFont(SUI.Font:GetFont('UnitFrames'), 10, 'OUTLINE')
	Duration:SetPoint('CENTER', button, 'CENTER', 0, 0)
	Duration:SetJustifyH('CENTER')
	button.Duration = Duration
	button.showDuration = true -- Default to showing duration

	-- Set up OnUpdate for duration countdown
	button:HookScript('OnUpdate', DurationOnUpdate)
end

local function CreateAddToFilterWindow(button, elementName)
	local AceGUI = SUI.Lib.AceGUI
	local window = AceGUI:Create('Frame') ---@type AceGUIFrame
	window:SetTitle('|cffffffffSpartan|cffe21f1fUI|r Aura filter addition')
	window:SetWidth(500)
	window:SetHeight(400)
	window:EnableResize(false)

	local label = AceGUI:Create('Label') ---@type AceGUILabel
	label:SetText(button.data.name)
	label:SetJustifyH('CENTER')
	label:SetImage(button.data.icon)
	label:SetFont(SUI.Font:GetFont(), 12, 'OUTLINE')
	label:SetParent(window)
	label.frame:SetPoint('TOP', window.content, 'TOP', 0, 0)
	label.frame:Show()
	window.content.SpellLabel = label

	local group = AceGUI:Create('InlineGroup') ---@type AceGUIInlineGroup
	group:SetTitle('Mode')
	group:SetLayout('Flow')
	group:SetWidth(480)
	group:SetParent(window)
	group.frame:Show()
	group.frame:SetPoint('TOP', label.frame, 'BOTTOM', 0, -5)
	window.content.group = group

	--Create 2 checkboxes for the filter type
	local Whitelist = AceGUI:Create('CheckBox') ---@type AceGUICheckBox
	Whitelist:SetLabel('Whitelist')
	Whitelist:SetType('radio')
	Whitelist:SetValue(false)
	group:AddChild(Whitelist)
	local Blacklist = AceGUI:Create('CheckBox') ---@type AceGUICheckBox
	Blacklist:SetLabel('Blacklist')
	Blacklist:SetType('radio')
	Blacklist:SetValue(true)
	group:AddChild(Blacklist)

	--Set Callbacks
	Whitelist:SetCallback('OnValueChanged', function(_, _, value)
		Whitelist:SetValue(value)
		Blacklist:SetValue(not value)
	end)
	Blacklist:SetCallback('OnValueChanged', function(_, _, value)
		Blacklist:SetValue(value)
		Whitelist:SetValue(not value)
	end)

	--UnitFrameListing to add buff to
	local scrollcontainer = AceGUI:Create('SimpleGroup') ---@type AceGUISimpleGroup
	scrollcontainer:SetWidth(480)
	scrollcontainer:SetHeight(200)
	scrollcontainer:SetLayout('Fill')
	scrollcontainer:SetParent(window)
	scrollcontainer.frame:Show()
	scrollcontainer.frame:SetPoint('TOP', group.frame, 'BOTTOM', 0, -5)
	window.content.scrollcontainer = scrollcontainer

	local scroll = AceGUI:Create('ScrollFrame') ---@type AceGUIScrollFrame
	scroll:SetLayout('Flow')
	scrollcontainer:AddChild(scroll)

	window.units = {}
	for name, config in pairs(SUI.UF.Unit:GetFrameList()) do
		local check = AceGUI:Create('CheckBox') ---@type AceGUICheckBox
		check:SetLabel(config.displayName or name)

		if button.unit == name then
			check:SetValue(true)
		end

		scroll:AddChild(check)
		window.units[name] = check
	end

	--Save Button
	local Save = AceGUI:Create('Button') ---@type AceGUIButton
	Save:SetText('Save')
	Save:SetParent(window)
	Save.frame:HookScript('OnClick', function()
		for frameName, check in pairs(window.units) do
			if check:GetValue() then
				local mode = Whitelist:GetValue() and 'whitelist' or 'blacklist'
				-- WoW 12.0.0: Use string key for table index
				local spellKey = tostring(button.data.spellId)

				UF.CurrentSettings[frameName].elements[elementName].rules[mode][spellKey] = true
				UF.DB.UserSettings[UF.DB.Style][frameName].elements[elementName].rules[mode][spellKey] = true

				UF.Unit[frameName]:ElementUpdate(elementName)
			end
		end

		window:Hide()
	end)
	Save.frame:Show()
	Save.frame:SetPoint('TOP', scrollcontainer.frame, 'BOTTOM', 0, -10)
	window.content.Save = Save

	window.frame.CloseBtn:SetText('Cancel')
end

function Auras:OnClick(button, elementName)
	local keyDown = IsShiftKeyDown() and 'SHIFT' or IsAltKeyDown() and 'ALT' or IsControlKeyDown() and 'CTRL'
	if not keyDown then
		return
	end

	local data = button.data ---@type UnitAuraInfo

	if data and keyDown then
		if keyDown == 'CTRL' then
			-- Show aura properties in logger (accessible via /logs)
			GetLogger():info('[UF.Auras] Aura Properties:')
			for k, v in pairs(data) do
				GetLogger():info('[UF.Auras]   ' .. k .. ' = ' .. tostring(v))
			end
			SUI:Print('Aura properties logged. Use /logs to view details.')
		elseif keyDown == 'ALT' then
			if not SUI.IsRetail then
				-- WoW 12.0.0: Use string key for table index
				local spellKey = tostring(data.spellId)
				if button:GetParent().displayReasons[spellKey] then
					GetLogger():info('[UF.Auras] Reasons for display:')
					for k, _ in pairs(button:GetParent().displayReasons[spellKey]) do
						GetLogger():info('[UF.Auras]   ' .. k)
					end
					SUI:Print('Display reasons logged. Use /logs to view details.')
				end
			else
				SUI:Print('Aura filtering details are not available in Retail due to API restrictions.')
			end
		elseif keyDown == 'SHIFT' then
			if not SUI.IsRetail then
				CreateAddToFilterWindow(button, elementName)
			else
				SUI:Print('Whitelist/Blacklist filtering is not available in Retail due to WoW 12.0+ API restrictions.')
			end
		end
	end
end

---@param element any
---@param unit UnitId
---@param button any
---@param index integer
function Auras.PostUpdateAura(element, unit, button, index)
	local auraData = C_UnitAuras.GetAuraDataByIndex(unit, index, button.filter)
	if not auraData then
		-- Clear duration when aura data unavailable
		button.expiration = nil
		if button.Duration then
			button.Duration:SetText('')
		end
		return
	end

	-- Safely handle duration/expiration (may be secret values in Retail)
	local duration, expiration = auraData.duration, auraData.expirationTime
	if duration and expiration and duration > 0 then
		-- Calculate remaining time
		local remaining = expiration - GetTime()
		if remaining > 0 then
			button.expiration = remaining
		else
			button.expiration = nil
		end
	else
		-- No duration (permanent aura) or invalid data
		button.expiration = math.huge
	end

	-- Visual effects for special aura types
	if button.SetBackdrop then
		if unit == 'target' and auraData.isStealable then
			button:SetBackdropColor(0, 1 / 2, 1 / 2)
		elseif auraData.sourceUnit ~= 'player' then
			button:SetBackdropColor(0, 0, 0)
		end
	end
end

UF.Auras = Auras
