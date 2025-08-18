local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
local DRData = LibStub("DRList-1.0")

-- global functions
local strfind = string.find
local pairs, unpack = pairs, unpack
local GetTime, UnitGUID = GetTime, UnitGUID
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture

local defaults = {
	drTrackerAdjustSize = false,
	drTrackerMargin = 1,
	drTrackerSize = 25,
	drTrackerCrop = true,
	drTrackerCooldownSwipeColor = { r = 0, g = 0, b = 0, a = 0.6 },
	drTrackerOffsetX = 0,
	drTrackerOffsetY = 0,
	drTrackerFrameLevel = 8,
	drTrackerGloss = false,
	drTrackerGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
	drTrackerCooldown = true,
	drTrackerCooldownReverse = false,
	drTrackerBorder = true,
	drTrackerText = true,
	drFontSize = 18,
	drCategories = {},
	drIcons = {},
	drShowOnApply = true,
}

local DRTracker = GladiusEx:NewGladiusExModule("DRTracker",
	fn.merge(defaults, {
		drTrackerAttachTo = "ClassIcon",
		drTrackerAnchor = "RIGHT",
		drTrackerRelativePoint = "LEFT",
		drTrackerGrowDirection = "LEFT",
		drTrackerOffsetX = -2,
	}),
	fn.merge(defaults, {
		drTrackerAttachTo = "ClassIcon",
		drTrackerAnchor = "LEFT",
		drTrackerRelativePoint = "RIGHT",
		drTrackerGrowDirection = "RIGHT",
		drTrackerOffsetX = 2,
	}))

local drTexts = {
	[1] =    { "½", 0, 1, 0 },
	[0.5] =  { "¼", 1, 0.65,0 },
	[0.25] = { "Ø", 1, 0, 0 },
	[0] =    { "Ø", 1, 0, 0 },
}

function DRTracker:OnEnable()
	if not self.frame then
		self.frame = {}
	end

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function DRTracker:OnDisable()
	self:UnregisterAllEvents()

	for _, frame in pairs(self.frame) do
		frame:Hide()
	end
end

function DRTracker:GetFrames()
	return nil
end

function DRTracker:GetModuleAttachPoints()
	return {
		["DRTracker"] = L["DRTracker"],
	}
end

function DRTracker:GetModuleAttachFrame(unit)
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end

	return self.frame[unit]
end

function DRTracker:CreateIcon(unit, drCat)
	local f = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. "FrameCat" .. drCat .. unit, self.frame[unit], nil)
	
	f.texture = f:CreateTexture(nil, "ARTWORK")
	f.texture:SetAllPoints()

	f.normalTexture = f:CreateTexture(nil, "OVERLAY")
	f.normalTexture:SetAllPoints()

	f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.cooldown:SetAllPoints()

	f.text = f:CreateFontString(nil, "OVERLAY")

	f.border = f:CreateTexture(nil, "OVERLAY")
	f.border:SetAllPoints()

	self.frame[unit].tracker[drCat] = f
end

