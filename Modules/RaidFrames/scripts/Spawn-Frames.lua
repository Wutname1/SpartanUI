local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local RaidFrames = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------

function RaidFrames:UpdateRaidPosition()
	RaidFrames.offset = DB.yoffset
	if DBMod.RaidFrames.moved then
		spartan.RaidFrames:SetMovable(true);
		spartan.RaidFrames:SetUserPlaced(false);
	else
		spartan.RaidFrames:SetMovable(false);
	end
	if not DBMod.RaidFrames.moved then
		spartan.RaidFrames:ClearAllPoints();
		if spartan:GetModule("PartyFrames",true) then
			spartan.RaidFrames:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(RaidFrames.offset));
		else
			spartan.RaidFrames:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(RaidFrames.offset));
		end
	else
		local Anchors = {}
		for k,v in pairs(DBMod.RaidFrames.Anchors) do
			Anchors[k] = v;
		end
		spartan.RaidFrames:ClearAllPoints();
		spartan.RaidFrames:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs);
	end
end

function RaidFrames:UpdateRaid(event,...)
	if spartan.RaidFrames == nil then return end
	
	if DBMod.RaidFrames.showRaid and IsInRaid() then
		spartan.RaidFrames:Show();
	else
		spartan.RaidFrames:Hide();
	end
	RaidFrames:UpdateRaidPosition()
	
	spartan.RaidFrames:SetAttribute('showRaid',DBMod.RaidFrames.showRaid);
	spartan.RaidFrames:SetAttribute('showParty',DBMod.RaidFrames.showParty);
	spartan.RaidFrames:SetAttribute('showPlayer',DBMod.RaidFrames.showPlayer);
	spartan.RaidFrames:SetAttribute('showSolo',DBMod.RaidFrames.showSolo);
	spartan.RaidFrames:SetAttribute('groupBy',DBMod.RaidFrames.mode);
	
	spartan.RaidFrames:SetAttribute('maxColumns', DBMod.RaidFrames.maxColumns);
	spartan.RaidFrames:SetAttribute('unitsPerColumn', DBMod.RaidFrames.unitsPerColumn);
	spartan.RaidFrames:SetAttribute('columnSpacing', DBMod.RaidFrames.columnSpacing);
		
	spartan.RaidFrames:SetScale(DBMod.RaidFrames.scale);
end

function RaidFrames:OnEnable()
	if DBMod.RaidFrames.HideBlizzFrames and CompactRaidFrameContainer ~= nil then
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:Hide()

		local function hideRaid()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if( InCombatLockdown() ) then return end
			local shown = CompactRaidFrameManager_GetSetting("IsShown")
			if( shown and shown ~= "0" ) then
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end
		end

		hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
			hideRaid()
		end)

		hideRaid();
		CompactRaidFrameContainer:HookScript("OnShow", hideRaid)
	end
	
	if (DBMod.RaidFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		spartan.RaidFrames = spartan:GetModule("Style_" .. DBMod.Artwork.Style):RaidFrames();
	elseif (DBMod.RaidFrames.Style == "Classic") or (DBMod.Artwork.Style == "Classic") then
		spartan.RaidFrames = RaidFrames:Classic()
	elseif (DBMod.RaidFrames.Style == "plain") then
		spartan.RaidFrames = RaidFrames:Plain();
	else
		spartan.RaidFrames = spartan:GetModule("Style_" .. DBMod.RaidFrames.Style):RaidFrames();
	end
	
	spartan.RaidFrames.mover = CreateFrame("Frame");
	spartan.RaidFrames.mover:SetSize(20, 20);
	spartan.RaidFrames.mover:SetPoint("TOPLEFT",spartan.RaidFrames,"TOPLEFT");
	spartan.RaidFrames.mover:SetPoint("BOTTOMRIGHT",spartan.RaidFrames,"BOTTOMRIGHT");
	spartan.RaidFrames.mover:EnableMouse(true);
	spartan.RaidFrames.mover:SetFrameStrata("LOW");
	
	spartan.RaidFrames:EnableMouse(enable)
	spartan.RaidFrames:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			spartan.RaidFrames.mover:Show();
			DBMod.RaidFrames.moved = true;
			spartan.RaidFrames:SetMovable(true);
			spartan.RaidFrames:StartMoving();
		end
	end);
	spartan.RaidFrames:SetScript("OnMouseUp",function(self,button)
		spartan.RaidFrames.mover:Hide();
		spartan.RaidFrames:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = spartan.RaidFrames:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.RaidFrames.Anchors[k] = v
		end
	end);
	
	spartan.RaidFrames.mover.bg = spartan.RaidFrames.mover:CreateTexture(nil,"BACKGROUND");
	spartan.RaidFrames.mover.bg:SetAllPoints(spartan.RaidFrames.mover);
	spartan.RaidFrames.mover.bg:SetTexture(1,1,1,0.5);
	
	spartan.RaidFrames.mover:SetScript("OnEvent",function()
		RaidFrames.locked = 1;
		spartan.RaidFrames.mover:Hide();
	end);
	spartan.RaidFrames.mover:RegisterEvent("VARIABLES_LOADED");
	spartan.RaidFrames.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	spartan.RaidFrames.mover:Hide();
	
	local raidWatch = CreateFrame("Frame");
	raidWatch:RegisterEvent('GROUP_ROSTER_UPDATE');
	raidWatch:RegisterEvent('PLAYER_ENTERING_WORLD');
	
	raidWatch:SetScript('OnEvent',function(self,event,...)
		if(InCombatLockdown()) then
			self:RegisterEvent('PLAYER_REGEN_ENABLED');
		else
			self:UnregisterEvent('PLAYER_REGEN_ENABLED');
			RaidFrames:UpdateRaid(event);
		end
	end);
end 