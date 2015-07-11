local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Classic");
---------------------------------------------------------------------------
local Minimap_Conflict_msg = true
local TribalArt

function module:MiniMap()
	Minimap:SetSize(140, 140);
	MinimapZoneText:Show()
	Minimap.coords:Hide()
	
	Minimap:ClearAllPoints();
	Minimap:SetPoint("CENTER",SpartanUI,"CENTER",0,50);

	Minimap.ZoneText:ClearAllPoints();
	Minimap.ZoneText:SetPoint("TOP",Minimap,"BOTTOM",5,-7);
	Minimap.ZoneText:SetTextColor(1,.82,0,1);
	
	Minimap.coords:SetTextColor(1,.82,0,1);
	
	QueueStatusFrame:ClearAllPoints();
	QueueStatusFrame:SetPoint("BOTTOM",SpartanUI,"TOP",0,100);
	
	Minimap.coords:Hide()
end

function module:EnableMinimap()
	if (DB.MiniMap.AutoDetectAllowUse) or (DB.MiniMap.ManualAllowUse) then module:MiniMap() end
end
