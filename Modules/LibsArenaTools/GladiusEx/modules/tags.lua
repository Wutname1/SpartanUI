local GladiusEx = _G.GladiusEx
local fn = LibStub("LibFunctional-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM = LibStub("LibSharedMedia-3.0")

-- global functions
local strfind, strgsub, strgmatch, strformat = string.find, string.gsub, string.gmatch, string.format
local tinsert = table.insert
local pairs, select = pairs, select

local UnitName, UnitIsDeadOrGhost, LOCALIZED_CLASS_NAMES_MALE = UnitName, UnitIsDeadOrGhost, LOCALIZED_CLASS_NAMES_MALE
local UnitClass, UnitRace = UnitClass, UnitRace
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitExists, UnitIsConnected = UnitExists, UnitIsConnected

local Tags = GladiusEx:NewGladiusExModule("Tags", {
	tags = {},
	tagEvents = {},
	tagsTexts = {
		["HealthBar Left Text"] = {
			attachTo = "HealthBar",
			position = "LEFT",
			offsetX = 2,
			offsetY = -1,

			globalFontSize = true,
			size = 11,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[name:status]",
		},
		["HealthBar Right Text"] = {
			attachTo = "HealthBar",
			position = "RIGHT",
			offsetX = -2,
			offsetY = -1,

			globalFontSize = true,
			size = 11,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[health:short]",
		},
		["PowerBar Left Text"] = {
			attachTo = "PowerBar",
			position = "LEFT",
			offsetX = 2,
			offsetY = -1,

			globalFontSize = true,
			size = 11,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[spec]",
		},
		["PowerBar Right Text"] = {
			attachTo = "PowerBar",
			position = "RIGHT",
			offsetX = -2,
			offsetY = -1,

			globalFontSize = true,
			size = 11,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[power:short]",
		},
		["TargetBar Left Text"] = {
			attachTo = "TargetBar",
			position = "LEFT",
			offsetX = 2,
			offsetY = 0,

			globalFontSize = false,
			size = 9,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[name:status]",
		},
		["TargetBar Right Text"] = {
			attachTo = "TargetBar",
			position = "RIGHT",
			offsetX = -2,
			offsetY = 0,

			globalFontSize = false,
			size = 9,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[health:short]",
		},
		["PetBar Left Text"] = {
			attachTo = "PetBar",
			position = "LEFT",
			offsetX = 2,
			offsetY = 0,

			globalFontSize = false,
			size = 9,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[name:status]",
		},
		["PetBar Right Text"] = {
			attachTo = "PetBar",
			position = "RIGHT",
			offsetX = -2,
			offsetY = 0,

			globalFontSize = false,
			size = 9,
			color = { r = 1, g = 1, b = 1, a = 1 },

			text = "[health:short]",
		},
	},
})

function Tags:OnEnable()
	-- frame
	if not self.frame then
		self.frame = {}
	end

	-- cached functions
	self:ClearTagCache()
end

function Tags:UpdateEvents(unit)
	if not self.events then
		self.events = {}
	end

	self.events[unit] = {}

	for k,v in pairs(self.db[unit].tagsTexts) do
		-- get tags
		for tag in v.text:gmatch("%[(.-)%]") do
			-- get events
			local tag_events = self:GetTagEvents(unit, tag)
			if tag_events then
				for event in tag_events:gmatch("%S+") do
					if not self.events[unit][event] then
						self.events[unit][event] = {}
					end

					self.events[unit][event][k] = true
				end
			end
		end
	end

	-- register events
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:UNIT_TARGET("PLAYER_TARGET_CHANGED", "") end)

	for unit, events in pairs(self.events) do
		for event in pairs(events) do
			if strfind(event, "GLADIUS") then
				self:RegisterMessage(event, "OnEvent")
			else
				self:RegisterEvent(event, "OnEvent")
			end
		end
	end
end

function Tags:OnDisable()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

	for unit in pairs(self.frame) do
		for text in pairs(self.frame[unit]) do
			self.frame[unit][text]:Hide()
		end
	end
end

function Tags:GetFrames()
	return nil
end

