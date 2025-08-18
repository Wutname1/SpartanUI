local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")

-- global functions
local strfind = string.find
local pairs = pairs
local min = math.min
local UnitHealth, UnitHealthMax, UnitClass = UnitHealth, UnitHealthMax, UnitClass
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs or (Precognito and Precognito.UnitGetTotalAbsorbs)

local HealthBar = GladiusEx:NewGladiusExModule("HealthBar", {
	healthBarAttachTo = "Frame",
	healthBarHeight = 15,
	healthBarAdjustWidth = true,
	healthBarWidth = 200,
	healthBarInverse = false,
	healthBarColor = { r = 1, g = 1, b = 1, a = 1 },
	healthBarClassColor = true,
	healthBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
	healthBarGlobalTexture = true,
	healthBarTexture = GladiusEx.default_bar_texture,
	healthBarOrder = 1,
	healthBarAnchor = "TOPLEFT",
	healthBarRelativePoint = "TOPLEFT",
	healthBarIncomingHeals = true,
	healthBarIncomingHealsColor = { r = 0, g = 1, b = 0, a = 0.55 },
	healthBarIncomingHealsCap = 0,
	healthBarIncomingAbsorbs = true,
	healthBarIncomingAbsorbsColor = { r = 0, g = 0.5, b = 1, a = 0.55 },
	healthBarIncomingAbsorbsCap = 0,
})

function HealthBar:OnEnable()
    self:RegisterEvent("UNIT_HEALTH", "UpdateHealthEvent")
    self:RegisterEvent("UNIT_MAXHEALTH", "UpdateHealthEvent")
    
    if GladiusEx.IS_RETAIL or GladiusEx.IS_CATAC or GladiusEx.IS_MOPC or PlayerFrame:IsEventRegistered("UNIT_HEAL_PREDICTION") then
        self:RegisterEvent("UNIT_HEAL_PREDICTION", "UpdateIncomingHealsEvent")
    end
    if GladiusEx.IS_RETAIL or PlayerFrame:IsEventRegistered("UNIT_ABSORB_AMOUNT_CHANGED") then
        self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", "UpdateIncomingAbsorbsEvent")
    end
    
    if GladiusEx.IS_CATAC then
        EventRegistry:RegisterCallback("Precognito", function(_, unitGUID)
            local unit = GladiusEx:GetUnitIdByGUID(unitGUID)
            if unit then
                self:UpdateIncomingAbsorbsEvent("UpdateIncomingAbsorbsEvent", unit)
            end
        end)
    end
    
    self:RegisterMessage("GLADIUS_SPEC_UPDATE", "UpdateColorEvent")

    if not self.frame then
        self.frame = {}
    end
end

function HealthBar:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:Hide()
	end
end

function HealthBar:GetAttachType(unit)
	return "Bar"
end

function HealthBar:GetBarHeight(unit)
	return self.db[unit].healthBarHeight
end

function HealthBar:GetBarOrder(unit)
	return self.db[unit].healthBarOrder
end

function HealthBar:GetModuleAttachPoints()
	return {
		["HealthBar"] = L["HealthBar"],
	}
end

function HealthBar:GetModuleAttachFrame(unit)
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	return self.frame[unit]
end

function HealthBar:UpdateColorEvent(event, unit)
	self:UpdateColor(unit)
end

function HealthBar:UpdateHealthEvent(event, unit)
	if UnitExists(unit) then
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		self:UpdateHealth(unit, health, maxHealth)
	else
		self:UpdateHealth(unit, 1, 1)
	end
end

function HealthBar:UpdateIncomingHealsEvent(event, unit)
	self:UpdateIncomingHeals(unit)
end

function HealthBar:UpdateIncomingAbsorbsEvent(event, unit)
	self:UpdateIncomingAbsorbs(unit)
end

function HealthBar:UpdateColor(unit)
	if not self.frame[unit] then return end

	local class
	if GladiusEx:IsTesting(unit) then
		class = GladiusEx.testing[unit].unitClass
	else
		class = select(2, UnitClass(unit)) or GladiusEx.buttons[unit].class
	end

	-- set color
	local color
	if self.db[unit].healthBarClassColor and class then
		color = self:GetBarColor(class)
	else
		color = self.db[unit].healthBarColor
	end
	self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
end

function HealthBar:UpdateHealth(unit, health, maxHealth)
	if not self.frame[unit] then return end

	self.frame[unit].health = health
	self.frame[unit].maxHealth = maxHealth

	-- update min max values
	self.frame[unit]:SetMinMaxValues(0, maxHealth)

	-- inverse bar
	if self.db[unit].healthBarInverse then
		self.frame[unit]:SetValue(maxHealth - health)
	else
		self.frame[unit]:SetValue(health)
	end

	-- update incoming bars
	self:UpdateIncomingHeals(unit)
	self:UpdateIncomingAbsorbs(unit)
