local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("Buffframe");
local minimap = addon:GetModule("Minimap");
----------------------------------------------------------------------------------------------------
do
	module.offset = 0;
	function module:updateBuffOffset() -- handles SpartanUI offset based on setting or fubar / titan
		local fubar,titan,offset = 0,0;
		for i = 1,4 do
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); 	end
			end
		end
						
		--2012.08.05 - med - titan panel exists. Calc off set for buff frame.
		if _G["TitanPanelBarButton"] ~= nil then
			-- local fullversion = GetAddOnMetadata("Titan", "Version")
			local nTitleBarCnt = TitanPanelGetVar("DoubleBar")
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["TitanPanelBarButton"];
			local pos = TitanPanelGetVar("Position");
			-- addon:Print("height: "..bar:GetHeight());	
			-- addon:Print("pos: "..pos);	
			-- addon:Print("Addon: Titan_Panel not nil");	
				
			if nTitleBarCnt == 1 and pos == 1 then
				titan = PanelScale * bar:GetHeight();
			elseif nTitleBarCnt == 2 and pos == 1 then
				titan = PanelScale * (bar:GetHeight() * 2);
			end
			
		end
		
		offset = max(fubar + titan,1);
		-- addon:Print("fubar: "..fubar.." titan: "..titan);
		
		return offset;
	end
	
	function module:UpdateBuffPosition()
		-- Debug
--		print("update")
		module.offset = module:updateBuffOffset()
		if (minimap.handleBuff == true) then
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",-13,-13-(module.offset));
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",-13,-13-(module.offset));
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		else
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(module.offset))
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(module.offset))
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		end
	end
end

function module:OnEnable()
	local BuffHandle = CreateFrame("Frame")
	-- Fix CPU leak, use UpdateInterval
	BuffHandle.UpdateInterval = 0.5
	BuffHandle.TimeSinceLastUpdate = 0
	BuffHandle:SetScript("OnUpdate",function(self,...)
		local elapsed = select(1,...)
		self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed; 
		if (self.TimeSinceLastUpdate > self.UpdateInterval) then
			-- Debug
--			print(self.TimeSinceLastUpdate)
			if (InCombatLockdown()) then return; end
			-- this can be improved      if offset have changed then update position - no reason to constantly update the position
			module:UpdateBuffPosition()
			self.TimeSinceLastUpdate = 0
		end
	end);
end
