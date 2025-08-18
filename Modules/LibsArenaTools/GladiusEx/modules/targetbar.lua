local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")

local defaults = {
	OffsetX = 0,
	OffsetY = 0,
	Height = 20,
	Width = 100,
	Inverse = false,
	Color = { r = 1, g = 1, b = 1, a = 1 },
	ClassColor = true,
	BackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
	GlobalTexture = true,
	Texture = GladiusEx.default_bar_texture,
	Icon = true,
	IconCrop = true,
}

local TargetBar = GladiusEx:NewUnitBarModule("TargetBar",
	fn.merge(defaults, {
		AttachTo = "Frame",
		RelativePoint = "TOPLEFT",
		Anchor = "BOTTOMLEFT",
		IconPosition = "LEFT",
	}),
	fn.merge(defaults, {
		AttachTo = "Frame",
		RelativePoint = "TOPRIGHT",
		Anchor = "BOTTOMRIGHT",
		IconPosition = "RIGHT",
	}))

function TargetBar:GetFrameUnit(unit)
	if unit == "player" then
		return "target", false
	else
		return unit .. "target", true
	end
end

function TargetBar:RegisterCustomEvents()
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:UNIT_TARGET("PLAYER_TARGET_CHANGED", "player") end)
end

function TargetBar:UNIT_TARGET(event, unit)
	if self.frame[unit] then
		self:Refresh(unit)
	end
end
