-- oUF DefensiveIndicator Element
-- Shows defensive cooldowns (Ironbark, Pain Suppression, etc.) on raid/party frames
-- Uses Blizzard's CenterDefensiveBuff data to determine which defensive to display

local _, ns = ...
local oUF = ns.oUF or oUF

if not oUF then
	return
end

-- ============================================================
-- BLIZZARD FRAME CACHE
-- ============================================================

-- Cache of defensive auras from Blizzard's CompactUnitFrame
-- Exposed globally so the SUI element file can access it
---@type table<string, table<number, boolean>>
SUI_DefensiveCache = SUI_DefensiveCache or {}
local DefensiveCache = SUI_DefensiveCache

-- Track if we've hooked Blizzard's frames
local BlizzardHookActive = false

-- Capture defensive aura from Blizzard's CompactUnitFrame
---@param frame table Blizzard's CompactUnitFrame
local function CaptureDefensiveFromBlizzardFrame(frame)
	if not frame or not frame.unit then
		return
	end

	-- Skip nameplates
	local unit = frame.unit
	if unit and type(unit) == 'string' and unit:find('nameplate') then
		return
	end

	-- Initialize cache for this unit
	if not DefensiveCache[unit] then
		DefensiveCache[unit] = {}
	else
		wipe(DefensiveCache[unit])
	end

	-- Capture defensive aura from CenterDefensiveBuff frame
	-- This is Blizzard's single frame that shows the most important defensive aura
	if frame.CenterDefensiveBuff then
		local defFrame = frame.CenterDefensiveBuff
		if defFrame:IsShown() and defFrame.auraInstanceID then
			DefensiveCache[unit][defFrame.auraInstanceID] = true
		end
	end
end

-- Setup hooks to Blizzard's CompactUnitFrame aura updates
local function SetupBlizzardHooks()
	if BlizzardHookActive then
		return
	end

	-- Hook the main aura update function
	if CompactUnitFrame_UpdateAuras then
		hooksecurefunc('CompactUnitFrame_UpdateAuras', function(frame)
			CaptureDefensiveFromBlizzardFrame(frame)
		end)
		BlizzardHookActive = true
	end

	-- Also hook UpdateBuffs if it exists separately
	if CompactUnitFrame_UpdateBuffs then
		hooksecurefunc('CompactUnitFrame_UpdateBuffs', function(frame)
			CaptureDefensiveFromBlizzardFrame(frame)
		end)
	end
end

-- Scan all Blizzard compact frames to build initial cache
local function ScanAllBlizzardFrames()
	-- Scan party frames
	for i = 1, 4 do
		local frame = _G['CompactPartyFrameMember' .. i]
		if frame then
			CaptureDefensiveFromBlizzardFrame(frame)
		end
	end

	-- Scan raid frames (up to 40)
	for i = 1, 40 do
		local frame = _G['CompactRaidFrame' .. i]
		if frame then
			CaptureDefensiveFromBlizzardFrame(frame)
		end
	end

	-- Scan raid group frames
	for group = 1, 8 do
		for member = 1, 5 do
			local frame = _G['CompactRaidGroup' .. group .. 'Member' .. member]
			if frame then
				CaptureDefensiveFromBlizzardFrame(frame)
			end
		end
	end
end

-- ============================================================
-- OUF ELEMENT
-- ============================================================

local function Update(self, event, unit)
	if self.unit ~= unit and event ~= 'ForceUpdate' then
		return
	end

	local element = self.DefensiveIndicator
	if not element then
		return
	end

	--[[ Callback: DefensiveIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the DefensiveIndicator element
	--]]
	if element.PreUpdate then
		element:PreUpdate()
	end

	unit = self.unit
	if not unit or not UnitExists(unit) then
		element:Hide()
		return
	end

	-- Scan Blizzard frames to update cache
	ScanAllBlizzardFrames()

	-- Get cached defensive from Blizzard's CenterDefensiveBuff
	local cache = DefensiveCache[unit]
	local auraInstanceID = nil

	if cache then
		-- Get the first (and typically only) defensive
		for id in pairs(cache) do
			auraInstanceID = id
			break
		end
	end

	if not auraInstanceID then
		element:Hide()
		return
	end

	-- Get aura data using the auraInstanceID
	-- This API is safe to call even in combat
	local auraData = nil
	local success = pcall(function()
		auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
	end)

	if not success or not auraData then
		element:Hide()
		return
	end

	-- Set icon texture (use pcall for secret value protection)
	local textureSet = false
	if element.icon then
		pcall(function()
			element.icon:SetTexture(auraData.icon)
			textureSet = true
		end)
	end

	if not textureSet then
		element:Hide()
		return
	end

	-- Update cooldown
	if element.cooldown then
		-- Use SetCooldownFromExpirationTime if available (safer with secrets)
		if element.cooldown.SetCooldownFromExpirationTime and auraData.expirationTime and auraData.duration then
			pcall(function()
				element.cooldown:SetCooldownFromExpirationTime(auraData.expirationTime, auraData.duration)
			end)
		end

		-- Check if aura has expiration using secret-safe API
		local hasExpiration = nil
		if C_UnitAuras.DoesAuraHaveExpirationTime then
			hasExpiration = C_UnitAuras.DoesAuraHaveExpirationTime(unit, auraInstanceID)
		end

		-- Show/hide cooldown using secret-safe API if available
		if element.cooldown.SetShownFromBoolean then
			element.cooldown:SetShownFromBoolean(hasExpiration, true, false)
		else
			element.cooldown:Show()
		end
	end

	-- Update stack count using secret-safe API
	if element.count then
		element.count:SetText('')
		if C_UnitAuras.GetAuraApplicationDisplayCount then
			local stackText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 99)
			if stackText then
				element.count:SetText(stackText)
			end
		end
	end

	element:Show()

	--[[ Callback: DefensiveIndicator:PostUpdate(auraInstanceID, auraData)
	Called after the element has been updated.

	* self           - the DefensiveIndicator element
	* auraInstanceID - the aura instance ID of the defensive
	* auraData       - the aura data table from C_UnitAuras
	--]]
	if element.PostUpdate then
		element:PostUpdate(auraInstanceID, auraData)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.DefensiveIndicator
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		-- Setup Blizzard hooks
		SetupBlizzardHooks()

		-- Register for aura events
		self:RegisterEvent('UNIT_AURA', Update)

		-- Initial scan
		ScanAllBlizzardFrames()

		return true
	end
end

local function Disable(self)
	local element = self.DefensiveIndicator
	if element then
		self:UnregisterEvent('UNIT_AURA', Update)
		element:Hide()
	end
end

oUF:AddElement('DefensiveIndicator', Update, Enable, Disable)
