---@class SUI.UF
local UF = SUI.UF
local Auras = {}
local MonitoredIds = {}
local AddToFilterWindow = nil

---@param unit UnitId
---@param data UnitAuraInfo
---@param rules SUI.UF.Auras.Rules
function Auras:Filter(element, unit, data, rules)
	---@param msg any
	local function debug(msg)
		if SUI:IsInTable(MonitoredIds, data.spellId) and SUI.releaseType == 'DEV Build' then
			print(msg)
		end
	end
	local ShouldDisplay = false

	debug('--')
	debug(data.spellId)

	for k, v in pairs(rules) do
		-- debug(k)
		if data[k] then
			-- debug(data.name)
			if type(v) == 'table' then
				if SUI:IsInTable(v, data[k]) then
					if v[data[k]] then
						debug('Force show per rules')
						return true
					else
						debug('Force hide per rules')
						return false
					end
				end
			elseif type(v) == 'boolean' then
				if v and v == data[k] then
					debug(k .. ' Not equal')
					ShouldDisplay = true
				end
			end
		elseif k == 'whitelist' or k == 'blacklist' then
			if v[data.spellId] then
				return (k == 'whitelist' and true) or false
			end
		else
			if k == 'isMount' and v then
				if UF.MountIds[data.spellId] then
					debug('Is mount')
					return true
				end
			elseif k == 'showPlayers' then
				if v == true and data.sourceUnit == 'player' then
					debug('Is casted by the player')
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
			ShouldDisplay = true
		elseif ShouldDisplay and (lessThanMin or moreThanMax) and rules.duration.mode == 'exclude' then
			ShouldDisplay = true
		else
			ShouldDisplay = false
		end
	else
		debug('Durration is not enabled')
	end
	debug('ShouldDisplay result ' .. (ShouldDisplay and 'true' or 'false'))
	return ShouldDisplay
end

---@param element any
---@param button any
function Auras.PostCreateAura(element, button)
	local function UpdateAura(self, elapsed)
		if (self.expiration) then
			self.expiration = math.max(self.expiration - elapsed, 0)

			if (self.expiration > 0 and self.expiration < 60) then
				self.Duration:SetFormattedText('%d', self.expiration)
			else
				self.Duration:SetText()
			end
		end
	end

	if button.SetBackdrop then
		button:SetBackdrop(nil)
		button:SetBackdropColor(0, 0, 0)
	end
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')
	-- button:SetScript('OnEnter', OnAuraEnter)

	-- We create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFont(SUI.Font:GetFont('UnitFrames'), select(2, button.count:GetFont()) - 3)

	local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
	Duration:SetFont(SUI.Font:GetFont('UnitFrames'), 11)
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', UpdateAura)
end

function Auras:PostCreateButton(elementName, button)
	button:SetScript(
		'OnClick',
		function()
			Auras:OnClick(button, elementName)
		end
	)
end

local function CreateAddToFilterWindow()
	local StdUi = SUI.StdUi
	AddToFilterWindow = StdUi:Window(nil, 300, 200, 'Add to Filter')
	AddToFilterWindow:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	AddToFilterWindow:Show()
end

function Auras:OnClick(button, elementName)
	local keyDown = IsShiftKeyDown() and 'SHIFT' or IsAltKeyDown() and 'ALT' or IsControlKeyDown() and 'CTRL'
	if not keyDown then
		return
	end

	if button.data and keyDown then
		if keyDown == 'CTRL' then
			for k, v in pairs(button.data) do
				print(k .. ' = ' .. tostring(v))
			end
		elseif keyDown == 'SHIFT' then
			if not AddToFilterWindow then
				CreateAddToFilterWindow()
			end
		--TODO: Add a way to add spells to the whitelist or blacklist
		end
	end
end

---@param element any
---@param unit UnitId
---@param button any
---@param index integer
function Auras.PostUpdateAura(element, unit, button, index)
	local _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)
	if (duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end

	if button.SetBackdrop then
		if (unit == 'target' and canStealOrPurge) then
			button:SetBackdropColor(0, 1 / 2, 1 / 2)
		elseif (owner ~= 'player') then
			button:SetBackdropColor(0, 0, 0)
		end
	end
end

UF.Auras = Auras