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
	
	spartan.PartyFrame.mover = CreateFrame("Frame");
	spartan.PartyFrame.mover:SetPoint("TOPLEFT",spartan.PartyFrame,"TOPLEFT");
	spartan.PartyFrame.mover:SetPoint("BOTTOMRIGHT",spartan.PartyFrame,"BOTTOMRIGHT");
	spartan.PartyFrame.mover:EnableMouse(true);
	
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