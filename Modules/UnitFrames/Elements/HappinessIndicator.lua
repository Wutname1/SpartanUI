local UF = SUI.UF

local function Build(frame, DB)
	local HappinessIndicator = frame:CreateTexture(nil, 'OVERLAY')
	HappinessIndicator.btn = CreateFrame('Frame', nil, frame)
	HappinessIndicator.Sizeable = true
	local function HIOnEnter(self)
		local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
		if not happiness then
			return
		end

		GameTooltip:SetOwner(HappinessIndicator.btn, 'ANCHOR_RIGHT')
		GameTooltip:SetText(_G['PET_HAPPINESS' .. happiness])
		GameTooltip:AddLine(format(PET_DAMAGE_PERCENTAGE, damagePercentage), '', 1, 1, 1)
		local tooltipLoyalty = nil
		if (loyaltyRate < 0) then
			tooltipLoyalty = _G['LOSING_LOYALTY']
		elseif (loyaltyRate > 0) then
			tooltipLoyalty = _G['GAINING_LOYALTY']
		end
		if (tooltipLoyalty) then
			GameTooltip:AddLine(tooltipLoyalty, '', 1, 1, 1)
		end
		GameTooltip:Show()
	end
	local function HIOnLeave()
		GameTooltip:Hide()
	end
	HappinessIndicator.btn:SetAllPoints(HappinessIndicator)
	HappinessIndicator.btn:SetScript('OnEnter', HIOnEnter)
	HappinessIndicator.btn:SetScript('OnLeave', HIOnLeave)
	HappinessIndicator:Hide()
	HappinessIndicator.PostUpdate = function()
		frame.ElementUpdate(frame, 'HappinessIndicator')
	end
	frame.HappinessIndicator = HappinessIndicator
end

local function Update(frame)
	local DB = frame.HappinessIndicator.DB
end

local function Options(unit)
end

UF:RegisterElement('HappinessIndicator', Build, Update, Options)
