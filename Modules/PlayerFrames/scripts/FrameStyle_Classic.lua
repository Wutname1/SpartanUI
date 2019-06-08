local _G, SUI = _G, SUI
local PlayerFrames = SUI.PlayerFrames
----------------------------------------------------------------------------------------------------

local base_plate1 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\classic\\base_plate1.tga' -- Player and Target
local base_plate2 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\classic\\base_plate2.blp' -- Focus and Focus Target
local base_plate3 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\classic\\base_plate3.tga' -- Pet, TargetTarget (Large, Medium)
local base_plate4 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\classic\\base_plate4.blp' -- TargetTarget small
local base_ring1 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\base_ring1' -- Player and Target
local base_ring3 = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\base_ring3' -- Pet and TargetTarget
local circle = 'Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\circle.tga'

local colors = setmetatable({}, {__index = SUIUF.colors})
local _, classFileName = UnitClass('player')

for k, v in pairs(SUIUF.colors) do
	if not colors[k] then
		colors[k] = v
	end
end
do -- setup custom colors that we want to use
	colors.health = {0, 1, 50 / 255} -- the color of health bars
	colors.reaction[1] = {1, 50 / 255, 0} -- Hated
	colors.reaction[2] = colors.reaction[1] -- Hostile
	colors.reaction[3] = {1, 150 / 255, 0} -- Unfriendly
	colors.reaction[4] = {1, 220 / 255, 0} -- Neutral
	colors.reaction[5] = colors.health -- Friendly
	colors.reaction[6] = colors.health -- Honored
	colors.reaction[7] = colors.health -- Revered
	colors.reaction[8] = colors.health -- Exalted
end

local threat = function(self, event, unit)
	if (not self.Portrait) then -- no Portrait color artwork if possible
		-- if (not self.artwork.bg:IsObjectType("Texture")) then return; end
		-- unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		-- local status
		-- if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		-- if (status and status > 0) then
		-- local r,g,b = GetThreatStatusColor(status);
		-- self.artwork.bg:SetVertexColor(r,g,b);
		-- else
		-- self.artwork.bg:SetVertexColor(1,1,1);
		-- end
		if (not self.artwork) then
			return
		end
	else -- Portrait exsits color picture for threat
		if (not self.Portrait:IsObjectType('Texture')) then
			return
		end
		unit = string.gsub(self.unit, '(.)', string.upper, 1) or string.gsub(unit, '(.)', string.upper, 1)
		local status
		if UnitExists(unit) then
			status = UnitThreatSituation(unit)
		else
			status = 0
		end
		if (status and status > 0) then
			local r, g, b = GetThreatStatusColor(status)
			self.Portrait:SetVertexColor(r, g, b)
		else
			self.Portrait:SetVertexColor(1, 1, 1)
		end
	end
	-- if ((self.TimeSinceLastUpdate < .5) or ((self.TimeSinceLastUpdate > 1) and (self.TimeSinceLastUpdate < 1.5))) then
	-- SpartanUI_Tribal:SetAlpha((SpartanUI_Tribal:GetAlpha()-.1));
	-- else
	-- SpartanUI_Tribal:SetAlpha((SpartanUI_Tribal:GetAlpha()+.1));
	-- end
end

local function CreatePortrait(self)
	if SUI.DBMod.PlayerFrames.Portrait3D then
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript(
			'OnShow',
			function(self)
				self:SetCamera(1)
			end
		)
		Portrait.type = '3D'
		if SUI.DBMod.PlayerFrames.Portrait3D then
			Portrait.bg2 = Portrait:CreateTexture(nil, 'BACKGROUND')
			Portrait.bg2:SetTexture(circle)
			Portrait.bg2:SetPoint('TOPLEFT', Portrait, 'TOPLEFT', -10, 10)
			Portrait.bg2:SetPoint('BOTTOMRIGHT', Portrait, 'BOTTOMRIGHT', 10, -10)
		end
		Portrait:SetFrameLevel(1)
		return Portrait
	else
		return self:CreateTexture(nil, 'BORDER')
	end
end

--	Updating functions
local PostUpdateText = function(self, unit)
	self:Untag(self.Health.value)
	if self.Power then
		self:Untag(self.Power.value)
	end
	self:Tag(self.Health.value, PlayerFrames:TextFormat('health'))
	if self.Power then
		self:Tag(self.Power.value, PlayerFrames:TextFormat('mana'))
	end
end

local PostUpdateAura = function(self, unit, mode)
	-- Buffs
	if mode == 'Buffs' then
		if SUI.DB.Styles.Classic.Frames[unit].Buffs.Display then
			self.size = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			self.spacing = SUI.DB.Styles.Classic.Frames[unit].Buffs.spacing
			self.showType = SUI.DB.Styles.Classic.Frames[unit].Buffs.showType
			self.numBuffs = SUI.DB.Styles.Classic.Frames[unit].Buffs.Number
			self.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Buffs.onlyShowPlayer
			self:Show()
		else
			self:Hide()
		end
	end

	-- Debuffs
	if mode == 'Debuffs' then
		if SUI.DB.Styles.Classic.Frames[unit].Debuffs.Display then
			self.size = SUI.DB.Styles.Classic.Frames[unit].Debuffs.size
			self.spacing = SUI.DB.Styles.Classic.Frames[unit].Debuffs.spacing
			self.showType = SUI.DB.Styles.Classic.Frames[unit].Debuffs.showType
			self.numDebuffs = SUI.DB.Styles.Classic.Frames[unit].Debuffs.Number
			self.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Debuffs.onlyShowPlayer
			self:Show()
		else
			self:Hide()
		end
	end
end

local PostUpdateColor = function(self, unit)
	self.Health.frequentUpdates = true
	self.Health.colorDisconnected = true
	if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
		self.Health.colorReaction = true
		self.Health.colorClass = false
	elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
		self.Health.colorHappiness = true
		self.Health.colorReaction = false
		self.Health.colorClass = false
	elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
		self.Health.colorClass = true
		self.Health.colorReaction = false
	else
		self.Health.colorClass = false
		self.Health.colorReaction = false
		self.Health.colorSmooth = true
	end
	self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
	self.Health.colorHealth = true
end

local PostCastStop = function(self)
	if self.Time then
		self.Time:SetTextColor(1, 1, 1)
	end
end

local PostCastStart = function(self, unit, name, rank, text, castid)
	self:SetStatusBarColor(1, 0.7, 0)
end

local PostChannelStart = function(self, unit, name, rank, text, castid)
	self:SetStatusBarColor(1, 0.2, 0.7)
end

local OnCastbarUpdate = function(self, elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil
			self:Hide()
			if PostCastStop then
				PostCastStop(self:GetParent())
			end
			if PostCastStop then
				PostCastStop(self)
			end
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetTextColor(1, 0, 0)
			else
				self.Time:SetTextColor(1, 1, 1)
			end
			if SUI.DBMod.PlayerFrames.Castbar.text[self:GetParent().unit] == 1 then
				self.Time:SetFormattedText('%.1f', self.max - self.duration)
			else
				self.Time:SetFormattedText('%.1f', self.duration)
			end
		end
		if SUI.DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.max - self.duration)
		else
			self:SetValue(self.duration)
		end
	elseif self.channeling then
		self.duration = self.duration - elapsed
		if (self.duration <= 0) then
			self.channeling = nil
			self:Hide()
			if PostChannelStop then
				PostChannelStop(self:GetParent())
			end
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetTextColor(1, 0, 0)
			else
				self.Time:SetTextColor(1, 1, 1)
			end
			self.Time:SetFormattedText('%.1f', self.max - self.duration)
		end
		if SUI.DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.duration)
		else
			self:SetValue(self.max - self.duration)
		end
	else
		self.unitName = nil
		self.channeling = nil
		self:SetValue(1)
		self:Hide()
	end
end

