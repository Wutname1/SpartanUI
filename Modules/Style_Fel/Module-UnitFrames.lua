local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:GetModule("Style_Fel");
local PlayerFrames = spartan:GetModule("PlayerFrames");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------
local Smoothv2 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\Smoothv2.tga]]
local square = [[Interface\AddOns\SpartanUI_Style_Transparent\Images\square.tga]]

local Images = {
	bg = {
		Texture =  [[Interface\Scenarios\LegionInvasion]],
		Coords = {.02, .385, .45, .575} --left, right, top, bottom
	},
	flair = {
		Texture =  [[Interface\Scenarios\LegionInvasion]],
		Coords = {0.140625,0.615234375,0,0.265625}
	}
}

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
	
	-- if pvp.shadow == nil then
		-- pvp.shadow = self:CreateTexture(nil,"BACKGROUND");
		-- pvp.shadow:SetSize(pvp:GetSize());
		-- pvp.shadow:SetPoint("CENTER",pvp,"CENTER",2,-2);
		-- pvp.shadow:SetVertexColor(0,0,0,.9)
	-- end
	
	local status
	local factionGroup = UnitFactionGroup(unit)
	if(UnitIsPVPFreeForAll(unit)) then
		pvp:SetTexture[[Interface\FriendsFrame\UI-Toast-FriendOnlineIcon]]
		status = 'ffa'
	-- XXX - WoW5: UnitFactionGroup() can return Neutral as well.
	elseif(factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then
		pvp:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		-- pvp.shadow:SetTexture([[Interface\FriendsFrame\PlusManz-]]..factionGroup)
		status = factionGroup
	end

	if(status) then
		pvp:Show()
		-- pvp.shadow:Show()
	else
		pvp:Hide()
		-- pvp.shadow:Hide()
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

-- Create Frames
local CreateLargeFrame = function(self,unit)
	self:SetSize(180, 58);
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER", self);
		self.artwork.bg:SetTexture(Images.bg.Texture);
		self.artwork.bg:SetTexCoord(unpack(Images.bg.Coords))
		self.artwork.bg:SetSize(self:GetSize());
		
		self.artwork.flair = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.flair:SetPoint("RIGHT", self, "RIGHT", 0, 5);
		self.artwork.flair:SetTexture(Images.flair.Texture);
		self.artwork.flair:SetTexCoord(unpack(Images.flair.Coords))
		self.artwork.flair:SetSize(self:GetWidth()+60, self:GetHeight()+75);
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetSize(58, 58);
		self.Portrait:SetPoint("RIGHT",self,"LEFT",0,0);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND");
			cast:SetFrameLevel(3);
			cast:SetSize(self:GetWidth(), 8);
			cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,0);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetJustifyH("CENTER");
			cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetAllPoints(cast);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND");
			health:SetFrameLevel(2);
			health:SetStatusBarTexture(Smoothv2)
			health:SetWidth(self:GetWidth());
			health:SetPoint("TOPLEFT",self.Castbar,"BOTTOMLEFT",0,-2);
			health:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",0,13);
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			health.value:SetAllPoints(health);
			self:Tag(health.value, TextFormat("health"))
			
			self.Health = health;
			
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			if DBMod.PlayerFrames.bars[unit].color == "reaction" then
				self.Health.colorReaction = true;
			elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
				self.Health.colorHappiness = true;
			elseif DBMod.PlayerFrames.bars[unit].color == "class" then
				self.Health.colorClass = true;
			else
				self.Health.colorSmooth = true;
			end
			self.colors.smooth = {1,0,0, 1,1,0, 0,1,0}
			self.Health.colorHealth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture(Smoothv2)
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture(Smoothv2)
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(self.Health:GetSize())
			otherBars:SetSize(self.Health:GetSize())
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 3,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND");
			power:SetFrameLevel(2);
			power:SetSize(self:GetWidth(), 10);
			power:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",0,2);
			power:SetStatusBarTexture(Smoothv2)
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline8");
			power.ratio:SetJustifyH("CENTER");
			power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetAllPoints(power);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
		do --Special Icons/Bars
			if unit == "player" then
				local playerClass = select(2, UnitClass("player"))
				if unit == "player" and playerClass =="DEATHKNIGHT" then	
					self.Runes = CreateFrame("Frame", nil, self)
					
					for i = 1, 6 do
						self.Runes[i] = CreateFrame("StatusBar", self:GetName().."_Runes"..i, self)
						self.Runes[i]:SetHeight(6)
						self.Runes[i]:SetWidth((245 - 5) / 6)
						if (i == 1) then
							self.Runes[i]:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -3)
						else
							self.Runes[i]:SetPoint("TOPLEFT", self.Runes[i-1], "TOPRIGHT", 1, 0)
						end
						self.Runes[i]:SetStatusBarTexture(Smoothv2)
						self.Runes[i]:SetStatusBarColor(0,.39,.63,1)

						self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
						self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", -0, 0)
						self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, -0)				
						self.Runes[i].bg:SetTexture(Smoothv2)
						self.Runes[i].bg:SetVertexColor(0,0,0,1)
						self.Runes[i].bg.multiplier = 0.64
						self.Runes[i]:Hide()
					end
				end
				
				local DruidMana = CreateFrame("StatusBar", nil, self)
				DruidMana:SetSize(self.Power:GetWidth(), 4);
				DruidMana:SetPoint("TOP",self.Power,"BOTTOM",0,0);
				DruidMana.colorPower = true
				DruidMana:SetStatusBarTexture(Smoothv2)

				-- Add a background
				local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
				Background:SetAllPoints(DruidMana)
				Background:SetTexture(1, 1, 1, .2)

				-- Register it with oUF
				self.DruidMana = DruidMana
				self.DruidMana.bg = Background
			end
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("LOW");
		ring:SetAllPoints(self.Portrait);
		ring:SetFrameLevel(3);
		
		self.Name = self:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(self:GetWidth(), 12);
		self.Name:SetJustifyH("LEFT");
		self.Name:SetPoint("TOPLEFT",self,"BOTTOMLEFT",0,-5);
		self:Tag(self.Name, "[level] [SUI_ColorClass][name]");
		
		self.Leader = self:CreateTexture(nil,"BORDER");
		self.Leader:SetSize(12, 12);
		self.Leader:SetPoint("RIGHT",self.Name,"LEFT");
		
		self.MasterLooter = self:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetSize(12, 12);
		self.MasterLooter:SetPoint("RIGHT",self.Leader,"LEFT");
		
		self.SUI_RaidGroup = self:CreateTexture(nil,"BORDER");
		self.SUI_RaidGroup:SetSize(12, 12);
		self.SUI_RaidGroup:SetPoint("TOPLEFT",self,"TOPLEFT")
		self.SUI_RaidGroup:SetTexture(square);
		self.SUI_RaidGroup:SetVertexColor(0,.8,.9,.9)
		
		self.SUI_RaidGroup.Text = self:CreateFontString(nil,"BORDER","SUI_Font10");
		self.SUI_RaidGroup.Text:SetSize(12, 12);
		self.SUI_RaidGroup.Text:SetJustifyH("CENTER");
		self.SUI_RaidGroup.Text:SetJustifyV("MIDDLE");
		self.SUI_RaidGroup.Text:SetPoint("CENTER",self.SUI_RaidGroup,"CENTER",0,1);
		self:Tag(self.SUI_RaidGroup.Text, "[group]");
		
		self.PvP = self:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25,25);
		self.PvP:SetPoint("CENTER",self,"BOTTOMRIGHT",0,-3);
		self.PvP.Override = pvpIcon
		
		self.Resting = self:CreateTexture(nil,"ARTWORK");
		self.Resting:SetSize(20,20);
		self.Resting:SetPoint("CENTER",self,"TOPLEFT");
		self.Resting:SetTexCoord(0.15,0.86,0.15,0.86)
		
		self.LFDRole = self:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(18, 18);
		self.LFDRole:SetPoint("CENTER",self,"LEFT",0,0);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		self.Combat = self:CreateTexture(nil,"ARTWORK");
		self.Combat:SetSize(20,20);
		self.Combat:SetPoint("CENTER",self.Resting,"CENTER");
		
		self.StatusText = self:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22");
		self.StatusText:SetPoint("CENTER",self,"CENTER");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
		
		if unit == "player" then
			local ClassIcons = {}
			for i = 1, 6 do
				local Icon = self:CreateTexture(nil, "OVERLAY")
				Icon:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
				
				if (i == 1) then
					Icon:SetPoint("LEFT",self.ComboPoints,"RIGHT",1,-1);
				else 
					Icon:SetPoint("LEFT",ClassIcons[i-1],"RIGHT",-2,0);
				end
				
				ClassIcons[i] = Icon
			end
			self.ClassIcons = ClassIcons
		
			local ClassPowerID = nil;
			ring:SetScript("OnEvent",function(a,b)
				if b == "PLAYER_SPECIALIZATION_CHANGED" then return end
				local cur, max
				if(unit == 'vehicle') then
					cur = GetComboPoints('vehicle', 'target')
					max = MAX_COMBO_POINTS
				else
					cur = UnitPower('player', ClassPowerID)
					max = UnitPowerMax('player', ClassPowerID)
				end
				self.ComboPoints:SetText((cur > 0 and cur) or "");
			end);
			
			ring:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', function()
				ClassPowerID = nil;
				if(classFileName == 'MONK') then
					ClassPowerID = SPELL_POWER_CHI
				elseif(classFileName == 'PALADIN') then
					ClassPowerID = SPELL_POWER_HOLY_POWER
				elseif(classFileName == 'WARLOCK') then
					ClassPowerID = SPELL_POWER_SOUL_SHARDS
				elseif(classFileName == 'ROGUE' or classFileName == 'DRUID') then
					ClassPowerID = SPELL_POWER_COMBO_POINTS
				elseif(classFileName == 'MAGE') then
					ClassPowerID = SPELL_POWER_ARCANE_CHARGES
				end
				if ClassPowerID ~= nil then 
					ring:RegisterEvent('UNIT_DISPLAYPOWER')
					ring:RegisterEvent('PLAYER_ENTERING_WORLD')
					ring:RegisterEvent('UNIT_POWER_FREQUENT')
					ring:RegisterEvent('UNIT_MAXPOWER')
				end
			end)
			
			if(classFileName == 'MONK') then
				ClassPowerID = SPELL_POWER_CHI
			elseif(classFileName == 'PALADIN') then
				ClassPowerID = SPELL_POWER_HOLY_POWER
			elseif(classFileName == 'WARLOCK') then
				ClassPowerID = SPELL_POWER_SOUL_SHARDS
			elseif(classFileName == 'ROGUE' or classFileName == 'DRUID') then
				ClassPowerID = SPELL_POWER_COMBO_POINTS
			elseif(classFileName == 'MAGE') then
				ClassPowerID = SPELL_POWER_ARCANE_CHARGES
			end
			if ClassPowerID ~= nil then 
				ring:RegisterEvent('UNIT_DISPLAYPOWER')
				ring:RegisterEvent('PLAYER_ENTERING_WORLD')
				ring:RegisterEvent('UNIT_POWER_FREQUENT')
				ring:RegisterEvent('UNIT_MAXPOWER')
			end
		end
	end
	do -- setup buffs and debuffs
		-- self.Debuffs = CreateFrame("Frame",nil,self);
		-- self.Debuffs:SetWidth(22*10); self.Debuffs:SetHeight(22*2);
		-- self.Debuffs:SetPoint("BOTTOMLEFT",self,"TOPLEFT",10,0);
		-- self.Debuffs:SetFrameStrata("BACKGROUND");
		-- self.Debuffs:SetFrameLevel(4);
		-- settings
		-- self.Debuffs.initialAnchor = "BOTTOMLEFT";
		-- self.Debuffs["growth-x"] = "RIGHT";
		-- self.Debuffs["growth-y"] = "UP";
		--self.Auras.gap = true;
		-- self.Debuffs.size = DBMod.PlayerFrames[unit].Auras.size;
		-- self.Debuffs.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
		-- self.Debuffs.showType = DBMod.PlayerFrames[unit].Auras.showType;
		--self.Auras.numBuffs = 1;
		--self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		-- self.Debuffs.num = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		
		--self.Auras.PostUpdate = PostUpdateAura;
		-- self.Debuffs.PostUpdate = PostUpdateAura;
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateSmallFrame = function(self,unit)
	self:SetSize(280, 80);
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER");
		self.artwork.bg:SetTexture(base_plate1);
		if unit == "target" then self.artwork.bg:SetTexCoord(1,0,0,1); end
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetSize(58, 58);
		self.Portrait:SetPoint("TOPRIGHT",self,"TOPRIGHT",-35,-15);
		--self.Portrait:SetPoint("BOTTOM",self,"BOTTOM",0,4);
		--if unit == "player" then self.Portrait:SetPoint("RIGHT",self,"RIGHT",-35,0); end
		--if unit == "target" then self.Portrait:SetPoint("CENTER",self,"CENTER",-80,3); end
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(185, 15);
			cast:SetPoint("TOPLEFT",self,"TOPLEFT",1,-24);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetSize(135, 11);
			cast.Text:SetJustifyH("RIGHT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("LEFT",cast,"LEFT",4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(90, 11);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"LEFT",2,0);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetStatusBarTexture(Smoothv2)
			-- health:AnimateTexCoords([[Interface\AddOns\SpartanUI_PlayerFrames\media\HealthBar.blp]], 256, 256, 80, 16, 40, elapsed, 0.08);
			health:SetSize(self.Castbar:GetWidth(), 24);
			health:SetPoint("TOPLEFT",self.Castbar,"BOTTOMLEFT",0,-2);
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetSize(135, 11);
			health.value:SetJustifyH("RIGHT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("LEFT",health,"LEFT",4,0);
			self:Tag(health.value, TextFormat("health"))
			
			-- health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			-- health.ratio:SetSize(90, 11);
			-- health.ratio:SetJustifyH("RIGHT"); health.ratio:SetJustifyV("MIDDLE");
			-- health.ratio:SetPoint("RIGHT",health,"LEFT",-2,0);
			-- self:Tag(health.ratio, '[perhp]%')
			
			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)
			
			self.Health = health;
			--self.Health.bg = Background;
			
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			-- if DBMod.PlayerFrames.bars[unit].color == "reaction" then
				-- self.Health.colorReaction = true;
			-- elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
				-- self.Health.colorHappiness = true;
			-- elseif DBMod.PlayerFrames.bars[unit].color == "class" then
				self.Health.colorClass = true;
			-- else
				-- self.Health.colorSmooth = true;
			-- end
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

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 3,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			power:SetSize(self.Castbar:GetWidth(), 8);
			power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-2);
			power:SetStatusBarTexture(Smoothv2)
			
			-- power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			-- power.value:SetWidth(135); power.value:SetHeight(11);
			-- power.value:SetJustifyH("RIGHT"); power.value:SetJustifyV("MIDDLE");
			-- power.value:SetPoint("LEFT",power,"LEFT",4,0);
			-- self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline8");
			power.ratio:SetSize(power:GetSize());
			power.ratio:SetJustifyH("CENTER"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetAllPoints(power);
			--power.ratio:SetPoint("RIGHT",power,"LEFT",-2,0);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
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
					self.Runes[i]:SetWidth((245 - 5) / 6)
					if (i == 1) then
						self.Runes[i]:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -3)
					else
						self.Runes[i]:SetPoint("TOPLEFT", self.Runes[i-1], "TOPRIGHT", 1, 0)
					end
					self.Runes[i]:SetStatusBarTexture(Smoothv2)
					self.Runes[i]:SetStatusBarColor(0,.39,.63,1)

					self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
					self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", -0, 0)
					self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, -0)				
					self.Runes[i].bg:SetTexture(Smoothv2)
					self.Runes[i].bg:SetVertexColor(0,0,0,1)
					self.Runes[i].bg.multiplier = 0.64
					self.Runes[i]:Hide()
				end
			end
			
			local DruidMana = CreateFrame("StatusBar", nil, self)
			DruidMana:SetSize(self.Power:GetWidth(), 4);
			DruidMana:SetPoint("TOP",self.Power,"BOTTOM",0,0);
			DruidMana.colorPower = true
			DruidMana:SetStatusBarTexture(Smoothv2)

			-- Add a background
			local Background = DruidMana:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(DruidMana)
			Background:SetTexture(1, 1, 1, .2)

			-- Register it with oUF
			self.DruidMana = DruidMana
			self.DruidMana.bg = Background
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("LOW");
		ring:SetAllPoints(self.Portrait);
		ring:SetFrameLevel(3);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(135, 12);
		self.Name:SetJustifyH("RIGHT");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",47,-7);
		self:Tag(self.Name, "[level] [SUI_ColorClass][name]");
		
		self.Leader = ring:CreateTexture(nil,"BORDER");
		self.Leader:SetWidth(20); self.Leader:SetHeight(20);
		self.Leader:SetPoint("CENTER",ring,"TOP");
		
		self.MasterLooter = ring:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetSize(18, 18);
		self.MasterLooter:SetPoint("CENTER",self.Portrait,"BOTTOM",0,0);
		
		self.SUI_RaidGroup = ring:CreateTexture(nil,"BORDER");
		self.SUI_RaidGroup:SetSize(15, 15);
		self.SUI_RaidGroup:SetPoint("CENTER",self.Portrait,"TOP",0,7);
		self.SUI_RaidGroup:SetTexture(square);
		self.SUI_RaidGroup:SetVertexColor(0,.8,.9,.9)
		
		self.SUI_RaidGroup.Text = ring:CreateFontString(nil,"BORDER","SUI_Font10");
		self.SUI_RaidGroup.Text:SetSize(15, 15);
		self.SUI_RaidGroup.Text:SetJustifyH("CENTER"); self.SUI_RaidGroup.Text:SetJustifyV("MIDDLE");
		self.SUI_RaidGroup.Text:SetPoint("CENTER",self.SUI_RaidGroup,"CENTER",0,1);
		self:Tag(self.SUI_RaidGroup.Text, "[group]");
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetSize(25, 25);
		self.PvP:SetPoint("CENTER",ring,"BOTTOMRIGHT",0,0);
		self.PvP.Override = pvpIcon
		
		self.Resting = ring:CreateTexture(nil,"ARTWORK");
		self.Resting:SetSize(25, 25);
		self.Resting:SetPoint("CENTER",ring,"TOPLEFT");
		self.Resting:SetTexCoord(0.15,0.86,0.15,0.86)
		
		self.LFDRole = ring:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(18, 18);
		self.LFDRole:SetPoint("CENTER",ring,"TOP",20,7);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		self.Combat = ring:CreateTexture(nil,"ARTWORK");
		self.Combat:SetSize(30,30);
		self.Combat:SetPoint("CENTER",ring,"RIGHT");
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(20,20);
		self.RaidIcon:SetPoint("CENTER",ring,"CENTER",0,20);
		
		self.StatusText = ring:CreateFontString(nil, "OVERLAY", "SUI_FontOutline22");
		self.StatusText:SetPoint("CENTER",ring,"CENTER");
		self.StatusText:SetJustifyH("CENTER");
		self:Tag(self.StatusText, "[afkdnd]");
		
		self.ComboPoints = ring:CreateFontString(nil, "BORDER","SUI_FontOutline13");
		self.ComboPoints:SetPoint("BOTTOMLEFT",self.Name,"TOPLEFT",40,6);
		
		local ClassIcons = {}
		for i = 1, 6 do
			local Icon = self:CreateTexture(nil, "OVERLAY")
			Icon:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
			
			if (i == 1) then
				Icon:SetPoint("LEFT",self.ComboPoints,"RIGHT",1,-1);
			else 
				Icon:SetPoint("LEFT",ClassIcons[i-1],"RIGHT",-2,0);
			end
			
			ClassIcons[i] = Icon
		end
		self.ClassIcons = ClassIcons
		
		local ClassPowerID = nil;
		ring:SetScript("OnEvent",function(a,b)
			if b == "PLAYER_SPECIALIZATION_CHANGED" then return end
			local cur, max
			if(unit == 'vehicle') then
				cur = GetComboPoints('vehicle', 'target')
				max = MAX_COMBO_POINTS
			else
				cur = UnitPower('player', ClassPowerID)
				max = UnitPowerMax('player', ClassPowerID)
			end
			self.ComboPoints:SetText((cur > 0 and cur) or "");
		end);
		
		ring:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', function()
			ClassPowerID = nil;
			if(classFileName == 'MONK') then
				ClassPowerID = SPELL_POWER_CHI
			elseif(classFileName == 'PALADIN') then
				ClassPowerID = SPELL_POWER_HOLY_POWER
			elseif(classFileName == 'WARLOCK') then
				ClassPowerID = SPELL_POWER_SOUL_SHARDS
			elseif(classFileName == 'ROGUE' or classFileName == 'DRUID') then
				ClassPowerID = SPELL_POWER_COMBO_POINTS
			elseif(classFileName == 'MAGE') then
				ClassPowerID = SPELL_POWER_ARCANE_CHARGES
			end
			if ClassPowerID ~= nil then 
				ring:RegisterEvent('UNIT_DISPLAYPOWER')
				ring:RegisterEvent('PLAYER_ENTERING_WORLD')
				ring:RegisterEvent('UNIT_POWER_FREQUENT')
				ring:RegisterEvent('UNIT_MAXPOWER')
			end
		end)
		
		if(classFileName == 'MONK') then
			ClassPowerID = SPELL_POWER_CHI
		elseif(classFileName == 'PALADIN') then
			ClassPowerID = SPELL_POWER_HOLY_POWER
		elseif(classFileName == 'WARLOCK') then
			ClassPowerID = SPELL_POWER_SOUL_SHARDS
		elseif(classFileName == 'ROGUE' or classFileName == 'DRUID') then
			ClassPowerID = SPELL_POWER_COMBO_POINTS
		elseif(classFileName == 'MAGE') then
			ClassPowerID = SPELL_POWER_ARCANE_CHARGES
		end
		if ClassPowerID ~= nil then 
			ring:RegisterEvent('UNIT_DISPLAYPOWER')
			ring:RegisterEvent('PLAYER_ENTERING_WORLD')
			ring:RegisterEvent('UNIT_POWER_FREQUENT')
			ring:RegisterEvent('UNIT_MAXPOWER')
		end
	end

	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateRaidFrame = function(self,unit)

