---@class SUI.UnitFrame
local UF = SUI:GetModule('Module_UnitFrames')
local Auras = {}

---@param unit UnitId
---@param data UnitAuraInfo
---@param rules SUI.UnitFrame.Auras.Rules
function Auras:Filter(element, unit, data, rules)
	local ShouldDisplay = false

	for k, v in pairs(rules) do
		UF:debug(k, unit, 'FilterAura')
		if data[k] then
			UF:debug(data.name, unit, 'FilterAura')
			if type(v) == 'table' then
				if k == 'duration' and v.enabled then
				elseif SUI:IsInTable(v, data[k]) then
					if v[data[k]] then
						UF:debug('Force show per rules', unit, 'FilterAura')
						return true
					else
						UF:debug('Force hide per rules', unit, 'FilterAura')
						return false
					end
				end
			elseif type(v) == 'boolean' then
				if v and v == data[k] then
					UF:debug('Not equal', unit, 'FilterAura')
					ShouldDisplay = true
				end
			end
		elseif k == 'whitelist' or k == 'blacklist' then
			if v[data.spellId] then
				return (k == 'whitelist' and true) or false
			end
		end
	end

	if rules.duration.enabled then
		local moreThanMax = data.duration > rules.duration.maxTime
		local lessThanMin = data.duration < rules.duration.minTime
		UF:debug('Durration is ' .. data.duration, unit, 'FilterAura')
		if ShouldDisplay and (lessThanMin and moreThanMax) then
			return true
		else
			return false
		end
	end

	UF:debug('ShouldDisplay result ' .. (ShouldDisplay and 'true' or 'false'), unit, 'FilterAura')
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
