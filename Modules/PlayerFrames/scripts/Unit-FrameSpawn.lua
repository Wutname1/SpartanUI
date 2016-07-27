local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PlayerFrames = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}

function PlayerFrames:SUI_PlayerFrames_Classic()
	SpartanoUF:SetActiveStyle("SUI_PlayerFrames_Classic");

	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
		if b == "player" then PlayerFrames:SetupExtras() end
	end
	
	PlayerFrames:PositionFrame_Classic()

	if DBMod.PlayerFrames.BossFrame.display == true then
		for i = 1, MAX_BOSS_FRAMES do
			PlayerFrames.boss[i] = SpartanoUF:Spawn('boss'..i, 'SUI_Boss'..i)
			if i == 1 then
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
				PlayerFrames.boss[i]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			else
				PlayerFrames.boss[i]:SetPoint('TOP', PlayerFrames.boss[i-1], 'BOTTOM', 0, -10)             
			end
		end
	end
	
end

function PlayerFrames:PositionFrame_Classic(b)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150); end
		if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12); end
		
		if b == "target" or b == nil then PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0); end
		if DBMod.PlayerFrames.targettarget.style == "small" and (b == "targettarget" or b == nil) then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11);
		elseif b == "targettarget" or b == nil then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",19,15);
		end
		
		PlayerFrames.player:SetScale(DB.scale);
		for a,b in pairs(FramesList) do
			PlayerFrames[b]:SetScale(DB.scale);
		end
	else
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3); end
		if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12); end
		if b == "target" or b == nil then PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3); end
		if DBMod.PlayerFrames.targettarget.style == "small" and (b == "targettarget" or b == nil) then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15);
		elseif b == "targettarget" or b == nil then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12);
		end
	end
	
	if b == "focus" or b == nil then PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30); end
	if b == "focustarget" or b == nil then PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", -35, 0); end
end

function PlayerFrames:AddMover(frame, framename)
	if frame == nil then
		spartan:Err("PlayerFrames", DBMod.PlayerFrames.Style .. " did not spawn " .. framename)
	else
		frame.mover = CreateFrame("Frame");
		frame.mover:SetSize(20, 20);
		
		if framename == "boss" then
			frame.mover:SetPoint("TOPLEFT",PlayerFrames.boss[1],"TOPLEFT");
			frame.mover:SetPoint("BOTTOMRIGHT",PlayerFrames.boss[MAX_BOSS_FRAMES],"BOTTOMRIGHT");
		else
			frame.mover:SetPoint("TOPLEFT",frame,"TOPLEFT");
			frame.mover:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT");
		end
		
		frame.mover:EnableMouse(true);
		frame.mover:SetFrameStrata("LOW");
		
		frame:EnableMouse(enable)
		frame:SetScript("OnMouseDown",function(self,button)
			if button == "LeftButton" and IsAltKeyDown() then
				frame.mover:Show();
				DBMod.PlayerFrames[framename].moved = true;
				frame:SetMovable(true);
				frame:StartMoving();
			end
		end);
		frame:SetScript("OnMouseUp",function(self,button)
			frame.mover:Hide();
			frame:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
			for k,v in pairs(Anchors) do
				DBMod.PlayerFrames[framename].Anchors[k] = v
			end
		end);
		
		frame.mover.bg = frame.mover:CreateTexture(nil,"BACKGROUND");
		frame.mover.bg:SetAllPoints(frame.mover);
		frame.mover.bg:SetTexture([[Interface\BlackMarket\BlackMarketBackground-Tile]]);
		frame.mover.bg:SetVertexColor(1,1,1,0.5);
		
		frame.mover:SetScript("OnEvent",function()
			PlayerFrames.locked = 1;
			frame.mover:Hide();
		end);
		frame.mover:RegisterEvent("VARIABLES_LOADED");
		frame.mover:RegisterEvent("PLAYER_REGEN_DISABLED");
		frame.mover:Hide();

		--Set Position if moved
		if DBMod.PlayerFrames[framename].moved then
			frame:SetMovable(true);
			frame:SetUserPlaced(false);
			local Anchors = {}
			for k,v in pairs(DBMod.PlayerFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints();
			frame:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			frame:SetMovable(false);
		end
	end
end

function PlayerFrames:BossMoveScripts(frame)
	frame:EnableMouse(enable)
	frame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			PlayerFrames.boss[1].mover:Show();
			DBMod.PlayerFrames.boss.moved = true;
			PlayerFrames.boss[1]:SetMovable(true);
			PlayerFrames.boss[1]:StartMoving();
		end
	end);
	frame:SetScript("OnMouseUp",function(self,button)
		PlayerFrames.boss[1].mover:Hide();
		PlayerFrames.boss[1]:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = PlayerFrames.boss[1]:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.PlayerFrames.boss.Anchors[k] = v
		end
	end);
end

function PlayerFrames:OnEnable()
	PlayerFrames.boss = {}
	if (DBMod.PlayerFrames.Style == "Classic") then
		PlayerFrames:SUI_PlayerFrames_Classic();
	else
		spartan:GetModule("Style_" .. DBMod.PlayerFrames.Style):PlayerFrames();
	end
	
	if DB.Styles[DBMod.PlayerFrames.Style].Movable.PlayerFrames == true then 
		local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
		for a,b in pairs(FramesList) do
			PlayerFrames:AddMover(PlayerFrames[b], b)
		end
		if DBMod.PlayerFrames.BossFrame.display then
			PlayerFrames:AddMover(PlayerFrames.boss[1], "boss")
			for i = 2, MAX_BOSS_FRAMES do
				if PlayerFrames.boss[i] ~= nil then
					PlayerFrames:BossMoveScripts(PlayerFrames.boss[i])
				end
			end
		end
	end
	
	PlayerFrames:SetupStaticOptions()
	PlayerFrames:UpdatePosition()
end