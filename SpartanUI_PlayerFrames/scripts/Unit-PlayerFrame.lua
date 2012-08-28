local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
oUF:SetActiveStyle("Spartan_PlayerFrames");

addon.player = oUF:Spawn("player","SUI_PlayerFrame");
addon.player:SetPoint("BOTTOMRIGHT",SpartanUI,"TOP",-72,-3);

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

do -- relocate the AlternatePowerBar
	hooksecurefunc(PlayerFrameAlternateManaBar,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			PlayerFrameAlternateManaBar:ClearAllPoints();
			PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,0);
		end
	end);
	PlayerFrameAlternateManaBar:SetParent(addon.player); AlternatePowerBar_OnLoad(PlayerFrameAlternateManaBar); PlayerFrameAlternateManaBar:SetFrameStrata("MEDIUM");
	PlayerFrameAlternateManaBar:SetFrameLevel(4); PlayerFrameAlternateManaBar:SetScale(1); PlayerFrameAlternateManaBar:ClearAllPoints();
	if (class == MONK) then
		PlayerFrameAlternateManaBar:SetScale(1.1);
	end
	PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,0);
end

do -- relocate the druid EclipseBar
	hooksecurefunc(EclipseBarFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			EclipseBarFrame:ClearAllPoints();
			EclipseBarFrame:SetPoint("TOPRIGHT",addon.player,"TOPRIGHT",155,10);
		end
	end);
	EclipseBarFrame:SetParent(addon.player); EclipseBar_OnLoad(EclipseBarFrame); EclipseBarFrame:SetFrameStrata("MEDIUM");
	EclipseBarFrame:SetFrameLevel(4); EclipseBarFrame:SetScale(0.8); EclipseBarFrame:ClearAllPoints();
	EclipseBarFrame:SetPoint("TOPRIGHT",addon.player,"TOPRIGHT",157,12);
end

do -- relocate the death knight RuneFrame
	hooksecurefunc(RuneFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			RuneFrame:ClearAllPoints();
			RuneFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,10);
		end
	end);
	RuneFrame:SetParent(addon.player); RuneFrame_OnLoad(RuneFrame); RuneFrame:SetFrameStrata("MEDIUM");
	RuneFrame:SetFrameLevel(4); RuneFrame:SetScale(0.97); RuneFrame:ClearAllPoints();
	RuneFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",40,7);
end

do -- relocate the paladin PaladinPowerBar
	hooksecurefunc(PaladinPowerBar,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			PaladinPowerBar:ClearAllPoints();
			PaladinPowerBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",60,14);
		end
	end);
	PaladinPowerBar:SetParent(addon.player); PaladinPowerBar_OnLoad(PaladinPowerBar); PaladinPowerBar:SetFrameStrata("MEDIUM");
	PaladinPowerBar:SetFrameLevel(4); PaladinPowerBar:SetScale(0.77); PaladinPowerBar:ClearAllPoints();
	PaladinPowerBar:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",60,12);
end

do -- relocate the shaman TotemFrame
	for i = 1,4 do
		local timer = _G["TotemFrameTotem"..i.."Duration"];
		timer.Show = function() return; end
		timer:Hide();
	end
	hooksecurefunc(TotemFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			TotemFrame:ClearAllPoints();
			TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",60,18);
			if (class == MONK) then
				TotemFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",-15,-105);
			end
		end
	end);
	TotemFrame:SetParent(addon.player); TotemFrame_OnLoad(TotemFrame); TotemFrame:SetFrameStrata("MEDIUM");
	TotemFrame:SetFrameLevel(4); TotemFrame:SetScale(0.7); TotemFrame:ClearAllPoints();
	TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",55,11);
end

do -- relocate the warlock bars
	hooksecurefunc(WarlockPowerFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			WarlockPowerFrame:ClearAllPoints();
			WarlockPowerFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",2,-2);
		end
	end);
	WarlockPowerFrame:SetParent(addon.player); WarlockPowerFrame_OnLoad(WarlockPowerFrame); WarlockPowerFrame:SetFrameStrata("MEDIUM");
	WarlockPowerFrame:SetFrameLevel(4); WarlockPowerFrame:SetScale(1); WarlockPowerFrame:ClearAllPoints();
	WarlockPowerFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",2,-2);
	WarlockPowerFrame_Relocate();
	local WarlockSpecWatcher = CreateFrame("Frame");
	WarlockSpecWatcher:RegisterEvent("PLAYER_TALENT_UPDATE");
	--WarlockSpecWatcher:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	WarlockSpecWatcher:SetScript("OnEvent",function()
		WarlockPowerFrame_Relocate();
	end);
end

do -- relocate the Priest PriestBarFrame
	hooksecurefunc(PriestBarFrame,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			PriestBarFrame:ClearAllPoints();
			PriestBarFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",2,-2);
		end
	end);
	PriestBarFrame:SetParent(addon.player); PriestBarFrame_OnLoad(PriestBarFrame); PriestBarFrame:SetFrameStrata("MEDIUM");
	PriestBarFrame:SetFrameLevel(4); PriestBarFrame:SetScale(.7); PriestBarFrame:ClearAllPoints();
	PriestBarFrame:SetPoint("TOPLEFT",addon.player,"TOPLEFT",-4,-2);
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