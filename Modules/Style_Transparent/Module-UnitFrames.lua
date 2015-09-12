local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Transparent");
local PlayerFrames = spartan:GetModule("PlayerFrames");
local PartyFrames = spartan:GetModule("PartyFrames");
----------------------------------------------------------------------------------------------------

local base_plate1 = [[Interface\AddOns\SpartanUI_Style_Transparent\Images\base_plate1.tga]] -- Player and Target
local base_plate2 = [[Interface\AddOns\SpartanUI_Style_Transparent\Images\base_plate2.blp]] -- Focus and Focus Target
local base_plate4 = [[Interface\AddOns\SpartanUI_Style_Transparent\Images\base_plate4.blp]] -- TargetTarget small
local square = [[Interface\AddOns\SpartanUI_Style_Transparent\Images\square.tga]]

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

-- Create Frames
local CreatePlayerFrame = function(self,unit)
	self:SetSize(280, 80);
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(0);
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
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
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
			if unit == "player" and playerClass == "DRUID" then
				local DruidMana = CreateFrame("StatusBar", nil, self)
				DruidMana:SetSize(self:GetWidth(), 4);
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
			elseif unit == "player" and playerClass =="DEATHKNIGHT" then	
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

					self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
					self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", -0, 0)
					self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, -0)				
					self.Runes[i].bg:SetTexture(Smoothv2)
					self.Runes[i].bg.multiplier = 0.34
					
				end
			elseif unit == "player" and (playerClass =="MONK" or playerClass =="PALADIN" or playerClass =="PRIEST" or playerClass =="WARLOCK") then
				local ClassIcons = {}
				for index = 1, 6 do
					local Icon = self:CreateTexture(nil, 'BORDER')

					-- Position and size.
					Icon:SetSize(16, 16)
					Icon:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
					Icon:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', index * Icon:GetWidth(), -3)
					
					
					Icon.bg = self:CreateTexture(nil, "BACKGROUND")
					Icon.bg:SetSize(16, 16)
					Icon.bg:SetTexture([[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_combo]]);
					Icon.bg:SetVertexColor(.4, .4, .4, .7)
					Icon.bg:SetAllPoints(Icon)

					ClassIcons[index] = Icon
				end
			end
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
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

