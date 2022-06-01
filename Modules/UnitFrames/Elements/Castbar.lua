local UF = SUI.UF
local Smoothv2 = 'Interface\\AddOns\\SpartanUI\\images\\textures\\Smoothv2'
local timers = {}

---@param frame table
---@param DB table
local function Build(frame, DB)
	local unitName = frame.PName or frame.unit or frame:GetName()

	local function Flash(self)
		if (self.Castbar.casting or self.Castbar.channeling) and self.Castbar.notInterruptible == false and self:IsVisible() then
			local _, g, b = self.Castbar:GetStatusBarColor()
			if b ~= 0 and g ~= 0 then
				self.Castbar:SetStatusBarColor(1, 0, 0)
			elseif b == 0 and g == 0 then
				self.Castbar:SetStatusBarColor(1, 1, 0)
			else
				self.Castbar:SetStatusBarColor(1, 1, 1)
			end
			timers[unitName] = UF:ScheduleTimer(Flash, .1, self)
		end
	end
	local function PostCastStart(self, unit)
		if self.notInterruptible == false and DB.FlashOnInterruptible and UnitIsEnemy('player', unit) then
			self:SetStatusBarColor(0, 0, 0)
			timers[unitName] = UF:ScheduleTimer(Flash, DB.InterruptSpeed, self.__owner)
		else
			self:SetStatusBarColor(1, 0.7, 0)
		end
	end
	local function PostCastStop(self)
		if timers[unitName] then
			UF:CancelTimer(timers[unitName])
		end
	end

	local cast = CreateFrame('StatusBar', nil, frame)
	cast:SetFrameStrata(DB.FrameStrata or frame:GetFrameStrata())
	cast:SetFrameLevel(DB.FrameLevel or 2)
	cast:SetStatusBarTexture(Smoothv2)
	cast:SetSize(DB.width or frame:GetWidth(), DB.height or 20)
	cast:Hide()

	cast:SetPoint('TOP', frame, 'TOP', 0, DB.offset or 0)

	local bg = cast:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(cast)
	bg:SetTexture(Smoothv2)
	bg:SetVertexColor(1, 1, 1, .2)
	cast.bg = bg

	-- Add spell text
	local Text = cast:CreateFontString()
	SUI:FormatFont(Text, DB.text['1'].size, 'UnitFrames')
	Text:SetPoint(
		DB.text['1'].position.anchor,
		cast,
		DB.text['1'].position.anchor,
		DB.text['1'].position.x,
		DB.text['1'].position.y
	)
	cast.Text = Text

	-- Add a timer
	local Time = cast:CreateFontString(nil, 'OVERLAY')
	SUI:FormatFont(Time, DB.text['2'].size, 'UnitFrames')
	Time:SetPoint(
		DB.text['2'].position.anchor,
		cast,
		DB.text['2'].position.anchor,
		DB.text['2'].position.x,
		DB.text['2'].position.y
	)
	cast.Time = Time

	-- Add Shield
	local Shield = cast:CreateTexture(nil, 'OVERLAY')
	Shield:SetSize(20, 20)
	Shield:SetPoint('CENTER', cast, 'RIGHT')
	Shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Small-Shield]])
	Shield:Hide()
	cast.Shield = Shield

	-- Add spell icon
	local Icon = cast:CreateTexture(nil, 'OVERLAY')
	Icon:SetSize(DB.Icon.size, DB.Icon.size)
	Icon:SetPoint(DB.Icon.position.anchor, cast, DB.Icon.position.anchor, DB.Icon.position.x, DB.Icon.position.y)
	cast.Icon = Icon

	-- Add safezone
	local SafeZone = cast:CreateTexture(nil, 'OVERLAY')
	cast.SafeZone = SafeZone

	-- --Interupt Flash
	cast.PostCastStart = PostCastStart
	cast.PostCastInterruptible = PostCastStart
	cast.PostCastStop = PostCastStop
	cast.TextElements = {
		['1'] = cast.Text,
		['2'] = cast.Time
	}

	frame.Castbar = cast

	if frame.unitOnCreate == 'player' then
		CastingBarFrame_SetUnit(_G['CastingBarFrame'])
		CastingBarFrame_SetUnit(_G['PetCastingBarFrame'])
	end
end

---@param frame table
local function Update(frame)
	local DB = frame.Castbar.DB

	if SUI.IsRetail then
		-- latency
		if DB.latency then
			frame.Castbar.Shield:Show()
		else
			frame.Castbar.Shield:Hide()
		end

		-- spell name
		if DB.text['1'].enabled then
			frame.Castbar.Text:Show()
		else
			frame.Castbar.Text:Hide()
		end
		-- spell timer
		if DB.text['2'].enabled then
			frame.Castbar.Time:Show()
		else
			frame.Castbar.Time:Hide()
		end
	end

	-- Spell icon
	if DB.Icon.enabled then
		frame.Castbar.Icon:Show()
	else
		frame.Castbar.Icon:Hide()
	end
	frame.Castbar.Icon:ClearAllPoints()
	frame.Castbar.Icon:SetPoint(
		DB.Icon.position.anchor,
		frame.Castbar,
		DB.Icon.position.anchor,
		DB.Icon.position.x,
		DB.Icon.position.y
	)

	frame.Castbar:SetSize(DB.width or frame:GetWidth(), DB.height or 20)
	frame.Castbar.Icon:SetSize(DB.Icon.size, DB.Icon.size)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
end

UF.Elements:Register('Castbar', Build, Update, Options)
