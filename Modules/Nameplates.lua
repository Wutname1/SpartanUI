local unpack, SUI, L, print, UF = unpack, SUI, SUI.L, SUI.print, SUI.UF
local module = SUI:NewModule('Module_Nameplates') ---@type SUI.Module
module.description = 'Basic nameplate module'
local Images = {
	Alliance = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = { 0, 0.458984375, 0.74609375, 1 }, --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = { 0.03125, 0.427734375, 0, 0.421875 },
		},
	},
	Horde = {
		bg = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = { 0.572265625, 0.96875, 0.74609375, 1 }, --left, right, top, bottom
		},
		flair = {
			Texture = 'Interface\\addons\\SpartanUI\\Images\\war\\UnitFrames',
			Coords = { 0.541015625, 1, 0, 0.421875 },
		},
	},
}
local BarTexture = 'Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2'
local NameplateList = {}
local ElementList = {
	'Auras',
	'ClassIcon',
	'Health',
	'Power',
	'Castbar',
	'RareElite',
	'RaidTargetIndicator',
	'QuestMob',
	'PvPIndicator',
	'ThreatIndicator',
	'PvPRoleIndicator',
}
---@type table<SUI.UF.Elements.list, SUI.UF.Elements.Settings>
local ElementDefaults = {
	Health = {
		enabled = true,
		height = 8,
		offset = 0,
		texture = 'SpartanUI Default',
		colorReaction = true,
		colorSmooth = true,
		colorClass = true,
		colorTapping = true,
		colorDisconnected = true,
		bg = {
			enabled = true,
			color = { 1, 1, 1, 0.6 },
		},
		text = {
			['1'] = {
				enabled = true,
				size = 8,
				text = '[SUIHealth(percentage)]',
				position = {
					anchor = 'CENTER',
					x = 0,
					y = 0,
				},
			},
		},
	},
	QuestMob = {
		enabled = true,
		size = 16,
		position = {
			anchor = 'RIGHT',
			relativePoint = 'LEFT',
			x = 0,
			y = 0,
		},
	},
}

---@type table<SUI.UF.Elements.list, SUI.UF.Elements.Settings>
local CurrentSettings = {}

---@param frame any
---@param obj SUI.UF.Elements.list
local function BuildElement(frame, obj)
	--Ensure we have settings
	if not CurrentSettings[obj] then CurrentSettings[obj] = SUI:CopyData(SUI.UF.Elements:GetConfig(obj), {}) end

	--Build it
	UF.Elements:Build(frame, obj, CurrentSettings[obj])
end

local UpdateElementState = function(frame)
	local elements = module.DB.elements

	frame.PvPIndicator.Override(frame, nil, frame.unit)

	-- Disable or enable elements that should not be enabled
	for _, item in ipairs(ElementList) do
		if frame[item] and elements[item].enabled then
			frame:EnableElement(item)
		else
			frame:DisableElement(item)
		end
	end
	-- Position Updates
	if InCombatLockdown() then return end

	for _, elementName in ipairs(ElementList) do
		local element = frame[elementName]
		local data = elements[elementName]

		-- Setup the Alpha scape and position
		element:SetAlpha(data.alpha)
		element:SetScale(data.scale)

		if UF.Elements:GetConfig(elementName).config.NoBulkUpdate then return end
		if UF.Elements:GetConfig(elementName).config.type == 'Indicator' and element.SetDrawLayer then element:SetDrawLayer('BORDER', 7) end

		-- Positioning
		element:ClearAllPoints()
		if data.points then
			if type(data.points) == 'string' then
				element:SetAllPoints(frame[data.points])
			elseif data.points and type(data.points) == 'table' then
				for _, key in pairs(data.points) do
					if key.relativeTo == 'Frame' then
						element:SetPoint(key.anchor, frame, key.anchor, key.x, key.y)
					else
						element:SetPoint(key.anchor, frame[key.relativeTo], key.anchor, key.x, key.y)
					end
				end
			else
				element:SetAllPoints(frame)
			end
		elseif data.position.anchor then
			if data.position.relativeTo == 'Frame' then
				element:SetPoint(data.position.anchor, frame, data.position.relativePoint or data.position.anchor, data.position.x, data.position.y)
			else
				element:SetPoint(data.position.anchor, frame[data.position.relativeTo], data.position.relativePoint or data.position.anchor, data.position.x, data.position.y)
			end
		end

		--Size it if we have a size change function for the element
		if element and data.enabled then
			element:ClearAllPoints()
			element:SetPoint(data.position.anchor, frame, data.position.relativePoint, data.position.x, data.position.y)

			--Size it if we have a size change function for the element
			if element.SizeChange then
				element:SizeChange()
			elseif data.size then
				element:SetSize(data.size, data.size)
			else
				element:SetSize(data.width or frame:GetWidth(), data.height or frame:GetHeight())
			end
		end

		-- Call the elements update function
		if frame[elementName] and data.enabled and frame[elementName].ForceUpdate then frame[elementName].ForceUpdate(element) end
	end

	-- Power
	frame.Power:ClearAllPoints()
	if elements.Health.enabled then
		frame.Power:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
	else
		frame.Power:SetPoint('BOTTOM', frame)
	end
	-- Castbar
	frame.Castbar:ClearAllPoints()
	if elements.Power.enabled then
		frame.Castbar:SetPoint('TOP', frame.Power, 'BOTTOM', 0, 0)
	elseif elements.Health.enabled then
		frame.Castbar:SetPoint('TOP', frame.Health, 'BOTTOM', 0, 0)
	else
		frame.Castbar:SetPoint('BOTTOM', frame)
	end