-- Create Frames
local CreatePlayerFrame = function(self, unit)
	self:SetSize(280, 80)
	do -- setup base artwork
		local artwork = CreateFrame('Frame', nil, self)
		artwork:SetFrameStrata('BACKGROUND')
		artwork:SetFrameLevel(2)
		artwork:SetAllPoints(self)

		artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
		artwork.bg:SetPoint('CENTER')
		artwork.bg:SetTexture(base_plate1)
		self.artwork = artwork

		self.Portrait = CreatePortrait(self)
		self.Portrait:SetSize(62)
		self.Portrait:SetPoint('CENTER', self, 'CENTER', 80, 3)

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(2)
			cast:SetSize(153, 16)
			cast:SetPoint('TOPLEFT', self, 'TOPLEFT', 36, -23)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 10, 'Player')
			cast.Text:SetSize(135, 11)
			cast.Text:SetJustifyH('RIGHT')
			cast.Text:SetJustifyV('MIDDLE')
			cast.Text:SetPoint('LEFT', cast, 'LEFT', 4, 0)

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			cast.Time:SetSize(90, 11)
			cast.Time:SetJustifyH('RIGHT')
			cast.Time:SetJustifyV('MIDDLE')
			cast.Time:SetPoint('RIGHT', cast, 'LEFT', -2, 0)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			health:SetSize(150, 16)
			health:SetPoint('TOPLEFT', self.Castbar, 'BOTTOMLEFT', 0, -2)

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(135, 11)
			health.value:SetJustifyH('RIGHT')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetPoint('LEFT', health, 'LEFT', 4, 0)
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.ratio:SetSize(90, 11)
			health.ratio:SetJustifyH('RIGHT')
			health.ratio:SetJustifyV('MIDDLE')
			health.ratio:SetPoint('RIGHT', health, 'LEFT', -2, 0)
			self:Tag(health.ratio, '[perhp]%')

			self.Health = health

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
				self.Health.colorReaction = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
				self.Health.colorHappiness = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
				self.Health.colorClass = true
			else
				self.Health.colorSmooth = true
			end
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true
			self.Health.Smooth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 3
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetWidth(155)
			power:SetHeight(14)
			power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -2)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetWidth(135)
			power.value:SetHeight(11)
			power.value:SetJustifyH('RIGHT')
			power.value:SetJustifyV('MIDDLE')
			power.value:SetPoint('LEFT', power, 'LEFT', 4, 0)
			self:Tag(power.value, PlayerFrames:TextFormat('mana'))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.ratio:SetWidth(90)
			power.ratio:SetHeight(11)
			power.ratio:SetJustifyH('RIGHT')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetPoint('RIGHT', power, 'LEFT', -2, 0)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame('Frame', nil, self)
		ring:SetFrameStrata('BACKGROUND')
		ring:SetAllPoints(self.Portrait)
		ring:SetFrameLevel(4)
		ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
		ring.bg:SetPoint('CENTER', ring, 'CENTER', -80, -3)
		ring.bg:SetTexture(base_ring1)

		self.Name = ring:CreateFontString()
		SUI:FormatFont(self.Name, 12, 'Player')
		self.Name:SetSize(170, 12)
		self.Name:SetJustifyH('RIGHT')
		self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 5, -6)
		if SUI.DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, '[SUI_ColorClass][name]')
		else
			self:Tag(self.Name, '[name]')
		end

		self.Level = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline10')
		self.Level:SetSize(40, 11)
		self.Level:SetJustifyH('CENTER')
		self.Level:SetJustifyV('MIDDLE')
		self.Level:SetPoint('CENTER', ring, 'CENTER', 53, 12)
		self:Tag(self.Level, '[level]')

		self.SUI_ClassIcon = ring:CreateTexture(nil, 'BORDER')
		self.SUI_ClassIcon:SetSize(19, 19)
		self.SUI_ClassIcon:SetPoint('CENTER', ring, 'CENTER', -29, 21)

		self.LeaderIndicator = ring:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator:SetSize(20, 20)
		self.LeaderIndicator:SetPoint('CENTER', ring, 'TOP')

		self.SUI_RaidGroup = ring:CreateTexture(nil, 'BORDER')
		self.SUI_RaidGroup:SetSize(32, 32)
		self.SUI_RaidGroup:SetPoint('CENTER', ring, 'TOPRIGHT', -6, -6)
		self.SUI_RaidGroup:SetTexture(circle)

		self.SUI_RaidGroup.Text = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline11')
		self.SUI_RaidGroup.Text:SetSize(40, 11)
		self.SUI_RaidGroup.Text:SetJustifyH('CENTER')
		self.Level:SetJustifyV('MIDDLE')
		self.SUI_RaidGroup.Text:SetPoint('CENTER', self.SUI_RaidGroup, 'CENTER', 0, 0)
		self:Tag(self.SUI_RaidGroup.Text, '[group]')

		self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetSize(48, 48)
		self.PvPIndicator:SetPoint('CENTER', ring, 'CENTER', 32, -40)

		self.GroupRoleIndicator = ring:CreateTexture(nil, 'BORDER')
		self.GroupRoleIndicator:SetSize(28, 28)
		self.GroupRoleIndicator:SetPoint('CENTER', ring, 'CENTER', -20, -35)
		self.GroupRoleIndicator:SetTexture('Interface\\AddOns\\SpartanUI_PlayerFrames\\media\\icon_role')

		self.RestingIndicator = ring:CreateTexture(nil, 'ARTWORK')
		self.RestingIndicator:SetSize(32, 30)
		self.RestingIndicator:SetPoint('CENTER', self.SUI_ClassIcon, 'CENTER')

		self.CombatIndicator = ring:CreateTexture(nil, 'ARTWORK')
		self.CombatIndicator:SetSize(32, 32)
		self.CombatIndicator:SetPoint('CENTER', self.Level, 'CENTER')

		self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetSize(24, 24)
		self.RaidTargetIndicator:SetPoint('CENTER', ring, 'LEFT', -2, -3)

		self.StatusText = ring:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		self.StatusText:SetPoint('CENTER', ring, 'CENTER')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')

		self.ComboPoints = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline13')
		self.ComboPoints:SetPoint('BOTTOMLEFT', self.Name, 'TOPLEFT', 12, -2)
		if unit == 'player' then
			local ClassPower = {}
			for index = 1, 10 do
				local Bar = CreateFrame('StatusBar', nil, self)
				Bar:SetStatusBarTexture(Smoothv2)

				-- Position and size.
				Bar:SetSize(16, 5)
				if (index == 1) then
					Bar:SetPoint('LEFT', self.ComboPoints, 'RIGHT', (index - 1) * Bar:GetWidth(), -1)
				else
					Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 3, 0)
				end
				-- Bar:SetPoint('LEFT', self, 'RIGHT', , 0)

				ClassPower[index] = Bar
			end

			-- Register with SUF
			self.ClassPower = ClassPower
		end
	end
	do -- setup buffs and debuffs
		if SUI.DB.Styles.Classic.Frames[unit] and PlayerFrames then
			self.BuffAnchor = CreateFrame('Frame', nil, self)
			self.BuffAnchor:SetSize(self:GetWidth() - 10, 1)
			self.BuffAnchor:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 10, 0)
			self.BuffAnchor:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 0)

			self = PlayerFrames:Buffs(self, unit)
		end
	end
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreateTargetFrame = function(self, unit)
	self:SetSize(295, 80)
	do --setup base artwork
		local artwork = CreateFrame('Frame', nil, self)
		artwork:SetFrameStrata('BACKGROUND')
		artwork:SetFrameLevel(3)
		artwork:SetAllPoints(self)

		artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
		artwork.bg:SetAllPoints(self)
		-- artwork.bg:SetPoint("CENTER",self,"CENTER",0,0);
		artwork.bg:SetTexture(base_plate1)
		artwork.bg:SetTexCoord(0.80859375, 0.2, 0.1953125, 0.8046875)
		self.artwork = artwork

		self.Portrait = CreatePortrait(self)
		self.Portrait:SetSize(64, 64)
		self.Portrait:SetPoint('CENTER', self, 'CENTER', -70, 3)

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(3)
			cast:SetSize(143, 16)
			cast:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -46, -23)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 10, 'Player')
			cast.Text:SetSize(125, 11)
			cast.Text:SetJustifyH('LEFT')
			cast.Text:SetJustifyV('MIDDLE')
			cast.Text:SetPoint('RIGHT', cast, 'RIGHT', -4, 0)

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			cast.Time:SetSize(90, 11)
			cast.Time:SetJustifyH('LEFT')
			cast.Time:SetJustifyV('MIDDLE')
			cast.Time:SetPoint('LEFT', cast, 'RIGHT', 2, 0)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(3)
			health:SetSize(140, 16)
			health:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -2)
			health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(125, 11)
			health.value:SetJustifyH('LEFT')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetPoint('RIGHT', health, 'RIGHT', -4, 0)
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.ratio:SetSize(90, 11)
			health.ratio:SetJustifyH('LEFT')
			health.ratio:SetJustifyV('MIDDLE')
			health.ratio:SetPoint('LEFT', health, 'RIGHT', 2, 0)
			self:Tag(health.ratio, '[perhp]%')

			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)

			self.Health = health
			--self.Health.bg = Background;
			self.Health.colorTapping = true
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
				self.Health.colorReaction = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
				self.Health.colorHappiness = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
				self.Health.colorClass = true
			else
				self.Health.colorSmooth = true
			end

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(3)
			power:SetSize(145, 14)
			power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -2)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetSize(125, 11)
			power.value:SetJustifyH('LEFT')
			power.value:SetJustifyV('MIDDLE')
			power.value:SetPoint('RIGHT', power, 'RIGHT', -4, 0)
			self:Tag(power.value, PlayerFrames:TextFormat('mana'))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.ratio:SetSize(90, 11)
			power.ratio:SetJustifyH('LEFT')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetPoint('LEFT', power, 'RIGHT', 2, 0)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame('Frame', nil, self)
		ring:SetFrameStrata('BACKGROUND')
		ring:SetAllPoints(self.Portrait)
		ring:SetFrameLevel(4)
		ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
		ring.bg:SetPoint('CENTER', ring, 'CENTER', 80, -3)
		ring.bg:SetTexture(base_ring1)
		ring.bg:SetTexCoord(1, 0, 0, 1)

		self.Name = ring:CreateFontString()
		SUI:FormatFont(self.Name, 12, 'Player')
		self.Name:SetWidth(170)
		self.Name:SetHeight(12)
		self.Name:SetJustifyH('LEFT')
		self.Name:SetJustifyV('MIDDLE')
		self.Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -5, -6)
		if SUI.DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, '[SUI_ColorClass][name]')
		else
			self:Tag(self.Name, '[name]')
		end

		self.Level = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline10')
		self.Level:SetWidth(40)
		self.Level:SetHeight(11)
		self.Level:SetJustifyH('CENTER')
		self.Level:SetJustifyV('MIDDLE')
		self.Level:SetPoint('CENTER', ring, 'CENTER', -49, 12)
		self:Tag(self.Level, '[difficulty][level]')

		self.SUI_ClassIcon = ring:CreateTexture(nil, 'BORDER')
		self.SUI_ClassIcon:SetSize(19, 19)
		self.SUI_ClassIcon:SetPoint('CENTER', ring, 'CENTER', 29, 21)

		self.LeaderIndicator = ring:CreateTexture(nil, 'BORDER')
		self.LeaderIndicator:SetWidth(20)
		self.LeaderIndicator:SetHeight(20)
		self.LeaderIndicator:SetPoint('CENTER', ring, 'TOP')

		self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
		self.PvPIndicator:SetWidth(48)
		self.PvPIndicator:SetHeight(48)
		self.PvPIndicator:SetPoint('CENTER', ring, 'CENTER', -16, -40)

		self.LevelSkull = ring:CreateTexture(nil, 'ARTWORK')
		self.LevelSkull:SetWidth(16)
		self.LevelSkull:SetHeight(16)
		self.LevelSkull:SetPoint('CENTER', self.Level, 'CENTER')

		self.RareElite = ring:CreateTexture(nil, 'ARTWORK')
		self.RareElite:SetWidth(150)
		self.RareElite:SetHeight(150)
		self.RareElite:SetPoint('CENTER', ring, 'CENTER', -12, -4)

		self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetWidth(24)
		self.RaidTargetIndicator:SetHeight(24)
		self.RaidTargetIndicator:SetPoint('CENTER', ring, 'RIGHT', 2, -4)

		self.StatusText = ring:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline22')
		self.StatusText:SetPoint('CENTER', ring, 'CENTER')
		self.StatusText:SetJustifyH('CENTER')
		self:Tag(self.StatusText, '[afkdnd]')
	end
	do -- setup buffs and debuffs
		if SUI.DB.Styles.Classic.Frames[unit] and PlayerFrames then
			self.BuffAnchor = CreateFrame('Frame', nil, self)
			self.BuffAnchor:SetSize(self:GetWidth() - 35, 1)
			self.BuffAnchor:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 30, 0)
			self.BuffAnchor:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -5, 0)

			self = PlayerFrames:Buffs(self, unit)
		end
	end
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor
	return self