local CreateTargetFrame = function(self,unit)
	self:SetSize(280, 80);
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2); self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER");
		self.artwork.bg:SetTexture(base_plate1);
		self.artwork.bg:SetTexCoord(1,0,0,1);
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetSize(58, 58);
		self.Portrait:SetPoint("TOPLEFT",self,"TOPLEFT",35,-15);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(184, 16);
			cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",-1,-23);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetSize(135,11);
			cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("RIGHT",cast,"RIGHT",-4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(90,11);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(self.Castbar:GetWidth(), 24);
			health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetWidth(135); health.value:SetHeight(11);
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("RIGHT",health,"RIGHT",-4,0);
			self:Tag(health.value, TextFormat("health"))	
			
			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)
			
			self.Health = health;
			--self.Health.bg = Background;
			self.Health.colorTapping = true;
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
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(self.Castbar:GetWidth(), 8);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetSize(135, 11);
			power.value:SetJustifyH("CENTER"); power.value:SetJustifyV("MIDDLE");
			power.value:SetAllPoints(power);
			self:Tag(power.value, TextFormat("mana"))
			
			self.Power = power;
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
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(135, 12);
		self.Name:SetJustifyH("LEFT");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",95,-7);
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
		
		self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		self.SUI_ClassIcon:SetSize(18,18);
		self.SUI_ClassIcon:SetPoint("RIGHT",self.Name,"LEFT");
		self.SUI_ClassIcon:SetAlpha(.75);
		
		self.Leader = ring:CreateTexture(nil,"BORDER");
		self.Leader:SetSize(18,18);
		self.Leader:SetPoint("CENTER",ring,"TOP");
		
		self.MasterLooter = ring:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetSize(18,18);
		self.MasterLooter:SetPoint("CENTER",self.Portrait,"BOTTOM",0,0);
		
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
		self.Auras = CreateFrame("Frame",nil,self);
		self.Auras:SetWidth(22*10); self.Auras:SetHeight(22*2);
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
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreatePetFrame = function(self,unit)
		self:SetSize(124, 55);
		self:SetAlpha(.75)
		do -- setup base artwork
			self.artwork = CreateFrame("Frame",nil,self);
			self.artwork:SetFrameStrata("BACKGROUND");
			self.artwork:SetFrameLevel(0);
			self.artwork:SetAllPoints(self);
			
			self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
			self.artwork.bg:SetPoint("CENTER");
			self.artwork.bg:SetTexture(base_plate2);
			
			self.Threat = CreateFrame("Frame",nil,self);
			self.Threat.Override = threat;
		end
		do -- setup status bars
			do -- health bar
				local health = CreateFrame("StatusBar",nil,self);
				health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
				health:SetSize(135, 16);
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",6,-28);
				health:SetStatusBarTexture(Smoothv2)
				
				
				health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.ratio:SetJustifyH("CENTER"); health.ratio:SetJustifyV("MIDDLE");
				health.ratio:SetAllPoints(health);
				self:Tag(health.ratio, '[perhp]%')
				
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
			end
			do -- power bar
				local power = CreateFrame("StatusBar",nil,self);
				power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
				power:SetSize(135, 8);
				power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-1);
				power:SetStatusBarTexture(Smoothv2)
				
				power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				power.value:SetAllPoints(power);
				power.value:SetJustifyH("CENTER");
				power.value:SetJustifyV("MIDDLE");
				self:Tag(power.value, "[perpp]%")
				
				self.Power = power;
				self.Power.colorPower = true;
				self.Power.frequentUpdates = true;
			end
		end
		do -- setup ring, icons, and text
			local ring = CreateFrame("Frame",nil,self);
			ring:SetFrameStrata("BACKGROUND");
			ring:SetPoint("TOPLEFT",self.artwork,"TOPLEFT",0,0); ring:SetFrameLevel(3);
			
			self.Name = ring:CreateFontString();
			spartan:FormatFont(self.Name, 12, "Player")
			self.Name:SetSize(95, 12); 
			self.Name:SetJustifyH("RIGHT");
			self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",6,-11);
			if DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
			else
				self:Tag(self.Name, "[difficulty][level] [name]");
			end
			
		end
		self.TextUpdate = PostUpdateText;
		self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateToTFrame = function(self,unit)
	self:SetSize(124, 55);
	self:SetAlpha(.75)
	if unit == "focustarget" then
		self:SetScale(0.75)
	end
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(0);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER");
		self.artwork.bg:SetTexture(base_plate2);
		self.artwork.bg:SetTexCoord(1,0,0,1);
		-- self.artwork.bg:SetSize(170, 80);
		-- self.artwork.bg:SetTexCoord(.68,0,0,0.6640625);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetSize(135, 16);
			health:SetPoint("TOPLEFT",self,"TOPLEFT",-6,-28);
			health:SetStatusBarTexture(Smoothv2)
			
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			--health.ratio:SetWidth(40); health.ratio:SetHeight(11);
			health.ratio:SetJustifyH("CENTER"); health.ratio:SetJustifyV("MIDDLE");
			health.ratio:SetAllPoints(health);
			self:Tag(health.ratio, '[perhp]%')
			
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
			myBars:SetStatusBarTexture(Smoothv2)
			myBars:SetStatusBarColor(0, 1, 0.5, 0.35)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture(Smoothv2)
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.25)

			myBars:SetSize(150, 16)
			otherBars:SetSize(150, 16)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			power:SetSize(135, 8);
			power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-1);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetAllPoints(power);
			power.value:SetJustifyH("CENTER");
			power.value:SetJustifyV("MIDDLE");
			self:Tag(power.value, "[perpp]%")
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
	end
	do -- setup ring, icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetPoint("TOPLEFT",self.artwork,"TOPLEFT",0,0);
		ring:SetFrameLevel(3);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(95, 12); 
		self.Name:SetJustifyH("LEFT");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",-6,-11);
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[difficulty][level] [name]");
		end
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(20, 20);
		self.RaidIcon:SetPoint("LEFT",self,"RIGHT",3,0);
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	return self;
end

