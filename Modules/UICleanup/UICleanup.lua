local SUI, L = SUI, SUI.L
---@class SUI.Module.UICleanup : SUI.Module
local module = SUI:NewModule('UICleanup')
module.DisplayName = L['UI Cleanup']
module.description = 'Hide and suppress various UI elements for a cleaner interface'
----------------------------------------------------------------------------------------------------

---@class SUI.Module.UICleanup.DB
local DBDefaults = {
	hideErrorMessages = false,
	hideZoneText = false,
	hideAlerts = false,
	hideBossBanner = false,
	hideEventToasts = false,
	decorMerchantBulkBuy = true,
	lootAlertPopup = true,
	lootAlertChat = true,
	lootAlertSound = false,
	lootAlertSoundName = 'None',
}

local DB

function module:OnInitialize()
	module.Database = SUI.SpartanUIDB:RegisterNamespace('UICleanup', { profile = DBDefaults })
	DB = module.Database.profile
	module.DB = DB

	-- Migrate enabled/disabled state from StopTalking
	module:MigrateFromStopTalking()
end

function module:MigrateFromStopTalking()
	-- Check if StopTalking was disabled and UICleanup state hasn't been set yet
	if SUI.DB and SUI.DB.DisabledModules then
		local disabled = SUI.DB.DisabledModules
		-- Only migrate if StopTalking had an explicit disabled state and UICleanup doesn't
		if disabled.StopTalking ~= nil and disabled.UICleanup == nil then
			disabled.UICleanup = disabled.StopTalking
			SUI:Print('Migrated StopTalking enabled state to UICleanup')
		end
	end
end

function module:GetDB()
	return DB
end

function module:OnEnable()
	if SUI:IsModuleDisabled(module) then
		return
	end

	-- Initialize sub-modules
	module:InitializeErrorMessages()
	module:InitializeFrameHiding()
	module:InitializeStopTalking()
	module:InitializeDecorMerchant()
	module:InitializeLootAlertPopup()

	-- Build options
	module:BuildOptions()

	-- Apply settings
	module:ApplySettings()
end

function module:ApplySettings()
	module:ApplyErrorMessageSettings()
	module:ApplyFrameHidingSettings()
end

function module:OnDisable()
	-- Restore default behavior for all hidden elements
	module:RestoreErrorMessages()
	module:RestoreFrameHiding()
	module:RestoreDecorMerchant()
	module:RestoreLootAlertPopup()
end
