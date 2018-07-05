local _G, SUI = _G, SUI
local PartyFrames = SUI.PartyFrames
----------------------------------------------------------------------------------------------------
local colors = setmetatable({}, {__index = SpartanoUF.colors})
for k, v in pairs(SpartanoUF.colors) do
	if not colors[k] then
		colors[k] = v
	end
end
colors.health = {0 / 255, 255 / 255, 50 / 255}
local base_plate1 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_1_full.blp]]
local base_plate2 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_2_dual.blp]]
local base_plate3 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_3_single.blp]]
local base_ring = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_ring1.blp]]

--	Formatting functions

local OnCastbarUpdate = function(self, elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil
			self:Hide()
			if PostCastStop then
				PostCastStop(self:GetParent())
			end
			return
		end
		if self.Time then
			if self.delay ~= 0 then
				self.Time:SetTextColor(1, 0, 0)
			else
				self.Time:SetTextColor(1, 1, 1)
			end
			if SUI.DBMod.PartyFrames.castbartext == 1 then
				self.Time:SetFormattedText("%.1f", self.max - self.duration)
			else
				self.Time:SetFormattedText("%.1f", self.duration)
			end
		end
		if SUI.DBMod.PartyFrames.castbar == 1 then
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
			--self.Time:SetFormattedText("%.1f",self.max-self.duration);
			if SUI.DBMod.PartyFrames.castbartext == 0 then
				self.Time:SetFormattedText("%.1f", self.max - self.duration)
			else
				self.Time:SetFormattedText("%.1f", self.duration)
			end
		end
		if SUI.DBMod.PartyFrames.castbar == 1 then
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

local threat = function(self, event, unit)
	local status
	unit = string.gsub(self.unit, "(.)", string.upper, 1) or string.gsub(unit, "(.)", string.upper, 1)
	if UnitExists(unit) then
		status = UnitThreatSituation(unit)
	else
		status = 0
	end
	if self.Portrait and SUI.DBMod.PartyFrames.threat then
		if (not self.Portrait:IsObjectType("Texture")) then
			return
		end
		if (status and status > 0) then
			local r, g, b = GetThreatStatusColor(status)
			self.Portrait:SetVertexColor(r, g, b)
		else
			self.Portrait:SetVertexColor(1, 1, 1)
		end
	elseif self.ThreatIndicatorOverlay and SUI.DBMod.PartyFrames.threat then
		if (status and status > 0) then
			self.ThreatIndicatorOverlay:SetVertexColor(GetThreatStatusColor(status))
			self.ThreatIndicatorOverlay:Show()
		else
			self.ThreatIndicatorOverlay:Hide()
		end
	end
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
	-- self:SetStatusBarColor(0,1,0); --B3
end

local CreatePartyFrame = function(self, unit)
	--self:SetSize(250, 70); -- just make it we will adjust later
	do -- setup base artwork
		self.artwork = CreateFrame("Frame", nil, self)
		self.artwork:SetFrameStrata("BACKGROUND")
		self.artwork:SetFrameLevel(1)
		self.artwork:SetAllPoints(self)

		self.artwork.bg = self.artwork:CreateTexture(nil, "BACKGROUND")
		self.artwork.bg:SetAllPoints(self)

		--	Portrait.Size = X Size of the Portrait section of the BG texture
		--  Portrait.XTexSize = This is the texcord size of the Portrait it
		-- 						is set by default for if there is no Portrait
		local Portrait = {Size = 0, XTexSize = .3}
		if SUI.DBMod.PartyFrames.Portrait then
			Portrait.Size = 75
			Portrait.XTexSize = 0
		end

		if SUI.DBMod.PartyFrames.FrameStyle == "large" then
			self.artwork.bg:SetTexture(base_plate1)
			self:SetSize(165 + Portrait.Size, 70)
			self.artwork.bg:SetTexCoord(Portrait.XTexSize, .95, 0.015, .59)
		elseif SUI.DBMod.PartyFrames.FrameStyle == "medium" then
			self.artwork.bg:SetTexture(base_plate1)
			self:SetSize(165 + Portrait.Size, 50)
			self.artwork.bg:SetTexCoord(Portrait.XTexSize, .95, 0.015, .44)
		elseif SUI.DBMod.PartyFrames.FrameStyle == "small" then
			self.artwork.bg:SetTexture(base_plate3)
			self:SetSize(165 + Portrait.Size, 48)
			self.artwork.bg:SetTexCoord(Portrait.XTexSize, .95, 0.015, .77)
		elseif SUI.DBMod.PartyFrames.FrameStyle == "xsmall" then
			self.artwork.bg:SetTexture(base_plate2)
			self:SetSize(165 + Portrait.Size, 35)
			self.artwork.bg:SetTexCoord(Portrait.XTexSize, .95, 0.015, .56)
		elseif SUI.DBMod.PartyFrames.FrameStyle == "raidsmall" then
			self.artwork.bg:SetTexture(base_plate2)
			self:SetSize(165 + Portrait.Size, 35)
			self.artwork.bg:SetTexCoord(Portrait.XTexSize, .95, 0.015, .56)
		end

		if SUI.DBMod.PartyFrames.Portrait then
			-- local Portrait = CreateFrame('PlayerModel', nil, self)
			-- Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
			-- Portrait.type = "3D"

			self.Portrait = PartyFrames:CreatePortrait(self)
			self.Portrait:SetSize(55, 55)
			self.Portrait:SetPoint("TOPLEFT", self, "TOPLEFT", 15, -8)

		--self.artwork.ring = self.artwork:CreateTexture(nil,"BORDER");
		--self.artwork.ring:SetPoint("TOPLEFT",self,"TOPLEFT",15,-8);
		end
	end
	do -- setup status bars
		do -- cast bar
			if SUI.DBMod.PartyFrames.FrameStyle == "large" then
				local cast = CreateFrame("StatusBar", nil, self)
				cast:SetFrameStrata("BACKGROUND")
				cast:SetFrameLevel(2)
				cast:SetSize(110, 16)
				cast:SetPoint("TOPRIGHT", self, "TOPRIGHT", -55, -17)

				cast.Text = cast:CreateFontString()
				SUI:FormatFont(cast.Text, 10, "Party")
				cast.Text:SetSize(100, 11)
				cast.Text:SetJustifyH("LEFT")
				cast.Text:SetJustifyV("BOTTOM")
				cast.Text:SetPoint("RIGHT", cast, "RIGHT", -2, 0)

				cast.Time = cast:CreateFontString()
				SUI:FormatFont(cast.Time, 10, "Party")
				cast.Time:SetSize(40, 11)
				cast.Time:SetJustifyH("LEFT")
				cast.Time:SetJustifyV("BOTTOM")
				cast.Time:SetPoint("LEFT", cast, "RIGHT", 2, 0)

				self.Castbar = cast
				self.Castbar.OnUpdate = OnCastbarUpdate
				self.Castbar.PostCastStart = PostCastStart
				self.Castbar.PostChannelStart = PostChannelStart
				self.Castbar.PostCastStop = PostCastStop
			end
		end
		do -- health bar
			local health = CreateFrame("StatusBar", nil, self)
			health:SetFrameStrata("BACKGROUND")
			health:SetFrameLevel(2)
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])

			if SUI.DBMod.PartyFrames.FrameStyle == "large" then
				health:SetPoint("TOPRIGHT", self.Castbar, "BOTTOMRIGHT", 0, -2)
				health:SetSize(110, 15)
			elseif SUI.DBMod.PartyFrames.FrameStyle == "medium" then
				health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -55, -19)
				health:SetSize(110, 15)
			elseif SUI.DBMod.PartyFrames.FrameStyle == "small" then
				health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -55, -19)
				health:SetSize(110, 27)
			elseif SUI.DBMod.PartyFrames.FrameStyle == "xsmall" then
				health:SetPoint("TOPRIGHT", self, "TOPRIGHT", -55, -20)
				health:SetSize(110, 13)
			end

			health.value = health:CreateFontString()
			SUI:FormatFont(health.value, 10, "Party")
			if SUI.DBMod.PartyFrames.FrameStyle == "large" then
				health.value:SetSize(100, 11)
			else
				health.value:SetSize(100, 10)
			end
			health.value:SetJustifyH("LEFT")
			health.value:SetJustifyV("BOTTOM")
			health.value:SetPoint("RIGHT", health, "RIGHT", -2, 0)
			self:Tag(health.value, PartyFrames:TextFormat("health"))

			health.ratio = health:CreateFontString()
			SUI:FormatFont(health.ratio, 10, "Party")
			health.ratio:SetSize(40, 11)
			health.ratio:SetJustifyH("LEFT")
			health.ratio:SetJustifyV("BOTTOM")
			health.ratio:SetPoint("LEFT", health, "RIGHT", 2, 0)
			self:Tag(health.ratio, "[perhp]%")

			self.Health = health
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			self.Health.colorHealth = true
			self.Health.colorSmooth = true

			-- Position and size
			local myBars = CreateFrame("StatusBar", nil, self.Health)
			myBars:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
			myBars:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame("StatusBar", nil, myBars)
			otherBars:SetPoint("TOPLEFT", myBars:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
			otherBars:SetPoint("BOTTOMLEFT", myBars:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
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
			if
				SUI.DBMod.PartyFrames.FrameStyle == "large" or SUI.DBMod.PartyFrames.FrameStyle == "medium" or
					SUI.DBMod.PartyFrames.display.mana == true
			 then
				local power = CreateFrame("StatusBar", nil, self)
				power:SetFrameStrata("BACKGROUND")
				power:SetFrameLevel(2)

				if SUI.DBMod.PartyFrames.Portrait then
					power:SetSize(123, 14)
				else
					power:SetSize(self.Health:GetWidth(), 14)
				end

				if SUI.DBMod.PartyFrames.FrameStyle ~= "small" and SUI.DBMod.PartyFrames.FrameStyle ~= "xsmall" then
					power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -2)
					power.value = power:CreateFontString()
					SUI:FormatFont(power.value, 10, "Party")
					if SUI.DBMod.PartyFrames.FrameStyle == "large" then
						power.value:SetSize(100, 11)
					else
						power.value:SetSize(100, 10)
					end
					power.value:SetJustifyH("LEFT")
					power.value:SetJustifyV("BOTTOM")
					power.value:SetPoint("RIGHT", power, "RIGHT", -2, 0)
					self:Tag(power.value, PartyFrames:TextFormat("mana"))

					power.ratio = power:CreateFontString()
					SUI:FormatFont(power.ratio, 10, "Party")
					power.ratio:SetSize(40, 11)
					power.ratio:SetJustifyH("LEFT")
					power.ratio:SetJustifyV("BOTTOM")
					power.ratio:SetPoint("LEFT", power, "RIGHT", 2, 0)
					self:Tag(power.ratio, "[perpp]%")
				else
					power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)
					power:SetHeight(3)
				end

				self.Power = power
				self.Power.colorPower = true
				self.Power.frequentUpdates = true
			end
		end
	end
	do -- setup text and icons
		local ring = CreateFrame("Frame", nil, self)
		ring:SetFrameStrata("BACKGROUND")

		self.Name = ring:CreateFontString()
		SUI:FormatFont(self.Name, 11, "Party")
		self.Name:SetSize(140, 10)
		self.Name:SetJustifyH("LEFT")
		self.Name:SetJustifyV("BOTTOM")
		self.Name:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, -6)
		if SUI.DBMod.PartyFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]")
		else
			self:Tag(self.Name, "[name]")
		end

		self.SUI_ClassIcon = ring:CreateTexture(nil, "BORDER")
		self.SUI_ClassIcon:SetSize(20, 20)

		self.HLeaderIndicator = ring:CreateTexture(nil, "BORDER")
		self.HLeaderIndicator:SetSize(20, 20)

		self.GroupRoleIndicator = ring:CreateTexture(nil, "BORDER")
		self.GroupRoleIndicator:SetSize(25, 25)
		self.GroupRoleIndicator:SetTexture [[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_role]]

		self.RaidTargetIndicator = ring:CreateTexture(nil, "ARTWORK")
		self.RaidTargetIndicator:SetSize(20, 20)

		if SUI.DBMod.PartyFrames.Portrait then
			ring.bg = ring:CreateTexture(nil, "BACKGROUND")
			ring.bg:SetPoint("TOPLEFT", self, "TOPLEFT", -2, 4)
			ring.bg:SetTexture(base_ring)

			self.Level = ring:CreateFontString()
			SUI:FormatFont(self.Level, 10, "Party")
			self.Level:SetSize(40, 12)
			self.Level:SetJustifyH("CENTER")
			self.Level:SetJustifyV("BOTTOM")
			self.Level:SetPoint("CENTER", self.Portrait, "CENTER", -27, 27)
			self:Tag(self.Level, "[level]")

			self.PvPIndicator = ring:CreateTexture(nil, "BORDER")
			self.PvPIndicator:SetSize(50, 50)
			self.PvPIndicator:SetPoint("CENTER", self.Portrait, "BOTTOMLEFT", 5, -10)

			self.StatusText = ring:CreateFontString()
			SUI:FormatFont(self.StatusText, 18, "Party")
			self.StatusText:SetPoint("CENTER", self.Portrait, "CENTER")
			self.StatusText:SetJustifyH("CENTER")
			self:Tag(self.StatusText, "[afkdnd]")

			ring:SetAllPoints(self.Portrait)
			ring:SetFrameLevel(5)
			self.RaidTargetIndicator:SetPoint("CENTER", self.Portrait, "CENTER")
			self.SUI_ClassIcon:SetPoint("CENTER", self.Portrait, "CENTER", 23, 24)
			self.HLeaderIndicator:SetPoint("CENTER", self.Portrait, "TOP", -1, 6)
			self.GroupRoleIndicator:SetPoint("CENTER", self.Portrait, "BOTTOM", 0, -10)
		else
			ring:SetAllPoints(self)
			ring:SetFrameLevel(3)
			self.SUI_ClassIcon:SetPoint("CENTER", self, "TOPLEFT", 5, -5)
			self.HLeaderIndicator:SetPoint("CENTER", self, "LEFT", 0, 0)
			self.GroupRoleIndicator:SetPoint("CENTER", self, "TOPRIGHT", -25, 0)
			self.RaidTargetIndicator:SetPoint("CENTER", self, "TOPRIGHT", -15, -15)
		end
	end
	do -- setup buffs and debuffs
		self.Auras = CreateFrame("Frame", nil, self)
		self.Auras:SetSize(self:GetWidth(), 17)
		self.Auras:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -3, -5)
		self.Auras:SetFrameStrata("BACKGROUND")
		self.Auras:SetFrameLevel(4)
		-- settings
		self.Auras.size = SUI.DBMod.PartyFrames.Auras.size
		self.Auras.spacing = SUI.DBMod.PartyFrames.Auras.spacing
		self.Auras.showType = SUI.DBMod.PartyFrames.Auras.showType
		self.Auras.initialAnchor = "TOPLEFT"
		self.Auras.gap = true -- adds an empty spacer between buffs and debuffs
		self.Auras.numBuffs = SUI.DBMod.PartyFrames.Auras.NumBuffs
		self.Auras.numDebuffs = SUI.DBMod.PartyFrames.Auras.NumDebuffs

		self.Auras.PostUpdate = PartyFrames:PostUpdateAura(self, unit)
	end
	do -- HoTs Display
		self.AuraWatch = SUI:oUF_Buffs(self, "BOTTOMRIGHT", "TOPRIGHT", 0)
	end
	do --Threat, SpellRange, and Ready Check
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1 / 2
		}

		if not SUI.DBMod.PartyFrames.Portrait then
			local overlay = self:CreateTexture(nil, "OVERLAY")
			overlay:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights")
			overlay:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
			overlay:SetAllPoints(self)
			overlay:SetVertexColor(1, 0, 0)
			overlay:Hide()
			self.ThreatIndicatorOverlay = overlay
		end

		self.ThreatIndicator = CreateFrame("Frame", nil, self)
		self.ThreatIndicator.Override = threat

		local ResurrectIcon = self:CreateTexture(nil, "OVERLAY")
		ResurrectIcon:SetSize(25, 25)
		ResurrectIcon:SetPoint("RIGHT", self, "CENTER", 0, 0)
		self.ResurrectIndicator = ResurrectIcon

		local ReadyCheck = self:CreateTexture(nil, "OVERLAY")
		ReadyCheck:SetSize(30, 30)
		ReadyCheck:SetPoint("RIGHT", self, "CENTER", 0, 0)
		self.ReadyCheckIndicator = ReadyCheck
	end
	self.TextUpdate = PartyFrames.PostUpdateText
	-- self.TextUpdate = function (self)
	-- self:Untag(self.Health.value)
	-- self:Tag(self.Health.value, PartyFrames:TextFormat("health"))
	-- if self.Power then self:Untag(self.Power.value) end
	-- if self.Power then self:Tag(self.Power.value, PartyFrames:TextFormat("mana")) end
	-- end
	return self