local CreateBossFrame = function(self,unit)
	self:SetSize(105, 60);
	self:SetAlpha(.8)
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER");
		self.artwork.bg:SetTexture(base_plate1);
		self.artwork.bg:SetTexCoord(0.22,0.59,0.21,0.79)
		self.artwork.bg:SetAllPoints(self);
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(100, 13);
			cast:SetPoint("TOPLEFT",self,"TOPLEFT",3,-16);
			cast:SetStatusBarTexture(Smoothv2)
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetSize(97, 10);
			cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("LEFT",cast,"LEFT",4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(50, 10);
			cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(100, 19);
			health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetAllPoints(health);
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			self:Tag(health.value, TextFormat("health"))	
			
			self.Health = health;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			self.Health.colorReaction = true;
			
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

			myBars:SetSize(105, 12)
			otherBars:SetSize(105, 12)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(100, 8);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
			power:SetStatusBarTexture(Smoothv2)
			
			power.value = power:CreateFontString();
			spartan:FormatFont(power.value, 8, "Player")
			power.value:SetAllPoints(power);
			power.value:SetJustifyH("CENTER");
			power.value:SetJustifyV("MIDDLE");
			self:Tag(power.value, TextFormat("mana"))
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup icons, and text
		local items = CreateFrame("Frame",nil,self);
		items:SetFrameStrata("BACKGROUND");
		items:SetAllPoints(self);
		items:SetFrameLevel(3);
		
		self.Name = items:CreateFontString();
		spartan:FormatFont(self.Name, 10, "Player")
		self.Name:SetSize(70, 10); 
		self.Name:SetJustifyH("RIGHT");
		self.Name:SetJustifyV("MIDDLE");
		self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-3,-2);
		self:Tag(self.Name, "[SUI_ColorClass][name]");
		
		self.LevelSkull = items:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("RIGHT",self.Name ,"LEFT",2,0);
		
		self.RaidIcon = items:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(18, 18);
		self.RaidIcon:SetPoint("CENTER",self,"RIGHT",0,0);
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 1/2,
	}
	
	--Make Boss Frames Movable
	self:EnableMouse(enable)
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			-- PlayerFrames.boss.mover:Show();
			-- DBMod.PlayerFrames.BossFrame.movement.moved = true;
			-- PlayerFrames.boss.mover:SetMovable(true);
			-- PlayerFrames.boss.mover:StartMoving();
			
			PlayerFrames.boss.mover:Show();
			DBMod.PlayerFrames.BossFrame.movement.moved = true;
			SUI_Boss1:SetMovable(true);
			SUI_Boss1:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		PlayerFrames.boss.mover:Hide();
		SUI_Boss1:StopMovingOrSizing();
		DBMod.PlayerFrames.BossFrame.movement.point,
		DBMod.PlayerFrames.BossFrame.movement.relativeTo,
		DBMod.PlayerFrames.BossFrame.movement.relativePoint,
		DBMod.PlayerFrames.BossFrame.movement.xOffset,
		DBMod.PlayerFrames.BossFrame.movement.yOffset = SUI_Boss1:GetPoint(SUI_Boss1:GetNumPoints())
		PlayerFrames:UpdateBossFramePosition();
	end);
	
	return self;
end

