---@diagnostic disable: duplicate-set-field
--[===[ File: Display/AnimationManager.lua
LibsDataBar Animation Framework
Smooth UI transitions and visual feedback system
--]===]

-- Get the LibsDataBar addon
local LibsDataBar = LibStub('AceAddon-3.0'):GetAddon('LibsDataBar', true)
if not LibsDataBar then return end

-- Local references for performance
local _G = _G
local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs
local math = math
local GetTime = GetTime

---@class AnimationManager
---@field animations table<string, Animation> Active animations
---@field presets table<string, AnimationPreset> Animation presets
---@field framePool table<Frame> Reusable animation frames
local AnimationManager = {}
AnimationManager.__index = AnimationManager

-- Initialize AnimationManager for LibsDataBar
LibsDataBar.animations = LibsDataBar.animations or setmetatable({
	animations = {},
	presets = {},
	framePool = {},
}, AnimationManager)

---@class Animation
---@field id string Animation identifier
---@field target Frame Target frame to animate
---@field startTime number Animation start time
---@field duration number Animation duration in seconds
---@field properties table Properties to animate
---@field easing string Easing function name
---@field onComplete function Completion callback
---@field onUpdate function Update callback

---@class AnimationPreset
---@field duration number Default duration
---@field easing string Default easing function
---@field properties table Default properties to animate

-- Animation presets for common UI transitions
local ANIMATION_PRESETS = {
	fadeIn = {
		duration = 0.3,
		easing = 'easeOut',
		properties = {
			alpha = { from = 0, to = 1 },
		},
	},

	fadeOut = {
		duration = 0.2,
		easing = 'easeIn',
		properties = {
			alpha = { from = 1, to = 0 },
		},
	},

	slideInBottom = {
		duration = 0.4,
		easing = 'easeOutBack',
		properties = {
			alpha = { from = 0, to = 1 },
			y = { from = -50, to = 0, relative = true },
		},
	},

	slideInTop = {
		duration = 0.4,
		easing = 'easeOutBack',
		properties = {
			alpha = { from = 0, to = 1 },
			y = { from = 50, to = 0, relative = true },
		},
	},

	highlight = {
		duration = 0.15,
		easing = 'easeOut',
		properties = {
			alpha = { from = 0, to = 0.3 },
		},
	},

	bounce = {
		duration = 0.6,
		easing = 'easeOutBounce',
		properties = {
			scale = { from = 0.8, to = 1.0 },
		},
	},

	pulse = {
		duration = 1.0,
		easing = 'easeInOut',
		properties = {
			alpha = { from = 1, to = 0.5, loop = true },
		},
	},
}

-- Easing functions for smooth animations
local EASING_FUNCTIONS = {
	linear = function(t)
		return t
	end,

	easeIn = function(t)
		return t * t
	end,
	easeOut = function(t)
		return 1 - (1 - t) * (1 - t)
	end,
	easeInOut = function(t)
		return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
	end,

	easeOutBack = function(t)
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end,

	easeOutBounce = function(t)
		local n1 = 7.5625
		local d1 = 2.75

		if t < 1 / d1 then
			return n1 * t * t
		elseif t < 2 / d1 then
			t = t - 1.5 / d1
			return n1 * t * t + 0.75
		elseif t < 2.5 / d1 then
			t = t - 2.25 / d1
			return n1 * t * t + 0.9375
		else
			t = t - 2.625 / d1
			return n1 * t * t + 0.984375
		end
	end,
}

---Initialize the animation manager
function AnimationManager:Initialize()
	-- Register animation presets
	for presetId, presetData in pairs(ANIMATION_PRESETS) do
		self.presets[presetId] = presetData
	end

	-- Create update frame
	if not self.updateFrame then
		self.updateFrame = CreateFrame('Frame')
		self.updateFrame:SetScript('OnUpdate', function()
			self:Update()
		end)
	end

	LibsDataBar:DebugLog('info', 'AnimationManager initialized with ' .. self:GetPresetCount() .. ' presets')
