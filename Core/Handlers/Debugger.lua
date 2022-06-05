---@class SUI
local SUI = SUI
local StdUi = SUI.StdUi
local debugger = SUI:NewModule('Handler_Debugger')
debugger.description = 'Assists with debug information'
----------------------------------------------------------------------------------------------------
local DebugWindow = nil
local DebugMessages = {}

local function CreateDebugWindow()
	DebugWindow = StdUi:Window(nil, 500, 200, '|cffffffffSpartan|cffe21f1fUI Debug|r info')
	DebugWindow:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -5)
	DebugWindow.TextPanel = StdUi:MultiLineBox(DebugWindow, 480, 200, 'Start of debug...')
	StdUi:GlueAcross(DebugWindow.TextPanel, DebugWindow, 5, -30, -5, 5)
	DebugWindow:MakeResizable('BOTTOMRIGHT')
	DebugWindow:Hide()
end

function SUI.Debug(debugText, module)
	if not debugger.DB.modules[module] and not debugger.DB.All then
		debugger.DB.modules[module] = false
		return
	end
	if not DebugMessages[module] then
		DebugMessages[module] = {}
	end

	table.insert(DebugMessages[module], #DebugMessages[module], tostring(debugText))
	DebugWindow.TextPanel:SetValue(DebugWindow.TextPanel:GetValue() .. '\n[' .. module .. '] ' .. tostring(debugText))
end

function debugger:OnInitialize()
	local defaults = {
		profile = {
			enable = false,
			modules = {}
		}
	}
	debugger.Database = SUI.SpartanUIDB:RegisterNamespace('Debugger', defaults)
	debugger.DB = debugger.Database.profile
end

local function AddOptions()
	---@type AceConfigOptionsTable
	local options = {
		name = 'Debug',
		type = 'group',
		get = function(info)
			return debugger.DB.modules[info[#info]]
		end,
		set = function(info, val)
			debugger.DB.modules[info[#info]] = val
		end,
		args = {
			EnableAll = {
				name = 'Enable All',
				type = 'toggle',
				order = 0,
				get = function(info)
					return debugger.DB.enable
				end,
				set = function(info, val)
					debugger.DB.enable = val
				end
			}
		}
	}

	for k, _ in pairs(debugger.DB.modules) do
		options.args[k] = {
			name = k,
			type = 'toggle',
			order = (#options.args + 1)
		}
	end

	SUI.Options:AddOptions(options, nil, 'Help')
end

function debugger:OnEnable()
	CreateDebugWindow()

	local function ToggleDebugWindow(comp)
		if not DebugWindow then
			CreateDebugWindow()
		end
		if DebugWindow:IsVisible() then
			DebugWindow:Hide()
		else
			DebugWindow:Show()
		end
		DebugWindow.TextPanel:SetValue('')

		if comp then
			for k, v in pairs(DebugMessages[comp]) do
				DebugWindow.TextPanel:SetValue(DebugWindow.TextPanel:GetValue() .. '\n[' .. comp .. '] ' .. v)
			end
		end
	end

	SUI:AddChatCommand('debug', ToggleDebugWindow, 'Toggles the debug info window display')
	AddOptions()
end
