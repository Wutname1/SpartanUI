local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:GetModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
local base_plate =	[[Interface\AddOns\SpartanUI_PlayerFrames\media\base_square.tga]] -- Player and Target
local circle =		[[Interface\AddOns\SpartanUI_PlayerFrames\media\circle.tga]]

local Smoothv2 =	[[Interface\AddOns\SpartanUI_PlayerFrames\media\Smoothv2.tga]]
local texture =		[[Interface\AddOns\SpartanUI_PlayerFrames\media\texture.tga]]
local metal =		[[Interface\AddOns\SpartanUI_PlayerFrames\media\metal.tga]]

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

local CreateFrame = function(self,unit)
	base_plate = Smoothv2
	self:SetSize(280, 80);
	do -- setup base artwork
		local artwork = CreateFrame("Frame",nil,self);
		artwork:SetFrameStrata("BACKGROUND");
		artwork:SetFrameLevel(0); artwork:SetAllPoints(self);
		
		artwork.bg = artwork:CreateTexture(nil,"BACKGROUND");
		artwork.bg:SetPoint("CENTER");
		artwork.bg:SetTexture(base_plate);
		--artwork.bg:SetAllPoints();
		artwork.bg:SetPoint("TOPLEFT", artwork, "TOPLEFT", 0, 0);
		artwork.bg:SetPoint("TOPRIGHT", artwork, "TOPRIGHT", 0, 0);
		artwork.bg:SetPoint("BOTTOM", artwork, "BOTTOM", 0, 0);
		if unit == "target" then artwork.bg:SetTexCoord(1,0,0,1); end
		
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
		--ring.bg:SetTexture(base_plate);
		
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
	
	return (CreateFrame(self,unit));
end

SpartanoUF:RegisterStyle("SUI_PlayerFrames_Plain", CreateUnitFrame);