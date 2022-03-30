local addonName, ns = ...
local oUF = ns.oUF or oUF

if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end

local LibClassicDurations = LibStub("LibClassicDurations")
LibClassicDurations:RegisterFrame(addonName)

local LCDWrapper = function(element, unit, button, index, position, duration, expiration, debuffType, isStealable)
	if duration == 0 then
		-- PostUpdateIcon doesn't pass spellID, so have to call UnitAura again for it
		local name, _, _, _, _, _, caster, _, _, spellID = UnitAura(unit, index, button.filter)
		local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellID, caster, name)
		if durationNew and durationNew > 0 then
			duration = durationNew
			expiration = expirationTimeNew

			if(button.cd and not element.disableCooldown) then
				button.cd:SetCooldown(expiration - duration, duration)
				button.cd:Show()
			end
		end
	end

	local originalPostUpdateIcon = element.PostUpdateIcon_cHcTXm3
	if originalPostUpdateIcon then
		originalPostUpdateIcon(element, unit, button, index, position, duration, expiration, debuffType, isStealable)
	end
end

local function prehook_PostUpdateIcon(element)
	element.PostUpdateIcon_cHcTXm3 = element.PostUpdateIcon
	element.PostUpdateIcon = LCDWrapper
end

local function hook(frame)
	if frame.Buffs then
		if frame.Buffs then
			prehook_PostUpdateIcon(frame.Buffs)
		end
	end
	if frame.Debuffs then
		if frame.Debuffs then
			prehook_PostUpdateIcon(frame.Debuffs)
		end
	end
end


for i, frame in ipairs(oUF.objects) do hook(frame) end
oUF:RegisterInitCallback(hook)
