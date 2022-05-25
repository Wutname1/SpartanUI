local UF, L = SUI.UF, SUI.L

local function InverseAnchor(anchor)
	if anchor == 'TOPLEFT' then
		return 'BOTTOMLEFT'
	elseif anchor == 'TOPRIGHT' then
		return 'BOTTOMRIGHT'
	elseif anchor == 'BOTTOMLEFT' then
		return 'TOPLEFT'
	elseif anchor == 'BOTTOMRIGHT' then
		return 'TOPRIGHT'
	elseif anchor == 'BOTTOM' then
		return 'TOP'
	elseif anchor == 'TOP' then
		return 'BOTTOM'
	elseif anchor == 'LEFT' then
		return 'RIGHT'
	elseif anchor == 'RIGHT' then
		return 'LEFT'
	end
end

---@param frame table
---@param DB table
local function Build(frame, DB)
	-- Setup icons if needed
	local iconFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
		if caster == 'player' and (duration == 0 or duration > 60) then --Do not show DOTS & HOTS
			return true
		elseif caster ~= 'player' then
			return true
		end
	end
	local function customFilter(
		element,
		unit,
		button,
		name,
		texture,
		count,
		debuffType,
		duration,
		expiration,
		caster,
		isStealable,
		nameplateShowSelf,
		spellID,
		canApply,
		isBossDebuff,
		casterIsPlayer,
		nameplateShowAll,
		timeMod,
		effect1,
		effect2,
		effect3)
		-- check for onlyShowPlayer rules
		if (element.onlyShowPlayer and button.isPlayer) or (not element.onlyShowPlayer and name) then
			return true
		end
		-- Check boss rules
		if isBossDebuff and element.ShowBossDebuffs then
			return true
		end
		if isStealable and element.ShowStealable then
			return true
		end

		-- We did not find a display rule, so hide it
		return false
	end

	--Buff Icons
	local Buffs = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame)
	-- Buffs.PostUpdate = PostUpdateAura
	-- Buffs.CustomFilter = customFilter
	frame.Buffs = Buffs

	--Debuff Icons
	local Debuffs = CreateFrame('Frame', frame.unitOnCreate .. 'Debuffs', frame)
	-- Debuffs.PostUpdate = PostUpdateAura
	-- Debuffs.CustomFilter = customFilter
	frame.Debuffs = Debuffs
end

