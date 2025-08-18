local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")

-- globals
local pairs = pairs
local min, max = math.min, math.max
local tinsert, tremove = table.insert, table.remove
local UnitHealth, UnitHealthMax, UnitIsDeadOrGhost = UnitHealth, UnitHealthMax, UnitIsDeadOrGhost
local GetTime = GetTime

local function GetDefaultCastsSpells()
	local h = { priority = 10, color = { r = 0, g = 1, b = 0, a = 1 } }
	local cc = { priority = 20, color = { r = 1, g = 0, b = 0, a = 1 } }
  return GladiusEx.Data.DefaultAlertSpells()
end

local function GetDefaultAuraSpells()
	local cc = { priority = 15, color = { r = 1, g = 1, b = 1, a = 1 } }
	local im = { priority = 15, color = { r = 1, g = 1, b = 0, a = 1 } }
	return GladiusEx.Data.DefaultAlertSpells()
end

local Alerts = GladiusEx:NewGladiusExModule("Alerts", {
		minAlpha = 0.2,
		maxAlpha = 0.6,
		duration = 0.35,
		ease = "OUT",
		blendMode = "BLEND",

		health = true,
		healthThreshold = 0.25,
		healthPriority = 10,
		healthColor = { r = 1, g = 0, b = 0, a = 1 },

		casts = true,
		hideSelfAlert = true,
		castsSpells = GetDefaultCastsSpells(),

		auras = true,
		aurasSpells = GetDefaultAuraSpells(),
	})

function Alerts:OnEnable()
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_NAME_UPDATE", "UNIT_HEALTH")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_STOP")

	if not self.frame then
		self.frame = {}
	end
end

function Alerts:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function Alerts:CreateFrame(unit)
	local button = GladiusEx.buttons[unit]
	if not button then return false end

	-- create frame
	self.frame[unit] = CreateFrame("Frame", "GladiusEx" .. self:GetName() .. unit, button)
	self.frame[unit].texture = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. "Texture" .. unit, "OVERLAY")
	self.frame[unit].texture:SetAllPoints()--self.frame[unit])
	self.frame[unit].ag = self.frame[unit]:CreateAnimationGroup()
	self.frame[unit].ag.aa = self.frame[unit].ag:CreateAnimation("Alpha")
	return true
end

function Alerts:Update(unit)
	local testing = GladiusEx:IsTesting(unit)

	-- create frame
	if not self.frame[unit] then
		-- V: check that CreateFrame returns a truthy value
		if not self:CreateFrame(unit) then
			return
		end
	end

	-- frame
	local parent = GladiusEx:GetAttachFrame(unit, "Frame")
	self.frame[unit]:ClearAllPoints()
	self.frame[unit]:SetAllPoints()
	self.frame[unit]:SetFrameLevel(100)

	-- texture
	self.frame[unit].texture:SetColorTexture(1, 1, 1, 1)
	self.frame[unit].texture:SetBlendMode(self.db[unit].blendMode)

	-- animation group
	self.frame[unit]:SetAlpha(self.db[unit].maxAlpha)
	self.frame[unit].ag:SetLooping("BOUNCE")
	self.frame[unit].ag.aa:SetFromAlpha(self.db[unit].minAlpha)
	self.frame[unit].ag.aa:SetToAlpha(self.db[unit].maxAlpha)
	self.frame[unit].ag.aa:SetDuration(self.db[unit].duration)
	self.frame[unit].ag.aa:SetSmoothing(self.db[unit].ease)
	self.frame[unit].ag:Stop()

	self.frame[unit]:Hide()
end

function Alerts:Show(unit)
end

function Alerts:Reset(unit)
	if not self.frame[unit] then return end

	self:StopFlash(unit)
	self:ClearAllAlerts(unit)
end

function Alerts:Test(unit)
	self:ClearAllAlerts(unit)
	self:SetAlert(unit, "test", 1, { r = 1, g = 0.2, b = 0.2, a = 0.5 })
