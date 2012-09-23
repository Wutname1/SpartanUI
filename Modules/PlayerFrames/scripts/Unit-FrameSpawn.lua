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
		if DBMod.PlayerFrames.focus.moved then
			addon.focus:SetMovable(true);
			addon.focus:SetPoint("CENTER",nil,"CENTER",DBMod.PlayerFrames.focus.xOffset,DBMod.PlayerFrames.focus.yOffset);
		else
			addon.focus:SetMovable(false);
			addon.focus:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",170,110);
		end
	end
	addon:UpdateFocusPosition();
	addon.focus.UpdatePosition = addon:UpdateFocusPosition();
end

if DBMod.PlayerFrames.BossFrame.display == true then
	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = oUF:Spawn('boss'..i, 'SUI_Boss'..i)
		if i == 1 then
			if DBMod.PlayerFrames.BossFrame.moved then
				boss[i]:SetMovable(true);
				boss[i]:SetPoint("CENTER",nil,"CENTER",DBMod.PlayerFrames.BossFrame.xOffset,DBMod.PlayerFrames.BossFrame.yOffset);
			else
				boss[i]:SetMovable(false);
				boss[i]:SetPoint('TOPRIGHT', UIParent, -14, -490)
			end
		else
			boss[i]:SetPoint('BOTTOM', boss[i-1], 'TOP', 0, 62)             
		end
		boss[i]:SetSize(200, 27)
		boss[i]:SetScale(DBMod.PlayerFrames.BossFrame.scale)
	end
	function addon:UpdateBossFramePosition()
		local i = 1
		if DBMod.PlayerFrames.BossFrame.moved then
			boss[i]:SetMovable(true);
			boss[i]:SetPoint("CENTER",nil,"CENTER",DBMod.PlayerFrames.BossFrame.xOffset,DBMod.PlayerFrames.BossFrame.yOffset);
		else
			boss[i]:SetMovable(false);
			boss[i]:SetPoint('TOPRIGHT', UIParent, -14, -490)
		end
	end
end

	function addon:UpdateArenaFramePosition()
		if DBMod.PlayerFrames.focus.moved then
			addon.focus:SetMovable(true);
			addon.focus:SetPoint("CENTER",nil,"CENTER",DBMod.PlayerFrames.focus.xOffset,DBMod.PlayerFrames.focus.yOffset);
		else
			addon.focus:SetMovable(false);
			addon.focus:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",170,110);
		end
	end
-- Watch for Pet name or level changes (may not be needed any more keeping just incase)
-- local Update = function(self,event)
	-- if self.Name then self.Name:UpdateTag(self.unit); end
	-- if self.Level then self.Level:UpdateTag(self.unit); end
-- end
-- addon.pet:RegisterEvent("UNIT_PET",Update);