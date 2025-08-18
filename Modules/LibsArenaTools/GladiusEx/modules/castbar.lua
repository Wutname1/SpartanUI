local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")
local LSM = LibStub("LibSharedMedia-3.0")

-- global functions
local strfind, strformat = string.find, string.format
local pairs = pairs
local min = math.min
local GetTime = GetTime
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture

local time_text_format_normal = "%.01f "
local time_text_format_delay = "+%.01f %.01f "

local defaults = {
		castBarOffsetX = -20,
		castBarOffsetY = -5,
		castBarWidth = 175,
		castBarHeight = 20,
		castBarInverse = false,
		castBarColor = { r = 1, g = 1, b = 0, a = 1 },
		castBarNotIntColor = { r = 1, g = 0, b = 0, a = 1 },
		castBarBackgroundColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.3 },
		castBarBackgroundHideWhenNotCasting = false,
		castBarGlobalTexture = true,
		castBarTexture = GladiusEx.default_bar_texture,
		castIcon = true,
		castSpark = true,
		castShieldIcon = true,
		castIconPosition = "LEFT",
		castIconOffsetX = -10,
		castIconOffsetY = 0,
		castText = true,
		castTextGlobalFontSize = true,
		castTextSize = 11,
		castTextColor = { r = 1, g = 1, b = 1, a = 1 },
		castTextAlign = "LEFT",
		castTextOffsetX = 2,
		castTextOffsetY = 0,
		castTimeText = true,
		castTimeTextCastTime = true,
		castTimeTextRemainingTime = true,
		castTimeTextTotalTime = false,
		castTimeTextDelay = true,
		castTimeTextGlobalFontSize = true,
		castTimeTextSize = 11,
		castTimeTextColor = { r = 1, g = 1, b = 1, a = 1 },
		castTimeTextAlign = "RIGHT",
		castTimeTextOffsetX = 0,
		castTimeTextOffsetY = 0,
}

local CastBar = GladiusEx:NewGladiusExModule("CastBar",
	fn.merge(defaults, {
    castBarAttachMode = "Widget",
		castBarAttachTo = "Frame",
		castBarRelativePoint = "BOTTOMLEFT",
		castBarAnchor = "TOPLEFT",
		castBarPosition = "BOTTOMLEFT",

		castIconPosition = "LEFT",
		castTextAlign = "LEFT",
		castTextOffsetX = 2,
		castTextOffsetY = 0,
		castTimeTextAlign = "RIGHT",
		castTimeTextOffsetX = -2,
		castTimeTextOffsetY = 0,
	}),
	fn.merge(defaults, {
		castBarAttachMode = "InFrame",
		castBarAttachTo = "Frame",
		castBarRelativePoint = "BOTTOMLEFT",
		castBarAnchor = "TOPRIGHT",
		castBarPosition = "BOTTOM",

		castIconPosition = "RIGHT",
		castTextAlign = "RIGHT",
		castTextOffsetX = -2,
		castTextOffsetY = 0,
		castTimeTextAlign = "LEFT",
		castTimeTextOffsetX = 2,
		castTimeTextOffsetY = 0,
	}))

function CastBar:OnEnable()
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

	if GladiusEx.IS_RETAIL then
		self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_START")
		self:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP", "UNIT_SPELLCAST_STOP")
	end

	self:RegisterMessage("GLADIUS_INTERRUPT")

	if not self.frame then
		self.frame = {}
	end
end

function CastBar:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:Hide()
	end
end

function CastBar:GetAttachType(unit)
	return self.db[unit].castBarAttachMode
end

function CastBar:GetAttachPoint(unit)
	return self.db[unit].castBarPosition
end

function CastBar:GetAttachSize(unit)
	return self.db[unit].castBarHeight
end

function CastBar:GetModuleAttachPoints(unit)
	return {
		["CastBar"] = L["CastBar"],
	}
end

function CastBar:GetModuleAttachFrame(unit, point)
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	return self.frame[unit]
end

local function UpdateCastText(f, spell)
	f.castText:SetText(spell)
