local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	if not _G['GetPetHappiness'] or not (_G['GetPetHappiness'] and 'HUNTER' == select(2, UnitClass('player')) and frame.unitOnCreate == 'pet') then return end
	local HappinessIndicator = frame:CreateTexture(nil, 'OVERLAY')
	HappinessIndicator.btn = CreateFrame('Frame', nil, frame)
	HappinessIndicator.Sizeable = true
	local function HIOnEnter(self)
		local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
		if not happiness then return end

		GameTooltip:SetOwner(HappinessIndicator.btn, 'ANCHOR_RIGHT')
		GameTooltip:SetText(_G['PET_HAPPINESS' .. happiness])
		GameTooltip:AddLine(format(PET_DAMAGE_PERCENTAGE, damagePercentage), '', 1, 1, 1)
		local tooltipLoyalty = nil
		if loyaltyRate < 0 then
			tooltipLoyalty = _G['LOSING_LOYALTY']
		elseif loyaltyRate > 0 then
			tooltipLoyalty = _G['GAINING_LOYALTY']
		end
		if tooltipLoyalty then GameTooltip:AddLine(tooltipLoyalty, '', 1, 1, 1) end
		GameTooltip:Show()
	end
	local function HIOnLeave()
		GameTooltip:Hide()
	end
	HappinessIndicator.btn:SetAllPoints(HappinessIndicator)
	HappinessIndicator.btn:SetScript('OnEnter', HIOnEnter)
	HappinessIndicator.btn:SetScript('OnLeave', HIOnLeave)
	HappinessIndicator:Hide()
	HappinessIndicator.UpdateSUI = CreateFrame('Frame', nil, frame)
	HappinessIndicator.UpdateSUI:RegisterEvent('UNIT_HAPPINESS')
	HappinessIndicator.UpdateSUI:SetScript('OnEvent', function()
		frame:ElementUpdate('HappinessIndicator')
	end)
	HappinessIndicator.UpdateSUI:Hide()
	frame.HappinessIndicator = HappinessIndicator
end

---@param frame table
local function Update(frame)
	local DB = frame.HappinessIndicator.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet) end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	position = {
		anchor = 'LEFT',
		x = -10,
		y = -10,
	},
	config = {
		type = 'Indicator',
		DisplayName = 'Happiness',
	},
}

UF.Elements:Register('HappinessIndicator', Build, Update, Options, Settings)
