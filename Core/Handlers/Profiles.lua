local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local StdUi = SUI.StdUi
local module = SUI:NewModule('Handler_Profiles')
----------------------------------------------------------------------------------------------------
local window
local namespaceblacklist = {'LibDualSpec-1.0'}
local namespacelist = {{text = 'Full profile', value = 'full'}, {text = 'Core', value = 'core'}}

local function ResetWindow()
	window.Export:Hide()
	window.ProfileItems:Hide()
	window.namespaces:Hide()
	window.Import:Hide()
	window.textBox:SetValue('')
	window.importWin:Hide()

	if window.mode == 'export' then
		window.Export:Show()
		window.ProfileItems:Show()
		window.namespaces:Show()
	else
		window.Import:Show()
		window.textBox:SetValue('')
		window.importWin:Show()
	end

	window.Desc1:SetText(mode)
	window:Show()
end

local function CreateWindow()
	window = StdUi:Window(nil, 650, 500)
	window.StdUi = StdUi
	window.mode = 'init'
	window:SetPoint('CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')
	window.Title = StdUi:Texture(window, 156, 45, 'Interface\\AddOns\\SpartanUI\\images\\setup\\SUISetup')
	window.Title:SetTexCoord(0, 0.611328125, 0, 0.6640625)
	window.Title:SetPoint('TOP')
	window.Title:SetAlpha(.8)

	window.Desc1 = StdUi:Label(window, '', 13, nil, window:GetWidth())
	window.Desc1:SetPoint('TOP', window.titlePanel, 'BOTTOM', 0, -20)
	window.Desc1:SetTextColor(1, 1, 1, .8)
	window.Desc1:SetWidth(window:GetWidth() - 40)
	window.Desc1:SetJustifyH('CENTER')
	window.Desc1:SetText('')

	window.textBox = StdUi:MultiLineBox(window, 600, 350, '')
	window.textBox:SetPoint('TOP', window.Title, 'BOTTOM', 0, -25)
	window.textBox:SetPoint('BOTTOM', window, 'BOTTOM', 0, 25)

	-- Setup the Buttons
	window.SwitchMode = StdUi:Button(window, 150, 20, 'SWITCH MODE')
	window.SwitchMode:SetPoint('TOPLEFT', window, 'TOPLEFT', 2, -2)
	window.SwitchMode:SetScript(
		'OnClick',
		function(this)
			if window.mode == 'import' then
				window.mode = 'export'
			else
				window.mode = 'import'
			end

			ResetWindow()
		end
	)

	window.Export = StdUi:Button(window, 150, 20, 'EXPORT')
	window.Export:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -2, 2)
	window.Export:SetScript(
		'OnClick',
		function(this)
			local profileScope = window.namespaces:GetValue()
			local profileKey, profileExport = module:GetProfileExport(window.ProfileItems:GetValue(), profileScope)
			if not profileExport then
				window.Desc1:SetText('Error exporting profile!')
			else
				local a = format('%s: |cff00b3ff%s|r', 'Exported', window.namespaces:FindValueText(profileScope))
				local b = format('%s: |cff00b3ff%s|r', 'Profile Name', profileKey)

				window.Desc1:SetText(a)
				if profileScope == 'full' then
					window.Desc1:SetText(a .. ' ' .. b)
				end

				window.textBox:SetValue(profileExport)
				window.textBox.editBox:HighlightText()
				window.textBox.editBox:SetFocus()
			end
		end
	)

	window.Import = StdUi:Button(window, 150, 20, 'IMPORT')
	window.Import:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -2, 2)
	window.Import:SetScript(
		'OnClick',
		function(this)
			local profileScope = window.namespaces:GetValue()
			local profileImport = window.textBox:GetValue()
			if profileImport == '' then
				window.Desc1:SetText('Please enter a string to import')
			else
				module:ImportProfile(profileImport)
			end
		end
	)

	local items = {
		{text = L['Text'], value = 'text'},
		{text = L['Table'], value = 'luaTable'},
		{text = L['Plugin'], value = 'luaPlugin'}
	}
	window.ProfileItems = StdUi:Dropdown(window, 200, 20, items, 'luaTable')
	window.ProfileItems:SetPoint('BOTTOM', window, 'BOTTOM', 0, 2)

	for i, v in pairs(SpartanUIDB.namespaces) do
		if not SUI:isInTable(namespaceblacklist, i) then
			table.insert(namespacelist, {text = i, value = i})
		end
	end
	window.namespaces = StdUi:Dropdown(window, 200, 20, namespacelist, 'full')
	window.namespaces:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 2, 2)

	local importWin = StdUi:Window(nil, 200, window:GetHeight())
	importWin:SetPoint('LEFT', window, 'RIGHT', 2, 0)
	importWin:SetFrameStrata('DIALOG')

	importWin.Title = StdUi:Label(importWin, '', 13, nil, importWin:GetWidth())
	importWin.Title:SetPoint('TOP')
	importWin.Title:SetTextColor(1, 1, 1, .8)
	importWin.Title:SetWidth(importWin:GetWidth() - 40)
	importWin.Title:SetJustifyH('CENTER')
	importWin.Title:SetText('Import Settings')

	-- importWin.CurrentProfile = StdUi:Checkbox(importWin, 'Use current profile', 220, 20)
	-- importWin.NewProfile = StdUi:Checkbox(importWin, 'New Profile', 220, 20)
	-- importWin.NewProfileName = StdUi:SimpleEditBox(importWin, 300, 24, '')

	window.importWin = importWin