end

function CastBar:UNIT_SPELLCAST_START(event, unit)
	self:CastStart(unit, false)
end

function CastBar:UNIT_SPELLCAST_EMPOWER_START(event, unit)
	self:CastStart(unit, true)
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit)
	self:CastStart(unit, true)
end

function CastBar:UNIT_SPELLCAST_INTERRUPTIBLE(event, unit)
	self:SetInterruptible(unit, true)
end

function CastBar:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(event, unit)
	self:SetInterruptible(unit, false)
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, spell, id)
	if not self.frame[unit] then return end
	-- BfA note: if spell is nil then... idk, we need to use "id" in the future, for now always CastEnd()
	if spell and self.frame[unit].spellName ~= spell then return end
	-- channels don't have a lineID, do it the "old" way.
	if spell and event == "UNIT_SPELLCAST_FAILED" and self.frame[unit].isChanneling then return end

	self.frame[unit].lineID = nil
	self:CastEnd(self.frame[unit], self.db[unit])
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, lineID, spell)
	if not self.frame[unit] then return end

	if GladiusEx:IsValidCastGUID(lineID) then
		if self.frame[unit].lineID ~= lineID then return end
	else
		if self.frame[unit].spellName ~= spell then return end
	end
	self.frame[unit].lineID = nil
	self:CastEnd(self.frame[unit], self.db[unit])
end

function CastBar:UNIT_SPELLCAST_EMPOWER_STOP(event, unit, lineID, spell)
	if not self.frame[unit] then return end

	if GladiusEx:IsValidCastGUID(lineID) then
		if self.frame[unit].lineID ~= lineID then return end
	else
		if self.frame[unit].spellName ~= spell then return end
	end
	self.frame[unit].lineID = nil
	self:CastEnd(self.frame[unit], self.db[unit])
end

function CastBar:GLADIUS_INTERRUPT(event, unit)
	-- TODO
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit)
	if not self.frame[unit] then return end
	if not self.frame[unit].isCasting or self.frame[unit].isChanneling then return end

	local spell, displayName, icon, startTime, endTime, isTradeSkill
	if event == "UNIT_SPELLCAST_DELAYED" then
		spell, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
	else
		spell, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
	end

	if not startTime or not endTime then return end

	if event == "UNIT_SPELLCAST_DELAYED" then
		self.frame[unit].delay = self.frame[unit].delay + (startTime / 1000 - self.frame[unit].startTime)
	else
		self.frame[unit].delay = self.frame[unit].delay + (self.startTime - startTime / 1000)
	end

	self.frame[unit].startTime = startTime / 1000
	self.frame[unit].endTime = endTime / 1000
	self.frame[unit].bar:SetMinMaxValues(0, (endTime - startTime) / 1000)
end

function CastBar:SetInterruptible(unit, interruptible)
	if not self.frame[unit] then return end

	local color = interruptible and self.db[unit].castBarColor or self.db[unit].castBarNotIntColor

	self.frame[unit].bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	self.frame[unit].spark:SetVertexColor(color.r, color.g, color.b, color.a)

	if not self.db[unit].castShieldIcon or interruptible then
		self.frame[unit].icon.shield:Hide()
	else
		self.frame[unit].icon.shield:Show()
	end
end

local delay_format = " +%.01f"
local function CastUpdate(self)
	if self.isCasting or self.isChanneling then
		-- V: Sometimes, we don't receive a cast end event.
		-- that happens with some vehicles/npcs, as well as phased-out casts.
		-- Instead, we manually check if we should already have ended the cast. (delay is accounted for already)
		if GetTime() > self.endTime then
			CastBar:CastEnd(CastBar.frame[self.unit], CastBar.db[self.unit])
		else
			local currentTime = GetTime()
			local value = self.endTime - currentTime

			if (self.isChanneling and CastBar.db[self.unit].castBarInverse) or (self.isCasting and not CastBar.db[self.unit].castBarInverse) then
				value = self.endTime - self.startTime - value
			end

			self.bar:SetValue(value)

			local width = self.bar:GetWidth()
			local sparkPosition = value / self.maxValue * width
			self.spark:SetPoint("CENTER", self.bar, "LEFT", sparkPosition, 0)

			if CastBar.db[self.unit].castTimeText then
				self.timeText:SetFormattedText(self.time_text_format, value, self.maxValue - value, self.maxValue, self.delay == 0 and "" or strformat(delay_format, self.delay))
			end
		end
	else
		self:SetScript("OnUpdate", nil)
	end
