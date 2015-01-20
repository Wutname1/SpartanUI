local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------

local base_plate1 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\classic\base_plate1.tga]] -- Player and Target
local base_plate2 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\classic\base_plate2.blp]] -- Focus and Focus Target
local base_plate3 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\classic\base_plate3.tga]] -- Pet, TargetTarget (Large, Medium)
local base_plate4 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\classic\base_plate4.blp]] -- TargetTarget small
local base_ring1 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\base_ring1]] -- Player and Target
local base_ring3 = [[Interface\AddOns\SpartanUI_PlayerFrames\media\base_ring3]] -- Pet and TargetTarget
local circle = [[Interface\AddOns\SpartanUI_PlayerFrames\media\circle.tga]]

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
	-- if ((self.TimeSinceLastUpdate < .5) or ((self.TimeSinceLastUpdate > 1) and (self.TimeSinceLastUpdate < 1.5))) then
		-- SpartanUI_Tribal:SetAlpha((SpartanUI_Tribal:GetAlpha()-.1)); 
	-- else
		-- SpartanUI_Tribal:SetAlpha((SpartanUI_Tribal:GetAlpha()+.1)); 
	-- end
end

local name = function(self)
	if (UnitIsEnemy(self.unit,"player")) then self.Name:SetTextColor(1, 50/255, 0);
	elseif (UnitIsUnit(self.unit,"player")) then self.Name:SetTextColor(1, 1, 1); 
	else
		local r,g,b = unpack(colors.reaction[UnitReaction(self.unit,"player")] or {1,1,1});
		self.Name:SetTextColor(r,g,b);
	end
end