end

local CreatePetFrame = function(self, unit)
	self:SetSize(210, 60)
	do -- setup base artwork
		local artwork = CreateFrame('Frame', nil, self)
		artwork:SetFrameStrata('BACKGROUND')
		artwork:SetFrameLevel(0)
		artwork:SetAllPoints(self)

		artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
		artwork.bg:SetPoint('LEFT', self, 'LEFT', -23, 0)
		artwork.bg:SetTexture(base_plate3)
		artwork.bg:SetSize(256, 85)
		artwork.bg:SetTexCoord(0, 1, 0, 85 / 128)
		self.artwork = artwork

		if SUI.DBMod.PlayerFrames.PetPortrait then
			self.Portrait = CreatePortrait(self)
			self.Portrait:SetSize(56, 50)
			self.Portrait:SetPoint('CENTER', self, 'CENTER', 87, -8)
		end

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(2)
			cast:SetParent(self)
			cast:SetSize(120, 15)
			cast:SetPoint('TOPLEFT', self, 'TOPLEFT', 36, -23)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 10, 'Player')
			cast.Text:SetHeight(11)
			cast.Text:SetPoint('LEFT', cast, 'LEFT', 0, 0)
			cast.Text:SetPoint('RIGHT', cast, 'RIGHT', -10, 0)
			cast.Text:SetJustifyH('RIGHT')
			cast.Text:SetJustifyV('MIDDLE')
			cast.Text:SetPoint('LEFT', cast, 'LEFT', 4, 0)

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			cast.Time:SetWidth(40)
			cast.Time:SetHeight(11)
			cast.Time:SetJustifyH('RIGHT')
			cast.Time:SetJustifyV('MIDDLE')
			cast.Time:SetPoint('RIGHT', cast, 'LEFT', -2, 0)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetSize(120, 16)
			health:SetPoint('TOPLEFT', self.Castbar, 'BOTTOMLEFT', 0, -2)
			health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetHeight(11)
			health.value:SetPoint('LEFT', health, 'LEFT', 0, 0)
			health.value:SetPoint('RIGHT', health, 'RIGHT', -8, 0)
			health.value:SetJustifyH('RIGHT')
			health.value:SetJustifyV('MIDDLE')
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.ratio:SetWidth(40)
			health.ratio:SetHeight(11)
			health.ratio:SetJustifyH('RIGHT')
			health.ratio:SetJustifyV('MIDDLE')
			health.ratio:SetPoint('RIGHT', health, 'LEFT', -2, 0)
			self:Tag(health.ratio, '[perhp]%')

			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)

			self.Health = health
			--self.Health.bg = Background;

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
				self.Health.colorReaction = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
				self.Health.colorHappiness = true
			elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
				self.Health.colorClass = true
			else
				self.Health.colorSmooth = true
			end
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetWidth(135)
			power:SetHeight(14)
			power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetHeight(11)
			power.value:SetPoint('LEFT', power, 'LEFT', 0, 0)
			power.value:SetPoint('RIGHT', power, 'RIGHT', -17, 0)
			power.value:SetJustifyH('RIGHT')
			power.value:SetJustifyV('MIDDLE')
			power.value:SetPoint('LEFT', power, 'LEFT', 4, 0)
			self:Tag(power.value, PlayerFrames:TextFormat('mana'))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.ratio:SetWidth(40)
			power.ratio:SetHeight(11)
			power.ratio:SetJustifyH('RIGHT')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetPoint('RIGHT', power, 'LEFT', -2, 0)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		if SUI.DBMod.PlayerFrames.PetPortrait then
			local ring = CreateFrame('Frame', nil, self)
			ring:SetParent(self)
			ring:SetFrameStrata('BACKGROUND')
			ring:SetAllPoints(self.Portrait)
			ring:SetFrameLevel(3)
			ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
			ring.bg:SetPoint('CENTER', ring, 'CENTER', -2, -3)
			ring.bg:SetTexture(base_ring3)
			ring.bg:SetTexCoord(1, 0, 0, 1)

			self.Name = ring:CreateFontString()
			SUI:FormatFont(self.Name, 12, 'Player')
			self.Name:SetHeight(12)
			self.Name:SetWidth(150)
			self.Name:SetJustifyH('RIGHT')
			self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 3, -5)
			if SUI.DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, '[SUI_ColorClass][name]')
			else
				self:Tag(self.Name, '[name]')
			end

			self.Level = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline10')
			self.Level:SetWidth(36)
			self.Level:SetHeight(11)
			self.Level:SetJustifyH('CENTER')
			self.Level:SetJustifyV('MIDDLE')
			self.Level:SetPoint('CENTER', ring, 'CENTER', 24, 25)
			self:Tag(self.Level, '[level]')

			self.SUI_ClassIcon = ring:CreateTexture(nil, 'BORDER')
			self.SUI_ClassIcon:SetSize(19, 19)
			self.SUI_ClassIcon:SetPoint('CENTER', ring, 'CENTER', -27, 24)

			self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
			self.PvPIndicator:SetWidth(48)
			self.PvPIndicator:SetHeight(48)
			self.PvPIndicator:SetPoint('CENTER', ring, 'CENTER', 30, -36)

			self.Happiness = ring:CreateTexture(nil, 'ARTWORK')
			self.Happiness:SetWidth(22)
			self.Happiness:SetHeight(22)
			self.Happiness:SetPoint('CENTER', ring, 'CENTER', -27, 24)

			self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
			self.RaidTargetIndicator:SetWidth(20)
			self.RaidTargetIndicator:SetHeight(20)
			self.RaidTargetIndicator:SetAllPoints(self.Portrait)
		else
			self.Name = self.artwork:CreateFontString()
			SUI:FormatFont(self.Name, 12, 'Player')
			self.Name:SetHeight(12)
			self.Name:SetJustifyH('RIGHT')
			self.Name:SetPoint('BOTTOMLEFT', self.Castbar, 'TOPLEFT', 0, 5)
			self.Name:SetPoint('BOTTOMRIGHT', self.Castbar, 'TOPRIGHT', 0, 5)
			if SUI.DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, '[level] [SUI_ColorClass][name]')
			else
				self:Tag(self.Name, '[level] [name]')
			end
		end
	end
	do -- setup buffs and debuffs
		if SUI.DB.Styles.Classic.Frames[unit] then
			local Buffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			local Debuffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			-- Position and size
			local Buffs = CreateFrame('Frame', nil, self)
			Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 5)
			Buffs.size = Buffsize
			Buffs['growth-y'] = 'UP'
			Buffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Buffs.spacing
			Buffs.showType = SUI.DB.Styles.Classic.Frames[unit].Buffs.showType
			Buffs.numBuffs = SUI.DB.Styles.Classic.Frames[unit].Buffs.Number
			Buffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Buffs.onlyShowPlayer
			Buffs:SetSize(Buffsize * 4, Buffsize * Buffsize)
			Buffs.PostUpdate = PostUpdateAura
			self.Buffs = Buffs

			-- Position and size
			local Debuffs = CreateFrame('Frame', nil, self)
			Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -5, 5)
			Debuffs.size = Debuffsize
			Debuffs.initialAnchor = 'BOTTOMRIGHT'
			Debuffs['growth-x'] = 'LEFT'
			Debuffs['growth-y'] = 'UP'
			Debuffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Debuffs.spacing
			Debuffs.showType = SUI.DB.Styles.Classic.Frames[unit].Debuffs.showType
			Debuffs.numDebuffs = SUI.DB.Styles.Classic.Frames[unit].Debuffs.Number
			Debuffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Debuffs.onlyShowPlayer
			Debuffs:SetSize(Debuffsize * 4, Debuffsize * Debuffsize)
			Debuffs.PostUpdate = PostUpdateAura
			self.Debuffs = Debuffs

			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].disabled = false
		end
	end
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor
	if not SUI.DBMod.PlayerFrames.PetPortrait then
		self.artwork.bg:SetTexCoord(0, .7, 0, 85 / 128)
		self.artwork.bg:SetSize(180, 85)
		self:SetSize(135, 60)
		self.Castbar:SetWidth(100)
		self.Health:SetWidth(99)
		self.Power:SetWidth(98)
	end
	self:SetScale(.87)
	return self
end

