local SUI, L, Lib = SUI, SUI.L, SUI.Lib
---@class SUI.Handler.Profiles : SUI.Module
local module = SUI:NewModule('Handler.Profiles')
----------------------------------------------------------------------------------------------------
local window
local namespaceblacklist = {'LibDualSpec-1.0'}

local function ResetWindow()
	window.textBox:SetValue('')
	window.optionPane.exportOpt:Hide()
	window.optionPane.importOpt:Hide()

	if window.mode == 'export' then
		window.optionPane.Title:SetText('Export settings')
		window.optionPane.exportOpt:Show()
	else
		window.optionPane.Title:SetText('Import settings')
		window.optionPane.importOpt:Show()
	end

	window:Show()
	window.optionPane:Show()
end

local function CreateWindow()
	local UI = LibAT.UI
	window = UI.CreateWindow({
		name = 'SUI_ProfileManager',
		title = '',
		width = 650,
		height = 500,
		hidePortrait = true,
	})
	window.mode = 'init'
	window:SetPoint('CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')
	window:SetFrameLevel(10)

	-- SUI Logo
	local logo = window:CreateTexture(nil, 'ARTWORK')
	logo:SetTexture('Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	logo:SetSize(156, 45)
	logo:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	logo:SetPoint('TOP', window, 'TOP', 0, -35)
	logo:SetAlpha(0.8)

	-- Description label
	local desc1 = UI.CreateLabel(window, '', 'GameFontHighlight')
	desc1:SetPoint('TOP', logo, 'BOTTOM', 0, -5)
	desc1:SetTextColor(1, 1, 1, 0.8)
	desc1:SetWidth(610)
	desc1:SetJustifyH('CENTER')
	desc1:SetText('')
	window.Desc1 = desc1

	-- Large multiline text box for import/export
	window.textBox = UI.CreateMultiLineBox(window, 640, 350, '')
	window.textBox:SetPoint('TOP', desc1, 'BOTTOM', 0, -5)
	window.textBox:SetPoint('BOTTOM', window, 'BOTTOM', 0, 5)

	-- Setup the Options Pane
	local OptWidth = 194

	local optionPane = UI.CreateWindow({
		name = 'SUI_ProfileManager_Options',
		title = '',
		width = OptWidth + 4,
		height = 500,
		hidePortrait = true,
	})
	optionPane:SetPoint('LEFT', window, 'RIGHT', 1, 0)
	optionPane:SetFrameStrata('DIALOG')
	window:HookScript(
		'OnHide',
		function()
			optionPane:Hide()
		end
	)
	optionPane.closeBtn:Hide()

	-- Title label
	local optTitle = UI.CreateLabel(optionPane, 'Import settings', 'GameFontHighlight')
	optTitle:SetTextColor(1, 1, 1, 0.8)
	optTitle:SetWidth(OptWidth)
	optTitle:SetJustifyH('CENTER')
	optTitle:SetPoint('TOP', optionPane, 'TOP', 0, -35)
	optionPane.Title = optTitle

	-- Switch Mode button at bottom
	local switchBtn = UI.CreateButton(optionPane, OptWidth, 20, 'SWITCH MODE')
	switchBtn:SetPoint('BOTTOM', optionPane, 'BOTTOM', 0, 24)
	switchBtn:SetScript(
		'OnClick',
		function()
			if window.mode == 'import' then
				window.mode = 'export'
			else
				window.mode = 'import'
			end

			ResetWindow()
		end
	)
	optionPane.SwitchMode = switchBtn

	--------------------------------
	-------- EXPORT STUFF ----------
	local exportOpt = CreateFrame('Frame', nil)
	exportOpt:SetParent(optionPane)
	exportOpt:SetPoint('TOPLEFT', optionPane, 3, -60)
	exportOpt:SetPoint('BOTTOMRIGHT', -3, 48)

	-- Radio buttons for export format
	local formatText = UI.CreateRadio(exportOpt, 'Text', 'exportFormat', OptWidth, 20)
	formatText:SetValue('text')
	formatText:SetPoint('TOP', exportOpt, 'TOP', 0, 0)
	exportOpt.formatExportText = formatText

	local formatTable = UI.CreateRadio(exportOpt, 'Table', 'exportFormat', OptWidth, 20)
	formatTable:SetValue('luaTable')
	formatTable:SetPoint('TOP', formatText, 'BOTTOM', 0, -2)
	exportOpt.formatExportTable = formatTable

	UI.SetRadioGroupValue('exportFormat', 'text')

	-- "All" checkbox for namespace selection
	local allCheck = UI.CreateCheckbox(exportOpt, 'All')
	allCheck:SetPoint('TOP', formatTable, 'BOTTOM', 0, -20)
	allCheck:SetChecked(true)
	allCheck:HookScript(
		'OnClick',
		function(self)
			for _, v in ipairs(exportOpt.items) do
				v:SetChecked(self:GetChecked())
			end
		end
	)
	exportOpt.AllNamespaces = allCheck

	-- Scrollable namespace checkbox list
	local scrollFrame = UI.CreateScrollFrame(exportOpt)
	scrollFrame:SetPoint('TOP', allCheck, 'BOTTOM', 0, -2)
	scrollFrame:SetPoint('LEFT', exportOpt, 'LEFT', 0, 0)
	scrollFrame:SetPoint('RIGHT', exportOpt, 'RIGHT', 0, 0)
	scrollFrame:SetPoint('BOTTOM', exportOpt, 'BOTTOM', 0, 30)

	local scrollChild = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetSize(OptWidth, 1)

	-- Create namespace list
	exportOpt.items = {}
	local list = {}
	table.insert(list, {text = 'Core', value = 'core'})
	for i, _ in pairs(SpartanUIDB.namespaces) do
		if not SUI:IsInTable(namespaceblacklist, i) then
			local DisplayName
			local tmpModule = SUI:GetModule(i, true)
			if tmpModule then
				DisplayName = tmpModule.DisplayName or i
				table.insert(list, {text = (DisplayName or i), value = i})
			end
		end
	end

	-- Create checkboxes dynamically
	local yOffset = 0
	for _, data in ipairs(list) do
		local checkbox = UI.CreateCheckbox(scrollChild, data.text)
		checkbox:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, yOffset)
		checkbox:SetChecked(true)
		checkbox.value = data.value

		-- Add GetValue method for compatibility
		function checkbox:GetValue()
			return self.value
		end

		checkbox:HookScript(
			'OnClick',
			function(self)
				if not self:GetChecked() then
					allCheck:SetChecked(false)
				end
			end
		)

		table.insert(exportOpt.items, checkbox)
		yOffset = yOffset - 22
	end
	scrollChild:SetHeight(math.abs(yOffset))

	exportOpt.NamespaceListings = scrollFrame

	-- Export button
	local exportBtn = UI.CreateButton(exportOpt, OptWidth, 20, 'EXPORT')
	exportBtn:SetPoint('BOTTOM', exportOpt, 'BOTTOM', 0, 0)
	exportBtn:SetScript(
		'OnClick',
		function()
			local ExportScopes = {}
			for _, v in ipairs(exportOpt.items) do
				if v:GetChecked() then
					ExportScopes[v:GetValue()] = {}
				end
			end

			local profileExport = module:ExportProfile(UI.GetRadioGroupValue('exportFormat'), ExportScopes)

			if not profileExport then
				window.Desc1:SetText('Error exporting profile!')
			else
				window.Desc1:SetText('Exported!')

				window.textBox:SetValue(profileExport)
				window.textBox:HighlightText()
				window.textBox:SetFocus()
			end
		end
	)
	exportOpt.Export = exportBtn

	--------------------------------
	-------- IMPORT STUFF ----------
	local importOpt = CreateFrame('Frame', nil)
	importOpt:SetParent(optionPane)
	importOpt:SetPoint('TOPLEFT', optionPane, 3, -60)
	importOpt:SetPoint('BOTTOMRIGHT', -3, 48)

	-- Radio buttons for import target
	local currentProfile = UI.CreateRadio(importOpt, 'Use current profile', 'importTo', OptWidth, 20)
	currentProfile:SetValue('current')
	currentProfile:SetPoint('TOP', importOpt, 'TOP', 0, 0)
	importOpt.CurrentProfile = currentProfile

	local newProfile = UI.CreateRadio(importOpt, 'New Profile', 'importTo', OptWidth, 20)
	newProfile:SetValue('new')
	newProfile:SetPoint('TOP', currentProfile, 'BOTTOM', 0, -2)
	importOpt.NewProfile = newProfile

	-- New profile name edit box
	local profileNameBox = UI.CreateEditBox(importOpt, OptWidth, 20)
	profileNameBox:SetPoint('TOP', newProfile, 'BOTTOM', 0, -2)
	importOpt.NewProfileName = profileNameBox

	-- Radio group change handler
	UI.OnRadioGroupValueChanged(
		'importTo',
		function(v)
			profileNameBox:SetText('')
			if v == 'new' then
				profileNameBox:Enable()
			else
				profileNameBox:Disable()
			end
		end
	)
	UI.SetRadioGroupValue('importTo', 'current')

	-- Import button
	local importBtn = UI.CreateButton(importOpt, OptWidth, 20, 'IMPORT')
	importBtn:SetPoint('BOTTOM', importOpt, 'BOTTOM', 0, 0)
	importBtn:SetScript(
		'OnClick',
		function()
			if UI.GetRadioGroupValue('importTo') == 'new' then
				local profileName = profileNameBox:GetText()
				if profileName == '' then
					window.Desc1:SetText('Please enter a new profile name')
					return
				end
				SUI.SpartanUIDB:SetProfile(profileName)
			end

			local profileImport = window.textBox:GetValue()
			if profileImport == '' then
				window.Desc1:SetText('Please enter a string to import')
			else
				module:ImportProfile(profileImport)
				window.Desc1:SetText('Settings imported!')
			end
		end
	)
	importOpt.Import = importBtn

	optionPane.exportOpt = exportOpt
	optionPane.importOpt = importOpt
	window.optionPane = optionPane
