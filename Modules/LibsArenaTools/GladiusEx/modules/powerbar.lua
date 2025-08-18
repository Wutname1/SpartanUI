local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")

-- global functions
local strfind = string.find
local pairs = pairs
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType

local PowerBar = GladiusEx:NewGladiusExModule("PowerBar", {
	powerBarAttachTo = "HealthBar",
	powerBarHeight = 0,
	powerBarAdjustWidth = true,
	powerBarWidth = 200,
	powerBarInverse = false,
	powerBarDefaultColor = true,
	powerBarColor = { r = 1, g = 1, b = 1, a = 1 },
	powerBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
	powerBarGlobalTexture = true,
	powerBarTexture = GladiusEx.default_bar_texture,
	powerBarOrder = 2,
	powerBarAnchor = "TOPLEFT",
	powerBarRelativePoint = "BOTTOMLEFT",
})

function PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_UPDATE", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_MANA", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdateColorEvent")
	self:RegisterMessage("GLADIUS_SPEC_UPDATE", "UpdateColorEvent")

	if not self.frame then
		self.frame = {}
	end
end

function PowerBar:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function PowerBar:GetAttachType(unit)
	return "Bar"
end

function PowerBar:GetBarHeight(unit)
	return self.db[unit].powerBarHeight
end

function PowerBar:GetBarOrder(unit)
	return self.db[unit].powerBarOrder
end

function PowerBar:GetModuleAttachPoints()
	return {
		["PowerBar"] = L["PowerBar"],
	}
end

function PowerBar:GetModuleAttachFrame(unit)
	if not self.frame[unit] then
		self:CreateBar(unit)
	end
	return self.frame[unit]
end

function PowerBar:UpdateColorEvent(event, unit)
	self:UpdateColor(unit)
end

function PowerBar:UpdateColor(unit)
	if not self.frame[unit] then return end

	-- get unit powerType
	local powerType
	if GladiusEx:IsTesting(unit) then
		powerType = GladiusEx.testing[unit].powerType
	elseif UnitExists(unit) then
		powerType = UnitPowerType(unit)
	end

	-- set color
	local color
	if powerType and self.db[unit].powerBarDefaultColor then
		color = self:GetBarColor(powerType)
	else
		color = self.db[unit].powerBarColor
	end
	self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)

	-- update power
	self:UpdatePowerEvent("UpdateColor", unit)
end

function PowerBar:UpdatePowerEvent(event, unit)
	if UnitExists(unit) then
		local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
		self:UpdatePower(unit, power, maxPower)
	else
		self:UpdatePower(unit, 1, 1)
	end
end

function PowerBar:UpdatePower(unit, power, maxPower)
	if not self.frame[unit] then return end

	-- update min max values
	self.frame[unit]:SetMinMaxValues(0, maxPower)

	-- inverse bar
	if self.db[unit].powerBarInverse then
		self.frame[unit]:SetValue(maxPower - power)
	else
		self.frame[unit]:SetValue(power)
	end
end

function PowerBar:GetBarColor(powerType)
	return PowerBarColor[powerType]
end

function PowerBar:CreateBar(unit)
	local button = GladiusEx.buttons[unit]
	if (not button) then return end

	-- create bar + text
	self.frame[unit] = CreateFrame("STATUSBAR", "GladiusEx" .. self:GetName() .. unit, button)
	self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "Background", "BACKGROUND")
	self.frame[unit].background:SetAllPoints()
end

function PowerBar:Refresh(unit)
	self:UpdateColorEvent("Refresh", unit)
	self:UpdatePowerEvent("Refresh", unit)
end

function PowerBar:Update(unit)
	local testing = GladiusEx:IsTesting(unit)

	-- create power bar
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	-- update statusbar
	local bar_texture = self.db[unit].powerBarGlobalTexture and LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusEx.db.base.globalBarTexture) or LSM:Fetch(LSM.MediaType.STATUSBAR, self.db[unit].powerBarTexture)
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(bar_texture)
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
	self.frame[unit]:GetStatusBarTexture():SetVertTile(false)

	-- update background
	self.frame[unit].background:SetTexture(bar_texture)
	self.frame[unit].background:SetVertexColor(self.db[unit].powerBarBackgroundColor.r, self.db[unit].powerBarBackgroundColor.g,
	self.db[unit].powerBarBackgroundColor.b, self.db[unit].powerBarBackgroundColor.a)
	self.frame[unit].background:SetHorizTile(false)
	self.frame[unit].background:SetVertTile(false)

	-- hide frame
	self.frame[unit]:Hide()
end

function PowerBar:Show(unit)
	if not self.frame[unit] then return end

	-- show frame
	self.frame[unit]:Show()
end

function PowerBar:Reset(unit)
	if not self.frame[unit] then return end

	-- reset bar
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)

	-- hide
	self.frame[unit]:Hide()
end

function PowerBar:Test(unit)
	-- set test values
	local maxPower, power
	maxPower = GladiusEx.testing[unit].maxPower
	power = GladiusEx.testing[unit].power

	self:UpdateColorEvent("Test", unit)
	self:UpdatePower(unit, power, maxPower)
end

function PowerBar:GetOptions(unit)
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
						powerBarDefaultColor = {
							type = "toggle",
							name = L["Default color"],
							desc = L["Toggle default color"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						powerBarColor = {
							type = "color",
							name = L["Color"],
							desc = L["Color of the power bar"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return self.db[unit].powerBarDefaultColor or not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						powerBarBackgroundColor = {
							type = "color",
							name = L["Background color"],
							desc = L["Color of the power bar background"],
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
							order = 16,
						},
						powerBarInverse = {
							type = "toggle",
							name = L["Inverse"],
							desc = L["Invert the bar colors"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						sep3 = {
							type = "description",
							name = "",
							width = "full",
							order = 21,
						},
						powerBarGlobalTexture = {
							type = "toggle",
							name = L["Use global texture"],
							desc = L["Use the global bar texture"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 22,
						},
						powerBarTexture = {
							type = "select",
							name = L["Texture"],
							desc = L["Texture of the power bar"],
							dialogControl = "LSM30_Statusbar",
							values = LSM.MediaTable.statusbar,
							disabled = function() return self.db[unit].powerBarGlobalTexture or not self:IsUnitEnabled(unit) end,
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
						powerBarHeight = {
							type = "range",
							name = L["Height"],
							desc = L["Height of the power bar"],
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
						powerBarOrder = {
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
	}
end
