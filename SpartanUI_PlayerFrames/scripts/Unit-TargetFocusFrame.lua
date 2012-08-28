local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

local targetfocus = oUF:Spawn("focustarget","SUI_TargetFocusFrame");
addon.targetfocus = targetfocus;
addon.targetfocus:SetPoint("BOTTOMLEFT","SUI_FocusFrame","BOTTOMRIGHT",20,0);