end

function module:ImportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'import'
	ResetWindow()
end

function module:ExportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'export'
	ResetWindow()
end

function module:OnEnable()
	SUI:AddChatCommand('export', module.ExportUI, 'Export your settings')
	SUI:AddChatCommand('import', module.ImportUI, 'Import settings')
end

-------- EXPORT STUFF ----------

local function GetProfileData(ScopeTable)
	local function SetCustomVars(data, keys)
		if not data then
			return
		end

		local vars = SUI:CopyTable({}, keys)
		for key in pairs(data) do
			if type(key) ~= 'table' then
				vars[key] = true
			end
		end

		return vars
	end
	local function inScope(localScope)
		if ScopeTable and ScopeTable[localScope] ~= nil then
			return true
		end
		return false
	end

	local profile = SUI.SpartanUIDB:GetCurrentProfile()
	local profileData = {}

	local namespaces = {}
	local blacklistedKeys = {}

	if inScope('core') then
		local data = SpartanUIDB.profiles[profile]
		local vars = SetCustomVars(data, namespaces)
		--Copy current profile data
		local core = SUI:CopyTable({}, SUI.DB)
		--Compare against the defaults and remove all duplicates
		core = SUI:RemoveTableDuplicates(SUI.DB, SUI.DBdefault, vars)
		core = SUI:FilterTableFromBlacklist(core, blacklistedKeys)
		profileData.core = core
	end

	for name, datatable in pairs(SpartanUIDB.namespaces) do
		if inScope(name) and datatable.profiles and datatable.profiles[profile] then
			--Copy current profile data
			local data = SUI:CopyTable({}, datatable.profiles[profile])
			--Compare against the defaults and remove all duplicates
			local namespace = SUI.SpartanUIDB:GetNamespace(name, true)
			if namespace then
				local namespaceData = namespace.defaults.profile
				data = SUI:RemoveTableDuplicates(data, namespaceData)

				profileData[name] = data
			end
		end
	end

	return profileData