end

---Start an animation
---@param target Frame Target frame to animate
---@param preset string|table Animation preset name or custom config
---@param options? table Optional animation overrides
---@return string animationId Unique animation identifier
function AnimationManager:Animate(target, preset, options)
	if not target then
		LibsDataBar:DebugLog('error', 'Animation target is required')
		return ''
	end

	local animationId = 'anim_' .. tostring(target) .. '_' .. GetTime()
	local config

	-- Get configuration from preset or use custom
	if type(preset) == 'string' then
		config = self.presets[preset]
		if not config then
			LibsDataBar:DebugLog('error', 'Animation preset not found: ' .. preset)
			return ''
		end
	else
		config = preset
	end

	-- Apply options overrides
	if options then config = self:MergeConfig(config, options) end

	-- Create animation object
	local animation = {
		id = animationId,
		target = target,
		startTime = GetTime(),
		duration = config.duration or 0.3,
		properties = config.properties or {},
		easing = config.easing or 'easeOut',
		onComplete = config.onComplete,
		onUpdate = config.onUpdate,
		startValues = {},
	}

	-- Store initial values
	for prop, propConfig in pairs(animation.properties) do
		animation.startValues[prop] = self:GetFrameProperty(target, prop)
	end

	-- Register animation
	self.animations[animationId] = animation

	LibsDataBar:DebugLog('debug', 'Started animation: ' .. animationId)
	return animationId
end

---Stop an animation
---@param animationId string Animation identifier
---@param complete? boolean Whether to jump to final state
function AnimationManager:StopAnimation(animationId, complete)
	local animation = self.animations[animationId]
	if not animation then return end

	if complete then
		-- Jump to final state
		for prop, propConfig in pairs(animation.properties) do
			local finalValue = propConfig.to
			self:SetFrameProperty(animation.target, prop, finalValue)
		end
	end

	-- Call completion callback
	if animation.onComplete then animation.onComplete(animation.target, complete) end

	-- Remove from active animations
	self.animations[animationId] = nil

	LibsDataBar:DebugLog('debug', 'Stopped animation: ' .. animationId)
end

---Update all active animations
function AnimationManager:Update()
	local currentTime = GetTime()
	local toRemove = {}

	for animationId, animation in pairs(self.animations) do
		local elapsed = currentTime - animation.startTime
		local progress = math.min(elapsed / animation.duration, 1)

		-- Apply easing
		local easingFunc = EASING_FUNCTIONS[animation.easing] or EASING_FUNCTIONS.linear
		local easedProgress = easingFunc(progress)

		-- Update properties
		for prop, propConfig in pairs(animation.properties) do
			local startValue = animation.startValues[prop] or propConfig.from or 0
			local endValue = propConfig.to or startValue
			local currentValue = startValue + (endValue - startValue) * easedProgress

			-- Handle relative values
			if propConfig.relative then currentValue = startValue + (propConfig.from or 0) + ((propConfig.to or 0) - (propConfig.from or 0)) * easedProgress end

			self:SetFrameProperty(animation.target, prop, currentValue)
		end

		-- Call update callback
		if animation.onUpdate then animation.onUpdate(animation.target, easedProgress) end

		-- Check if animation is complete
		if progress >= 1 then tinsert(toRemove, animationId) end
	end

	-- Remove completed animations
	for _, animationId in ipairs(toRemove) do
		self:StopAnimation(animationId, true)
	end
end

---Get a frame property value
---@param frame Frame Target frame
---@param property string Property name
---@return number value Property value
function AnimationManager:GetFrameProperty(frame, property)
	if property == 'alpha' then
		return frame:GetAlpha()
	elseif property == 'x' then
		return frame:GetLeft() or 0
	elseif property == 'y' then
		return frame:GetBottom() or 0
	elseif property == 'scale' then
		return frame:GetScale()
	elseif property == 'width' then
		return frame:GetWidth()
	elseif property == 'height' then
		return frame:GetHeight()
	end
	return 0