end

local function ImportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'import'
	ResetWindow()
end

local function ExportUI()
	if not window then
		CreateWindow()
	end
	window.mode = 'export'
	ResetWindow()
end

function module:OnInitialize()
end
function module:OnEnable()
	SUI:AddChatCommand('export', ExportUI)
	SUI:AddChatCommand('import', ImportUI)
end

local function GetProfileData(profileScope)
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
		if not profileScope or (profileScope == 'full' or profileScope == localScope) then
			return true
		end
		return false
	end

	local profileKey = SUI.SpartanUIDB:GetCurrentProfile()
	local profileData = {}

	-- profileKey = SpartanUIDB.profileKeys and SpartanUIDB.profileKeys[E.myname .. ' - ' .. E.myrealm]

	local namespaces = {}
	local blacklistedKeys = {}

	if inScope('core') then
		local data = SpartanUIDB.profiles[profileKey]
		local vars = SetCustomVars(data, namespaces)
		--Copy current profile data
		local core = SUI:CopyTable({}, SUI.DB)
		--Compare against the defaults and remove all duplicates
		core = SUI:RemoveTableDuplicates(SUI.DB, SUI.DBdefault, vars)
		core = SUI:FilterTableFromBlacklist(core, blacklistedKeys)
		profileData.core = core
	end

	for name, datatable in pairs(SpartanUIDB.namespaces) do
		if inScope(name) and datatable.profiles and datatable.profiles[profileKey] then
			--Copy current profile data
			local data = SUI:CopyTable({}, datatable.profiles[profileKey])
			--Compare against the defaults and remove all duplicates
			local namespaceData = SUI.SpartanUIDB:GetNamespace(name).defaults.profile
			data = SUI:RemoveTableDuplicates(data, namespaceData, vars)

			profileData[name] = data
		end
	end

	return profileKey, profileData
end

function module:GetProfileExport(exportFormat, profileScope)
	local profileExport, exportString
	local profileKey, profileData = GetProfileData(profileScope)

	if not profileKey or not profileData or (profileData and type(profileData) ~= 'table') then
		print('Error getting data from "GetProfileData"')
		return
	end

	if exportFormat == 'text' then
		local serialData = SUI:Serialize(profileData)
		exportString = module:CreateProfileExport(serialData, profileScope, profileKey)
		local compressedData = Lib.Compress:Compress(exportString)
		local encodedData = Lib.Base64:Encode(compressedData)
		profileExport = encodedData
	elseif exportFormat == 'luaTable' then
		exportString = SUI:TableToLuaString(profileData)
		profileExport = module:CreateProfileExport(exportString, profileScope, profileKey)
	elseif exportFormat == 'luaPlugin' then
		profileExport = SUI:ProfileTableToPluginFormat(profileData, profileScope)
	end

	return profileKey, profileExport
