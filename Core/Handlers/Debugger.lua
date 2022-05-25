---@class SUI
local SUI = SUI
local StdUi = SUI.StdUi
local module = SUI:NewModule('Handler_Debugger')
module.description = 'Assists with debug information'
----------------------------------------------------------------------------------------------------
local DebugWindow = nil
local DebugMessages = {}

local function CreateDebugWindow()
	DebugWindow = StdUi:Window(nil, 500, 200, '|cffffffffSpartan|cffe21f1fUI Debug|r info')
	DebugWindow:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -5)
	DebugWindow.TextPanel = StdUi:MultiLineBox(DebugWindow, 480, 200, 'Start of debug...')
	StdUi:GlueAcross(DebugWindow.TextPanel, DebugWindow, 5, -30, -5, 5)
	DebugWindow:MakeResizable('BOTTOMRIGHT')
	-- StdUi:ObjectList(DebugWindow, nil, 'Button', nil, module.DB.modules)
	DebugWindow:Hide()
end

function SUI.Debug(debugText, comp)
	if not module.DB[comp] then
		module.DB[comp] = false
	end
	if not DebugMessages[comp] then
		DebugMessages[comp] = {}
	end

	table.insert(DebugMessages[comp], #DebugMessages[comp], tostring(debugText))
end

function module:OnInitialize()
	local defaults = {
		profile = {
			enable = false,
			modules = {}
		}
	}
	module.Database = SUI.SpartanUIDB:RegisterNamespace('Debugger', defaults)
	module.DB = module.Database.profile
end

function module:OnEnable()
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
end