function DRTracker:UpdateIcon(unit, drCat)
	local tracked = self.frame[unit].tracker[drCat]

	tracked:EnableMouse(false)
	tracked.reset_time = 0

	tracked:SetWidth(self.frame[unit]:GetHeight())
	tracked:SetHeight(self.frame[unit]:GetHeight())

	tracked.normalTexture:SetTexture([[Interface\AddOns\GladiusEx\media\gloss]])
	tracked.normalTexture:SetVertexColor(self.db[unit].drTrackerGlossColor.r, self.db[unit].drTrackerGlossColor.g,
		self.db[unit].drTrackerGlossColor.b, self.db[unit].drTrackerGloss and self.db[unit].drTrackerGlossColor.a or 0)

	tracked.border:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])

	-- cooldown
	tracked.cooldown:SetReverse(self.db[unit].drTrackerCooldownReverse)
	if self.db[unit].drTrackerCooldown then
		tracked.cooldown:Show()
	else
		tracked.cooldown:Hide()
	end

	local swipeColor = self.db[unit].drTrackerCooldownSwipeColor
	tracked.cooldown:SetSwipeColor(swipeColor.r, swipeColor.g, swipeColor.b, swipeColor.a)

	-- text
	tracked.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, "2002"), self.db[unit].drFontSize, "OUTLINE")
	tracked.text:ClearAllPoints()
	tracked.text:SetPoint("BOTTOMRIGHT", tracked, -2, 0)
	tracked.text:SetDrawLayer("OVERLAY")
	tracked.text:SetJustifyH("RIGHT")

	-- style action button
	tracked.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
	tracked.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)

	tracked.normalTexture:ClearAllPoints()
	tracked.normalTexture:SetPoint("CENTER", 0, 0)

	tracked.texture:ClearAllPoints()
	tracked.texture:SetPoint("TOPLEFT", tracked, "TOPLEFT")
	tracked.texture:SetPoint("BOTTOMRIGHT", tracked, "BOTTOMRIGHT")
	if self.db[unit].drTrackerCrop then
		local n = 5
		tracked.texture:SetTexCoord(n / 64, 1 - n / 64, n / 64, 1 - n / 64)
	else
		tracked.texture:SetTexCoord(0, 1, 0, 1)
	end
end

function DRTracker:SortIcons(unit)
	local lastFrame

	for cat, frame in pairs(self.frame[unit].tracker) do
		frame:ClearAllPoints()

		if frame.active then
			if not lastFrame then
				-- frame:SetPoint(self.db[unit].drTrackerAnchor, self.frame[unit], self.db[unit].drTrackerRelativePoint, self.db[unit].drTrackerOffsetX, self.db[unit].drTrackerOffsetY)
				frame:SetPoint("TOPLEFT", self.frame[unit])
			elseif self.db[unit].drTrackerGrowDirection == "RIGHT" then
				frame:SetPoint("TOPLEFT", lastFrame, "TOPRIGHT", self.db[unit].drTrackerMargin, 0)
			elseif self.db[unit].drTrackerGrowDirection == "LEFT" then
				frame:SetPoint("TOPRIGHT", lastFrame, "TOPLEFT", -self.db[unit].drTrackerMargin, 0)
			elseif self.db[unit].drTrackerGrowDirection == "UP" then
				frame:SetPoint("BOTTOMLEFT", lastFrame, "TOPLEFT", 0, self.db[unit].drTrackerMargin)
			elseif self.db[unit].drTrackerGrowDirection == "DOWN" then
				frame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -self.db[unit].drTrackerMargin)
			end

			lastFrame = frame

			frame:Show()
		else
			frame:Hide()
		end
	end
end

