---@class LibAT : AceAddon, AceEvent-3.0, AceConsole-3.0
local LibAT = LibStub('AceAddon-3.0'):NewAddon('Libs-AddonTools', 'AceEvent-3.0', 'AceConsole-3.0')
-- Global namespace
_G.LibAT = LibAT

-- Version information
LibAT.Version = C_AddOns.GetAddOnMetadata('Libs-AddonTools', 'Version') or 0
LibAT.BuildNum = C_AddOns.GetAddOnMetadata('Libs-AddonTools', 'X-Build') or 0
LibAT.BuildType = 'Release'
--@alpha@
LibAT.BuildType = 'ALPHA ' .. LibAT.BuildNum
--@end-alpha@
--@beta@
LibAT.BuildType = 'BETA ' .. LibAT.BuildNum
--@end-beta@
--@do-not-package@
LibAT.BuildType = 'DEV Build'
LibAT.Version = ''
--@end-do-not-package@

-- Core systems storage
LibAT.UI = {}
LibAT.Components = {}
LibAT.Systems = {}

---Safely reload the UI with instance+combat check
---@param showMessage? boolean Whether to show error message (default: true)
---@return boolean success Whether reload was initiated or would be allowed
function LibAT:SafeReloadUI(showMessage)
	if showMessage == nil then
		showMessage = true
	end

	local inInstance = IsInInstance()
	local inCombat = InCombatLockdown()

	if inInstance and inCombat then
		if showMessage then
			self:Print('|cffff0000Cannot reload UI while in combat in an instance|r')
		end
		return false
	end

	ReloadUI()
	return true
end

---Options Manager - Simple interface for managing AceConfig options
LibAT.Options = {
	optionsTable = {},
	registry = nil,
	dialog = nil
}

---Initialize the Options system with AceConfig
function LibAT.Options:Init()
	if not self.registry then
		self.registry = LibStub('AceConfigRegistry-3.0', true)
		self.dialog = LibStub('AceConfigDialog-3.0', true)
	end
end

---Add options to the config system
---@param options table The options table
---@param name string The name for this options group
---@param parent? string Optional parent category
function LibAT.Options:AddOptions(options, name, parent)
	self:Init()

	if not self.registry then
		LibAT:Print('Warning: AceConfig not available, options cannot be registered')
		return
	end

	-- Store the options
	self.optionsTable[name] = options

	-- Register with AceConfig if available
	if self.registry and self.dialog then
		self.registry:RegisterOptionsTable(name, options)

		-- Try to add to Blizzard options
		-- If parent is specified but doesn't exist, add without parent
		local success, err =
			pcall(
			function()
				if parent then
					-- First ensure parent exists by trying to create it
					if not self.optionsTable[parent] then
						-- Create a dummy parent category
						local parentOptions = {
							type = 'group',
							name = parent,
							args = {}
						}
						self.registry:RegisterOptionsTable(parent, parentOptions)
						self.dialog:AddToBlizOptions(parent, parent)
						self.optionsTable[parent] = parentOptions
					end
					self.dialog:AddToBlizOptions(name, name, parent)
				else
					self.dialog:AddToBlizOptions(name, name)
				end
			end
		)

		if not success then
			-- Fallback: add without parent if there was an error
			LibAT:Print('Warning: Could not add options with parent "' .. tostring(parent) .. '", adding as standalone. Error: ' .. tostring(err))
			pcall(
				function()
					self.dialog:AddToBlizOptions(name, name)
				end
			)
		end
	end
end

---Toggle options dialog
---@param path? table Optional path to specific options
function LibAT.Options:ToggleOptions(path)
	self:Init()

	if self.dialog then
		if path and #path > 0 then
			-- Open specific options page
			Settings.OpenToCategory(path[#path])
		else
			-- Open main LibAT options
			Settings.OpenToCategory('Libs-AddonTools')
		end
	end
end

---Register a system with LibAT
---@param name string The name of the system
---@param system table The system object
function LibAT:RegisterSystem(name, system)
	if not name or not system then
		self:Print('RegisterSystem: Invalid parameters')
		return
	end
	self.Systems[name] = system
	self:Print(string.format('Registered system: %s', name))
end

---Initialize the LibAT framework
function LibAT:OnInitialize()
	-- Initialize database
	local defaults = {
		profile = {
			errorDisplay = {
				autoPopup = false,
				chatframe = true,
				fontSize = 12,
				minimapIcon = {hide = false, minimapPos = 97.66349921766368},
				ignoredErrors = {} -- Store signatures of errors to ignore
			},
			profileManager = {
				lastExportFormat = 'text',
				defaultProfileName = 'LibAT Import'
			}
		}
	}

	self.Database = LibStub('AceDB-3.0'):New('LibsAddonToolsDB', defaults, 'Default')
	self.DB = self.Database.profile
end

---Enable the LibAT framework
function LibAT:OnEnable()
end

---Handle slash commands
SLASH_LIBAT1 = '/libat'
SlashCmdList['LIBAT'] = function(msg)
	local args = {strsplit(' ', msg)}
	local command = args[1] and args[1]:lower() or ''

	if command == 'errors' or command == 'error' then
		if LibAT.ErrorDisplay then
			LibAT.ErrorDisplay.BugWindow:OpenErrorWindow()
		elseif _G.LibATErrorDisplay then
			_G.LibATErrorDisplay.BugWindow:OpenErrorWindow()
		else
			LibAT:Print('Error Display system not available')
		end
	elseif command == 'profiles' or command == 'profile' then
		if LibAT.ProfileManager then
			LibAT.ProfileManager:ImportUI()
		else
			LibAT:Print('Profile Manager system not available')
		end
	elseif command == 'logs' or command == 'log' then
		if LibAT.Logger then
			LibAT.Logger.ToggleWindow()
		else
			LibAT:Print('Logger system not available')
		end
	else
		LibAT:Print('LibAT Commands:')
		LibAT:Print('  /libat errors - Open error display window')
		LibAT:Print('  /libat profiles - Open profile manager')
		LibAT:Print('  /libat logs - Open logger window')
		LibAT:Print('  /libatlogs - Toggle logger (direct command)')
		LibAT:Print('  /libatprofiles - Open profile manager (direct command)')
	end
end

SLASH_RL1 = '/rl'
SlashCmdList['RL'] = function()
	LibAT:SafeReloadUI()
end