end

function Alerts:Refresh(unit)
end

function Alerts:SetFlashColor(unit, color)
	self.frame[unit].texture:SetVertexColor(color.r, color.g, color.b, color.a)
end

function Alerts:StartFlash(unit, color)
	local f = self.frame[unit]
	f.texture:SetVertexColor(color.r, color.g, color.b, color.a)
	
	f:Show()
	f.ag:Play()
end

function Alerts:StopFlash(unit)
	self.frame[unit].ag:Stop()
	self.frame[unit].ag:SetScript("OnLoop", nil)
	self.frame[unit]:SetAlpha(0)
	self.frame[unit]:Hide()
end

local loop_queue = {}
function Alerts:QueueLoopEvent(unit, count, func)
	if not loop_queue[unit] then loop_queue[unit] = {} end

	tinsert(loop_queue[unit], { ["start"] = GetTime(), ["count"] = count, ["func"] = func })

	if #loop_queue[unit] == 1 then
		self.frame[unit].ag:SetScript("OnLoop",	function(ag, loopState)
			if loopState == "REVERSE" then
				local start_threshold = GetTime() - 0.3
				for i = #loop_queue[unit], 1, -1 do
					local q = loop_queue[unit][i]
					if start_threshold >= q.start then
						q.count = q.count - 1
						if q.count <= 0 then
							self[q.func](self, unit)
							tremove(loop_queue[unit], i)
						end
					end
				end
				if #loop_queue[unit] == 0 then
					ag:SetScript("OnLoop", nil)
				end
			end
		end)
	end
end

local alerts = {}
local alerts_color = {}
local line_ids = {}
function Alerts:SetAlert(unit, alert, priority, color)
	assert(type(unit) == "string")
	assert(type(alert) == "string")
	assert(type(priority) == "number")
	assert(type(color) == "table")
	if not alerts[unit] then alerts[unit] = { count = 0, priority = 0, current = false, alerts = {} } end
	if not alerts_color[unit] then alerts_color[unit] = {} end

	if not alerts[unit].alerts[alert] then
		alerts[unit].alerts[alert] = priority
		alerts_color[unit][alert] = color
		alerts[unit].count = alerts[unit].count + 1

		if alerts[unit].count == 1 or alerts[unit].priority < priority then
			alerts[unit].priority = priority
			alerts[unit].current = alert
			self:StartFlash(unit, color)
		end
	end
end

function Alerts:UpdateAlertColor(unit)
	-- find new alert
	local new_alert
	local new_priority = 0
	for alert, priority in pairs(alerts[unit].alerts) do
		if priority and priority > new_priority then
			new_alert = alert
			new_priority = priority
		end
	end
	GladiusEx:Log(unit, new_alert, new_priority, alerts[unit].priority)
	if new_alert then
		local cur_alert = alerts[unit].current
		if not alerts[unit][cur_alert] or new_priority > alerts[unit].priority then
			alerts[unit].priority = new_priority
			alerts[unit].current = new_alert
			self:SetFlashColor(unit, alerts_color[unit][new_alert])
		end
	else
		alerts[unit].priority = 0
		alerts[unit].current = false
		self:StopFlash(unit)
	end
end

function Alerts:ClearAlert(unit, alert, count)
	if alerts[unit] and alerts[unit].alerts[alert] then
		alerts[unit].alerts[alert] = false
		alerts[unit].count = alerts[unit].count - 1

		if count and count > 0 then
			self:QueueLoopEvent(unit, count or 1, "UpdateAlertColor")
		else
			self:UpdateAlertColor(unit)
		end
	end
end

function Alerts:IsAlertActive(unit, alert)
	return alerts[unit] and alerts[unit].alerts[alert]
end

function Alerts:ClearAllAlerts(unit)
	alerts[unit] = nil
	line_ids[unit] = nil
