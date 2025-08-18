local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local fn = LibStub("LibFunctional-1.0")

local defaults = {
	OffsetX = 0,
	OffsetY = 0,
	Height = 20,
	Width = 100,
	Inverse = false,
	Color = { r = 0, g = 1, b = 0, a = 1 },
	ClassColor = false,
	BackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
	GlobalTexture = true,
	Texture = GladiusEx.default_bar_texture,
	Icon = false,
	IconCrop = true,
}

local PetBar = GladiusEx:NewUnitBarModule("PetBar",
	fn.merge(defaults, {
		AttachTo = "Frame",
		RelativePoint = "TOPRIGHT",
		Anchor = "BOTTOMRIGHT",
		IconPosition = "RIGHT",
	}),
	fn.merge(defaults, {
		AttachTo = "Frame",
		RelativePoint = "TOPLEFT",
		Anchor = "BOTTOMLEFT",
		IconPosition = "LEFT",
	}))

function PetBar:GetFrameUnit(unit)
	if unit == "player" then
		return "pet", false
	else
		local utype, n = strmatch(unit, "^(%a+)(%d+)$")
		return utype .. "pet" .. n, false
	end
end

function PetBar:RegisterCustomEvents()
	self:RegisterEvent("UNIT_PET")
	-- self:RegisterEvent("PLAYER_TARGET_CHANGED", function() self:UNIT_TARGET("PLAYER_TARGET_CHANGED", "player") end)
end

function PetBar:UNIT_PET(event, unit)
	if self.frame[unit] then
		self:Refresh(unit)
	end
end
