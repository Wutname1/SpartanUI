local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PlayerFrames = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------

function PlayerFrames:SUI_PlayerFrames_Classic()
	SpartanoUF:SetActiveStyle("SUI_PlayerFrames_Classic");

	PlayerFrames.player = SpartanoUF:Spawn("player","SUI_PlayerFrame");
	PlayerFrames:SetupExtras()

	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget"}

	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
	end

	do -- Position Static Frames
		if (SUI_FramesAnchor:GetParent() == UIParent) then
			PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150);
			PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12);
			
			PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11);
			else
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",19,15);
			end
			PlayerFrames.player:SetScale(DB.scale);
			for a,b in pairs(FramesList) do
				_G["SUI_"..b.."Frame"]:SetScale(DB.scale);
			end
		else
			PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
			PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12);
			PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15);
			else
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12);
			end
		end
		
		PlayerFrames.focustarget:SetPoint("TOPLEFT", "SUI_focusFrame", "TOPRIGHT", -51, 0);
	end

	PlayerFrames:UpdateFocusPosition();

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
		
		function PlayerFrames:UpdateBossFramePosition()
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
		
		PlayerFrames.boss = boss;
		
	end

end

function PlayerFrames:SUI_PlayerFrames_Plain()
	SpartanoUF:SetActiveStyle("SUI_PlayerFrames_Plain");
	
	PlayerFrames.player = SpartanoUF:Spawn("player","SUI_PlayerFrame");
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-80,150);
	else
		PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
	end
	
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget"}

	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
	end
	do -- Position Static Frames
		if (SUI_FramesAnchor:GetParent() == UIParent) then
			PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150);
			PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-10,12);
			
			PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11);
			else
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",19,15);
			end
			PlayerFrames.player:SetScale(DB.scale);
			for a,b in pairs(FramesList) do
				_G["SUI_"..b.."Frame"]:SetScale(DB.scale);
			end
		else
			PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
			PlayerFrames.pet:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-370,12);
			PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3);
			if DBMod.PlayerFrames.targettarget.style == "small" then
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15);
			else
				PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12);
			end
		end
		
		PlayerFrames.focustarget:SetPoint("TOPLEFT", "SUI_focusFrame", "TOPRIGHT", -51, 0);
	end
end

function PlayerFrames:OnEnable()
	if (DBMod.PlayerFrames.Style == "theme") and (DBMod.Artwork.Style ~= "Classic") then
		spartan:GetModule("Style_" .. DBMod.Artwork.Style):PlayerFrames();
	elseif (DBMod.PlayerFrames.Style == "Classic") or (DBMod.Artwork.Style == "Classic") then
		PlayerFrames:SUI_PlayerFrames_Classic();
	elseif (DBMod.PlayerFrames.Style == "plain") then
		PlayerFrames:SUI_PlayerFrames_Plain();
	else
		spartan:GetModule("Style_" .. DBMod.PlayerFrames.Style):PlayerFrames();
	end
end