local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------

local CreateUnitFrame = function(self,unit)
	-- self.menu = menu;
	
	-- if (SUI_FramesAnchor:GetParent() == UIParent) then
		-- self:SetParent(UIParent);
	-- else
		-- self:SetParent(SUI_FramesAnchor);
	-- end
	
	-- self:SetFrameStrata("BACKGROUND"); self:SetFrameLevel(1);
	-- self:SetScript("OnEnter", UnitFrame_OnEnter);
	-- self:SetScript("OnLeave", UnitFrame_OnLeave);
	-- self:RegisterForClicks("anyup");
	-- self:SetAttribute("*type2", "menu");
	-- self.colors = addon.colors;
	
	-- return ((unit == "target" and CreateTargetFrame(self,unit))
	-- or (unit == "targettarget" and CreateToTFrame(self,unit))
	-- or (unit == "player" and CreatePlayerFrame(self,unit))
	-- or (unit == "focus" and CreateFocusFrame(self,unit))
	-- or (unit == "focustarget" and CreateFocusFrame(self,unit))
	-- or (unit == "pet" and CreatePetFrame(self,unit))
	-- or CreateBossFrame(self,unit));
end

SpartanoUF:RegisterStyle("SUI_PlayerFrames_Plain", CreateUnitFrame);