local function CreatePortrait(self)
	if DBMod.PlayerFrames.Portrait3D then			
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
		Portrait.type = "3D"
		if DBMod.PlayerFrames.Portrait3D then
			Portrait.bg2 = Portrait:CreateTexture(nil,"BACKGROUND");
			Portrait.bg2:SetTexture(circle);
			Portrait.bg2:SetPoint("TOPLEFT",Portrait,"TOPLEFT",-10,10);
			Portrait.bg2:SetPoint("BOTTOMRIGHT",Portrait,"BOTTOMRIGHT",10,-10);
		end
		Portrait:SetFrameLevel(1);
		return Portrait;
	else
		return self:CreateTexture(nil,"BORDER");
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
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(0); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER");
		artwork.bg:SetTexture(base_plate1);
		if unit == "target" then artwork.bg:SetTexCoord(1,0,0,1); end
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetSize(55, 55);
		if unit == "player" then self.Portrait:SetPoint("CENTER",self,"CENTER",80,3); end
		if unit == "target" then self.Portrait:SetPoint("CENTER",self,"CENTER",-80,3); end
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
			cast:SetSize(153, 16);
			cast:SetPoint("TOPLEFT",self,"TOPLEFT",36,-23);
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetSize(135, 11);
			cast.Text:SetJustifyH("RIGHT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("LEFT",cast,"LEFT",4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetSize(90, 11);
			cast.Time:SetJustifyH("RIGHT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("RIGHT",cast,"LEFT",-2,0);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			-- health:AnimateTexCoords([[Interface\AddOns\SpartanUI_PlayerFrames\media\HealthBar.blp]], 256, 256, 80, 16, 40, elapsed, 0.08);
			health:SetSize(150, 16);
			health:SetPoint("TOPLEFT",self.Castbar,"BOTTOMLEFT",0,-2);
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetSize(135, 11);
			health.value:SetJustifyH("RIGHT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("LEFT",health,"LEFT",4,0);
			self:Tag(health.value, TextFormat("health"))
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.ratio:SetSize(90, 11);
			health.ratio:SetJustifyH("RIGHT"); health.ratio:SetJustifyV("MIDDLE");
			health.ratio:SetPoint("RIGHT",health,"LEFT",-2,0);
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
			self.Health.Smooth = true
			
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
			power:SetWidth(155); power:SetHeight(14);
			power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-2);
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetWidth(135); power.value:SetHeight(11);
			power.value:SetJustifyH("RIGHT"); power.value:SetJustifyV("MIDDLE");
			power.value:SetPoint("LEFT",power,"LEFT",4,0);
			self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.ratio:SetWidth(90); power.ratio:SetHeight(11);
			power.ratio:SetJustifyH("RIGHT"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetPoint("RIGHT",power,"LEFT",-2,0);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetAllPoints(self.Portrait); ring:SetFrameLevel(3);
		ring.bg = ring:CreateTexture(nil,"BACKGROUND");
		ring.bg:SetPoint("CENTER",ring,"CENTER",-80,-3);
		ring.bg:SetTexture(base_ring1);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(170, 12); self.Name:SetJustifyH("RIGHT");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",5,-6);
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.Level = ring:CreateFontString(nil,"BORDER","SUI_FontOutline10");
		self.Level:SetSize(40, 11);
		self.Level:SetJustifyH("CENTER"); self.Level:SetJustifyV("MIDDLE");
		self.Level:SetPoint("CENTER",ring,"CENTER",53,12);
		self:Tag(self.Level, "[level]");
		
		self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		self.SUI_ClassIcon:SetWidth(22); self.SUI_ClassIcon:SetHeight(22);
		self.SUI_ClassIcon:SetPoint("CENTER",ring,"CENTER",-29,21);
		
		self.Leader = ring:CreateTexture(nil,"BORDER");
		self.Leader:SetWidth(20); self.Leader:SetHeight(20);
		self.Leader:SetPoint("CENTER",ring,"TOP");
		
		self.MasterLooter = ring:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetWidth(18); self.MasterLooter:SetHeight(18);
		self.MasterLooter:SetPoint("CENTER",ring,"TOPRIGHT",-6,-6);
		
		self.SUI_RaidGroup = ring:CreateTexture(nil,"BORDER");
		self.SUI_RaidGroup:SetSize(32, 32);
		self.SUI_RaidGroup:SetPoint("RIGHT",self.MasterLooter,"LEFT",-1,12);
		self.SUI_RaidGroup:SetTexture(circle);
		
		self.SUI_RaidGroup.Text = ring:CreateFontString(nil,"BORDER","SUI_FontOutline11");
		self.SUI_RaidGroup.Text:SetSize(40, 11);
		self.SUI_RaidGroup.Text:SetJustifyH("CENTER"); self.Level:SetJustifyV("MIDDLE");
		self.SUI_RaidGroup.Text:SetPoint("CENTER",self.SUI_RaidGroup,"CENTER",0,0);
		self:Tag(self.SUI_RaidGroup.Text, "[group]");
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetWidth(48); self.PvP:SetHeight(48);
		self.PvP:SetPoint("CENTER",ring,"CENTER",32,-40);
		
		self.LFDRole = ring:CreateTexture(nil,"BORDER");
		self.LFDRole:SetWidth(28); self.LFDRole:SetHeight(28);
		self.LFDRole:SetPoint("CENTER",ring,"CENTER",-20,-35);
		self.LFDRole:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_role]];
		
		self.Resting = ring:CreateTexture(nil,"ARTWORK");
		self.Resting:SetWidth(32); self.Resting:SetHeight(30);
		self.Resting:SetPoint("CENTER",self.SUI_ClassIcon,"CENTER");
		
		self.Combat = ring:CreateTexture(nil,"ARTWORK");
		self.Combat:SetWidth(32); self.Combat:SetHeight(32);
		self.Combat:SetPoint("CENTER",self.Level,"CENTER");
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetWidth(24); self.RaidIcon:SetHeight(24);
		self.RaidIcon:SetPoint("CENTER",ring,"LEFT",-2,-3);
		
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
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(2); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER");
		artwork.bg:SetTexture(base_plate1);
		artwork.bg:SetTexCoord(1,0,0,1);
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetWidth(64); self.Portrait:SetHeight(64);
		self.Portrait:SetPoint("CENTER",self,"CENTER",-80,3);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(153, 16);
			cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",-36,-23);
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetWidth(135); cast.Text:SetHeight(11);
			cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("RIGHT",cast,"RIGHT",-4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetWidth(90); cast.Time:SetHeight(11);
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
			health:SetWidth(150); health:SetHeight(16);
			health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetWidth(135); health.value:SetHeight(11);
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("RIGHT",health,"RIGHT",-4,0);
			self:Tag(health.value, TextFormat("health"))	
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.ratio:SetWidth(90); health.ratio:SetHeight(11);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
			health.ratio:SetPoint("LEFT",health,"RIGHT",2,0);
			self:Tag(health.ratio, '[perhp]%')
			
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
			power:SetWidth(155); power:SetHeight(14);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetWidth(135); power.value:SetHeight(11);
			power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("MIDDLE");
			power.value:SetPoint("RIGHT",power,"RIGHT",-4,0);
			self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.ratio:SetWidth(90); power.ratio:SetHeight(11);
			power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetPoint("LEFT",power,"RIGHT",2,0);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetAllPoints(self.Portrait); ring:SetFrameLevel(4);
		ring.bg = ring:CreateTexture(nil,"BACKGROUND");
		ring.bg:SetPoint("CENTER",ring,"CENTER",80,-3);
		ring.bg:SetTexture(base_ring1);
		ring.bg:SetTexCoord(1,0,0,1);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetWidth(170); self.Name:SetHeight(12); 
		self.Name:SetJustifyH("LEFT"); self.Name:SetJustifyV("MIDDLE");
		self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-5,-6);
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.Level = ring:CreateFontString(nil,"BORDER","SUI_FontOutline10");
		self.Level:SetWidth(40); self.Level:SetHeight(11);
		self.Level:SetJustifyH("CENTER"); self.Level:SetJustifyV("MIDDLE");
		self.Level:SetPoint("CENTER",ring,"CENTER",-49,12);
		self:Tag(self.Level, "[difficulty][level]");
		
		self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		self.SUI_ClassIcon:SetWidth(22); self.SUI_ClassIcon:SetHeight(22);
		self.SUI_ClassIcon:SetPoint("CENTER",ring,"CENTER",29,21);
		
		self.Leader = ring:CreateTexture(nil,"BORDER");
		self.Leader:SetWidth(20); self.Leader:SetHeight(20);
		self.Leader:SetPoint("CENTER",ring,"TOP");
		
		self.MasterLooter = ring:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetWidth(18); self.MasterLooter:SetHeight(18);
		self.MasterLooter:SetPoint("CENTER",ring,"TOPLEFT",6,-6);
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetWidth(48); self.PvP:SetHeight(48);
		self.PvP:SetPoint("CENTER",ring,"CENTER",-16,-40);
		
		self.LevelSkull = ring:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetWidth(16); self.LevelSkull:SetHeight(16);
		self.LevelSkull:SetPoint("CENTER",self.Level,"CENTER");
		
		self.RareElite = ring:CreateTexture(nil,"ARTWORK");
		self.RareElite:SetWidth(150); self.RareElite:SetHeight(150);
		self.RareElite:SetPoint("CENTER",ring,"CENTER",-12,-4);
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetWidth(24); self.RaidIcon:SetHeight(24);
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
	self:SetWidth(210); self:SetHeight(60);
	do -- setup base artwork
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(0); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER"); artwork.bg:SetTexture(base_plate3);
		artwork.bg:SetWidth(256); artwork.bg:SetHeight(85);
		artwork.bg:SetTexCoord(0,1,0,85/128);
		
		self.Portrait = CreatePortrait(self);
		self.Portrait:SetWidth(56); self.Portrait:SetHeight(50);
		self.Portrait:SetPoint("CENTER",self,"CENTER",87,-8);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
			cast:SetWidth(120); cast:SetHeight(15);
			cast:SetPoint("TOPLEFT",self,"TOPLEFT",36,-23);
			
			cast.Text = cast:CreateFontString();
			spartan:FormatFont(cast.Text, 10, "Player")
			cast.Text:SetWidth(110); cast.Text:SetHeight(11);
			cast.Text:SetJustifyH("RIGHT"); cast.Text:SetJustifyV("MIDDLE");
			cast.Text:SetPoint("LEFT",cast,"LEFT",4,0);
			
			cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			cast.Time:SetWidth(40); cast.Time:SetHeight(11);
			cast.Time:SetJustifyH("RIGHT"); cast.Time:SetJustifyV("MIDDLE");
			cast.Time:SetPoint("RIGHT",cast,"LEFT",-2,0);
			
			self.Castbar = cast;
			self.Castbar.OnUpdate = OnCastbarUpdate;
			self.Castbar.PostCastStart = PostCastStart;
			self.Castbar.PostChannelStart = PostChannelStart;
			self.Castbar.PostCastStop = PostCastStop;
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetWidth(120); health:SetHeight(16);
			health:SetPoint("TOPLEFT",self.Castbar,"BOTTOMLEFT",0,-2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetWidth(110); health.value:SetHeight(11);
			health.value:SetJustifyH("RIGHT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("LEFT",health,"LEFT",4,0);
			self:Tag(health.value, TextFormat("health"))
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.ratio:SetWidth(40); health.ratio:SetHeight(11);
			health.ratio:SetJustifyH("RIGHT"); health.ratio:SetJustifyV("MIDDLE");
			health.ratio:SetPoint("RIGHT",health,"LEFT",-2,0);
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
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			power:SetWidth(135); power:SetHeight(14);
			power:SetPoint("TOPLEFT",self.Health,"BOTTOMLEFT",0,-1);
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetWidth(110); power.value:SetHeight(11);
			power.value:SetJustifyH("RIGHT"); power.value:SetJustifyV("MIDDLE");
			power.value:SetPoint("LEFT",power,"LEFT",4,0);
			self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.ratio:SetWidth(40); power.ratio:SetHeight(11);
			power.ratio:SetJustifyH("RIGHT"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetPoint("RIGHT",power,"LEFT",-2,0);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");
		ring:SetAllPoints(self.Portrait); ring:SetFrameLevel(3);
		ring.bg = ring:CreateTexture(nil,"BACKGROUND");
		ring.bg:SetPoint("CENTER",ring,"CENTER",-2,-3);
		ring.bg:SetTexture(base_ring3);
		ring.bg:SetTexCoord(1,0,0,1);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetHeight(12); self.Name:SetWidth(150); self.Name:SetJustifyH("RIGHT");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",3,-5);
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.Level = ring:CreateFontString(nil,"BORDER","SUI_FontOutline10");
		self.Level:SetWidth(36); self.Level:SetHeight(11);
		self.Level:SetJustifyH("CENTER"); self.Level:SetJustifyV("MIDDLE");
		self.Level:SetPoint("CENTER",ring,"CENTER",24,25);
		self:Tag(self.Level, "[level]");
		
		self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		self.SUI_ClassIcon:SetWidth(22); self.SUI_ClassIcon:SetHeight(22);
		self.SUI_ClassIcon:SetPoint("CENTER",ring,"CENTER",-27,24);
		
		self.PvP = ring:CreateTexture(nil,"BORDER");
		self.PvP:SetWidth(48); self.PvP:SetHeight(48);
		self.PvP:SetPoint("CENTER",ring,"CENTER",30,-36);
		
		self.Happiness = ring:CreateTexture(nil,"ARTWORK");
		self.Happiness:SetWidth(22); self.Happiness:SetHeight(22);
		self.Happiness:SetPoint("CENTER",ring,"CENTER",-27,24);
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetAllPoints(self.Portrait);
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetWidth(20); self.RaidIcon:SetHeight(20);
		self.RaidIcon:SetPoint("CENTER",ring,"LEFT",-5,0);
	end
	do -- setup buffs and debuffs
		self.Auras = CreateFrame("Frame",nil,self);
		self.Auras:SetWidth(17*11); self.Auras:SetHeight(16*1);
		self.Auras:SetPoint("BOTTOMLEFT",self,"TOPLEFT",10,0);
		self.Auras:SetFrameStrata("BACKGROUND");
		self.Auras:SetFrameLevel(4);
		-- settings
		self.Auras.initialAnchor = "BOTTOMLEFT";
		self.Auras["growth-x"] = "RIGHT";
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

local CreateToTFrame = function(self,unit)
	if DBMod.PlayerFrames.targettarget.style == "large" then
	do -- large
		self:SetWidth(210); self:SetHeight(60);
		do -- setup base artwork
			local artwork = CreateFrame("Frame",nil,self);
			artwork:SetFrameStrata("BACKGROUND");
			artwork:SetFrameLevel(0); artwork:SetAllPoints(self);
			
			artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
			artwork.bg:SetPoint("CENTER"); artwork.bg:SetTexture(base_plate3);
			artwork.bg:SetSize(256, 85);
			artwork.bg:SetTexCoord(1,0,0,85/128);
			
			self.Portrait = CreatePortrait(self);
			self.Portrait:SetWidth(56); self.Portrait:SetHeight(50);
			self.Portrait:SetPoint("CENTER",self,"CENTER",-83,-8);
			
			self.Threat = CreateFrame("Frame",nil,self);
			self.Threat.Override = threat;
		end
		do -- setup status bars
			do -- cast bar
				local cast = CreateFrame("StatusBar",nil,self);
				cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
				cast:SetWidth(120); cast:SetHeight(15);
				cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",-36,-23);
				
				cast.Text = cast:CreateFontString();
				spartan:FormatFont(cast.Text, 10, "Player")
				cast.Text:SetWidth(110); cast.Text:SetHeight(11);
				cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("MIDDLE");
				cast.Text:SetPoint("RIGHT",cast,"RIGHT",-4,0);
				
				cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				cast.Time:SetWidth(40); cast.Time:SetHeight(11);
				cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
				cast.Time:SetPoint("LEFT",cast,"RIGHT",4,0);
				
				self.Castbar = cast;
				self.Castbar.OnUpdate = OnCastbarUpdate;
				self.Castbar.PostCastStart = PostCastStart;
				self.Castbar.PostChannelStart = PostChannelStart;
				self.Castbar.PostCastStop = PostCastStop;
			end
			do -- health bar
				local health = CreateFrame("StatusBar",nil,self);
				health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
				health:SetWidth(120); health:SetHeight(16);
				health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
				health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				
				health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.value:SetWidth(110); health.value:SetHeight(11);
				health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
				health.value:SetPoint("RIGHT",health,"RIGHT",-4,0);
				
				self:Tag(health.value, TextFormat("health"))
				
				health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.ratio:SetWidth(40); health.ratio:SetHeight(11);
				health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
				health.ratio:SetPoint("LEFT",health,"RIGHT",4,0);
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
				power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
				power:SetWidth(135); power:SetHeight(14);
				power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-1);
				
				power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				power.value:SetWidth(110); power.value:SetHeight(11);
				power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("MIDDLE");
				power.value:SetPoint("RIGHT",power,"RIGHT",-4,0);
				self:Tag(power.value, TextFormat("mana"))
				
				power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				power.ratio:SetWidth(40); power.ratio:SetHeight(11);
				power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("MIDDLE");
				power.ratio:SetPoint("LEFT",power,"RIGHT",4,0);
				self:Tag(power.ratio, '[perpp]%')		
				
				self.Power = power;
				self.Power.colorPower = true;
				self.Power.frequentUpdates = true;
			end
		end
		do -- setup ring, icons, and text
			local ring = CreateFrame("Frame",nil,self);
			ring:SetFrameStrata("BACKGROUND");
			ring:SetAllPoints(self.Portrait); ring:SetFrameLevel(3);
			ring.bg = ring:CreateTexture(nil,"BACKGROUND");
			ring.bg:SetPoint("CENTER",ring,"CENTER",-2,-3);
			ring.bg:SetTexture(base_ring3);
			
			self.Name = ring:CreateFontString();
			spartan:FormatFont(self.Name, 12, "Player")
			self.Name:SetHeight(12); self.Name:SetWidth(150); self.Name:SetJustifyH("LEFT");
			self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-3,-5);
			if DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, "[SUI_ColorClass][name]");
			else
				self:Tag(self.Name, "[name]");
			end
			
			self.Level = ring:CreateFontString(nil,"BORDER","SUI_FontOutline10");
			self.Level:SetWidth(36); self.Level:SetHeight(11);
			self.Level:SetJustifyH("CENTER"); self.Level:SetJustifyV("MIDDLE");
			self.Level:SetPoint("CENTER",ring,"CENTER",-27,25);
			self:Tag(self.Level, "[difficulty][level]");
			
			self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
			self.SUI_ClassIcon:SetWidth(22); self.SUI_ClassIcon:SetHeight(22);
			self.SUI_ClassIcon:SetPoint("CENTER",ring,"CENTER",23,24);
			
			self.PvP = ring:CreateTexture(nil,"BORDER");
			self.PvP:SetWidth(48); self.PvP:SetHeight(48);
			self.PvP:SetPoint("CENTER",ring,"CENTER",-14,-36);
			
			self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
			self.RaidIcon:SetWidth(20); self.RaidIcon:SetHeight(20);
			self.RaidIcon:SetPoint("CENTER",ring,"RIGHT",1,-1);
			
			self.StatusText = ring:CreateFontString(nil, "OVERLAY", "SUI_FontOutline18");
			self.StatusText:SetPoint("CENTER",ring,"CENTER");
			self.StatusText:SetJustifyH("CENTER");
			self:Tag(self.StatusText, "[afkdnd]");

		end
		self.TextUpdate = PostUpdateText;
		self.ColorUpdate = PostUpdateColor;
	end
	elseif DBMod.PlayerFrames.targettarget.style == "medium" then
	do -- medium
		self:SetWidth(124); self:SetHeight(55);
		do -- setup base artwork
			self.artwork = CreateFrame("Frame",nil,self);
			self.artwork:SetFrameStrata("BACKGROUND");
			self.artwork:SetFrameLevel(0); self.artwork:SetAllPoints(self);
			
			self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
			self.artwork.bg:SetPoint("CENTER"); self.artwork.bg:SetTexture(base_plate3);
			self.artwork.bg:SetSize(170, 80);
			self.artwork.bg:SetTexCoord(.68,0,0,0.6640625);
			
			self.Threat = CreateFrame("Frame",nil,self);
			self.Threat.Override = threat;
		end
		do -- setup status bars
			do -- cast bar
				local cast = CreateFrame("StatusBar",nil,self);
				cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
				cast:SetSize(95, 14);
				cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",-36,-20);
				
				cast.Text = cast:CreateFontString();
				spartan:FormatFont(cast.Text, 10, "Player")
				cast.Text:SetSize(90, 11);
				cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("MIDDLE");
				cast.Text:SetPoint("RIGHT",cast,"RIGHT",-4,0);
				
				cast.Time = cast:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				cast.Time:SetSize(40, 11);
				cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("MIDDLE");
				cast.Time:SetPoint("LEFT",cast,"RIGHT",4,0);
				
				self.Castbar = cast;
				self.Castbar.OnUpdate = OnCastbarUpdate;
				self.Castbar.PostCastStart = PostCastStart;
				self.Castbar.PostChannelStart = PostChannelStart;
				self.Castbar.PostCastStop = PostCastStop;
			end
			do -- health bar
				local health = CreateFrame("StatusBar",nil,self);
				health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
				health:SetSize(93, 14);
				health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
				health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				
				health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.value:SetSize(85, 11);
				health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
				health.value:SetPoint("RIGHT",health,"RIGHT",-4,0);
				
				self:Tag(health.value, TextFormat("health"))
				
				health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.ratio:SetWidth(40); health.ratio:SetHeight(11);
				health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
				health.ratio:SetPoint("LEFT",health,"RIGHT",5,0);
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
				power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
				power:SetSize(90, 14);
				power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-1);
				
				power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				power.value:SetSize(85, 11);
				power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("MIDDLE");
				power.value:SetPoint("RIGHT",power,"RIGHT",-4,0);
				self:Tag(power.value, TextFormat("mana"))
				
				power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				power.ratio:SetSize(40, 11);
				power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("MIDDLE");
				power.ratio:SetPoint("LEFT",power,"RIGHT",5,0);
				self:Tag(power.ratio, '[perpp]%')		
				
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
			self.Name:SetHeight(12); self.Name:SetWidth(132); self.Name:SetJustifyH("LEFT");
			self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,-5);
			if DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
			else
				self:Tag(self.Name, "[difficulty][level] [name]");
			end
			
			self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
			self.RaidIcon:SetWidth(20); self.RaidIcon:SetHeight(20);
			self.RaidIcon:SetPoint("LEFT",self,"RIGHT",3,0);
			
			self.PvP = ring:CreateTexture(nil,"BORDER");
			self.PvP:SetWidth(40); self.PvP:SetHeight(40);
			self.PvP:SetPoint("LEFT",self,"RIGHT",-5,24);
		end
		self.TextUpdate = PostUpdateText;
		self.ColorUpdate = PostUpdateColor;
	end
	elseif DBMod.PlayerFrames.targettarget.style == "small" then
	do -- small
		self:SetSize(200, 65);
		do -- setup base artwork
			self.artwork = CreateFrame("Frame",nil,self);
			self.artwork:SetFrameStrata("BACKGROUND");
			self.artwork:SetFrameLevel(0); self.artwork:SetAllPoints(self);
			
			self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
			self.artwork.bg:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT"); self.artwork.bg:SetTexture(base_plate4);
			self.artwork.bg:SetSize(200, 65);
			self.artwork.bg:SetTexCoord(.24,1,0,1);
			
			self.Threat = CreateFrame("Frame",nil,self);
			self.Threat.Override = threat;
		end
		do -- setup status bars
			do -- health bar
				local health = CreateFrame("StatusBar",nil,self);
				health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(1);
				health:SetSize(125, 25);
				health:SetPoint("BOTTOMLEFT",self.artwork,"BOTTOMLEFT",5,17);
				health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
				
				health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.value:SetSize(100, 11);
				health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
				health.value:SetPoint("RIGHT",health,"RIGHT",-4,0);
				
				self:Tag(health.value, TextFormat("health"))
				
				health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
				health.ratio:SetWidth(50); health.ratio:SetHeight(11);
				health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
				health.ratio:SetPoint("LEFT",health,"RIGHT",5,0);
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
		end
		do -- setup ring, icons, and text
			local ring = CreateFrame("Frame",nil,self);
			ring:SetFrameStrata("BACKGROUND");
			ring:SetPoint("TOPLEFT",self.artwork,"TOPLEFT",0,0); ring:SetFrameLevel(3);
			
			self.Name = ring:CreateFontString();
			spartan:FormatFont(self.Name, 12, "Player")
			self.Name:SetSize(132, 12); self.Name:SetJustifyH("LEFT");
			self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-50,-5);
			if DBMod.PlayerFrames.showClass then
				self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
			else
				self:Tag(self.Name, "[difficulty][level] [name]");
			end
			
			self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
			self.RaidIcon:SetSize(15, 15);
			self.RaidIcon:SetPoint("RIGHT",self,"RIGHT",-5,0);
			
			self.PvP = ring:CreateTexture(nil,"BORDER");
			self.PvP:SetSize(30, 30);
			self.PvP:SetPoint("RIGHT",self,"RIGHT",0,20);
		end
		self.TextUpdate = PostUpdateText;
		self.ColorUpdate = PostUpdateColor;
	end
	end
	do -- setup buffs and debuffs
		self.Auras = CreateFrame("Frame",nil,self);
		self.Auras:SetSize(self:GetWidth()/1.3, 16);
		self.Auras:SetPoint("BOTTOM",self,"TOP",-10,0);
		self.Auras:SetFrameStrata("BACKGROUND");
		self.Auras:SetFrameLevel(4);
		-- settings
		self.Auras.initialAnchor = "BOTTOMRIGHT";
		self.Auras["growth-x"] = "LEFT";
		self.Auras["growth-y"] = "UP";
		self.Auras.gap = false;
		self.Auras.size = DBMod.PlayerFrames[unit].Auras.size;
		self.Auras.spacing = DBMod.PlayerFrames[unit].Auras.spacing;
		self.Auras.showType = DBMod.PlayerFrames[unit].Auras.showType;
		self.Auras.numBuffs = DBMod.PlayerFrames[unit].Auras.NumBuffs;
		self.Auras.numDebuffs = DBMod.PlayerFrames[unit].Auras.NumDebuffs;
		self.Auras.onlyShowPlayer = DBMod.PlayerFrames[unit].Auras.onlyShowPlayer;
		
		self.Auras.PostUpdate = PostUpdateAura;
	end
	return self;