end

function CastBar:CastStart(unit, channel)
	local f = self.frame[unit]
	if not f then return end

	local spell, displayName, icon, startTime, endTime, isTradeSkill, lineID, notInterruptible
	if channel then
		-- a channel doesn't have a lineID
		spell, displayName, icon, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	else
		spell, displayName, icon, startTime, endTime, isTradeSkill, lineID, notInterruptible = UnitCastingInfo(unit)
	end

	if spell then
		f.spellName = spell
		f.isChanneling = channel
		f.isCasting = not channel
		f.startTime = startTime / 1000
		f.endTime = endTime / 1000
		f.maxValue = f.endTime - f.startTime
		f.delay = 0
		f.lineID = lineID

		f.icon:SetTexture(icon)
		if self.db[unit].castBarBackgroundHideWhenNotCasting then
			f.icon.bg:Show()
			f.background:Show()
		end

		self:SetInterruptible(unit, not notInterruptible)

		f.bar:SetMinMaxValues(0, f.maxValue)

		if self.db[unit].castSpark then f.spark:Show() end
		f:SetScript("OnUpdate", CastUpdate)
		CastUpdate(f)
		UpdateCastText(f, spell)
	end
end

function CastBar:CastEnd(frame, db)
	frame.isCasting = false
	frame.isChanneling = false
	frame.timeText:SetText("")
	frame.castText:SetText("")
	frame.icon:SetTexture("")
	if db.castBarBackgroundHideWhenNotCasting then
		frame.icon.bg:Hide()
		frame.background:Hide()
	end
	frame.bar:SetValue(0)
	frame.spark:Hide()
	self:SetInterruptible(frame.unit, true)
end

function CastBar:CreateBar(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create bar + text
	self.frame[unit] = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit .. "Parent", button)
	self.frame[unit].bar = CreateFrame("STATUSBAR", "GladiusEx" .. self:GetName() .. unit .. "Bar", self.frame[unit])
	self.frame[unit].background = self.frame[unit].bar:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "Background", "BACKGROUND")
	self.frame[unit].background:SetAllPoints()
	-- self.frame[unit].castText = self.frame[unit].bar:CreateFontString("GladiusEx" .. self:GetName() .. "CastText" .. unit, "OVERLAY")
	-- self.frame[unit].timeText = self.frame[unit].bar:CreateFontString("GladiusEx" .. self:GetName() .. "TimeText" .. unit, "OVERLAY")
	self.frame[unit].textsFrame = CreateFrame("Frame", nil, self.frame[unit].bar)
	self.frame[unit].castText = GladiusEx:CreateSuperFS(self.frame[unit].textsFrame, "OVERLAY")
	self.frame[unit].timeText = GladiusEx:CreateSuperFS(self.frame[unit].textsFrame, "OVERLAY")

	self.frame[unit].icon = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. "IconFrame" .. unit, "ARTWORK")
	self.frame[unit].icon.bg = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. "IconFrameBackground" .. unit, "BACKGROUND")

	self.frame[unit].icon.shield_frame = CreateFrame("Frame", nil, self.frame[unit])
	self.frame[unit].icon.shield = self.frame[unit].icon.shield_frame:CreateTexture(nil, "OVERLAY")
	self.frame[unit].icon.shield:SetTexture([[Interface\AddOns\GladiusEx\media\shield]])

	self.frame[unit].spark = self.frame[unit].bar:CreateTexture(nil, "OVERLAY")
	self.frame[unit].spark:SetTexture([[Interface\AddOns\GladiusEx\media\spark]])
	self.frame[unit].spark:SetBlendMode("ADD")

	self.frame[unit].unit = unit