local CreateToTFrame = function(self, unit)
	if SUI.DBMod.PlayerFrames.targettarget.style == 'large' then
		do -- large
			self:SetWidth(210)
			self:SetHeight(60)
			do -- setup base artwork
				local artwork = CreateFrame('Frame', nil, self)
				artwork:SetFrameStrata('BACKGROUND')
				artwork:SetFrameLevel(0)
				artwork:SetAllPoints(self)

				artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
				artwork.bg:SetPoint('CENTER')
				artwork.bg:SetTexture(base_plate3)
				artwork.bg:SetSize(256, 85)
				artwork.bg:SetTexCoord(1, 0, 0, 85 / 128)
				self.artwork = artwork

				self.Portrait = CreatePortrait(self)
				self.Portrait:SetWidth(56)
				self.Portrait:SetHeight(50)
				self.Portrait:SetPoint('CENTER', self, 'CENTER', -83, -8)

				self.ThreatIndicator = CreateFrame('Frame', nil, self)
				self.ThreatIndicator.Override = threat
			end
			do -- setup status bars
				do -- cast bar
					local cast = CreateFrame('StatusBar', nil, self)
					cast:SetFrameStrata('BACKGROUND')
					cast:SetFrameLevel(2)
					cast:SetWidth(120)
					cast:SetHeight(15)
					cast:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -36, -23)

					cast.Text = cast:CreateFontString()
					SUI:FormatFont(cast.Text, 10, 'Player')
					cast.Text:SetWidth(110)
					cast.Text:SetHeight(11)
					cast.Text:SetJustifyH('LEFT')
					cast.Text:SetJustifyV('MIDDLE')
					cast.Text:SetPoint('RIGHT', cast, 'RIGHT', -4, 0)

					cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					cast.Time:SetWidth(40)
					cast.Time:SetHeight(11)
					cast.Time:SetJustifyH('LEFT')
					cast.Time:SetJustifyV('MIDDLE')
					cast.Time:SetPoint('LEFT', cast, 'RIGHT', 4, 0)

					self.Castbar = cast
					self.Castbar.OnUpdate = OnCastbarUpdate
					self.Castbar.PostCastStart = PostCastStart
					self.Castbar.PostChannelStart = PostChannelStart
					self.Castbar.PostCastStop = PostCastStop
				end
				do -- health bar
					local health = CreateFrame('StatusBar', nil, self)
					health:SetFrameStrata('BACKGROUND')
					health:SetFrameLevel(2)
					health:SetWidth(120)
					health:SetHeight(16)
					health:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -2)
					health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

					health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.value:SetWidth(110)
					health.value:SetHeight(11)
					health.value:SetJustifyH('LEFT')
					health.value:SetJustifyV('MIDDLE')
					health.value:SetPoint('RIGHT', health, 'RIGHT', -4, 0)

					self:Tag(health.value, PlayerFrames:TextFormat('health'))

					health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.ratio:SetWidth(40)
					health.ratio:SetHeight(11)
					health.ratio:SetJustifyH('LEFT')
					health.ratio:SetJustifyV('MIDDLE')
					health.ratio:SetPoint('LEFT', health, 'RIGHT', 4, 0)
					self:Tag(health.ratio, '[perhp]%')

					-- local Background = health:CreateTexture(nil, 'BACKGROUND')
					-- Background:SetAllPoints(health)
					-- Background:SetTexture(1, 1, 1, .08)

					self.Health = health
					--self.Health.bg = Background;

					self.Health.frequentUpdates = true
					self.Health.colorDisconnected = true
					if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
						self.Health.colorReaction = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
						self.Health.colorHappiness = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
						self.Health.colorClass = true
					else
						self.Health.colorSmooth = true
					end
					self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
					self.Health.colorHealth = true

					-- Position and size
					local myBars = CreateFrame('StatusBar', nil, self.Health)
					myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

					local otherBars = CreateFrame('StatusBar', nil, myBars)
					otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

					myBars:SetSize(150, 16)
					otherBars:SetSize(150, 16)

					self.HealthPrediction = {
						myBar = myBars,
						otherBar = otherBars,
						maxOverflow = 4
					}
				end
				do -- power bar
					local power = CreateFrame('StatusBar', nil, self)
					power:SetFrameStrata('BACKGROUND')
					power:SetFrameLevel(2)
					power:SetWidth(135)
					power:SetHeight(14)
					power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)

					power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					power.value:SetWidth(110)
					power.value:SetHeight(11)
					power.value:SetJustifyH('LEFT')
					power.value:SetJustifyV('MIDDLE')
					power.value:SetPoint('RIGHT', power, 'RIGHT', -4, 0)
					self:Tag(power.value, PlayerFrames:TextFormat('mana'))

					power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					power.ratio:SetWidth(40)
					power.ratio:SetHeight(11)
					power.ratio:SetJustifyH('LEFT')
					power.ratio:SetJustifyV('MIDDLE')
					power.ratio:SetPoint('LEFT', power, 'RIGHT', 4, 0)
					self:Tag(power.ratio, '[perpp]%')

					self.Power = power
					self.Power.colorPower = true
					self.Power.frequentUpdates = true
				end
			end
			do -- setup ring, icons, and text
				local ring = CreateFrame('Frame', nil, self)
				ring:SetFrameStrata('BACKGROUND')
				ring:SetAllPoints(self.Portrait)
				ring:SetFrameLevel(3)
				ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
				ring.bg:SetPoint('CENTER', ring, 'CENTER', -2, -3)
				ring.bg:SetTexture(base_ring3)

				self.Name = ring:CreateFontString()
				SUI:FormatFont(self.Name, 12, 'Player')
				self.Name:SetHeight(12)
				self.Name:SetWidth(150)
				self.Name:SetJustifyH('LEFT')
				self.Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -3, -5)
				if SUI.DBMod.PlayerFrames.showClass then
					self:Tag(self.Name, '[SUI_ColorClass][name]')
				else
					self:Tag(self.Name, '[name]')
				end

				self.Level = ring:CreateFontString(nil, 'BORDER', 'SUI_FontOutline10')
				self.Level:SetWidth(36)
				self.Level:SetHeight(11)
				self.Level:SetJustifyH('CENTER')
				self.Level:SetJustifyV('MIDDLE')
				self.Level:SetPoint('CENTER', ring, 'CENTER', -27, 25)
				self:Tag(self.Level, '[difficulty][level]')

				self.SUI_ClassIcon = ring:CreateTexture(nil, 'BORDER')
				self.SUI_ClassIcon:SetSize(19, 19)
				self.SUI_ClassIcon:SetPoint('CENTER', ring, 'CENTER', 23, 24)

				self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
				self.PvPIndicator:SetWidth(48)
				self.PvPIndicator:SetHeight(48)
				self.PvPIndicator:SetPoint('CENTER', ring, 'CENTER', -14, -36)

				self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
				self.RaidTargetIndicator:SetWidth(20)
				self.RaidTargetIndicator:SetHeight(20)
				self.RaidTargetIndicator:SetPoint('CENTER', ring, 'RIGHT', 1, -1)

				self.StatusText = ring:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline18')
				self.StatusText:SetPoint('CENTER', ring, 'CENTER')
				self.StatusText:SetJustifyH('CENTER')
				self:Tag(self.StatusText, '[afkdnd]')
			end
			self.TextUpdate = PostUpdateText
			self.ColorUpdate = PostUpdateColor
		end
	elseif SUI.DBMod.PlayerFrames.targettarget.style == 'medium' then
		do -- medium
			self:SetSize(124, 55)
			do -- setup base artwork
				self.artwork = CreateFrame('Frame', nil, self)
				self.artwork:SetFrameStrata('BACKGROUND')
				self.artwork:SetFrameLevel(0)
				self.artwork:SetAllPoints(self)

				self.artwork.bg = self.artwork:CreateTexture(nil, 'BACKGROUND')
				self.artwork.bg:SetPoint('CENTER')
				self.artwork.bg:SetTexture(base_plate3)
				self.artwork.bg:SetSize(170, 80)
				self.artwork.bg:SetTexCoord(.68, 0, 0, 0.6640625)
				self.artwork = artwork

				self.ThreatIndicator = CreateFrame('Frame', nil, self)
				self.ThreatIndicator.Override = threat
			end
			do -- setup status bars
				do -- cast bar
					local cast = CreateFrame('StatusBar', nil, self)
					cast:SetFrameStrata('BACKGROUND')
					cast:SetFrameLevel(2)
					cast:SetSize(95, 14)
					cast:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -36, -20)

					cast.Text = cast:CreateFontString()
					SUI:FormatFont(cast.Text, 10, 'Player')
					cast.Text:SetSize(90, 11)
					cast.Text:SetJustifyH('LEFT')
					cast.Text:SetJustifyV('MIDDLE')
					cast.Text:SetPoint('RIGHT', cast, 'RIGHT', -4, 0)

					cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					cast.Time:SetSize(40, 11)
					cast.Time:SetJustifyH('LEFT')
					cast.Time:SetJustifyV('MIDDLE')
					cast.Time:SetPoint('LEFT', cast, 'RIGHT', 4, 0)

					self.Castbar = cast
					self.Castbar.OnUpdate = OnCastbarUpdate
					self.Castbar.PostCastStart = PostCastStart
					self.Castbar.PostChannelStart = PostChannelStart
					self.Castbar.PostCastStop = PostCastStop
				end
				do -- health bar
					local health = CreateFrame('StatusBar', nil, self)
					health:SetFrameStrata('BACKGROUND')
					health:SetFrameLevel(2)
					health:SetSize(93, 14)
					health:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -2)
					health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

					health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.value:SetSize(85, 11)
					health.value:SetJustifyH('LEFT')
					health.value:SetJustifyV('MIDDLE')
					health.value:SetPoint('RIGHT', health, 'RIGHT', -4, 0)

					self:Tag(health.value, PlayerFrames:TextFormat('health'))

					health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.ratio:SetWidth(40)
					health.ratio:SetHeight(11)
					health.ratio:SetJustifyH('LEFT')
					health.ratio:SetJustifyV('MIDDLE')
					health.ratio:SetPoint('LEFT', health, 'RIGHT', 5, 0)
					self:Tag(health.ratio, '[perhp]%')

					-- local Background = health:CreateTexture(nil, 'BACKGROUND')
					-- Background:SetAllPoints(health)
					-- Background:SetTexture(1, 1, 1, .08)

					self.Health = health
					--self.Health.bg = Background;

					self.Health.frequentUpdates = true
					self.Health.colorDisconnected = true
					if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
						self.Health.colorReaction = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
						self.Health.colorHappiness = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
						self.Health.colorClass = true
					else
						self.Health.colorSmooth = true
					end
					self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
					self.Health.colorHealth = true

					-- Position and size
					local myBars = CreateFrame('StatusBar', nil, self.Health)
					myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

					local otherBars = CreateFrame('StatusBar', nil, myBars)
					otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

					myBars:SetSize(150, 16)
					otherBars:SetSize(150, 16)

					self.HealthPrediction = {
						myBar = myBars,
						otherBar = otherBars,
						maxOverflow = 4
					}
				end
				do -- power bar
					local power = CreateFrame('StatusBar', nil, self)
					power:SetFrameStrata('BACKGROUND')
					power:SetFrameLevel(2)
					power:SetSize(90, 14)
					power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)

					power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					power.value:SetSize(85, 11)
					power.value:SetJustifyH('LEFT')
					power.value:SetJustifyV('MIDDLE')
					power.value:SetPoint('RIGHT', power, 'RIGHT', -4, 0)
					self:Tag(power.value, PlayerFrames:TextFormat('mana'))

					power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					power.ratio:SetSize(40, 11)
					power.ratio:SetJustifyH('LEFT')
					power.ratio:SetJustifyV('MIDDLE')
					power.ratio:SetPoint('LEFT', power, 'RIGHT', 5, 0)
					self:Tag(power.ratio, '[perpp]%')

					self.Power = power
					self.Power.colorPower = true
					self.Power.frequentUpdates = true
				end
			end
			do -- setup ring, icons, and text
				local ring = CreateFrame('Frame', nil, self)
				ring:SetFrameStrata('BACKGROUND')
				ring:SetPoint('TOPLEFT', self.artwork, 'TOPLEFT', 0, 0)
				ring:SetFrameLevel(3)

				self.Name = ring:CreateFontString()
				SUI:FormatFont(self.Name, 12, 'Player')
				self.Name:SetHeight(12)
				self.Name:SetWidth(132)
				self.Name:SetJustifyH('LEFT')
				self.Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, -5)
				if SUI.DBMod.PlayerFrames.showClass then
					self:Tag(self.Name, '[difficulty][level] [SUI_ColorClass][name]')
				else
					self:Tag(self.Name, '[difficulty][level] [name]')
				end

				self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
				self.RaidTargetIndicator:SetWidth(20)
				self.RaidTargetIndicator:SetHeight(20)
				self.RaidTargetIndicator:SetPoint('LEFT', self, 'RIGHT', 3, 0)

				self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
				self.PvPIndicator:SetWidth(40)
				self.PvPIndicator:SetHeight(40)
				self.PvPIndicator:SetPoint('LEFT', self, 'RIGHT', -5, 24)
			end
			self.TextUpdate = PostUpdateText
			self.ColorUpdate = PostUpdateColor
		end
	elseif SUI.DBMod.PlayerFrames.targettarget.style == 'small' then
		do -- small
			self:SetSize(200, 65)
			do -- setup base artwork
				self.artwork = CreateFrame('Frame', nil, self)
				self.artwork:SetFrameStrata('BACKGROUND')
				self.artwork:SetFrameLevel(0)
				self.artwork:SetAllPoints(self)

				self.artwork.bg = self.artwork:CreateTexture(nil, 'BACKGROUND')
				self.artwork.bg:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT')
				self.artwork.bg:SetTexture(base_plate4)
				self.artwork.bg:SetSize(200, 65)
				self.artwork.bg:SetTexCoord(.24, 1, 0, 1)
				self.artwork = artwork

				self.ThreatIndicator = CreateFrame('Frame', nil, self)
				self.ThreatIndicator.Override = threat
			end
			do -- setup status bars
				do -- health bar
					local health = CreateFrame('StatusBar', nil, self)
					health:SetFrameStrata('BACKGROUND')
					health:SetFrameLevel(1)
					health:SetSize(125, 25)
					health:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 6, 17)
					health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

					health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.value:SetSize(100, 11)
					health.value:SetJustifyH('LEFT')
					health.value:SetJustifyV('MIDDLE')
					health.value:SetPoint('RIGHT', health, 'RIGHT', -4, 0)

					self:Tag(health.value, PlayerFrames:TextFormat('health'))

					health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
					health.ratio:SetWidth(50)
					health.ratio:SetHeight(11)
					health.ratio:SetJustifyH('LEFT')
					health.ratio:SetJustifyV('MIDDLE')
					health.ratio:SetPoint('LEFT', health, 'RIGHT', 5, 0)
					self:Tag(health.ratio, '[perhp]%')

					-- local Background = health:CreateTexture(nil, 'BACKGROUND')
					-- Background:SetAllPoints(health)
					-- Background:SetTexture(1, 1, 1, .08)

					self.Health = health
					--self.Health.bg = Background;

					self.Health.frequentUpdates = true
					self.Health.colorDisconnected = true
					if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
						self.Health.colorReaction = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
						self.Health.colorHappiness = true
					elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
						self.Health.colorClass = true
					else
						self.Health.colorSmooth = true
					end
					self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
					self.Health.colorHealth = true

					-- Position and size
					local myBars = CreateFrame('StatusBar', nil, self.Health)
					myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

					local otherBars = CreateFrame('StatusBar', nil, myBars)
					otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
					otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
					otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
					otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

					myBars:SetSize(150, 16)
					otherBars:SetSize(150, 16)

					self.HealthPrediction = {
						myBar = myBars,
						otherBar = otherBars,
						maxOverflow = 4
					}
				end
			end
			do -- setup ring, icons, and text
				local ring = CreateFrame('Frame', nil, self)
				ring:SetFrameStrata('BACKGROUND')
				ring:SetPoint('TOPLEFT', self.artwork, 'TOPLEFT', 0, 0)
				ring:SetFrameLevel(3)

				self.Name = ring:CreateFontString()
				SUI:FormatFont(self.Name, 12, 'Player')
				self.Name:SetSize(132, 12)
				self.Name:SetJustifyH('LEFT')
				self.Name:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -50, -5)
				if SUI.DBMod.PlayerFrames.showClass then
					self:Tag(self.Name, '[difficulty][level] [SUI_ColorClass][name]')
				else
					self:Tag(self.Name, '[difficulty][level] [name]')
				end

				self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
				self.RaidTargetIndicator:SetSize(15, 15)
				self.RaidTargetIndicator:SetPoint('RIGHT', self, 'RIGHT', -5, 0)

				self.PvPIndicator = ring:CreateTexture(nil, 'BORDER')
				self.PvPIndicator:SetSize(30, 30)
				self.PvPIndicator:SetPoint('RIGHT', self, 'RIGHT', 0, 20)
			end
			self.TextUpdate = PostUpdateText
			self.ColorUpdate = PostUpdateColor
		end
	end
	do -- setup buffs and debuffs
		if SUI.DB.Styles.Classic.Frames[unit] then
			local Buffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			local Debuffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			-- Position and size
			local Buffs = CreateFrame('Frame', nil, self)
			Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 5)
			Buffs.size = Buffsize
			Buffs['growth-y'] = 'UP'
			Buffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Buffs.spacing
			Buffs.showType = SUI.DB.Styles.Classic.Frames[unit].Buffs.showType
			Buffs.numBuffs = SUI.DB.Styles.Classic.Frames[unit].Buffs.Number
			Buffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Buffs.onlyShowPlayer
			Buffs:SetSize(Buffsize * 4, Buffsize * Buffsize)
			Buffs.PostUpdate = PostUpdateAura
			self.Buffs = Buffs

			-- Position and size
			local Debuffs = CreateFrame('Frame', nil, self)
			Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -5, 5)
			Debuffs.size = Debuffsize
			Debuffs.initialAnchor = 'BOTTOMRIGHT'
			Debuffs['growth-x'] = 'LEFT'
			Debuffs['growth-y'] = 'UP'
			Debuffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Debuffs.spacing
			Debuffs.showType = SUI.DB.Styles.Classic.Frames[unit].Debuffs.showType
			Debuffs.numDebuffs = SUI.DB.Styles.Classic.Frames[unit].Debuffs.Number
			Debuffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Debuffs.onlyShowPlayer
			Debuffs:SetSize(Debuffsize * 4, Debuffsize * Debuffsize)
			Debuffs.PostUpdate = PostUpdateAura
			self.Debuffs = Debuffs

			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].disabled = false
		end
	end
	return self
