local _G, SUI = _G, SUI
local module = SUI:GetModule('Module_UnitFrames')
----------------------------------------------------------------------------------------------------

--	Formatting functions
function module:TextFormat(text, unit)
	local textstyle = SUI.DBMod.PartyFrames.bars[text].textstyle
	local textmode = SUI.DBMod.PartyFrames.bars[text].textmode
	local a, m, t, z
	if text == 'mana' then
		z = 'pp'
	else
		z = 'hp'
	end

	-- textstyle
	-- "Long: 			 Displays all numbers."
	-- "Long Formatted: Displays all numbers with commas."
	-- "Dynamic: 		 Abbriviates and formats as needed"
	if textstyle == 'long' then
		a = '[cur' .. z .. ']'
		m = '[missing' .. z .. ']'
		t = '[max' .. z .. ']'
	elseif textstyle == 'longfor' then
		a = '[cur' .. z .. 'formatted]'
		m = '[missing' .. z .. 'formatted]'
		t = '[max' .. z .. 'formatted]'
	elseif textstyle == 'disabled' then
		return ''
	else
		a = '[cur' .. z .. 'dynamic]'
		m = '[missing' .. z .. 'dynamic]'
		t = '[max' .. z .. 'dynamic]'
	end
	-- textmode
	-- [1]="Avaliable / Total",
	-- [2]="(Missing) Avaliable / Total",
	-- [3]="(Missing) Avaliable"

	if textmode == 1 then
		return a .. ' / ' .. t
	elseif textmode == 2 then
		return '(' .. m .. ') ' .. a .. ' / ' .. t
	elseif textmode == 3 then
		return '(' .. m .. ') ' .. a
	end
end

PartyFrames.PostUpdateText = function(self)
	if self.Health and self.Health.value then
		self:Untag(self.Health.value)
		self:Tag(self.Health.value, PartyFrames:TextFormat('health'))
	end
	if self.Power and self.Power.value then
		self:Untag(self.Power.value)
		self:Tag(self.Power.value, PartyFrames:TextFormat('mana'))
	end
end

function PartyFrames:menu(self)
	if (not self.id) then
		self.id = self.unit:match '^.-(%d+)'
	end
	local unit = string.gsub(self.unit, '(.)', string.upper, 1)
	if (_G[unit .. 'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit .. 'FrameDropDown'], 'cursor')
	elseif ((self.unit:match('party')) and (not self.unit:match('partypet'))) then
		ToggleDropDownMenu(1, nil, _G['PartyMemberFrame' .. self.id .. 'DropDown'], 'cursor')
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, 'cursor')
	end
end

function PlayerFrames:CreatePortrait(self)
	if SUI.DBMod.PlayerFrames.Portrait3D then
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript(
			'OnShow',
			function(self)
				self:SetCamera(1)
			end
		)
		Portrait.type = '3D'
		Portrait:SetFrameLevel(1)
		return Portrait
	else
		return self:CreateTexture(nil, 'BORDER')
	end
end

function PartyFrames:PostUpdateAura(self, unit)
	if SUI.DBMod.PartyFrames.showAuras then
		self:Show()
		self.size = SUI.DBMod.PartyFrames.Auras.size
		self.spacing = SUI.DBMod.PartyFrames.Auras.spacing
		self.showType = SUI.DBMod.PartyFrames.Auras.showType
		self.numBuffs = SUI.DBMod.PartyFrames.Auras.NumBuffs
		self.numDebuffs = SUI.DBMod.PartyFrames.Auras.NumDebuffs
	else
		self:Hide()
	end
end

function PartyFrames:MakeMovable(self)
	self:RegisterForClicks('AnyDown')
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)

	self:SetScript(
		'OnMouseDown',
		function(self, button)
			if button == 'LeftButton' and IsAltKeyDown() then
				SUI.PartyFrames.mover:Show()
				SUI.DBMod.PartyFrames.moved = true
				SUI.PartyFrames:SetMovable(true)
				SUI.PartyFrames:StartMoving()
			end
		end
	)
	self:SetScript(
		'OnMouseUp',
		function(self, button)
			SUI.PartyFrames.mover:Hide()
			SUI.PartyFrames:StopMovingOrSizing()
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = SUI.PartyFrames:GetPoint()
			for k, v in pairs(Anchors) do
				SUI.DBMod.PartyFrames.Anchors[k] = v
			end
		end
	)

	return self
