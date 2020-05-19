
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
		if not profileScope or (profileScope == 'all' or profileScope == localScope) then
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
		core = SUI:RemoveTableDuplicates(SUI.DB, DBdefault, vars)
		core = SUI:FilterTableFromBlacklist(core, blacklistedKeys)
		profileData.core = core
	end

	for name, datatable in pairs(SpartanUIDB.namespaces) do
		if inScope(name) and datatable.profiles and datatable.profiles[profileKey] then
			profileData[name] = datatable.profiles[profileKey]
		end
	end

	return profileKey, profileData
end

local function GetProfileExport(exportFormat, profileScope)
	local profileExport, exportString
	local profileKey, profileData = GetProfileData(profileScope)

	if not profileKey or not profileData or (profileData and type(profileData) ~= 'table') then
		print('Error getting data from "GetProfileData"')
		return
	end

	if exportFormat == 'text' then
		local serialData = SUI:Serialize(profileData)
		exportString = SUI:CreateProfileExport(serialData, profileScope, profileKey)
		local compressedData = SUI.Lib.Compress:Compress(exportString)
		local encodedData = SUI.Lib.Base64:Encode(compressedData)
		profileExport = encodedData
	elseif exportFormat == 'luaTable' then
		exportString = SUI:TableToLuaString(profileData)
		profileExport = SUI:CreateProfileExport(exportString, profileScope, profileKey)
	elseif exportFormat == 'luaPlugin' then
		profileExport = SUI:ProfileTableToPluginFormat(profileData, profileScope)
	end

	return profileKey, profileExport
end

function SUI:CreateProfileExport(dataString, profileScope, profileKey)
	local returnString

	if profileScope == 'core' or profileScope == 'all' then
		returnString = format('%s::%s::%s', dataString, profileScope, profileKey)
	else
		returnString = format('%s::%s', dataString, profileScope)
	end

	return returnString
end

function SUI:GetImportStringType(dataString)
	local stringType = ''

	if SUI.Lib.Base64:IsBase64(dataString) then
		stringType = 'Base64'
	elseif find(dataString, '{') then --Basic check to weed out obviously wrong strings
		stringType = 'Table'
	end

	return stringType
end

function SUI:Decode(dataString)
	local profileInfo, profileType, profileKey, profileData
	local stringType = self:GetImportStringType(dataString)

	if stringType == 'Base64' then
		local decodedData = SUI.Lib.Base64:Decode(dataString)
		local decompressedData, decompressedMessage = SUI.Lib.Compress:Decompress(decodedData)

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

function SUI:ExportUI()
	local StdUi = LibStub('StdUi'):NewInstance()
	local window = StdUi:Window(nil, 650, 500)
	window.StdUi = StdUi
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
	window.Export = StdUi:Button(window, 150, 20, 'EXPORT')
	local items = {
		{text = L['Text'], value = 'text'},
		{text = L['Table'], value = 'luaTable'},
		{text = L['Plugin'], value = 'luaPlugin'}
	}

	window.mode = StdUi:Dropdown(window, 200, 20, items, 'luaTable')
	window.mode:SetPoint('BOTTOM', window, 'BOTTOM', 0, 2)

	local namespaceblacklist = {'LibDualSpec-1.0'}
	local namespacelist = {{text = 'All', value = 'all'}, {text = 'Core', value = 'core'}}
	for i, v in pairs(SpartanUIDB.namespaces) do
		if not SUI:isInTable(namespaceblacklist, i) then
			table.insert(namespacelist, {text = i, value = i})
		end
	end

	window.namespaces = StdUi:Dropdown(window, 200, 20, namespacelist, 'all')
	window.namespaces:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 2, 2)

	--Position the Buttons
	window.Export:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -2, 2)

	window.Export:SetScript(
		'OnClick',
		function(this)
			local profileScope = window.namespaces:GetValue()
			local profileKey, profileExport = GetProfileExport(window.mode:GetValue(), profileScope)
			if not profileExport then
				window.Desc1:SetText('Error exporting profile!')
			else
				local a = format('%s: |cff00b3ff%s|r', 'Exported', window.namespaces:FindValueText(profileScope))
				local b = format('%s: |cff00b3ff%s|r', 'Profile Name', profileKey)

				window.Desc1:SetText(a)
				if profileScope == 'all' or profileScope == 'core' then
					window.Desc1:SetText(a .. ' ' .. b)
				end

				window.textBox:SetValue(profileExport)
				window.textBox.editBox:HighlightText()
				window.textBox.editBox:SetFocus()

				exportString = profileExport
			end
		end
	)

	-- Display first page
	-- window.closeBtn:Hide()
	window:Show()
end
