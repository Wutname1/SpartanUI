local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_RaidFrames");

-- local raid = oUF:SpawnHeader("oUF_Raid", nil, visible,
	-- "showRaid", true,  
	-- "showPlayer", true,
	-- "showSolo", true,
	-- "showParty", true,
	-- "xoffset", 4,
	-- "yOffset", 4,
	-- "groupBy", "ROLE",
	-- "groupingOrder", "NONE, TANK, DAMAGER, HEALER",
	-- "sortMethod", "NAME",
	-- "maxColumns", "4",
	-- "sortDir", "ASC",
	-- "unitsPerColumn", 3,
	-- "columnSpacing", 4,
	-- "point", "LEFT",
	-- "columnAnchorPoint", "TOP");
	-- raid:SetPoint("TOPLEFT", "UIParent", "BOTTOM", -156, 177)

raid = oUF:SpawnHeader("SUI_RaidFrameHeader", nil, 'raid',
	'showPlayer', true,
	'showRaid', true,
	'showParty', false,
	'showSolo', false,
	'xoffset', 7,
	'yOffset', 0,
	'point', 'LEFT',
	'groupFilter', '1,2,3,4,5,6,7,8',
	'groupBy', 'ROLE',
	'groupingOrder', 'MAINTANK,MAINASSIST,1,2,3,4,5,6,7,8',
	'sortMethod', 'INDEX',
	'maxColumns', 12,
	'unitsPerColumn', 5,
	'columnSpacing', 5,
	'columnAnchorPoint', 'TOP'
)   
raid:SetPoint('LEFT', UIParent, 20, -40)
	
do -- raid header configuration
--	raid:SetPoint("TOPLEFT", 0, -26)
	raid:SetParent("SpartanUI");
	raid:SetClampedToScreen(true);
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:Hide()
	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer:Hide()
end

do -- scripts to make it movable
	raid.mover = CreateFrame("Frame");
	raid.mover:SetSize(205, 332);
	raid.mover:SetPoint("TOPLEFT",raid,"TOPLEFT");
	raid.mover:EnableMouse(true);
	
	raid.bg = raid.mover:CreateTexture(nil,"BACKGROUND");
	raid.bg:SetAllPoints(raid.mover);
	raid.bg:SetTexture(1,1,1,0.5);
	
	raid.mover:SetScript("OnEvent",function()
		addon.locked = 1;
		raid.mover:Hide();
	end);
	raid.mover:RegisterEvent("VARIABLES_LOADED");
	raid.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	function addon:UpdatePartyPosition()
		addon.offset = DB.yoffset
		if DBMod.RaidFrames.moved then
			raid:SetMovable(true);
			raid:SetUserPlaced(false);
		else
			raid:SetMovable(false);
		end
		-- User Moved the RaidFrame, so we shouldn't be moving it
		if not DBMod.RaidFrames.moved then
			raid:ClearAllPoints();
			if spartan:GetModule("RaidFrames",true) then
				raid:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(addon.offset));
			else
				raid:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(addon.offset));
			end
		else
			local Anchors = {}
			for k,v in pairs(DBMod.RaidFrames.Anchors) do
				Anchors[k] = v
			end
			raid:ClearAllPoints();
			raid:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		end
	end
end