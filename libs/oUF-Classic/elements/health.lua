--[[
# Element: Health Bar

Handles the updating of a status bar that displays the unit's health.

## Widget

Health - A `StatusBar` used to represent the unit's health.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture set.

## Options

.smoothGradient                   - 9 color values to be used with the .colorSmooth option (table)

The following options are listed by priority. The first check that returns true decides the color of the bar.

.colorDisconnected - Use `self.colors.disconnected` to color the bar if the unit is offline (boolean)
.colorHappiness    - Use `self.colors.happiness[happiness]` to color the bar.
.colorTapping      - Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player (boolean)
.colorClass        - Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the
                     second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) (boolean)
.colorClassNPC     - Use `self.colors.class[class]` to color the bar if the unit is a NPC (boolean)
.colorClassPet     - Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player
                     (boolean)
.colorReaction     - Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the
                     unit. `reaction` is defined by the return value of
                     [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) (boolean)
.colorSmooth       - Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient
                     based on the player's current health percentage (boolean)
.colorHealth       - Use `self.colors.health` to color the bar. This flag is used to reset the bar color back to default
                     if none of the above conditions are met (boolean)

## Sub-Widgets Options

.multiplier - Used to tint the background based on the main widgets R, G and B values. Defaults to 1 (number)[0-1]

## Examples

    -- Position and size
    local Health = CreateFrame('StatusBar', nil, self)
    Health:SetHeight(20)
    Health:SetPoint('TOP')
    Health:SetPoint('LEFT')
    Health:SetPoint('RIGHT')

    -- Add a background
    local Background = Health:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(Health)
    Background:SetColorTexture(1, 1, 1, .5)

    -- Options
    Health.colorTapping = true
    Health.colorDisconnected = true
    Health.colorClass = true
    Health.colorReaction = true
    Health.colorHealth = true

    -- Make the background darker.
    Background.multiplier = .5

    -- Register it with oUF
    Health.bg = Background
    self.Health = Health
--]]

local _, ns = ...
local oUF = ns.oUF