function Tags:UNIT_NAME_UPDATE(event, unit)
	if not self.frame[unit] then return end

	self:Refresh(unit)
end

function Tags:UNIT_TARGET(event, unit)
	local tunit = unit .. "target"
	if not self.frame[tunit] then return end

	self:Refresh(tunit)
end

function Tags:OnEvent(event, unit)
	if self.events[unit] and self.events[unit][event] then
		-- update texts
		for text, _ in pairs(self.events[unit][event]) do
			self:UpdateText(unit, text)
		end
	end
end

-- Takes a tag text and returns a function that receives a unit parameter and returns the formatted text
function Tags:ParseText(unit, text)
	if text == "" then
		return function() return "" end
	end

	local out = {}
	local arg_values = {}


	local function output_text(otext)
		if otext ~= "" then
			tinsert(arg_values, otext)
			tinsert(out, "args[" .. tostring(#out + 1) .. "]")
		end
	end

	local function output_tag(tag)
		tinsert(arg_values, self:GetTagFunc(unit, tag))
		tinsert(out, "args[" .. tostring(#out + 1) .. "](unit) or default")
	end

	while true do
		local posb, tag, pose = string.match(text, "()%[(.-)%]()")
		if not posb then
			output_text(text)
			break
		end
		local otext = string.sub(text, 1, posb - 1)
		output_text(otext)
		output_tag(tag)
		text = string.sub(text, pose)
	end

	local fntext = [[local strjoin, default = strjoin, ""; return function(args, unit) ]] ..
		[[ return strjoin("", ]] .. table.concat(out, ", ") .. [[)]] ..
		[[ end]]
	local text_fn = loadstring(fntext)()
	return fn.bind(text_fn, arg_values)
end

function Tags:GetTextFunction(unit, tagText)
	local fn = self.text_cache[tagText]
	if not fn then
		fn = self:ParseText(unit, tagText)
		self.text_cache[tagText] = fn
	end
	return fn
end

function Tags:GetTagFunc(unit, tag)
	local func = self.func_cache[tag]
	if not func then
		local builtins = self:GetBuiltinTags()
		if self.db[unit].tags[tag] then
			func = loadstring("local strformat = string.format; return " .. self.db[unit].tags[tag])()
		elseif builtins[tag] then
			func = builtins[tag]
		else
			func = function() return "[" .. tag .. "]" end
		end
		self.func_cache[tag] = func
	end
	return func
end

function Tags:ClearTagCache()
	self.func_cache = {}
	self.text_cache = {}
end

function Tags:UpdateText(unit, text)
	if not self.frame[unit] or not self.frame[unit][text] then return end

	-- update tag
	local unit = self.frame[unit][text].unit
	local tagText = self.db[unit].tagsTexts[text].text
	local fn = self:GetTextFunction(unit, tagText)
	local formattedText = fn(unit)

	--[[
	local formattedText = strgsub(self.db[unit].tagsTexts[text].text, "%[(.-)%]", function(tag)
			return self:GetTagFunc(tag)(unit)
		end
	end)
	]]

	self.frame[unit][text].fs:SetText(formattedText or tagText)
end

function Tags:GetTagEvents(unit, tag)
	return self.db[unit].tagEvents[tag] or self:GetBuiltinTagsEvents()[tag]
end

function Tags:Refresh(unit)
	for text, _ in pairs(self.db[unit].tagsTexts) do
		-- update text
		self:UpdateText(unit, text)
	end
end

function Tags:CreateFrame(unit, text)
	local button = GladiusEx.buttons[unit]
	if not button then return end

	-- create frame
	self.frame[unit][text] = CreateFrame("Frame", nil, button)
	-- self.frame[unit][text].fs = self.frame[unit][text]:CreateFontString("GladiusEx" .. self:GetName() .. unit .. text, "OVERLAY")
	self.frame[unit][text].fs = GladiusEx:CreateSuperFS(self.frame[unit][text], "OVERLAY")
end

function Tags:Update(unit)
	if not self.frame[unit] then
		self.frame[unit] = {}
	end

	self:ClearTagCache()
	self:UpdateEvents(unit)

	-- hide removed texts
	for text, frame in pairs(self.frame[unit]) do
		if not self.db[unit].tagsTexts[text] then
			frame:Hide()
			frame.fs:Hide()
		end
	end

	-- update text frames
	for text, _ in pairs(self.db[unit].tagsTexts) do
		local attachframe = GladiusEx:GetAttachFrame(unit, self.db[unit].tagsTexts[text].attachTo, true)

		if attachframe then
			-- create frame
			if not self.frame[unit][text] then
				self:CreateFrame(unit, text)
				if attachframe.unit then
					if not self.frame[attachframe.unit] then
						self.frame[attachframe.unit] = {}
						self.events[attachframe.unit] = self.events[unit]
					end
					self.frame[attachframe.unit][text] = self.frame[unit][text]
					if attachframe.poll then
						GladiusEx:Log("Polling:", unit, attachframe.unit)
						-- not a real unit so it needs to be polled
						local polling_time = 0.5
						local next_update = 0
						self.frame[unit][text]:SetScript("OnUpdate", function(f, elapsed)
							next_update = next_update - elapsed
							if next_update <= 0 then
								self:UpdateText(unit, text)
								next_update = polling_time
							end
						end)
					end
				end
				self.frame[unit][text].unit = attachframe.unit or unit
			end

			-- update frame
			local position = self.db[unit].tagsTexts[text].position
			local hjustify = (strfind(position, "RIGHT") and "RIGHT") or (strfind(position, "LEFT") and "LEFT") or "CENTER"
			local vjustify = (strfind(position, "TOP") and "TOP") or (strfind(position, "BOTTOM") and "BOTTOM") or "MIDDLE"
			local ox = self.db[unit].tagsTexts[text].offsetX
			local oy = self.db[unit].tagsTexts[text].offsetY
			self.frame[unit][text]:SetParent(attachframe)
			self.frame[unit][text]:SetFrameStrata(attachframe:GetFrameStrata())
			self.frame[unit][text]:SetFrameLevel(50)

			-- update fontstring
			self.frame[unit][text].fs:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusEx.db.base.globalFont),
				self.db[unit].tagsTexts[text].globalFontSize and GladiusEx.db.base.globalFontSize or self.db[unit].tagsTexts[text].size,
				GladiusEx.db.base.globalFontOutline)
			self.frame[unit][text].fs:SetTextColor(self.db[unit].tagsTexts[text].color.r, self.db[unit].tagsTexts[text].color.g, self.db[unit].tagsTexts[text].color.b, self.db[unit].tagsTexts[text].color.a)
			self.frame[unit][text].fs:SetShadowOffset(1, -1)
			self.frame[unit][text].fs:SetShadowColor(GladiusEx.db.base.globalFontShadowColor.r, GladiusEx.db.base.globalFontShadowColor.g, GladiusEx.db.base.globalFontShadowColor.b, GladiusEx.db.base.globalFontShadowColor.a)
			self.frame[unit][text].fs:SetJustifyH(hjustify)
			self.frame[unit][text].fs:SetJustifyV(vjustify)
			self.frame[unit][text].fs:SetWordWrap(false)
			self.frame[unit][text].fs:ClearAllPoints()
			self.frame[unit][text].fs:SetPoint(position, attachframe, position, ox, oy)

			-- limit text bounds
			local invpos = (position == "LEFT" and "RIGHT") or (position == "RIGHT" and "LEFT")
			if invpos then
				--self.frame[unit][text].fs:SetPoint(invpos, attachframe, invpos, ox, oy)
				self.frame[unit][text].fs:SetPoint(invpos, attachframe, "CENTER", 0, oy)
			end

			-- hide
			self.frame[unit][text]:Hide()
		end
	end
end

function Tags:Show(unit)
	if (not self.frame[unit]) then
		self.frame[unit] = {}
	end

	-- update text
	for text, _ in pairs(self.db[unit].tagsTexts) do
		self:UpdateText(unit, text)
	end

	-- show
	for _, text in pairs(self.frame[unit]) do
		text:Show()
	end
end

function Tags:Reset(unit)
	if not self.frame[unit] then return end

	-- hide
	for _, text in pairs(self.frame[unit]) do
		text:Hide()
	end
end

function Tags:Test(unit)
	-- test
end

function Tags:GetOptions(unit)
	local optionTags

	-- add values
	local addTextAttachTo = ""
	local addTextName = ""
	local addTagName = ""

	local options = {}
	options.textList = {
		type = "group",
		name = L["Texts"],
		order = 1,
		args = {
			add = {
				type = "group",
				name = L["Add text"],
				inline = true,
				order = 1,
				hidden = function() return not GladiusEx.db.base.advancedOptions end,
				args = {
					name = {
						type = "input",
						name = L["Name"],
						desc = L["Name of the text element"],
						get = function(info)
							return addTextName
						end,
						set = function(info, value)
							addTextName = value
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 5,
					},
					attachTo = {
						type = "select",
						name = L["Attach to"],
						desc = L["Attach text to module bar"],
						values = function() return self:GetOtherAttachPoints(unit) end,
						get = function(info)
							return addTextAttachTo
						end,
						set = function(info, value)
							addTextAttachTo = value
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 10,
					},
					add = {
						type = "execute",
						name = L["Add text"],
						func = function()
							local text = addTextAttachTo .. " " .. addTextName

							if (addTextName ~= "" and not self.db[unit].tagsTexts[text]) then
								-- add to db
								self.db[unit].tagsTexts[text] = {
									attachTo = addTextAttachTo,
									position = "LEFT",
									offsetX = 0,
									offsetY = 0,
									globalFontSize = true,
									size = 11,
									color = { r = 1, g = 1, b = 1, a = 1 },
									text = ""
								}

								-- add to options
								options.textList.args[text] = self:GetTextOptionTable(options, unit, text, 100)

								-- set tags
								options.textList.args[text].args.tag.args = optionTags

								-- update
								GladiusEx:UpdateFrames()
							end
						end,
						disabled = function() return addTextName == "" or addTextAttachTo == "" or not self:IsUnitEnabled(unit) end,
						order = 15,
					},
				},
			},
		}
	}

	options.tagList = {
		type = "group",
		name = L["Tags"],
		hidden = function() return not GladiusEx.db.base.advancedOptions end,
		order = 2,
		args = {
			add = {
				type = "group",
				name = L["Add tag"],
				inline = true,
				order = 1,
				args = {
					name = {
						type = "input",
						name = L["Name"],
						desc = L["Name of the tag"],
						get = function(info)
							return addTagName
						end,
						set = function(info, value)
							addTagName = value
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 5,
					},
					add = {
						type = "execute",
						name = L["Add tag"],
						func = function()
							if (addTagName ~= "" and not self.db[unit].tags[addTagName]) then
								-- add to db
								self.db[unit].tags[addTagName] = "function(unit)\n  return UnitName(unit)\nend"
								self.db[unit].tagEvents[addTagName] = ""

								-- add to options
								options.tagList.args[addTagName] = self:GetTagOptionTable(options, unit, addTagName, 100)

								-- add to text option tags
								for text, v in pairs(options.textList.args) do
									if (v.args.tag) then
										local tag = addTagName
										local tagName = Tags:FormatTagName(tag)

										options.textList.args[text].args.tag.args[tag] = {
											type = "toggle",
											name = tagName,
											get = function(info)
												local key = info[#info - 2]

												-- check if the tag is in the text
												if strfind(self.db[unit].tagsTexts[key].text, "%[" .. info[#info] .. "%]") then
													return true
												else
													return false
												end
											end,
											set = function(info, v)
												local key = info[#info - 2]

												-- add/remove tag to the text
												if not v then
													self.db[unit].tagsTexts[key].text = strgsub(self.db[unit].tagsTexts[key].text, "%[" .. info[#info] .. "%]", "")

													-- trim right
													self.db[unit].tagsTexts[key].text = strgsub(self.db[unit].tagsTexts[key].text, "^(.-)%s*$", "%1")
												else
													self.db[unit].tagsTexts[key].text = self.db[unit].tagsTexts[key].text .. " [" .. info[#info] .. "]"
												end

												-- update
												GladiusEx:UpdateFrames()
											end,
											order = 100,
										}
									end
								end

								-- update
								GladiusEx:UpdateFrames()
							end
						end,
						disabled = function() return addTagName == "" or not self:IsUnitEnabled(unit) end,
						order = 10,
					},
				},
			},
		},
	}

	-- text option tags
	optionTags = {
		text = {
			type = "input",
			name = L["Text"],
			desc = L["Text to be displayed"],
			disabled = function() return not self:IsUnitEnabled(unit) end,
			width = "double",
			order = 1,
		},
	}

	local order = 2
	local function MakeTagTextOption(tag)
		local tagName = Tags:FormatTagName(tag)

		optionTags[tag] = {
			type = "toggle",
			name = tagName,
			get = function(info)
				local key = info[#info - 2]

				-- check if the tag is in the text
				if strfind(self.db[unit].tagsTexts[key].text, "%[" .. info[#info] .. "%]") then
					return true
				else
					return false
				end
			end,
			set = function(info, v)
				local key = info[#info - 2]

				-- add/remove tag to the text
				if not v then
					self.db[unit].tagsTexts[key].text = strgsub(self.db[unit].tagsTexts[key].text, "%[" .. info[#info] .. "%]", "")

					-- trim right
					self.db[unit].tagsTexts[key].text = strgsub(self.db[unit].tagsTexts[key].text, "^(.-)%s*$", "%1")
				else
					self.db[unit].tagsTexts[key].text = self.db[unit].tagsTexts[key].text .. " [" .. info[#info] .. "]"
				end

				-- update
				GladiusEx:UpdateFrames()
			end,
			disabled = function() return not self:IsUnitEnabled(unit) end,
			order = order,
		}

		order = order + 1
	end

	local tag_names = self:GetTagNames(unit)
	table.sort(tag_names, function(a, b)
		return Tags:FormatTagName(a) < Tags:FormatTagName(b)
	end)
	for _, tag in ipairs(tag_names) do MakeTagTextOption(tag) end

	-- texts
	order = 1
	local sorted_texts = fn.sort(fn.keys(self.db[unit].tagsTexts))
	for _, text in ipairs(sorted_texts) do
		options.textList.args[text] = self:GetTextOptionTable(options, unit, text, order)

		-- set tags
		options.textList.args[text].args.tag.args = optionTags

		order = order + 1
	end

	-- tags
	order = 1
	for tag, _ in pairs(self.db[unit].tags) do
		options.tagList.args[tag] = self:GetTagOptionTable(options, unit, tag, order)
		order = order + 1
	end

	return options
end

function Tags:GetTextOptionTable(options, unit, text, order)
	local function getOption(info)
		local key = info[#info - 2]
		return self.db[unit].tagsTexts[key][info[#info]]
	end

	local function setOption(info, value)
		local key = info[#info - 2]
		self.db[unit].tagsTexts[key][info[#info]] = value
		GladiusEx:UpdateFrames()
	end

	local function getColorOption(info)
		local key = info[#info - 2]
		return self.db[unit].tagsTexts[key][info[#info]].r, self.db[unit].tagsTexts[key][info[#info]].g,
			self.db[unit].tagsTexts[key][info[#info]].b, self.db[unit].tagsTexts[key][info[#info]].a
	end

	local function setColorOption(info, r, g, b, a)
		local key = info[#info - 2]
		self.db[unit].tagsTexts[key][info[#info]].r, self.db[unit].tagsTexts[key][info[#info]].g,
		self.db[unit].tagsTexts[key][info[#info]].b, self.db[unit].tagsTexts[key][info[#info]].a = r, g, b, a
		GladiusEx:UpdateFrames()
	end

	return {
		type = "group",
		name = text,
		childGroups = "tree",
		get = getOption,
		set = setOption,
		order = order,
		disabled = function() return not self:IsUnitEnabled(unit) end,
		args = {
			tag = {
				type = "group",
				name = L["Tag"],
				desc = L["Tag settings"],
				inline = true,
				order = 2,
				args = {},
			},
			text = {
				type = "group",
				name = L["Text"],
				desc = L["Text settings"],
				inline = true,
				order = 3,
				args = {
					color = {
						type = "color",
						name = L["Text color"],
						desc = L["Color of the text"],
						hasAlpha = true,
						get = getColorOption,
						set = setColorOption,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 5,
					},
					globalFontSize = {
						type = "toggle",
						name = L["Global font size"],
						desc = L["Use the global font size"],
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 7,
					},
					size = {
						type = "range",
						name = L["Text size"],
						desc = L["Size of the text"],
						min = 1, max = 20, step = 1,
						disabled = function() return not self:IsUnitEnabled(unit) or self.db[unit].tagsTexts[text].globalFontSize end,
						order = 10,
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
					position = {
						type = "select",
						name = L["Text align"],
						desc = L["Align of the text"],
						values = {
							["BOTTOM"] = L["Bottom"],
							["BOTTOMLEFT"] = L["Bottom left"],
							["BOTTOMRIGHT"] = L["Bottom right"],
							["CENTER"] = L["Center"],
							["LEFT"] = L["Left"],
							["RIGHT"] = L["Right"],
							["TOP"] = L["Top"],
							["TOPLEFT"] = L["Top left"],
							["TOPRIGHT"] = L["Top right"],
						},
						disabled = function() return not self:IsUnitEnabled(unit) end,
						width = "double",
						order = 5,
					},
					offsetX = {
						type = "range",
						name = L["Offset X"],
						desc = L["X offset of the frame"],
						softMin = -100, softMax = 100, bigStep = 1,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 10,
					},
					offsetY = {
						type = "range",
						name = L["Offset Y"],
						desc = L["Y offset of the frame"],
						softMin = -100, softMax = 100, bigStep = 1,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 15,
					},
				},
			},
			delete = {
				type = "execute",
				name = L["Delete text"],
				func = function()
					-- remove from db
					self.db[unit].tagsTexts[text] = nil
					-- remove from options
					options.textList.args[text] = nil
					-- update
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self:IsUnitEnabled(unit) end,
				hidden = function() return not GladiusEx.db.base.advancedOptions end,
				order = 5,
			},
		},
	}
end

function Tags:FormatTagName(tag)
	local tag_name = rawget(L, tag .. "Tag") or strformat(L["Tag: %s"], tag)
	return tag_name
end

function Tags:GetTagOptionTable(options, unit, tag, order)
	local tagName = self:FormatTagName(tag)

	return {
		type = "group",
		name = tagName,
		childGroups = "tree",
		disabled = function() return not self:IsUnitEnabled(unit) end,
		order = order,
		args = {
			tag = {
				type = "group",
				name = L["Tag"],
				desc = L["Tag settings"],
				inline = true,
				order = 10,
				args = {
					name = {
						type = "input",
						name = L["Name"],
						desc = L["Name of the tag"],
						get = function(info)
							local key = info[#info - 2]
							return key
						end,
						set = function(info, value)
							local key = info[#info - 2]

							-- db
							self.db[unit].tags[value] = self.db[unit].tags[key]
							self.db[unit].tagEvents[value] = self.db[unit].tagEvents[key]

							self.db[unit].tags[key] = nil
							self.db[unit].tagEvents[key] = nil

							-- options
							options.tagList.args[key] = nil
							options.tagList.args[value] = self:GetTagOptionTable(options, unit, value, order)

							-- update
							GladiusEx:UpdateFrames()
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						width = "double",
						order = 5,
					},
					events = {
						type = "input",
						name = L["Events"],
						desc = L["Events which update the tag"],
						get = function(info)
							local key = info[#info - 2]
							return self.db[unit].tagEvents[key]
						end,
						set = function(info, value)
							local key = info[#info - 2]
							self.db[unit].tagEvents[key] = value

							-- update
							GladiusEx:UpdateFrames()
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						width = "double",
						order = 10,
					},
					func = {
						type = "input",
						name = L["Function"],
						get = function(info)
							local key = info[#info - 2]
							return self.db[unit].tags[key]
						end,
						set = function(info, value)
							local key = info[#info - 2]
							self.db[unit].tags[key] = value

							-- update
							GladiusEx:UpdateFrames()
						end,
						disabled = function() return not self:IsUnitEnabled(unit) end,
						width = "double",
						multiline = true,
						order = 15,
					},
				},
			},
			delete = {
				type = "execute",
				name = L["Delete tag"],
				func = function()
					-- remove from db
					self.db[unit].tags[tag] = nil
					self.db[unit].tagEvents[tag] = nil

					-- remove from options
					options.tagList.args[tag] = nil

					-- remove from text option tags
					for text, v in pairs(options.textList.args) do
						if (v.args.tag and v.args.tag.args[tag]) then
							options.textList.args[text].args.tag.args[tag] = nil
						end
					end

					-- update
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self:IsUnitEnabled(unit) end,
				order = 20,
			},
		},
	}
end

function Tags:GetBuiltinTags()
	local function health(unit)
		if GladiusEx:IsTesting(unit) then
			return GladiusEx.testing[unit].health
		elseif UnitExists(unit) then
			return UnitHealth(unit)
		else
			return 1
		end
	end
	local function maxhealth(unit)
		if GladiusEx:IsTesting(unit) then
			return GladiusEx.testing[unit].maxHealth
		elseif UnitExists(unit) then
			return UnitHealthMax(unit)
		else
			return 1
		end
	end
	local function power(unit)
		if GladiusEx:IsTesting(unit) then
			return GladiusEx.testing[unit].power
		elseif UnitExists(unit) then
			return UnitPower(unit)
		else
			return 1
		end
	end
	local function maxpower(unit)
		if GladiusEx:IsTesting(unit) then
			return GladiusEx.testing[unit].maxPower
		elseif UnitExists(unit) then
			return UnitPowerMax(unit)
		else
			return 1
		end
	end
	local function absorbs(unit)
		if GladiusEx:IsTesting(unit) then
			return GladiusEx.testing[unit].maxHealth * 0.2
		elseif UnitExists(unit) then
			return UnitGetTotalAbsorbs(unit)
		else
			return 0
		end
	end
	local function healthabsorbs(unit)
		return health(unit) + absorbs(unit)
	end
	local function short(fn)
		return function(unit)
			local amount = fn(unit) or 0
			if amount >= 1000 then
				return strformat("%.1fk", (amount / 1000))
			else
				return amount
			end
		end
	end
	local function percentage(fn, fnmax)
		return function(unit)
			local amount = fn(unit)
			local maxamount = fnmax(unit)

			if not amount or not maxamount or maxamount == 0 then
				return ""
			else
        local value = amount / maxamount * 100
        -- avoid printing "XYZ.0%", print "50%"
        if value == math.floor(value) then
          return value .. "%"
        else
          return strformat("%.1f%%", value)
        end
			end
		end
	end
	local function percentage_rounded(fn, fnmax)
		return function(unit)
			local amount = fn(unit)
			local maxamount = fnmax(unit)

			if not amount or not maxamount or maxamount == 0 then
				return ""
			else
        return math.floor((amount / maxamount * 100) + 0.5) .. "%"
      end
		end
	end

	return {
		["name"] = function(unit)
			return UnitName(unit) or unit
		end,
    ["unit"] = function(unit)
      return unit
    end,
    ["index0"] = function(unit)
      if unit == "player" then
        return 0
      else
        return string.match(unit, "party(%d+)") or string.match(unit, "arena(%d+)") or "?"
      end
    end,
    ["index1"] = function(unit)
      if unit == "player" then
        return 1
      else
        local party = string.match(unit, "party(%d+)")
        if party then
          return party + 1
        else
          return string.match(unit, "arena(%d+)") or "?"
        end
      end
    end,
		["name:status"] = function(unit)
			if not UnitExists(unit) then
				return unit
			elseif not UnitIsConnected(unit) then
				return L["OFFLINE"]
			elseif UnitIsDeadOrGhost(unit) then
				return L["DEAD"]
			else
				return UnitName(unit) or unit
			end
		end,
		["class"] = function(unit)
			if GladiusEx:IsTesting(unit) then
				return LOCALIZED_CLASS_NAMES_MALE[GladiusEx.testing[unit].unitClass]
			else
				return UnitClass(unit) or LOCALIZED_CLASS_NAMES_MALE[GladiusEx.buttons[unit].class] or ""
			end
		end,
		["class:short"] = function(unit)
			if GladiusEx:IsTesting(unit) then
				return L[GladiusEx.testing[unit].unitClass .. ":short"]
			else
				return L[(select(2, UnitClass(unit)) or GladiusEx.buttons[unit].class or "") .. ":short"]
			end
		end,
		["race"] = function(unit)
			if GladiusEx:IsTesting(unit) then
				return GladiusEx.testing[unit].unitRace
			else
				return UnitRace(unit) or ""
			end
		end,
		["spec"] = function(unit)
			local specID
			if GladiusEx:IsTesting(unit) then
				specID = GladiusEx.testing[unit].specID
			else
				specID = GladiusEx.buttons[unit].specID or 0
			end

			if not specID or specID == 0 then
				return ""
			end
			return select(2, GladiusEx.Data.GetSpecializationInfoByID(specID))
		end,
		["spec:short"] = function(unit)
			local specID
			if GladiusEx:IsTesting(unit) then
				specID = GladiusEx.testing[unit].specID
			else
				specID = GladiusEx.buttons[unit].specID or 0
			end

			if not specID or specID == 0 then
				return ""
			end
			return L["specID:" .. specID .. ":short"]
		end,
		["health"] = health,
		["maxhealth"] = maxHealth,
		["health:short"] = short(health),
		["maxhealth:short"] = short(maxhealth),
		["health:percentage"] = percentage(health, maxhealth),
		["health:rounded"] = percentage_rounded(health, maxhealth),
		["absorbs"] = absorbs,
		["absorbs:short"] = short(absorbs),
		["healthabsorbs"] = healthabsorbs,
		["healthabsorbs:short"] = short(healthabsorbs),
		["power"] = power,
		["maxpower"] = maxpower,
		["power:short"] = short(power),
		["maxpower:short"] = short(maxpower),
		["power:percentage"] = percentage(power, maxpower),
		["power:rounded"] = percentage_rounded(power, maxpower),
	}
end

function Tags:GetTagNames(unit)
	local names = {}
	for tag, _ in pairs(self:GetBuiltinTags()) do table.insert(names, tag) end
	for tag, _ in pairs(self.db[unit].tags) do table.insert(names, tag) end
	return names
end

function Tags:GetBuiltinTagsEvents()
	return {
		["name"] = "",
		["name:status"] = "UNIT_HEALTH",
		["class"] = "",
		["class:short"] = "",
		["race"] = "",
		["spec"] = "GLADIUS_SPEC_UPDATE",
		["spec:short"] = "GLADIUS_SPEC_UPDATE",

		["health"] = "UNIT_HEALTH UNIT_MAXHEALTH",
		["maxhealth"] = "UNIT_HEALTH UNIT_MAXHEALTH",
		["health:short"] = "UNIT_HEALTH UNIT_MAXHEALTH",
		["maxhealth:short"] = "UNIT_HEALTH UNIT_MAXHEALTH",
		["health:percentage"] = "UNIT_HEALTH UNIT_MAXHEALTH",
		["health:rounded"] = "UNIT_HEALTH UNIT_MAXHEALTH",

		["absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED",
		["absorbs:short"] = "UNIT_ABSORB_AMOUNT_CHANGED",

		["healthabsorbs"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",
		["healthabsorbs:short"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED",

		["power"] = "UNIT_POWER_UPDATE UNIT_POWER_FREQUENT UNIT_DISPLAYPOWER",
		["maxpower"] = "UNIT_MAXPOWER UNIT_DISPLAYPOWER",
		["power:short"] = "UNIT_POWER_UPDATE UNIT_POWER_FREQUENT UNIT_DISPLAYPOWER",
		["maxpower:short"] = "UNIT_MAXPOWER UNIT_POWER_FREQUENT UNIT_DISPLAYPOWER",
		["power:percentage"] = "UNIT_POWER_UPDATE UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER",
		["power:rounded"] = "UNIT_POWER_UPDATE UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER",
	}
end
