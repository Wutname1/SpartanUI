local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

function PartyFrames:OnEnable()
	if (DBMod.PartyFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		spartan.PartyFrame = spartan:GetModule("Style_" .. DBMod.Artwork.Style):PartyFrames();
	elseif (DBMod.PartyFrames.Style == "Classic") or (DBMod.Artwork.Style == "Classic") then
		spartan.PartyFrame = PartyFrames:Classic()
	elseif (DBMod.PartyFrames.Style == "plain") then
		spartan.PartyFrame = PartyFrames:Plain();
	else
		spartan.PartyFrame = spartan:GetModule("Style_" .. DBMod.PartyFrames.Style):PartyFrames();
	end
	
	if DB.Styles[DBMod.PartyFrames.Style].Movable.PartyFrames == true then
		spartan.PartyFrame.mover = CreateFrame("Frame");
		spartan.PartyFrame.mover:SetPoint("TOPLEFT",spartan.PartyFrame,"TOPLEFT");
		spartan.PartyFrame.mover:SetPoint("BOTTOMRIGHT",spartan.PartyFrame,"BOTTOMRIGHT");
		spartan.PartyFrame.mover:EnableMouse(true);
		spartan.PartyFrame.mover:SetFrameStrata("LOW");
		
		spartan.PartyFrame.bg = spartan.PartyFrame.mover:CreateTexture(nil,"BACKGROUND");
		spartan.PartyFrame.bg:SetAllPoints(spartan.PartyFrame.mover);
		spartan.PartyFrame.bg:SetTexture(1,1,1,0.5);
		
		spartan.PartyFrame.mover:SetScript("OnEvent",function()
			PartyFrames.locked = 1;
			spartan.PartyFrame.mover:Hide();
		end);
		spartan.PartyFrame.mover:RegisterEvent("VARIABLES_LOADED");
		spartan.PartyFrame.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
		spartan.PartyFrame.mover:Hide();
		
		spartan.PartyFrame:EnableMouse(enable)
		spartan.PartyFrame:SetScript("OnMouseDown",function(self,button)
			if button == "LeftButton" and IsAltKeyDown() then
				spartan.PartyFrame.mover:Show();
				DBMod.PartyFrames.moved = true;
				spartan.PartyFrame:SetMovable(true);
				spartan.PartyFrame:StartMoving();
			end
		end);
		spartan.PartyFrame:SetScript("OnMouseUp",function(self,button)
			spartan.PartyFrame.mover:Hide();
			spartan.PartyFrame:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = spartan.PartyFrame:GetPoint()
			for k,v in pairs(Anchors) do
				DBMod.PartyFrames.Anchors[k] = v
			end
		end);
		
		function PartyFrames:UpdatePartyPosition()
			PartyFrames.offset = DB.yoffset
			if DBMod.PartyFrames.moved then
				spartan.PartyFrame:SetMovable(true);
				spartan.PartyFrame:SetUserPlaced(false);
			else
				spartan.PartyFrame:SetMovable(false);
			end
			-- User Moved the PartyFrame, so we shouldn't be moving it
			if not DBMod.PartyFrames.moved then
				spartan.PartyFrame:ClearAllPoints();
				-- SpartanUI_PlayerFrames are loaded
				if spartan:GetModule("PlayerFrames",true) then
					spartan.PartyFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(DB.BuffSettings.offset));
				-- SpartanUI_PlayerFrames isn't loaded
				else
					spartan.PartyFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(DB.BuffSettings.offset));
				end
			else
				local Anchors = {}
				for k,v in pairs(DBMod.PartyFrames.Anchors) do
					Anchors[k] = v
				end
				spartan.PartyFrame:ClearAllPoints();
				spartan.PartyFrame:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
			end
		end
	end
	

--	spartan.PartyFrame:SetPoint("TOPLEFT", 0, -26)
	spartan.PartyFrame:SetParent("SpartanUI");
	spartan.PartyFrame:SetClampedToScreen(true);
	PartyMemberBackground.Show = function() return; end
	PartyMemberBackground:Hide();


	function PartyFrames:UpdateParty(event,...)
		local inParty = IsInGroup()  -- ( numGroupMembers () > 0 )
		local bDebug_ShowFrame = true;

		spartan.PartyFrame:SetAttribute('showParty',DBMod.PartyFrames.showParty)
		spartan.PartyFrame:SetAttribute('showPlayer',DBMod.PartyFrames.showPlayer)
		spartan.PartyFrame:SetAttribute('showSolo',DBMod.PartyFrames.showSolo)

		if DBMod.PartyFrames.showParty or DBMod.PartyFrames.showSolo then
			if IsInRaid() then
				if DBMod.PartyFrames.showPartyInRaid then spartan.PartyFrame:Show() else spartan.PartyFrame:Hide() end
			elseif inParty then
					spartan.PartyFrame:Show()
			elseif DBMod.PartyFrames.showSolo then
					spartan.PartyFrame:Show()
			elseif spartan.PartyFrame:IsShown() then
					spartan.PartyFrame:Hide()
			end
		else
			spartan.PartyFrame:Hide();
		end
		
		PartyFrames:UpdatePartyPosition()
		spartan.PartyFrame:SetScale(DBMod.PartyFrames.scale);
	end
	
	local partyWatch = CreateFrame("Frame");
	partyWatch:RegisterEvent('PLAYER_LOGIN');
	partyWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	partyWatch:RegisterEvent('RAID_ROSTER_UPDATE');
	partyWatch:RegisterEvent('PARTY_LEADER_CHANGED');
	partyWatch:RegisterEvent('PARTY_MEMBERS_CHANGED');
	partyWatch:RegisterEvent('PARTY_CONVERTED_TO_RAID');
	partyWatch:RegisterEvent('CVAR_UPDATE');
	partyWatch:RegisterEvent('PLAYER_REGEN_ENABLED');
	partyWatch:RegisterEvent('ZONE_CHANGED_NEW_AREA');
	partyWatch:RegisterEvent('FORCE_UPDATE');
	
	partyWatch:SetScript('OnEvent',function(self,event,...)
		if InCombatLockdown() then
			return;
		end
		PartyFrames:UpdateParty(event)
	end);
end