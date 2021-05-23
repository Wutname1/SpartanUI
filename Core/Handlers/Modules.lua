local SUI, L, Lib = SUI, SUI.L, SUI.Lib
local module = SUI:NewModule('Handler_Modules')
-- Incase we decide to handle this different again in the future using these helpers will 'help'
----------------------------------------------------------------------------------------------------

local function GetName(ModuleTable)
	local name

	-- Ace3 adds SpartanUI_ to the name so it knows how to handle things, we need to account for that.

	if (string.match(ModuleTable.name, 'Component_')) then
		name = string.sub(ModuleTable.name, 21)
	end
	if (string.match(ModuleTable.name, 'Module_')) then
		name = string.sub(ModuleTable.name, 18)
	end
	return name
end

function SUI:IsModuleEnabled(moduleName)
	if type(moduleName) == 'table' then
		moduleName = GetName(moduleName)
	end

	if SUI.DB.DisabledComponents[moduleName] then
		return false
	end
	return true
end

function SUI:IsModuleDisabled(moduleName)
	if type(moduleName) == 'table' then
		moduleName = GetName(moduleName)
	end

	if SUI.DB.DisabledComponents[moduleName] then
		return true
	end
	return false
end

-- These override the default Ace3 calls so we can track the status
function SUI:DisableModule(moduleName)
	if type(moduleName) == 'table' then
		moduleName = GetName(moduleName)
	end

	SUI.DB.DisabledComponents[moduleName] = true
	moduleName = 'Component_' .. moduleName
	local module = self:GetModule(moduleName)
	return module:Disable()
end

function SUI:EnableModule(moduleName)
	if type(moduleName) == 'table' then
		moduleName = GetName(moduleName)
	end

	SUI.DB.DisabledComponents[moduleName] = nil
	moduleName = 'Component_' .. moduleName
	local module = self:GetModule(moduleName)
	return module:Enable()
end

local function ModuleSelectionPage()
	local ModuleSelectionPage = {
		ID = 'ModuleSelectionPage',
		Name = L['Enabled modules'],
		Priority = true,
		SubTitle = L['Enabled modules'],
		Desc1 = 'Below you can disable modules of SpartanUI',
		RequireDisplay = (not SUI.DB.SetupDone),
		Display = function()
			local window = SUI:GetModule('SetupWizard').window
			local SUI_Win = window.content
			local StdUi = window.StdUi

			--Container
			SUI_Win.ModSelection = CreateFrame('Frame', nil)
			SUI_Win.ModSelection:SetParent(SUI_Win)
			SUI_Win.ModSelection:SetAllPoints(SUI_Win)

			local itemsMatrix = {}

			-- List Components
			for _, submodule in pairs(SUI.orderedModules) do
				if
					((string.match(submodule.name, 'Component_')) or (string.match(submodule.name, 'Module_'))) and
						not submodule.HideModule
				 then
					local RealName = GetName(submodule)
					-- Get modules display name
					local Displayname = submodule.DisplayName or RealName

					local checkbox = StdUi:Checkbox(SUI_Win.ModSelection, Displayname, 160, 20)
					if submodule.description then
						StdUi:FrameTooltip(checkbox, submodule.description, submodule.name .. 'Tooltip', 'TOP', true)
					end

					checkbox:HookScript(
						'OnClick',
						function()
							local IsDisabled = (not checkbox:GetValue()) or false
							SUI.DB.DisabledComponents[RealName] = IsDisabled

							if (IsDisabled) then
								submodule:Disable()
							else
								submodule:Enable()
							end
						end
					)
					checkbox:SetChecked(not SUI.DB.DisabledComponents[RealName])
					checkbox.name = RealName
					checkbox.Core = (submodule.Core or false)
					itemsMatrix[(#itemsMatrix + 1)] = checkbox
				end
			end

			StdUi:GlueTop(itemsMatrix[1], SUI_Win.ModSelection, -60, 0)

			local left, leftIndex = false, 1
			for i = 2, #itemsMatrix do
				if left then
					StdUi:GlueBelow(itemsMatrix[i], itemsMatrix[leftIndex], 0, -3)
					leftIndex = i
					left = false
				else
					StdUi:GlueRight(itemsMatrix[i], itemsMatrix[leftIndex], 3, 0)
					left = true
				end
			end

			local btnOptional = StdUi:Button(SUI_Win.ModSelection, 130, 18, 'Toggle optional(s)')
			btnOptional.tooltip =
				StdUi:FrameTooltip(
				btnOptional,
				'Toggles optional SUI modules. Disabling Core modules may cause unintended side effects.',
				'OptionalTooltip',
				'TOP',
				true
			)
			btnOptional:SetScript(
				'OnClick',
				function(this)
					for i, v in ipairs(itemsMatrix) do
						if not v.Core then
							v:Click()
						end
					end
				end
			)
			StdUi:GlueBottom(btnOptional, SUI_Win.ModSelection, 0, 0)
			SUI_Win.ModSelection.btnOptional = btnOptional
		end,
		Next = function()
			SUI.DB.SetupDone = true
		end,
		Skip = function()
			SUI.DB.SetupDone = true
		end
	}

	SUI:GetModule('SetupWizard'):AddPage(ModuleSelectionPage)
end

function module:OnEnable()
	ModuleSelectionPage()
end
