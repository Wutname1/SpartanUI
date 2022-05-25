local UF, L = SUI.UF, SUI.L

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
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable

-- UF.Elements:Register('Auras', Build, Update, Options)
