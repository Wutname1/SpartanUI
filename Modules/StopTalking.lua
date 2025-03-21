local SUI = SUI
if not SUI.IsRetail then
	return
end
---@class SUI.Module.StopTalking : SUI.Module
local module = SUI:NewModule("StopTalking")
local L = SUI.L
module.Displayname = L["Stop Talking"]
module.description = "Mutes the talking head frame once you have heard it."
----------------------------------------------------------------------------------------------------
local HeardLines = {}

function module:OnInitialize()
	---@class SUI.Module.StopTalking.DB
	local defaults = {
		persist = true,
		chatOutput = true,
		global = true,
		history = {},
		whitelist = {},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace("StopTalking", { profile = defaults, global = defaults })
	module.DB = module.Database.profile ---@type SUI.Module.StopTalking.DB
	module.DBGlobal = module.Database.global ---@type SUI.Module.StopTalking.DB
end

local function Options()
	---@type AceConfig.OptionsTable
	local optTable = {
		name = L["Stop Talking"],
		type = "group",
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		childGroups = "tab",
		args = {
			global = {
				name = L["Remember voice lines across all characters"],
				type = "toggle",
				order = 0.5,
				width = "full",
				get = function(info)
					return module.DBGlobal.global
				end,
				set = function(info, val)
					module.DBGlobal.global = val
				end,
			},
			persist = {
				name = L["Keep track of voice lines forever"],
				type = "toggle",
				order = 1,
				width = "full",
			},
			chatOutput = {
				name = L["Display heard voice lines in the chat."],
				type = "toggle",
				order = 2,
				width = "full",
			},
			Blacklist = {
				type = "group",
				name = "Blacklisted voice lines",
				order = 30,
				args = {
					items = {
						name = "",
						type = "multiselect",
						width = "full",
						order = 3,
						get = function(_, key)
							if module.DBGlobal.global then
								return (module.DBGlobal.history[key] and true) or false
							else
								return (module.DB.history[key] and true) or false
							end
						end,
						set = function(_, key, val)
							if module.DBGlobal.global then
								module.DBGlobal.history[key] = nil
							else
								module.DB.history[key] = nil
							end
						end,
						values = (module.DBGlobal.global and module.DBGlobal.history) or module.DB.history,
					},
				},
			},
			Whitelist = {
				type = "group",
				name = "Whitelisted voice lines",
				order = 40,
				args = {
					create = {
						name = "Add voice line",
						type = "input",
						order = 1,
						width = "full",
						set = function(info, input)
							if module.DBGlobal.global then
								module.DBGlobal.whitelist[input] = input
							else
								module.DB.whitelist[input] = input
							end
						end,
					},
					items = {
						name = L["Whitelisted voice lines"],
						type = "multiselect",
						width = "full",
						order = 2,
						get = function(_, key)
							if module.DBGlobal.global then
								return (module.DBGlobal.whitelist[key] and true) or false
							else
								return (module.DB.whitelist[key] and true) or false
							end
						end,
						set = function(_, key, val)
							if module.DBGlobal.global then
								module.DBGlobal.whitelist[key] = val
							else
								module.DB.whitelist[key] = val
							end
						end,
						values = (module.DBGlobal.global and module.DBGlobal.whitelist) or module.DB.whitelist,
					},
				},
			},
		},
	}

	SUI.Options:AddOptions(optTable, "Stop Talking", "Module")
end

function module:TALKINGHEAD_REQUESTED()
	if SUI:IsModuleDisabled(module) then
		TalkingHeadFrame:PlayCurrent()
		return
	end

	local _, _, vo, _, _, _, name, text = C_TalkingHead.GetCurrentLineInfo()
	if not vo then
		return
	end

	local persist = module.DB.persist
	local history = module.DBGlobal.global and module.DBGlobal.history or module.DB.history
	local whitelist = module.DBGlobal.global and module.DBGlobal.whitelist or module.DB.whitelist

	-- Check both persistent storage and session-based HeardLines
	if (persist and history[vo] and not whitelist[vo]) or (not persist and HeardLines[vo] and not whitelist[vo]) then
		-- Line has been heard before
		if module.DB.chatOutput and name and text then
			SUI:Print(name)
			print(text)
		end
		TalkingHeadFrame:CloseImmediately()
	else
		-- New line, play it and store it
		TalkingHeadFrame:PlayCurrent()
		if persist then
			history[vo] = name .. " - " .. text
		else
			HeardLines[vo] = name .. " - " .. text
		end
	end
end

function module:OnEnable()
	Options()
	if SUI:IsModuleDisabled(module) then
		return
	end

	--Import Globals if active
	if module.DBGlobal.global then
		for k, v in pairs(module.DB.history) do
			module.DBGlobal.history[k] = v
		end
		module.DB.history = {}
	end

	module:RegisterEvent("TALKINGHEAD_REQUESTED")
	TalkingHeadFrame:UnregisterEvent("TALKINGHEAD_REQUESTED")
end
