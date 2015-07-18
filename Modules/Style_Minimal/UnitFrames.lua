local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Minimal");
local PFrame;
----------------------------------------------------------------------------------------------------
local square = [[Interface\AddOns\SpartanUI\media\map-overlay.tga]]

local Smoothv2 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\Smoothv2.tga]]
local texture = [[Interface\AddOns\SpartanUI_PlayerFrames\media\texture.tga]]
local metal = [[Interface\AddOns\SpartanUI_PlayerFrames\media\metal.tga]]

--Interface/WorldStateFrame/ICONS-CLASSES
local lfdrole = [[Interface\AddOns\SpartanUI\media\icon_role.tga]]

local colors = setmetatable({},{__index = SpartanoUF.colors});
for k,v in pairs(SpartanoUF.colors) do if not colors[k] then colors[k] = v end end
do -- setup custom colors that we want to use
	colors.health 		= {0,1,50/255};			-- the color of health bars
	colors.reaction[1]	= {1, 50/255, 0};		-- Hated
	colors.reaction[2]	= colors.reaction[1];	-- Hostile
	colors.reaction[3]	= {1, 150/255, 0};		-- Unfriendly
	colors.reaction[4]	= {1, 220/255, 0};		-- Neutral
	colors.reaction[5]	= colors.health;		-- Friendly
	colors.reaction[6]	= colors.health;		-- Honored
	colors.reaction[7]	= colors.health;		-- Revered
	colors.reaction[8]	= colors.health;		-- Exalted
end

--	Formatting functions
local TextFormat = function(text)
	local textstyle = DBMod.PlayerFrames.bars[text].textstyle
	local textmode = DBMod.PlayerFrames.bars[text].textmode
	local a,m,t,z
	if text == "mana" then z = "pp" else z = "hp" end
	
	-- textstyle
	-- "Long: 			 Displays all numbers."
	-- "Long Formatted: Displays all numbers with commas."
	-- "Dynamic: 		 Abbriviates and formats as needed"
	if textstyle == "long" then
		a = "[cur"..z.."]";
		m = "[missing"..z.."]";
		t = "[max"..z.."]";
	elseif textstyle == "longfor" then
		a = "[cur"..z.."formatted]";
		m = "[missing"..z.."formatted]";
		t = "[max"..z.."formatted]";
	elseif textstyle == "dynamic" then
		a = "[cur"..z.."dynamic]";
		m = "[missing"..z.."dynamic]";
		t = "[max"..z.."dynamic]";
	end
	-- textmode
	-- [1]="Avaliable / Total",
	-- [2]="(Missing) Avaliable / Total",
	-- [3]="(Missing) Avaliable"
	
	if textmode == 1 then
		return a .. " / " .. t
	elseif textmode == 2 then
		return "("..m..") "..a.." / "..t
	elseif textmode == 3 then
		return "("..m..") "..a
	end
end