end

local CreateFocusFrame = function(self,unit)
	self:SetWidth(180); self:SetHeight(60);
	do --setup base artwork
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(0); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER"); artwork.bg:SetTexture(base_plate2);
		artwork.bg:SetWidth(180); artwork.bg:SetHeight(60);
		if unit == "focus" then artwork.bg:SetTexCoord(0, 1, 0, 0.4) end
		if unit == "focustarget" then artwork.bg:SetTexCoord(0, 1, .5, .9) end
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetSize(85, 15);
			if unit == "focus" then health:SetPoint("CENTER",self,"CENTER",-5,-2) end
			if unit == "focustarget" then health:SetPoint("CENTER",self,"CENTER",-46,-2) end
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetSize(80, 11);
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
			if unit == "focus" then health.value:SetPoint("RIGHT",health,"RIGHT",0,0) end
			if unit == "focustarget" then health.value:SetPoint("LEFT",health,"LEFT",0,0) end
			self:Tag(health.value, TextFormat("health"))
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.ratio:SetSize(40, 11);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
			if unit == "focus" then health.ratio:SetPoint("LEFT",health,"LEFT",-30,0) end
			if unit == "focustarget" then health.ratio:SetPoint("LEFT",health,"RIGHT",1,0) end
			self:Tag(health.ratio, '[perhp]%')
			
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
				-- self.Health.colorClass = true;
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
				maxOverflow = 4,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			power:SetSize(85, 15);
			power:SetPoint("TOP",self.Health,"BOTTOM",0,-2);
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetSize(85, 11);
			power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("MIDDLE");
			power.value:SetPoint("TOP",self.Health.value,"BOTTOM",-1,-6);
			self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetSize(40, 11);
			power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetPoint("TOP",self.Health.ratio,"BOTTOM",-4,-7);	
			self:Tag(power.ratio, '[perpp]%')		
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		--ring:SetFrameStrata("BACKGROUND");
		--ring:SetAllPoints(self); ring:SetFrameLevel(3);
		ring.bg = ring:CreateTexture(nil,"BACKGROUND");
		ring.bg:SetPoint("LEFT",ring,"LEFT",-2,-3);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 12, "Player")
		self.Name:SetSize(110, 12); self.Name:SetJustifyH("LEFT");
		if unit == "focus" then
			self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",20,-6);
		elseif unit == "focustarget" then
			self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",2,-6);
		end
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[difficulty][level] [SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[difficulty][level] [name]");
		end
		
		self.LevelSkull = ring:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("CENTER",self.Name,"LEFT",8,0);
	end
	do -- setup buffs and debuffs
		self.Auras = CreateFrame("Frame",nil,self);
		self.Auras:SetSize(160, 16);
		self.Auras:SetPoint("BOTTOMLEFT",self,"TOPLEFT",10,0);
		self.Auras:SetFrameStrata("BACKGROUND");
		self.Auras:SetFrameLevel(4);
		-- settings
		self.Auras.initialAnchor = "BOTTOMLEFT";
		self.Auras["growth-x"] = "RIGHT";
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
	
	--Make Focus Movable
	self:EnableMouse(enable)
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			DBMod.PlayerFrames.focus.movement.moved = true;
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		self:StopMovingOrSizing();
		DBMod.PlayerFrames.focus.movement.point,
		DBMod.PlayerFrames.focus.movement.relativeTo,
		DBMod.PlayerFrames.focus.movement.relativePoint,
		DBMod.PlayerFrames.focus.movement.xOffset,
		DBMod.PlayerFrames.focus.movement.yOffset = self:GetPoint(self:GetNumPoints())
	end);
	return self;
