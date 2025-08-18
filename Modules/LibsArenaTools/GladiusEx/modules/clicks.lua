local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")

-- global functions
local tinsert, tsort = table.insert, table.sort

local Clicks = GladiusEx:NewGladiusExModule("Clicks", {
	clickAttributes = {
		["Left"] = { button = "1", modifier = "", action = "target", macro = "" },
		["Right"] = { button = "2", modifier = "", action = "focus", macro = "" },
	},
})

function Clicks:OnEnable()
	-- Table that holds all of the secure frames to apply click actions to.
end

function Clicks:OnDisable()
	-- todo: restore attributes ?
end

-- Finds all the secure frames belonging to a specific unit and return them
function Clicks:GetSecureFrames(unit)
	local frames = {}

	-- Find secure frames
	for point, _ in pairs(self:GetOtherAttachPoints(unit)) do
		local frame = GladiusEx:GetAttachFrame(unit, point)
		if frame and frame.secure then
			tinsert(frames, frame.secure)
		end
	end

	return frames
end

function Clicks:Update(unit)
	-- Update secure frame table
	local frames = self:GetSecureFrames(unit)

	-- Apply attributes to the frames
	for _, frame in ipairs(frames) do
		self:ApplyAttributes(unit, frame)
	end
end

-- Applies attributes to a specific frame
function Clicks:ApplyAttributes(unit, frame)
	-- todo: remove previous attributes ..
	for _, attr in pairs(self.db[unit].clickAttributes) do
    if attr ~= true then -- might be true if deleted
      frame:SetAttribute(attr.modifier .. "type" .. attr.button, attr.action)
      if attr.action == "macro" and attr.macro ~= "" then
        frame:SetAttribute(attr.modifier .. "macrotext" .. attr.button, string.gsub(attr.macro, "*unit", unit))
      elseif attr.action == "spell" and attr.macro ~= "" then
        frame:SetAttribute(attr.modifier .. "spell" .. attr.button, attr.macro)
      end
    end
	end
end

function Clicks:Test(unit)
end

local CLICK_BUTTONS = { ["1"] = L["Left"], ["2"] = L["Right"], ["3"] = L["Middle"], ["4"] = L["Button 4"], ["5"] = L["Button 5"] }
local CLICK_MODIFIERS = { [""] = L["None"], ["ctrl-"] = L["ctrl-"], ["shift-"] = L["shift-"], ["alt-"] = L["alt-"] }

function Clicks:GetOptions(unit)
	local addAttrButton = "1"
	local addAttrMod = ""

	local options

	options = {
		attributeList = {
			type = "group",
			name = L["Click actions"],
			order = 1,
			args = {
				add = {
					type = "group",
					name = L["Add click action"],
					inline = true,
					order = 1,
					args = {
						button = {
							type = "select",
							name = L["Mouse button"],
							desc = L["Select which mouse button this click action uses"],
							values = CLICK_BUTTONS,
							get = function(info) return addAttrButton end,
							set = function(info, value) addAttrButton = value end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 10,
						},
						modifier = {
							type = "select",
							name = L["Modifier"],
							desc = L["Select a modifier for this click action"],
							values = CLICK_MODIFIERS,
							get = function(info) return addAttrMod end,
							set = function(info, value) addAttrMod = value end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 20,
						},
						add = {
							type = "execute",
							name = L["Add"],
							func = function()
								local attr = addAttrMod ~= "" and CLICK_MODIFIERS[addAttrMod] .. CLICK_BUTTONS[addAttrButton] or CLICK_BUTTONS[addAttrButton]
								-- Check for table, because if we delete an action it becomes true instead of nil (see Delete Click Action)
								if type(self.db[unit].clickAttributes[attr]) ~= 'table' then
									-- add to db
									self.db[unit].clickAttributes[attr] = {
										button = addAttrButton,
										modifier = addAttrMod,
										action = "target",
										macro = ""
									}
									options.attributeList.args[attr] = self:GetAttributeOptionTable(options, unit, attr, 100)
									-- update
									GladiusEx:UpdateFrames()
								end
							end,
							disabled = function() return not self:IsUnitEnabled(unit) end,
							order = 30,
						},
					},
				}
			},
		}
	}

	-- attributes
	local order = 1
	for attr, value in pairs(self.db[unit].clickAttributes) do
    if type(value) == "table" then
      options.attributeList.args[attr] = self:GetAttributeOptionTable(options, unit, attr, order)
      order = order + 1
    end
	end

	return options
end

function Clicks:GetAttributeOptionTable(options, unit, attribute, order)
	local function getOption(info)
		local key = info[#info - 2]
		return self.db[unit].clickAttributes[key][info[#info]]
	end

	local function setOption(info, value)
		local key = info[#info - 2]
		self.db[unit].clickAttributes[key][info[#info]] = value
		GladiusEx:UpdateFrames()
	end

	return {
		type = "group",
		name = attribute,
		childGroups = "tree",
		order = order,
		args = {
			delete = {
				type = "execute",
				name = L["Delete click action"],
				func = function()
					-- remove from db
          if defaultClickAttributes[attribute] then
            -- do not set to `nil`, AceDB would merge with default and just re-add it later
            self.db[unit].clickAttributes[attribute] = true
          else
            self.db[unit].clickAttributes[attribute] = nil
          end

					-- remove from options
					options.attributeList.args[attribute] = nil

					-- update
					GladiusEx:UpdateFrames()
				end,
				disabled = function() return not self:IsUnitEnabled(unit) end,
				order = 1,
			},
			action = {
				type = "group",
				name = L["Action"],
				inline = true,
				get = getOption,
				set = setOption,
				order = 2,
				args = {
					action = {
						type = "select",
						name = L["Action"],
						desc = L["Select what this click action does"],
						values = {["macro"] = MACRO, ["target"] = TARGET, ["focus"] = FOCUS, ["spell"] = L["Cast spell"]},
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 10,
					},
					sep = {
						type = "description",
						name = "",
						width = "full",
						order = 15,
					},
					macro = {
						type = "input",
						multiline = true,
						name = L["Spell name / Macro text"],
						desc = L["Select what this click action does"],
						width = "double",
						disabled = function() return not self:IsUnitEnabled(unit) end,
						order = 20,
					},
				},
			},
		},
	}
end
