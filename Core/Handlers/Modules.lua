---@class SUI
local SUI = SUI
local L = SUI.L
local module = SUI:NewModule('Handler.Modules') ---@type SUI.Module

---@param ModuleTable AceAddon
---@return string
function SUI:GetModuleName(ModuleTable)
	local name

	-- Remove SpartanUI_
	name = string.gsub(ModuleTable.name, 'SpartanUI_', '')

	return name
end

---@param moduleName AceAddon|string
---@return boolean
function SUI:IsModuleEnabled(moduleName)
	-- If we are passed a table, we need to get the name from it.
	if type(moduleName) == 'table' then
		if moduleName.override then return false end

		moduleName = SUI:GetModuleName(moduleName)
	else
		-- Fetch the Module
		local moduleObj = SUI:GetModule(moduleName, true)
		if not moduleObj then return false end
		-- See if the modules has been overridden
		if moduleObj and moduleObj.override then return false end
	end

	if SUI.DB.DisabledModules[moduleName] then return false end

	return true
end

---@param moduleName AceAddon|string
---@return boolean
function SUI:IsModuleDisabled(moduleName)
	return not SUI:IsModuleEnabled(moduleName)
end

-- These override the default Ace3 calls so we can track the status
---@param input AceAddon|string
function SUI:DisableModule(input)
	local moduleToDisable
	if type(input) == 'table' then
		moduleToDisable = input
	else
		moduleToDisable = SUI:GetModule(input, true)
	end

	if moduleToDisable then
		SUI.DB.DisabledModules[SUI:GetModuleName(moduleToDisable)] = true
		return moduleToDisable:Disable()
	end
end

---@param input AceAddon|string
function SUI:EnableModule(input)
	local moduleToDisable
	if type(input) == 'table' then
		moduleToDisable = input
	else
		moduleToDisable = SUI:GetModule(input)
	end

	SUI.DB.DisabledModules[SUI:GetModuleName(moduleToDisable)] = nil
	return moduleToDisable:Enable()
end

local function CreateSetupPage()
	local SetupPage = {
		ID = 'ModuleSelectionPage',
		Name = L['Enabled modules'],
		Priority = true,
		SubTitle = L['Enabled modules'],
		Desc1 = 'Below you can disable modules of SpartanUI',
		RequireDisplay = not SUI.DB.SetupDone,
		Display = function()
			local SUI_Win = SUI.Setup.window.content
			local StdUi = SUI.StdUi

			--Container
			SUI_Win.ModSelection = CreateFrame('Frame', nil)
			SUI_Win.ModSelection:SetParent(SUI_Win)
			SUI_Win.ModSelection:SetAllPoints(SUI_Win)

			local itemsMatrix = {}

			-- List Modules
			for _, submodule in pairs(SUI.orderedModules) do
				local name = submodule.name
				if not string.match(name, 'Handler.') and not string.match(name, 'Style.') and not submodule.HideModule then
					local RealName = SUI:GetModuleName(submodule)
					-- Get modules display name
					local Displayname = submodule.DisplayName or RealName

					local checkbox = StdUi:Checkbox(SUI_Win.ModSelection, Displayname, 160, 20)
					if submodule.description then StdUi:FrameTooltip(checkbox, submodule.description, submodule.name .. 'Tooltip', 'TOP', true) end

					checkbox:HookScript('OnClick', function()
						local IsDisabled = (not checkbox:GetValue()) or false
						if IsDisabled then
							SUI:DisableModule(submodule)
						else
							SUI:EnableModule(submodule)
						end
					end)
					checkbox:SetChecked(SUI:IsModuleEnabled(RealName))
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
			btnOptional.tooltip = StdUi:FrameTooltip(btnOptional, 'Toggles optional SUI modules. Disabling Core modules may cause unintended side effects.', 'OptionalTooltip', 'TOP', true)
			btnOptional:SetScript('OnClick', function(this)
				for i, v in ipairs(itemsMatrix) do
					if not v.Core then v:Click() end
				end
			end)
			StdUi:GlueBottom(btnOptional, SUI_Win.ModSelection, 0, 0)
			SUI_Win.ModSelection.btnOptional = btnOptional
		end,
		Next = function()
			SUI.DB.SetupDone = true
		end,
		Skip = function()
			SUI.DB.SetupDone = true
		end,
	}

	SUI.Setup:AddPage(SetupPage)
end

function module:OnEnable()
	CreateSetupPage()
end