function DRTracker:DRFaded(unit, drCat, spellID, event)
	if drCat == nil then return end -- Should only happen in testing
	if self.db[unit].drCategories[drCat] == false then return end

	if not self.frame[unit].tracker[drCat] then
		self:CreateIcon(unit, drCat)
		self:UpdateIcon(unit, drCat)
	end

	local tracked = self.frame[unit].tracker[drCat]

	local useApplied = self.db[unit].drShowOnApply

	local applied = useApplied and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") or (event == "SPELL_AURA_APPLIED")

	if not useApplied and applied then
		return -- K: If we're not showing on apply then _APPLIED events are not relevant
	end

	local tracked = self.frame[unit].tracker[drCat]

	if (not applied and not useApplied) or (applied and useApplied) then
		if tracked.active then
			local oldDiminished = tracked.diminished
			tracked.diminished = DRData:NextDR(tracked.diminished)
			-- K: Fallback edge-case early DR reset detection
			if oldDiminished and oldDiminished == 0 and tracked.diminished == 0 then
				tracked.diminished = 1
			end
		else
			tracked.active = true
			tracked.diminished = 1
		end
	end

	-- K: This could happen if a _REMOVED is received before an _APPLIED/_REFRESH
	-- when using showOnApply, or reversed if not using it (could happen due to late join)
	if not tracked.active then
		return 
	end

	local text, r, g, b = unpack(drTexts[tracked.diminished])

	if self.db[unit].drTrackerText then
		tracked.text:Show()
		tracked.text:SetText(text)
		tracked.text:SetTextColor(r,g,b)
	else
		tracked.text:Hide()
	end

	local texture = GetSpellTexture(spellID)
	if self.db[unit].drIcons[drCat] then
		texture = GetSpellTexture(self.db[unit].drIcons[drCat])
	end
	tracked.texture:SetTexture(texture)

	if self.db[unit].drTrackerBorder then
		tracked.border:SetVertexColor(r, g, b, 1)
		tracked.border:Show()
	else
		tracked.border:Hide()
	end

	if self.db[unit].drTrackerCooldown then
		if useApplied and applied then
			CooldownFrame_Set(tracked.cooldown, 0, 0)
			tracked.cooldown:Hide()
		else
			local time_left = DRData:GetResetTime()
			tracked.reset_time = time_left + GetTime()
			CooldownFrame_Set(tracked.cooldown, GetTime(), time_left, 1)
			tracked.cooldown:Show()
		end
	end

	if not applied then
		tracked:SetScript("OnUpdate", function(f, elapsed)
			-- add extra time to allow the cooldown frame to play the bling animation
			if GetTime() >= (f.reset_time + 0.5) then
				tracked.active = false
				self:SortIcons(unit)
				f:SetScript("OnUpdate", nil)
			end
		end)
	elseif (applied and useApplied) then
		tracked:SetScript("OnUpdate", nil)
	end

	tracked:Show()
	self:SortIcons(unit)
end

function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event)
	self:CombatLogEvent(event, CombatLogGetCurrentEventInfo())
end

