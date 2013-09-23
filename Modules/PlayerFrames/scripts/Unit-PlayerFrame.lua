local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

addon.player = oUF:Spawn("player","SUI_PlayerFrame");
addon.player:SetPoint("BOTTOMRIGHT",SpartanUI,"TOP",-72,-3);

do -- relocate the AlternatePowerBar
	local classname, classFileName = UnitClass("player")
	if classFileName == "MONK" then
		--Align and shrink to fit under CHI, not movable
		PlayerFrameAlternateManaBar:SetParent(addon.player); AlternatePowerBar_OnLoad(PlayerFrameAlternateManaBar); PlayerFrameAlternateManaBar:SetFrameStrata("MEDIUM");
		PlayerFrameAlternateManaBar:SetFrameLevel(6); PlayerFrameAlternateManaBar:SetScale(.7); PlayerFrameAlternateManaBar:ClearAllPoints();
		hooksecurefunc(PlayerFrameAlternateManaBar,"SetPoint",function(_,_,parent)
			if (parent ~= addon.player) then
				PlayerFrameAlternateManaBar:ClearAllPoints();
				PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",-5,-17);
			end
		end);
		PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",-5,-17);
	else
		--Make it look like a smaller, movable mana bar.
		hooksecurefunc(PlayerFrameAlternateManaBar,"SetPoint",function(_,_,parent)
			if (parent ~= addon.player) and (DBMod.PlayerFrames.AltManaBar.movement.moved == false) then
				PlayerFrameAlternateManaBar:ClearAllPoints();
				PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,0);
			end
		end);
		PlayerFrameAlternateManaBar:SetParent(addon.player); AlternatePowerBar_OnLoad(PlayerFrameAlternateManaBar); PlayerFrameAlternateManaBar:SetFrameStrata("MEDIUM");
		PlayerFrameAlternateManaBar:SetFrameLevel(4); PlayerFrameAlternateManaBar:SetScale(1); PlayerFrameAlternateManaBar:EnableMouse(enable);
		PlayerFrameAlternateManaBar:SetScript("OnMouseDown",function(self,button)
			if button == "LeftButton" and IsAltKeyDown() then
				DBMod.PlayerFrames.AltManaBar.movement.moved = true;
				self:SetMovable(true);
				self:StartMoving();
			end
		end);
		PlayerFrameAlternateManaBar:SetScript("OnMouseUp",function(self,button)
			self:StopMovingOrSizing();
			DBMod.PlayerFrames.AltManaBar.movement.point,
			DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
			DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
			DBMod.PlayerFrames.AltManaBar.movement.xOffset,
			DBMod.PlayerFrames.AltManaBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
		end);
	end
	
	-- Druid EclipseBar
	EclipseBarFrame:SetParent(addon.player); EclipseBar_OnLoad(EclipseBarFrame); EclipseBarFrame:SetFrameStrata("MEDIUM");
	EclipseBarFrame:SetFrameLevel(4); EclipseBarFrame:SetScale(0.8); EclipseBarFrame:EnableMouse(enable);
	EclipseBarFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	EclipseBarFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	
	-- Monk Chi Bar (Hard to move but it is doable.)
	MonkHarmonyBar:SetParent(addon.player); MonkHarmonyBar_OnLoad(MonkHarmonyBar); MonkHarmonyBar:SetFrameStrata("MEDIUM");
	MonkHarmonyBar:SetFrameLevel(4); MonkHarmonyBar:SetScale(.7); MonkHarmonyBar:EnableMouse(enable);
	MonkHarmonyBar:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	MonkHarmonyBar:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);

 -- Paladin Holy Power
	PaladinPowerBar:SetParent(addon.player); PaladinPowerBar_OnLoad(PaladinPowerBar); PaladinPowerBar:SetFrameStrata("MEDIUM");
	PaladinPowerBar:SetFrameLevel(4); PaladinPowerBar:SetScale(0.77); PaladinPowerBar:EnableMouse(enable);
	PaladinPowerBar:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	PaladinPowerBar:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);

	-- PriestBarFrame
	PriestBarFrame:SetParent(addon.player); PriestBarFrame_OnLoad(PriestBarFrame); PriestBarFrame:SetFrameStrata("MEDIUM");
	PriestBarFrame:SetFrameLevel(4); PriestBarFrame:SetScale(.7); PriestBarFrame:EnableMouse(enable);
	PriestBarFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	PriestBarFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	
 -- relocate the warlock bars
	WarlockPowerFrame:SetParent(addon.player); WarlockPowerFrame_OnLoad(WarlockPowerFrame); WarlockPowerFrame:SetFrameStrata("MEDIUM");
	WarlockPowerFrame:SetFrameLevel(4); WarlockPowerFrame:SetScale(1); WarlockPowerFrame:EnableMouse(enable);
	ShardBarFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	ShardBarFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	BurningEmbersBarFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	BurningEmbersBarFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	DemonicFuryBarFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	DemonicFuryBarFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	local WarlockSpecWatcher = CreateFrame("Frame");
	WarlockSpecWatcher:RegisterEvent("PLAYER_TALENT_UPDATE");
	WarlockSpecWatcher:SetScript("OnEvent",function()
		addon:UpdateAltBarPositions();
	end);

 -- Rune Frame
	RuneFrame:SetParent(addon.player); RuneFrame_OnLoad(RuneFrame); RuneFrame:SetFrameStrata("MEDIUM");
	RuneFrame:SetFrameLevel(4); RuneFrame:SetScale(0.97); RuneFrame:EnableMouse(enable);
	RuneButtonIndividual1:EnableMouse(enable);
	RuneFrame:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	RuneFrame:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	RuneButtonIndividual1:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.ClassBar.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	RuneButtonIndividual1:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);

	-- Totem Frame (Pally Concentration, Shaman Totems, Monk Statues)
	for i = 1,4 do
		local timer = _G["TotemFrameTotem"..i.."Duration"];
		timer.Show = function() return; end
		timer:Hide();
	end
	hooksecurefunc(TotemFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			TotemFrame:ClearAllPoints();
			if classFileName == "MONK" then
				TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",100,8);
			elseif classFileName == "PALADIN" then
				TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",15,8);
			else
				TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",70,8);
			end
		end
	end);
	TotemFrame:SetParent(addon.player); TotemFrame_OnLoad(TotemFrame); TotemFrame:SetFrameStrata("MEDIUM");
	TotemFrame:SetFrameLevel(4); TotemFrame:SetScale(0.7); TotemFrame:ClearAllPoints();
	
	-- relocate the PlayerPowerBarAlt
	hooksecurefunc(PlayerPowerBarAlt,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			PlayerPowerBarAlt:ClearAllPoints();
			PlayerPowerBarAlt:SetPoint("BOTTOMLEFT",addon.player,"TOPLEFT",10,40);
		end
	end);
	PlayerPowerBarAlt:SetParent(addon.player); PlayerPowerBarAlt:SetFrameStrata("MEDIUM");
	PlayerPowerBarAlt:SetFrameLevel(4); PlayerPowerBarAlt:SetScale(1); PlayerPowerBarAlt:ClearAllPoints();
	PlayerPowerBarAlt:SetPoint("BOTTOMLEFT",addon.player,"TOPLEFT",10,40);

	addon:UpdateAltBarPositions();