end

function CastBar:Update(unit)
	-- create cast bar
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	local bar_texture = self.db[unit].castBarGlobalTexture and LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusEx.db.base.globalBarTexture) or LSM:Fetch(LSM.MediaType.STATUSBAR, self.db[unit].castBarTexture)
	local height = self:GetAttachSize(unit)
	-- place widget
	if self.db[unit].castBarAttachMode == "Widget" then
		local parent = GladiusEx:GetAttachFrame(unit, self.db[unit].castBarAttachTo)
		local width = self.db[unit].castBarWidth
		self.frame[unit]:ClearAllPoints()
		self.frame[unit]:SetPoint(self.db[unit].castBarAnchor, parent, self.db[unit].castBarRelativePoint, self.db[unit].castBarOffsetX, self.db[unit].castBarOffsetY)
		self.frame[unit]:SetWidth(width)
		self.frame[unit]:SetHeight(height)
		self.frame[unit]:SetFrameLevel(60)
		self.frame[unit].textsFrame:SetFrameLevel(61)
	else
		self.frame[unit]:SetFrameLevel(5)
		self.frame[unit].textsFrame:SetFrameLevel(50)
	end

	-- update icon
	self.frame[unit].icon.bg:ClearAllPoints()
	self.frame[unit].icon.bg:SetPoint(self.db[unit].castIconPosition, self.frame[unit], self.db[unit].castIconPosition, self.db[unit].castIconOffsetX, self.db[unit].castIconOffsetY)
	self.frame[unit].icon.bg:SetSize(height, height)
	self.frame[unit].icon.bg:SetTexture(bar_texture)
	self.frame[unit].icon.bg:SetVertexColor(self.db[unit].castBarBackgroundColor.r, self.db[unit].castBarBackgroundColor.g,
		self.db[unit].castBarBackgroundColor.b, self.db[unit].castBarBackgroundColor.a)

	self.frame[unit].icon:SetSize(height, height)
	self.frame[unit].icon:ClearAllPoints()
	self.frame[unit].icon:SetPoint("CENTER", self.frame[unit].icon.bg, "CENTER")
	local n = 5
	self.frame[unit].icon:SetTexCoord(n / 64, 1 - n / 64, n / 64, 1 - n / 64)

	if self.db[unit].castIcon then
		self.frame[unit].icon.bg:Show()
	else
		self.frame[unit].icon:Hide()
		self.frame[unit].icon.bg:Hide()
	end
	self.frame[unit].icon:SetTexture(nil)
	self.frame[unit].icon.bg:Hide()

	-- update not interruptible shield
	self.frame[unit].icon.shield_frame:SetFrameLevel(70)
	self.frame[unit].icon.shield:SetSize(height * 64 / 20, height * 64 / 20)
	self.frame[unit].icon.shield:SetPoint("CENTER", self.frame[unit].icon, "CENTER")
	self.frame[unit].icon.shield:Hide()

	-- update bar
	self.frame[unit].bar:ClearAllPoints()
	if self.db[unit].castIcon then
		-- attach to icon
		if self.db[unit].castIconPosition == "LEFT" then
			-- self.frame[unit].bar:SetPoint("LEFT", self.frame[unit].icon, "RIGHT")
			self.frame[unit].bar:SetPoint("LEFT", height, 0)
			self.frame[unit].bar:SetPoint("RIGHT")
		else
			self.frame[unit].bar:SetPoint("LEFT")
			self.frame[unit].bar:SetPoint("RIGHT", -height, 0)
			-- self.frame[unit].bar:SetPoint("RIGHT", self.frame[unit].icon, "LEFT")
		end
	else
		-- attach to frame
		self.frame[unit].bar:SetAllPoints()
	end
	self.frame[unit].bar:SetHeight(height)
	self.frame[unit].bar:SetMinMaxValues(0, 100)
	self.frame[unit].bar:SetValue(0)
	self.frame[unit].bar:SetStatusBarTexture(bar_texture)
	self.frame[unit].bar:GetStatusBarTexture():SetHorizTile(false)
	self.frame[unit].bar:GetStatusBarTexture():SetVertTile(false)
	local color = self.db[unit].castBarColor
	self.frame[unit].bar:SetStatusBarColor(color.r, color.g, color.b, color.a)

	-- update spark
	self.frame[unit].spark:SetWidth(32)
	self.frame[unit].spark:SetHeight(height * 2)
	self.frame[unit].spark:Hide()

	-- update cast bar background
	self.frame[unit].background:SetTexture(bar_texture)
	self.frame[unit].background:SetVertexColor(self.db[unit].castBarBackgroundColor.r, self.db[unit].castBarBackgroundColor.g,
		self.db[unit].castBarBackgroundColor.b, self.db[unit].castBarBackgroundColor.a)

	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
	self.frame[unit].background:SetVertTile(false)

	-- update cast text
	if self.db[unit].castText then
		self.frame[unit].castText:Show()
	else
		self.frame[unit].castText:Hide()
	end

	self.frame[unit].castText:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusEx.db.base.globalFont),
		self.db[unit].castTextGlobalFontSize and GladiusEx.db.base.globalFontSize or self.db[unit].castTextSize,
		GladiusEx.db.base.globalFontOutline)

	local color = self.db[unit].castTextColor
	self.frame[unit].castText:SetTextColor(color.r, color.g, color.b, color.a)

	local function invpos(position) return (position == "LEFT" and "RIGHT") or (position == "RIGHT" and "LEFT") end
	self.frame[unit].castText:SetShadowOffset(1, -1)
	self.frame[unit].castText:SetShadowColor(GladiusEx.db.base.globalFontShadowColor.r, GladiusEx.db.base.globalFontShadowColor.g, GladiusEx.db.base.globalFontShadowColor.b, GladiusEx.db.base.globalFontShadowColor.a)
	self.frame[unit].castText:SetJustifyH(self.db[unit].castTextAlign)
	self.frame[unit].castText:ClearAllPoints()
	self.frame[unit].castText:SetPoint(self.db[unit].castTextAlign, self.frame[unit].bar, self.db[unit].castTextAlign, self.db[unit].castTextOffsetX, self.db[unit].castTextOffsetY)
	if invpos(self.db[unit].castTextAlign) then
		self.frame[unit].castText:SetPoint(invpos(self.db[unit].castTextAlign), self.frame[unit].bar, invpos(self.db[unit].castTextAlign), 0, 0)
	end
	self.frame[unit].castText:SetWordWrap(false)

	-- update cast time text
	if self.db[unit].castTimeText then
		self.frame[unit].timeText:Show()
	else
		self.frame[unit].timeText:Hide()
	end

	self.frame[unit].timeText:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusEx.db.base.globalFont),
		self.db[unit].castTimeTextGlobalFontSize and GladiusEx.db.base.globalFontSize or self.db[unit].castTimeTextSize,
		GladiusEx.db.base.globalFontOutline)
	local color = self.db[unit].castTimeTextColor
	self.frame[unit].timeText:SetTextColor(color.r, color.g, color.b, color.a)
	self.frame[unit].timeText:SetShadowOffset(1, -1)
	self.frame[unit].timeText:SetShadowColor(GladiusEx.db.base.globalFontShadowColor.r, GladiusEx.db.base.globalFontShadowColor.g, GladiusEx.db.base.globalFontShadowColor.b, GladiusEx.db.base.globalFontShadowColor.a)
	self.frame[unit].timeText:SetJustifyH(self.db[unit].castTimeTextAlign)
	self.frame[unit].timeText:ClearAllPoints()
	self.frame[unit].timeText:SetPoint(self.db[unit].castTimeTextAlign, self.frame[unit].bar, self.db[unit].castTimeTextAlign, self.db[unit].castTimeTextOffsetX, self.db[unit].castTimeTextOffsetY)
	if invpos(self.db[unit].castTimeTextAlign) then
		self.frame[unit].timeText:SetPoint(invpos(self.db[unit].castTimeTextAlign), self.frame[unit].bar, invpos(self.db[unit].castTimeTextAlign), 0, 0)
	end
	self.frame[unit].timeText:SetWordWrap(false)

	-- time text format
	local fmt
	if self.db[unit].castTimeTextCastTime then
		if self.db[unit].castTimeTextRemainingTime then
			fmt = "%2$.01f"
		else
			fmt = "%1$.01f"
		end
		if self.db[unit].castTimeTextTotalTime then
			fmt = fmt .. "/"
		end
	end
	if self.db[unit].castTimeTextTotalTime then
		fmt = (fmt or "")  .. "%3$.01f"
	end
	if self.db[unit].castTimeTextDelay then
		fmt = (fmt or "") .. "%4$s"
	end

	self.frame[unit].time_text_format = fmt

	-- hide
	self.frame[unit]:Hide()

	if self.db[unit].castBarBackgroundHideWhenNotCasting then
		self.frame[unit].icon.bg:Hide()
		self.frame[unit].background:Hide()
	else
		self.frame[unit].icon.bg:Show()
		self.frame[unit].background:Show()
	end
