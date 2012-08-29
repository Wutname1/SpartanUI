local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("Buffframe");
local minimap = addon:GetModule("Minimap");
----------------------------------------------------------------------------------------------------
function module:OnInitialize()
	addon.optionsGeneral.args["BuffSettings"] = {
		name = "Buff Settings",
		desc = "configure Buff Settings",
		type = "group", args = {
			enabled = {
				name= "Enable Buff tweaks",
				type="toggle",
				width="full",
				order = 1,
				get = function(info) return addon.db.profile.BuffSettings.enabled; end,
				set = function(info,val)
					addon.db.profile.BuffSettings.enabled = val;
					if val == true then module:UpdateBuffPosition(); end
				end
			},
			offset = {name = "Configure Offset", type = "range", order = 2,
				desc = "offsets the bottom bar automatically, or set value",
				width="double", min=0, max=200, step=.1,
				get = function(info) return addon.db.profile.BuffSettings.offset; end,
				set = function(info,val)
					if addon.db.profile.BuffSettings.Manualoffset == true then addon.db.profile.BuffSettings.offset = val; end
				end
			},
			ManualOffset = {name="Manual Offset", type="toggle", order = 3,
				get	= function(info) return addon.db.profile.BuffSettings.Manualoffset; end,
				set = function(info,val)
					addon.db.profile.BuffSettings.Manualoffset = val;
					if val ~= true then
						addon.db.profile.BuffSettings.offset = module:updateBuffOffset();
						module:UpdateBuffPosition();
					end
				end
			},
			BarsEnabled = {name="Manual Offset", type="toggle", order = 3,
				get	= function(info) return addon.db.profile.BuffSettings.BarsEnabled; end,
				set = function(info,val) addon.db.profile.BuffSettings.BarsEnabled = val; end
			}
		}
	}
end

function module:OnEnable()
	if addon.db.profile.BuffSettings.enabled == true then
		local BuffHandle = CreateFrame("Frame")
		-- Fix CPU leak, use UpdateInterval
		BuffHandle.UpdateInterval = 0.5
		BuffHandle.TimeSinceLastUpdateTimeSinceLastUpdate = 0
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
end

function module:UpdateBuffPosition()
	if addon.db.profile.BuffSettings.enabled == true then
		if (minimap.handleBuff == true) then
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",-13,-13-(addon.db.profile.BuffSettings.offset));
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",-13,-13-(addon.db.profile.BuffSettings.offset));
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		else
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(addon.db.profile.BuffSettings.offset))
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(addon.db.profile.BuffSettings.offset))
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		end
	end
end

function module:updateBuffOffset() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar,titan,ChocolateBar,offset = 0,0,0;
	for i = 1,4 do
		if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
			local bar = _G["FuBarFrame"..i];
			local point = bar:GetPoint(1);
			if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); 	end
		end
	end
	for i = 1,100 do
		if (_G["ChocolateBar"..i] and _G["ChocolateBar"..i]:IsVisible()) then
			local bar = _G["ChocolateBar"..i];
			local point = bar:GetPoint(1);
			if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); 	end
			addon:Print("1");
		end
	end
	
	if _G["TitanPanelBarButton"] ~= nil then
		local nTitleBarCnt = TitanPanelGetVar("DoubleBar")
		local PanelScale = TitanPanelGetVar("Scale") or 1
		local bar = _G["TitanPanelBarButton"];
		local pos = TitanPanelGetVar("Position");
		
		if nTitleBarCnt == 1 and pos == 1 then
			titan = PanelScale * bar:GetHeight();
		elseif nTitleBarCnt == 2 and pos == 1 then
			titan = PanelScale * (bar:GetHeight() * 2);
		end
	end
	
	offset = max(fubar + titan + ChocolateBar,1);
	
	return offset;
end