function DRTracker:CombatLogEvent(_, _, eventType, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, _, _, auraType)
    -- Enemy had a debuff refreshed before it faded
    -- Buff or debuff faded from an enemy
    if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_REMOVED" then
        local drCat, catTbl = DRData:GetSpellCategory(spellID)
        if drCat and auraType == "DEBUFF" then
            local unit = GladiusEx:GetUnitIdByGUID(destGUID)
            if unit and self.frame[unit] then
                local tbl = catTbl and catTbl or { drCat }
                for _, drCat in pairs(tbl) do -- K: Use a for loop to catch auras that DR with multiple categories (primarily Ring of Frost/Deep Freeze)				

                    -- K: Dynamic DR reset early if we have a full duration aura on _REFRESH / _APPLIED 
                    if GladiusEx.IS_PRE_WOD then
                        local tracked = (self.frame[unit] and self.frame[unit].tracker) and self.frame[unit].tracker[drCat] or nil
                        if tracked and (eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_APPLIED") then
                            if self:HasFullDurationAura(unit, sourceGUID, spellID) then
                                tracked.active = false
                            end
                        end
                    end

                    self:DRFaded(unit, drCat, spellID, eventType)
                end
            end
        end
    end
end

function DRTracker:HasFullDurationAura(unit, sourceGUID, spellID)
    local fullDuration = GladiusEx.Data.AuraDurations and GladiusEx.Data.AuraDurations[spellID] or nil

    if fullDuration then
        local srcUnit = GladiusEx:GetUnitIdByGUID(sourceGUID)

        local i = 1
        while true do
            local name, _, _, _, _, duration, _, unitCaster, _, _, secID, secSourceGUID = GladiusEx.UnitAura(unit, i, "HARMFUL")
            if not name then break end
            if secID == spellID then
                if (secSourceGUID and secSourceGUID == sourceGUID) or unitCaster == srcUnit then
                    -- K: Some classes/races have CC duration reduction effects, thus we have to check if the aura is at least longer than 50% of fullDuration
                    -- which would imply it's possibly reduced by effects - but at least not DRd (which would be less than or equal to 50%)
                    -- Note: In MoP/WotLK some class/race/comp combo have the possibility to reduce a CC by 50% or more
                    -- will therefore not detect early resets for units with Nimble Brew (60% CC reduction) and Mage Armor (50% CC reduction in WotLK)
                    if duration > (fullDuration / 2) then
                        return true
                    end
                end
            end
            i = i + 1
        end
    end

    return false
end

function DRTracker:CreateFrame(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create frame
	-- TODO make my own CheckButton/ActionButtonTemplate
	self.frame[unit] = CreateFrame("CheckButton", "GladiusEx" .. self:GetName() .. "Frame" .. unit, button, "ActionButtonTemplate")
	self.frame[unit].NormalTexture:Hide()
	if self.frame[unit].HighlightTexture then
		self.frame[unit].HighlightTexture:Hide()
	end
	if self.frame[unit].SlotBackground then
		self.frame[unit].SlotBackground:Hide()
	end
	self.frame[unit]:EnableMouse(false) -- fixes a bug in which, with some settings, the first DR category icon is clickable and clicking it causes a strange border to appear
end

function DRTracker:Update(unit)
	-- create frame
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end

	-- update frame
	self.frame[unit]:ClearAllPoints()

	-- anchor point
	local parent = GladiusEx:GetAttachFrame(unit, self.db[unit].drTrackerAttachTo)
	self.frame[unit]:SetPoint(self.db[unit].drTrackerAnchor, parent, self.db[unit].drTrackerRelativePoint, self.db[unit].drTrackerOffsetX, self.db[unit].drTrackerOffsetY)

	-- frame level
	self.frame[unit]:SetFrameLevel(self.db[unit].drTrackerFrameLevel)

	local size = self.db[unit].drTrackerSize
	if self.db[unit].drTrackerAdjustSize then
		size = parent:GetHeight()
	end
	self.frame[unit]:SetSize(size, size)

	-- update icons
	if not self.frame[unit].tracker then
		self.frame[unit].tracker = {}
	else
		for cat, frame in pairs(self.frame[unit].tracker) do
			frame:SetWidth(self.frame[unit]:GetHeight())
			frame:SetHeight(self.frame[unit]:GetHeight())

			frame.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
			frame.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)

			self:UpdateIcon(unit, cat)
		end
		self:SortIcons(unit)
	end

	-- hide
	self.frame[unit]:Hide()
end

function DRTracker:Show(unit)
	-- show frame
	self.frame[unit]:Show()
end

function DRTracker:Reset(unit)
	if not self.frame[unit] then return end

	-- hide icons
	for _, frame in pairs(self.frame[unit].tracker) do
		frame.active = false
		frame.diminished = 1
		frame:SetScript("OnUpdate", nil)
		frame:Hide()
	end

	-- hide
	self.frame[unit]:Hide()
end

function DRTracker:Test(unit)
	self:DRFaded(unit, DRData:GetSpellCategory(64058), 64058, "SPELL_AURA_APPLIED")
	self:DRFaded(unit, DRData:GetSpellCategory(64058), 64058, "SPELL_AURA_REMOVED")

	self:DRFaded(unit, DRData:GetSpellCategory(118), 118, "SPELL_AURA_APPLIED")
	self:DRFaded(unit, DRData:GetSpellCategory(118), 118, "SPELL_AURA_REFRESH")
	self:DRFaded(unit, DRData:GetSpellCategory(118), 118, "SPELL_AURA_REMOVED")
	self:DRFaded(unit, DRData:GetSpellCategory(118), 118, "SPELL_AURA_REMOVED")

	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_APPLIED")
	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_APPLIED")
	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_APPLIED")
	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_REMOVED")
	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_REMOVED")
	self:DRFaded(unit, DRData:GetSpellCategory(33786), 33786, "SPELL_AURA_REMOVED")
end

function DRTracker:GetOptions(unit)
	local options = {
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
						drTrackerCooldown = {
							type = "toggle",
							name = L["Cooldown spiral"],
							desc = L["Display the cooldown spiral for the drTracker icons"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						drTrackerCooldownReverse = {
							type = "toggle",
							name = L["Cooldown reverse"],
							desc = L["Invert the dark/bright part of the cooldown spiral"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 13,
						},
						drTrackerCooldownSwipeColor = {
							type = "color",
							hasAlpha = true,
							name = L["Swipe color"],
							desc = L["Cooldown swipe color on buffs"],
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							disabled = function() return not self:IsUnitEnabled(unit) or not self.db[unit].drTrackerCooldown end,
							order = 14,
						},
						sep3 = {
							type = "description",
							name = "",
							width = "full",
							order = 15,
						},
						drTrackerCrop = {
							type = "toggle",
							name = L["Crop borders"],
							desc = L["Toggle if the icon borders should be cropped or not"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 16,
						},
						drTrackerGloss = {
							type = "toggle",
							name = L["Gloss"],
							desc = L["Toggle gloss on the icon"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 25,
						},
						drTrackerGlossColor = {
							type = "color",
							name = L["Gloss color"],
							desc = L["Color of the gloss"],
							get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
							hasAlpha = true,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 30,
						},
						sep4 = {
							type = "description",
							name = "",
							width = "full",
							order = 33,
						},
						drTrackerBorder = {
							type = "toggle",
							name = L["DR-Colored Border"],
							desc = L["Adds a border to the icon the color of which will be the DR color"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 34,
						},
						drShowOnApply = {
							type = "toggle",
							name = L["Show on Apply"],
							desc = L["Show DRs on start instead of on refresh/removal"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 35,
						},
						drTrackerFrameLevel = {
							type = "range",
							name = L["Frame level"],
							desc = L["Frame level of the frame"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							softMin = 1, softMax = 100, step = 1,
							order = 36,
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
						drTrackerMargin = {
							type = "range",
							name = L["Spacing"],
							desc = L["Space between the icons"],
							min = 0, max = 100, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
						drTrackerSize = {
							type = "range",
							name = L["Icon size"],
							desc = L["Size of the icons"],
							min = 1, softMin = 10, softMax = 100, bigStep = 1,
							disabled = function() return self.db[unit].drTrackerAdjustSize or not self:IsUnitEnabled(unit) end,
							order = 6,
						},
						drTrackerAdjustSize = {
							type = "toggle",
							name = L["Adjust size"],
							desc = L["Adjust size to the frame size"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 7,
						},
					},
				},
				font = {
					type = "group",
					name = L["Font"],
					desc = L["Font settings"],
					inline = true,
					order = 3,
					args = {
						drFontSize = {
							type = "range",
							name = L["Text size"],
							desc = L["Text size of the DR text"],
							min = 1, max = 20, step = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						drTrackerText = {
							type = "toggle",
							name = L["DR Text"],
							desc = L["Show the current DR on the icon as text"],
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 15,
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
						drTrackerAttachTo = {
							type = "select",
							name = L["Attach to"],
							desc = L["Attach to the given frame"],
							values = function() return self:GetOtherAttachPoints(unit) end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						drTrackerPosition = {
							type = "select",
							name = L["Position"],
							desc = L["Position of the frame"],
							values = GladiusEx:GetGrowSimplePositions(),
							get = function()
								return GladiusEx:GrowSimplePositionFromAnchor(
									self.db[unit].drTrackerAnchor,
									self.db[unit].drTrackerRelativePoint,
									self.db[unit].drTrackerGrowDirection)
							end,
							set = function(info, value)
								self.db[unit].drTrackerAnchor, self.db[unit].drTrackerRelativePoint =
									GladiusEx:AnchorFromGrowSimplePosition(value, self.db[unit].drTrackerGrowDirection)
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return GladiusEx.db.base.advancedOptions end,
							order = 6,
						},
						drTrackerGrowDirection = {
							type = "select",
							name = L["Grow direction"],
							values = {
								["LEFT"]  = L["Left"],
								["RIGHT"] = L["Right"],
								["UP"]    = L["Up"],
								["DOWN"]  = L["Down"],
							},
							set = function(info, value)
								if not GladiusEx.db.base.advancedOptions then
									self.db[unit].drTrackerAnchor, self.db[unit].drTrackerRelativePoint =
										GladiusEx:AnchorFromGrowDirection(
											self.db[unit].drTrackerAnchor,
											self.db[unit].drTrackerRelativePoint,
											self.db[unit].drTrackerGrowDirection,
											value)
								end
								self.db[unit].drTrackerGrowDirection = value
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 8,
						},
						drTrackerAnchor = {
							type = "select",
							name = L["Anchor"],
							desc = L["Anchor of the frame"],
							values = GladiusEx:GetPositions(),
							disabled = function() return not self:IsUnitEnabled(unit) end,
							hidden = function() return not GladiusEx.db.base.advancedOptions end,
							order = 10,
						},
						drTrackerRelativePoint = {
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
						drTrackerOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the frame"],
							softMin = -100, softMax = 100, bigStep = 1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						drTrackerOffsetY = {
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

	options.categories = {
		type = "group",
		name = L["Categories"],
		order = 2,
		args = {
			categories = {
				type = "group",
				name = L["Categories"],
				desc = L["Category settings"],
				inline = true,
				order = 1,
				args = {
				},
			},
		},
	}

	options.icon_for_category = {
		type = "group",
		name = "Icon for category",
		order = 3,
		args = {}
	}

	local index = 1
	for key, name in pairs(DRData:GetCategories()) do
		options.categories.args.categories.args[key] = {
			type = "toggle",
			name = name,
			get = function(info)
				if self.db[unit].drCategories[info[#info]] == nil then
					return true
				else
					return self.db[unit].drCategories[info[#info]]
				end
			end,
			set = function(info, value)
				self.db[unit].drCategories[info[#info]] = value
			end,
			disabled = function() return not self:IsUnitEnabled(unit) end,
			order = index * 5,
		}

		local values = {"Default"}
		local seen_icons = {}
		local idx = 1
		local spellid_by_idx = {}
		for spellid, _ in DRData:IterateSpellsByCategory(key) do
      local spellname, spellicon
      if C_Spell and C_Spell.GetSpellTexture then
        spellicon = C_Spell.GetSpellTexture(spellid)
        spellname = C_Spell.GetSpellName(spellid)
      else
        spellname, _, spellicon = GetSpellInfo(spellid)
      end
			if spellicon and not seen_icons[spellicon] then
				spellid_by_idx[idx] = spellid
				seen_icons[spellicon] = true
				table.insert(
					values,
					string.format(" |T%s:20|t %s", spellicon, spellname)
				)
				idx = idx + 1
			end
		end

		options.icon_for_category.args[key] = {
			type = "select",
			name = name,
			values = values,
			order = index * 5,
			style = "dropdown",
			get = function(info)
				if not self.db[unit].drIcons[key] then
					return 1
				end
				for idx, spellid in pairs(spellid_by_idx) do
					if spellid == self.db[unit].drIcons[key] then
						-- +1 because 1 is "default"
						return idx + 1
					end
				end
				return 1
			end,
			set = function(info, value)
				-- 1 = default
				if value > 1 then
					self.db[unit].drIcons[key] = spellid_by_idx[value - 1]
				else
					self.db[unit].drIcons[key] = nil
				end
			end,
		}


		index = index + 1
	end

	return options
end