end

------------------------

function PlayerFrames:round(val, decimal)
	if (decimal) then
		return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end

function PlayerFrames:comma_value(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

do -- Boss graphic as an SUIUF module
	local Update = function(self, event, unit)
		if (self.unit ~= unit) then
			return
		end
		if (not self.BossGraphic) then
			return
		end
		self.BossGraphic:SetTexture('Interface\\AddOns\\SpartanUI\\Images\\elite_rare')
		self.BossGraphic:SetTexCoord(1, 0, 0, 1)
		self.BossGraphic:SetVertexColor(1, 0.9, 0, 1)
	end
	local Enable = function(self)
		if (self.BossGraphic) then
			return true
		end
	end
	local Disable = function(self)
		return
	end
	SUIUF:AddElement('BossGraphic', Update, Enable, Disable)
end

function PlayerFrames:SetupStaticOptions()
	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}
	for _, unit in pairs(FramesList) do
		--Health Bar Color
		if SUI.DBMod.PlayerFrames.bars[unit].color == 'reaction' then
			PlayerFrames[unit].Health.colorReaction = true
		elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'happiness' then
			PlayerFrames[unit].Health.colorHappiness = true
		elseif SUI.DBMod.PlayerFrames.bars[unit].color == 'class' then
			PlayerFrames[unit].Health.colorClass = true
		else
			PlayerFrames[unit].Health.colorSmooth = true
		end
	end
end