end

local CreateFocusFrame = function(self, unit)
	self:SetWidth(180)
	self:SetHeight(60)
	do --setup base artwork
		local artwork = CreateFrame('Frame', nil, self)
		artwork:SetFrameStrata('BACKGROUND')
		artwork:SetFrameLevel(0)
		artwork:SetAllPoints(self)

		artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
		artwork.bg:SetPoint('CENTER')
		artwork.bg:SetTexture(base_plate2)
		artwork.bg:SetWidth(180)
		artwork.bg:SetHeight(60)
		if unit == 'focus' then
			artwork.bg:SetTexCoord(0, 1, 0, 0.4)
		end
		if unit == 'focustarget' then
			artwork.bg:SetTexCoord(0, 1, .5, .9)
		end
		self.artwork = artwork

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(2)
			health:SetSize(85, 15)
			if unit == 'focus' then
				health:SetPoint('CENTER', self, 'CENTER', -5, -2)
			end
			if unit == 'focustarget' then
				health:SetPoint('CENTER', self, 'CENTER', -46, -2)
			end
			health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(80, 11)
			health.value:SetJustifyH('LEFT')
			health.value:SetJustifyV('MIDDLE')
			if unit == 'focus' then
				health.value:SetPoint('RIGHT', health, 'RIGHT', 0, 0)
			end
			if unit == 'focustarget' then
				health.value:SetPoint('LEFT', health, 'LEFT', 0, 0)
			end
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.ratio:SetSize(40, 11)
			health.ratio:SetJustifyH('LEFT')
			health.ratio:SetJustifyV('MIDDLE')
			if unit == 'focus' then
				health.ratio:SetPoint('LEFT', health, 'LEFT', -30, 0)
			end
			if unit == 'focustarget' then
				health.ratio:SetPoint('LEFT', health, 'RIGHT', 1, 0)
			end
			self:Tag(health.ratio, '[perhp]%')

			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)

			self.Health = health
			--self.Health.bg = Background;

			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			-- if SUI.DBMod.PlayerFrames.bars[unit].color == "reaction" then
			-- self.Health.colorReaction = true;
			-- elseif SUI.DBMod.PlayerFrames.bars[unit].color == "happiness" then
			-- self.Health.colorHappiness = true;
			-- elseif SUI.DBMod.PlayerFrames.bars[unit].color == "class" then
			-- self.Health.colorClass = true;
			-- else
			-- self.Health.colorSmooth = true;
			-- end
			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(2)
			power:SetSize(85, 15)
			power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -2)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetSize(85, 11)
			power.value:SetJustifyH('LEFT')
			power.value:SetJustifyV('MIDDLE')
			power.value:SetPoint('TOP', self.Health.value, 'BOTTOM', -1, -6)
			self:Tag(power.value, PlayerFrames:TextFormat('mana'))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetSize(40, 11)
			power.ratio:SetJustifyH('LEFT')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetPoint('TOP', self.Health.ratio, 'BOTTOM', -4, -7)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame('Frame', nil, self)
		--ring:SetFrameStrata("BACKGROUND");
		--ring:SetAllPoints(self); ring:SetFrameLevel(3);
		ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
		ring.bg:SetPoint('LEFT', ring, 'LEFT', -2, -3)

		self.Name = ring:CreateFontString()
		SUI:FormatFont(self.Name, 12, 'Player')
		self.Name:SetSize(110, 12)
		self.Name:SetJustifyH('LEFT')
		if unit == 'focus' then
			self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 20, -6)
		elseif unit == 'focustarget' then
			self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 2, -6)
		end
		if SUI.DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, '[difficulty][level] [SUI_ColorClass][name]')
		else
			self:Tag(self.Name, '[difficulty][level] [name]')
		end

		self.LevelSkull = ring:CreateTexture(nil, 'ARTWORK')
		self.LevelSkull:SetSize(16, 16)
		self.LevelSkull:SetPoint('CENTER', self.Name, 'LEFT', 8, 0)
	end
	do -- setup buffs and debuffs
		if SUI.DB.Styles.Classic.Frames[unit] then
			local Buffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			local Debuffsize = SUI.DB.Styles.Classic.Frames[unit].Buffs.size
			-- Position and size
			local Buffs = CreateFrame('Frame', nil, self)
			Buffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 5)
			Buffs.size = Buffsize
			Buffs['growth-y'] = 'UP'
			Buffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Buffs.spacing
			Buffs.showType = SUI.DB.Styles.Classic.Frames[unit].Buffs.showType
			Buffs.numBuffs = SUI.DB.Styles.Classic.Frames[unit].Buffs.Number
			Buffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Buffs.onlyShowPlayer
			Buffs:SetSize(Buffsize * 4, Buffsize * Buffsize)
			Buffs.PostUpdate = PostUpdateAura
			self.Buffs = Buffs

			-- Position and size
			local Debuffs = CreateFrame('Frame', nil, self)
			Debuffs:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -5, 5)
			Debuffs.size = Debuffsize
			Debuffs.initialAnchor = 'BOTTOMRIGHT'
			Debuffs['growth-x'] = 'LEFT'
			Debuffs['growth-y'] = 'UP'
			Debuffs.spacing = SUI.DB.Styles.Classic.Frames[unit].Debuffs.spacing
			Debuffs.showType = SUI.DB.Styles.Classic.Frames[unit].Debuffs.showType
			Debuffs.numDebuffs = SUI.DB.Styles.Classic.Frames[unit].Debuffs.Number
			Debuffs.onlyShowPlayer = SUI.DB.Styles.Classic.Frames[unit].Debuffs.onlyShowPlayer
			Debuffs:SetSize(Debuffsize * 4, Debuffsize * Debuffsize)
			Debuffs.PostUpdate = PostUpdateAura
			self.Debuffs = Debuffs

			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].disabled = false
		end
	end
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor

	return self
