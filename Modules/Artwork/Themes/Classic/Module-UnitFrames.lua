local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Artwork_Classic");
----------------------------------------------------------------------------------------------------

function module:UnitFrames()
	local addon = spartan:GetModule("PlayerFrames");
	SpartanoUF:SetActiveStyle("SUI_PlayerFrames_Classic");

	addon.player = SpartanoUF:Spawn("player","SUI_PlayerFrame");
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		addon.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-80,150);
	else
		addon.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
	end
	
	addon:SetupExtras()

	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget"}

	for a,b in pairs(FramesList) do
		addon[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
	end

	do -- Position Static Frames
		
		if (SUI_FramesAnchor:GetParent() == UIParent) then
			addon.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150);
			addon.pet:SetPoint("BOTTOMRIGHT",addon.player,"BOTTOMLEFT",-10,12);
			
			addon.target:SetPoint("LEFT",addon.player,"RIGHT",100,0);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				addon.targettarget:SetPoint("BOTTOMLEFT",addon.target,"BOTTOMRIGHT",8,-11);
			else
				addon.targettarget:SetPoint("BOTTOMLEFT",addon.target,"BOTTOMRIGHT",19,15);
			end
			addon.player:SetScale(DB.scale);
			for a,b in pairs(FramesList) do
				_G["SUI_"..b.."Frame"]:SetScale(DB.scale);
			end
		else
			addon.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
			addon.pet:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-370,12);
			addon.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				addon.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15);
			else
				addon.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12);
			end
		end
		
		addon.focustarget:SetPoint("TOPLEFT", "SUI_focusFrame", "TOPRIGHT", -51, 0);
	end

	addon:UpdateFocusPosition();

	if DBMod.PlayerFrames.BossFrame.display == true then
		local boss = {}
		for i = 1, MAX_BOSS_FRAMES do
			boss[i] = SpartanoUF:Spawn('boss'..i, 'SUI_Boss'..i)
			if i == 1 then
				boss[i]:SetMovable(true);
				if DBMod.PlayerFrames.BossFrame.movement.moved then
					boss[i]:SetPoint(DBMod.PlayerFrames.BossFrame.movement.point,
					DBMod.PlayerFrames.BossFrame.movement.relativeTo,
					DBMod.PlayerFrames.BossFrame.movement.relativePoint,
					DBMod.PlayerFrames.BossFrame.movement.xOffset,
					DBMod.PlayerFrames.BossFrame.movement.yOffset);
				else
					boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				end
			else
				boss[i]:SetPoint('TOP', boss[i-1], 'BOTTOM', 0, -10)             
			end
		end
		
		boss.mover = CreateFrame("Frame");
		boss.mover:SetSize(5, 5);
		boss.mover:SetPoint("TOPLEFT",SUI_Boss1,"TOPLEFT");
		boss.mover:SetPoint("TOPRIGHT",SUI_Boss1,"TOPRIGHT");
		boss.mover:SetPoint("BOTTOMLEFT",'SUI_Boss'..MAX_BOSS_FRAMES,"BOTTOMLEFT");
		boss.mover:SetPoint("BOTTOMRIGHT",'SUI_Boss'..MAX_BOSS_FRAMES,"BOTTOMRIGHT");
		boss.mover:EnableMouse(true);
		
		boss.bg = boss.mover:CreateTexture(nil,"BACKGROUND");
		boss.bg:SetAllPoints(boss.mover);
		boss.bg:SetTexture(1,1,1,0.5);
		
		boss.mover:Hide();
		boss.mover:RegisterEvent("VARIABLES_LOADED");
		boss.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
		
		function addon:UpdateBossFramePosition()
			if DBMod.PlayerFrames.BossFrame.movement.moved then
				SUI_Boss1:SetPoint(DBMod.PlayerFrames.BossFrame.movement.point,
				DBMod.PlayerFrames.BossFrame.movement.relativeTo,
				DBMod.PlayerFrames.BossFrame.movement.relativePoint,
				DBMod.PlayerFrames.BossFrame.movement.xOffset,
				DBMod.PlayerFrames.BossFrame.movement.yOffset);
			else
				SUI_Boss1:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', -50, -490)
			end
		end
		
		addon.boss = boss;
		
	end
end

