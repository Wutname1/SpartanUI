---@class SUI
local SUI = SUI
local StdUi = SUI.StdUi
local debugger = SUI:NewModule('Handler_Debugger')
debugger.description = 'Assists with debug information'
----------------------------------------------------------------------------------------------------
local DebugWindow = nil ---@type StdUi.Window
local DebugMessages = {}
local ScrollListing = {}
local ActiveModule = nil

local function ScrollItemUpdate(_, button, data)
	button:SetText(data.text)
	StdUi:SetObjSize(button, 60, 20)
	button:SetPoint('RIGHT')
	button:SetPoint('LEFT')
	button:HookScript(
		'OnClick',
		function(self)
			ActiveModule = self:GetText()
			DebugWindow.TextPanel:SetText('Start of log for ' .. ActiveModule)

			if ActiveModule and DebugMessages[ActiveModule] then
				for k, v in pairs(DebugMessages[ActiveModule]) do
					DebugWindow.TextPanel:SetText(DebugWindow.TextPanel:GetText() .. '\n' .. v)
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

	DebugWindow.OpenSettings = StdUi:Button(DebugWindow, 100, 20, 'Open Settings')
	DebugWindow.OpenSettings:SetPoint('TOPLEFT', DebugWindow, 5, -5)
	DebugWindow.OpenSettings:SetScript(
		'OnClick',
		function()
			SUI.Options:ToggleOptions({'Help', 'Debug'})
		end
	)

	local OutputSelect = StdUi:Panel(DebugWindow, 180, 200)
	OutputSelect:SetPoint('TOPLEFT', DebugWindow, 'TOPRIGHT', 5)
	OutputSelect:SetPoint('BOTTOMLEFT', DebugWindow, 'BOTTOMRIGHT', 5)

	local NamespaceListings = StdUi:FauxScrollFrame(OutputSelect, 160, 180, 15, 20)
	NamespaceListings:SetPoint('TOP', OutputSelect, 'TOP', 0, -10)
	NamespaceListings:SetPoint('BOTTOM', OutputSelect, 'BOTTOM', 0, 10)

	for moduleName, _ in pairs(debugger.DB.modules) do
		table.insert(ScrollListing, {text = (moduleName), value = moduleName})
	end
	DebugWindow.modules = debugger.DB.modules

	StdUi:ObjectList(NamespaceListings.scrollChild, DebugWindow.Modules, 'Button', ScrollItemUpdate, ScrollListing, 1, 0, 0)

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
		StdUi:ObjectList(DebugWindow.NamespaceListings.scrollChild, DebugWindow.Modules, 'Button', ScrollItemUpdate, ScrollListing, 1, 0, 0)
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
		DebugWindow.TextPanel:SetText(DebugWindow.TextPanel:GetText() .. '\n' .. tostring(debugText))
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
			if not val and debugger.DB.enable then
				debugger.DB.enable = false
			end
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
					for k, _ in pairs(debugger.DB.modules) do
						debugger.DB.modules[k] = val
					end
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
	SUI.Options:AddOptions(options, 'Debug', 'Help')
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

	if SUI:IsModuleEnabled('Module_Chatbox') then
		debugger:RegisterEvent('ADDON_LOADED')
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

local function RefreshData(self)
	local function OnMouseDown(line, button)
		local text = line.Text:GetText()
		if button == 'RightButton' then
			SUI.Chat:SetEditBoxMessage(text)
		elseif button == 'MiddleButton' then
			local rawData = line:GetParent():GetAttributeData().rawValue
			if rawData.IsObjectType and rawData:IsObjectType('Texture') then
				_G.TEX = rawData
				SUI:Print('_G.TEX set to: ', text)
			else
				_G.FRAME = rawData
				SUI:Print('_G.FRAME set to: ', text)
			end
		else
			TableAttributeDisplayValueButton_OnMouseDown(line)
		end
	end

	local scrollFrame = self.LinesScrollFrame or TableAttributeDisplay.LinesScrollFrame
	if not scrollFrame then
		return
	end
	for _, child in next, {scrollFrame.LinesContainer:GetChildren()} do
		if child.ValueButton and child.ValueButton:GetScript('OnMouseDown') ~= OnMouseDown then
			child.ValueButton:SetScript('OnMouseDown', OnMouseDown)
		end
	end
end

function debugger:ADDON_LOADED(_, addon)
	if addon == 'Blizzard_DebugTools' then
		hooksecurefunc(TableInspectorMixin, 'RefreshAllData', RefreshData)
		hooksecurefunc(TableAttributeDisplay.dataProviders[2], 'RefreshData', RefreshData)
		debugger:UnregisterEvent('ADDON_LOADED')
	end
end
