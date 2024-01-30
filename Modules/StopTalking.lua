local SUI = SUI
if not SUI.IsRetail then return end
---@class SUI.Module.StopTalking : SUI.Module
local module = SUI:NewModule('Module_StopTalking')
local L = SUI.L
module.Displayname = L['Stop Talking']
module.description = 'Mutes the talking head frame once you have heard it.'
----------------------------------------------------------------------------------------------------
local HeardLines = {}

function module:OnInitialize()
	---@class SUI.Module.StopTalking.DB
	local defaults = {
		persist = true,
		chatOutput = true,
		global = true,
		history = {},
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StopTalking', { profile = defaults, global = defaults })
	module.DB = module.Database.profile ---@type SUI.Module.StopTalking.DB
	module.DBGlobal = module.Database.global ---@type SUI.Module.StopTalking.DB

	--blank this out; start fresh in 10.0
	if module.DB.lines then module.DB.lines = nil end
end

local function Options()
	---@type AceConfig.OptionsTable
	local optTable = {
		name = L['Stop Talking'],
		type = 'group',
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		disabled = function()
			return SUI:IsModuleDisabled(module)
		end,
		args = {
			global = {
				name = L['Remember voice lines across all characters'],
				type = 'toggle',
				order = 0.5,
				width = 'full',
				get = function(info)
					return module.DBGlobal.global
				end,
				set = function(info, val)
					module.DBGlobal.global = val
				end,
			},
			persist = {
				name = L['Keep track of voice lines forever'],
				type = 'toggle',
				order = 1,
				width = 'full',
			},
			chatOutput = {
				name = L['Display heard voice lines in the chat.'],
				type = 'toggle',
				order = 2,
				width = 'full',
			},
			lines = {
				name = L['Heard voice lines'],
				type = 'multiselect',
				desc = L['Uncheck a line to remove it from the history.'],
				width = 'full',
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
	}

	SUI.Options:AddOptions(optTable, 'Stop Talking', 'Module')
end

function module:TALKINGHEAD_REQUESTED()
	if SUI:IsModuleDisabled(module) then
		TalkingHeadFrame:PlayCurrent()
		return
	end

	local _, _, vo, _, _, _, name, text = C_TalkingHead.GetCurrentLineInfo()
	if not vo then return end

	local persist = module.DB.persist
	if (module.DB.history[vo] and persist) or (not persist and HeardLines[vo]) or (module.DBGlobal.global and module.DBGlobal.history[vo]) then
		-- Heard this before.
		if module.DB.chatOutput and name and text then
			SUI:Print(name)
			print(text)
		end

		return
	else
		TalkingHeadFrame:PlayCurrent()
		-- New, flag it as heard.
		if persist then
			if module.DBGlobal.global then
				module.DBGlobal.history[vo] = name .. ' - ' .. text
			else
				module.DB.history[vo] = name .. ' - ' .. text
			end
		else
			HeardLines[vo] = name .. ' - ' .. text
		end
	end
end

function module:OnEnable()
	Options()
	if SUI:IsModuleDisabled(module) then return end

	--Import Globals if active
	if module.DBGlobal.global then
		for k, v in pairs(module.DB.history) do
			module.DBGlobal.history[k] = v
		end
		module.DB.history = {}
	end

	module:RegisterEvent('TALKINGHEAD_REQUESTED')
	TalkingHeadFrame:UnregisterEvent('TALKINGHEAD_REQUESTED')
end