function PlayerFrames:Buffs(self, unit)
	--Make sure there is an anchor for buffs
	if not self.BuffAnchor then
		return self
	end
	local CurStyle = SUI.DBMod.PlayerFrames.Style
	-- Build buffs
	if SUI.DB.Styles[CurStyle].Frames[unit] then
		local Buffsize = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.size
		local Debuffsize = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.size
		local BuffsMode = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Mode
		local DebuffsMode = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Mode

		--Determine how many we can fit for Hybrid Display
		local split = 4
		local Spacer = 3
		local BuffWidth = 0
		local BuffWidth2 = 0
		local DeBuffWidth = 0
		local DeBuffWidth2 = 0
		for index = 1, 10 do
			if
				((index * (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing)) <= (self.BuffAnchor:GetWidth() / split))
			 then
				BuffWidth = index
			end
			if ((index * (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing)) <= (self.BuffAnchor:GetWidth() / 2)) then
				BuffWidth2 = index
			end
		end
		for index = 1, 10 do
			if
				((index * (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing)) <=
					(self.BuffAnchor:GetWidth() / split))
			 then
				DeBuffWidth = index
			end
			if
				((index * (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing)) <= (self.BuffAnchor:GetWidth() / 2))
			 then
				DeBuffWidth2 = index
			end
		end
		local BuffWidthActual = (Buffsize + SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing) * BuffWidth
		local DeBuffWidthActual = (Debuffsize + SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing) * DeBuffWidth

		-- Position Bar
		local BarPosition = function(self, pos)
			-- Reminder on how position is defined
			-- * = Icons
			-- - = Bars
			--Pos1 -------**
			--Pos2 **-----**
			--Pos3 **-------
			if pos == 1 then
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', ((DeBuffWidthActual + Spacer) * -1), 0)
			elseif pos == 2 then
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', (BuffWidthActual + Spacer), 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', ((DeBuffWidthActual + Spacer) * -1), 0)
			else --pos 3
				self.AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', (BuffWidthActual + Spacer), 0)
				self.AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			end
			return self
		end

		--Buff Icons
		local Buffs = CreateFrame('Frame', nil, self)
		--Debuff Icons
		local Debuffs = CreateFrame('Frame', nil, self)
		-- Setup icons if needed
		local iconFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
			if caster == 'player' and (duration == 0 or duration > 60) then --Do not show DOTS & HOTS
				return true
			elseif caster ~= 'player' then
				return true
			end
		end
		if BuffsMode ~= 'bars' and BuffsMode ~= 'disabled' then
			Buffs:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			Buffs.size = Buffsize
			Buffs['growth-x'] = 'RIGHT'
			Buffs['growth-y'] = 'UP'
			Buffs.spacing = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.spacing
			Buffs.showType = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.showType
			Buffs.numBuffs = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Number
			Buffs.onlyShowPlayer = SUI.DB.Styles[CurStyle].Frames[unit].Buffs.onlyShowPlayer
			Buffs:SetSize(BuffWidthActual, (Buffsize * (Buffs.numBuffs / BuffWidth)))
			Buffs.PostUpdate = PostUpdateAura
			if BuffsMode ~= 'icons' then
				Buffs.CustomFilter = iconFilter
			end
			self.Buffs = Buffs
		end
		if DebuffsMode ~= 'bars' and DebuffsMode ~= 'disabled' then
			Debuffs:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			Debuffs.size = Debuffsize
			Debuffs.initialAnchor = 'BOTTOMRIGHT'
			Debuffs['growth-x'] = 'LEFT'
			Debuffs['growth-y'] = 'UP'
			Debuffs.spacing = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.spacing
			Debuffs.showType = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.showType
			Debuffs.numDebuffs = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Number
			Debuffs.onlyShowPlayer = SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.onlyShowPlayer
			Debuffs:SetSize(DeBuffWidthActual, (Debuffsize * (Debuffs.numDebuffs / DeBuffWidth)))
			Debuffs.PostUpdate = PostUpdateAura
			if DebuffsMode ~= 'icons' then
				Debuffs.CustomFilter = iconFilter
			end
			self.Debuffs = Debuffs
		end

		--Bars
		local AuraBars = CreateFrame('Frame', nil, self)
		AuraBars:SetHeight(1)
		AuraBars.auraBarTexture = Smoothv2
		AuraBars.PostUpdate = PostUpdateAura
		AuraBars.spellTimeFont = SUI:GetFontFace('Player')
		AuraBars.spellNameFont = SUI:GetFontFace('Player')

		--Hots and Dots Filter
		local Barfilter = function(name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, spellID)
			--Only Show things with a SHORT durration (HOTS and DOTS)
			if duration > 0 and duration < 60 then
				return true
			end
		end

		-- Determine Buff Bar locaion
		if BuffsMode == 'bars' and DebuffsMode == 'icons' then
			AuraBars.Buffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		elseif BuffsMode == 'bars' and DebuffsMode == 'both' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		elseif BuffsMode == 'bars' and (DebuffsMode == 'bars' or DebuffsMode == 'disabled') then
			if DebuffsMode == 'disabled' then
				AuraBars.Buffs = true
			else
				AuraBars.ShowAll = true
			end
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'icons' and DebuffsMode == 'icons' then
			Buffs:SetSize(self.BuffAnchor:GetWidth() / 2, (Buffsize * (Buffs.numBuffs / BuffWidth2)))
			Debuffs:SetSize(self.BuffAnchor:GetWidth() / 2, (Debuffsize * (Debuffs.numDebuffs / DeBuffWidth2)))
		elseif BuffsMode == 'icons' and DebuffsMode == 'both' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'icons' and DebuffsMode == 'bars' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 3)
		elseif BuffsMode == 'icons' and DebuffsMode == 'disabled' then
			Buffs:SetSize(self.BuffAnchor:GetWidth(), (Buffsize * (Buffs.numBuffs / self.BuffAnchor:GetWidth())))
		elseif BuffsMode == 'both' and DebuffsMode == 'icons' then
			AuraBars.Buffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'both' and DebuffsMode == 'both' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 2)
		elseif BuffsMode == 'both' and DebuffsMode == 'bars' then
			AuraBars.ShowAll = true
			self.AuraBars = AuraBars
			BarPosition(self, 3)
		elseif BuffsMode == 'bars' and DebuffsMode == 'disabled' then
			AuraBars.Buffs = true
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'disabled' and DebuffsMode == 'bars' then
			AuraBars.Debuffs = true
			AuraBars:SetPoint('BOTTOMLEFT', self.BuffAnchor, 'TOPLEFT', 0, 0)
			AuraBars:SetPoint('BOTTOMRIGHT', self.BuffAnchor, 'TOPRIGHT', 0, 0)
			self.AuraBars = AuraBars
		elseif BuffsMode == 'disabled' and DebuffsMode == 'icons' then
			Debuffs:SetSize(self.BuffAnchor:GetWidth(), (Debuffsize * (Debuffs.numDebuffs / self.BuffAnchor:GetWidth())))
		elseif BuffsMode == 'disabled' and DebuffsMode == 'both' then
			AuraBars.Debuffs = true
			self.AuraBars = AuraBars
			BarPosition(self, 1)
		end

		--Buff Filter for bars
		if self.AuraBars then
			AuraBars.filter = Barfilter
		end

		--Change options if needed
		if SUI.DB.Styles[CurStyle].Frames[unit].Buffs.Mode == 'bars' then
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['Number'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['size'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['spacing'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Buffs'].args['showType'].disabled = true
		end
		if SUI.DB.Styles[CurStyle].Frames[unit].Debuffs.Mode == 'bars' then
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['Number'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['size'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['spacing'].disabled = true
			SUI.opt.args['PlayerFrames'].args['auras'].args[unit].args['Debuffs'].args['showType'].disabled = true
		end

		SUI.opt.args['PlayerFrames'].args['auras'].args[unit].disabled = false
	end
	return self
end

function PlayerFrames:UpdatePosition()
	local FramesList = {
		[1] = 'pet',
		[2] = 'target',
		[3] = 'targettarget',
		[4] = 'focus',
		[5] = 'focustarget',
		[6] = 'player'
	}

	for _, b in pairs(FramesList) do
		if SUI.DBMod.PlayerFrames[b] ~= nil and SUI.DBMod.PlayerFrames[b].moved then
			PlayerFrames[b]:SetMovable(true)
			PlayerFrames[b]:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(SUI.DBMod.PlayerFrames[b].Anchors) do
				Anchors[k] = v
			end
			PlayerFrames[b]:ClearAllPoints()
			PlayerFrames[b]:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		elseif SUI.DBMod.PlayerFrames[b] ~= nil then
			PlayerFrames[b]:SetMovable(false)
			PlayerFrames[b]:ClearAllPoints()
			if (SUI.DBMod.PlayerFrames.Style == 'Classic') then
				PlayerFrames:PositionFrame_Classic(b)
			elseif (SUI.DBMod.PlayerFrames.Style == 'plain') then
				PlayerFrames:PositionFrame_Plain(b)
			else
				SUI:GetModule('Style_' .. SUI.DBMod.PlayerFrames.Style):PositionFrame(b)
			end
		else
			print(b .. ' Frame has not been spawned by your theme')
		end
	end

	-- for i = 1, MAX_BOSS_FRAMES do
	if SUI.DBMod.PlayerFrames.BossFrame.display then
		if SUI.DBMod.PlayerFrames.boss.moved then
			PlayerFrames.boss[1]:SetMovable(true)
			PlayerFrames.boss[1]:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(SUI.DBMod.PlayerFrames.boss.Anchors) do
				Anchors[k] = v
			end
			PlayerFrames.boss[1]:ClearAllPoints()
			PlayerFrames.boss[1]:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			PlayerFrames.boss[1]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			PlayerFrames.boss[1]:SetMovable(false)
		end
	end
	-- end
end

function PlayerFrames:MakeMovable(self, unit)
	self:RegisterForClicks('AnyDown')
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)

	if self.artwork then
		self.artwork:SetScript(
			'OnEnter',
			function()
				UnitFrame_OnEnter(self, unit)
			end
		)
		self.artwork:SetScript(
			'OnLeave',
			function()
				UnitFrame_OnLeave(self, unit)
			end
		)
	end

	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	return self
end

------------------------

function RaidFrames:PostUpdateDebuffs(self, unit)
	if SUI.DBMod.RaidFrames.showDebuffs then
		self:Show()
		self.size = SUI.DBMod.RaidFrames.Auras.size
		self.spacing = SUI.DBMod.RaidFrames.Auras.spacing
		self.showType = SUI.DBMod.RaidFrames.Auras.showType
	else
		self:Hide()
	end
end

function RaidFrames:UpdateAura()
	for i = 1, 40 do
		local unit = _G['SUI_RaidFrameHeaderUnitButton' .. i]
		if unit and unit.Auras then
			unit.Auras:PostUpdateDebuffs()
		end
	end
end

function RaidFrames:UpdateText()
	for i = 1, 40 do
		local unit = _G['SUI_RaidFrameHeaderUnitButton' .. i]
		if unit then
			unit:TextUpdate()
		end
	end
end
