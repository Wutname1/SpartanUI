local addon = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local module = addon:NewModule("Buffframe");
local minimap = addon:GetModule("Minimap");
----------------------------------------------------------------------------------------------------
function module:OnInitialize()
	addon.optionsGeneral.args["BuffSettings"] = {
		name = "Buff Settings",
		desc = "configure Buff Settings",
		type = "group", args = {
			enabled = {name= "Enable Buff offset",type="toggle",width="full",order = 1,
				desc= "Enabled the offset (moving) of the stock blizzard buffs",
				get = function(info) return DB.BuffSettings.enabled; end,
				set = function(info,val)
					DB.BuffSettings.enabled = val;
					if val == true then module:UpdateBuffPosition(); end
				end
			},
			disableblizz = {name= "Hide Blizzard buffs",type="toggle",width="full",order = 1,
				desc= "Enabled the offset (moving) of the stock blizzard buffs",
				get = function(info) return DB.BuffSettings.disableblizz; end,
				set = function(info,val)
					DB.BuffSettings.disableblizz = val;
					if val == true then module:UpdateBuffPosition(); end
				end
			},
			offset = {name = "Configure Offset", type = "range", order = 2,
				desc = "offsets the bottom bar automatically, or set value",
				width="double", min=0, max=200, step=.1,
				get = function(info) return DB.BuffSettings.offset; end,
				set = function(info,val)
					if DB.BuffSettings.Manualoffset == true then DB.BuffSettings.offset = val; end
				end
			},
			ManualOffset = {name="Manual Offset", type="toggle", order = 3,
				get	= function(info) return DB.BuffSettings.Manualoffset; end,
				set = function(info,val)
					DB.BuffSettings.Manualoffset = val;
					if val ~= true then
						DB.BuffSettings.offset = module:updateBuffOffset();
						module:UpdateBuffPosition();
					end
				end
			},
		}
	}
end

function module:OnEnable()
	if DB.BuffSettings.enabled then
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
				module:updateBuffOffset()
				module:UpdateBuffPosition()
				self.TimeSinceLastUpdate = 0
			end
		end);
	end
end

function module:UpdateBuffPosition()
	if DB.BuffSettings.enabled then
		if minimap.handleBuff then
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",-13,-13-(DB.BuffSettings.offset));
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		else
			BuffFrame:ClearAllPoints();
			BuffFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(DB.BuffSettings.offset))
			ConsolidatedBuffs:ClearAllPoints();
			ConsolidatedBuffs:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-205,-13-(DB.BuffSettings.offset))
			if (ConsolidatedBuffs:IsVisible()) then
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",-5,0);
			else
				TemporaryEnchantFrame:SetPoint("TOPRIGHT","ConsolidatedBuffs","TOPLEFT",30,0);
			end
		end
	end
	if DB.BuffSettings.disableblizz then
		BuffFrame:UnregisterEvent("UNIT_AURA")
		BuffFrame:Hide()
		ConsolidatedBuffs:Hide()
		TemporaryEnchantFrame:Hide()
	elseif not BuffFrame:IsVisible() and not DB.BuffSettings.disableblizz then
		BuffFrame:RegisterEvent("UNIT_AURA")
		BuffFrame:Show()
		BuffFrame_Update()
		TemporaryEnchantFrame:Show()
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
			if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
			--if point == "RIGHT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end-- bottom bars
		end
	end
		
	TitanBarOrder = {[1]="Bar", [2]="Bar2"} -- Top 2 bar names
	for i=1,2 do
		if (_G["Titan_Bar__Display_"..TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i].."_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_"..TitanBarOrder[i]]
			titan = titan + (PanelScale * bar:GetHeight());
		end
	end
	
	offset = max(fubar + titan + ChocolateBar,1);
	DB.BuffSettings.offset = offset
	return offset;
end