end

function module:ExportProfile(exportFormat, ScopeTable)
	local profileExport
	local profileData = GetProfileData(ScopeTable)

	if not profileData or (profileData and type(profileData) ~= 'table') then
		print('Error getting data from "GetProfileData"')
		return
	end

	if exportFormat == 'text' then
		local serialData = SUI:Serialize(profileData)
		local compressedData = Lib.Compress:Compress(serialData)
		local encodedData = Lib.Base64:Encode(compressedData)
		profileExport = encodedData
	elseif exportFormat == 'luaTable' then
		profileExport = SUI:TableToLuaString(profileData)
	end

	return profileExport
end

-------- IMPORT STUFF ----------

local function GetImportStringType(dataString)
	local stringType = ''

	if Lib.Base64:IsBase64(dataString) then
		stringType = 'Base64'
	elseif strfind(dataString, '{') then --Basic check to weed out obviously wrong strings
		stringType = 'Table'
	end

	return stringType
end

local function DecodeImportInput(dataString)
	local profileData
	local stringType = GetImportStringType(dataString)

	if stringType == 'Base64' then
		local decodedData = Lib.Base64:Decode(dataString)
		local decompressedData, decompressedMessage = Lib.Compress:Decompress(decodedData)

		if not decompressedData then
			SUI:Print('Error decompressing data:', decompressedMessage)
			return
		end

		local success
		success, profileData = SUI:Deserialize(decompressedData)

		if not success then
			SUI:Print('Error deserializing:', profileData)
			return
		end
	elseif stringType == 'Table' then
		local profileDataAsString = gsub(dataString, '\124\124', '\124') --Remove escape pipe characters
		local profileMessage
		local profileToTable = loadstring(format('%s %s', 'return', profileDataAsString))
		if profileToTable then
			profileMessage, profileData = pcall(profileToTable)
		end

		if profileMessage and (not profileData or type(profileData) ~= 'table') then
			SUI:Print('Error converting lua string to table:', profileMessage)
			return
		end
	end

	return profileData
