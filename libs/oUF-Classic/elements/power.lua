--[[
# Element: Power Bar

Handles the updating of a status bar that displays the unit's power.

## Widget

Power - A `StatusBar` used to represent the unit's power.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Notes

A default texture will be applied if the widget is a StatusBar and doesn't have a texture or a color set.

## Options

.frequentUpdates                  - Indicates whether to use UNIT_POWER_FREQUENT instead UNIT_POWER_UPDATE to update the
                                    bar (boolean)
.useAtlas                         - Use this to let the widget use an atlas for its texture if an atlas is present in
                                    `self.colors.power` for the appropriate power type (boolean)
.smoothGradient                   - 9 color values to be used with the .colorSmooth option (table)

The following options are listed by priority. The first check that returns true decides the color of the bar.

.colorDisconnected - Use `self.colors.disconnected` to color the bar if the unit is offline (boolean)
.colorTapping      - Use `self.colors.tapping` to color the bar if the unit isn't tapped by the player (boolean)
.colorPower        - Use `self.colors.power[token]` to color the bar based on the unit's power type. This method will
                     fall-back to `:GetAlternativeColor()` if it can't find a color matching the token. If this function
                     isn't defined, then it will attempt to color based upon the alternative power colors returned by
                     [UnitPowerType](http://wowprogramming.com/docs/api/UnitPowerType.html). Finally, if these aren't
                     defined, then it will attempt to color the bar based upon `self.colors.power[type]` (boolean)
.colorClass        - Use `self.colors.class[class]` to color the bar based on unit class. `class` is defined by the
                     second return of [UnitClass](http://wowprogramming.com/docs/api/UnitClass.html) (boolean)
.colorClassNPC     - Use `self.colors.class[class]` to color the bar if the unit is a NPC (boolean)
.colorClassPet     - Use `self.colors.class[class]` to color the bar if the unit is player controlled, but not a player
                     (boolean)
.colorReaction     - Use `self.colors.reaction[reaction]` to color the bar based on the player's reaction towards the
                     unit. `reaction` is defined by the return value of
                     [UnitReaction](http://wowprogramming.com/docs/api/UnitReaction.html) (boolean)
.colorSmooth       - Use `smoothGradient` if present or `self.colors.smooth` to color the bar with a smooth gradient
                     based on the player's current power percentage (boolean)

## Sub-Widget Options

.multiplier - A multiplier used to tint the background based on the main widgets R, G and B values. Defaults to 1
              (number)[0-1]

## Examples

    -- Position and size
    local Power = CreateFrame('StatusBar', nil, self)
    Power:SetHeight(20)
    Power:SetPoint('BOTTOM')
    Power:SetPoint('LEFT')
    Power:SetPoint('RIGHT')

    -- Add a background
    local Background = Power:CreateTexture(nil, 'BACKGROUND')
    Background:SetAllPoints(Power)
    Background:SetColorTexture(1, 1, 1, .5)

    -- Options
    Power.frequentUpdates = true
    Power.colorTapping = true
    Power.colorDisconnected = true
    Power.colorPower = true
    Power.colorClass = true
    Power.colorReaction = true

    -- Make the background darker.
    Background.multiplier = .5

    -- Register it with oUF
    Power.bg = Background
    self.Power = Power
--]]

local _, ns = ...
local oUF = ns.oUF

local function UpdateColor(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power

	local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)

	local r, g, b, t, atlas
	if(element.colorDisconnected and not UnitIsConnected(unit)) then
		t = self.colors.disconnected
	elseif(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		t = self.colors.tapped
	elseif(element.colorPower) then
		t = self.colors.power[ptoken or ptype]
		if(not t) then
			if(element.GetAlternativeColor) then
				r, g, b = element:GetAlternativeColor(unit, ptype, ptoken, altR, altG, altB)
			elseif(altR) then
				r, g, b = altR, altG, altB
				if(r > 1 or g > 1 or b > 1) then
					-- BUG: As of 7.0.3, altR, altG, altB may be in 0-1 or 0-255 range.
					r, g, b = r / 255, g / 255, b / 255
				end
			end
		end

		if(element.useAtlas and t and t.atlas) then
			atlas = t.atlas
		end
	elseif(element.colorClass and UnitIsPlayer(unit)) or
		(element.colorClassNPC and not UnitIsPlayer(unit)) or
		(element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = self.colors.class[class]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		t = self.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth) then
		local adjust = 0 - (element.min or 0)
		r, g, b = self:ColorGradient((element.cur or 1) + adjust, (element.max or 1) + adjust, unpack(element.smoothGradient or self.colors.smooth))
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(atlas) then
		element:SetStatusBarAtlas(atlas)
		element:SetStatusBarColor(1, 1, 1)
	else
		element:SetStatusBarTexture(element.texture)

		if(b) then
			element:SetStatusBarColor(r, g, b)
		end
	end

	local bg = element.bg
	if(bg and b) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if(element.PostUpdateColor) then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function ColorPath(self, ...)
	--[[ Override: Power.UpdateColor(self, event, unit)
	Used to completely override the internal function for updating the widgets' colors.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	(self.Power.UpdateColor or UpdateColor) (self, ...)
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end
	local element = self.Power

	--[[ Callback: Power:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = UnitPower(unit), UnitPowerMax(unit)

	element:SetMinMaxValues(0, max)

	if not UnitIsConnected(unit) then
		element:SetValue(max)
	else
		element:SetValue(cur)
	end

	element.cur = cur
	element.min = 0
	element.max = max

	--[[ Callback: Power:PostUpdate(unit, cur, min, max)
	Called after the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	* cur  - the unit's current power value (number)
	* min  - the unit's minimum possible power value (number)
	* max  - the unit's maximum possible power value (number)
	--]]
	if(element.PostUpdate) then
		element:PostUpdate(unit, cur, 0, max)
	end
end

local function Path(self, event, ...)
	if (self.isForced and event ~= 'ElvUI_UpdateAllElements') then return end -- ElvUI changed

	--[[ Override: Power.Override(self, event, unit, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	* ...   - the arguments accompanying the event
	--]]
	(self.Power.Override or Update) (self, event, ...);

	ColorPath(self, event, ...)
end

local function ForceUpdate(element)
	Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

--[[ Power:SetColorDisconnected(state)
Used to toggle coloring if the unit is offline.

* self  - the Power element
* state - the desired state (boolean)
--]]
local function SetColorDisconnected(element, state)
	if(element.colorDisconnected ~= state) then
		element.colorDisconnected = state
		if(element.colorDisconnected) then
			element.__owner:RegisterEvent('UNIT_CONNECTION', ColorPath)
		else
			element.__owner:UnregisterEvent('UNIT_CONNECTION', ColorPath)
		end
	end
end

--[[ Power:SetColorTapping(state)
Used to toggle coloring if the unit isn't tapped by the player.

* self  - the Power element
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

--[[ Power:SetFrequentUpdates(state)
Used to toggle frequent updates.

* self  - the Power element
* state - the desired state (boolean)
--]]
local function SetFrequentUpdates(element, state)
	if(element.frequentUpdates ~= state) then
		element.frequentUpdates = state
		if(element.frequentUpdates) then
			element.__owner:UnregisterEvent('UNIT_POWER_UPDATE', Path)
			element.__owner:RegisterEvent('UNIT_POWER_FREQUENT', Path)
		else
			element.__owner:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
			element.__owner:RegisterEvent('UNIT_POWER_UPDATE', Path)
		end
	end
end

-- ElvUI changed block
local onUpdateElapsed, onUpdateWait = 0, 0.25
local function onUpdatePower(self, elapsed)
	if onUpdateElapsed > onUpdateWait then
		Path(self.__owner, 'OnUpdate', self.__owner.unit)

		onUpdateElapsed = 0
	else
		onUpdateElapsed = onUpdateElapsed + elapsed
	end
end

local function SetPowerUpdateSpeed(self, state)
	onUpdateWait = state
end

local function SetPowerUpdateMethod(self, state, force)
	if self.effectivePower ~= state or force then
		self.effectivePower = state

		if state then
			self.Power:SetScript('OnUpdate', onUpdatePower)
			self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
			self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
			self:UnregisterEvent('UNIT_MAXPOWER', Path)
		else
			self.Power:SetScript('OnUpdate', nil)
			self:RegisterEvent('UNIT_MAXPOWER', Path)
			if self.Power.frequentUpdates then
				self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
			else
				self:RegisterEvent('UNIT_POWER_UPDATE', Path)
			end
		end
	end
end
-- end block

local function Enable(self)
	local element = self.Power
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.SetColorDisconnected = SetColorDisconnected
		element.SetColorTapping = SetColorTapping
		element.SetFrequentUpdates = SetFrequentUpdates

		-- ElvUI changed block
		self.SetPowerUpdateSpeed = SetPowerUpdateSpeed
		self.SetPowerUpdateMethod = SetPowerUpdateMethod
		SetPowerUpdateMethod(self, self.effectivePower, true)
		-- end block

		if(element.colorDisconnected) then
			self:RegisterEvent('UNIT_CONNECTION', ColorPath)
		end

		if(element.colorSelection) then
			self:RegisterEvent('UNIT_FLAGS', ColorPath)
		end

		if(element.colorTapping) then
			self:RegisterEvent('UNIT_FACTION', ColorPath)
		end

		self:RegisterEvent('UNIT_DISPLAYPOWER', Path)
		self:RegisterEvent('UNIT_POWER_BAR_HIDE', Path)
		self:RegisterEvent('UNIT_POWER_BAR_SHOW', Path)

		if(element:IsObjectType('StatusBar')) then
			element.texture = element:GetStatusBarTexture() and element:GetStatusBarTexture():GetTexture() or [[Interface\TargetingFrame\UI-StatusBar]]
			element:SetStatusBarTexture(element.texture)
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Power
	if(element) then
		element:Hide()

		element:SetScript('OnUpdate', nil) -- ElvUI changed
		self:UnregisterEvent('UNIT_DISPLAYPOWER', Path)
		self:UnregisterEvent('UNIT_MAXPOWER', Path)
		self:UnregisterEvent('UNIT_POWER_BAR_HIDE', Path)
		self:UnregisterEvent('UNIT_POWER_BAR_SHOW', Path)
		self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
		self:UnregisterEvent('UNIT_POWER_UPDATE', Path)
		self:UnregisterEvent('UNIT_CONNECTION', ColorPath)
		self:UnregisterEvent('UNIT_FACTION', ColorPath)
		self:UnregisterEvent('UNIT_FLAGS', ColorPath)
	end
end

oUF:AddElement('Power', Path, Enable, Disable)
