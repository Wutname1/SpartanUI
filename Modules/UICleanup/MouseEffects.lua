local SUI, L = SUI, SUI.L
---@class SUI.Module.UICleanup
local module = SUI:GetModule('UICleanup')
----------------------------------------------------------------------------------------------------

-- Constants
local DENSITY_PRESETS = {
	verylow = { spawnRate = 0.08, fadeDuration = 0.3, maxElements = 10 },
	low = { spawnRate = 0.05, fadeDuration = 0.4, maxElements = 20 },
	medium = { spawnRate = 0.03, fadeDuration = 0.5, maxElements = 35 },
	high = { spawnRate = 0.02, fadeDuration = 0.6, maxElements = 50 },
	veryhigh = { spawnRate = 0.01, fadeDuration = 0.8, maxElements = 75 },
}

local MIN_MOVE_DISTANCE_SQ = 25 -- 5^2, minimum cursor movement squared to spawn trail element
local MAX_POOL_SIZE = 75

-- State
local mouseRingFrame = nil
local trailPool = {}
local activeTrailElements = {}
local lastCursorX, lastCursorY = 0, 0
local timeAccumulator = 0
local isOnUpdateActive = false
local updateFrame = nil

---Get color based on settings
---@param colorSettings table Color settings with mode, r, g, b
---@return number r Red component
---@return number g Green component
---@return number b Blue component
local function GetEffectColor(colorSettings)
	if colorSettings.mode == 'class' then
		local _, class = UnitClass('player')
		local classColor = RAID_CLASS_COLORS[class]
		if classColor then
			return classColor.r, classColor.g, classColor.b
		end
	end
	return colorSettings.r, colorSettings.g, colorSettings.b
end

---Check if mouse effects should be visible based on combat state
---@param settings table Effect settings with combatOnly field
---@return boolean visible Whether effect should be visible
local function ShouldShowEffect(settings)
	if not settings.enabled then
		return false
	end
	if settings.combatOnly then
		return InCombatLockdown()
	end
	return true
end

-- Mouse Ring Implementation

---Initialize the mouse ring frame
function module:InitializeMouseRing()
	if mouseRingFrame then
		return
	end

	mouseRingFrame = CreateFrame('Frame', 'SUI_MouseRing', UIParent)
	mouseRingFrame:SetFrameStrata('TOOLTIP')
	mouseRingFrame:SetFrameLevel(9999)

	-- Ring texture
	mouseRingFrame.ring = mouseRingFrame:CreateTexture(nil, 'OVERLAY')
	mouseRingFrame.ring:SetTexture('Interface\\AddOns\\SpartanUI\\images\\circle')
	mouseRingFrame.ring:SetAllPoints()
	mouseRingFrame.ring:SetBlendMode('ADD')

	-- Optional center dot
	mouseRingFrame.dot = mouseRingFrame:CreateTexture(nil, 'OVERLAY')
	mouseRingFrame.dot:SetTexture('Interface\\AddOns\\SpartanUI\\images\\blank')
	mouseRingFrame.dot:SetPoint('CENTER')
	mouseRingFrame.dot:Hide()

	mouseRingFrame:Hide()
end

-- Mouse Trail Implementation (Object Pool Pattern)

---Create a single trail element
---@return Frame element Trail element frame
local function CreateTrailElement()
	local element = CreateFrame('Frame', nil, UIParent)
	element:SetFrameStrata('TOOLTIP')
	element:SetFrameLevel(9998)

	element.texture = element:CreateTexture(nil, 'OVERLAY')
	element.texture:SetTexture('Interface\\AddOns\\SpartanUI\\images\\circle')
	element.texture:SetAllPoints()
	element.texture:SetBlendMode('ADD')

	-- Fade animation group
	element.fadeAnim = element:CreateAnimationGroup()
	local fade = element.fadeAnim:CreateAnimation('Alpha')
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetSmoothing('OUT')
	element.fadeAnim.fade = fade

	element.fadeAnim:SetScript('OnFinished', function()
		module:ReturnTrailElement(element)
	end)

	element:Hide()
	return element
end

---Initialize the trail element pool
function module:InitializeMouseTrail()
	-- Pre-populate pool
	for i = 1, MAX_POOL_SIZE do
		local element = CreateTrailElement()
		table.insert(trailPool, element)
	end
end

---Get a trail element from the pool
---@return Frame|nil element Trail element or nil if pool is empty
function module:GetTrailElement()
	local element = table.remove(trailPool)
	if element then
		table.insert(activeTrailElements, element)
	end
	return element
end

---Return a trail element to the pool
---@param element Frame Trail element to return
function module:ReturnTrailElement(element)
	element:Hide()
	element:ClearAllPoints()
	element.fadeAnim:Stop()

	for i, active in ipairs(activeTrailElements) do
		if active == element then
			table.remove(activeTrailElements, i)
			break
		end
	end

	table.insert(trailPool, element)