end

local CreateSubFrame = function(self, unit)
	self:SetSize(150, 36)
	do -- setup base artwork
		self.artwork = CreateFrame("Frame", nil, self)
		self.artwork:SetFrameStrata("BACKGROUND")
		self.artwork:SetFrameLevel(0.9)
		self.artwork:SetAllPoints(self)

		self.artwork.bg = self.artwork:CreateTexture(nil, "BACKGROUND")
		self.artwork.bg:SetAllPoints(self)
		self.artwork.bg:SetTexture(base_plate2)
		self.artwork.bg:SetTexCoord(.3, 1, .01, .55)

		self.ThreatIndicator = CreateFrame("Frame", nil, self)
		self.ThreatIndicator.Override = threat
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar", nil, self)
			health:SetFrameStrata("BACKGROUND")
			health:SetFrameLevel(.95)
			health:SetSize(self:GetWidth() / 1.70, self:GetHeight() / 2.97)
			health:SetPoint("BOTTOMLEFT", self.artwork.bg, "BOTTOMLEFT", 11, 2)

			health.value = health:CreateFontString()
			SUI:FormatFont(health.value, 10, "Party")
			health.value:SetSize(self:GetWidth() / 2, health:GetHeight() - 2)
			health.value:SetJustifyH("LEFT")
			health.value:SetJustifyV("BOTTOM")
			health.value:SetPoint("RIGHT", health, "RIGHT", 0, 1)
			self:Tag(health.value, "[curhpshort]/[maxhpshort]")

			health.ratio = health:CreateFontString()
			SUI:FormatFont(health.ratio, 10, "Party")
			health.ratio:SetSize(self:GetWidth() / 1.85, health:GetHeight() - 2)
			health.ratio:SetJustifyH("LEFT")
			health.ratio:SetJustifyV("BOTTOM")
			health.ratio:SetPoint("LEFT", health, "RIGHT", 4, 0)
			self:Tag(health.ratio, "[perhp]%")

			self.Health = health
			self.Health.frequentUpdates = true
			self.Health.colorDisconnected = true
			self.Health.colorHealth = true
			self.Health.colorSmooth = true
		end
	end
	do -- setup text and icons
		self.Name = self:CreateFontString()
		SUI:FormatFont(self.Name, 11, "Party")
		self.Name:SetSize(135, 12)
		self.Name:SetJustifyH("LEFT")
		self.Name:SetJustifyV("BOTTOM")
		self.Name:SetPoint("TOPRIGHT", self.artwork.bg, "TOPRIGHT", 0, -4)
		if SUI.DBMod.PartyFrames.showClass then
			self:Tag(self.Name, "[level][SUI_ColorClass][name]")
		else
			self:Tag(self.Name, "[level][name]")
		end
	end
	return self