end

local PlayerPowerIcons = function(frame, attachPoint)
	--Runes
	if select(2, UnitClass('player')) == 'DEATHKNIGHT' then
		frame.Runes = {}
		frame.Runes.colorSpec = true

		for i = 1, 6 do
			frame.Runes[i] = CreateFrame('StatusBar', frame:GetName() .. '_Runes' .. i, frame)
			frame.Runes[i]:SetSize((frame.Health:GetWidth() - 10) / 6, 4)
			if i == 1 then
				frame.Runes[i]:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, 0)
			else
				frame.Runes[i]:SetPoint('TOPLEFT', frame.Runes[i - 1], 'TOPRIGHT', 2, 0)
			end
			frame.Runes[i]:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2')
			frame.Runes[i]:SetStatusBarColor(0, 0.39, 0.63, 1)

			frame.Runes[i].bg = frame.Runes[i]:CreateTexture(nil, 'BORDER')
			frame.Runes[i].bg:SetPoint('TOPLEFT', frame.Runes[i], 'TOPLEFT', -0, 0)
			frame.Runes[i].bg:SetPoint('BOTTOMRIGHT', frame.Runes[i], 'BOTTOMRIGHT', 0, -0)
			frame.Runes[i].bg:SetTexture('Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2')
			frame.Runes[i].bg:SetVertexColor(0, 0, 0, 1)
			frame.Runes[i].bg.multiplier = 0.64
			frame.Runes[i]:Hide()

			DeathKnightResourceOverlayFrame:HookScript('OnShow', function()
				DeathKnightResourceOverlayFrame:Hide()
			end)
		end
	else
		frame.ComboPoints = frame:CreateFontString(nil, 'BORDER')
		frame.ComboPoints:SetPoint('TOPLEFT', frame[attachPoint], 'BOTTOMLEFT', 0, -2)
		local MaxPower, ClassPower = 5, {}

		if select(2, UnitClass('player')) == 'MONK' then MaxPower = 6 end

		for index = 1, MaxPower do
			local Bar = CreateFrame('StatusBar', nil, frame)
			Bar:SetStatusBarTexture('Interface\\AddOns\\SpartanUI\\images\\statusbars\\Smoothv2')

			-- Position and size.
			Bar:SetSize(((frame.Health:GetWidth() - 10) / MaxPower), 6)
			if index == 1 then
				Bar:SetPoint('TOPLEFT', frame.ComboPoints, 'TOPLEFT')
			else
				Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', 2, 0)
			end
			Bar:Hide()

			ClassPower[index] = Bar
		end

		-- Register with oUF
		frame.ClassPower = ClassPower
	end
end