end

-- Shared OnUpdate Handler

---Update mouse effects (called every frame when active)
---@param elapsed number Time since last frame
local function MouseEffectsOnUpdate(_, elapsed)
	local DB = module:GetDB()
	local scale = UIParent:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()
	cursorX, cursorY = cursorX / scale, cursorY / scale

	local ringVisible = ShouldShowEffect(DB.mouseRing)
	local trailVisible = ShouldShowEffect(DB.mouseTrail)

	-- Update Mouse Ring position
	if ringVisible and mouseRingFrame then
		local size = DB.mouseRing.size
		mouseRingFrame:SetSize(size, size)
		mouseRingFrame:ClearAllPoints()
		mouseRingFrame:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', cursorX, cursorY)

		local r, g, b = GetEffectColor(DB.mouseRing.color)
		mouseRingFrame.ring:SetVertexColor(r, g, b, DB.mouseRing.alpha)

		if DB.mouseRing.showCenterDot then
			mouseRingFrame.dot:SetSize(DB.mouseRing.centerDotSize, DB.mouseRing.centerDotSize)
			mouseRingFrame.dot:SetVertexColor(r, g, b, DB.mouseRing.alpha)
			mouseRingFrame.dot:Show()
		else
			mouseRingFrame.dot:Hide()
		end

		mouseRingFrame:Show()
	elseif mouseRingFrame then
		mouseRingFrame:Hide()
	end

	-- Update Mouse Trail
	if trailVisible then
		timeAccumulator = timeAccumulator + elapsed

		local dx = cursorX - lastCursorX
		local dy = cursorY - lastCursorY
		local distanceSq = dx * dx + dy * dy

		local preset = DENSITY_PRESETS[DB.mouseTrail.density] or DENSITY_PRESETS.medium

		if distanceSq >= MIN_MOVE_DISTANCE_SQ and timeAccumulator >= preset.spawnRate then
			if #activeTrailElements < preset.maxElements then
				local element = module:GetTrailElement()
				if element then
					local size = DB.mouseTrail.size
					element:SetSize(size, size)
					element:ClearAllPoints()
					element:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', cursorX, cursorY)

					local r, g, b = GetEffectColor(DB.mouseTrail.color)
					element.texture:SetVertexColor(r, g, b, DB.mouseTrail.alpha)

					element.fadeAnim.fade:SetDuration(preset.fadeDuration)
					element:Show()
					element.fadeAnim:Play()
				end
			end
			timeAccumulator = 0
		end
	end

	lastCursorX, lastCursorY = cursorX, cursorY
end

-- Public API

---Initialize mouse effects (called from UICleanup OnEnable)
function module:InitializeMouseEffects()
	module:InitializeMouseRing()
	module:InitializeMouseTrail()

	-- Create update frame
	if not updateFrame then
		updateFrame = CreateFrame('Frame')
	end

	-- Register combat events for combat-only mode
	updateFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
	updateFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
	updateFrame:SetScript('OnEvent', function()
		module:ApplyMouseEffectSettings()
	end)
end

---Apply mouse effect settings (called when settings change or combat state changes)
function module:ApplyMouseEffectSettings()
	local DB = module:GetDB()
	local ringEnabled = DB.mouseRing and DB.mouseRing.enabled
	local trailEnabled = DB.mouseTrail and DB.mouseTrail.enabled
	local needsOnUpdate = ringEnabled or trailEnabled

	if needsOnUpdate and not isOnUpdateActive then
		updateFrame:SetScript('OnUpdate', MouseEffectsOnUpdate)
		isOnUpdateActive = true
		-- Reset state
		timeAccumulator = 0
		local scale = UIParent:GetEffectiveScale()
		local cursorX, cursorY = GetCursorPosition()
		lastCursorX, lastCursorY = cursorX / scale, cursorY / scale
	elseif not needsOnUpdate and isOnUpdateActive then
		updateFrame:SetScript('OnUpdate', nil)
		if mouseRingFrame then
			mouseRingFrame:Hide()
		end
		isOnUpdateActive = false
	end
end

---Restore mouse effects to default state (called from UICleanup OnDisable)
function module:RestoreMouseEffects()
	if updateFrame then
		updateFrame:SetScript('OnUpdate', nil)
		updateFrame:UnregisterAllEvents()
	end

	if mouseRingFrame then
		mouseRingFrame:Hide()
	end

	-- Return all active trail elements to pool
	for i = #activeTrailElements, 1, -1 do
		module:ReturnTrailElement(activeTrailElements[i])
	end

	isOnUpdateActive = false
end
