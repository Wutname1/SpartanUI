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
	
	
            local raid = oUF:SpawnHeader("oUF_Raid", nil, 'solo,party,raid',
                'showPlayer', true,
	            'showRaid', true,
		        'showParty', true,
		        'showSolo', true,
	            'xoffset', 7,
                'yOffset', 0,
	            'point', 'LEFT',
	            'groupFilter', '1,2,3,4,5,6,7,8',
	            'groupBy', 'ROLE',
	            'groupingOrder', '1,2,3,4,5,6,7,8',
				'sortMethod', 'INDEX',
	            'maxColumns', 5,
	            'unitsPerColumn', 5,
	            'columnSpacing', 6,
	            'columnAnchorPoint', 'TOP', 
		        'oUF-initialConfigFunction', [[
			        self:SetWidth(59)
		            self:SetHeight(38)
			        self:SetScale(1)
		        ]]
	        )   
 	        raid:SetPoint('LEFT', UIParent, 221, -36)
	
do -- raid header configuration
--	raid:SetPoint("TOPLEFT", 0, -26)
	raid:SetParent("SpartanUI");
	raid:SetClampedToScreen(true);
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();
end

do -- scripts to make it movable
	raid.mover = CreateFrame("Frame");
	raid.mover:SetWidth(205); raid.mover:SetHeight(332);
	raid.mover:SetPoint("TOPLEFT",raid,"TOPLEFT");
	raid.mover:EnableMouse(true);
	
	raid.bg = raid.mover:CreateTexture(nil,"BACKGROUND");
	raid.bg:SetAllPoints(raid.mover);
	raid.bg:SetTexture(1,1,1,0.5);
	
	raid.mover:SetScript("OnMouseDown",function()
		raid.isMoving = true;
		DBMod.RaidFrames.raidMoved = true;
		raid:SetMovable(true);
		raid:StartMoving();
	end);
	raid.mover:SetScript("OnMouseUp",function()
		if raid.isMoving then
			raid.isMoving = nil;
			raid:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = raid:GetPoint()
			for k,v in pairs(Anchors) do
				DBMod.RaidFrames.Anchors[k] = v
			end
			raid:SetUserPlaced(false);
		end
	end);
	raid.mover:SetScript("OnHide",function()
		raid.isMoving = nil;
		raid:StopMovingOrSizing();
		raid:SetMovable(true);
		raid:SetUserPlaced(false);
		raid:SetMovable(false);
	end);
	raid.mover:SetScript("OnEvent",function()
		addon.locked = 1;
		raid.mover:Hide();
	end);
	raid.mover:RegisterEvent("VARIABLES_LOADED");
	raid.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	addon.offset = 0;
	function addon:updatePartyOffset() -- handles SpartanUI offset based on setting or fubar / titan
		local fubar,titan,offset = 0,0;
		for i = 1,4 do
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "TOPLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		if (_G["Titan_Bar__Display_Bar"] and TitanPanelGetVar("Bar_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_Bar"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
		if (_G["Titan_Bar__Display_Bar2"] and TitanPanelGetVar("Bar2_Show")) then
			local PanelScale = TitanPanelGetVar("Scale") or 1
			local bar = _G["Titan_Bar__Display_Bar2"]
			titan = titan + (PanelScale * bar:GetHeight());
		end
		offset = max(fubar + titan,1);
		return offset;
	end
	
	function addon:UpdatePartyPosition()
		-- Debug
--		print("update")
		addon.offset = addon:updatePartyOffset()
		if DBMod.RaidFrames.raidMoved then
			raid:SetMovable(true);
			raid:SetUserPlaced(false);
		else
			raid:SetMovable(false);
		end
		-- User Moved the PartyFrame, so we shouldn't be moving it
		if not DBMod.RaidFrames.raidMoved then
			raid:ClearAllPoints();
			-- SpartanUI_PlayerFrames are loaded
			if spartan:GetModule("PlayerFrames",true) then
				raid:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(addon.offset));
			-- SpartanUI_PlayerFrames isn't loaded
			else
				raid:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(addon.offset));
			end
		else
			local Anchors = {}
			for k,v in pairs(DBMod.RaidFrames.Anchors) do
				Anchors[k] = v
			end
			raid:ClearAllPoints();
			raid:SetPoint(Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		end
	end
end

do -- hide raid frame in raid, if option enabled
	function addon:UpdateParty(event,...)

		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		raid:SetAttribute('showParty',DBMod.RaidFrames.showParty)
		raid:SetAttribute('showPlayer',DBMod.RaidFrames.showPlayer)
		raid:SetAttribute('showSolo',DBMod.RaidFrames.showSolo)

		if DBMod.RaidFrames.showParty or DBMod.RaidFrames.showSolo then
			if IsInRaid() then
				if DBMod.RaidFrames.showPartyInRaid then raid:Show() else raid:Hide() end
			elseif inParty then
					raid:Show()
			elseif DBMod.RaidFrames.showSolo then
					raid:Show()
			elseif raid:IsShown() then
					raid:Hide()
			end
		else
			raid:Hide();
		end
		
		if ( addon.offset ~= addon:updatePartyOffset() ) then addon:UpdatePartyPosition() end
	end
	
	local raidWatch = CreateFrame("Frame");
	raidWatch:RegisterEvent('PLAYER_LOGIN');
	raidWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	raidWatch:RegisterEvent('RAID_ROSTER_UPDATE');
	raidWatch:RegisterEvent('PARTY_LEADER_CHANGED');
	raidWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	raidWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	raidWatch:RegisterEvent('CVAR_UPDATE');
	raidWatch:RegisterEvent('FORCE_UPDATE'); -- Used by slash-commands
	-- Debug
--	raidWatch:RegisterAllEvents()
--	raidWatch:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
	raidWatch:SetScript('OnEvent',function(self,event,...)
		if InCombatLockdown() then
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
			return;
		end
		if (event == 'PLAYER_REGEN_ENABLED') then
			-- we aren't in combat
			self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		end
		addon:UpdateParty(event)
	end);
end