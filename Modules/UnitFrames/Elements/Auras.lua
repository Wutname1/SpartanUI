local UF = SUI.UF

local function InverseAnchor(anchor)
	if anchor == 'TOPLEFT' then
		return 'BOTTOMLEFT'
	elseif anchor == 'TOPRIGHT' then
		return 'BOTTOMRIGHT'
	elseif anchor == 'BOTTOMLEFT' then
		return 'TOPLEFT'
	elseif anchor == 'BOTTOMRIGHT' then
		return 'TOPRIGHT'
	elseif anchor == 'BOTTOM' then
		return 'TOP'
	elseif anchor == 'TOP' then
		return 'BOTTOM'
	elseif anchor == 'LEFT' then
		return 'RIGHT'
	elseif anchor == 'RIGHT' then
		return 'LEFT'
	end
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- Setup icons if needed
	local iconFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
		if caster == 'player' and (duration == 0 or duration > 60) then --Do not show DOTS & HOTS
			return true
		elseif caster ~= 'player' then
			return true
		end
	end
	local function customFilter(
		element,
		unit,
		button,
		name,
		texture,
		count,
		debuffType,
		duration,
		expiration,
		caster,
		isStealable,
		nameplateShowSelf,
		spellID,
		canApply,
		isBossDebuff,
		casterIsPlayer,
		nameplateShowAll,
		timeMod,
		effect1,
		effect2,
		effect3)
		-- check for onlyShowPlayer rules
		if (element.onlyShowPlayer and button.isPlayer) or (not element.onlyShowPlayer and name) then
			return true
		end
		-- Check boss rules
		if isBossDebuff and element.ShowBossDebuffs then
			return true
		end
		if isStealable and element.ShowStealable then
			return true
		end

		-- We did not find a display rule, so hide it
		return false
	end

	--Buff Icons
	local Buffs = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame)
	-- Buffs.PostUpdate = PostUpdateAura
	-- Buffs.CustomFilter = customFilter
	frame.Buffs = Buffs

	--Debuff Icons
	local Debuffs = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame)
	-- Debuffs.PostUpdate = PostUpdateAura
	-- Debuffs.CustomFilter = customFilter
	frame.Debuffs = Debuffs
end

---@param frame table
local function Update(frame)
	local DB = frame.auras.DB
	if (DB.Buffs.enabled) then
		frame.Buffs:Show()
	else
		frame.Buffs:Hide()
	end
	if (DB.Debuffs.enabled) then
		frame.Debuffs:Show()
	else
		frame.Debuffs:Hide()
	end

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

	local function PostCreateAura(element, button)
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
		button.count:SetFont(SUI:GetFontFace('UnitFrames'), select(2, button.count:GetFont()) - 3)

		local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
		Duration:SetFont(SUI:GetFontFace('UnitFrames'), 11)
		Duration:SetPoint('TOPLEFT', button, 0, -1)
		button.Duration = Duration

		button:HookScript('OnUpdate', UpdateAura)
	end

	local function PostUpdateAura(element, unit, button, index)
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

	local DB = UF.CurrentSettings[frame.unitOnCreate].elements.Auras

	local Buffs = frame.Buffs
	Buffs.size = DB.Buffs.size
	Buffs.initialAnchor = DB.Buffs.initialAnchor
	Buffs['growth-x'] = DB.Buffs.growthx
	Buffs['growth-y'] = DB.Buffs.growthy
	Buffs.spacing = DB.Buffs.spacing
	Buffs.showType = DB.Buffs.showType
	Buffs.num = DB.Buffs.number
	Buffs.onlyShowPlayer = DB.Buffs.onlyShowPlayer
	Buffs.PostCreateIcon = PostCreateAura
	Buffs.PostUpdateIcon = PostUpdateAura
	Buffs:SetPoint(
		InverseAnchor(DB.Buffs.position.anchor),
		frame,
		DB.Buffs.position.anchor,
		DB.Buffs.position.x,
		DB.Buffs.position.y
	)
	local w = (DB.Buffs.number / DB.Buffs.rows)
	if w < 1.5 then
		w = 1.5
	end
	Buffs:SetSize((DB.Buffs.size + DB.Buffs.spacing) * w, (DB.Buffs.spacing + DB.Buffs.size) * DB.Buffs.rows)

	--Debuff Icons
	local Debuffs = frame.Debuffs
	Debuffs.size = DB.Debuffs.size
	Debuffs.initialAnchor = DB.Debuffs.initialAnchor
	Debuffs['growth-x'] = DB.Debuffs.growthx
	Debuffs['growth-y'] = DB.Debuffs.growthy
	Debuffs.spacing = DB.Debuffs.spacing
	Debuffs.showType = DB.Debuffs.showType
	Debuffs.num = DB.Debuffs.number
	Debuffs.onlyShowPlayer = DB.Debuffs.onlyShowPlayer
	Debuffs.PostCreateIcon = PostCreateAura
	Debuffs.PostUpdateIcon = PostUpdateAura
	Debuffs:SetPoint(
		InverseAnchor(DB.Debuffs.position.anchor),
		frame,
		DB.Debuffs.position.anchor,
		DB.Debuffs.position.x,
		DB.Debuffs.position.y
	)
	w = (DB.Debuffs.number / DB.Debuffs.rows)
	if w < 1.5 then
		w = 1.5
	end
	Debuffs:SetSize((DB.Debuffs.size + DB.Debuffs.spacing) * w, (DB.Debuffs.spacing + DB.Debuffs.size) * DB.Debuffs.rows)
	frame:UpdateAllElements('ForceUpdate')
	-- frame.Buffs:PostUpdate(unit, 'Buffs')
	-- frame.Debuffs:PostUpdate(unit, 'Buffs')
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName][option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName][option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('Auras')
	end

	--local DB = UF.CurrentSettings[unitName]
end

UF.Elements:Register('Auras', Build, Update, Options)
