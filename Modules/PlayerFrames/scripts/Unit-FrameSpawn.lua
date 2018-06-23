local _G, SUI = _G, SUI
local L = SUI.L;
local PlayerFrames = SUI.PlayerFrames
----------------------------------------------------------------------------------------------------
local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}

function PlayerFrames:SUI_PlayerFrames_Classic()
	SpartanoUF:SetActiveStyle("SUI_PlayerFrames_Classic");

	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
		if b == "player" then PlayerFrames:SetupExtras() end
	end
	
	PlayerFrames:PositionFrame_Classic()

	if SUI.DBMod.PlayerFrames.BossFrame.display == true then
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

function PlayerFrames:PositionFrame_Classic(b)
	PlayerFrames.pet:SetParent(PlayerFrames.player)
	PlayerFrames.targettarget:SetParent(PlayerFrames.target)
	
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150); end
		if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12); end
		if b == "target" or b == nil then PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0); end
		
		if SUI.DBMod.PlayerFrames.targettarget.style == "small" then
			if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11); end
		else
			if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",19,15); end
		end
		
		for a,b in pairs(FramesList) do
			PlayerFrames[b]:SetScale(SUI.DB.scale);
		end
	else
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3); end
		if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-18,12) end
		if b == "target" or b == nil then PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3); end
		
		if SUI.DBMod.PlayerFrames.targettarget.style == "small" then
			if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",360,-15); end
		else
			if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",370,12); end
		end
	end
	
	if b == "focus" or b == nil then PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30); end
	if b == "focustarget" or b == nil then PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", -35, 0); end
end

function PlayerFrames:AddMover(frame, framename)
	if frame == nil then
		SUI:Err("PlayerFrames", SUI.DBMod.PlayerFrames.Style .. " did not spawn " .. framename)
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
				SUI.DBMod.PlayerFrames[framename].moved = true;
				frame:SetMovable(true);
				frame:StartMoving();
			end
		end);
		frame:SetScript("OnMouseUp",function(self,button)
			frame.mover:Hide();
			frame:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
			Anchors.relativeTo = "UIParent"
			for k,v in pairs(Anchors) do
				SUI.DBMod.PlayerFrames[framename].Anchors[k] = v
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
		if SUI.DBMod.PlayerFrames[framename].moved then
			frame:SetMovable(true);
			frame:SetUserPlaced(false);
			local Anchors = {}
			for k,v in pairs(SUI.DBMod.PlayerFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints();
			frame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
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
			SUI.DBMod.PlayerFrames.boss.moved = true;
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
			SUI.DBMod.PlayerFrames.boss.Anchors[k] = v
		end
	end);
end

function PlayerFrames:OnEnable()
	PlayerFrames.boss = {}
	if (SUI.DBMod.PlayerFrames.Style == "Classic") then
		PlayerFrames:BuffOptions()
		PlayerFrames:SUI_PlayerFrames_Classic();
	else
		SUI:GetModule("Style_" .. SUI.DBMod.PlayerFrames.Style):PlayerFrames();
	end
	
	if SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Movable.PlayerFrames == true then 
		local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
		for a,b in pairs(FramesList) do
			PlayerFrames:AddMover(PlayerFrames[b], b)
		end
		if SUI.DBMod.PlayerFrames.BossFrame.display then
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
	SUI.opt.args["PlayerFrames"].args["auras"] = {name = "Buffs & Debuffs",type = "group",order=3,desc = "Buff & Debuff display settings", args={}};
	local Units = {[1]="player",[2]="pet",[3]="target",[4]="targettarget",[5]="focus",[6]="focustarget"}
	local values = {["bars"]=L["Bars"],["icons"]=L["Icons"],["both"]=L["Both"],["disabled"]=L["Disabled"]}
	
	for k,unit in pairs(Units) do
		SUI.opt.args["PlayerFrames"].args["auras"].args[unit] = {name=unit, type = "group", order=k, disabled=true,
			args = {
				Notice = {type="description", order=.5, fontSize="medium", name=L["possiblereloadneeded"]},
				Buffs = {name="Buffs",type = "group",inline=true,order=1,
					args = {
						Display={name = L["Display mode"], type = "select", order=15,
							values = values,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode; end,
							set = function(info,val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Mode = val;
								SUI:reloadui()
							end
						},
						Number={name = L["Number to show"], type = "range", order=20,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.Number = val; if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then PlayerFrames[unit].Buffs:PostUpdate(unit,"Buffs"); end end
						},
						size = {name = L["Size"], type = "range", order=30,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size; end,
							set = function(info,val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.size = val;
								if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then PlayerFrames[unit].Buffs:PostUpdate(unit,"Buffs"); end
							end
						},
						spacing = {name = L["Spacing"], type = "range", order=40,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.spacing = val; if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then PlayerFrames[unit].Buffs:PostUpdate(unit,"Buffs"); end end
						},
						showType={name = L["Show type"], type = "toggle", order=50,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.showType = val; if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then PlayerFrames[unit].Buffs:PostUpdate(unit,"Buffs"); end end
						},
						onlyShowPlayer={name = L["Only show players"], type = "toggle", order=60,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Buffs.onlyShowPlayer = val; if PlayerFrames[unit].Buffs and PlayerFrames[unit].Buffs.PostUpdate then PlayerFrames[unit].Buffs:PostUpdate(unit,"Buffs"); end end
						}
					}
				},
				Debuffs = {name="Debuffs",type = "group",inline=true,order=2,
					args = {
						Display={name = L["Display mode"], type = "select", order=15, 
							values = values,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode; end,
							set = function(info,val)
								SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Mode = val;
								SUI:reloadui()
							end
						},
						Number = {name = L["Number to show"], type = "range", order=20,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.Number = val; if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then PlayerFrames[unit].Debuffs:PostUpdate(unit,"Debuffs"); end end
						},
						size = {name = L["Size"], type = "range", order=30,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.size = val; if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then PlayerFrames[unit].Debuffs:PostUpdate(unit,"Debuffs"); end end
						},
						spacing = {name = L["Spacing"], type = "range", order=40,
						min=1,max=30,step=1,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.spacing = val; if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then PlayerFrames[unit].Debuffs:PostUpdate(unit,"Debuffs"); end end
						},
						showType={name = L["Show type"], type = "toggle", order=50,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.showType = val; if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then PlayerFrames[unit].Debuffs:PostUpdate(unit,"Debuffs"); end end
						},
						onlyShowPlayer={name = L["Only show players"], type = "toggle", order=60,
							get = function(info) return SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer; end,
							set = function(info,val) SUI.DB.Styles[SUI.DBMod.PlayerFrames.Style].Frames[unit].Debuffs.onlyShowPlayer = val; if PlayerFrames[unit].Debuffs and PlayerFrames[unit].Debuffs.PostUpdate then PlayerFrames[unit].Debuffs:PostUpdate(unit,"Debuffs"); end end
						}
					}
				}
			}
		}
	end
end
