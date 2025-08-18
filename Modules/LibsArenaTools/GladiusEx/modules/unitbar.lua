local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")
local fn = LibStub("LibFunctional-1.0")

-- global functions
local strfind = string.find
local select, pairs, unpack = select, pairs, unpack
local UnitExists, UnitIsUnit, UnitClass = UnitExists, UnitIsUnit, UnitClass
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax

function GladiusEx:NewUnitBarModule(name, defaults_arena, defaults_party)
	local UnitBar = GladiusEx:NewGladiusExModule(name, defaults_arena, defaults_party)

	UnitBar.frame = {}
	UnitBar.unit_map = {}

	function UnitBar:OnEnable()
		self:RegisterEvent("UNIT_HEALTH")
		self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
		self:RegisterCustomEvents()
	end

	function UnitBar:OnDisable()
		self:UnregisterAllEvents()

		for unit in pairs(self.frame) do
			self.frame[unit]:Hide()
		end
	end

	function UnitBar:GetModuleAttachPoints()
		return {
			[name] = L[name],
		}
	end

	function UnitBar:GetModuleAttachFrame(unit)
		if not self.frame[unit] then
			self:CreateBar(unit)
		end

		return self.frame[unit].statusbar
	end

	function UnitBar:SetClassIcon(unit)
		if not self.frame[unit] then return end
		local funit = self.frame[unit].statusbar.unit

		-- get unit class
		local class
		if not GladiusEx:IsTesting(unit) then
			class = select(2, UnitClass(funit))
		else
			class = GladiusEx.testing[unit].unitClass
		end

		if class then
			-- color
			local color = self.db[unit].ClassColor and self:GetBarColor(class) or self.db[unit].Color

			self.frame[unit].statusbar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
			self.frame[unit].icon:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
			local left, right, top, bottom = unpack(CLASS_ICON_TCOORDS[class])
			if self.db[unit].IconCrop then
				local n = 5
				-- zoom class icon
				left = left + (right - left) * (n / 64)
				right = right - (right - left) * (n / 64)
				top = top + (bottom - top) * (n / 64)
				bottom = bottom - (bottom - top) * (n / 64)
			end

			self.frame[unit].icon:SetTexCoord(left, right, top, bottom)

		end
	end

	function UnitBar:UNIT_HEALTH(event, unit)
		local owner_unit = self.unit_map[unit]
		if owner_unit then
			self:UpdateHealth(owner_unit, UnitHealth(unit), UnitHealthMax(unit))
		end
	end

	function UnitBar:UpdateHealth(unit, health, maxHealth)
		-- update min max values
		self.frame[unit].statusbar:SetMinMaxValues(0, maxHealth)

		-- inverse bar
		if self.db[unit].Inverse then
			self.frame[unit].statusbar:SetValue(maxHealth - health)
		else
			self.frame[unit].statusbar:SetValue(health)
		end
	end

	function UnitBar:GetBarColor(class)
		return RAID_CLASS_COLORS[class]
	end

	local polling_time = 0.5
	local function UnitBar_OnUpdate(frame, elapsed)
		frame.next_update = frame.next_update - elapsed
		if frame.next_update <= 0 then
			frame.next_update = polling_time
			UnitBar:Refresh(frame.owner_unit)
		end
	end

	function UnitBar:Show(unit)
		local testing = GladiusEx:IsTesting(unit)

		if self.frame[unit].statusbar.poll then
			-- not a real unit so it needs to be polled
			self.frame[unit]:SetScript("OnUpdate", UnitBar_OnUpdate)
		end

		-- show frame
		self.frame[unit]:Show()
	end

	function UnitBar:Reset(unit)
		if not self.frame[unit] then return end

		-- reset bar
		self.frame[unit].statusbar:SetMinMaxValues(0, 1)
		self.frame[unit].statusbar:SetValue(1)

		-- reset texture
		self.frame[unit].icon:SetTexture("")

		-- hide
		self.frame[unit]:Hide()
		self.frame[unit]:SetScript("OnUpdate", nil)
	end

	function UnitBar:Refresh(unit)
		-- create bar
		if not self.frame[unit] then
			self:CreateBar(unit)
		end
		local tunit = self.frame[unit].statusbar.unit
		if UnitExists(tunit) then
			self:SetClassIcon(unit)
			self:UpdateHealth(unit, UnitHealth(tunit), UnitHealthMax(tunit))
			self.frame[unit].parent:Show()
		else
			self.frame[unit].parent:Hide()
		end
	end

	function UnitBar:Test(unit)
		-- set test values
		local maxHealth = GladiusEx.testing[unit].maxHealth
		local health = GladiusEx.testing[unit].health
		self:SetClassIcon(unit)
		self:UpdateHealth(unit, health, maxHealth)
		self.frame[unit].parent:Show()
		self.frame[unit]:SetScript("OnUpdate", nil)
	end

	function UnitBar:CreateBar(unit)
		local button = GladiusEx.buttons[unit]
		if not button then return end

		if self.frame[unit] then return end

		local tunit, poll = self:GetFrameUnit(unit)

		-- create bar + text
		self.frame[unit] = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit, button)
		self.frame[unit].parent = CreateFrame("Frame", nil, self.frame[unit])
		self.frame[unit].secure = CreateFrame("Button", "GladiusEx" .. self:GetName() .. "Secure" .. unit, button, "SecureActionButtonTemplate")
		self.frame[unit].statusbar = CreateFrame("STATUSBAR", "GladiusEx" .. self:GetName() .. "Bar" .. unit, self.frame[unit].parent)
		self.frame[unit].background = self.frame[unit].parent:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "Background", "BACKGROUND")
		self.frame[unit].icon = self.frame[unit].parent:CreateTexture("GladiusEx" .. self:GetName() .. "IconFrame" .. unit, "ARTWORK")
		self.frame[unit].secure:SetAttribute("unit", tunit)
		self.frame[unit].secure:SetAttribute("type1", "target")
		self.frame[unit].statusbar.unit = tunit
		self.frame[unit].statusbar.poll = poll
		self.frame[unit].owner_unit = unit
		self.frame[unit].next_update = 0

		self.unit_map[tunit] = unit

		-- clique support
		ClickCastFrames = ClickCastFrames or {}
		ClickCastFrames[self.frame[unit].secure] = true
	end

	function UnitBar:Update(unit)
		-- create bar
		if not self.frame[unit] then
			self:CreateBar(unit)
		end

		local parent = GladiusEx:GetAttachFrame(unit, self.db[unit].AttachTo)
		local width = self.db[unit].Width
		local height = self.db[unit].Height
		local bar_texture = self.db[unit].GlobalTexture and LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusEx.db.base.globalBarTexture) or LSM:Fetch(LSM.MediaType.STATUSBAR, self.db[unit].Texture)

		self.frame[unit]:ClearAllPoints()
		self.frame[unit]:SetPoint(self.db[unit].Anchor, parent, self.db[unit].RelativePoint, self.db[unit].OffsetX, self.db[unit].OffsetY)
		self.frame[unit]:SetWidth(width)
		self.frame[unit]:SetHeight(height)

		-- update icon
		self.frame[unit].icon:ClearAllPoints()
		if self.db[unit].Icon then
			self.frame[unit].icon:SetPoint(self.db[unit].IconPosition, self.frame[unit], self.db[unit].IconPosition)
			self.frame[unit].icon:SetWidth(height)
			self.frame[unit].icon:SetHeight(height)
			self.frame[unit].icon:SetTexCoord(0, 1, 0, 1)
			self.frame[unit].icon:Show()
		else
			self.frame[unit].icon:Hide()
		end

		-- update health bar
		self.frame[unit].statusbar:ClearAllPoints()
		if self.db[unit].Icon then
			if self.db[unit].IconPosition == "LEFT" then
				self.frame[unit].statusbar:SetPoint("LEFT", self.frame[unit].icon, "RIGHT")
				self.frame[unit].statusbar:SetPoint("RIGHT", self.frame[unit], "RIGHT")
			else
				self.frame[unit].statusbar:SetPoint("LEFT", self.frame[unit], "LEFT")
				self.frame[unit].statusbar:SetPoint("RIGHT", self.frame[unit].icon, "LEFT")
			end
			self.frame[unit].statusbar:SetHeight(height)
		else
			self.frame[unit].statusbar:SetAllPoints(self.frame[unit])
		end
		self.frame[unit].statusbar:SetMinMaxValues(0, 100)
		self.frame[unit].statusbar:SetValue(100)
		self.frame[unit].statusbar:SetStatusBarTexture(bar_texture)
		self.frame[unit].statusbar:GetStatusBarTexture():SetHorizTile(false)
		self.frame[unit].statusbar:GetStatusBarTexture():SetVertTile(false)

		-- update health bar background
		self.frame[unit].background:ClearAllPoints()
		self.frame[unit].background:SetAllPoints(self.frame[unit])
		self.frame[unit].background:SetTexture(bar_texture)
		self.frame[unit].background:SetVertexColor(self.db[unit].BackgroundColor.r, self.db[unit].BackgroundColor.g,
			self.db[unit].BackgroundColor.b, self.db[unit].BackgroundColor.a)
		self.frame[unit].background:SetHorizTile(false)
		self.frame[unit].background:SetVertTile(false)

		-- update secure frame
		self.frame[unit].secure:ClearAllPoints()
		self.frame[unit].secure:SetPoint(self.db[unit].Anchor, parent, self.db[unit].RelativePoint, self.db[unit].OffsetX, self.db[unit].OffsetY)
		self.frame[unit].secure:SetWidth(width)
		self.frame[unit].secure:SetHeight(height)
		self.frame[unit].secure:SetFrameStrata("MEDIUM")
		self.frame[unit].secure:RegisterForClicks("AnyDown", "AnyUp")

		-- hide frame
		self.frame[unit]:Hide()
	end

	function UnitBar:GetOptions(unit)
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
							ClassColor = {
								type = "toggle",
								name = L["Class color"],
								desc = L["Toggle health bar class color"],
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 5,
							},
							Color = {
								type = "color",
								name = L["Color"],
								desc = L["Color of the health bar"],
								hasAlpha = true,
								get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
								set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
								disabled = function() return self.db[unit].ClassColor or not self:IsUnitEnabled(unit) end,
								order = 10,
							},
							BackgroundColor = {
								type = "color",
								name = L["Background color"],
								desc = L["Color of the health bar background"],
								hasAlpha = true,
								get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
								set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 15,
							},
							sep3 = {
								type = "description",
								name = "",
								width = "full",
								order = 17,
							},
							Inverse = {
								type = "toggle",
								name = L["Inverse"],
								desc = L["Invert the bar colors"],
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 20,
							},
							sep4 = {
								type = "description",
								name = "",
								width = "full",
								order = 21,
							},
							GlobalTexture = {
								type = "toggle",
								name = L["Use global texture"],
								desc = L["Use the global bar texture"],
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 22,
							},
							Texture = {
								type = "select",
								name = L["Texture"],
								desc = L["Texture of the health bar"],
								dialogControl = "LSM30_Statusbar",
								values = LSM.MediaTable.statusbar,
								disabled = function() return self.db[unit].GlobalTexture or not self:IsUnitEnabled(unit) end,
								order = 25,
							},
							sep5 = {
								type = "description",
								name = "",
								width = "full",
								order = 27,
							},
							Icon = {
								type = "toggle",
								name = L["Class icon"],
								desc = L["Toggle the class icon"],
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 30,
							},
							IconPosition = {
								type = "select",
								name = L["Icon position"],
								desc = L["Position of the class icon"],
								values = { ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] },
								disabled = function() return not self.db[unit].Icon or not self:IsUnitEnabled(unit) end,
								order = 35,
							},
							IconCrop = {
								type = "toggle",
								name = L["Crop borders"],
								desc = L["Toggle if the icon borders should be cropped or not"],
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 40,
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
							Width = {
								type = "range",
								name = L["Width"],
								desc = L["Frame width"],
								softMin = 10, softMax = 500, bigStep = 1,
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 15,
							},
							Height = {
								type = "range",
								name = L["Height"],
								desc = L["Frame height"],
								softMin = 10, softMax = 200, bigStep = 1,
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
							AttachTo = {
								type = "select",
								name = L["Attach to"],
								desc = L["Attach to the given frame"],
								values = function() return self:GetOtherAttachPoints(unit) end,
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 1,
							},
							Position = {
								type = "select",
								name = L["Position"],
								desc = L["Position of the frame"],
								values = GladiusEx:GetSimplePositions(),
								get = function()
									return GladiusEx:AnchorToSimplePosition(self.db[unit].Anchor, self.db[unit].RelativePoint)
								end,
								set = function(info, value)
									self.db[unit].Anchor, self.db[unit].RelativePoint = GladiusEx:SimplePositionToAnchor(value)
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
							Anchor = {
								type = "select",
								name = L["Anchor"],
								desc = L["Anchor of the frame"],
								values = GladiusEx:GetPositions(),
								disabled = function() return not self:IsUnitEnabled(unit) end,
								hidden = function() return not GladiusEx.db.base.advancedOptions end,
								order = 10,
							},
							RelativePoint = {
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
							OffsetX = {
								type = "range",
								name = L["Offset X"],
								desc = L["X offset of the frame"],
								softMin = -100, softMax = 100, bigStep = 1,
								disabled = function() return  not self:IsUnitEnabled(unit) end,
								order = 20,
							},
							OffsetY = {
								type = "range",
								name = L["Offset Y"],
								desc = L["Y offset of the frame"],
								softMin = -100, softMax = 100, bigStep = 1,
								disabled = function() return not self:IsUnitEnabled(unit) end,
								order = 25,
							},
						},
					},
				},
			},
		}
	end

	return UnitBar
end
