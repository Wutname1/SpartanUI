local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local StdUi = SUI.StdUi
local module = SUI:NewModule('Handler_Profiles')
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
	window = StdUi:Window(nil, 650, 500)
	window.StdUi = StdUi
	window.mode = 'init'
	window:SetPoint('CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')
	window:SetFrameLevel(10)
	window.Title = StdUi:Texture(window, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	window.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	window.Title:SetPoint('TOP')
	window.Title:SetAlpha(.8)

	window.Desc1 = StdUi:Label(window, '', 13, nil, window:GetWidth())
	window.Desc1:SetPoint('TOP', window.Title, 'BOTTOM', 0, -5)
	window.Desc1:SetTextColor(1, 1, 1, .8)
	window.Desc1:SetWidth(window:GetWidth() - 40)
	window.Desc1:SetJustifyH('CENTER')
	window.Desc1:SetText('')

	window.textBox = StdUi:MultiLineBox(window, window:GetWidth() - 10, 350, '')
	window.textBox:SetPoint('TOP', window.Desc1, 'BOTTOM', 0, -5)
	window.textBox:SetPoint('BOTTOM', window, 'BOTTOM', 0, 5)

	-- Setup the Options Pane
	local OptWidth = 194 -- Will be created 4 larger than this value

	local optionPane = StdUi:Window(nil, OptWidth + 4, window:GetHeight())
	optionPane:SetPoint('LEFT', window, 'RIGHT', 1, 0)
	optionPane:SetFrameStrata('DIALOG')
	window:HookScript(
		'OnHide',
		function()
			optionPane:Hide()
		end
	)
	optionPane.closeBtn:Hide()

	optionPane.Title = StdUi:Label(optionPane, '', 13, nil, OptWidth)
	optionPane.Title:SetTextColor(1, 1, 1, .8)
	optionPane.Title:SetJustifyH('CENTER')
	optionPane.Title:SetText('Import settings')
	optionPane.Title:SetPoint('TOP', 0, -2)

	optionPane.SwitchMode = StdUi:Button(optionPane, OptWidth, 20, 'SWITCH MODE')
	optionPane.SwitchMode:SetPoint('BOTTOM', optionPane, 0, 24)
	optionPane.SwitchMode:SetScript(
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

	--------------------------------
	-------- EXPORT STUFF ----------
	local exportOpt = CreateFrame('Frame', nil)
	exportOpt:SetParent(optionPane)
	exportOpt:SetPoint('TOPLEFT', optionPane, 3, -25)
	exportOpt:SetPoint('BOTTOMRIGHT', -3, 3)

	exportOpt.formatExportText = StdUi:Radio(exportOpt, 'Text', 'exportFormat', OptWidth, 20)
	exportOpt.formatExportText:SetValue('text')
	exportOpt.formatExportText:SetPoint('TOP')

	exportOpt.formatExportTable = StdUi:Radio(exportOpt, 'Table', 'exportFormat', OptWidth, 20)
	exportOpt.formatExportTable:SetValue('luaTable')
	exportOpt.formatExportTable:SetPoint('TOP', exportOpt.formatExportText, 'BOTTOM', 0, -2)

	StdUi:SetRadioGroupValue('exportFormat', 'luaTable')

	exportOpt.AllNamespaces = StdUi:Checkbox(exportOpt, 'All', OptWidth, 20)
	exportOpt.AllNamespaces:SetPoint('TOP', exportOpt.formatExportTable, 'BOTTOM', 0, -20)
	exportOpt.AllNamespaces:SetChecked(true)
	exportOpt.AllNamespaces:HookScript(
		'OnClick',
		function(self)
			for _, v in ipairs(exportOpt.items) do
				v:SetChecked(self:GetChecked())
			end
		end
	)

	local NamespaceListings = StdUi:FauxScrollFrame(exportOpt, OptWidth, 300, 15, 20)
	NamespaceListings:SetPoint('TOP', exportOpt.AllNamespaces, 'BOTTOM', 0, -2)

	exportOpt.items = {}
	local list = {}
	table.insert(list, {text = 'Core', value = 'core'})
	for i, _ in pairs(SpartanUIDB.namespaces) do
		if not SUI:isInTable(namespaceblacklist, i) then
			local DisplayName
			local tmpModule = SUI:GetModule('Component_' .. i, true)
			if tmpModule and tmpModule.DisplayName then
				DisplayName = tmpModule.DisplayName
			end

			table.insert(list, {text = (DisplayName or i), value = i})
		end
	end

	local function update(_, checkbox, data)
		checkbox:SetText(data.text)
		checkbox:SetValue(data.value)
		checkbox:SetChecked(true)
		StdUi:SetObjSize(checkbox, 60, 20)
		checkbox:SetPoint('RIGHT')
		checkbox:SetPoint('LEFT')
		checkbox:HookScript(
			'OnClick',
			function(self)
				if not self:GetChecked() then
					exportOpt.AllNamespaces:SetChecked(false)
				end
			end
		)
		return checkbox
	end

	StdUi:ObjectList(NamespaceListings.scrollChild, exportOpt.items, 'Checkbox', update, list, 1, 0, 0)
	exportOpt.NamespaceListings = NamespaceListings

	exportOpt.Export = StdUi:Button(exportOpt, OptWidth, 20, 'EXPORT')
	exportOpt.Export:SetPoint('BOTTOM')
	exportOpt.Export:SetScript(
		'OnClick',
		function()
			local ExportScopes = {}
			for _, v in ipairs(exportOpt.items) do
				if v:GetChecked() then
					ExportScopes[v:GetValue()] = {}
				end
			end

			local profileExport = module:ExportProfile(StdUi:GetRadioGroupValue('exportFormat'), ExportScopes)

			if not profileExport then
				window.Desc1:SetText('Error exporting profile!')
			else
				window.Desc1:SetText('Exported!')

				window.textBox:SetValue(profileExport)
				window.textBox.editBox:HighlightText()
				window.textBox.editBox:SetFocus()
			end
		end
	)

	--------------------------------
	-------- IMPORT STUFF ----------
	local importOpt = CreateFrame('Frame', nil)
	importOpt:SetParent(optionPane)
	importOpt:SetPoint('TOPLEFT', optionPane, 3, -25)
	importOpt:SetPoint('BOTTOMRIGHT', -3, 3)

	importOpt.CurrentProfile = StdUi:Radio(importOpt, 'Use current profile', 'importTo', OptWidth, 20)
	importOpt.CurrentProfile:SetValue('current')
	importOpt.CurrentProfile:SetPoint('TOP')

	importOpt.NewProfile = StdUi:Radio(importOpt, 'New Profile', 'importTo', OptWidth, 20)
	importOpt.NewProfile:SetValue('new')
	importOpt.NewProfile:SetPoint('TOP', importOpt.CurrentProfile, 'BOTTOM', 0, -2)

	importOpt.NewProfileName = StdUi:SimpleEditBox(importOpt, OptWidth, 20, '')
	importOpt.NewProfileName:SetPoint('TOP', importOpt.NewProfile, 'BOTTOM', 0, -2)

	StdUi:OnRadioGroupValueChanged(
		'importTo',
		function(v)
			importOpt.NewProfileName:SetText('')
			if v == 'new' then
				importOpt.NewProfileName:Enable()
			else
				importOpt.NewProfileName:Disable()
			end
		end
	)
	StdUi:SetRadioGroupValue('importTo', 'current')

	importOpt.Import = StdUi:Button(importOpt, OptWidth, 20, 'IMPORT')
	importOpt.Import:SetPoint('BOTTOM')
	importOpt.Import:SetScript(
		'OnClick',
		function()
			if StdUi:GetRadioGroupValue('importTo') == 'new' then
				local profileName = importOpt.NewProfileName:GetText()
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
			local namespaceData = SUI.SpartanUIDB:GetNamespace(name).defaults.profile
			data = SUI:RemoveTableDuplicates(data, namespaceData, vars)

			profileData[name] = data
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
	local module = SUI:GetModule('Component_' .. ModuleName, true) or SUI:GetModule('Handler_' .. ModuleName, true)
	if not module then
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

	return true
end