local CreateRaidFrame = function(self,unit)
	self:SetSize(95, 40);
	self:SetAlpha(.8)
	do --setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(2);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetPoint("CENTER");
		self.artwork.bg:SetTexture(base_plate1);
		self.artwork.bg:SetTexCoord(0.22,0.59,0.36,0.79)
		self.artwork.bg:SetVertexColor(0,.8,.9,.9)
		self.artwork.bg:SetAllPoints(self);
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(3);
			health:SetSize(101, 17);
			health:SetPoint("TOPLEFT",self,"TOPLEFT",3,-14);
			health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-1,-14);
			health:SetStatusBarTexture(Smoothv2)
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetAllPoints(health);
			health.value:SetJustifyH("CENTER");
			health.value:SetJustifyV("MIDDLE");
			-- self:Tag(health.value, TextFormat("health"))	
			self:Tag(health.value, "[perhp]% ([missinghpdynamic])")	
			
			self.Health = health;
			self.Health.colorTapping = true;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			self.Health.colorReaction = true;
			
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

			myBars:SetSize(105, 12)
			otherBars:SetSize(105, 12)
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(3);
			power:SetSize(101, 4);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
			power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-2);
			power:SetStatusBarTexture(Smoothv2)
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup icons, and text
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		local items = CreateFrame("Frame",nil,self);
		items:SetFrameStrata("BACKGROUND");
		items:SetAllPoints(self);
		items:SetFrameLevel(3);
		
		self.Name = items:CreateFontString();
		spartan:FormatFont(self.Name, 10, "Player")
		self.Name:SetSize(70, 10); 
		self.Name:SetJustifyH("CENTER");
		self.Name:SetJustifyV("MIDDLE");
		self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-2,0);
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",20,0);
		self:Tag(self.Name, "[SUI_ColorClass][name]");
		
		self.LFDRole = items:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(15, 15);
		self.LFDRole:SetPoint("TOPLEFT",self,"TOPLEFT",-1,-2);
		self.LFDRole:SetTexture(lfdrole);
		self.LFDRole:SetAlpha(.75);
		
		self.RaidIcon = items:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(18, 18);
		self.RaidIcon:SetPoint("CENTER",self,"RIGHT",0,0);
		
		self.ResurrectIcon = items:CreateTexture(nil, 'OVERLAY')
		self.ResurrectIcon:SetSize(30, 30)
		self.ResurrectIcon:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ResurrectIcon = ResurrectIcon

		self.ReadyCheck = items:CreateTexture(nil, 'OVERLAY')
		self.ReadyCheck:SetSize(30, 30)
		self.ReadyCheck:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ReadyCheck = ReadyCheck
	   
		local overlay = items:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights");
		overlay:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
		overlay:SetAllPoints(self)
		overlay:SetVertexColor(1, 0, 0)
		overlay:Hide();
		self.ThreatOverlay = overlay
			
	end
	do --Hots Displays
		local auras = {}
		local class, classFileName = UnitClass("player");
		local spellIDs ={}
		if classFileName == "DRUID" then
			spellIDs = {
				774, -- Rejuvenation
				33763, -- Lifebloom
				8936, -- Regrowth
				102351, -- Cenarion Ward
				48438, -- Wild Growth
				155777, -- Germination
				102342, -- Ironbark
			}
		elseif classFileName == "PRIEST" then
			spellIDs = {
				139, -- Renew
				17, -- sheild
				33076, -- Prayer of Mending
			}
		end
		auras.presentAlpha = 1
		auras.onlyShowPresent = true
		auras.PostCreateIcon = myCustomIconSkinnerFunction
		-- Set any other AuraWatch settings
		auras.icons = {}
		for i, sid in pairs(spellIDs) do
			local icon = CreateFrame("Frame", nil, self)
			icon.spellID = sid
			-- set the dimensions and positions
			icon:SetSize(DBMod.PartyFrames.Auras.size, DBMod.PartyFrames.Auras.size)
			icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", (-icon:GetWidth()*i)-2, 0)
			auras.icons[sid] = icon
			-- Set any other AuraWatch icon settings
		end
		self.AuraWatch = auras
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
	
	self:SetFrameStrata("BACKGROUND");
	self:SetFrameLevel(1);
	self:RegisterForClicks("anyup");
	self:SetAttribute("*type2", "menu");
	self.colors = module.colors;
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	return ((unit == "target" and CreateTargetFrame(self,unit))
	or (unit == "targettarget" and CreateToTFrame(self,unit))
	or (unit == "player" and CreatePlayerFrame(self,unit))
	or (unit == "focus" and CreateBossFrame(self,unit))
	or (unit == "focustarget" and CreateToTFrame(self,unit))
	or (unit == "pet" and CreatePetFrame(self,unit))
	or CreateBossFrame(self,unit));
end

local CreatespecFrames = function(self,unit)
	self.menu = menu;
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		self:SetParent(UIParent);
	else
		self:SetParent(SUI_FramesAnchor);
	end
	
	self:SetFrameStrata("BACKGROUND");
	self:SetFrameLevel(1);
	
	return CreateRaidFrame(self,unit);
end

local CreateUnitFrameParty = function(self,unit)
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			PartyFrames.party.mover:Show();
			DBMod.PartyFrames.moved = true;
			PartyFrames.party:SetMovable(true);
			PartyFrames.party:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		PartyFrames.party.mover:Hide();
		PartyFrames.party:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = PartyFrames.party:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.PartyFrames.Anchors[k] = v
		end
	end);
	
	return CreateRaidFrame(self,unit)
end