end 

do -- create a LFD cooldown frame
	local GetLFGDeserter = GetLFGDeserterExpiration
	local GetLFGRandomCooldown = GetLFGRandomCooldownExpiration

	local UpdateCooldown = function(self)
	local deserterExpiration = GetLFGDeserter();
	local myExpireTime, mode, hasDeserter
	if ( deserterExpiration ) then
		myExpireTime = deserterExpiration;
		hasDeserter = true;
	else
		myExpireTime = GetLFGRandomCooldown();
	end
	self.myExpirationTime = myExpireTime or GetTime();
	if ( myExpireTime and GetTime() < myExpireTime ) then
		if ( hasDeserter ) then
			self.text:SetText"|CFFEE0000X|r" -- deserter
			mode = "deserter"
		else
			mode = "time"
		end
	else
		mode = false
	end
	return mode
end

	local StartAnimating = EyeTemplate_StartAnimating
	local StopAnimating = EyeTemplate_StopAnimating

	local UpdateIsShown = function(self)
	--	local mode, submode = GetLFGMode();
		local mode = UpdateCooldown(self);
		if ( mode ) then
			self:Show();
			if ( mode == "time" ) then
				StartAnimating(self);
			else
				StopAnimating(self);
			end
		else
			self:Hide();
		end
	end

	local OnEnter = function(self)
		local mode = UpdateCooldown(self);
		local DESERTER = "You recently deserted a Dungeon Finder group|nand may not queue again for:"
		local RANDOM_COOLDOWN = LFG_RANDOM_COOLDOWN_YOU
		if ( mode ) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT");
			GameTooltip:SetText(LOOKING_FOR_DUNGEON);
			local timeRemaining = self.myExpirationTime - GetTime();
			if ( timeRemaining > 0 ) then
				if ( mode == "deserter" ) then
					GameTooltip:AddLine(string.format(DESERTER.." %s","|CFFEE0000"..SecondsToTime(ceil(timeRemaining)).."|r"));
				else
					GameTooltip:AddLine(string.format(RANDOM_COOLDOWN.." %s","|CFFEE0000"..SecondsToTime(ceil(timeRemaining)).."|r"));
				end
			else
				GameTooltip:AddLine("Ready")
			end
			GameTooltip:Show();
		end
	end

	local OnLeave = function(self)
		GameTooltip:Hide();
	end
		
	LFDCooldown = CreateFrame("Frame",nil,addon.player)
	LFDCooldown:SetFrameStrata("BACKGROUND")
	LFDCooldown:SetFrameLevel(10);
	LFDCooldown:SetWidth(38) -- Set these to whatever height/width is needed 
	LFDCooldown:SetHeight(38) -- for your Texture
	
	local t = LFDCooldown:CreateTexture(nil,"BACKGROUND")
