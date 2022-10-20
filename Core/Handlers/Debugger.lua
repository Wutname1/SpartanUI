---@class SUI
local SUI = SUI
local StdUi = SUI.StdUi
local debugger = SUI:NewModule('Handler_Debugger')
debugger.description = 'Assists with debug information'
----------------------------------------------------------------------------------------------------
local DebugWindow = nil
local DebugMessages = {}
local ScrollListing = {}
local ActiveModule = nil

local function ScrollItemUpdate(_, button, data)
	button:SetText(data.text)
	-- checkbox:SetValue(data.value)
	-- checkbox:SetChecked(true)
	StdUi:SetObjSize(button, 60, 20)
	button:SetPoint('RIGHT')
	button:SetPoint('LEFT')
	button:HookScript(
		'OnClick',
		function(self)
			ActiveModule = self:GetText()
			DebugWindow.TextPanel:SetValue('Start of log for ' .. ActiveModule)

			if ActiveModule and DebugMessages[ActiveModule] then
				for k, v in pairs(DebugMessages[ActiveModule]) do
					DebugWindow.TextPanel:SetValue(DebugWindow.TextPanel:GetValue() .. '\n' .. v)
				end
			end
		end
	)
	return button
end

local function CreateDebugWindow()
	if DebugWindow then
		return
	end

	DebugWindow = StdUi:Window(nil, 500, 200, '|cffffffffSpartan|cffe21f1fUI Debug|r info')
	DebugWindow:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -5)
	DebugWindow.TextPanel = StdUi:MultiLineBox(DebugWindow, 480, 200, 'No output active')
	StdUi:GlueAcross(DebugWindow.TextPanel, DebugWindow, 5, -30, -5, 5)
	DebugWindow:MakeResizable('BOTTOMRIGHT')
	DebugWindow:Hide()
	DebugWindow.Modules = {}

	local OutputSelect = StdUi:Panel(DebugWindow, 180, 200)
	OutputSelect:SetPoint('TOPLEFT', DebugWindow, 'TOPRIGHT', 5)
	OutputSelect:SetPoint('BOTTOMLEFT', DebugWindow, 'BOTTOMRIGHT', 5)

	local NamespaceListings = StdUi:FauxScrollFrame(OutputSelect, 160, 180, 15, 20)
	NamespaceListings:SetPoint('TOP', OutputSelect, 'TOP', 0, -10)
	NamespaceListings:SetPoint('BOTTOM', OutputSelect, 'BOTTOM', 0, 10)

	for moduleName, _ in pairs(DebugMessages) do
		table.insert(ScrollListing, {text = (moduleName), value = moduleName})
	end

	StdUi:ObjectList(
		NamespaceListings.scrollChild,
		DebugWindow.Modules,
		'Button',
		ScrollItemUpdate,
		ScrollListing,
		1,
		0,
		0
	)

	DebugWindow.NamespaceListings = NamespaceListings
	DebugWindow.OutputSelect = OutputSelect
end

function SUI.Debug(debugText, module)
	if not debugger.DB.enable then
		return
	elseif not DebugWindow then
		CreateDebugWindow()
	end
	if not DebugMessages[module] then
		DebugMessages[module] = {}
		table.insert(ScrollListing, {text = (module), value = module})
		StdUi:ObjectList(
			DebugWindow.NamespaceListings.scrollChild,
			DebugWindow.Modules,
			'Button',
			ScrollItemUpdate,
			ScrollListing,
			1,
			0,
			0
		)
		debugger.DB.modules[module] = debugger.DB.enable
		if debugger.options then
			debugger.options.args[module] = {
				name = module,
				type = 'toggle',
				order = (#debugger.options.args + 1)
			}
		end
	end
	if not debugger.DB.modules[module] then
		return
	end

	table.insert(DebugMessages[module], tostring(debugText))

	if ActiveModule and ActiveModule == module then
		DebugWindow.TextPanel:SetValue(DebugWindow.TextPanel:GetValue() .. '\n' .. tostring(debugText))
	end
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
	debugger.options = options
	SUI.Options:AddOptions(options, nil, 'Help')
end

function debugger:OnInitialize()
	local defaults = {
		enable = false,
		modules = {
			Core = false
		}
	}
	debugger.Database = SUI.SpartanUIDB:RegisterNamespace('Debugger', {profile = defaults})
	debugger.DB = debugger.Database.profile

	for k, _ in pairs(debugger.DB.modules) do
		DebugMessages[k] = {}
	end
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
	end

	SUI:AddChatCommand('debug', ToggleDebugWindow, 'Toggles the debug info window display')
	AddOptions()
end