end

---Set a frame property value
---@param frame Frame Target frame
---@param property string Property name
---@param value number Property value
function AnimationManager:SetFrameProperty(frame, property, value)
	if property == 'alpha' then
		frame:SetAlpha(value)
	elseif property == 'x' then
		local _, _, relativePoint, oldX, y = frame:GetPoint()
		frame:ClearAllPoints()
		frame:SetPoint('BOTTOMLEFT', UIParent, relativePoint or 'BOTTOMLEFT', value, y or 0)
	elseif property == 'y' then
		local point, _, relativePoint, x, _ = frame:GetPoint()
		frame:ClearAllPoints()
		frame:SetPoint(point or 'BOTTOMLEFT', UIParent, relativePoint or 'BOTTOMLEFT', x or 0, value)
	elseif property == 'scale' then
		frame:SetScale(value)
	elseif property == 'width' then
		frame:SetWidth(value)
	elseif property == 'height' then
		frame:SetHeight(value)
	end
end

---Merge animation configuration
---@param base table Base configuration
---@param override table Override configuration
---@return table merged Merged configuration
function AnimationManager:MergeConfig(base, override)
	local merged = {}

	-- Copy base
	for key, value in pairs(base) do
		if type(value) == 'table' then
			merged[key] = {}
			for subkey, subvalue in pairs(value) do
				merged[key][subkey] = subvalue
			end
		else
			merged[key] = value
		end
	end

	-- Apply overrides
	for key, value in pairs(override) do
		if type(value) == 'table' and merged[key] then
			for subkey, subvalue in pairs(value) do
				merged[key][subkey] = subvalue
			end
		else
			merged[key] = value
		end
	end

	return merged
end

---Get number of animation presets
---@return number count Number of presets
function AnimationManager:GetPresetCount()
	local count = 0
	for _ in pairs(self.presets) do
		count = count + 1
	end
	return count
end

---Add custom animation preset
---@param presetId string Preset identifier
---@param config table Animation configuration
function AnimationManager:AddPreset(presetId, config)
	self.presets[presetId] = config
	LibsDataBar:DebugLog('info', 'Added animation preset: ' .. presetId)
end

---Convenience method to fade in a frame
---@param frame Frame Target frame
---@param duration? number Animation duration
---@param callback? function Completion callback
---@return string animationId Animation identifier
function AnimationManager:FadeIn(frame, duration, callback)
	return self:Animate(frame, 'fadeIn', {
		duration = duration,
		onComplete = callback,
	})
end

---Convenience method to fade out a frame
---@param frame Frame Target frame
---@param duration? number Animation duration
---@param callback? function Completion callback
---@return string animationId Animation identifier
function AnimationManager:FadeOut(frame, duration, callback)
	return self:Animate(frame, 'fadeOut', {
		duration = duration,
		onComplete = callback,
	})
end

---Convenience method to slide in from bottom
---@param frame Frame Target frame
---@param duration? number Animation duration
---@param callback? function Completion callback
---@return string animationId Animation identifier
function AnimationManager:SlideInBottom(frame, duration, callback)
	return self:Animate(frame, 'slideInBottom', {
		duration = duration,
		onComplete = callback,
	})
end

---Stop all animations for a target frame
---@param frame Frame Target frame
function AnimationManager:StopAllAnimations(frame)
	local toStop = {}
	for animationId, animation in pairs(self.animations) do
		if animation.target == frame then tinsert(toStop, animationId) end
	end

	for _, animationId in ipairs(toStop) do
		self:StopAnimation(animationId)
	end
end

-- Initialize the animation manager when this file loads
if LibsDataBar.animations then LibsDataBar.animations:Initialize() end

LibsDataBar:DebugLog('info', 'AnimationManager loaded successfully')
