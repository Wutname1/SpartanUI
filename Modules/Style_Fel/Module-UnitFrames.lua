local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local module = spartan:GetModule("Style_Fel");
local PlayerFrames = spartan:GetModule("PlayerFrames");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

-- Create Frames
local CreateLargeFrame = function(self,unit)
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
	do -- setup buffs and debuffs
		self.Debuffs = CreateFrame("Frame",nil,self);
		self.Debuffs:SetWidth(22*10); self.Debuffs:SetHeight(22*2);
		self.Debuffs:SetPoint("BOTTOMLEFT",self,"TOPLEFT",10,0);
		self.Debuffs:SetFrameStrata("BACKGROUND");
		self.Debuffs:SetFrameLevel(4);
		-- settings
		self.Debuffs.initialAnchor = "BOTTOMLEFT";
		self.Debuffs["growth-x"] = "RIGHT";
		self.Debuffs["growth-y"] = "UP";
		--self.Auras.gap = true;
		self.Debuffs.size = DBMod.PlayerFrames[unit].Auras.size;
		self.Debuffs.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
		self.Debuffs.showType = DBMod.PlayerFrames[unit].Auras.showType;
		--self.Auras.numBuffs = 1;
		--self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		self.Debuffs.num = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		
		--self.Auras.PostUpdate = PostUpdateAura;
		self.Debuffs.PostUpdate = PostUpdateAura;
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
	do -- setup buffs and debuffs
		self.Debuffs = CreateFrame("Frame",nil,self);
		self.Debuffs:SetWidth(22*10); self.Debuffs:SetHeight(22*2);
		self.Debuffs:SetPoint("BOTTOMLEFT",self,"TOPLEFT",10,0);
		self.Debuffs:SetFrameStrata("BACKGROUND");
		self.Debuffs:SetFrameLevel(4);
		-- settings
		self.Debuffs.initialAnchor = "BOTTOMLEFT";
		self.Debuffs["growth-x"] = "RIGHT";
		self.Debuffs["growth-y"] = "UP";
		--self.Auras.gap = true;
		self.Debuffs.size = DBMod.PlayerFrames[unit].Auras.size;
		self.Debuffs.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
		self.Debuffs.showType = DBMod.PlayerFrames[unit].Auras.showType;
		--self.Auras.numBuffs = 1;
		--self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		self.Debuffs.num = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		
		--self.Auras.PostUpdate = PostUpdateAura;
		self.Debuffs.PostUpdate = PostUpdateAura;
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

SpartanoUF:RegisterStyle("Spartan_TransparentPlayerFrames", CreateUnitFrame);
SpartanoUF:RegisterStyle("Spartan_TransparentPartyFrames", CreateUnitFrameParty);
SpartanoUF:RegisterStyle("Spartan_TransparentRaidFrames", CreateUnitFrameRaid);
	
function module:PlayerFrames()
	SpartanoUF:SetActiveStyle("Spartan_TransparentPlayerFrames");
	
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
	Transparent_SpartanUI:HookScript("OnHide", function(this, event)
		if UnitUsingVehicle("player") then
			SUI_FramesAnchor:SetParent(UIParent)
			unattached = true
		end
	end)
	
	Transparent_SpartanUI:HookScript("OnShow", function(this, event)
		if unattached then
			SUI_FramesAnchor:SetParent(Transparent_SpartanUI)
			module:PositionFrame()
		end
	end)
end

function module:RaidFrames()
	SpartanoUF:SetActiveStyle("Spartan_TransparentRaidFrames");
	
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
	SpartanoUF:SetActiveStyle("Spartan_TransparentPartyFrames");
	
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