end

function Alerts:UNIT_AURA(event, unit)
	if not self.frame[unit] then return end
	if not self.db[unit].auras then return end

	for name, aura in pairs(self.db[unit].aurasSpells) do
		if aura then
			if AuraUtil.FindAuraByName(name, unit, "HELPFUL|HARMFUL") then
				self:SetAlert(unit, "aura_" .. name, aura.priority, aura.color)
			else
				self:ClearAlert(unit, "aura_" .. name)
			end
		end
	end
end

function Alerts:UNIT_HEALTH(event, unit)
	if not self.frame[unit] then return end
	if not self.db[unit].health then return end

	local health = UnitHealth(unit)
	local healthMax = UnitHealthMax(unit)

	if not UnitIsDeadOrGhost(unit) and (health / healthMax) <= self.db[unit].healthThreshold then
		self:SetAlert(unit, "health", self.db[unit].healthPriority, self.db[unit].healthColor)
	else
		self:ClearAlert(unit, "health")
	end
end

function Alerts:UNIT_SPELLCAST_START(event, unit, lineID, spell)
	if not self.frame[unit] then return end
	if not self.db[unit].casts then return end
	-- we check self.db[unit] and not self.db.base because the option appears only in party mode
	if unit == "player" and self.db[unit].hideSelfAlert then return end

	local cast = self.db[unit].castsSpells[GladiusEx:SafeGetSpellName(spell)]
	if cast then
		line_ids[unit] = lineID
		self:SetAlert(unit, "cast", cast.priority, cast.color)
	end
end

