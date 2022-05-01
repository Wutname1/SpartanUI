local UF = SUI.UF

local function Build(frame)
	local playerClass = select(2, UnitClass('player'))
	if playerClass == 'DEATHKNIGHT' then
		frame.Runes = CreateFrame('Frame', nil, frame)
		frame.Runes.colorSpec = true

		for i = 1, 6 do
			frame.Runes[i] = CreateFrame('StatusBar', frame:GetName() .. '_Runes' .. i, frame)
			frame.Runes[i]:SetHeight(6)
			frame.Runes[i]:SetWidth((frame.Health:GetWidth() - 10) / 6)
			if (i == 1) then
				frame.Runes[i]:SetPoint('TOPLEFT', frame.Name, 'BOTTOMLEFT', 0, -3)
			else
				frame.Runes[i]:SetPoint('TOPLEFT', frame.Runes[i - 1], 'TOPRIGHT', 2, 0)
			end
			frame.Runes[i]:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
			frame.Runes[i]:SetStatusBarColor(0, .39, .63, 1)

			frame.Runes[i].bg = frame.Runes[i]:CreateTexture(nil, 'BORDER')
			frame.Runes[i].bg:SetPoint('TOPLEFT', frame.Runes[i], 'TOPLEFT', -0, 0)
			frame.Runes[i].bg:SetPoint('BOTTOMRIGHT', frame.Runes[i], 'BOTTOMRIGHT', 0, -0)
			frame.Runes[i].bg:SetTexture('Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2')
			frame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
			frame.Runes[i].bg.multiplier = 0.64
			frame.Runes[i]:Hide()
		end
	end
end

local function Update(frame)
	local DB = frame.Runes.DB
end

local function Options(unitName)
end

UF.Elements:Register('Runes', Build, Update, Options)