end

local function PrepareImport(defaults, importData)
	local newData = SUI:CopyTable({}, defaults)
	newData = SUI:CopyTable(newData, importData)

	return newData
end

local function ImportCoreSettings(importData)
	local newsettings = PrepareImport(SUI.SpartanUIDB.defaults.profile, importData)
	SUI.DB = SUI:MergeData(SUI.DB, newsettings, true)
end

local function ImportModuleSettings(ModuleName, NewSettings)
	local module = SUI:GetModule(ModuleName, true) or SUI:GetModule('Handler.' .. ModuleName, true)
	if not module or not module.Database then
		return
	end
	local newsettings = PrepareImport(module.Database.defaults.profile, NewSettings)

	module.DB = SUI:MergeData(module.DB, newsettings, true)
	-- Trigger a update for the module if the module has an updater
	-- If module needs reloadui it can call SUI:reloadui in the update call
	if module.update then
		module:update()
	end
end

function module:ImportProfile(dataString)
	local profileData = DecodeImportInput(dataString)

	-- local CurProfile = SUI.SpartanUIDB:GetCurrentProfile()
	-- SUI.SpartanUIDB:SetProfile(CurProfile)
	for k, v in pairs(profileData) do
		if k == 'core' then
			ImportCoreSettings(v)
			SUI:reloadui()
		else
			ImportModuleSettings(k, v)
		end
	end

	window.textBox:SetValue(SUI:TableToLuaString(profileData))

	return true
end