local NamePlateFactory = function(frame, unit)
	---#TODO: Cleanup the nameplate factory
	if unit:match('nameplate') then
		local blizzPlate = frame:GetParent().UnitFrame
		if blizzPlate then
			frame.blizzPlate = blizzPlate
			frame.widget = blizzPlate.WidgetContainer
		end

		frame.unitGUID = UnitGUID(unit)
		frame.unitOnCreate = 'Nameplate'
		frame.npcID = frame.unitGUID and select(6, strsplit('-', frame.unitGUID))

		local elementsDB = module.DB.elements
		local height = 0
		if elementsDB.Health.enabled then height = height + elementsDB.Health.height end
		if elementsDB.Power.enabled then height = height + elementsDB.Power.height end
		if elementsDB.Castbar.enabled then height = height + elementsDB.Castbar.height end

		frame:SetSize(module.DB.width, height)
		frame:SetPoint('CENTER', 0, 0)

		frame.raised = CreateFrame('Frame', nil, frame)
		local level = frame:GetFrameLevel() + 100
		frame.raised:SetFrameLevel(level)
		frame.raised.__owner = frame

		frame.bg = {}
		frame.bg.artwork = {}
		frame.bg.solid = frame:CreateTexture(nil, 'BACKGROUND')
		frame.bg.solid:SetAllPoints()
		frame.bg.solid:SetTexture(BarTexture)
		frame.bg.solid:SetVertexColor(0, 0, 0, 0.5)

		frame.bg.artwork.Neutral = frame:CreateTexture(nil, 'BACKGROUND')
		frame.bg.artwork.Neutral:SetAllPoints()
		frame.bg.artwork.Neutral:SetTexture(BarTexture)
		frame.bg.artwork.Neutral:SetVertexColor(0, 0, 0, 0.6)

		frame.bg.artwork.Alliance = frame:CreateTexture(nil, 'BACKGROUND')
		frame.bg.artwork.Alliance:SetAllPoints()
		frame.bg.artwork.Alliance:SetTexture(Images.Alliance.bg.Texture)
		frame.bg.artwork.Alliance:SetTexCoord(unpack(Images.Alliance.bg.Coords))
		frame.bg.artwork.Alliance:SetSize(frame:GetSize())

		frame.bg.artwork.Horde = frame:CreateTexture(nil, 'BACKGROUND')
		frame.bg.artwork.Horde:SetAllPoints()
		frame.bg.artwork.Horde:SetTexture(Images.Horde.bg.Texture)
		frame.bg.artwork.Horde:SetTexCoord(unpack(Images.Horde.bg.Coords))
		frame.bg.artwork.Horde:SetSize(frame:GetSize())

		-- Name
		local nameString = ''
		if module.DB.ShowLevel then nameString = '[difficulty][level]' end
		if module.DB.ShowName then nameString = nameString .. ' [SUI_ColorClass][name]' end
		if nameString ~= '' then
			frame.Name = frame:CreateFontString(nil, 'OVERLAY')
			SUI.Font:Format(frame.Name, 8, 'Nameplate')
			frame.Name:SetSize(frame:GetWidth(), 9)
			frame.Name:SetJustifyH(elementsDB.Name.SetJustifyH)
			frame.Name:SetPoint('BOTTOM', frame, 'TOP')
			frame:Tag(frame.Name, nameString)
		end

		-- health bar
		BuildElement(frame, 'ThreatIndicator')
		BuildElement(frame, 'RaidTargetIndicator')
		BuildElement(frame, 'ClassIcon')
		BuildElement(frame, 'QuestMob')
		BuildElement(frame, 'PvPRoleIndicator')

		BuildElement(frame, 'Health')
		BuildElement(frame, 'Power')
		frame.Power:SetWidth(module.DB.width)
		BuildElement(frame, 'Castbar')
		frame.Castbar:SetWidth(module.DB.width)

		BuildElement(frame, 'TargetIndicator')
		BuildElement(frame, 'WidgetXPBar')

		BuildElement(frame, 'PvPIndicator')
		frame.PvPIndicator.Override = function(self, event, unit)
			if unit ~= self.unit then return end
			local factionColor = {
				['Alliance'] = { 0, 0, 1, 0.3 },
				['Horde'] = { 1, 0, 0, 0.3 },
				['Neutral'] = { 0, 0, 0, 0.5 },
			}
			local settings = module.DB.elements
			self.bg.solid:Hide()
			self.bg.artwork.Neutral:Hide()
			self.bg.artwork.Alliance:Hide()
			self.bg.artwork.Horde:Hide()

			if not settings.Background.enabled then return end

			local factionGroup = UnitFactionGroup(unit) or 'Neutral'
			if settings.Background.type == 'solid' then
				self.bg.solid:Show()
				if settings.Background.colorMode == 'faction' and factionGroup then
					self.bg.solid:SetVertexColor(unpack(factionColor[factionGroup]))
				elseif settings.Background.colorMode == 'reaction' then
					local colors = SUIUF.colors.reaction[UnitReaction(unit, 'player')]
					if colors then
						if colors[1] == 0.9 and colors[2] == 0.7 then
							self.bg.solid:SetVertexColor(0.5, 0.5, 0.5, 0.5)
						else
							self.bg.solid:SetVertexColor(colors[1], colors[2], colors[3])
						end
					else
						self.bg.solid:SetVertexColor(0, 0, 0)
					end
				else
					self.bg.solid:SetVertexColor(0, 0, 0)
				end
				self.bg.solid:SetAlpha(settings.Background.alpha)
			else
				if factionGroup then
					self.bg.artwork[factionGroup]:Show()
					self.bg.artwork[factionGroup]:SetAlpha(settings.Background.alpha)
				else
					self.bg.artwork.Neutral:Show()
					self.bg.artwork.Neutral:SetAlpha(settings.Background.alpha)
				end
			end
		end

		-- Hots/Dots
		local Auras = CreateFrame('Frame', unit .. 'Auras', frame)
		Auras:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, 2)
		Auras:SetSize(frame:GetWidth(), 16)
		if UnitReaction(unit, 'player') <= 2 then
			if module.DB.onlyShowPlayer and module.DB.showStealableBuffs then
				Auras.showStealableBuffs = module.DB.showStealableBuffs
			else
				Auras.onlyShowPlayer = module.DB.onlyShowPlayer
				Auras.showStealableBuffs = module.DB.showStealableBuffs
			end
		else
			Auras.onlyShowPlayer = module.DB.onlyShowPlayer
		end

		frame.Auras = Auras

		-- Rare Elite indicator
		local RareElite = frame:CreateTexture(nil, 'BACKGROUND', nil, -2)
		RareElite:SetTexture('Interface\\Addons\\SpartanUI\\Images\\status-glow')
		RareElite:SetAlpha(0.6)
		RareElite:SetAllPoints(frame)
		frame.RareElite = RareElite

		-- WidgetXPBar
		if SUI.IsRetail then
			local WidgetXPBar = CreateFrame('StatusBar', frame:GetDebugName() .. 'WidgetXPBar', frame)
			-- WidgetXPBar:SetFrameStrata(frame:GetFrameStrata())
			WidgetXPBar:SetFrameLevel(5)
			WidgetXPBar:SetStatusBarTexture(BarTexture)
			WidgetXPBar:SetSize(frame:GetWidth(), elementsDB.XPBar.height)
			WidgetXPBar:SetPoint('TOP', frame, 'BOTTOM', 0, elementsDB.XPBar.Offset)
			WidgetXPBar:SetStatusBarColor(0, 0.5, 1, 0.7)

			WidgetXPBar.bg = WidgetXPBar:CreateTexture(nil, 'BACKGROUND')
			WidgetXPBar.bg:SetAllPoints()
			WidgetXPBar.bg:SetTexture(BarTexture)
			WidgetXPBar.bg:SetVertexColor(0, 0, 0, 0.5)

			WidgetXPBar.Rank = WidgetXPBar:CreateFontString()
			WidgetXPBar.Rank:SetJustifyH('LEFT')
			WidgetXPBar.Rank:SetJustifyV('MIDDLE')
			WidgetXPBar.Rank:SetAllPoints(WidgetXPBar)
			SUI.Font:Format(WidgetXPBar.Rank, 7, 'Nameplate')

			WidgetXPBar.ProgressText = WidgetXPBar:CreateFontString()
			WidgetXPBar.ProgressText:SetJustifyH('CENTER')
			WidgetXPBar.ProgressText:SetJustifyV('MIDDLE')
			WidgetXPBar.ProgressText:SetAllPoints(WidgetXPBar)
			SUI.Font:Format(WidgetXPBar.ProgressText, 7, 'Nameplate')

			frame.WidgetXPBar = WidgetXPBar
		end

		-- Setup Player Icons
		if module.DB.ShowPlayerPowerIcons then
			local attachPoint = 'Castbar'
			if not elementsDB.Castbar.enabled then
				if elementsDB.Power.enabled then
					attachPoint = 'Power'
				else
					attachPoint = 'Health'
				end
			end

			PlayerPowerIcons(frame, attachPoint)
		end

		-- Setup Scale
		frame:SetScale(module.DB.Scale)
	end