function Alerts:UNIT_SPELLCAST_SUCCEEDED(event, unit, spell)
	if not self.frame[unit] then return end
	if not self.db[unit].casts then return end

	-- in case of a _SUCCEEDED event, we do not check the line ID / spell name.
	-- this is because there are several blizzard bugs where we never receive a cast end event.
	-- (the castbar modules keeps track of cast end times, but it's too much logic for this module)
	-- see https://github.com/slaren/GladiusEx/issues/5
	line_ids[unit] = nil
	local cast = self.db[unit].castsSpells[spell]
	-- flash the screen for an instant
	if cast and (unit ~= "player" or self.db[unit].hideSelfAlert) then
		self:SetAlert(unit, "cast", cast.priority, cast.color)
	end
	self:ClearAlert(unit, "cast")
end

function Alerts:UNIT_SPELLCAST_STOP(event, unit, spell, _, lineID)
	if not self.frame[unit] then return end
	if not self.db[unit].casts then return end
	if line_ids[unit] ~= lineID then return end

	line_ids[unit] = nil
	self:ClearAlert(unit, "cast")
end

local function HasAuraEditBox()
	return not not LibStub("AceGUI-3.0").WidgetVersions["Aura_EditBox"]
end

local function HasSpellEditBox()
	return false -- not not LibStub("AceGUI-3.0").WidgetVersions["Spell_EditBox"]
end

function Alerts:GetOptions(unit)
	local options
	options = {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				bar = {
					type = "group",
					name = L["Alert animation"],
					desc = L["Alert animation settings"],
					inline = true,
					order = 1,
					args = {
						minAlpha = {
							type = "range",
							name = L["Alpha low"],
							desc = L["Low transparency alpha value of the animation"],
							set = function(info, value)
								self.db[unit].minAlpha = value
								self.db[unit].maxAlpha = max(value + 0.1, self.db[unit].maxAlpha)
								GladiusEx:UpdateFrames()
							end,
							min = 0, max = 0.9, bigStep = 0.1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						maxAlpha = {
							type = "range",
							name = L["Alpha high"],
							desc = L["High transparency alpha value of the animation"],
							set = function(info, value)
								self.db[unit].minAlpha = min(value - 0.1, self.db[unit].minAlpha)
								self.db[unit].maxAlpha = value
								GladiusEx:UpdateFrames()
							end,
							min = 0.1, max = 1, bigStep = 0.1,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 2,
						},
						duration = {
							type = "range",
							name = L["Duration"],
							desc = L["Duration of each animation cycle, in seconds"],
							min = 0.1, softMax = 1, bigStep = 0.05,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 3,
						},
						ease = {
							type = "select",
							name = L["Ease"],
							desc = L["Animation ease method"],
							values = {
								["IN"] = L["In"],
								["IN_OUT"] = L["In-Out"],
								["OUT"] = L["Out"],
								["NONE"] = L["None"],
							},
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 4,
						},
						blendMode = {
							type = "select",
							name = L["Blend mode"],
							desc = L["Overlay blend mode"],
							values = {
								["ADD"] = L["Add"],
								-- ["ALPHAKEY"] = L["Alpha key"],
								["BLEND"] = L["Blend"],
								-- ["DISABLE"] = L["Disable"],
								-- ["MOD"] = L["Mod"],
							},
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 5,
						},
					},
				},
			},
		},
		health = {
			type = "group",
			name = L["Low health"],
			desc = L["Low health settings"],
			order = 2,
			args = {
				health = {
					type = "toggle",
					name = L["Low health alert"],
					desc = L["Toggle low health alerts"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 1,
				},
				sep = {
					type = "description",
					name = "",
					width = "full",
					order = 11,
				},
				healthThreshold = {
					type = "range",
					name = L["Low health threshold"],
					desc = L["Minimum health percent to fire the alert"],
					min = 0, max = 1, bigStep = 0.05, isPercent = true,
					disabled = function() return not self.db[unit].health or not self:IsUnitEnabled(unit) end,
					order = 20,
				},
				sep2 = {
					type = "description",
					name = "",
					width = "full",
					order = 21,
				},
				healthPriority = {
					type = "range",
					name = L["Alert priority"],
					desc = L["Select what priority the alert should have - higher equals more priority"],
					min = 0, max = 100, step = 1,
					disabled = function() return not self.db[unit].health or not self:IsUnitEnabled(unit) end,
					order = 30,
				},
				healthColor = {
					type = "color",
					name = L["Alert color"],
					name = L["Alert overlay color"],
					get = function(info) return GladiusEx:GetColorOption(self.db[unit], info) end,
					set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db[unit], info, r, g, b, a) end,
					hasAlpha = true,
					disabled = function() return not self.db[unit].health or not self:IsUnitEnabled(unit) end,
					order = 40,
				},
			},
		},
		casts = {
			type = "group",
			name = L["Casts"],
			childGroups = "tree",
			order = 3,
			args = {
				casts = {
					type = "toggle",
					name = L["Casts alerts"],
					desc = L["Toggle alerts when some spells are being cast"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 1,
				},
				hideSelfAlert = {
					type = "toggle",
					name = L["Hide cast alerts on self"],
					desc = L["Hide cast alerts on your own frame when you are casting alert-worthy spells"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					hidden = function() return GladiusEx:IsArenaUnit(unit) end,
					order = 2,
				},
				newCast = {
					type = "group",
					name = L["New cast"],
					desc = L["New cast"],
					inline = true,
					order = 3,
					args = {
						name = {
							type = "input",
							dialogControl = HasSpellEditBox() and "Spell_EditBox" or nil,
							name = L["Spell name"],
							desc = L["Name of the cast spell"],
							get = function() return self.newCastName or "" end,
							set = function(info, value) self.newCastName = (C_Spell and C_Spell.GetSpellName(value) or GetSpellInfo(value)) or value end,
							disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						priority = {
							type= "range",
							name = L["Alert priority"],
							desc = L["Select what priority the cast should have - higher equals more priority"],
							get = function() return self.newCastPriority or "" end,
							set = function(info, value) self.newCastPriority = value end,
							disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
							min = 0, max = 100, step = 1,
							order = 2,
						},
						color = {
							type = "color",
							name = L["Alert color"],
							name = L["Alert overlay color"],
							get = function(info) return self.newCastColor.r, self.newCastColor.g, self.newCastColor.b, self.newCastColor.a end,
							set = function(info, r, g, b, a) self.newCastColor = { r = r, g = g, b = b, a = a } end,
							hasAlpha = true,
							disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
							order = 3,
						},
						add = {
							type = "execute",
							name = L["Add new cast"],
							func = function(info)
								self.db[unit].castsSpells[self.newCastName] = {
									priority = self.newCastPriority,
									color = self.newCastColor,
								}
								options.casts.args[self.newCastName] = self:SetupCastOptions(options, unit, self.newCastName)
								self.newCastName = nil
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) or not (self.newCastName and self.newCastPriority and self.newCastColor) end,
							order = 4,
						},
					},
				},
			},
		},
		auras = {
			type = "group",
			name = L["Auras"],
			desc = L["Toggle alerts when some auras are active"],
			childGroups = "tree",
			order = 4,
			args = {
				auras = {
					type = "toggle",
					name = L["Auras alerts"],
					disabled = function() return not self:IsUnitEnabled(unit) end,
					order = 1,
				},
				newAura = {
					type = "group",
					name = L["New aura"],
					desc = L["New aura"],
					inline = true,
					order = 1,
					args = {
						name = {
							type = "input",
							dialogControl = HasAuraEditBox() and "Aura_EditBox" or nil,
							name = L["Aura name"],
							desc = L["Name of the aura"],
							get = function() return self.newAuraName or "" end,
							set = function(info, value) self.newAuraName = C_Spell and C_Spell.GetSpellName(value) or GetSpellInfo(value) or value end,
							disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
							order = 1,
						},
						priority = {
							type= "range",
							name = L["Alert priority"],
							desc = L["Select what priority the aura should have - higher equals more priority"],
							get = function() return self.newAuraPriority or "" end,
							set = function(info, value) self.newAuraPriority = value end,
							disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
							min = 0, max = 100, step = 1,
							order = 2,
						},
						color = {
							type = "color",
							name = L["Alert color"],
							get = function(info) return self.newAuraColor.r, self.newAuraColor.g, self.newAuraColor.b, self.newAuraColor.a end,
							set = function(info, r, g, b, a) self.newAuraColor = { r = r, g = g, b = b, a = a } end,
							hasAlpha = true,
							disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
							order = 3,
						},
						add = {
							type = "execute",
							name = L["Add new aura"],
							func = function(info)
								self.db[unit].aurasSpells[self.newAuraName] = {
									priority = self.newAuraPriority,
									color = self.newAuraColor,
								}
								options.auras.args[self.newAuraName] = self:SetupAuraOptions(options, unit, self.newAuraName)
								self.newAuraName = nil
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) or not (self.newAuraName and self.newAuraPriority and self.newAuraColor) end,
							order = 4,
						},
					},
				},
			},
		},
	}

	-- set some initial values
	self.newCastPriority = 5
	self.newCastColor = { r = 1, g = 0, b = 0, a = 1 }
	self.newAuraPriority = 5
	self.newAuraColor = { r = 1, g = 0, b = 0, a = 1 }

	-- setup casts
	for cast, v in pairs(self.db[unit].castsSpells) do
		if v then
			options.casts.args[cast] = self:SetupCastOptions(options, unit, cast)
		end
	end

	-- setup auras
	for aura, v in pairs(self.db[unit].aurasSpells) do
		if v then
			options.auras.args[aura] = self:SetupAuraOptions(options, unit, aura)
		end
	end

	return options
end

function Alerts:SetupCastOptions(options, unit, cast)
	return {
		type = "group",
		name = cast,
		desc = cast,
		disabled = function() return not self:IsUnitEnabled(unit) end,
		args = {
			name = {
				type = "input",
				dialogControl = HasSpellEditBox() and "Spell_EditBox" or nil,
				name = L["Spell name"],
				desc = L["Name of the cast"],
				get = function(info) return info[#(info) - 1] end,
				set = function(info, value)
					local old_name = info[#(info) - 1]
					-- create new cast
					self.db[unit].castsSpells[value] = self.db[unit].castsSpells[old_name]
					options.casts.args[value] = self:SetupCastOptions(options, unit, value)
					-- delete old cast
					self.db[unit].castsSpells[old_name] = false
					options.casts.args[old_name] = nil
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
				order = 1,
			},
			priority = {
				type= "range",
				name = L["Alert priority"],
				desc = L["Select what priority the cast should have - higher equals more priority"],
				min = 0, softMax = 100, step = 1,
				get = function() return self.db[unit].castsSpells[cast].priority end,
				set = function(info, value)
					self.db[unit].castsSpells[cast].priority = value
					GladiusEx:UpdateFrames()
				end,
				order = 2,
			},
			color = {
				type = "color",
				name = L["Alert color"],
				name = L["Alert overlay color"],
				hasAlpha = true,
				get = function(info) return self.db[unit].castsSpells[cast].color.r, self.db[unit].castsSpells[cast].color.g, self.db[unit].castsSpells[cast].color.b, self.db[unit].castsSpells[cast].color.a end,
				set = function(info, r, g, b, a) self.db[unit].castsSpells[cast].color = { r = r, g = g, b = b, a = a } end,
				disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
				order = 3,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				func = function(info)
					local name = info[#(info) - 1]
					self.db[unit].castsSpells[name] = false
					options.casts.args[name] = nil
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self.db[unit].casts or not self:IsUnitEnabled(unit) end,
				order = 4,
			},
		},
	}
end

function Alerts:SetupAuraOptions(options, unit, aura)
	return {
		type = "group",
		name = aura,
		desc = aura,
		disabled = function() return not self:IsUnitEnabled(unit) end,
		args = {
			name = {
				type = "input",
				dialogControl = HasAuraEditBox() and "Aura_EditBox" or nil,
				name = L["Aura name"],
				desc = L["Name of the aura"],
				get = function(info) return info[#(info) - 1] end,
				set = function(info, value)
					local old_name = info[#(info) - 1]
					-- create new aura
					self.db[unit].aurasSpells[value] = self.db[unit].aurasSpells[old_name]
					options.auras.args[value] = self:SetupAuraOptions(options, unit, value)
					-- delete old aura
					self.db[unit].aurasSpells[old_name] = false
					options.auras.args[old_name] = nil
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
				order = 1,
			},
			priority = {
				type= "range",
				name = L["Alert priority"],
				desc = L["Select what priority the aura should have - higher equals more priority"],
				min = 0, softMax = 100, step = 1,
				get = function() return self.db[unit].aurasSpells[aura].priority end,
				set = function(info, value)
					self.db[unit].aurasSpells[aura].priority = value
					GladiusEx:UpdateFrames()
				end,
				order = 2,
			},
			color = {
				type = "color",
				name = L["Alert color"],
				name = L["Alert overlay color"],
				hasAlpha = true,
				get = function(info) return self.db[unit].aurasSpells[aura].color.r, self.db[unit].aurasSpells[aura].color.g, self.db[unit].aurasSpells[aura].color.b, self.db[unit].aurasSpells[aura].color.a end,
				set = function(info, r, g, b, a) self.db[unit].aurasSpells[aura].color = { r = r, g = g, b = b, a = a } end,
				disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
				order = 3,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				func = function(info)
					local name = info[#(info) - 1]
					self.db[unit].aurasSpells[name] = false
					options.auras.args[name] = nil
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self.db[unit].auras or not self:IsUnitEnabled(unit) end,
				order = 4,
			},
		},
	}
end