--	t:SetTexture("Interface\\LFGFrame\\BattlenetWorking19.blp")
	t:SetTexture("Interface\\LFGFrame\\LFG-Eye.blp")
	t:SetAllPoints(LFDCooldown)
	LFDCooldown.texture = t
	
	local txt = LFDCooldown:CreateFontString(nil, "OVERLAY", "SUI_FontOutline18");
	txt:SetWidth(14);
	txt:SetHeight(22);
	txt:SetJustifyH("MIDDLE");
	txt:SetJustifyV("MIDDLE");
	--txt:SetAllPoints(LFDCooldown)
	txt:SetPoint("TOPLEFT", LFDCooldown ,"TOPLEFT", 5, 0)
	txt:SetPoint("BOTTOMRIGHT", LFDCooldown ,"BOTTOMRIGHT", 0, 0)
	LFDCooldown.text = txt
	LFDCooldown.text:SetText""
	
--	LFDCooldown.myExpirationTime = "";
	LFDCooldown:SetPoint("CENTER",addon.player,"CENTER",85,-30)
	LFDCooldown:RegisterEvent("PLAYER_ENTERING_WORLD");
	LFDCooldown:RegisterEvent("UNIT_AURA");
	LFDCooldown:EnableMouse()
	LFDCooldown:SetScript("OnEvent", UpdateIsShown)
	LFDCooldown:SetScript("OnEnter", OnEnter)
	LFDCooldown:SetScript("OnLeave", OnLeave)
--	LFDCooldown.text:SetText"|CFFEE0000X|r" -- deserter
--	LFDCooldown:Show() -- on cooldown
--	addon.player.LFDRole:SetTexCoord(20/64, 39/64, 22/64, 41/64) -- set dps lfdrole icon
end