end

local NameplateCallback = function(self, event, unit)
	if not self or not unit or event == 'NAME_PLATE_UNIT_REMOVED' then return end

	self.ShowWidgetOnly = UnitNameplateShowsWidgetsOnly(unit)

	local elementDB = module.DB.elements
	if event == 'NAME_PLATE_UNIT_ADDED' then
		local blizzPlate = self:GetParent().UnitFrame
		if blizzPlate then
			self.blizzPlate = blizzPlate
			self.widget = blizzPlate.WidgetContainer
		end
		self.unitGUID = UnitGUID(unit)
		self.npcID = self.unitGUID and select(6, strsplit('-', self.unitGUID))

		NameplateList[self:GetName()] = true

		self:UpdateAllElements('ForceUpdate')

		if self.ShowWidgetOnly then
			for _, element in ipairs(ElementList) do
				if self:IsElementEnabled(element) then
					self:DisableElement(element)
					if self[element] then self[element]:Hide() end
				end
			end

			self.widgetContainer = self.blizzPlate.WidgetContainer
			if self.widgetContainer then
				self.widgetContainer:SetParent(self)
				self.widgetContainer:ClearAllPoints()
				self.widgetContainer:SetPoint('TOP', self, 'BOTTOM')
			end
			return
		end
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		NameplateList[self:GetName()] = false
	end

	for _, item in ipairs(ElementList) do
		if self[item] and elementDB[item].enabled then
			self:EnableElement(item)
		else
			self:DisableElement(item)
		end
	end

	for element, _ in pairs(self.elementList) do
		self[element].DB = elementDB[element]
		UF.Elements:Update(self, element, elementDB[element])
	end

	-- Update elements
	UpdateElementState(self)

	-- Update Player Icons
	if UnitIsUnit(unit, 'player') and event == 'NAME_PLATE_UNIT_ADDED' then
		if self.Runes then
			self:EnableElement('Runes')
			self.Runes:ForceUpdate()
		elseif self.ClassPower then
			self:EnableElement('ClassPower')
			self.ClassPower:ForceUpdate()
		end
	else
		if self.Runes then
			self:DisableElement('Runes')
		elseif self.ClassPower then
			self:DisableElement('ClassPower')
		end
	end

	-- Set the Scale of the nameplate
	self:SetScale(module.DB.Scale)