end

local CreateBossFrame = function(self, unit)
	self:SetSize(145, 80)
	do --setup base artwork
		local artwork = CreateFrame('Frame', nil, self)
		artwork:SetFrameStrata('BACKGROUND')
		artwork:SetFrameLevel(2)
		artwork:SetAllPoints(self)

		artwork.bg = artwork:CreateTexture(nil, 'BACKGROUND')
		artwork.bg:SetPoint('CENTER')
		artwork.bg:SetTexture(base_plate1)
		artwork.bg:SetTexCoord(.57, .2, .2, 1)
		artwork.bg:SetAllPoints(self)
		self.artwork = artwork

		self.ThreatIndicator = CreateFrame('Frame', nil, self)
		self.ThreatIndicator.Override = threat

		local Bossartwork = CreateFrame('Frame', nil, self)
		Bossartwork:SetFrameStrata('BACKGROUND')
		Bossartwork:SetFrameLevel(1)
		Bossartwork:SetAllPoints(self)

		self.BossGraphic = Bossartwork:CreateTexture(nil, 'ARTWORK')
		self.BossGraphic:SetSize(130, 125)
		self.BossGraphic:SetPoint('TOP', self, 'TOPRIGHT', -25, 36)
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame('StatusBar', nil, self)
			cast:SetFrameStrata('BACKGROUND')
			cast:SetFrameLevel(3)
			cast:SetSize(105, 12)
			cast:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -17)

			cast.Text = cast:CreateFontString()
			SUI:FormatFont(cast.Text, 10, 'Player')
			cast.Text:SetSize(97, 10)
			cast.Text:SetJustifyH('LEFT')
			cast.Text:SetJustifyV('MIDDLE')
			cast.Text:SetPoint('LEFT', cast, 'LEFT', 4, 0)

			cast.Time = cast:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			cast.Time:SetSize(50, 10)
			cast.Time:SetJustifyH('LEFT')
			cast.Time:SetJustifyV('MIDDLE')
			cast.Time:SetPoint('LEFT', cast, 'RIGHT', 2, 0)

			self.Castbar = cast
			self.Castbar.OnUpdate = OnCastbarUpdate
			self.Castbar.PostCastStart = PostCastStart
			self.Castbar.PostChannelStart = PostChannelStart
			self.Castbar.PostCastStop = PostCastStop
		end
		do -- health bar
			local health = CreateFrame('StatusBar', nil, self)
			health:SetFrameStrata('BACKGROUND')
			health:SetFrameLevel(3)
			health:SetSize(105, 12)
			health:SetPoint('TOPRIGHT', self.Castbar, 'BOTTOMRIGHT', 0, -2)
			health:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

			health.value = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.value:SetSize(97, 10)
			health.value:SetJustifyH('LEFT')
			health.value:SetJustifyV('MIDDLE')
			health.value:SetPoint('LEFT', health, 'LEFT', 4, 0)
			self:Tag(health.value, PlayerFrames:TextFormat('health'))

			health.ratio = health:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			health.ratio:SetSize(50, 10)
			health.ratio:SetJustifyH('LEFT')
			health.ratio:SetJustifyV('MIDDLE')
			health.ratio:SetPoint('LEFT', health, 'RIGHT', 2, 0)
			self:Tag(health.ratio, '[perhp]%')

			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)

			self.Health = health
			--self.Health.bg = Background;
			self.Health.colorTapping = true
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			self.Health.colorReaction = true

			self.colors.smooth = {1, 0, 0, 1, 1, 0, 0, 1, 0}
			self.Health.colorHealth = true

			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(105, 12)
			otherBars:SetSize(105, 12)

			self.HealthPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4
			}
		end
		do -- power bar
			local power = CreateFrame('StatusBar', nil, self)
			power:SetFrameStrata('BACKGROUND')
			power:SetFrameLevel(3)
			power:SetWidth(105)
			power:SetHeight(12)
			power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -2)

			power.value = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.value:SetSize(70, 10)
			power.value:SetJustifyH('LEFT')
			power.value:SetJustifyV('MIDDLE')
			power.value:SetPoint('RIGHT', power, 'RIGHT', -4, 0)
			self:Tag(power.value, PlayerFrames:TextFormat('mana'))

			power.ratio = power:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline10')
			power.ratio:SetSize(50, 10)
			power.ratio:SetJustifyH('LEFT')
			power.ratio:SetJustifyV('MIDDLE')
			power.ratio:SetPoint('LEFT', power, 'RIGHT', 2, 0)
			self:Tag(power.ratio, '[perpp]%')

			self.Power = power
			self.Power.colorPower = true
			self.Power.frequentUpdates = true
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame('Frame', nil, self)
		ring:SetFrameLevel(4)
		ring:SetFrameStrata('BACKGROUND')
		ring:SetSize(50, 50)
		ring:SetPoint('CENTER', self, 'CENTER', -80, 3)

		self.Name = ring:CreateFontString()
		SUI:FormatFont(self.Name, 10, 'Player')
		self.Name:SetSize(127, 10)
		self.Name:SetJustifyH('LEFT')
		self.Name:SetJustifyV('MIDDLE')
		self.Name:SetPoint('TOPLEFT', self, 'TOPLEFT', 8, -2)
		if SUI.DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, '[SUI_ColorClass][name]')
		else
			self:Tag(self.Name, '[name]')
		end

		self.LevelSkull = ring:CreateTexture(nil, 'ARTWORK')
		self.LevelSkull:SetSize(16, 16)
		self.LevelSkull:SetPoint('RIGHT', self.Name, 'LEFT', 2, 0)

		self.RaidTargetIndicator = ring:CreateTexture(nil, 'ARTWORK')
		self.RaidTargetIndicator:SetSize(24, 24)
		self.RaidTargetIndicator:SetPoint('CENTER', self, 'BOTTOMLEFT', 0, 23)
	end
	self.TextUpdate = PostUpdateText
	self.ColorUpdate = PostUpdateColor

	return self