end

function CastBar:Show(unit)
	-- show frame
	self.frame[unit]:Show()
end

function CastBar:Reset(unit)
	if not self.frame[unit] then return end

	self:CastEnd(self.frame[unit], self.db[unit])

	-- hide
	self.frame[unit]:Hide()
end

function CastBar:Test(unit)
	local f = self.frame[unit]

	if GladiusEx.testing[unit].powerType == 0 then
		local spell, displayName, icon, startTime, endTime, isTradeSkill, lineID, notInterruptible = L["Example Spell Name"], "", GetSpellTexture(1),
			GetTime() * 1000 - 1000, GetTime() * 1000 + 1500, false, 0, false

		f.spellName = spell
		f.isChanneling = false
		f.isCasting = true
		f.startTime = startTime / 1000
		f.endTime = endTime / 1000
		f.maxValue = f.endTime - f.startTime
		f.delay = 0.2

		f.icon:SetTexture(icon)
		self:SetInterruptible(unit, not notInterruptible)
		f.bar:SetMinMaxValues(0, f.maxValue)

		if self.db[unit].castSpark then f.spark:Show() end
		CastUpdate(f)
		UpdateCastText(f, spell)
	end
end

function CastBar:GetOptions(unit)
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				bar = {
					type = "group",
					name = L["Bar"],
					desc = L["Bar settings"],
					inline = true,
					order = 1,
					args = {
						castBarColor = {
							type = "color",
							name = L["Color"],
							desc = L["Color of the cast bar"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						castBarNotIntColor = {
							type = "color",
							name = L["Not interruptible color"],
							desc = L["Color of the cast bar when the spell can't be interrupted"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 6,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castBarBackgroundColor = {
							type = "color",
							name = L["Background color"],
							desc = L["Color of the cast bar background"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						castBarBackgroundHideWhenNotCasting = {
							type = "toggle",
							name = L["Hide background out of cast"],
							desc = L["Hides the background when the unit is not casting. If in \"Inside Frame\" mode, will still show the frame's background."],

							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 11,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						castBarInverse = {
							type = "toggle",
							name = L["Inverse"],
							desc = L["Invert the bar colors"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 15,
						},
						sep3 = {
							type = "description",
							name = "",
							width = "full",
							order = 16,
						},
						castBarGlobalTexture = {
							type = "toggle",
							name = L["Use global texture"],
							desc = L["Use the global bar texture"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 17,
						},
						castBarTexture = {
							type = "select",
							name = L["Texture"],
							desc = L["Texture of the cast bar"],
							dialogControl = "LSM30_Statusbar",
							values = LSM.MediaTable.statusbar,
							disabled = function() return self.db[unit].castBarGlobalTexture or not self:IsUnitEnabled(unit) end,
							order = 18,
						},
						sep4 = {
							type = "description",
							name = "",
							width = "full",
							order = 23,
						},
						castIcon = {
							type = "toggle",
							name = L["Icon"],
							desc = L["Toggle the cast bar spell icon"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 25,
						},
						castIconPosition = {
							type = "select",
							name = L["Icon position"],
							desc = L["Position of the cast bar icon"],
							values = { ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] },
							disabled = function() return not self.db[unit].castIcon or not self:IsUnitEnabled(unit) end,
							order = 26,
						},
						sep5 = {
							type = "description",
							name = "",
							width = "full",
							order = 27,
						},
						castIconOffsetX = {
							type = "range",
							name = L["Icon Offset X"],
							desc = L["X offset of the icon"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castIcon or not self:IsUnitEnabled(unit) end,
							order = 28,
						},
						castIconOffsetY = {
							type = "range",
							name = L["Icon Offset Y"],
							desc = L["Y offset of the icon"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castIcon or not self:IsUnitEnabled(unit) end,
							order = 29,
						},
						sep6 = {
							type = "description",
							name = "",
							width = "full",
							order = 31,
						},
						castSpark = {
							type = "toggle",
							name = L["Show spark"],
							desc = L["Toggle the cast bar spark"],
							disabled = function() return not self.db[unit].castIcon or not self:IsUnitEnabled(unit) end,
							order = 35,
						},
						castShieldIcon = {
							type = "toggle",
							name = L["Shield icon"],
							desc = L["Toggle the cast bar shield icon for not interruptible spells"],
							disabled = function() return not self.db[unit].castIcon or not self:IsUnitEnabled(unit) end,
							order = 35,
						},
					},
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 2,
					args = {
						castBarAttachMode = {
							type = "toggle",
							name = L["Inside frame"],
							desc = L["Toggle if you want the cast bar to be part of the frame or if you want to position it freely"],
							get = function() return self.db[unit].castBarAttachMode == "InFrame" end,
							set = function(k, v)
								self.db[unit].castBarAttachMode = v and "InFrame" or "Widget"
								GladiusEx:UpdateFrames()
							end,
							order = 10,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 11,
						},
						castBarWidth = {
							type = "range",
							name = L["Width"],
							desc = L["Width of the cast bar"],
							min = 1, softMin = 5, softMax = 500, bigStep = 1,
							disabled = function() return not self:IsUnitEnabled(unit) or self.db[unit].castBarAttachMode == "InFrame" end,
							order = 20,
						},
						castBarHeight = {
							type = "range",
							name = L["Height"],
							desc = L["Height of the cast bar"],
							min = 1, softMin = 5, softMax = 100, bigStep = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 30,
						},
					},
				},
				position_widget = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					hidden = function() return self.db[unit].castBarAttachMode ~= "Widget" end,
					order = 3,
					args = {
						castBarAttachTo = {
							type = "select",
							name = L["Attach to"],
							desc = L["Attach to the given frame"],
							values = function() return self:GetOtherAttachPoints(unit) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						castBarPosition = {
							type = "select",
							name = L["Position"],
							desc = L["Position of the frame"],
							values = GladiusEx:GetSimplePositions(),
							get = function()
								return GladiusEx:AnchorToSimplePosition(self.db[unit].castBarAnchor, self.db[unit].castBarRelativePoint)
							end,
							set = function(info, value)
								self.db[unit].castBarAnchor, self.db[unit].castBarRelativePoint = GladiusEx:SimplePositionToAnchor(value)
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return GladiusEx.db.base.advancedOptions end,
							order = 2,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castBarAnchor = {
							type = "select",
							name = L["Anchor"],
							desc = L["Anchor of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 10,
						},
						castBarRelativePoint = {
							type = "select",
							name = L["Relative point"],
							desc = L["Relative point of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						castBarOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the frame"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return  not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						castBarOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset of the frame"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 25,
						},
					},
				},
				position_inframe = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					hidden = function() return self.db[unit].castBarAttachMode ~= "InFrame" end,
					order = 3,
					args = {
						castBarPosition = {
							type = "select",
							name = L["Position"],
							-- desc = L[""],
							values = {
								["TOP"] = L["Top"],
								["BOTTOM"] = L["Bottom"]
							},
							order = 1,
						},
					},
				},
			},
		},
		castText = {
			type = "group",
			name = L["Cast text"],
			order = 2,
			args = {
				text = {
					type = "group",
					name = L["Text"],
					desc = L["Text settings"],
					inline = true,
					order = 1,
					args = {
						castText = {
							type = "toggle",
							name = L["Cast text"],
							desc = L["Toggle cast text"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castTextColor = {
							type = "color",
							name = L["Text color"],
							desc = L["Text color of the cast text"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self.db[unit].castText or not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						castTextGlobalFontSize = {
							type = "toggle",
							name = L["Global font size"],
							desc = L["Use the global font size"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 11,
						},
						castTextSize = {
							type = "range",
							name = L["Text size"],
							desc = L["Text size of the cast text"],
							min = 1, max = 20, step = 1,
							disabled = function() return self.db[unit].castTextGlobalFontSize or not self.db[unit].castText or not self:IsUnitEnabled(unit) end,
							order = 15,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 2,
					args = {
						castTextAlign = {
							type = "select",
							name = L["Text align"],
							desc = L["Text align of the cast text"],
							values = { ["LEFT"] = L["Left"], ["CENTER"] = L["Center"], ["RIGHT"] = L["Right"] },
							disabled = function() return not self.db[unit].castText or not self:IsUnitEnabled(unit) end,
							width = "double",
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castTextOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the cast text"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castText or not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						castTextOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset of the cast text"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castText or not self:IsUnitEnabled(unit) end,
							order = 15,
						},
					},
				},
			},
		},
		castTimeText = {
			type = "group",
			name = L["Cast time text"],
			order = 3,
			args = {
				text = {
					type = "group",
					name = L["Text"],
					desc = L["Text settings"],
					inline = true,
					order = 1,
					args = {
						castTimeText = {
							type = "toggle",
							name = L["Cast time text"],
							desc = L["Toggle cast time text"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 2,
						},
						castTimeTextColor = {
							type = "color",
							name = L["Text color"],
							desc = L["Text color of the cast time text"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self.db[unit].castTimeText or not self:IsUnitEnabled(unit) end,
							order = 3,
						},
						castTimeTextGlobalFontSize = {
							type = "toggle",
							name = L["Global font size"],
							desc = L["Use the global font size"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						castTimeTextSize = {
							type = "range",
							name = L["Text size"],
							desc = L["Text size of the cast time text"],
							min = 1, max = 20, step = 1,
							disabled = function() return self.db[unit].castTimeTextGlobalFontSize or not self.db[unit].castTimeText or not self:IsUnitEnabled(unit) end,
							order = 6,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castTimeTextCastTime = {
							type = "toggle",
							name = L["Show cast time"],
							desc = L["Toggle cast time"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 8,
						},
						castTimeTextRemainingTime = {
							type = "toggle",
							name = L["Remaining time"],
							desc = L["Toggle remaining time instead of cast time"],
							disabled = function() return not self:IsUnitEnabled(unit) or not self.db[unit].castTimeTextCastTime end,
							order = 9,
						},
						castTimeTextTotalTime = {
							type = "toggle",
							name = L["Show total time"],
							desc = L["Toggle total time"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						castTimeTextDelay = {
							type = "toggle",
							name = L["Show delay"],
							desc = L["Toggle delay"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 11,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 2,
					args = {
						castTimeTextAlign = {
							type = "select",
							name = L["Text align"],
							desc = L["Text align of the cast time text"],
							values = { ["LEFT"] = L["Left"], ["CENTER"] = L["Center"], ["RIGHT"] = L["Right"] },
							disabled = function() return not self.db[unit].castTimeText or not self:IsUnitEnabled(unit) end,
							width = "double",
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						castTimeTextOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the cast time text"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castTimeText or not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						castTimeTextOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset of the cast time text"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self.db[unit].castTimeText or not self:IsUnitEnabled(unit) end,
							order = 15,
						},
					},
				},
			},
		},
	}
end