end

local CreateUnitFrame = function(self,unit)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent);
	else
		self:SetParent(SUI_FramesAnchor);
	end
	
	self = ((unit == "target" and CreateLargeFrame(self,unit))
	or (unit == "player" and CreateLargeFrame(self,unit))
	or (unit == "targettarget" and CreateRaidFrame(self,unit))
	or (unit == "focus" and CreateRaidFrame(self,unit))
	or (unit == "focustarget" and CreateRaidFrame(self,unit))
	or (unit == "pet" and CreateRaidFrame(self,unit))
	or CreateSmallFrame(self,unit));
	
	self = PlayerFrames:MakeMovable(self,unit)
	
	return self
end

local CreateUnitFrameParty = function(self,unit)
	self = CreateSmallFrame(self,unit)
	self = PartyFrames:MakeMovable(self)
	return self
end

local CreateUnitFrameRaid = function(self,unit)
	self = CreateRaidFrame(self,unit)
	self = spartan:GetModule("RaidFrames"):MakeMovable(self)
	return self
end

SpartanoUF:RegisterStyle("Spartan_FelPlayerFrames", CreateUnitFrame);
SpartanoUF:RegisterStyle("Spartan_FelPartyFrames", CreateUnitFrameParty);
SpartanoUF:RegisterStyle("Spartan_FelRaidFrames", CreateUnitFrameRaid);
	
