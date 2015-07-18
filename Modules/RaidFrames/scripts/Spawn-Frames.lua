local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local RaidFrames = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------

function RaidFrames:UpdateRaidPosition()
	RaidFrames.offset = DB.yoffset
	if DBMod.RaidFrames.moved then
		spartan.RFrame:SetMovable(true);
		spartan.RFrame:SetUserPlaced(false);
	else
		spartan.RFrame:SetMovable(false);
	end
	if not DBMod.RaidFrames.moved then
		spartan.RFrame:ClearAllPoints();
		if spartan:GetModule("PartyFrames",true) then
			spartan.RFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-140-(RaidFrames.offset));
		else
			spartan.RFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",10,-20-(RaidFrames.offset));
		end
	else
		local Anchors = {}
		for k,v in pairs(DBMod.RaidFrames.Anchors) do
			Anchors[k] = v;
		end
		spartan.RFrame:ClearAllPoints();
		spartan.RFrame:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs);
	end
end

function RaidFrames:UpdateRaid(event,...)
	if spartan.RFrame == nil then return end
	if DBMod.RaidFrames.showRaid and IsInRaid() then
		spartan.RFrame:Show();
	else
		spartan.RFrame:Hide();
	end
	RaidFrames:UpdateRaidPosition()
	spartan.RFrame:SetAttribute('showRaid',DBMod.RaidFrames.showRaid);
	spartan.RFrame:SetScale(DBMod.RaidFrames.scale);
end

function RaidFrames:OnEnable()
	if DBMod.RaidFrames.HideBlizzFrames then
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
		spartan.RFrame = spartan:GetModule("Style_" .. DBMod.Artwork.Style):RaidFrames();
	elseif (DBMod.RaidFrames.Style == "Classic") or (DBMod.Artwork.Style == "Classic") then
		spartan.RFrame = RaidFrames:Classic()
	elseif (DBMod.RaidFrames.Style == "plain") then
		spartan.RFrame = RaidFrames:Plain();
	else
		spartan.RFrame = spartan:GetModule("Style_" .. DBMod.RaidFrames.Style):RaidFrames();
	end
	
	spartan.RFrame.mover = CreateFrame("Frame");
	spartan.RFrame.mover:SetSize(20, 20);
	spartan.RFrame.mover:SetPoint("TOPLEFT",spartan.RFrame,"TOPLEFT");
	spartan.RFrame.mover:SetPoint("BOTTOMRIGHT",spartan.RFrame,"BOTTOMRIGHT");
	spartan.RFrame.mover:EnableMouse(true);
	
	spartan.RFrame.bg = spartan.RFrame.mover:CreateTexture(nil,"BACKGROUND");
	spartan.RFrame.bg:SetAllPoints(spartan.RFrame.mover);
	spartan.RFrame.bg:SetTexture(1,1,1,0.5);
	
	spartan.RFrame.mover:SetScript("OnEvent",function()
		RaidFrames.locked = 1;
		spartan.RFrame.mover:Hide();
	end);
	spartan.RFrame.mover:RegisterEvent("VARIABLES_LOADED");
	spartan.RFrame.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
	spartan.RFrame.mover:Hide();
	
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