---@class LibAT.Locales
local LibAT = _G.LibAT
if not LibAT then return end

-- Basic localization for LibAT (Phase 1)
-- Phase 5 will implement full localization system

local L = {}

-- Error Display
L["Options"] = "Options"
L["Auto popup on errors"] = "Auto popup on errors"
L["Chat frame output"] = "Chat frame output"
L["Font Size"] = "Font Size"
L["Reset to Defaults"] = "Reset to Defaults"
L["Show Minimap Icon"] = "Show Minimap Icon"
L["Session: %d"] = "Session: %d"
L["No errors"] = "No errors"
L["You have no errors, yay!"] = "You have no errors, yay!"
L["All Errors"] = "All Errors"
L["Current Session"] = "Current Session"
L["Previous Session"] = "Previous Session"
L["< Previous"] = "< Previous"
L["Next >"] = "Next >"
L["Easy Copy All"] = "Easy Copy All"
L["Clear all errors"] = "Clear all errors"
L["BugGrabber is required for LibAT error handling."] = "BugGrabber is required for LibAT error handling."
L["LibAT Error"] = "LibAT Error"
L["New error captured. Type /libat errors to view."] = "New error captured. Type /libat errors to view."
L["|cffffffffLibAT|r: All stored errors have been wiped."] = "|cffffffffLibAT|r: All stored errors have been wiped."

-- General
L["LibAT"] = "LibAT"
L["Addon Tools"] = "Addon Tools"

-- Store in LibAT namespace
LibAT.L = L

return L