local menu = function(self)
	local unit = string.gsub(self.unit,"(.)",string.upper,1);
	if (_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	end
end

local threat = function(self,event,unit)
	if (not self.Portrait) then -- no Portrait color artwork if possible
		if (not self.artwork) then return end
		-- if (not self.artwork.bg:IsObjectType("Texture")) then return; end
		-- unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		-- local status
		-- if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		-- if (status and status > 0) then
			-- local r,g,b = GetThreatStatusColor(status);
			-- self.artwork.bg:SetVertexColor(r,g,b);
		-- else
			-- self.artwork.bg:SetVertexColor(1,1,1);
		-- end
	else -- Portrait exsits color picture for threat
		if (not self.Portrait:IsObjectType("Texture")) then return; end
		unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
		local status
		if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
		if (status and status > 0) then
			local r,g,b = GetThreatStatusColor(status);
			self.Portrait:SetVertexColor(r,g,b);
		else
			self.Portrait:SetVertexColor(1,1,1);
		end
	end
end

local name = function(self)
	if (UnitIsEnemy(self.unit,"player")) then self.Name:SetTextColor(1, 50/255, 0);
	elseif (UnitIsUnit(self.unit,"player")) then self.Name:SetTextColor(1, 1, 1); 
	else
		local r,g,b = unpack(colors.reaction[UnitReaction(self.unit,"player")] or {1,1,1});
		self.Name:SetTextColor(r,g,b);
	end
end

local pvpIcon = function (self, event, unit)
	if(unit ~= self.unit) then return end
	
	local pvp = self.PvP
	if(pvp.PreUpdate) then
		pvp:PreUpdate()
	end
	
	if pvp.shadow == nil then
		pvp.shadow = self:CreateTexture(nil,"BACKGROUND");
		pvp.shadow:SetSize(25,25);
		pvp.shadow:SetPoint("CENTER",pvp,"CENTER",2,-2);
		pvp.shadow:SetVertexColor(0,0,0,.9)
	end
	
	local status
	local factionGroup = UnitFactionGroup(unit)
	if(UnitIsPVPFreeForAll(unit)) then
		pvp:SetTexture[[Interface\FriendsFrame\UI-Toast-FriendOnlineIcon]]
		status = 'ffa'
	-- XXX - WoW5: UnitFactionGroup() can return Neutral as well.
	elseif(factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
		pvp:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		pvp.shadow:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		status = factionGroup
	end

	if(status) then
		pvp:Show()
		pvp.shadow:Show()
	else
		pvp:Hide()
		pvp.shadow:Hide()
	end

	if(pvp.PostUpdate) then
		return pvp:PostUpdate(status)
	end
end

function CreatePortrait(self)
	if DBMod.PlayerFrames.Portrait3D then			
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
		Portrait.type = "3D"
		return Portrait;
	else
		local tmp = self:CreateTexture(nil,"BORDER");
		tmp:SetTexCoord(0.15,0.86,0.15,0.86)
		return tmp;
	end
end

--	Updating functions
local PostUpdateText = function(self,unit)
	self:Untag(self.Health.value)
	if self.Power then self:Untag(self.Power.value) end
	self:Tag(self.Health.value, TextFormat("health"))
	if self.Power then self:Tag(self.Power.value, TextFormat("mana")) end
end

local PostUpdateAura = function(self,unit)
	if DBMod.PlayerFrames[unit] then
		if DBMod.PlayerFrames[unit].AuraDisplay then
			self:Show();
			self.size = DBMod.PlayerFrames[unit].Auras.size;
			self.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
			self.showType = DBMod.PlayerFrames[unit].Auras.showType;
			self.numBuffs = DBMod.PlayerFrames[unit].Auras.NumBuffs;
			self.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
			self.onlyShowPlayer = DBMod.PlayerFrames[unit].Auras.onlyShowPlayer;
		else
			self:Hide();
		end
	end
end

local PostUpdateColor = function(self,unit)
	self.Health.frequentUpdates = true;
	self.Health.colorDisconnected = true;
	if DBMod.PlayerFrames.bars[unit].color == "reaction" then
		self.Health.colorReaction = true;
		self.Health.colorClass = false;
	elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
		self.Health.colorHappiness = true;
		self.Health.colorReaction = false;
		self.Health.colorClass = false;
	elseif DBMod.PlayerFrames.bars[unit].color == "class" then
		self.Health.colorClass = true;
		self.Health.colorReaction = false;
	else
		self.Health.colorClass = false;
		self.Health.colorReaction = false;
		self.Health.colorSmooth = true;
	end
	self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
	self.Health.colorHealth = true;
end

local ChangeFrameStatus = function(self,unit)
	if DBMod.PlayerFrames[unit].display then
		self:Show();
	else
		self:Hide();
	end
end

local PostCastStop = function(self)
	if self.Time then self.Time:SetTextColor(1,1,1); end
end

local PostCastStart = function(self,unit,name,rank,text,castid)
	self:SetStatusBarColor(1,0.7,0);
end

local PostChannelStart = function(self,unit,name,rank,text,castid)
	self:SetStatusBarColor(1,0.2,0.7);
end

local OnCastbarUpdate = function(self,elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil;
			self:Hide();
			if PostCastStop then PostCastStop(self:GetParent()); end
			if PostCastStop then PostCastStop(self); end
			return;
		end
		if self.Time then
			if self.delay ~= 0 then self.Time:SetTextColor(1,0,0); else self.Time:SetTextColor(1,1,1); end
			if DBMod.PlayerFrames.Castbar.text[self:GetParent().unit] == 1 then
				self.Time:SetFormattedText("%.1f",self.max - self.duration);
			else
				self.Time:SetFormattedText("%.1f",self.duration);
			end
		end
		if DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.max-self.duration)
		else
			self:SetValue(self.duration)
		end
	elseif self.channeling then
		self.duration = self.duration - elapsed;
		if (self.duration <= 0) then
			self.channeling = nil;
			self:Hide();
			if PostChannelStop then PostChannelStop(self:GetParent()); end
			return;
		end
		if self.Time then
			if self.delay ~= 0 then self.Time:SetTextColor(1,0,0); else self.Time:SetTextColor(1,1,1); end
				self.Time:SetFormattedText("%.1f",self.max-self.duration);
		end
		if DBMod.PlayerFrames.Castbar[self:GetParent().unit] == 1 then
			self:SetValue(self.duration)
		else
			self:SetValue(self.max-self.duration)
		end
	else
		self.unitName = nil;
		self.channeling = nil;
		self:SetValue(1);
		self:Hide();
	end
end

local MakeSmallFrame = function(self,unit)
	self:SetSize(140, 40);
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2); self.artwork:SetAllPoints(self);
		
		-- if DBMod.PartyFrames.Portrait then
			-- self.Portrait = CreatePortrait(self);
			-- self.Portrait:SetSize(60, 60);
			-- self.Portrait:SetPoint("TOPLEFT",self,"TOPLEFT",35,-15);
		-- end
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(self:GetWidth(), 5);
			cast:SetPoint("TOP",self,"TOP",0,-1);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(20,8);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
			
			local Background = cast:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(cast)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Castbar = cast;
			self.Castbar.bg = Background;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(self:GetWidth(), 30);
			health:SetPoint("TOP",self.Castbar,"BOTTOM",0,0);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetAllPoints(health);
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			self:Tag(health.value, TextFormat("health"))	
			
			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Health = health;
			self.Health.bg = Background;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			if DBMod.PlayerFrames.bars[unit] then
				if DBMod.PlayerFrames.bars[unit].color == "reaction" then
					self.Health.colorReaction = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
					self.Health.colorHappiness = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "class" then
					self.Health.colorClass = true;
				end
			else
				self.Health.colorSmooth = true;
			end
			
			self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
			self.Health.colorHealth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(self:GetWidth(), 8);
			power:SetPoint("TOP",self.Health,"BOTTOM",0,0);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetAllPoints(power);
			power.value:SetJustifyH("CENTER");
			power.value:SetJustifyV("MIDDLE");
			self:Tag(power.value, TextFormat("mana"))
			
			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Power = power;
			self.Power.bg = Background;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetAllPoints(self.Portrait);
		ring:SetFrameLevel(4);
		ring.low = CreateFrame("Frame",nil,self);
		ring.low:SetFrameStrata("BACKGROUND");
		ring.low:SetAllPoints(self.Portrait);
		ring.low:SetFrameLevel(1);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 10, "Player")
		self.Name:SetSize(self:GetWidth(), 10);
		self.Name:SetJustifyH("CENTER");
		self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("BOTTOMLEFT",self,"TOPLEFT",0,0);
		self.Name:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",0,0);
		self:Tag(self.Name, "[SUI_ColorClass][name]");
		
		self.RareElite = ring.low:CreateTexture(nil,"ARTWORK", nil, -5);
		self.RareElite:SetSize(150, 110);
		self.RareElite:SetPoint("CENTER",ring,"CENTER",-12,25);
		self.RareElite.short = true
		
		
		self.LFDRole = ring:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(18, 18);
		self.LFDRole:SetPoint("CENTER",ring,"TOP",-20,7);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		-- self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		-- self.SUI_ClassIcon:SetSize(18,18);
		-- self.SUI_ClassIcon:SetPoint("RIGHT",self.Name,"LEFT");
		-- self.SUI_ClassIcon:SetAlpha(.75);
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25, 25);
		self.PvP:SetPoint("CENTER",self.Portrait,"BOTTOMLEFT",0,0);
		self.PvP.Override = pvpIcon
		
		self.LevelSkull = ring:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("LEFT",self.Name,"LEFT");
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(24, 24);
		self.RaidIcon:SetPoint("CENTER",ring,"RIGHT",2,-4);
		
		self.StatusText = ring:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22");
		self.StatusText:SetPoint("CENTER",ring,"CENTER");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
		
		self.CPoints = ring:CreateFontString(nil, "BORDER","SUI_FontOutline13");
		self.CPoints:SetPoint("TOPLEFT",ring,"BOTTOMRIGHT",8,-4);
		for i = 1, 5 do
			self.CPoints[i] = ring:CreateTexture(nil,"OVERLAY");
			self.CPoints[i]:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
			if (i == 1) then self.CPoints[1]:SetPoint("LEFT",self.CPoints,"RIGHT",1,-1); else 
				self.CPoints[i]:SetPoint("LEFT",self.CPoints[i-1],"RIGHT",-2,0);
			end
		end
		ring:SetScript("OnUpdate",function()
			if self.CPoints then
				local cp = GetComboPoints("player","target");
				self.CPoints:SetText( (cp > 0 and cp) or "");
			end
		end);
	end
	do -- setup buffs and debuffs
		if DBMod.PlayerFrames[unit] then
			self.Auras = CreateFrame("Frame",nil,self);
			self.Auras:SetSize(220, 44);
			self.Auras:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",-10,0);
			self.Auras:SetFrameStrata("BACKGROUND");
			self.Auras:SetFrameLevel(5);
			-- settings
			self.Auras.initialAnchor = "BOTTOMRIGHT";
			self.Auras["growth-x"] = "LEFT";
			self.Auras["growth-y"] = "UP";
			self.Auras.gap = true;
		
			self.Auras.size = DBMod.PlayerFrames[unit].Auras.size;
			self.Auras.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
			self.Auras.showType = DBMod.PlayerFrames[unit].Auras.showType;
			self.Auras.numBuffs = DBMod.PlayerFrames[unit].Auras.NumBuffs;
			self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
			self.Auras.onlyShowPlayer = DBMod.PlayerFrames[unit].Auras.onlyShowPlayer;
		
			self.Auras.PostUpdate = PostUpdateAura;
		end
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local MakeLargeFrame = function(self,unit)
	self:SetSize(240, 40);
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2); self.artwork:SetAllPoints(self);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(self:GetWidth(), 5);
			cast:SetPoint("TOP",self,"TOP",0,-1);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(20,8);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
			
			local Background = cast:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(cast)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Castbar = cast;
			self.Castbar.bg = Background;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(self:GetWidth(), 30);
			health:SetPoint("TOP",self.Castbar,"BOTTOM",0,0);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetAllPoints(health);
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			self:Tag(health.value, TextFormat("health"))	
			
			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Health = health;
			self.Health.bg = Background;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			if DBMod.PlayerFrames.bars[unit] then
				if DBMod.PlayerFrames.bars[unit].color == "reaction" then
					self.Health.colorReaction = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
					self.Health.colorHappiness = true;
				elseif DBMod.PlayerFrames.bars[unit].color == "class" then
					self.Health.colorClass = true;
				end
			else
				self.Health.colorSmooth = true;
			end
			
			self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
			self.Health.colorHealth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(200, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(self:GetWidth(), 8);
			power:SetPoint("TOP",self.Health,"BOTTOM",0,0);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetAllPoints(power);
			power.value:SetJustifyH("CENTER");
			power.value:SetJustifyV("MIDDLE");
			self:Tag(power.value, TextFormat("mana"))
			
			local Background = power:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(power)
			Background:SetTexture(1, 1, 1, .2)
			
			self.Power = power;
			self.Power.bg = Background;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
		do --Special Icons/Bars
			local playerClass = select(2, UnitClass("player"))
			if unit == "player" and playerClass =="DEATHKNIGHT" then	
				self.Runes = CreateFrame("Frame", nil, self)
				
				for i = 1, 6 do
					self.Runes[i] = CreateFrame("StatusBar", self:GetName().."_Runes"..i, self)
					self.Runes[i]:SetHeight(6)
					self.Runes[i]:SetWidth((self:GetWidth() - 6) / 6)
					if (i == 1) then
						self.Runes[i]:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -3)
					else
						self.Runes[i]:SetPoint("TOPLEFT", self.Runes[i-1], "TOPRIGHT", 1, 0)
					end
					self.Runes[i]:SetStatusBarTexture(Smoothv2)

					self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
					self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", -0, 0)
					self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, -0)				
					self.Runes[i].bg:SetTexture(Smoothv2)
					self.Runes[i].bg.multiplier = 0.34
					
				end
			end	
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetAllPoints(self);
		ring:SetFrameLevel(4);
		ring.low = CreateFrame("Frame",nil,self);
		ring.low:SetFrameStrata("BACKGROUND");
		ring.low:SetAllPoints(self.Portrait);
		ring.low:SetFrameLevel(1);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(self:GetWidth(), 12);
		self.Name:SetJustifyH("CENTER");
		self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("BOTTOMLEFT",self,"TOPLEFT",0,0);
		self.Name:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",0,0);
		self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
		
		self.RareElite = ring.low:CreateTexture(nil,"ARTWORK", nil, -5);
		self.RareElite:SetSize(150, 110);
		self.RareElite:SetPoint("CENTER",ring,"CENTER",-12,25);
		self.RareElite.short = true
		
		
		self.LFDRole = ring:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(18, 18);
		self.LFDRole:SetPoint("CENTER",ring,"TOP",-20,7);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		-- self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		-- self.SUI_ClassIcon:SetSize(18,18);
		-- self.SUI_ClassIcon:SetPoint("RIGHT",self.Name,"LEFT");
		-- self.SUI_ClassIcon:SetAlpha(.75);
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25, 25);
		self.PvP:SetPoint("CENTER",self.Portrait,"BOTTOMLEFT",0,0);
		self.PvP.Override = pvpIcon
		
		self.LevelSkull = ring:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("LEFT",self.Name,"LEFT");
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(24, 24);
		self.RaidIcon:SetPoint("CENTER",ring,"RIGHT",2,-4);
		
		self.StatusText = ring:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22");
		self.StatusText:SetPoint("CENTER",ring,"CENTER");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
		
		self.CPoints = ring:CreateFontString(nil, "BORDER","SUI_FontOutline13");
		self.CPoints:SetPoint("TOPLEFT",ring,"BOTTOMRIGHT",8,-4);
		for i = 1, 5 do
			self.CPoints[i] = ring:CreateTexture(nil,"OVERLAY");
			self.CPoints[i]:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
			if (i == 1) then self.CPoints[1]:SetPoint("LEFT",self.CPoints,"RIGHT",1,-1); else 
				self.CPoints[i]:SetPoint("LEFT",self.CPoints[i-1],"RIGHT",-2,0);
			end
		end
		ring:SetScript("OnUpdate",function()
			if self.CPoints then
				local cp = GetComboPoints("player","target");
				self.CPoints:SetText( (cp > 0 and cp) or "");
			end
		end);
	end
	do -- setup buffs and debuffs
		if DBMod.PlayerFrames[unit] then
			self.Auras = CreateFrame("Frame",nil,self);
			self.Auras:SetSize(220, 44);
			self.Auras:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",-10,0);
			self.Auras:SetFrameStrata("BACKGROUND");
			self.Auras:SetFrameLevel(5);
			-- settings
			self.Auras.initialAnchor = "BOTTOMRIGHT";
			self.Auras["growth-x"] = "LEFT";
			self.Auras["growth-y"] = "UP";
			self.Auras.gap = true;
		
			self.Auras.size = DBMod.PlayerFrames[unit].Auras.size;
			self.Auras.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
			self.Auras.showType = DBMod.PlayerFrames[unit].Auras.showType;
			self.Auras.numBuffs = DBMod.PlayerFrames[unit].Auras.NumBuffs;
			self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
			self.Auras.onlyShowPlayer = DBMod.PlayerFrames[unit].Auras.onlyShowPlayer;
		
			self.Auras.PostUpdate = PostUpdateAura;
		end
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateUnitFrame = function(self,unit)
	self.menu = menu;
	
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent);
	else
		self:SetParent(SUI_FramesAnchor);
	end
	
	self:SetFrameStrata("BACKGROUND"); self:SetFrameLevel(1);
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	self:RegisterForClicks("anyup");
	self:SetAttribute("*type2", "menu");
	self.colors = module.colors;
	
	return ((unit == "player" and MakeLargeFrame(self,unit))
	or (unit == "target" and MakeLargeFrame(self,unit))
	-- or (unit == "targettarget" and MakeSmallFrame(self,unit))
	-- or (unit == "focus" and MakeSmallFrame(self,unit))
	-- or (unit == "focustarget" and MakeSmallFrame(self,unit))
	-- or (unit == "pet" and MakeSmallFrame(self,unit))
	or MakeSmallFrame(self,unit));
