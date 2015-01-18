local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_WorkOrders");
----------------------------------------------------------------------------------------------------
local QueueMax

function module:OnEnable()
	if not DB.EnabledComponents.WorkOrders then return end
	
	QueueMax = CreateFrame('Frame', 'QueueMax', UIParent);
	QueueMax.button = CreateFrame('Button', 'MaxQueue', QueueMax, "MagicButtonTemplate");
	QueueMax.button:SetSize(100, 22);
	QueueMax.button:SetText("Start Max");
	QueueMax.button:SetScript('OnClick', function(self)
		QueueMax.button:Disable();
		QueueMax.elapsed = 0
		QueueMax:SetScript("OnUpdate", function (self, elapsed)
		self.elapsed = self.elapsed + elapsed;
		if self.elapsed > .3 then
			self.elapsed = 0;
			C_Garrison.RequestShipmentCreation();
			if self.maxShipments == C_Garrison.GetNumPendingShipments() then
				self:SetScript("OnUpdate", nil);
				QueueMax.button:Disable();
			end
		end
		end)
	end)
	
	function QueueMax:SHIPMENT_CRAFTER_OPENED (containerID)
		self:SetScript("OnUpdate", nil);
		QueueMax:Show()
		QueueMax.button:ClearAllPoints()
		QueueMax.button:SetPoint("TOPRIGHT", GarrisonCapacitiveDisplayFrame.StartWorkOrderButton, "TOPLEFT", 0, 0)
		QueueMax.button:SetPoint("BOTTOMRIGHT", GarrisonCapacitiveDisplayFrame.StartWorkOrderButton, "BOTTOMLEFT", 0, 0)
		
		--This will let us replace the Current Button
		-- GarrisonCapacitiveDisplayFrame.StartWorkOrderButton:SetScript("OnClick", function (self, event, ...)
			-- print("HAHA")
		-- end)
	end
	QueueMax:RegisterEvent("SHIPMENT_CRAFTER_OPENED");
	
	function QueueMax:SHIPMENT_CRAFTER_CLOSED ()
		QueueMax:Hide()
		self:SetScript("OnUpdate", nil);
	end
	QueueMax:RegisterEvent("SHIPMENT_CRAFTER_CLOSED");
	
	function QueueMax:SHIPMENT_CRAFTER_INFO (success, _, maxShipments, plotID)
		self.maxShipments = maxShipments;
		QueueMax.button:SetEnabled(maxShipments ~= C_Garrison.GetNumPendingShipments());
	end
	QueueMax:RegisterEvent("SHIPMENT_CRAFTER_INFO");
	
	QueueMax:SetScript("OnEvent", function (self, event, ...) if self[event] then self[event] (self, ...) end end)
	QueueMax:Hide()
end

function module:OnDisable()
	QueueMax:UnregisterEvent("SHIPMENT_CRAFTER_OPENED");
	QueueMax:UnregisterEvent("SHIPMENT_CRAFTER_CLOSED");
	QueueMax:UnregisterEvent("SHIPMENT_CRAFTER_INFO");
	QueueMax = nil
end

