local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")

-- global functions
local strfind, pairs = string.find, pairs
local abs = math.abs
local GetRealNumRaidMembers, GetPartyAssignment, GetRaidTargetIndex = GetRealNumRaidMembers, GetPartyAssignment, GetRaidTargetIndex
local UnitGUID = UnitGUID

local Highlight = GladiusEx:NewGladiusExModule("Highlight", {
	highlightBorderWidth = 2,

	highlightHover = true,
	highlightHoverColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },

	highlightTarget = true,
	highlightTargetColor = { r = 1, g = .7, b = 0, a = 1 },
	highlightTargetPriority = 10,

	highlightFocus = true,
	highlightFocusColor = { r = 0, g = 0, b = 1, a = 1 },
	highlightFocusPriority = 0,

	highlightAssist = true,
	highlightAssistColor = { r = 0, g = 1, b = 0, a = 1 },
	highlightAssistPriority = 9,

	highlightRaidIcon1 = false,
	highlightRaidIcon1Color = { r = 1, g = 1, b = 0, a = 1 },
	highlightRaidIcon1Priority = 8,

	highlightRaidIcon2 = false,
	highlightRaidIcon2Color = { r = 1, g = 0.55, b = 0, a = 1 },
	highlightRaidIcon2Priority = 7,

	highlightRaidIcon3 = false,
	highlightRaidIcon3Color = { r = 1, g = 0.08, b = 0.58, a = 1 },
	highlightRaidIcon3Priority = 6,

	highlightRaidIcon4 = false,
	highlightRaidIcon4Color = { r = 0.13, g = 0.55, b = 0.13, a = 1 },
	highlightRaidIcon4Priority = 5,

	highlightRaidIcon5 = false,
	highlightRaidIcon5Color = { r = 0.86, g = 0.86, b = 0.86, a = 1 },
	highlightRaidIcon5Priority = 4,

	highlightRaidIcon6 = false,
	highlightRaidIcon6Color = { r = 0.12, g = 0.56, b = 1.0, a = 1 },
	highlightRaidIcon6Priority = 3,

	highlightRaidIcon7 = false,
	highlightRaidIcon7Color = { r = 1, g = 0.27, b = 0, a = 1 },
	highlightRaidIcon7Priority = 2,

	highlightRaidIcon8 = true,
	highlightRaidIcon8Color = { r = 1, g = 0, b = 0, a = 1 },
	highlightRaidIcon8Priority = 1,
})

function Highlight:OnEnable()
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "UNIT_TARGET")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UNIT_TARGET")
	self:RegisterEvent("RAID_TARGET_UPDATE", "UNIT_TARGET")

	-- frame
	if not self.frame then
		self.frame = {}
	end
end

function Highlight:OnDisable()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function Highlight:GetFrames()
	return nil
end

