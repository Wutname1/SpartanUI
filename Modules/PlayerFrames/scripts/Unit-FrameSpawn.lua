local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget"}

for a,b in pairs(FramesList) do
	addon[b] = oUF:Spawn(b,"SUI_"..b.."Frame");
end

do -- Position Static Frames
	addon.pet:SetPoint("BOTTOMRIGHT",SpartanUI,"TOP",-370,12);
	addon.target:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",72,-3);
	addon.focustarget:SetPoint("TOPLEFT", "SUI_focusFrame", "TOPRIGHT", -51, 0);
	
	if DBMod.PlayerFrames.targettarget.style == "small" then
		addon.targettarget:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",360,-15);
	else
		addon.targettarget:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",370,12);
	end
end

do -- Setup Dynamic Position
	function addon:UpdateFocusPosition()
		if DBMod.PlayerFrames.focusMoved then
			addon.focus:SetMovable(true);
		else
			addon.focus:SetMovable(false);
			addon.focus:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",170,110);
		end
	end
	addon:UpdateFocusPosition();
	addon.focus.UpdatePosition = addon:UpdateFocusPosition();
end

-- Watch for Pet name or level changes (may not be needed any more keeping just incase)
-- local Update = function(self,event)
	-- if self.Name then self.Name:UpdateTag(self.unit); end
	-- if self.Level then self.Level:UpdateTag(self.unit); end
-- end
-- addon.pet:RegisterEvent("UNIT_PET",Update);