end

function module:CreateProfileExport(dataString, profileScope, profileKey)
	local returnString

	if profileScope == 'full' then
		returnString = format('%s::%s::%s', dataString, profileScope, profileKey)
	else
		returnString = format('%s::%s', dataString, profileScope)
	end

	return returnString
end

local function GetImportStringType(dataString)
	local stringType = ''

	if Lib.Base64:IsBase64(dataString) then
		stringType = 'Base64'
	elseif strfind(dataString, '{') then --Basic check to weed out obviously wrong strings
		stringType = 'Table'
	end

	return stringType
end

function module:Decode(dataString)
	local profileInfo, profileType, profileKey, profileData
	local stringType = GetImportStringType(dataString)

	if stringType == 'Base64' then
		local decodedData = Lib.Base64:Decode(dataString)
		local decompressedData, decompressedMessage = Lib.Compress:Decompress(decodedData)

		if not decompressedData then
			SUI:Print('Error decompressing data:', decompressedMessage)
			return
		end

		local serializedData, success
		serializedData, profileInfo = SUI:SplitString(decompressedData, '^^::') -- '^^' indicates the end of the AceSerializer string

		if not profileInfo then
			SUI:Print('Error importing profile. String is invalid or corrupted!')
			return
		end

		serializedData = format('%s%s', serializedData, '^^') --Add back the AceSerializer terminator
		profileType, profileKey = SUI:SplitString(profileInfo, '::')
		success, profileData = SUI:Deserialize(serializedData)

		if not success then
			SUI:Print('Error deserializing:', profileData)
			return
		end
	elseif stringType == 'Table' then
		local profileDataAsString
		profileDataAsString, profileInfo = SUI:SplitString(dataString, '}::') -- '}::' indicates the end of the table

		if not profileInfo then
			SUI:Print('Error extracting profile info. Invalid import string!')
			return
		end

		if not profileDataAsString then
			SUI:Print('Error extracting profile data. Invalid import string!')
			return
		end

		profileDataAsString = format('%s%s', profileDataAsString, '}') --Add back the missing '}'
		profileDataAsString = gsub(profileDataAsString, '\124\124', '\124') --Remove escape pipe characters
		profileType, profileKey = SUI:SplitString(profileInfo, '::')

		local profileMessage
		local profileToTable = loadstring(format('%s %s', 'return', profileDataAsString))
		if profileToTable then
			profileMessage, profileData = pcall(profileToTable)
		end

		if profileMessage and (not profileData or type(profileData) ~= 'table') then
			SUI:Print('Error converting lua string to tablSUI:', profileMessage)
			return
		end
	end

	return profileType, profileKey, profileData
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
	local module = SUI:GetModule('Component_' .. ModuleName)
	local newsettings = PrepareImport(module.Database.defaults.profile, NewSettings)

	module.DB = SUI:MergeData(module.DB, newsettings, true)
	-- Trigger a update for the module if the module has an updater
	-- If module needs reloadui it can call SUI:reloadui in the update call
	if module.update then
		module:update()
	end
end

function module:ImportProfile(dataString)
	local profileScope, profileKey, profileData = module:Decode(dataString)

	-- local CurProfile = SUI.SpartanUIDB:GetCurrentProfile()
	-- SUI.SpartanUIDB:SetProfile(CurProfile)
	if profileScope == 'full' then
		for k, v in pairs(profileData) do
			if k == 'core' then
				ImportCoreSettings(v)
				SUI:reloadui()
			else
				ImportModuleSettings(k, v)
			end
		end
	elseif profileScope == 'core' then
		ImportCoreSettings(v)
		SUI:reloadui()
	else
		ImportModuleSettings(profileScope, profileData[profileScope])
	end
end