end

local CreateUnitFrame = function(self, unit)
	if (self:GetAttribute("unitsuffix") == "target") and SUI.DBMod.PartyFrames.display.target then
		self = CreateSubFrame(self, unit)
	elseif
		(self:GetAttribute("unitsuffix") == "pet") and
			(SUI.DBMod.PartyFrames.FrameStyle == "large" or (not SUI.DBMod.PartyFrames.display.target)) and
			SUI.DBMod.PartyFrames.display.pet
	 then
		self = CreateSubFrame(self, unit)
	elseif (unit == "party") then
		self = CreatePartyFrame(self, unit)
	end

	self = PartyFrames:MakeMovable(self)

	return self
end

SpartanoUF:RegisterStyle("Spartan_PartyFrames", CreateUnitFrame)

local OptionsSetup = function()
	SUI.opt.args["PartyFrames"].args["auras"] = {
		name = SUI.L["BuffDebuff"],
		type = "group",
		order = 2,
		args = {
			display = {
				name = SUI.L["DispBuffDebuff"],
				type = "toggle",
				order = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.showAuras
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.showAuras = val
					addon:UpdateAura()
				end
			},
			showType = {
				name = SUI.L["ShowType"],
				type = "toggle",
				order = 2,
				get = function(info)
					return SUI.DBMod.PartyFrames.Auras.showType
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.Auras.showType = val
					addon:UpdateAura()
				end
			},
			numBufs = {
				name = SUI.L["NumBuffs"],
				type = "range",
				width = "full",
				order = 11,
				min = 0,
				max = 50,
				step = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.Auras.NumBuffs
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.Auras.NumBuffs = val
					addon:UpdateAura()
				end
			},
			numDebuffs = {
				name = SUI.L["NumDebuff"],
				type = "range",
				width = "full",
				order = 12,
				min = 0,
				max = 50,
				step = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.Auras.NumDebuffs
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.Auras.NumDebuffs = val
					addon:UpdateAura()
				end
			},
			size = {
				name = SUI.L["SizeBuff"],
				type = "range",
				width = "full",
				order = 13,
				min = 0,
				max = 60,
				step = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.Auras.size
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.Auras.size = val
					addon:UpdateAura()
				end
			},
			spacing = {
				name = SUI.L["SpacingBuffDebuffs"],
				type = "range",
				width = "full",
				order = 14,
				min = 0,
				max = 50,
				step = 1,
				get = function(info)
					return SUI.DBMod.PartyFrames.Auras.spacing
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.Auras.spacing = val
					addon:UpdateAura()
				end
			}
		}
	}
	SUI.opt.args["PartyFrames"].args["castbar"] = {
		name = SUI.L["PrtyCast"],
		type = "group",
		order = 3,
		desc = SUI.L["PrtyCastDesc"],
		args = {
			castbar = {
				name = SUI.L["FillDir"],
				type = "select",
				style = "radio",
				values = {[0] = SUI.L["FillLR"], [1] = SUI.L["DepRL"]},
				get = function(info)
					return SUI.DBMod.PartyFrames.castbar
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.castbar = val
				end
			},
			castbartext = {
				name = SUI.L["TextStyle"],
				type = "select",
				style = "radio",
				values = {[0] = SUI.L["CountUp"], [1] = SUI.L["CountDown"]},
				get = function(info)
					return SUI.DBMod.PartyFrames.castbartext
				end,
				set = function(info, val)
					SUI.DBMod.PartyFrames.castbartext = val
				end
			}
		}
	}

	SUI.opt.args["PartyFrames"].args["FramePreSets"] = {
		name = SUI.L["PreSets"],
		type = "select",
		order = 1,
		values = {
			["custom"] = SUI.L["Custom"],
			["tank"] = SUI.L["Tank"],
			["dps"] = SUI.L["DPS"],
			["healer"] = SUI.L["Healer"]
		},
		get = function(info)
			return SUI.DBMod.PartyFrames.preset
		end,
		set = function(info, val)
			SUI.DBMod.PartyFrames.preset = val
			if val == "tank" then
				SUI.DBMod.PartyFrames.FrameStyle = "medium"
				SUI.DBMod.PartyFrames.Portrait = false
			elseif val == "dps" then
				SUI.DBMod.PartyFrames.FrameStyle = "xsmall"
				SUI.DBMod.PartyFrames.Portrait = false
				SUI.DBMod.PartyFrames.showAuras = false
			elseif val == "healer" then
				SUI.DBMod.PartyFrames.FrameStyle = "small"
				SUI.DBMod.PartyFrames.Portrait = false
			end
		end
	}
	SUI.opt.args["PartyFrames"].args["FrameStyle"] = {
		name = SUI.L["FrameStyle"],
		type = "select",
		order = 2,
		values = {
			["large"] = SUI.L["StyleLarge"],
			["medium"] = SUI.L["StyleMed"],
			["small"] = SUI.L["StyleSmall"],
			["xsmall"] = SUI.L["StyleXSmall"]
		},
		get = function(info)
			return SUI.DBMod.PartyFrames.FrameStyle
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				return SUI:Print(ERR_NOT_IN_COMBAT)
			end
			SUI.DBMod.PartyFrames.FrameStyle = val
			SUI.DBMod.PartyFrames.preset = "custom"
		end
	}
	SUI.opt.args["PartyFrames"].args["mana"] = {
		name = SUI.L["DispMana"],
		type = "toggle",
		order = 2.5,
		hidden = function(info)
			if SUI.DBMod.PartyFrames.FrameStyle == "xsmall" or SUI.DBMod.PartyFrames.FrameStyle == "small" then
				return false
			else
				return true
			end
		end,
		get = function(info)
			return SUI.DBMod.PartyFrames.display.mana
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				return SUI:Print(ERR_NOT_IN_COMBAT)
			end
			SUI.DBMod.PartyFrames.display.mana = val
			SUI.DBMod.PartyFrames.preset = "custom"
		end
	}
	SUI.opt.args["PartyFrames"].args["Portrait"] = {
		name = SUI.L["DispPort"],
		type = "toggle",
		order = 3,
		get = function(info)
			return SUI.DBMod.PartyFrames.Portrait
		end,
		set = function(info, val)
			if (InCombatLockdown()) then
				return SUI:Print(ERR_NOT_IN_COMBAT)
			end
			SUI.DBMod.PartyFrames.Portrait = val
			SUI.DBMod.PartyFrames.preset = "custom"
		end
	}
	SUI.opt.args["PartyFrames"].args["Portrait3D"] = {
		name = SUI.L["Portrait3D"],
		type = "toggle",
		order = 3.1,
		get = function(info)
			return SUI.DBMod.PartyFrames.Portrait3D
		end,
		set = function(info, val)
			SUI.DBMod.PartyFrames.Portrait3D = val
		end
	}
	SUI.opt.args["PartyFrames"].args["threat"] = {
		name = SUI.L["DispThreat"],
		type = "toggle",
		order = 4,
		get = function(info)
			return SUI.DBMod.PartyFrames.threat
		end,
		set = function(info, val)
			SUI.DBMod.PartyFrames.threat = val
			SUI.DBMod.PartyFrames.preset = "custom"
		end
	}
end

function PartyFrames:Classic()
	--Create the options
	OptionsSetup()
	--DB Fix
	if SUI.DBMod.PartyFrames.FrameStyle == "Large" then
		SUI.DBMod.PartyFrames.FrameStyle = "large"
	end

	--Set the style
	SpartanoUF:SetActiveStyle("Spartan_PartyFrames")
	--Create the frames
	local party =
		SpartanoUF:SpawnHeader(
		"SUI_PartyFrameHeader",
		nil,
		nil,
		"showRaid",
		SUI.DBMod.PartyFrames.showRaid,
		"showParty",
		SUI.DBMod.PartyFrames.showParty,
		"showPlayer",
		SUI.DBMod.PartyFrames.showPlayer,
		"showSolo",
		SUI.DBMod.PartyFrames.showSolo,
		"yOffset",
		-16,
		"xOffset",
		0,
		"columnAnchorPoint",
		"TOPLEFT",
		"initial-anchor",
		"TOPLEFT",
		"template",
		"SUI_PartyMemberTemplate"
	)

	return (party)
end