end

SpartanoUF:RegisterStyle("Spartan_MinimalFrames", CreateUnitFrame);

function module:UpdateAltBarPositions()
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
		EclipseBarFrame:SetPoint("TOPRIGHT",PFrame.player,"TOPRIGHT",157,12);
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
		MonkHarmonyBar:SetPoint("BOTTOMLEFT",PFrame.player,"BOTTOMLEFT",40,-40);
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
		PaladinPowerBar:SetPoint("TOPLEFT",PFrame.player,"BOTTOMLEFT",60,12);
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
		PriestBarFrame:SetPoint("TOPLEFT",PFrame.player,"TOPLEFT",-4,-2);
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
		PFrame:WarlockPowerFrame_Relocate();
	end
	
	--Death Knight Runes
	RuneFrame:ClearAllPoints();
	if DBMod.PlayerFrames.ClassBar.movement.moved then
		RuneFrame:SetPoint(DBMod.PlayerFrames.ClassBar.movement.point,
		DBMod.PlayerFrames.ClassBar.movement.relativeTo,
		DBMod.PlayerFrames.ClassBar.movement.relativePoint,
		DBMod.PlayerFrames.ClassBar.movement.xOffset,
		DBMod.PlayerFrames.ClassBar.movement.yOffset);
	else
		RuneFrame:SetPoint("BOTTOM",PFrame.player,"TOP",0,20);
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
			PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",PFrame.player,"BOTTOMLEFT",40,0);
		end
	end
end

function module:UnitFrames()
	PFrame = spartan:GetModule("PlayerFrames");
	SpartanoUF:SetActiveStyle("Spartan_MinimalFrames");
	
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}

	for a,b in pairs(FramesList) do
		PFrame[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
	end
	PFrame:SetupExtras()
	-- PFrame.pet:SetScale(0.5)
	-- PFrame.targettarget:SetScale(0.5)
	
	do -- Position Static Frames
		
		PFrame.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,200);
		PFrame.pet:SetPoint("BOTTOMRIGHT",PFrame.player,"BOTTOMLEFT",-2,0);
		
		PFrame.target:SetPoint("BOTTOM",UIParent,"BOTTOM",220,200);
		
		PFrame.targettarget:SetPoint("BOTTOMLEFT",PFrame.target,"BOTTOMRIGHT",2,0);
		
		PFrame.focustarget:SetPoint("BOTTOM", PFrame.targettarget, "TOP", 0, 80);
	end

	PFrame:UpdateFocusPosition();
	module:UpdateAltBarPositions();
	
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
		
		function PFrame:UpdateBossFramePosition()
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
		
		PFrame.boss = boss;
	end
	spartan.PFrame = PFrame
end