local function UpdateColor(self, event, unit)
	if(not unit or self.unit ~= unit) then return end
	local element = self.Health

	local r, g, b, t
	if(element.colorDisconnected and not UnitIsConnected(unit)) then
		t = self.colors.disconnected
	elseif(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		t = self.colors.tapped
	elseif(element.colorHappiness and UnitIsUnit(unit, "pet") and GetPetHappiness()) then
		t = self.colors.happiness[GetPetHappiness()]
	elseif(element.colorClass and UnitIsPlayer(unit)) or
		(element.colorClassNPC and not UnitIsPlayer(unit)) or
		((element.colorClassPet or element.colorPetByUnitClass) and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		if element.colorPetByUnitClass then unit = unit == 'pet' and 'player' or gsub(unit, 'pet', '') end
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		t = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth) then
		r, g, b = self:ColorGradient(element.cur or 1, element.max or 1, unpack(element.smoothGradient or self.colors.smooth))
	elseif(element.colorHealth) then
		t = self.colors.health
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(b) then
		element:SetStatusBarColor(r, g, b)

		local bg = element.bg
		if(bg) then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end

	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	--[[ Override: Health.UpdateColor(self, event, unit)
	Used to completely override the internal function for updating the widgets' colors.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Health.UpdateColor or UpdateColor) (self, ...)
end

local function Update(self, event, unit)
	if(not unit or self.unit ~= unit) then return end
	local element = self.Health

	--[[ Callback: Health:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Health element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)

	element:SetMinMaxValues(0, max)

	if(disconnected) then
		element:SetValue(max)
	else
		element:SetValue(cur)
	end

	element.cur = cur
	element.max = max

	--[[ Callback: Health:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self - the Health element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current health value (number)
	* max  - the unit's maximum possible health value (number)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, event, ...)
	if (self.isForced and event ~= 'ElvUI_UpdateAllElements') then return end -- ElvUI changed

	--[[ Override: Health.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Health.Override or Update) (self, event, ...);

	ColorPath(self, event, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

--[[ Health:SetColorDisconnected(state)
Used to toggle coloring if the unit is offline.

* self  - the Health element
* state - the desired state (boolean)
--]]
local function SetColorDisconnected(element, state)
	if(element.colorDisconnected ~= state) then
		element.colorDisconnected = state
		if(element.colorDisconnected) then
			element.__owner:RegisterEvent('UNIT_CONNECTION', ColorPath)
			element.__owner:RegisterEvent('PARTY_MEMBER_ENABLE', ColorPath)
			element.__owner:RegisterEvent('PARTY_MEMBER_DISABLE', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_CONNECTION', ColorPath)
			element.__owner:UnregisterEvent('PARTY_MEMBER_ENABLE', ColorPath)
			element.__owner:UnregisterEvent('PARTY_MEMBER_DISABLE', ColorPath)
		end
	end
end

--[[ Health:SetColorTapping(state)
Used to toggle coloring if the unit isn't tapped by the player.

* self  - the Health element
* state - the desired state (boolean)
--]]
local function SetColorTapping(element, state)
	if(element.colorTapping ~= state) then
		element.colorTapping = state
		if(element.colorTapping) then
			element.__owner:RegisterEvent('UNIT_FACTION', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_FACTION', ColorPath)
		end
	end
end

-- ElvUI changed block
local onUpdateElapsed, onUpdateWait = 0, 0.25
local function onUpdateHealth(self, elapsed)
	if onUpdateElapsed > onUpdateWait then
		Path(self.__owner, 'OnUpdate', self.__owner.unit)

		onUpdateElapsed = 0
	else
		onUpdateElapsed = onUpdateElapsed + elapsed
	end
end

local function SetHealthUpdateSpeed(self, state)
	onUpdateWait = state
end

local function SetHealthUpdateMethod(self, state, force)
	if self.effectiveHealth ~= state or force then
		self.effectiveHealth = state

		if state then
			self.Health:SetScript('OnUpdate', onUpdateHealth)
			self:UnregisterEvent('UNIT_HEALTH_FREQUENT', Path)
			self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		else
			self.Health:SetScript('OnUpdate', nil)
			self:RegisterEvent('UNIT_HEALTH_FREQUENT', Path)
			self:RegisterEvent('UNIT_MAXHEALTH', Path)
		end
	end
end
-- end block

local function Enable(self, unit)
	local element = self.Health
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.SetColorDisconnected = SetColorDisconnected
		element.SetColorTapping = SetColorTapping

		-- ElvUI changed block
		self.SetHealthUpdateSpeed = SetHealthUpdateSpeed
		self.SetHealthUpdateMethod = SetHealthUpdateMethod
		SetHealthUpdateMethod(self, self.effectiveHealth, true)
		-- end block

		if(element.colorDisconnected) then
			self:RegisterEvent('UNIT_CONNECTION', ColorPath)
			self:RegisterEvent('PARTY_MEMBER_ENABLE', ColorPath)
			self:RegisterEvent('PARTY_MEMBER_DISABLE', ColorPath)
		end

		if(element.colorTapping) then
			self:RegisterEvent('UNIT_FACTION', ColorPath)
		end

		if(element:IsObjectType('StatusBar') and not element:GetStatusBarTexture()) then
			element:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Health
	if(element) then
		element:Hide()

		element:SetScript('OnUpdate', nil) -- ElvUI changed
		self:UnregisterEvent('UNIT_HEALTH_FREQUENT', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)

		self:UnregisterEvent('UNIT_CONNECTION', ColorPath)
		self:UnregisterEvent('UNIT_FACTION', ColorPath)
		self:UnregisterEvent('PARTY_MEMBER_ENABLE', ColorPath)
		self:UnregisterEvent('PARTY_MEMBER_DISABLE', ColorPath)
	end
end

oUF:AddElement('Health', Path, Enable, Disable)