function module:PlayerFrames()
	SpartanoUF:SetActiveStyle("Spartan_FelPlayerFrames");
	
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}

	for a,b in pairs(FramesList) do
		PlayerFrames[b] = SpartanoUF:Spawn(b,"SUI_"..b.."Frame");
		if b == "player" then PlayerFrames:SetupExtras() end
		PlayerFrames[b].artwork.bg:SetVertexColor(0,.8,.9,.9)
	end
	
	module:PositionFrame()
	module:UpdateAltBarPositions();
	
	if DBMod.PlayerFrames.BossFrame.display == true then
		if (InCombatLockdown()) then return; end
		local boss = {}
		for i = 1, MAX_BOSS_FRAMES do
			boss[i] = SpartanoUF:Spawn('boss'..i, 'SUI_Boss'..i)
			boss[i].artwork.bg:SetVertexColor(0,.8,.9,.9)
		
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
			if (InCombatLockdown()) then return; end
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
	spartan.PlayerFrames = PlayerFrames
	
	local unattached = false
	Fel_SpartanUI:HookScript("OnHide", function(this, event)
		if UnitUsingVehicle("player") then
			SUI_FramesAnchor:SetParent(UIParent)
			unattached = true
		end
	end)
	
	Fel_SpartanUI:HookScript("OnShow", function(this, event)
		if unattached then
			SUI_FramesAnchor:SetParent(Fel_SpartanUI)
			module:PositionFrame()
		end
	end)