---@param frame table
local function Update(frame)
	local DB = frame.auras.DB
	if (DB.Buffs.enabled) then
		frame.Buffs:Show()
	else
		frame.Buffs:Hide()
	end
	if (DB.Debuffs.enabled) then
		frame.Debuffs:Show()
	else
		frame.Debuffs:Hide()
	end

	local function UpdateAura(self, elapsed)
		if (self.expiration) then
			self.expiration = math.max(self.expiration - elapsed, 0)

			if (self.expiration > 0 and self.expiration < 60) then
				self.Duration:SetFormattedText('%d', self.expiration)
			else
				self.Duration:SetText()
			end
		end
	end

	local function PostCreateAura(element, button)
		if button.SetBackdrop then
			button:SetBackdrop(nil)
			button:SetBackdropColor(0, 0, 0)
		end
		button.cd:SetReverse(true)
		button.cd:SetHideCountdownNumbers(true)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button.icon:SetDrawLayer('ARTWORK')
		-- button:SetScript('OnEnter', OnAuraEnter)

		-- We create a parent for aura strings so that they appear over the cooldown widget
		local StringParent = CreateFrame('Frame', nil, button)
		StringParent:SetFrameLevel(20)

		button.count:SetParent(StringParent)
		button.count:ClearAllPoints()
		button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
		button.count:SetFont(SUI:GetFontFace('UnitFrames'), select(2, button.count:GetFont()) - 3)

		local Duration = StringParent:CreateFontString(nil, 'OVERLAY')
		Duration:SetFont(SUI:GetFontFace('UnitFrames'), 11)
		Duration:SetPoint('TOPLEFT', button, 0, -1)
		button.Duration = Duration

		button:HookScript('OnUpdate', UpdateAura)
	end

	local function PostUpdateAura(element, unit, button, index)
		local _, _, _, _, duration, expiration, owner, canStealOrPurge = UnitAura(unit, index, button.filter)
		if (duration and duration > 0) then
			button.expiration = expiration - GetTime()
		else
			button.expiration = math.huge
		end

		if button.SetBackdrop then
			if (unit == 'target' and canStealOrPurge) then
				button:SetBackdropColor(0, 1 / 2, 1 / 2)
			elseif (owner ~= 'player') then
				button:SetBackdropColor(0, 0, 0)
			end
		end
	end

	local DB = UF.CurrentSettings[frame.unitOnCreate].elements.Auras

	local Buffs = frame.Buffs
	Buffs.size = DB.Buffs.size
	Buffs.initialAnchor = DB.Buffs.initialAnchor
	Buffs['growth-x'] = DB.Buffs.growthx
	Buffs['growth-y'] = DB.Buffs.growthy
	Buffs.spacing = DB.Buffs.spacing
	Buffs.showType = DB.Buffs.showType
	Buffs.num = DB.Buffs.number
	Buffs.onlyShowPlayer = DB.Buffs.onlyShowPlayer
	Buffs.PostCreateIcon = PostCreateAura
	Buffs.PostUpdateIcon = PostUpdateAura
	Buffs:SetPoint(
		InverseAnchor(DB.Buffs.position.anchor),
		frame,
		DB.Buffs.position.anchor,
		DB.Buffs.position.x,
		DB.Buffs.position.y
	)
	local w = (DB.Buffs.number / DB.Buffs.rows)
	if w < 1.5 then
		w = 1.5
	end
	Buffs:SetSize((DB.Buffs.size + DB.Buffs.spacing) * w, (DB.Buffs.spacing + DB.Buffs.size) * DB.Buffs.rows)

	--Debuff Icons
	local Debuffs = frame.Debuffs
	Debuffs.size = DB.Debuffs.size
	Debuffs.initialAnchor = DB.Debuffs.initialAnchor
	Debuffs['growth-x'] = DB.Debuffs.growthx
	Debuffs['growth-y'] = DB.Debuffs.growthy
	Debuffs.spacing = DB.Debuffs.spacing
	Debuffs.showType = DB.Debuffs.showType
	Debuffs.num = DB.Debuffs.number
	Debuffs.onlyShowPlayer = DB.Debuffs.onlyShowPlayer
	Debuffs.PostCreateIcon = PostCreateAura
	Debuffs.PostUpdateIcon = PostUpdateAura
	Debuffs:SetPoint(
		InverseAnchor(DB.Debuffs.position.anchor),
		frame,
		DB.Debuffs.position.anchor,
		DB.Debuffs.position.x,
		DB.Debuffs.position.y
	)
	w = (DB.Debuffs.number / DB.Debuffs.rows)
	if w < 1.5 then
		w = 1.5
	end
	Debuffs:SetSize((DB.Debuffs.size + DB.Debuffs.spacing) * w, (DB.Debuffs.spacing + DB.Debuffs.size) * DB.Debuffs.rows)
	frame:UpdateAllElements('ForceUpdate')
	-- frame.Buffs:PostUpdate(unit, 'Buffs')
	-- frame.Debuffs:PostUpdate(unit, 'Buffs')
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local anchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOP'] = 'TOP',
		['TOPRIGHT'] = 'TOP RIGHT',
		['RIGHT'] = 'RIGHT',
		['CENTER'] = 'CENTER',
		['LEFT'] = 'LEFT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOM'] = 'BOTTOM',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
	}
	local limitedAnchorPoints = {
		['TOPLEFT'] = 'TOP LEFT',
		['TOPRIGHT'] = 'TOP RIGHT',
		['BOTTOMLEFT'] = 'BOTTOM LEFT',
		['BOTTOMRIGHT'] = 'BOTTOM RIGHT'
	}
	local CurrentSettings = UF.CurrentSettings[unitName].elements.Auras

	OptionSet.args['auras'] = {
		name = L['Buffs & Debuffs'],
		desc = L['Buff & Debuff display settings'],
		type = 'group',
		childGroups = 'tree',
		order = 100,
		args = {}
	}

	local function SetOption(val, buffType, setting)
		--Update memory
		CurrentSettings[buffType][setting] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Auras[buffType][setting] = val
		--Update the screen
		UF.frames[unitName]:UpdateAuras()
	end

	for _, buffType in pairs({'Buffs', 'Debuffs'}) do
		OptionSet.args.auras.args[buffType] = {
			name = L[buffType],
			type = 'group',
			-- inline = true,
			order = 1,
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					get = function(info)
						return CurrentSettings[buffType].enabled
					end,
					set = function(info, val)
						SetOption(val, buffType, 'enabled')
					end
				},
				Display = {
					name = L['Display settings'],
					type = 'group',
					order = 100,
					inline = true,
					get = function(info)
						return CurrentSettings[buffType][info[#info]]
					end,
					set = function(info, val)
						SetOption(val, buffType, info[#info])
					end,
					args = {
						number = {
							name = L['Number to show'],
							type = 'range',
							order = 20,
							min = 1,
							max = 30,
							step = 1
						},
						showType = {
							name = L['Show type'],
							type = 'toggle',
							order = 30
						},
						selfScale = {
							order = 2,
							type = 'range',
							name = L['Scaled aura size'],
							desc = L[
								'Scale for auras that you casted or can Spellsteal, any number above 100% is bigger than default, any number below 100% is smaller than default.'
							],
							min = 1,
							max = 3,
							step = 0.10,
							isPercent = true
						}
					}
				},
				Sizing = {
					name = L['Sizing & layout'],
					type = 'group',
					order = 200,
					inline = true,
					args = {
						size = {
							name = L['Size'],
							type = 'range',
							order = 40,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].size
							end,
							set = function(info, val)
								SetOption(val, buffType, 'size')
							end
						},
						spacing = {
							name = L['Spacing'],
							type = 'range',
							order = 41,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].spacing
							end,
							set = function(info, val)
								SetOption(val, buffType, 'spacing')
							end
						},
						rows = {
							name = L['Rows'],
							type = 'range',
							order = 50,
							min = 1,
							max = 30,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].rows
							end,
							set = function(info, val)
								SetOption(val, buffType, 'rows')
							end
						},
						initialAnchor = {
							name = L['Buff anchor point'],
							type = 'select',
							order = 70,
							values = limitedAnchorPoints,
							get = function(info)
								return CurrentSettings[buffType].initialAnchor
							end,
							set = function(info, val)
								SetOption(val, buffType, 'initialAnchor')
							end
						},
						growthx = {
							name = L['Growth x'],
							type = 'select',
							order = 71,
							values = {
								['RIGHT'] = 'RIGHT',
								['LEFT'] = 'LEFT'
							},
							get = function(info)
								return CurrentSettings[buffType].growthx
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthx')
							end
						},
						growthy = {
							name = L['Growth y'],
							type = 'select',
							order = 72,
							values = {
								['UP'] = 'UP',
								['DOWN'] = 'DOWN'
							},
							get = function(info)
								return CurrentSettings[buffType].growthy
							end,
							set = function(info, val)
								SetOption(val, buffType, 'growthy')
							end
						}
					}
				},
				position = {
					name = L['Position'],
					type = 'group',
					order = 400,
					inline = true,
					args = {
						x = {
							name = L['X Axis'],
							type = 'range',
							order = 1,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].position.x
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.x = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][unitName].elements.Auras[buffType].position.x = val
								--Update Screen
								UF.frames[unitName]:UpdateAuras()
							end
						},
						y = {
							name = L['Y Axis'],
							type = 'range',
							order = 2,
							min = -100,
							max = 100,
							step = 1,
							get = function(info)
								return CurrentSettings[buffType].position.y
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.y = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][unitName].elements.Auras[buffType].position.y = val
								--Update Screen
								UF.frames[unitName]:UpdateAuras()
							end
						},
						anchor = {
							name = L['Anchor point'],
							type = 'select',
							order = 3,
							values = anchorPoints,
							get = function(info)
								return CurrentSettings[buffType].position.anchor
							end,
							set = function(info, val)
								--Update memory
								CurrentSettings[buffType].position.anchor = val
								--Update the DB
								UF.DB.UserSettings[UF.DB.Style][unitName].elements.Auras[buffType].position.anchor = val
								--Update Screen
								UF.frames[unitName]:UpdateAuras()
							end
						}
					}
				},
				filters = {
					name = L['Filters'],
					type = 'group',
					order = 500,
					get = function(info)
						return CurrentSettings[buffType].filters[info[#info]]
					end,
					set = function(info, value)
						--Update memory
						CurrentSettings[buffType].filters[info[#info]] = value
						--Update the DB
						UF.DB.UserSettings[UF.DB.Style][unitName].elements.Auras[buffType].filters[info[#info]] = value
						--Update Screen
						UF.frames[unitName]:UpdateAuras()
					end,
					args = {
						minDuration = {
							order = 1,
							type = 'range',
							name = L['Minimum Duration'],
							desc = L["Don't display auras that are shorter than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1,
							width = 'full'
						},
						maxDuration = {
							order = 2,
							type = 'range',
							name = L['Maximum Duration'],
							desc = L["Don't display auras that are longer than this duration (in seconds). Set to zero to disable."],
							min = 0,
							max = 7200,
							step = 1,
							width = 'full'
						},
						showPlayers = {
							order = 3,
							type = 'toggle',
							name = L['Show your auras'],
							desc = L['Whether auras you casted should be shown'],
							width = 'full'
						},
						raid = {
							order = 4,
							type = 'toggle',
							name = function(info)
								return buffType == 'buffs' and L['Show castable on other auras'] or L['Show curable/removable auras']
							end,
							desc = function(info)
								return buffType == 'buffs' and L['Whether to show buffs that you cannot cast.'] or
									L['Whether to show any debuffs you can remove, cure or steal.']
							end,
							width = 'full'
						},
						boss = {
							order = 5,
							type = 'toggle',
							name = L['Show casted by boss'],
							desc = L['Whether to show any auras casted by the boss'],
							width = 'full'
						},
						misc = {
							order = 6,
							type = 'toggle',
							name = L['Show any other auras'],
							desc = L['Whether to show auras that do not fall into the above categories.'],
							width = 'full'
						},
						relevant = {
							order = 7,
							type = 'toggle',
							name = L['Smart Friendly/Hostile Filter'],
							desc = L[
								'Only apply the selected filters to buffs on friendly units and debuffs on hostile units, and otherwise show all auras.'
							],
							width = 'full'
						}
					}
				}
			}
		}
	end
end

UF.Elements:Register('Auras', Build, Update, Options)
