local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")

-- upvalues
local pairs = pairs
local min, max = math.min, math.max
local tinsert, tremove = table.insert, table.remove
local GetTime = GetTime
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture

local defaults = {
	MaxIcons = 2,
	IconSize = 20,
	Margin = 2,
	PaddingX = 0,
	PaddingY = 0,
	BackgroundColor = { r = 0, g = 0, b = 0, a = 0 },
	Crop = true,

	Timeout = 5,
	TimeoutAnimDuration = 0.5,

	EnterAnimDuration = 1.0,
	EnterAnimEase = "OUT",
	EnterAnimEaseMode = "CUBIC",
}

local MAX_ICONS = 40

local SkillHistory = GladiusEx:NewGladiusExModule("SkillHistory",
	fn.merge(defaults, {
		AttachTo = "CastBar",
		Anchor = "RIGHT",
		RelativePoint = "LEFT",
		GrowDirection = "LEFT",
		OffsetX = -2,
		OffsetY = 0,
	}),
	fn.merge(defaults, {
		AttachTo = "CastBar",
		Anchor = "LEFT",
		RelativePoint = "RIGHT",
		GrowDirection = "RIGHT",
		OffsetX = 2,
		OffsetY = 0,
	}))

function SkillHistory:OnEnable()
	if not self.frame then
		self.frame = {}
	end

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_NAME_UPDATE")
end

function SkillHistory:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:Hide()
	end
end

function SkillHistory:CreateFrame(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create frame
	self.frame[unit] = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit, button, "BackdropTemplate")
end

function SkillHistory:Update(unit)
	local testing = GladiusEx:IsTesting(unit)

	-- create frame
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end

	-- frame
	local parent = GladiusEx:GetAttachFrame(unit, self.db[unit].AttachTo)
	self.frame[unit]:ClearAllPoints()
	self.frame[unit]:SetPoint(self.db[unit].Anchor, parent, self.db[unit].RelativePoint, self.db[unit].OffsetX, self.db[unit].OffsetY)
	self.frame[unit]:SetFrameLevel(9)

	-- size
	self.frame[unit]:SetWidth(self.db[unit].MaxIcons * self.db[unit].IconSize + (self.db[unit].MaxIcons - 1) * self.db[unit].Margin + self.db[unit].PaddingX * 2)
	self.frame[unit]:SetHeight(self.db[unit].IconSize + self.db[unit].PaddingY * 2)

	-- backdrop
	local bgcolor = self.db[unit].BackgroundColor
	self.frame[unit]:SetBackdrop({ bgFile = [[Interface\Buttons\WHITE8X8]], tile = true, tileSize = 8 })
	self.frame[unit]:SetBackdropColor(bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a)

	-- icons
	if not self.frame[unit].enter then
		self:CreateIcon(unit, "enter")
	end
	self:UpdateIcon(unit, "enter")
	for i = 1, MAX_ICONS do
		if not self.frame[unit][i] then
			if i <= self.db[unit].MaxIcons then
				self:CreateIcon(unit, i)
			else
				break
			end
		end
		self:UpdateIcon(unit, i)
	end

	self:StopAnimation(unit)
	self:UpdateSpells(unit)

	self.frame[unit]:Hide()
end

function SkillHistory:Show(unit)
	self.frame[unit]:Show()
end

function SkillHistory:Reset(unit)
	if not self.frame[unit] then return end
	-- hide
	self:ClearUnit(unit)
	self.frame[unit]:Hide()
end

function SkillHistory:Test(unit)
	self:ClearUnit(unit)

	-- local spells = { GetSpecializationSpells(GetSpecialization()) }
	-- for i = 1, #spells / 2 do
	-- 	self:QueueSpell(unit, spells[i * 2 - 1], GetTime())
	-- end
	local specID, class, race
	specID = GladiusEx.testing[unit].specID
	class = GladiusEx.testing[unit].unitClass
	race = GladiusEx.testing[unit].unitRace
	local n = 1
	for spellid, spelldata in LibStub("LibCooldownTracker-1.0"):IterateCooldowns(class, specID, race) do
		self:QueueSpell(unit, spellid, GetTime() + n * self.db[unit].EnterAnimDuration)
		n = n + 1
	end