end

local CreateUnitFrame = function(self, unit)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent)
	else
		self:SetParent(SUI_FramesAnchor)
	end

	self =
		((unit == 'target' and CreateTargetFrame(self, unit)) or (unit == 'targettarget' and CreateToTFrame(self, unit)) or
		(unit == 'player' and CreatePlayerFrame(self, unit)) or
		(unit == 'focus' and CreateFocusFrame(self, unit)) or
		(unit == 'focustarget' and CreateFocusFrame(self, unit)) or
		(unit == 'pet' and CreatePetFrame(self, unit)) or
		CreateBossFrame(self, unit))

	if self.Buffs and self.Buffs.PostUpdate then
		self.Buffs:PostUpdate(unit, 'Buffs')
	end
	if self.Debuffs and self.Debuffs.PostUpdate then
		self.Debuffs:PostUpdate(unit, 'Debuffs')
	end

	self = PlayerFrames:MakeMovable(self, unit)

	return self
end

function PlayerFrames:UpdateAltBarPositions()
	-- Druid EclipseBar
	-- EclipseBarFrame:ClearAllPoints();
	-- if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
	-- EclipseBarFrame:SetPoint(SUI.DBMod.PlayerFrames.ClassBar.movement.point,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset);
	-- else
	-- EclipseBarFrame:SetPoint("TOPRIGHT",PlayerFrames.player,"TOPRIGHT",157,12);
	-- end

	-- Monk Chi Bar (Hard to move but it is doable.)
	-- MonkHarmonyBar:ClearAllPoints();
	-- if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
	-- MonkHarmonyBar:SetPoint(SUI.DBMod.PlayerFrames.ClassBar.movement.point,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset);
	-- else
	-- MonkHarmonyBar:SetPoint("BOTTOMLEFT",PlayerFrames.player,"BOTTOMLEFT",40,-40);
	-- end

	--Paladin Holy Power
	-- PaladinPowerBarFrame:ClearAllPoints();
	-- if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
	-- PaladinPowerBarFrame:SetPoint(SUI.DBMod.PlayerFrames.ClassBar.movement.point,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset);
	-- else
	-- PaladinPowerBarFrame:SetPoint("TOPLEFT",PlayerFrames.player,"BOTTOMLEFT",60,12);
	-- end

	--Priest Power Frame
	PriestBarFrame:ClearAllPoints()
	if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
		PriestBarFrame:SetPoint(
			SUI.DBMod.PlayerFrames.ClassBar.movement.point,
			SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
			SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset
		)
	else
		PriestBarFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'TOPLEFT', -4, -2)
	end

	--Warlock Power Frame
	-- WarlockPowerFrame:ClearAllPoints();
	-- if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
	-- WarlockPowerFrame:SetPoint(SUI.DBMod.PlayerFrames.ClassBar.movement.point,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
	-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset);
	-- else
	-- PlayerFrames:WarlockPowerFrame_Relocate();
	-- end

	--Death Knight Runes
	RuneFrame:ClearAllPoints()
	if SUI.DBMod.PlayerFrames.ClassBar.movement.moved then
		RuneFrame:SetPoint(
			SUI.DBMod.PlayerFrames.ClassBar.movement.point,
			SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
			SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset
		)
	else
		RuneFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 40, 7)
	end

	-- relocate the AlternatePowerBar
	if classFileName ~= 'MONK' then
		PlayerFrameAlternateManaBar:ClearAllPoints()
		if SUI.DBMod.PlayerFrames.AltManaBar.movement.moved then
			PlayerFrameAlternateManaBar:SetPoint(
				SUI.DBMod.PlayerFrames.AltManaBar.movement.point,
				SUI.DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
				SUI.DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
				SUI.DBMod.PlayerFrames.AltManaBar.movement.xOffset,
				SUI.DBMod.PlayerFrames.AltManaBar.movement.yOffset
			)
		else
			PlayerFrameAlternateManaBar:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 40, 0)
		end
	end
end

function PlayerFrames:ResetAltBarPositions()
	SUI.DBMod.PlayerFrames.AltManaBar.movement.moved = false
	SUI.DBMod.PlayerFrames.ClassBar.movement.moved = false
	PlayerFrames:UpdateAltBarPositions()
end

function PlayerFrames:WarlockPowerFrame_Relocate() -- Sets the location of the warlock bars based on spec
	local spec = GetSpecialization()
	if (spec == SPEC_WARLOCK_AFFLICTION) then
		-- set up Affliction
		WarlockPowerFrame:SetScale(.85)
		WarlockPowerFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'TOPLEFT', 8, -2)
	elseif (spec == SPEC_WARLOCK_DESTRUCTION) then
		-- set up Destruction
		WarlockPowerFrame:SetScale(0.85)
		WarlockPowerFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'TOPLEFT', 14, -2)
	elseif (spec == SPEC_WARLOCK_DEMONOLOGY) then
		-- set up Demonic
		WarlockPowerFrame:SetScale(1)
		WarlockPowerFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'TOPRIGHT', 15, 15)
	end
end