end

function module:UpdateNameplates()
	for k, v in pairs(NameplateList) do
		if v then UpdateElementState(_G[k]) end
	end
end

function module:OnInitialize()
	---#TODO: convert to new element settings process
	---@class SUI.NamePlates.Settings
	local defaults = {
		ShowName = true,
		ShowLevel = true,
		ShowTarget = true,
		onlyShowPlayer = true,
		showStealableBuffs = false,
		Scale = 1,
		width = 128,
		elements = {
			['**'] = {
				enabled = false,
				Scale = 1,
				points = false,
				alpha = 1,
				scale = 1,
				FrameLevel = nil,
				FrameStrata = nil,
				bg = {
					enabled = false,
					color = false,
				},
				text = {
					['**'] = {
						enabled = false,
						text = '',
						size = 10,
						SetJustifyH = 'CENTER',
						SetJustifyV = 'MIDDLE',
						position = {
							anchor = 'CENTER',
							x = 0,
							y = 0,
						},
					},
					['1'] = {
						enabled = false,
						position = {},
					},
					['2'] = {
						enabled = false,
						position = {},
					},
				},
				position = {
					anchor = 'CENTER',
					x = 0,
					y = 0,
				},
			},
			Auras = {},
			Background = {
				type = 'solid',
				colorMode = 'reaction',
				alpha = 0.35,
			},
			DispelHighlight = {},
			RareElite = {},
			Name = {
				SetJustifyH = 'CENTER',
			},
			Health = {
				enabled = true,
				height = 8,
				offset = 0,
				texture = 'SpartanUI Default',
				colorReaction = true,
				colorSmooth = true,
				colorClass = true,
				colorTapping = true,
				colorDisconnected = true,
				bg = {
					enabled = true,
					color = { 1, 1, 1, 0.3 },
				},
				text = {
					['1'] = {
						enabled = true,
						size = 5,
						text = '[SUIHealth(percentage,hideMax)]',
						position = {
							anchor = 'CENTER',
							x = 0,
							y = 0,
						},
					},
				},
			},
			Power = {
				enabled = false,
				height = 3,
				offset = 1,
				texture = 'SpartanUI Default',
				bg = {
					enabled = true,
					color = { 1, 1, 1, 0.2 },
				},
				text = {
					['1'] = {
						enabled = false,
						text = '[power:current-formatted] / [power:max-formatted]',
					},
					['2'] = {
						enabled = false,
						text = '[perpp]%',
					},
				},
			},
			PvPIndicator = {
				size = 10,
			},
			ThreatIndicator = {},
			Castbar = {
				enabled = true,
				width = false,
				height = 5,
				offset = -6,
				interruptable = true,
				FlashOnInterruptible = true,
				latency = false,
				InterruptSpeed = 0.1,
				texture = 'SpartanUI Default',
				bg = {
					enabled = true,
					color = { 1, 1, 1, 0.2 },
				},
				Icon = {
					enabled = false,
					size = 12,
					position = {
						anchor = 'LEFT',
						x = 0,
						y = 0,
					},
				},
				text = {
					['1'] = {
						enabled = true,
						text = '[Spell name]',
						position = {
							anchor = 'CENTER',
							x = 0,
							y = 0,
						},
					},
					['2'] = {
						enabled = true,
						text = '[Spell timer]',
						size = 8,
						position = {
							anchor = 'RIGHT',
							x = 0,
							y = 0,
						},
					},
				},
			},
			ClassIcon = {
				enabled = false,
				size = 20,
				VisibleOn = 'PlayerControlled',
				position = {
					anchor = 'TOP',
					x = 0,
					y = 40,
				},
			},
			RaidTargetIndicator = {
				enabled = true,
				size = 15,
				position = {
					anchor = 'BOTTOMRIGHT',
					x = 0,
					y = 0,
				},
			},
			QuestMob = {
				enabled = true,
				size = 16,
				position = {
					anchor = 'RIGHT',
					relativePoint = 'LEFT',
					x = 0,
					y = 0,
				},
			},
			XPBar = {
				height = 5,
				Offset = -10,
			},
			PvPRoleIndicator = {
				enabled = true,
				size = 20,
				position = {
					anchor = 'BOTTOM',
					relativeTo = 'Name',
					relativePoint = 'TOP',
					x = 0,
					y = 7,
				},
				['**'] = {
					display = true,
				},
				friendly = {
					display = true,
					alertonDamage = false,
					damageThreshold = 10000,
				},
				enemy = {},
			},
		},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Nameplates', { profile = defaults })
	module.DB = module.Database.profile ---@type SUI.NamePlates.Settings

	-- Migrate old settings
	if SUI.DB.Nameplates then
		print('Nameplate DB Migration')
		module.DB = SUI:MergeData(module.DB, SUI.DB.Nameplates, true)
		SUI.DB.Nameplates = nil
	end

	SUIUF:RegisterStyle('Spartan_NamePlates', NamePlateFactory)
end

function module:OnDisable()
	SUI.opt.args.Modules.args.Nameplates.enabled = false
end

function module:OnEnable()
	module:BuildOptions()
	if SUI:IsModuleDisabled('Nameplates') then return end

	if not oUF_NamePlateDriver then
		SUIUF:SetActiveStyle('Spartan_NamePlates')
		SUIUF:SpawnNamePlates(nil, NameplateCallback)

		-- oUF is not hiding the mana bar. So we need to hide it.
		if ClassNameplateManaBarFrame then ClassNameplateManaBarFrame:HookScript('OnShow', function()
			ClassNameplateManaBarFrame:Hide()
		end) end
	end

	--Make sure we start fresh
	CurrentSettings = {}
	for _, v in ipairs(ElementList) do
		--Import base options
		CurrentSettings[v] = SUI:CopyData(ElementDefaults[v], SUI.UF.Elements:GetConfig(v))
		--Import User settings
		SUI:CopyData(CurrentSettings[v], module.DB[v] or {})
	end
end

function module:BuildOptions()
	local Options = UF.Options
	---#TODO: update to new element options process
	local function toInt(val)
		if val then return 1 end
		return 0
	end
	local function toBool(val)
		if tonumber(val) == 1 then
			return true
		else
			return false
		end
	end

	---@type AceConfig.OptionsTable
	local OptSet = Options:CreateFrameOptionSet(L['Nameplates'], function(info)
		return module.DB[info[#info]]
	end, function(info, val)
		module.DB[info[#info]] = val
		module:UpdateNameplates()
	end)
	OptSet.disabled = function()
		return SUI:IsModuleDisabled(module)
	end
	OptSet.args.ShowFrame.hidden = true
	OptSet.args.General.args.Display = {
		name = L.Display,
		type = 'group',
		order = 1,
		args = {
			width = {
				name = L['Frame width'],
				type = 'input',
				order = 1,
			},
			Scale = {
				name = L['Scale'],
				type = 'range',
				width = 'full',
				min = 0.01,
				max = 3,
				step = 0.01,
				order = 2,
			},
		},
	}
	OptSet.args.General.args.Blizzard = {
		name = L['Blizzard display options'],
		type = 'group',
		args = {
			nameplateShowAll = {
				name = UNIT_NAMEPLATES_AUTOMODE,
				desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_AUTOMODE,
				type = 'toggle',
				width = 'double',
				get = function(info)
					return toBool(GetCVar('nameplateShowAll'))
				end,
				set = function(info, val)
					SetCVar('nameplateShowAll', toInt(val))
				end,
			},
			nameplateShowSelf = {
				name = DISPLAY_PERSONAL_RESOURCE,
				desc = OPTION_TOOLTIP_UNIT_NAMEPLATES_AUTOMODE,
				type = 'toggle',
				width = 'double',
				get = function(info)
					return toBool(GetCVar('nameplateShowSelf'))
				end,
				set = function(info, val)
					SetCVar('nameplateShowSelf', toInt(val))
				end,
			},
			nameplateMotion = {
				name = UNIT_NAMEPLATES_TYPES,
				desc = function(info)
					if GetCVar('nameplateMotion') == '1' then
						return UNIT_NAMEPLATES_TYPE_TOOLTIP_2
					else
						return UNIT_NAMEPLATES_TYPE_TOOLTIP_1
					end
				end,
				type = 'select',
				values = { ['1'] = UNIT_NAMEPLATES_TYPE_2, ['0'] = UNIT_NAMEPLATES_TYPE_1 },
				get = function(info)
					return GetCVar('nameplateMotion')
				end,
				set = function(info, val)
					SetCVar('nameplateMotion', tonumber(val))
				end,
			},
		},
	}

	-- ---@type AceConfig.OptionsTable
	-- local OptSet = {
	-- 	args = {
	-- 		Indicator = {
	-- 			name = L['Indicators'],
	-- 			type = 'group',
	-- 			order = 20,
	-- 			childGroups = 'tree',
	-- 			args = {
	-- 				Name = {
	-- 					name = L['Name'],
	-- 					type = 'group',
	-- 					order = 1,
	-- 					args = {
	-- 						ShowLevel = {
	-- 							name = L['Show level'],
	-- 							type = 'toggle',
	-- 							order = 1,
	-- 							get = function(info)
	-- 								return module.DB.ShowLevel
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.ShowLevel = val
	-- 							end
	-- 						},
	-- 						ShowName = {
	-- 							name = L['Show name'],
	-- 							type = 'toggle',
	-- 							order = 2,
	-- 							get = function(info)
	-- 								return module.DB.elements.Name.enabled
	-- 							end,
	-- 							set = function(info, val)
	-- 								--Update the DB
	-- 								module.DB.elements.Name.enabled = val
	-- 							end
	-- 						},
	-- 						JustifyH = {
	-- 							name = L['Horizontal alignment'],
	-- 							type = 'select',
	-- 							order = 3,
	-- 							values = {
	-- 								['LEFT'] = 'Left',
	-- 								['CENTER'] = 'Center',
	-- 								['RIGHT'] = 'Right'
	-- 							},
	-- 							get = function(info)
	-- 								return module.DB.elements.Name.SetJustifyH
	-- 							end,
	-- 							set = function(info, val)
	-- 								--Update the DB
	-- 								module.DB.elements.Name.SetJustifyH = val
	-- 								--Update the screen
	-- 								-- module.frames[frameName][key]:SetJustifyH(val)
	-- 							end
	-- 						}
	-- 					}
	-- 				},
	-- 				Auras = {
	-- 					name = L['Auras'],
	-- 					type = 'group',
	-- 					args = {
	-- 						enabled = {
	-- 							name = L['Enabled'],
	-- 							type = 'toggle',
	-- 							order = 1,
	-- 							width = 'double',
	-- 							get = function(info)
	-- 								return module.DB.elements.Auras.enabled
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.elements.Auras.enabled = val
	-- 								module:UpdateNameplates()
	-- 							end
	-- 						},
	-- 						onlyShowPlayer = {
	-- 							name = L['Show only auras created by player'],
	-- 							type = 'toggle',
	-- 							order = 2,
	-- 							width = 'double',
	-- 							get = function(info)
	-- 								return module.DB.onlyShowPlayer
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.onlyShowPlayer = val
	-- 								module:UpdateNameplates()
	-- 							end
	-- 						},
	-- 						showStealableBuffs = {
	-- 							name = L['Show Stealable/Dispellable buffs'],
	-- 							type = 'toggle',
	-- 							order = 3,
	-- 							width = 'double',
	-- 							get = function(info)
	-- 								return module.DB.showStealableBuffs
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.showStealableBuffs = val
	-- 								module:UpdateNameplates()
	-- 							end
	-- 						},
	-- 						notice = {
	-- 							name = L['With both of these options active your DOTs will not appear on enemies.'],
	-- 							type = 'description',
	-- 							order = 4,
	-- 							fontSize = 'small'
	-- 						}
	-- 					}
	-- 				},
	-- 				XPBar = {
	-- 					name = L['XP Bar'],
	-- 					type = 'group',
	-- 					args = {
	-- 						enabled = {
	-- 							name = L['Enabled'],
	-- 							type = 'toggle',
	-- 							width = 'full',
	-- 							order = 1,
	-- 							get = function(info)
	-- 								return module.DB.elements.XPBar.enabled
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.elements.XPBar.enabled = val
	-- 							end
	-- 						},
	-- 						size = {
	-- 							name = L['Size'],
	-- 							type = 'range',
	-- 							order = 2,
	-- 							min = 1,
	-- 							max = 30,
	-- 							step = 1,
	-- 							get = function(info)
	-- 								return module.DB.elements.XPBar.size
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.elements.XPBar.size = val
	-- 							end
	-- 						},
	-- 						Offset = {
	-- 							name = L['Offset'],
	-- 							type = 'range',
	-- 							order = 3,
	-- 							min = -30,
	-- 							max = 30,
	-- 							step = .5,
	-- 							get = function(info)
	-- 								return module.DB.elements.XPBar.Offset
	-- 							end,
	-- 							set = function(info, val)
	-- 								module.DB.elements.XPBar.Offset = val
	-- 							end
	-- 						}
	-- 					}
	-- 				}
	-- 			}
	-- 		},
	-- 	}
	-- }

	for _, elementName in ipairs(ElementList) do
		local config = UF.Elements:GetConfig(elementName).config

		--TODO: Right now these are the same, but in the future they will not be
		local ElementSettings = module.DB.elements[elementName]
		local UserSetting = module.DB.elements[elementName]

		---@type AceConfig.OptionsTable
		local ElementOptSet = {
			name = config.DisplayName and L[config.DisplayName] or elementName,
			desc = config.Description or '',
			type = 'group',
			order = 1,
			get = function(info)
				return ElementSettings[info[#info]] or false
			end,
			set = function(info, val)
				--Update memory
				ElementSettings[info[#info]] = val
				--Update the DB
				UserSetting[info[#info]] = val
				-- TODO: Update the frame
			end,
			args = {},
		}

		local PositionGet = function(info)
			return ElementSettings.position[info[#info]]
		end
		local PositionSet = function(info, val)
			if val == elementName then
				SUI:Print(L['Cannot set position to self'])
				return
			end
			--Update memory
			ElementSettings.position[info[#info]] = val
			--Update the DB
			UserSetting.position[info[#info]] = val
			-- TODO: Update the frame
		end

		if config.type == 'General' then
		elseif config.type == 'StatusBar' then
			-- TODO
			-- Options:StatusBarDefaults(frameName, ElementOptSet, elementName)
		elseif config.type == 'Indicator' then
			Options:IndicatorAddDisplay(ElementOptSet)
			Options:AddPositioning(ElementList, ElementOptSet, PositionGet, PositionSet)
		elseif config.type == 'Text' then
			--TODO
		elseif config.type == 'Auras' then
			--TODO
		end

		-- local Opt = OptSet.args[config.type].args[elementName]
		-- if Opt then
		-- 	if config.type == 'StatusBar' then
		-- 		-- SUI.UF.Options:StatusBarDefaults('Nameplate', Opt, elementName)
		-- 	elseif config.type == 'Indicator' then
		-- 		SUI.UF.Options:IndicatorAddDisplay(Opt)
		-- 		SUI.UF.Options:AddPositioning(ElementList, Opt, PositionGet, PositionSet)
		-- 	end
		-- else
		-- 	print(elementName)
		-- end

		--Call Elements Custom function
		-- UF.Elements:Options('Nameplates', elementName, ElementOptSet, ElementSettings)

		if not ElementOptSet.args.enabled then
			--Add a disable check to all args
			for k, v in pairs(ElementOptSet.args) do
				v.disabled = function()
					return not ElementSettings.enabled
				end
			end

			ElementOptSet.args.enabled = {
				name = L['Enabled'],
				type = 'toggle',
				order = 1,
			}
		end
		-- Add element option to screen
		OptSet.args[config.type].args[elementName] = ElementOptSet
	end

	SUI.opt.args.Modules.args.Nameplates = OptSet
end