end

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
		EclipseBarFrame:SetPoint("TOPRIGHT",PlayerFrames.player,"TOPRIGHT",157,12);
	end
	
	if RuneFrame then RuneFrame:Hide() end
	
	-- Hide the AlternatePowerBar
	if PlayerFrameAlternateManaBar then
		PlayerFrameAlternateManaBar:Hide()
		PlayerFrameAlternateManaBar.Show = PlayerFrameAlternateManaBar.Hide
	end
end

function module:PositionFrame(b)
	if Fel_SpartanUI_Left then
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOMRIGHT",Fel_SpartanUI_Left,"TOPLEFT",-60,10); end
	else
		if b == "player" or b == nil then PlayerFrames.player:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOM",-60,250); end
	end
	
	if b == "pet" or b == nil then PlayerFrames.pet:SetPoint("RIGHT",PlayerFrames.player,"BOTTOMLEFT",-4,0); end
	
	if b == "target" or b == nil then PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",150,0); end
	if b == "targettarget" or b == nil then PlayerFrames.targettarget:SetPoint("LEFT",PlayerFrames.target,"BOTTOMRIGHT",4,0); end
	
	if b == "focus" or b == nil then PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30); end
	if b == "focustarget" or b == nil then PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", 5, 0); end
	
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
	for a,b in pairs(FramesList) do
		PlayerFrames[b]:SetScale(DB.scale);
	end