end

local CreateBossFrame = function(self,unit)
	self:SetSize(145, 80);
	do --setup base artwork
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(2); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER");
		artwork.bg:SetTexture(base_plate1);
		artwork.bg:SetTexCoord(.57,.2,.2,1);
		artwork.bg:SetAllPoints(self);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
		
		local Bossartwork = CreateFrame("Frame",nil,self);
		Bossartwork:SetFrameStrata("BACKGROUND");
		Bossartwork:SetFrameLevel(1); Bossartwork:SetAllPoints(self);
		
		self.BossGraphic = Bossartwork:CreateTexture(nil,"ARTWORK");
		self.BossGraphic:SetSize(130, 125);
		self.BossGraphic:SetPoint("TOP",self,"TOPRIGHT",-25,36);
		
	end
	do -- setup status bars
		do -- cast bar
			local cast = CreateFrame("StatusBar",nil,self);
			cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(3);
			cast:SetSize(105, 12);
			cast:SetPoint("TOPLEFT",self,"TOPLEFT",0,-17);
			
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
			health:SetSize(105, 12);
			health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			health.value = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.value:SetSize(97, 10);
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("MIDDLE");
			health.value:SetPoint("LEFT",health,"LEFT",4,0);
			self:Tag(health.value, TextFormat("health"))	
			
			health.ratio = health:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			health.ratio:SetSize(50, 10);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("MIDDLE");
			health.ratio:SetPoint("LEFT",health,"RIGHT",2,0);
			self:Tag(health.ratio, '[perhp]%')
			
			-- local Background = health:CreateTexture(nil, 'BACKGROUND')
			-- Background:SetAllPoints(health)
			-- Background:SetTexture(1, 1, 1, .08)
			
			self.Health = health;
			--self.Health.bg = Background;
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
			power:SetWidth(105); power:SetHeight(12);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
			
			power.value = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.value:SetSize(70, 10);
			power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("MIDDLE");
			power.value:SetPoint("RIGHT",power,"RIGHT",-4,0);
			self:Tag(power.value, TextFormat("mana"))
			
			power.ratio = power:CreateFontString(nil, "OVERLAY", "SUI_FontOutline10");
			power.ratio:SetSize(50, 10);
			power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("MIDDLE");
			power.ratio:SetPoint("LEFT",power,"RIGHT",2,0);
			self:Tag(power.ratio, '[perpp]%')
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
			
		end
	end
	do -- setup ring, icons, and text
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameLevel(4); ring:SetFrameStrata("BACKGROUND");
		ring:SetSize(50, 50);
		ring:SetPoint("CENTER",self,"CENTER",-80,3);
		
		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 10, "Player")
		self.Name:SetSize(127, 10); 
		self.Name:SetJustifyH("LEFT"); self.Name:SetJustifyV("MIDDLE");
		self.Name:SetPoint("TOPLEFT",self,"TOPLEFT",8,-2);
		if DBMod.PlayerFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.LevelSkull = ring:CreateTexture(nil,"ARTWORK");
		self.LevelSkull:SetSize(16, 16);
		self.LevelSkull:SetPoint("RIGHT",self.Name ,"LEFT",2,0);
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(24, 24);
		self.RaidIcon:SetPoint("CENTER",self,"BOTTOMLEFT",0,23);
	end
	self.TextUpdate = PostUpdateText;
	self.ColorUpdate = PostUpdateColor;
	
	--Make Boss Frames Movable
	self:EnableMouse(enable)
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			-- addon.boss.mover:Show();
			-- DBMod.PlayerFrames.BossFrame.movement.moved = true;
			-- addon.boss.mover:SetMovable(true);
			-- addon.boss.mover:StartMoving();
			
			addon.boss.mover:Show();
			DBMod.PlayerFrames.BossFrame.movement.moved = true;
			SUI_Boss1:SetMovable(true);
			SUI_Boss1:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		addon.boss.mover:Hide();
		SUI_Boss1:StopMovingOrSizing();
		DBMod.PlayerFrames.BossFrame.movement.point,
		DBMod.PlayerFrames.BossFrame.movement.relativeTo,
		DBMod.PlayerFrames.BossFrame.movement.relativePoint,
		DBMod.PlayerFrames.BossFrame.movement.xOffset,
		DBMod.PlayerFrames.BossFrame.movement.yOffset = SUI_Boss1:GetPoint(SUI_Boss1:GetNumPoints())
		addon:UpdateBossFramePosition();
	end);
	
	return self;
