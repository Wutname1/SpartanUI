---@diagnostic disable: missing-parameter
local _, ns = ...
local oUF = ns.oUF or oUF

-- HoT (Heal Over Time) spell listing utility
-- Returns class-specific HoT spell IDs for AuraWatch and other systems
-- This function is attached to the global SUI table when SUI is available
local function HotsListing()
	local _, classFileName = UnitClass('player')
	local lifebloomInfo = C_Spell.GetSpellInfo('Lifebloom')
	local lifebloomSpellId = lifebloomInfo and lifebloomInfo.spellID

	if classFileName == 'DRUID' then
		return {
			774, -- Rejuvenation
			lifebloomSpellId, -- Lifebloom
			8936, -- Regrowth
			48438, -- Wild Growth
			155777, -- Germination
			102351, -- Cenarion Ward
			102342, -- Ironbark
		}
	elseif classFileName == 'PRIEST' then
		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			return {
				139, -- Renew
				17, -- Power Word: Shield
			}
		else
			return {
				139, -- Renew
				17, -- Power Word: Shield
				33076, -- Prayer of Mending
			}
		end
	elseif classFileName == 'MONK' then
		return {
			119611, -- Renewing Mist
			227345, -- Enveloping Mist
		}
	end

	return {}
end

-- Export to SUI global when it becomes available
local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:SetScript('OnEvent', function(self, event, addonName)
	if addonName == 'SpartanUI' and SUI then
		SUI.HotsListing = HotsListing
		self:UnregisterEvent('ADDON_LOADED')
	end
end)
