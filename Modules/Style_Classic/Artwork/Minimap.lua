local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Classic");
---------------------------------------------------------------------------

function module:MiniMap()
	Minimap:SetSize(156, 156);
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",SpartanUI,"CENTER",0,54);
	Minimap:SetParent(SpartanUI);
	
	if Minimap.ZoneText ~= nil then
		Minimap.ZoneText:ClearAllPoints();
		Minimap.ZoneText:SetPoint("TOPLEFT",Minimap,"BOTTOMLEFT",0,-5);
		Minimap.ZoneText:SetPoint("TOPRIGHT",Minimap,"BOTTOMRIGHT",0,-5);
		Minimap.ZoneText:Hide();
		MinimapZoneText:Show();
		
		Minimap.coords:SetTextColor(1,.82,0,1);
	end
	
	-- Minimap.coords:Hide()
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	
end

function module:EnableMinimap()
	if (DB.MiniMap.AutoDetectAllowUse) or (DB.MiniMap.ManualAllowUse) then module:MiniMap() end
end