end

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
	self.colors = addon.colors;
	
	return ((unit == "target" and CreateTargetFrame(self,unit))
	or (unit == "targettarget" and CreateToTFrame(self,unit))
	or (unit == "player" and CreatePlayerFrame(self,unit))
	or (unit == "focus" and CreateFocusFrame(self,unit))
	or (unit == "focustarget" and CreateFocusFrame(self,unit))
	or (unit == "pet" and CreatePetFrame(self,unit))
	or CreateBossFrame(self,unit));
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
		addon:WarlockPowerFrame_Relocate();
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

function addon:ResetAltBarPositions()
	DBMod.PlayerFrames.AltManaBar.movement.moved = false;
	DBMod.PlayerFrames.ClassBar.movement.moved = false; 
	addon:UpdateAltBarPositions();
end

function addon:WarlockPowerFrame_Relocate() -- Sets the location of the warlock bars based on spec
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

function addon:SetupExtras()

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
	TotemFrame:SetPoint("TOPLEFT",addon.player,"BOTTOMLEFT",70,8);
	
	-- relocate the PlayerPowerBarAlt
	hooksecurefunc(PlayerPowerBarAlt,"SetPoint",function(_,_,parent)
		if (parent ~= addon.player) then
			PlayerPowerBarAlt:ClearAllPoints();
			PlayerPowerBarAlt:SetPoint("BOTTOMLEFT",addon.player,"TOPLEFT",10,40);
		end
	end);
	PlayerPowerBarAlt:SetParent(addon.player);
	PlayerPowerBarAlt:SetFrameStrata("MEDIUM");
	PlayerPowerBarAlt:SetFrameLevel(4);
	PlayerPowerBarAlt:SetScale(1);
	PlayerPowerBarAlt:ClearAllPoints();
	PlayerPowerBarAlt:SetPoint("BOTTOMLEFT",addon.player,"TOPLEFT",10,40);

	addon:UpdateAltBarPositions();
	
	--Watch for Spec Changes
	local SpecWatcher = CreateFrame("Frame");
	SpecWatcher:RegisterEvent("PLAYER_TALENT_UPDATE");
	SpecWatcher:SetScript("OnEvent",function()
		addon:UpdateAltBarPositions();
	end);
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
end

function addon:UpdateFocusPosition()
	addon.focus:ClearAllPoints();
	if DBMod.PlayerFrames.focus.movement.moved then
		addon.focus:SetPoint(DBMod.PlayerFrames.focus.movement.point,
		DBMod.PlayerFrames.focus.movement.relativeTo,
		DBMod.PlayerFrames.focus.movement.relativePoint,
		DBMod.PlayerFrames.focus.movement.xOffset,
		DBMod.PlayerFrames.focus.movement.yOffset);
	else
		addon.focus:SetPoint("BOTTOMLEFT",SUI_FramesAnchor,"TOP",170,110);
	end
end

SpartanoUF:RegisterStyle("SUI_PlayerFrames_Classic", CreateUnitFrame);