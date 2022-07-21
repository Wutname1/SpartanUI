local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local health = CreateFrame('StatusBar', nil, frame)
	health:SetFrameStrata(DB.FrameStrata or frame:GetFrameStrata())
	health:SetFrameLevel(DB.FrameLevel or 2)
	health:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	health:SetSize(DB.width or frame:GetWidth(), DB.height or 20)

	local Background = health:CreateTexture(nil, 'BACKGROUND')
	Background:SetAllPoints(health)
	Background:SetTexture(UF:FindStatusBarTexture(DB.texture))
	Background:SetVertexColor(1, 1, 1, .2)
	health.bg = Background

	health:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, DB.offset or -1)
	health:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, DB.offset or -1)

	health.TextElements = {}
	for i, key in pairs(DB.text) do
		local NewString = health:CreateFontString(nil, 'OVERLAY')
		SUI:FormatFont(NewString, key.size, 'UnitFrames')
		NewString:SetJustifyH(key.SetJustifyH)
		NewString:SetJustifyV(key.SetJustifyV)
		NewString:SetPoint(key.position.anchor, health, key.position.anchor, key.position.x, key.position.y)
		frame:Tag(NewString, key.text)

		health.TextElements[i] = NewString
		if not key.enabled then
			health.TextElements[i]:Hide()
		end
	end

	frame.Health = health

	frame.Health.frequentUpdates = true
	frame.Health.colorDisconnected = DB.colorDisconnected or true
	frame.Health.colorTapping = DB.colorTapping or true
	frame.Health.colorReaction = DB.colorReaction or true
	frame.Health.colorSmooth = DB.colorSmooth or true
	frame.Health.colorClass = DB.colorClass or false

	frame.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
	frame.Health.colorHealth = true

	frame.Health.DataTable = DB.text

	if SUI.IsRetail then
		-- Position and size
		local myBar = CreateFrame('StatusBar', nil, frame.Health)
		myBar:SetPoint('TOP')
		myBar:SetPoint('BOTTOM')
		myBar:SetPoint('LEFT', frame.Health:GetStatusBarTexture(), 'RIGHT')
		myBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		myBar:SetStatusBarColor(0, 1, 0.5, 0.45)
		myBar:SetSize(150, 16)
		myBar:Hide()

		local otherBar = CreateFrame('StatusBar', nil, myBar)
		otherBar:SetPoint('TOP')
		otherBar:SetPoint('BOTTOM')
		otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
		otherBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		otherBar:SetStatusBarColor(0, 0.5, 1, 0.35)
		otherBar:SetSize(150, 16)
		otherBar:Hide()

		local absorbBar = CreateFrame('StatusBar', nil, frame.Health)
		absorbBar:SetPoint('TOP')
		absorbBar:SetPoint('BOTTOM')
		absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
		absorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		absorbBar:SetWidth(10)
		absorbBar:Hide()

		local healAbsorbBar = CreateFrame('StatusBar', nil, frame.Health)
		healAbsorbBar:SetPoint('TOP')
		healAbsorbBar:SetPoint('BOTTOM')
		healAbsorbBar:SetPoint('RIGHT', frame.Health:GetStatusBarTexture())
		healAbsorbBar:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
		healAbsorbBar:SetReverseFill(true)
		healAbsorbBar:SetWidth(10)
		healAbsorbBar:Hide()

		local overAbsorb = frame.Health:CreateTexture(nil, 'OVERLAY')
		overAbsorb:SetPoint('TOP')
		overAbsorb:SetPoint('BOTTOM')
		overAbsorb:SetPoint('LEFT', frame.Health, 'RIGHT')
		overAbsorb:SetWidth(10)
		overAbsorb:Hide()

		local overHealAbsorb = frame.Health:CreateTexture(nil, 'OVERLAY')
		overHealAbsorb:SetPoint('TOP')
		overHealAbsorb:SetPoint('BOTTOM')
		overHealAbsorb:SetPoint('RIGHT', frame.Health, 'LEFT')
		overHealAbsorb:SetWidth(10)
		overHealAbsorb:Hide()

		frame.HealthPrediction = {
			myBar = myBar,
			otherBar = otherBar,
			absorbBar = absorbBar,
			healAbsorbBar = healAbsorbBar,
			overAbsorb = overAbsorb,
			overHealAbsorb = overHealAbsorb,
			maxOverflow = 2
		}
	end
end

---@param frame table
local function Update(frame)
	local DB = frame.Health.DB

	--Update Health items
	frame.Health.colorDisconnected = DB.colorDisconnected
	frame.Health.colorTapping = DB.colorTapping
	frame.Health.colorReaction = DB.colorReaction
	frame.Health.colorSmooth = DB.colorSmooth
	frame.Health.colorClass = DB.colorClass

	frame.Health:SetStatusBarTexture(UF:FindStatusBarTexture(DB.texture))
	frame.Health.bg:SetTexture(UF:FindStatusBarTexture(DB.texture))

	frame.Health:ClearAllPoints()
	frame.Health:SetSize(DB.width or frame:GetWidth(), DB.height or 20)
	frame.Health:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, DB.offset or 0)
	frame.Health:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, DB.offset or 0)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].DB[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].DB[option] = val
		--Update the screen
		UF.Frames[unitName]:ElementUpdate('Health')
	end
	--local DB = UF.CurrentSettings[unitName].DB
end

UF.Elements:Register('Health', Build, Update, Options)