end

function module:RaidFrames()
	SpartanoUF:SetActiveStyle("Spartan_FelRaidFrames");
	
	local xoffset = 3
	local yOffset = -5
	local point = 'TOP'
	local columnAnchorPoint = 'LEFT'
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
	
	if DBMod.RaidFrames.mode == "GROUP" then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	
	local raid = SpartanoUF:SpawnHeader(nil, nil, 'raid',
		"showRaid", DBMod.RaidFrames.showRaid,
		"showParty", DBMod.RaidFrames.showParty,
		"showPlayer", DBMod.RaidFrames.showPlayer,
		"showSolo", DBMod.RaidFrames.showSolo,
		'xoffset', xoffset,
		'yOffset', yOffset,
		'point', point,
		'groupBy', DBMod.RaidFrames.mode,
		'groupingOrder', groupingOrder,
		'sortMethod', 'index',
		'maxColumns', DBMod.RaidFrames.maxColumns,
		'unitsPerColumn', DBMod.RaidFrames.unitsPerColumn,
		'columnSpacing', DBMod.RaidFrames.columnSpacing,
		'columnAnchorPoint', columnAnchorPoint
	)
	
	raid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -40)
	
	return (raid)
end

function module:PartyFrames()
	SpartanoUF:SetActiveStyle("Spartan_FelPartyFrames");
	
	local party = SpartanoUF:SpawnHeader("SUI_PartyFrameHeader", nil, nil,
		"showRaid", DBMod.PartyFrames.showRaid,
		"showParty", DBMod.PartyFrames.showParty,
		"showPlayer", DBMod.PartyFrames.showPlayer,
		"showSolo", DBMod.PartyFrames.showSolo,
		"yOffset", -16,
		"xOffset", 0,
		"columnAnchorPoint", "TOPLEFT",
		"initial-anchor", "TOPLEFT");
	
	return (party)
end