end

function SkillHistory:Refresh(unit)
end

local prev_lineid = {}
function SkillHistory:UNIT_SPELLCAST_SUCCEEDED(event, unit, lineID, spellId)
	if self.frame[unit] then
		--print("unit:"..unit.." just casted "..spellName.."="..spellId)
		-- casts with lineID = 0 seem to be secondary effects not directly casted by the unit
		if lineID ~= 0 and lineID ~= prev_lineid[unit] then
			prev_lineid[unit] = lineID
			self:QueueSpell(unit, spellId, GetTime())
		end
	end
end

function SkillHistory:UNIT_NAME_UPDATE(event, unit)
	if self.frame[unit] then
		self:ClearUnit(unit)
	end
end

local unit_spells = {}
local unit_queue = {}

function SkillHistory:QueueSpell(unit, spellid, time)
	if not unit_queue[unit] then unit_queue[unit] = {} end
	local uq = unit_queue[unit]

	-- avoid duplicate events
	-- if #uq > 0 then
	-- 	local last = uq[#uq]
	-- 	if last.spellid == spellid and (last.time + 1) > time then
	-- 		return
	-- 	end
	-- end

	-- replace trinket icon
	-- if spellid == 42292 then
	-- 	icon_alliance = [[Interface\Icons\INV_Jewelry_TrinketPVP_01]]
	-- 	icon_horde = [[Interface\Icons\INV_Jewelry_TrinketPVP_02]]
	-- end

	-- hide uninteresting spells
	-- 178293: Arena Inbounds Marker
	-- 199642: Necrotic Aura
	-- 199719: Heartstop Aura
	if spellid == 178293 or spellid == 199642 or spellid == 199719 then
		return
	end

	local entry = {
		["spellid"] = spellid,
		["time"] = time
	}

	tinsert(uq, entry)

	if not self:IsAnimating(unit) then
		self:SetupAnimation(unit)
	end
end

local function InverseDirection(direction)
	if direction == "LEFT" then
		return "RIGHT", -1
	elseif direction == "RIGHT" then
		return "LEFT", 1
	else
		assert(false, "Invalid grow direction")
	end
end

local ease_funcs = {
	["LINEAR"] = function(t) return t end,
	["QUAD"] = function(t) return t * t end,
	["CUBIC"] = function(t) return t * t * t end,
}

local ease_methods = {
	["NONE"] = function(f) return function(t) return t end end,
	["IN"] = function(f) return f end,
	["OUT"] = function(f) return function(t) return 1 - f(1 - t) end end,
	["IN_OUT"] = function(f) return function(t) return .5 * (t < .5 and f(2 * t) or (2 - f(2 - 2 * t))) end end,
}

local ease_cache = setmetatable({}, {
	__index = function(t1, func)
		assert(ease_funcs[func], "Unknown ease function " .. tostring(func))
		local m = setmetatable({}, {
			__index = function(t2, method)
				assert(ease_methods[method], "Invalid ease method " .. tostring(method))
				local f = ease_funcs[func]
				local m = ease_methods[method]
				local mf = m(f)
				rawset(t2, method, mf)
				return mf
			end
		})
		rawset(t1, func, m)
		return m
	end
})

local function GetEaseFunc(method, func)
	return ease_cache[func][method]
end

function SkillHistory:IsAnimating(unit)
	local frame = self.frame[unit]
	return frame and frame.animating
end

function SkillHistory:SetupAnimation(unit)
	local frame = self.frame[unit]
	local uq = unit_queue[unit]
	local us = unit_spells[unit]
	local entry = uq[1]

	local dir = self.db[unit].GrowDirection
	local iconsize = self.db[unit].IconSize
	local margin = self.db[unit].Margin
	local maxicons = self.db[unit].MaxIcons
	local crop = self.db[unit].Crop
	local animdur = self.db[unit].EnterAnimDuration
	-- speed up animation if there are too many queued spells
	if #uq >= 2 then
		animdur = animdur * 0.5
	end

	local st = GetTime()
	local off = iconsize + margin

	local enter = frame.enter
	local leave = frame[maxicons]

	enter.entry = entry
	enter.icon:SetTexture(GetSpellTexture(entry.spellid))
	--enter:SetAlpha(0)
	enter:Show()

	if leave then leave.icon:ClearAllPoints() end
	enter.icon:ClearAllPoints()

	local ease = GetEaseFunc(self.db[unit].EnterAnimEase, self.db[unit].EnterAnimEaseMode)

	-- while this could be implemented with AnimationGroups, they are more
	-- trouble than it is worth, sadly
	local function AnimationFrame()
		local t = (GetTime() - st) / animdur
		if t < 1 then
			t = ease(t)
			local ox = off * t
			local oy = 0
			-- move all but the last icon
			for i = 1, maxicons - 1 do
				if not frame[i] or not frame[i]:IsShown() then break end
				self:UpdateIconPosition(unit, i, ox, oy)
			end

			if leave then
				-- move the leaving icon with clipping
				self:UpdateIconPosition(unit, maxicons, ox, oy)
				local left, right
				if dir == "LEFT" then
					left = min(iconsize, ox)
					right = 0
				elseif dir == "RIGHT" then
					left = 0
					right = min(iconsize, ox)
				end
				leave.icon:SetPoint("TOPLEFT", left, 0)
				leave.icon:SetPoint("BOTTOMRIGHT", -right, 0)
				if crop then
					local n = 5
					local range = 1 - (n / 32)
					local texleft = n / 64 + (left / iconsize * range)
					local texright = n / 64 + ((1 - right / iconsize) * range)
					leave.icon:SetTexCoord(texleft, texright, n / 64, 1 - n / 64)
				else
					leave.icon:SetTexCoord(left / iconsize, 1 - right / iconsize, 0, 1)
				end

				-- fade out leaving icon to alpha 0
				--frame[maxicons]:SetAlpha(1 - t)
			end

			-- enter new icon with clipping
			self:UpdateIconPosition(unit, "enter", ox, oy)
			local left, right
			if dir == "LEFT" then
				left = 0
				right = iconsize - max(0, ox - margin)
			elseif dir == "RIGHT" then
				left = iconsize - max(0, ox - margin)
				right = 0
			end
			enter.icon:SetPoint("TOPLEFT", left, 0)
			enter.icon:SetPoint("BOTTOMRIGHT", -right, 0)
			if crop then
				local n = 5
				local range = 1 - (n / 32)
				local texleft = n / 64 + (left / iconsize * range)
				local texright = n / 64 + ((1 - right / iconsize) * range)
				enter.icon:SetTexCoord(texleft, texright, n / 64, 1 - n / 64)
			else
				enter.icon:SetTexCoord(left / iconsize, 1 - right / iconsize, 0, 1)
			end

			-- fade in enter icon to alpha 1
			--enter:SetAlpha(t)
		else
			-- restore last icon
			if leave then
				self:UpdateIcon(unit, maxicons)
			end

			-- after:
			--  updatespells, hide tmp1
			tremove(uq, 1)
			if #uq > 0 then
				self:SetupAnimation(unit)
			else
				self:StopAnimation(unit)
			end

			self:AddSpell(unit, entry)
		end
	end

	frame.animating = true
	frame:SetScript("OnUpdate", AnimationFrame)
	AnimationFrame()
end

function SkillHistory:StopAnimation(unit)
	local frame = self.frame[unit]
	frame.animating = false
	frame:SetScript("OnUpdate", nil)
	if frame.enter then
		frame.enter:Hide()
	end
end

function SkillHistory:ClearQueue(unit)
	unit_queue[unit] = {}
	self:StopAnimation(unit)
end

function SkillHistory:AddSpell(unit, entry)
	if not unit_spells[unit] then unit_spells[unit] = {} end
	local us = unit_spells[unit]

	tremove(us, self.db[unit].MaxIcons)
	tinsert(us, 1, entry)

	self:UpdateSpells(unit)
end

function SkillHistory:ClearSpells(unit)
	unit_spells[unit] = {}
	self:UpdateSpells(unit)
end

function SkillHistory:UpdateSpells(unit)
	local frame = self.frame[unit]
	local us = unit_spells[unit]
	if not frame or not us then return end

	local now = GetTime()
	local timeout = self.db[unit].Timeout
	local timeout_duration = self.db[unit].TimeoutAnimDuration
	local ease = GetEaseFunc(self.db[unit].EnterAnimEase, self.db[unit].EnterAnimEaseMode)

	-- remove timed out spells
	for i = #us, 1, -1 do
		if (us[i].time + timeout + timeout_duration) < now then
			tremove(us, i)
		else
			break
		end
	end

	-- update icons
	local n = min(#us, self.db[unit].MaxIcons)
	for i = 1, n do
		self:UpdateIconPosition(unit, i, 0, 0)

		local entry = unit_spells[unit][i]
		frame[i].entry = entry
		frame[i].icon:SetTexture(GetSpellTexture(entry.spellid))
		frame[i]:SetAlpha(1)
		frame[i]:Show()

		local function IconFadeFrame(icon)
			local t = (GetTime() - icon.entry.time - timeout) / timeout_duration
			if t >= 1 then
				icon:Hide()
				icon:SetScript("OnUpdate", nil)
			elseif t >= 0 then
				icon:SetAlpha(1 - ease(t))
			end
		end
		frame[i]:SetScript("OnUpdate", IconFadeFrame)
		IconFadeFrame(frame[i])
	end

	-- hide unused icons
	for i = n + 1, MAX_ICONS do
		if not frame[i] or not frame[i]:IsShown() then break end
		frame[i]:Hide()
		frame[i]:SetScript("OnUpdate", nil)
		frame[i].entry = false
	end
end

function SkillHistory:ClearUnit(unit)
	self:ClearQueue(unit)
	self:ClearSpells(unit)
end

function SkillHistory:CreateIcon(unit, i)
	self.frame[unit][i] = CreateFrame("Frame", nil, self.frame[unit])
	self.frame[unit][i].icon = self.frame[unit][i]:CreateTexture(nil, "OVERLAY")

	self.frame[unit][i]:EnableMouse(false)
	self.frame[unit][i]:SetScript("OnEnter", function(self)
		if self.entry then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetSpellByID(self.entry.spellid)
		end
	end)
	self.frame[unit][i]:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
end

function SkillHistory:UpdateIcon(unit, index)
	self.frame[unit][index]:ClearAllPoints()
	self.frame[unit][index]:SetSize(self.db[unit].IconSize, self.db[unit].IconSize)
	self.frame[unit][index].icon:SetAllPoints()

	-- crop
	if self.db[unit].Crop then
		local n = 5
		self.frame[unit][index].icon:SetTexCoord(n / 64, 1 - n / 64, n / 64, 1 - n / 64)
	else
		self.frame[unit][index].icon:SetTexCoord(0, 1, 0, 1)
	end
end

function SkillHistory:UpdateIconPosition(unit, index, ox, oy)
	local i = index == "enter" and 0 or index

	-- position
	local dir = self.db[unit].GrowDirection
	local invdir, sign = InverseDirection(dir)

	local posx = self.db[unit].PaddingX + (self.db[unit].IconSize + self.db[unit].Margin) * (i - 1)
	self.frame[unit][index]:SetPoint(invdir, self.frame[unit], invdir, sign * (posx + ox), oy)
end

function SkillHistory:GetOptions(unit)
	local options
	options = {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				widget = {
					type = "group",
					name = L["Widget"],
					desc = L["Widget settings"],
					inline = true,
					order = 1,
					args = {
						BackgroundColor = {
							type = "color",
							name = L["Background color"],
							desc = L["Color of the frame background"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						Crop = {
							type = "toggle",
							name = L["Crop borders"],
							desc = L["Toggle if the icon borders should be cropped or not"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 14,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 14.5,
						},
						MaxIcons = {
							type = "range",
							name = L["Icons max"],
							desc = L["Number of max icons"],
							min = 1, max = MAX_ICONS, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
					},
				},
				enteranim = {
					type = "group",
					name = L["Enter animation"],
					desc = L["Enter animation settings"],
					inline = true,
					order = 2,
					args = {
						EnterAnimDuration = {
							type = "range",
							name = L["Duration"],
							desc = L["Duration of the enter animation, in seconds"],
							min = 0.1, softMax = 5, bigStep = 0.05,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						EnterAnimEase = {
							type = "select",
							name = L["Ease mode"],
							desc = L["Animation ease mode"],
							values = {
								["IN"] = L["In"],
								["IN_OUT"] = L["In-Out"],
								["OUT"] = L["Out"],
								["NONE"] = L["None"],
							},
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 2,
						},
						EnterAnimEaseMode = {
							type = "select",
							name = L["Ease function"],
							desc = L["Animation ease function"],
							values = {
								["QUAD"] = L["Quadratic"],
								["CUBIC"] = L["Cubic"],
							},
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
						},
					},
				},
				timeout = {
					type = "group",
					name = L["Timeout"],
					desc = L["Timeout settings"],
					inline = true,
					order = 2,
					args = {
						Timeout = {
							type = "range",
							name = L["Timeout"],
							desc = L["Timeout, in seconds"],
							min = 1, softMin = 3, softMax = 30, bigStep = 0.5,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						TimeoutAnimDuration = {
							type = "range",
							name = L["Fade out duration"],
							desc = L["Duration of the fade out animation, in seconds"],
							min = 0.1, softMax = 3, bigStep = 0.05,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 2,
						},
					},
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 3,
					args = {
						IconSize = {
							type = "range",
							name = L["Icon size"],
							desc = L["Size of the cooldown icons"],
							min = 1, softMin = 10, softMax = 100, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						PaddingY = {
							type = "range",
							name = L["Vertical padding"],
							desc = L["Vertical padding of the icons"],
							min = 0, softMax = 30, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 15,
						},
						PaddingX = {
							type = "range",
							name = L["Horizontal padding"],
							desc = L["Horizontal padding of the icons"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							min = 0, softMax = 30, step = 1,
							order = 20,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 23,
						},
						Margin = {
							type = "range",
							name = L["Horizontal spacing"],
							desc = L["Horizontal spacing of the icons"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							min = 0, softMax = 30, step = 1,
							order = 30,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 4,
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
							values = GladiusEx:GetGrowSimplePositions(),
							get = function()
								return GladiusEx:GrowSimplePositionFromAnchor(
									self.db[unit].Anchor,
									self.db[unit].RelativePoint,
									self.db[unit].GrowDirection)
							end,
							set = function(info, value)
								self.db[unit].Anchor, self.db[unit].RelativePoint =
									GladiusEx:AnchorFromGrowSimplePosition(value, self.db[unit].GrowDirection)
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return GladiusEx.db.base.advancedOptions end,
							order = 2,
						},
						GrowDirection = {
							type = "select",
							name = L["Grow direction"],
							desc = L["Grow direction of the icons"],
							values = {
								["LEFT"] = L["Left"],
								["RIGHT"] = L["Right"],
							},
							set = function(info, value)
								if not GladiusEx.db.base.advancedOptions then
									self.db[unit].Anchor, self.db[unit].RelativePoint =
										GladiusEx:AnchorFromGrowDirection(
											self.db[unit].Anchor,
											self.db[unit].RelativePoint,
											self.db[unit].GrowDirection,
											value)
								end
								self.db[unit].GrowDirection = value
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
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
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						OffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["Y offset of the frame"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							softMin = -100, softMax = 100, bigStep = 1,
							order = 25,
						},
					},
				},
			},
		},
	}

	return options
end
