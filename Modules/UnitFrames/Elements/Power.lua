local UF = SUI.UF
local Smoothv2 = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'

---@param frame table
---@param DB table
local function Build(frame, DB)
	local power = CreateFrame('StatusBar', nil, frame)
	power:SetStatusBarTexture(Smoothv2)
	power:SetHeight(DB.height)

	local Background = power:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(power)
	Background:SetTexture(Smoothv2)
	Background:SetVertexColor(1, 1, 1, .2)
	power.bg = Background

	-- local powerOffset = DB.offset
	-- if elementsDB.Castbar.enabled then
	-- 	powerOffset = powerOffset + elementsDB.Castbar.height
	-- end
	-- if elementsDB.Health.enabled then
	-- 	powerOffset = powerOffset + elementsDB.Health.height
	-- end
	-- if elementsDB.Castbar.enabled or elementsDB.Health.enabled then
	-- 	powerOffset = powerOffset * -1
	-- end

	power:SetPoint('TOPLEFT', frame.Health or frame, 'TOPLEFT', 0, DB.offset or -1)
	power:SetPoint('TOPRIGHT', frame.Health or frame, 'TOPRIGHT', 0, DB.offset or -1)

	power.TextElements = {}
	for i, key in pairs(DB.text) do
		local NewString = power:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(NewString, key.size, 'UnitFrames')
		NewString:SetJustifyH(key.SetJustifyH)
		NewString:SetJustifyV(key.SetJustifyV)
		NewString:SetPoint(key.position.anchor, power, key.position.anchor, key.position.x, key.position.y)
		frame:Tag(NewString, key.text)

		power.TextElements[i] = NewString
		if not key.enabled then
			power.TextElements[i]:Hide()
		end
	end

	frame.Power = power
	frame.Power.colorPower = true
	frame.Power.frequentUpdates = true
end

---@param frame table
local function Update(frame)
	local DB = frame.Power.DB
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Power[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Power[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('Power')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Power
end

UF.Elements:Register('Power', Build, Update, Options)