function PlayerFrames:SetupExtras()
	do -- relocate the AlternatePowerBar
		if classFileName == 'MONK' then
			--Align and shrink to fit under CHI, not movable
			PlayerFrameAlternateManaBar:SetParent(PlayerFrames.player)
			AlternatePowerBar_OnLoad(PlayerFrameAlternateManaBar)
			PlayerFrameAlternateManaBar:SetFrameStrata('MEDIUM')
			PlayerFrameAlternateManaBar:SetFrameLevel(6)
			PlayerFrameAlternateManaBar:SetScale(.7)
			PlayerFrameAlternateManaBar:ClearAllPoints()
			hooksecurefunc(
				PlayerFrameAlternateManaBar,
				'SetPoint',
				function(_, _, parent)
					if (parent ~= PlayerFrames.player) then
						PlayerFrameAlternateManaBar:ClearAllPoints()
						PlayerFrameAlternateManaBar:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', -5, -17)
					end
				end
			)
			PlayerFrameAlternateManaBar:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', -5, -17)
		else
			--Make it look like a smaller, movable mana bar.
			hooksecurefunc(
				PlayerFrameAlternateManaBar,
				'SetPoint',
				function(_, _, parent)
					if (parent ~= PlayerFrames.player) and (SUI.DBMod.PlayerFrames.AltManaBar.movement.moved == false) then
						PlayerFrameAlternateManaBar:ClearAllPoints()
						PlayerFrameAlternateManaBar:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 40, 0)
					end
				end
			)
			PlayerFrameAlternateManaBar:SetParent(PlayerFrames.player)
			AlternatePowerBar_OnLoad(PlayerFrameAlternateManaBar)
			PlayerFrameAlternateManaBar:SetFrameStrata('MEDIUM')
			PlayerFrameAlternateManaBar:SetFrameLevel(4)
			PlayerFrameAlternateManaBar:SetScale(1)
			PlayerFrameAlternateManaBar:EnableMouse(enable)
			PlayerFrameAlternateManaBar:SetScript(
				'OnMouseDown',
				function(self, button)
					if button == 'LeftButton' and IsAltKeyDown() then
						SUI.DBMod.PlayerFrames.AltManaBar.movement.moved = true
						self:SetMovable(true)
						self:StartMoving()
					end
				end
			)
			PlayerFrameAlternateManaBar:SetScript(
				'OnMouseUp',
				function(self, button)
					self:StopMovingOrSizing()
					SUI.DBMod.PlayerFrames.AltManaBar.movement.point,
						SUI.DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
						SUI.DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
						SUI.DBMod.PlayerFrames.AltManaBar.movement.xOffset,
						SUI.DBMod.PlayerFrames.AltManaBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
				end
			)
		end

		-- Druid EclipseBar
		-- if classname == "Druid" then
		-- EclipseBarFrame:SetParent(PlayerFrames.player); EclipseBar_OnLoad(EclipseBarFrame); EclipseBarFrame:SetFrameStrata("MEDIUM");
		-- EclipseBarFrame:SetFrameLevel(4); EclipseBarFrame:SetScale(0.8 * SUI.DBMod.PlayerFrames.ClassBar.scale); EclipseBarFrame:EnableMouse(enable);
		-- EclipseBarFrame:SetScript("OnMouseDown",function(self,button)
		-- if button == "LeftButton" and IsAltKeyDown() then
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.moved = true;
		-- self:SetMovable(true);
		-- self:StartMoving();
		-- end
		-- end);
		-- EclipseBarFrame:SetScript("OnMouseUp",function(self,button)
		-- self:StopMovingOrSizing();
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.point,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
		-- end);
		-- end

		-- PriestBarFrame
		-- if classname == "Priest" then
		PriestBarFrame:SetParent(PlayerFrames.player)
		PriestBarFrame_OnLoad(PriestBarFrame)
		PriestBarFrame:SetFrameStrata('MEDIUM')
		PriestBarFrame:SetFrameLevel(4)
		PriestBarFrame:SetScale(.7 * SUI.DBMod.PlayerFrames.ClassBar.scale)
		PriestBarFrame:EnableMouse(enable)
		PriestBarFrame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					SUI.DBMod.PlayerFrames.ClassBar.movement.moved = true
					self:SetMovable(true)
					self:StartMoving()
				end
			end
		)
		PriestBarFrame:SetScript(
			'OnMouseUp',
			function(self, button)
				self:StopMovingOrSizing()
				SUI.DBMod.PlayerFrames.ClassBar.movement.point,
					SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
					SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
					SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
					SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
			end
		)
		-- end

		-- Rune Frame
		-- if classname == "DeathKnight" then
		RuneFrame:SetParent(PlayerFrames.player)
		-- RuneFrame_OnLoad(RuneFrame);
		RuneFrame:SetFrameStrata('MEDIUM')
		RuneFrame:SetFrameLevel(4)
		RuneFrame:SetScale(0.97 * SUI.DBMod.PlayerFrames.ClassBar.scale)
		RuneFrame:EnableMouse(enable)
		-- RuneButtonIndividual1:EnableMouse(enable);
		RuneFrame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					SUI.DBMod.PlayerFrames.ClassBar.movement.moved = true
					self:SetMovable(true)
					self:StartMoving()
				end
			end
		)
		RuneFrame:SetScript(
			'OnMouseUp',
			function(self, button)
				self:StopMovingOrSizing()
				SUI.DBMod.PlayerFrames.ClassBar.movement.point,
					SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
					SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
					SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
					SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
			end
		)
		-- RuneButtonIndividual1:SetScript("OnMouseDown",function(self,button)
		-- if button == "LeftButton" and IsAltKeyDown() then
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.moved = true;
		-- self:SetMovable(true);
		-- self:StartMoving();
		-- end
		-- end);
		-- RuneButtonIndividual1:SetScript("OnMouseUp",function(self,button)
		-- self:StopMovingOrSizing();
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.point,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.xOffset,
		-- SUI.DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
		-- end);
		-- end

		-- if classname == "Shaman" then
		-- Totem Frame (Pally Concentration, Shaman Totems, Monk Statues)
		for i = 1, 4 do
			local timer = _G['TotemFrameTotem' .. i .. 'Duration']
			timer.Show = function()
				return
			end
			timer:Hide()
		end
		hooksecurefunc(
			TotemFrame,
			'SetPoint',
			function(_, _, parent)
				if (parent ~= PlayerFrames.player) then
					TotemFrame:ClearAllPoints()
					if classFileName == 'MONK' then
						TotemFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 100, 8)
					elseif classFileName == 'PALADIN' then
						TotemFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 15, 8)
					else
						TotemFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 70, 8)
					end
				end
			end
		)
		TotemFrame:SetParent(PlayerFrames.player)
		TotemFrame_OnLoad(TotemFrame)
		TotemFrame:SetFrameStrata('MEDIUM')
		TotemFrame:SetFrameLevel(4)
		TotemFrame:SetScale(0.7 * SUI.DBMod.PlayerFrames.ClassBar.scale)
		TotemFrame:ClearAllPoints()
		TotemFrame:SetPoint('TOPLEFT', PlayerFrames.player, 'BOTTOMLEFT', 70, 8)
		-- end

		-- relocate the PlayerPowerBarAlt
		hooksecurefunc(
			PlayerPowerBarAlt,
			'SetPoint',
			function(_, _, parent)
				if (parent ~= PlayerFrames.player) then
					PlayerPowerBarAlt:ClearAllPoints()
					PlayerPowerBarAlt:SetPoint('BOTTOMLEFT', PlayerFrames.player, 'TOPLEFT', 10, 40)
				end
			end
		)
		PlayerPowerBarAlt:SetParent(PlayerFrames.player)
		PlayerPowerBarAlt:SetFrameStrata('MEDIUM')
		PlayerPowerBarAlt:SetFrameLevel(4)
		PlayerPowerBarAlt:SetScale(1 * SUI.DBMod.PlayerFrames.ClassBar.scale)
		PlayerPowerBarAlt:ClearAllPoints()
		PlayerPowerBarAlt:SetPoint('BOTTOMLEFT', PlayerFrames.player, 'TOPLEFT', 10, 40)

		PlayerFrames:UpdateAltBarPositions()

		--Watch for Spec Changes
		local SpecWatcher = CreateFrame('Frame')
		SpecWatcher:RegisterEvent('PLAYER_TALENT_UPDATE')
		SpecWatcher:SetScript(
			'OnEvent',
			function()
				PlayerFrames:UpdateAltBarPositions()
			end
		)
	end

	do -- create a LFD cooldown frame
		local GetLFGDeserter = GetLFGDeserterExpiration
		local GetLFGRandomCooldown = GetLFGRandomCooldownExpiration

		local UpdateCooldown = function(self)
			local deserterExpiration = GetLFGDeserter()
			local myExpireTime, mode, hasDeserter
			if (deserterExpiration) then
				myExpireTime = deserterExpiration
				hasDeserter = true
			else
				myExpireTime = GetLFGRandomCooldown()
			end
			self.myExpirationTime = myExpireTime or GetTime()
			if (myExpireTime and GetTime() < myExpireTime) then
				if (hasDeserter) then
					self.text:SetText '|CFFEE0000X|r' -- deserter
					mode = 'deserter'
				else
					mode = 'time'
				end
			else
				mode = false
			end
			return mode
		end

		local StartAnimating = EyeTemplate_StartAnimating
		local StopAnimating = EyeTemplate_StopAnimating

		local UpdateIsShown = function(self)
			--	local mode, submode = GetLFGMode();
			local mode = UpdateCooldown(self)
			if (mode) then
				self:Show()
				if (mode == 'time') then
					StartAnimating(self)
				else
					StopAnimating(self)
				end
			else
				self:Hide()
			end
		end

		local OnEnter = function(self)
			local mode = UpdateCooldown(self)
			local DESERTER = 'You recently deserted a Dungeon Finder group|nand may not queue again for:'
			local RANDOM_COOLDOWN = LFG_RANDOM_COOLDOWN_YOU
			if (mode) then
				GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
				GameTooltip:SetText(LOOKING_FOR_DUNGEON)
				local timeRemaining = self.myExpirationTime - GetTime()
				if (timeRemaining > 0) then
					if (mode == 'deserter') then
						GameTooltip:AddLine(string.format(DESERTER .. ' %s', '|CFFEE0000' .. SecondsToTime(ceil(timeRemaining)) .. '|r'))
					else
						GameTooltip:AddLine(
							string.format(RANDOM_COOLDOWN .. ' %s', '|CFFEE0000' .. SecondsToTime(ceil(timeRemaining)) .. '|r')
						)
					end
				else
					GameTooltip:AddLine('Ready')
				end
				GameTooltip:Show()
			end
		end

		local OnLeave = function(self)
			GameTooltip:Hide()
		end

		LFDCooldown = CreateFrame('Frame', nil, PlayerFrames.player)
		LFDCooldown:SetFrameStrata('BACKGROUND')
		LFDCooldown:SetFrameLevel(10)
		LFDCooldown:SetWidth(38) -- Set these to whatever height/width is needed
		LFDCooldown:SetHeight(38) -- for your Texture

		local t = LFDCooldown:CreateTexture(nil, 'BACKGROUND')
		--	t:SetTexture("Interface\\LFGFrame\\BattlenetWorking19.blp")
		t:SetTexture('Interface\\LFGFrame\\LFG-Eye.blp')
		t:SetAllPoints(LFDCooldown)
		LFDCooldown.texture = t

		local txt = LFDCooldown:CreateFontString(nil, 'OVERLAY', 'SUI_FontOutline18')
		txt:SetWidth(14)
		txt:SetHeight(22)
		txt:SetJustifyH('MIDDLE')
		txt:SetJustifyV('MIDDLE')
		txt:SetPoint('TOPLEFT', LFDCooldown, 'TOPLEFT', 5, 0)
		txt:SetPoint('BOTTOMRIGHT', LFDCooldown, 'BOTTOMRIGHT', 0, 0)
		LFDCooldown.text = txt
		LFDCooldown.text:SetText ''

		--	LFDCooldown.myExpirationTime = "";
		LFDCooldown:SetPoint('CENTER', PlayerFrames.player, 'CENTER', 85, -30)
		LFDCooldown:RegisterEvent('PLAYER_ENTERING_WORLD')
		LFDCooldown:RegisterEvent('UNIT_AURA')
		LFDCooldown:EnableMouse()
		LFDCooldown:SetScript('OnEvent', UpdateIsShown)
		LFDCooldown:SetScript('OnEnter', OnEnter)
		LFDCooldown:SetScript('OnLeave', OnLeave)
		--	LFDCooldown.text:SetText"|CFFEE0000X|r" -- deserter
		--	LFDCooldown:Show() -- on cooldown
		--	PlayerFrames.player.LFDRole:SetTexCoord(20/64, 39/64, 22/64, 41/64) -- set dps lfdrole icon
	end
end

SUIUF:RegisterStyle('SUI_PlayerFrames_Classic', CreateUnitFrame)
