local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget"}

do --color
	oUF.Tags.Events["SUI_ColorClass"] = 'UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'
	oUF.Tags.Methods["SUI_ColorClass"] = function(u)
		local _, class = UnitClass(u)
		local reaction = UnitReaction(u, "player")
		
		if (u == "pet") then
			return hex(oUF.colors.class[class])
		elseif (UnitIsPlayer(u)) then
			return hex(oUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end

for a,b in pairs(FramesList) do
	addon[b] = oUF:Spawn(b,"SUI_"..b.."Frame");
end

do -- Position Static Frames
	addon.pet:SetPoint("BOTTOMRIGHT",SpartanUI,"TOP",-370,12);
	addon.target:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",72,-3);
	addon.focustarget:SetPoint("TOPLEFT", "SUI_focusFrame", "TOPRIGHT", -51, 0);
	
	if DBMod.PlayerFrames.targettarget.style == "small" then
		addon.targettarget:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",360,-15);
	else
		addon.targettarget:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",370,12);
	end
end

do -- Dynamic Position Functions
	function addon:UpdateFocusPosition()
		addon.focus:ClearAllPoints();
		if DBMod.PlayerFrames.focus.movement.moved then
			addon.focus:SetPoint(DBMod.PlayerFrames.focus.movement.point,
			DBMod.PlayerFrames.focus.movement.relativeTo,
			DBMod.PlayerFrames.focus.movement.relativePoint,
			DBMod.PlayerFrames.focus.movement.xOffset,
			DBMod.PlayerFrames.focus.movement.yOffset);
		else
			addon.focus:SetPoint("BOTTOMLEFT",SpartanUI,"TOP",170,110);
		end
	end
	addon:UpdateFocusPosition();
	
	function addon:ResetAltBarPositions()
		DBMod.PlayerFrames.AltManaBar.movement.moved = false;
		DBMod.PlayerFrames.ClassBar.movement.moved = false; 
		addon:UpdateAltBarPositions();
	end
	function addon:UpdateAltBarPositions()
		local classname, classFileName = UnitClass("player");	
		-- Druid EclipseBar
		EclipseBarFrame:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			EclipseBarFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
		else
			EclipseBarFrame:SetPoint("TOPRIGHT",addon.player,"TOPRIGHT",157,12);
		end
		
		-- Monk Chi Bar (Hard to move but it is doable.)
		MonkHarmonyBar:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			MonkHarmonyBar:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
		else
			MonkHarmonyBar:SetPoint("BOTTOMLEFT",addon.player,"BOTTOMLEFT",40,-40);
		end
		
		--Paladin Holy Power
		PaladinPowerBar:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			PaladinPowerBar:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
		else
			PaladinPowerBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",60,12);
		end
		
		--Priest Power Frame
		PriestBarFrame:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			PriestBarFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
		else
			PriestBarFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",-4,-2);
		end
		
		--Warlock Power Frame
		WarlockPowerFrame:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			WarlockPowerFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
		else
			WarlockPowerFrame_Relocate();
		end
		
		--Death Knight Runes
		RuneFrame:ClearAllPoints();
		if DBMod.PlayerFrames.ClassBar.movement.moved then
			RuneFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
			DBMod.PlayerFrames.ClassBar.movement.relativeTo,
			DBMod.PlayerFrames.ClassBar.movement.relativePoint,
			DBMod.PlayerFrames.ClassBar.movement.xOffset,
			DBMod.PlayerFrames.ClassBar.movement.yOffset);
			spartan:Print("Runes");
		else
			RuneFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,7);
		end
				
		-- relocate the AlternatePowerBar
		if classFileName ~= "MONK" then
			PlayerFrameAlternateManaBar:ClearAllPoints();
			if DBMod.PlayerFrames.AltManaBar.movement.moved then
				PlayerFrameAlternateManaBar:SetPoint(DBMod.PlayerFrames.AltManaBar.movement.point,
				DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
				DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
				DBMod.PlayerFrames.AltManaBar.movement.xOffset,
				DBMod.PlayerFrames.AltManaBar.movement.yOffset);
			else
				PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,0);
			end
		end
	end
	
	function WarlockPowerFrame_Relocate() -- Sets the location of the warlock bars based on spec
		local spec = GetSpecialization();
		if ( spec == SPEC_WARLOCK_AFFLICTION ) then
			-- set up Affliction
			WarlockPowerFrame:SetScale(.85);
			WarlockPowerFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",8,-2);
		elseif ( spec == SPEC_WARLOCK_DESTRUCTION ) then
			-- set up Destruction
			WarlockPowerFrame:SetScale(0.85);
			WarlockPowerFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",14,-2);
		elseif ( spec == SPEC_WARLOCK_DEMONOLOGY ) then
			-- set up Demonic
			WarlockPowerFrame:SetScale(1);
			WarlockPowerFrame:SetPoint("TOPLEFT",addon.player,"TOPRIGHT",15,15);
		else
			-- no spec
		end
	end
end

if DBMod.PlayerFrames.BossFrame.display == true then
	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = oUF:Spawn('boss'..i, 'SUI_Boss'..i)
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

-- Watch for Pet name or level changes (may not be needed any more keeping just incase)
-- local Update = function(self,event)
	-- if self.Name then self.Name:UpdateTag(self.unit); end
	-- if self.Level then self.Level:UpdateTag(self.unit); end
-- end
-- addon.pet:RegisterEvent("UNIT_PET",Update);