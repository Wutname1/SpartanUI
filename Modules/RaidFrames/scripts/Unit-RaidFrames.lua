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
	
	
            -- local raid = oUF:SpawnHeader("oUF_Raid", nil, 'solo,party,raid',
                -- 'showPlayer', true,
	            -- 'showRaid', true,
		        -- 'showParty', true,
		        -- 'showSolo', true,
	            -- 'xoffset', 7,
                -- 'yOffset', 0,
	            -- 'point', 'LEFT',
	            -- 'groupFilter', '1,2,3,4,5,6,7,8',
	            -- 'groupBy', 'ROLE',
	            -- 'groupingOrder', '1,2,3,4,5,6,7,8',
				-- 'sortMethod', 'INDEX',
	            -- 'maxColumns', 5,
	            -- 'unitsPerColumn', 5,
	            -- 'columnSpacing', 6,
	            -- 'columnAnchorPoint', 'TOP', 
		        -- 'oUF-initialConfigFunction', [[
			        -- self:SetWidth(59)
		            -- self:SetHeight(38)
			        -- self:SetScale(1)
		        -- ]]
	        -- )   
 	        -- raid:SetPoint('LEFT', UIParent, 221, -36)
	
do -- raid header configuration
--	raid:SetPoint("TOPLEFT", 0, -26)
	-- raid:SetParent("SpartanUI");
	-- raid:SetClampedToScreen(true);
	-- PartyMemberBackground.Show = function() return; end
	-- PartyMemberBackground:Hide();
end

do -- hide raid frame in raid, if option enabled
	-- function addon:UpdateParty(event,...)

		-- local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		-- local bDebug_ShowFrame = true;

		-- raid:SetAttribute('showParty',DBMod.RaidFrames.showParty)
		-- raid:SetAttribute('showPlayer',DBMod.RaidFrames.showPlayer)
		-- raid:SetAttribute('showSolo',DBMod.RaidFrames.showSolo)

		-- if DBMod.RaidFrames.showParty or DBMod.RaidFrames.showSolo then
			-- if IsInRaid() then
				-- if DBMod.RaidFrames.showPartyInRaid then raid:Show() else raid:Hide() end
			-- elseif inParty then
					-- raid:Show()
			-- elseif DBMod.RaidFrames.showSolo then
					-- raid:Show()
			-- elseif raid:IsShown() then
					-- raid:Hide()
			-- end
		-- else
			-- raid:Hide();
		-- end
		
		-- if ( addon.offset ~= addon:updatePartyOffset() ) then addon:UpdatePartyPosition() end
	-- end
	
	-- local raidWatch = CreateFrame("Frame");
	-- raidWatch:RegisterEvent('PLAYER_LOGIN');
	-- raidWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	-- raidWatch:RegisterEvent('RAID_ROSTER_UPDATE');
	-- raidWatch:RegisterEvent('PARTY_LEADER_CHANGED');
	-- raidWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	-- raidWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	-- raidWatch:RegisterEvent('CVAR_UPDATE');
	-- raidWatch:RegisterEvent('FORCE_UPDATE'); -- Used by slash-commands
	-- Debug
--	raidWatch:RegisterAllEvents()
--	raidWatch:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED');
	-- raidWatch:SetScript('OnEvent',function(self,event,...)
		-- if InCombatLockdown() then
			-- self:RegisterEvent('PLAYER_REGEN_ENABLED')
			-- return;
		-- end
		-- if (event == 'PLAYER_REGEN_ENABLED') then
			-- we aren't in combat
			-- self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		-- end
		-- addon:UpdateParty(event)
	-- end);
end