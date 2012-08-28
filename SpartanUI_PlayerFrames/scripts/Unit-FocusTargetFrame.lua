local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

addon.focustarget = oUF:Spawn("focustarget","SUI_FocusTargetFrame");
addon.focustarget:SetPoint("TOPLEFT", "SUI_FocusFrame", "TOPRIGHT", -51, 0);