end

function HealthBar:SetIncomingBarAmount(unit, bar, incamount, inccap)
	local health = self.frame[unit].health
	local maxHealth = self.frame[unit].maxHealth
	local barWidth = self.frame[unit]:GetWidth()


	-- cap amount
	incamount = min((maxHealth * (1 + inccap)) - health, incamount)

	local value
	if self.db[unit].healthBarInverse then
		value = maxHealth - health
	else
		value = health
	end

	if incamount == 0 then
		bar:Hide()
	else
		local parent = self.frame[unit]
		local ox = value / maxHealth * barWidth

		if self.db[unit].healthBarInverse then
			bar:SetPoint("TOPRIGHT", parent, "TOPLEFT", ox, 0)
			bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", ox, 0)
		else
			bar:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, 0)
			bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", ox, 0)
		end
		bar:SetWidth(incamount / maxHealth * barWidth)

		-- set tex coords so that the incoming bar follows the bar texture
		local left = value / maxHealth
		local right = (value + incamount) / maxHealth
		bar:SetTexCoord(left, right, 0, 1)
		bar:Show()
	end
end

function HealthBar:UpdateIncomingHeals(unit)
	if not self.frame[unit] then return end
	if not self.db[unit].healthBarIncomingHeals then return end

  -- TODO integrate with HealComm if present
	local incamount = UnitGetIncomingHeals and UnitGetIncomingHeals(unit) or 0
	self:SetIncomingBarAmount(unit, self.frame[unit].incheals, incamount, self.db[unit].healthBarIncomingHealsCap)
end

function HealthBar:UpdateIncomingAbsorbs(unit)
	if not self.frame[unit] then return end
	if not self.db[unit].healthBarIncomingAbsorbs then return end

	local incamount = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or 0
	self:SetIncomingBarAmount(unit, self.frame[unit].incabsorbs, incamount, self.db[unit].healthBarIncomingAbsorbsCap)
end

function HealthBar:GetBarColor(class)
	return RAID_CLASS_COLORS[class] or { r = 0, g = 1, b = 0 }
end

function HealthBar:CreateBar(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create bar + text
	self.frame[unit] = CreateFrame("STATUSBAR", "GladiusEx" .. self:GetName() .. unit, button)
	self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "Background", "BACKGROUND")
	self.frame[unit].background:SetAllPoints()

	self.frame[unit].inc_frame = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit .. "IncBars", self.frame[unit])
	self.frame[unit].inc_frame:SetAllPoints()

	self.frame[unit].incabsorbs = self.frame[unit].inc_frame:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "IncAbsorbs", "OVERLAY", nil, 6)
	self.frame[unit].incheals = self.frame[unit].inc_frame:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "IncHeals", "OVERLAY", nil, 7)
end

function HealthBar:Refresh(unit)
	self:UpdateColorEvent("Refresh", unit)
	self:UpdateHealthEvent("Refresh", unit)
end

function HealthBar:Update(unit)
	-- create power bar
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	local bar_texture = self.db[unit].healthBarGlobalTexture and LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusEx.db.base.globalBarTexture) or LSM:Fetch(LSM.MediaType.STATUSBAR, self.db[unit].healthBarTexture)
	self.frame[unit]:SetStatusBarTexture(bar_texture)
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
	self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)

	-- incframe
	self.frame[unit].inc_frame:SetFrameLevel(10)

	-- incoming heals
	self.frame[unit].incheals:ClearAllPoints()
	self.frame[unit].incheals:SetTexture(bar_texture, true)
	local color = self.db[unit].healthBarIncomingHealsColor
	self.frame[unit].incheals:SetVertexColor(color.r, color.g, color.b, color.a)
	self.frame[unit].incheals:Hide()

	-- incoming absorbs
	self.frame[unit].incabsorbs:ClearAllPoints()
	self.frame[unit].incabsorbs:SetTexture(bar_texture, true)
	local color = self.db[unit].healthBarIncomingAbsorbsColor
	self.frame[unit].incabsorbs:SetVertexColor(color.r, color.g, color.b, color.a)
	self.frame[unit].incabsorbs:Hide()

	-- update health bar background
	self.frame[unit].background:SetTexture(bar_texture)
	self.frame[unit].background:SetVertexColor(self.db[unit].healthBarBackgroundColor.r, self.db[unit].healthBarBackgroundColor.g,
		self.db[unit].healthBarBackgroundColor.b, self.db[unit].healthBarBackgroundColor.a)
	self.frame[unit].background:SetHorizTile(false)
	self.frame[unit].background:SetVertTile(false)

	-- hide frame
	self.frame[unit]:Hide()