function Highlight:UNIT_TARGET(event, unit)
	local unit = unit or ""

	local playerTargetGUID = UnitGUID("target")
	local focusGUID = UnitGUID("focus")
	local targetGUID = UnitGUID(unit .. "target")

	for arenaUnit, frame in pairs(self.frame) do
		-- reset
		self:Reset(arenaUnit)

		if (targetGUID and UnitGUID(arenaUnit) == targetGUID and unit ~= "") then
			-- main assist
			if (self.db[arenaUnit].highlightAssist and GetPartyAssignment("MAINASSIST", unit) == 1) then
				if (frame.priority < self.db[arenaUnit].highlightTargetPriority) then
					frame.priority = self.db[arenaUnit].highlightTargetPriority
					frame:SetBackdropBorderColor(self.db[arenaUnit].highlightTargetColor.r, self.db[arenaUnit].highlightTargetColor.g, self.db[arenaUnit].highlightTargetColor.b, self.db[arenaUnit].highlightTargetColor.a)
				end
			end
		end

		-- raid target icon
		local icon = GetRaidTargetIndex(arenaUnit)
		if (icon and self.db[arenaUnit]["highlightRaidIcon" .. icon]) then
			if (frame.priority < self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Priority"]) then
				frame.priority = self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Priority"]
				frame:SetBackdropBorderColor(self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Color"].r, self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Color"].g,
					self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Color"].b, self.db[arenaUnit]["highlightRaidIcon" .. icon .. "Color"].a)
			end
		end

		-- focus
		if (focusGUID and UnitGUID(arenaUnit) == focusGUID) then
			if (frame.priority < self.db[arenaUnit].highlightFocusPriority) then
				frame.priority = self.db[arenaUnit].highlightFocusPriority
				frame:SetBackdropBorderColor(self.db[arenaUnit].highlightFocusColor.r, self.db[arenaUnit].highlightFocusColor.g, self.db[arenaUnit].highlightFocusColor.b, self.db[arenaUnit].highlightFocusColor.a)
			end
		end

		-- player target
		if (playerTargetGUID and UnitGUID(arenaUnit) == playerTargetGUID) then
			if (frame.priority < self.db[arenaUnit].highlightTargetPriority) then
				frame.priority = self.db[arenaUnit].highlightTargetPriority
				frame:SetBackdropBorderColor(self.db[arenaUnit].highlightTargetColor.r, self.db[arenaUnit].highlightTargetColor.g, self.db[arenaUnit].highlightTargetColor.b, self.db[arenaUnit].highlightTargetColor.a)
			end
		end
	end
end

function Highlight:CreateFrame(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create frame
	self.frame[unit] = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. "Border" .. unit, button, "BackdropTemplate")
	self.frame[unit].highlight = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit, button)
	self.frame[unit].highlight:SetAllPoints()
	self.frame[unit].highlight:SetFrameStrata("HIGH")
	self.frame[unit].highlight_texture = self.frame[unit].highlight:CreateTexture(nil, "OVERLAY")
	self.frame[unit].highlight_texture:SetAllPoints()

	-- set priority
	self.frame[unit].priority = -1
end

function Highlight:Update(unit)
	-- create frame
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end

	-- update frame
	local w = GladiusEx:AdjustPixels(self.frame[unit], self.db[unit].highlightBorderWidth)
	self.frame[unit]:ClearAllPoints()
	self.frame[unit]:SetPoint("TOPLEFT", GladiusEx.buttons[unit], "TOPLEFT", -w, w)
	self.frame[unit]:SetPoint("BOTTOMRIGHT", GladiusEx.buttons[unit], "BOTTOMRIGHT", w, -w)

	-- update hightlight
	self.frame[unit].highlight_texture:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	self.frame[unit].highlight_texture:SetDesaturated(true)
	self.frame[unit].highlight_texture:SetBlendMode("ADD")
	local color = self.db[unit].highlightHoverColor
	self.frame[unit].highlight_texture:SetVertexColor(color.r, color.g, color.b, color.a)
	self.frame[unit].highlight_texture:SetAlpha(1)
	self.frame[unit].highlight:SetAlpha(0)

	self.frame[unit]:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = w })
	self.frame[unit]:SetBackdropBorderColor(0, 0, 0, 0)

	-- update highlight
	local button = GladiusEx.buttons[unit]
	local secure = button.secure

	if self.db[unit].highlightHover then
		-- set scripts
		if not button.highlight_hooked then
			button.highlight_hooked = true

			local onenterhook = function(f, motion)
				if motion and f:GetAlpha() > 0 then
					self.frame[unit].highlight:SetAlpha(0.5)
				end
			end

			local onleavehook = function(f, motion)
				if motion then
					self.frame[unit].highlight:SetAlpha(0)
				end
			end

			button:HookScript("OnEnter", onenterhook)
			button:HookScript("OnLeave", onleavehook)

			secure:HookScript("OnEnter", onenterhook)
			secure:HookScript("OnLeave", onleavehook)
		end
	end

	-- hide
	self.frame[unit]:Hide()

	-- update
	self:UNIT_TARGET("UNIT_TARGET", unit)
end

function Highlight:Show(unit)
	-- show
	self.frame[unit]:Show()
end

function Highlight:Reset(unit)
	if not self.frame[unit] then return end

	-- set priority
	self.frame[unit].priority = -1

	-- hide border
	self.frame[unit]:SetBackdropBorderColor(0, 0, 0, 0)
