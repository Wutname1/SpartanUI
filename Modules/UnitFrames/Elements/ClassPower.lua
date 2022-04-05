local _G, SUI = _G, SUI
local module = SUI:GetModule('Component_UnitFrames')

local function Build(frame, DB)
	frame.CPAnchor = frame:CreateFontString(nil, 'BORDER')
	frame.CPAnchor:SetPoint('TOPLEFT', frame.Name, 'BOTTOMLEFT', 40, -5)
	local ClassPower = {}
	for index = 1, 10 do
		local Bar = CreateFrame('StatusBar', nil, frame)
		Bar:SetStatusBarTexture(Smoothv2)

		-- Position and size.
		Bar:SetSize(16, 5)
		if (index == 1) then
			Bar:SetPoint('LEFT', frame.CPAnchor, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
		else
			Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
		end
		ClassPower[index] = Bar
	end

	-- Register with oUF
	frame.ClassPower = ClassPower
end

local function Update(frame)
	local DB = frame.ClassPower.DB
end

local function Options()
end

module:RegisterElement('ClassPower', Build, Update, Options)