end

function HealthBar:Show(unit)
	-- update color
	self:UpdateColorEvent("Show", unit)

	-- call event
	self:UpdateHealthEvent("Show", unit)

	-- show frame
	self.frame[unit]:Show()
end

function HealthBar:Reset(unit)
	if not self.frame[unit] then return end

	-- reset bar
	self.frame[unit]:SetMinMaxValues(0, 1)
	self.frame[unit]:SetValue(1)

	-- hide
	self.frame[unit]:Hide()
end

function HealthBar:Test(unit)
	-- set test values
	local maxHealth = GladiusEx.testing[unit].maxHealth
	local health = GladiusEx.testing[unit].health
	self:UpdateColorEvent("Test", unit)
	self:UpdateHealth(unit, health, maxHealth)
	if self.db[unit].healthBarIncomingHeals then self:SetIncomingBarAmount(unit, self.frame[unit].incheals, maxHealth * 0.1, self.db[unit].healthBarIncomingHealsCap) end
	if self.db[unit].healthBarIncomingAbsorbs then self:SetIncomingBarAmount(unit, self.frame[unit].incabsorbs, maxHealth * 0.2, self.db[unit].healthBarIncomingAbsorbsCap) end
end

function HealthBar:GetOptions(unit)
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
						healthBarClassColor = {
							type = "toggle",
							name = L["Class color"],
							desc = L["Toggle health bar class color"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						healthBarColor = {
							type = "color",
							name = L["Color"],
							desc = L["Color of the health bar"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return self.db[unit].healthBarClassColor or not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						healthBarBackgroundColor = {
							type = "color",
							name = L["Background color"],
							desc = L["Color of the health bar background"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 15,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						healthBarInverse = {
							type = "toggle",
							name = L["Inverse"],
							desc = L["Invert the bar colors"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 21,
						},
						healthBarGlobalTexture = {
							type = "toggle",
							name = L["Use global texture"],
							desc = L["Use the global bar texture"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 24,
						},
						healthBarTexture = {
							type = "select",
							name = L["Texture"],
							desc = L["Texture of the health bar"],
							dialogControl = "LSM30_Statusbar",
							values = LSM.MediaTable.statusbar,
							disabled = function() return self.db[unit].healthBarGlobalTexture or not self:IsUnitEnabled(unit) end,
							order = 25,
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
						healthBarHeight = {
							type = "range",
							name = L["Height"],
							desc = L["Height of the health bar"],
							softMin = -25, softMax = 25, bigStep = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 3,
					args = {
						healthBarOrder = {
							type = "range",
							name = L["Bar order"],
							desc = L["Bar order"],
							softMin = 1, softMax = 10, bigStep = 1,
							disabled = function() return  not self:IsUnitEnabled(unit) end,
							order = 1,
						},
					},
				},
			},
		},
		incoming = {
			type = "group",
			name = L["Incoming heals"],
			order = 2,
			args = {
				heals = {
					type = "group",
					name = L["Incoming heals"],
					desc = L["Incoming heals settings"],
					inline = true,
					order = 1,
					args = {
						healthBarIncomingHeals = {
							type = "toggle",
							name = L["Show incoming heals"],
							desc = L["Toggle display of incoming heals in the health bar"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						healthBarIncomingHealsColor = {
							type = "color",
							name = L["Incoming heals color"],
							desc = L["Incoming heals bar color"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 2,
						},
						healthBarIncomingHealsCap = {
							type = "range",
							name = L["Outside bar limit"],
							desc = L["How much the incoming heals bar can grow outside the health bar, as a proportion of the unit's total health"],
							min = 0, softMax = 1, bigStep = 0.01, isPercent = true,
							width = "double",
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
						},
					}
				},
				absorbs = {
					type = "group",
					name = L["Absorbs"],
					desc = L["Absorbs settings"],
					inline = true,
					order = 2,
					args = {
						healthBarIncomingAbsorbs = {
							type = "toggle",
							name = L["Show absorbs"],
							desc = L["Toggle display of absorbs in the health bar"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						healthBarIncomingAbsorbsColor = {
							type = "color",
							name = L["Absorbs color"],
							desc = L["Absorbs bar color"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 2,
						},
						healthBarIncomingAbsorbsCap = {
							type = "range",
							name = L["Outside bar limit"],
							desc = L["How much the absorbs bar can grow outside the health bar, as a proportion of the unit's total health"],
							min = 0, softMax = 1, bigStep = 0.01, isPercent = true,
							width = "double",
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
						},
					}
				}
			}
		}
	}
end