end

function Highlight:Test(unit)
	-- test
end

function Highlight:GetOptions(unit)
	local options = {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				highlightBorderWidth = {
					type = "range",
					name = L["Highlight border width"],
					min = 1, max = 10, step = 1,
					disabled = function() return not self:IsUnitEnabled(unit) end,
					width = "double",
					order = 0.1,
				},
				hover = {
					type = "group",
					name = L["Hover"],
					desc = L["Hover settings"],
					inline = true,
					order = 1,
					args = {
						highlightHover = {
							type = "toggle",
							name = L["Highlight on mouseover"],
							desc = L["Highlight frame on mouseover"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						highlightHoverColor = {
							type = "color",
							name = L["Highlight color"],
							desc = L["Color of the highlight"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
					},
				},
				target = {
					type = "group",
					name = L["Player target"],
					desc = L["Player target settings"],
					inline = true,
					order = 2,
					args = {
						highlightTarget = {
							type = "toggle",
							name = L["Highlight player target"],
							desc = L["Show border around your target"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						highlightTargetColor = {
							type = "color",
							name = L["Highlight color"],
							desc = L["Color of the highlight"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						highlightTargetPriority = {
							type = "range",
							name = L["Priority"],
							desc = L["Priority of the highlight"],
							min = 0, max = 10, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							width = "double",
							order = 15,
						},
					},
				},
				focus = {
					type = "group",
					name = L["Player focus target"],
					desc = L["Player focus target settings"],
					inline = true,
					order = 2,
					args = {
						highlightFocus = {
							type = "toggle",
							name = L["Highlight focus target"],
							desc = L["Show border around your focus target"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						highlightFocusColor = {
							type = "color",
							name = L["Highlight color"],
							desc = L["Color of the highlight"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						highlightFocusPriority = {
							type = "range",
							name = L["Priority"],
							desc = L["Priority of the highlight"],
							min = 0, max = 10, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							width = "double",
							order = 15,
						},
					},
				},
				assist = {
					type = "group",
					name = L["Raid assist target"],
					desc = L["Raid assist settings"],
					inline = true,
					order = 2,
					args = {
						highlightAssist = {
							type = "toggle",
							name = L["Highlight raid assist target"],
							desc = L["Show border around raid assist"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						highlightAssistColor = {
							type = "color",
							name = L["Highlight color"],
							desc = L["Color of the highlight"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						highlightAssistPriority = {
							type = "range",
							name = L["Priority"],
							desc = L["Priority of the highlight"],
							min = 0, max = 10, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							width = "double",
							order = 15,
						},
					},
				},
			},
		},
		raidTargets = {
			type = "group",
			name = L["Raid target icons"],
			order = 2,
			args = {
			},
		},
	}

	-- raid targets
	for i = 1, 8 do
		options.raidTargets.args["raidTarget" .. i] = {
			type = "group",
			name = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ".blp:0|t " .. string.format(L["Raid target icon %i"], i),
			inline = true,
			order = i,
			args = {
				highlightRaidIcon = {
					type = "toggle",
					name = L["Highlight"],
					desc = string.format(L["Show border around raid target %i"],  i),
					disabled = function() return not self:IsUnitEnabled(unit) end,
					arg = "highlightRaidIcon" .. i,
					order = 5,
				},
				highlightRaidIconColor = {
					type = "color",
					name = L["Highlight color"],
					desc = L["Color of the highlight"],
					hasAlpha = true,
					get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
					set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
					disabled = function() return not self:IsUnitEnabled(unit) end,
					arg = "highlightRaidIcon" .. i .. "Color",
					order = 10,
				},
				highlightRaidIconPriority = {
					type = "range",
					name = L["Priority"],
					desc = L["Priority of the highlight"],
					min = 0, max = 10, step = 1,
					disabled = function() return not self:IsUnitEnabled(unit) end,
					arg = "highlightRaidIcon" .. i .. "Priority",
					width = "double",
					order = 15,
				},
			},
		}
	end

	return options
end
