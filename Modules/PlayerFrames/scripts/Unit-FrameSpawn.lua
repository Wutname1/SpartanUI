local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
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
	
	local unattached = false
	SpartanUI:HookScript("OnHide", function(this, event)
		if UnitUsingVehicle("player") then
			SUI_FramesAnchor:SetParent(UIParent)
			unattached = true
		end
	end)
	
	SpartanUI:HookScript("OnShow", function(this, event)
		if unattached then
			SUI_FramesAnchor:SetParent(SpartanUI)
			PlayerFrames:PositionFrame_Classic()
		end
	end)
	
end

function PlayerFrames:PositionFrame_Classic()
	PlayerFrames.pet:SetParent(PlayerFrames.player)
	PlayerFrames.targettarget:SetParent(PlayerFrames.target)
	
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150);
		PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12);
		PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0);
		
		if DBMod.PlayerFrames.targettarget.style == "small" then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11);
		else
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",19,15);
		end
		
		for a,b in pairs(FramesList) do
			PlayerFrames[b]:SetScale(DB.scale);
		end
	else
		PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3);
		PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12)
		PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3);
		
		if DBMod.PlayerFrames.targettarget.style == "small" then
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15);
		else
			PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12);
		end
	end
	
	PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30);
	PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", -35, 0);
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
		PlayerFrames:BuffOptions()
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

function PlayerFrames:BuffOptions()
	spartan.opt.args["PlayerFrames"].args["auras"] = {name = "Buffs & Debuffs",type = "group",order=3,desc = "Buff & Debuff display settings", args={}};
	local Units = {[1]="player",[2]="pet",[3]="target",[4]="targettarget",[5]="focus",[6]="focustarget"}
	for k,unit in pairs(Units) do if DB.Styles.Classic.Frames[unit].Auras.AuraDisplay then
		spartan.opt.args["PlayerFrames"].args["auras"].args[unit] = {name=unit,type = "group",inline=true,order=k,
		args = {
			AuraDisplay={name = L["Display Buffs"], type = "toggle", order=10,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.AuraDisplay; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.AuraDisplay = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			NumBuffs={name = L["Number of buffs"], type = "range", order=20,
			min=1,max=30,step=1,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.NumBuffs; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.NumBuffs = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			NumDebuffs = {name = L["Number of debuffs"], type = "range", order=30,
			min=1,max=30,step=1,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.NumDebuffs; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.NumDebuffs = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			size = {name = L["Size"], type = "range", order=40,
			min=1,max=30,step=1,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.size; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.size = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			spacing = {name = L["Spacing"], type = "range", order=50,
			min=1,max=30,step=1,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.spacing; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.spacing = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			showType={name = L["Show type"], type = "toggle", order=60,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.showType; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.showType = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			},
			onlyShowPlayer={name = L["Only show players"], type = "toggle", order=70,
				get = function(info) return DB.Styles.Classic.Frames[unit].Auras.onlyShowPlayer; end,
				set = function(info,val) DB.Styles.Classic.Frames[unit].Auras.onlyShowPlayer = val; PlayerFrames[unit].Auras:PostUpdate(unit); end
			}
		}
	}
	end end
end