local CreateUnitFrameRaid = function(self,unit)
	self = CreateRaidFrame(self,unit)
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			spartan.RaidFrames.mover:Show();
			DBMod.RaidFrames.moved = true;
			spartan.RaidFrames:SetMovable(true);
			spartan.RaidFrames:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		spartan.RaidFrames.mover:Hide();
		spartan.RaidFrames:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = spartan.RaidFrames:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.RaidFrames.Anchors[k] = v
		end
	end);
	
	return self
end

SpartanoUF:RegisterStyle("Spartan_TransparentPlayerFrames", CreateUnitFrame);
SpartanoUF:RegisterStyle("Spartan_TransparentPartyFrames", CreateUnitFrameParty);
SpartanoUF:RegisterStyle("Spartan_TransparentRaidFrames", CreateUnitFrameRaid);
	
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
	
	-- Monk Chi Bar (Hard to move but it is doable.)
	MonkHarmonyBar.Show = MonkHarmonyBar.Hide
	MonkHarmonyBar:Hide()
	
	--Paladin Holy Power
	PaladinPowerBar.Show = MonkHarmonyBar.Hide
	PaladinPowerBar:Hide()
	
	--Priest Power Frame
	PriestBarFrame.Show = MonkHarmonyBar.Hide
	PriestBarFrame:Hide()
	
	--Warlock Power Frame
	WarlockPowerFrame.Show = MonkHarmonyBar.Hide
	WarlockPowerFrame:Hide()
	
	-- relocate the AlternatePowerBar
	if classFileName == "DRUID" then
		PlayerFrameAlternateManaBar:Hide()
		PlayerFrameAlternateManaBar.Show = PlayerFrameAlternateManaBar.Hide
	elseif classFileName ~= "MONK" then
		PlayerFrameAlternateManaBar:ClearAllPoints();
		if DBMod.PlayerFrames.AltManaBar.movement.moved then
			PlayerFrameAlternateManaBar:SetPoint(DBMod.PlayerFrames.AltManaBar.movement.point,
			DBMod.PlayerFrames.AltManaBar.movement.relativeTo,
			DBMod.PlayerFrames.AltManaBar.movement.relativePoint,
			DBMod.PlayerFrames.AltManaBar.movement.xOffset,
			DBMod.PlayerFrames.AltManaBar.movement.yOffset);
		else
			PlayerFrameAlternateManaBar:SetPoint("TOPLEFT",PlayerFrames.player,"BOTTOMLEFT",40,0);
		end
	end
end

function module:PositionFrame(b)
	if (SUI_FramesAnchor:GetParent() == UIParent) then
		if b == nil or b == "player" then PlayerFrames.player:SetPoint("BOTTOM",UIParent,"BOTTOM",-220,150); end
		if b == nil or b == "pet" then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-6,4); end
		if b == nil or b == "target" then PlayerFrames.target:SetPoint("LEFT",PlayerFrames.player,"RIGHT",100,0); end
		
		-- if DBMod.PlayerFrames.targettarget.style == "small" then
		if b == nil or b == "targettarget" then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11); end
		-- else
			-- PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",-20,0);
		-- end
		
		PlayerFrames.player:SetScale(DB.scale);
		for a,b in pairs(FramesList) do
			_G["SUI_"..b.."Frame"]:SetScale(DB.scale);
		end
	else
		if b == nil or b == "player" then PlayerFrames.player:SetPoint("BOTTOMRIGHT",SUI_FramesAnchor,"TOP",-72,-3); end
		if b == nil or b == "pet" then PlayerFrames.pet:SetPoint("BOTTOMRIGHT",PlayerFrames.player,"BOTTOMLEFT",-6,4); end
		if b == nil or b == "target" then PlayerFrames.target:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",72,-3); end
		-- if DBMod.PlayerFrames.targettarget.style == "small" then
			-- PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",8,-11);
		-- else
		if b == nil or b == "targettarget" then PlayerFrames.targettarget:SetPoint("BOTTOMLEFT",PlayerFrames.target,"BOTTOMRIGHT",6,4); end
		-- end
	end
	
	if b == nil or b == "focus" then PlayerFrames.focus:SetPoint("BOTTOMLEFT",PlayerFrames.target,"TOP",0,30); end
	if b == nil or b == "focustarget" then PlayerFrames.focustarget:SetPoint("BOTTOMLEFT", PlayerFrames.focus, "BOTTOMRIGHT", 5, 0); end
end

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