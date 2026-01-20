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
		if moduleName.override then
			return false
		end

		moduleName = SUI:GetModuleName(moduleName)
	else
		-- Fetch the Module
		local moduleObj = SUI:GetModule(moduleName, true)
		if not moduleObj then
			return false
		end
		-- See if the modules has been overridden
		if moduleObj and moduleObj.override then
			return false
		end
	end

	if SUI.DB.DisabledModules[moduleName] then
		return false
	end

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
			local UI = LibAT.UI
			local SUI_Win = SUI.Setup.window.content

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

					local checkbox = UI.CreateCheckbox(SUI_Win.ModSelection, Displayname)

					-- Add tooltip if description exists
					if submodule.description then
						checkbox:SetScript('OnEnter', function(self)
							GameTooltip:SetOwner(self, 'ANCHOR_TOP')
							GameTooltip:SetText(Displayname)
							GameTooltip:AddLine(submodule.description, 1, 1, 1, true)
							GameTooltip:Show()
						end)
						checkbox:SetScript('OnLeave', function(self)
							GameTooltip:Hide()
						end)
					end

					checkbox:HookScript(
						'OnClick',
						function()
							local IsDisabled = (not checkbox:GetChecked()) or false
							if not IsDisabled then
								SUI:EnableModule(submodule)
							else
								SUI:DisableModule(submodule)
							end
						end
					)
					checkbox:SetChecked(SUI:IsModuleEnabled(RealName))
					checkbox.name = RealName
					checkbox.Core = (submodule.Core or false)
					itemsMatrix[(#itemsMatrix + 1)] = checkbox
				end
			end

			-- Position checkboxes in 2-column layout with proper spacing
			local col1X, col2X = -150, 50  -- X positions for each column
			local startY = -10  -- Starting Y position
			local ySpacing = 3  -- Vertical spacing between rows

			for i = 1, #itemsMatrix do
				local row = math.floor((i - 1) / 2)  -- Calculate row (0-indexed)
				local col = (i - 1) % 2  -- Calculate column (0 = left, 1 = right)

				local xPos = (col == 0) and col1X or col2X
				local yPos = startY - (row * (20 + ySpacing))  -- 20px height + spacing

				itemsMatrix[i]:SetPoint('TOPLEFT', SUI_Win.ModSelection, 'TOP', xPos, yPos)

				-- Set max width on checkbox label to prevent overflow
				if itemsMatrix[i].text then
					itemsMatrix[i].text:SetWidth(180)
					itemsMatrix[i].text:SetWordWrap(false)
				end
			end

			-- Toggle optional button at bottom
			local btnOptional = UI.CreateButton(SUI_Win.ModSelection, 130, 18, 'Toggle optional(s)')
			btnOptional:SetScript('OnEnter', function(self)
				GameTooltip:SetOwner(self, 'ANCHOR_TOP')
				GameTooltip:SetText('Toggle optional(s)')
				GameTooltip:AddLine('Toggles optional SUI modules. Disabling Core modules may cause unintended side effects.', 1, 1, 1, true)
				GameTooltip:Show()
			end)
			btnOptional:SetScript('OnLeave', function(self)
				GameTooltip:Hide()
			end)
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
			btnOptional:SetPoint('BOTTOM', SUI_Win.ModSelection, 'BOTTOM', 0, 0)
			SUI_Win.ModSelection.btnOptional = btnOptional
		end,
		Next = function()
			SUI.DB.SetupDone = true
		end,
		Skip = function()
			SUI.DB.SetupDone = true
		end
	}

	SUI.Setup:AddPage(SetupPage)
end

function module:OnEnable()
	CreateSetupPage()
end
