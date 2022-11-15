local SUI = SUI
if not SUI.IsRetail then
	return
end
local module = SUI:NewModule('Module_StopTalking') ---@type SUI.Module
local L = SUI.L
module.Displayname = L['Stop Talking']
module.description = 'Mutes the talking head frame once you have heard it.'
----------------------------------------------------------------------------------------------------
local HeardLines = {}

function module:OnInitialize()
	---@class SUI.StopTalking.DB
	local defaults = {
		persist = true,
		chatOutput = true,
		lines = {},
		history = {}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('StopTalking', {profile = defaults})
	module.DB = module.Database.profile ---@type SUI.StopTalking.DB
	module.DB.lines = {} --blank this out; start fresh in 10.0
end

local function Options()
	---@type AceConfigOptionsTable
	local optTable = {
		name = L['Stop Talking'],
		type = 'group',
		get = function(info)
			return module.DB[info[#info]]
		end,
		set = function(info, val)
			module.DB[info[#info]] = val
		end,
		args = {
			persist = {
				name = L['Keep track of voice lines forever'],
				type = 'toggle',
				order = 1,
				width = 'full'
			},
			chatOutput = {
				name = L['Display heard voice lines in the chat.'],
				type = 'toggle',
				order = 2,
				width = 'full'
			},
			lines = {
				name = L['Heard voice lines'],
				type = 'multiselect',
				desc = L['Uncheck a line to remove it from the history.'],
				width = 'full',
				order = 3,
				get = function(_, key)
					return (module.DB.history[key] and true) or false
				end,
				set = function(_, key, val)
					module.DB.history[key] = nil
				end,
				values = module.DB.history
			}
		}
	}

	SUI.Options:AddOptions(optTable, 'Stop Talking', 'Module')
end

function module:TALKINGHEAD_REQUESTED()
	local _, _, vo, _, _, _, name, text = C_TalkingHead.GetCurrentLineInfo()
	if not vo then
		return
	end

	local persist = module.DB.persist
	if (module.DB.history[vo] and persist) or (not persist and HeardLines[vo]) then
		-- Heard this before.
		if module.DB.chatOutput and name and text then
			SUI:Print(name)
			print(text)
		end

		return
	else
		-- New, flag it as heard.
		if persist then
			module.DB.history[vo] = name .. ' - ' .. text
		else
			HeardLines[vo] = name .. ' - ' .. text
		end
	end
end

function module:OnEnable()
	if SUI:IsModuleDisabled(module) then
		return
	end

	module:RegisterEvent('TALKINGHEAD_REQUESTED')
	Options()
end

function module:OnDisable()
	module:UnregisterEvent('TALKINGHEAD_REQUESTED')
end
