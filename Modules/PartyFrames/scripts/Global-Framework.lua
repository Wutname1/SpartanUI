local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:NewModule("PartyFrames");
----------------------------------------------------------------------------------------------------
local colors = setmetatable({},{__index = SpartanoUF.colors});
for k,v in pairs(SpartanoUF.colors) do if not colors[k] then colors[k] = v end end
colors.health = {0/255,255/255,50/255};
local base_plate1 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_1_full.blp]]
local base_plate2 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_2_dual.blp]]
local base_plate3 = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_3_single.blp]]
local base_ring = [[Interface\AddOns\SpartanUI_PartyFrames\media\base_ring1.blp]]

--	Formatting functions
local TextFormat = function(text)
	local textstyle = DBMod.PartyFrames.bars[text].textstyle
	local textmode = DBMod.PartyFrames.bars[text].textmode
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
	elseif textstyle == "disabled" then
		return "";
	else
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

local PostUpdateText = function(self,unit)
	self:Untag(self.Health.value)
	self:Tag(self.Health.value, TextFormat("health"))
	if self.Power then self:Untag(self.Power.value) end
	if self.Power then self:Tag(self.Power.value, TextFormat("mana")) end
end

local menu = function(self)
	if (not self.id) then self.id = self.unit:match"^.-(%d+)" end
	local unit = string.gsub(self.unit,"(.)",string.upper,1);
	if (_G[unit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[unit..'FrameDropDown'], 'cursor')
	elseif ( (self.unit:match('party')) and (not self.unit:match('partypet')) ) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, 'cursor')
	end
end

function CreatePortrait(self)
	if DBMod.PartyFrames.Portrait3D then
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
		Portrait.type = "3D"
		return Portrait;
	else
		return self.artwork:CreateTexture(nil,"BORDER");
	end
end

local threat = function(self,event,unit)
	local status
	unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
	if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
	if self.Portrait and DBMod.PartyFrames.threat then
		if (not self.Portrait:IsObjectType("Texture")) then return; end
		if (status and status > 0) then
			local r,g,b = GetThreatStatusColor(status);
			self.Portrait:SetVertexColor(r,g,b);
		else
			self.Portrait:SetVertexColor(1,1,1);
		end
	elseif self.ThreatOverlay and DBMod.PartyFrames.threat then
		if ( status and status > 0 ) then
			self.ThreatOverlay:SetVertexColor(GetThreatStatusColor(status));
			self.ThreatOverlay:Show();
		else
			self.ThreatOverlay:Hide();
		end
	end
end

local PostUpdateAura = function(self,unit)
	if DBMod.PartyFrames.showAuras then
		self:Show();
		self.size = DBMod.PartyFrames.Auras.size;
		self.spacing = DBMod.PartyFrames.Auras.spacing;
		self.showType = DBMod.PartyFrames.Auras.showType;
		self.numBuffs = DBMod.PartyFrames.Auras.NumBuffs;
		self.numDebuffs = DBMod.PartyFrames.Auras.NumDebuffs;
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
	-- self:SetStatusBarColor(0,1,0); --B3
end

local OnCastbarUpdate = function(self,elapsed)
	if self.casting then
		self.duration = self.duration + elapsed
		if (self.duration >= self.max) then
			self.casting = nil;
			self:Hide();
			if PostCastStop then PostCastStop(self:GetParent()); end
			return;
		end
		if self.Time then
			if self.delay ~= 0 then self.Time:SetTextColor(1,0,0); else self.Time:SetTextColor(1,1,1); end
			if DBMod.PartyFrames.castbartext == 1 then
				self.Time:SetFormattedText("%.1f",self.max - self.duration);
			else
				self.Time:SetFormattedText("%.1f",self.duration);
			end
		end
		if DBMod.PartyFrames.castbar == 1 then
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
			--self.Time:SetFormattedText("%.1f",self.max-self.duration);
			if DBMod.PartyFrames.castbartext == 0 then
				self.Time:SetFormattedText("%.1f",self.max-self.duration);
			else
				self.Time:SetFormattedText("%.1f",self.duration);
			end
		end
		if DBMod.PartyFrames.castbar == 1 then
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

local ClassFontColor = function(self,event,unit)
	local name = self.Name;
	if (name) then
		local _,class = UnitClass(self.unit);
		local coords = RAID_CLASS_COLORS[class or "DEFAULT"];
		name:SetTextColor(coords[1], coords[2], coords[3], 1);
		--name:Show();
	end
end

local CreatePartyFrame = function(self,unit)
	--self:SetSize(250, 70); -- just make it we will adjust later
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(1);
		self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetAllPoints(self);

		--	Portrait.Size = X Size of the Portrait section of the BG texture
		--  Portrait.XTexSize = This is the texcord size of the Portrait it
		-- 						is set by default for if there is no Portrait
		local Portrait = {Size=0,XTexSize=.3}
		if DBMod.PartyFrames.Portrait then
			Portrait.Size = 75
			Portrait.XTexSize = 0
		end
		
		if DBMod.PartyFrames.FrameStyle == "large" then
			self.artwork.bg:SetTexture(base_plate1);
			self:SetSize(165+Portrait.Size, 70);
			self.artwork.bg:SetTexCoord(Portrait.XTexSize,.95,0.015,.59);
		elseif DBMod.PartyFrames.FrameStyle == "medium" then
			self.artwork.bg:SetTexture(base_plate1);
			self:SetSize(165+Portrait.Size, 50);
			self.artwork.bg:SetTexCoord(Portrait.XTexSize,.95,0.015,.44);
		elseif DBMod.PartyFrames.FrameStyle == "small" then
			self.artwork.bg:SetTexture(base_plate3);
			self:SetSize(165+Portrait.Size, 48);
			self.artwork.bg:SetTexCoord(Portrait.XTexSize,.95,0.015,.77);
		elseif DBMod.PartyFrames.FrameStyle == "xsmall" then
			self.artwork.bg:SetTexture(base_plate2);
			self:SetSize(165+Portrait.Size, 35);
			self.artwork.bg:SetTexCoord(Portrait.XTexSize,.95,0.015,.56);
		elseif DBMod.PartyFrames.FrameStyle == "raidsmall" then
			self.artwork.bg:SetTexture(base_plate2);
			self:SetSize(165+Portrait.Size, 35);
			self.artwork.bg:SetTexCoord(Portrait.XTexSize,.95,0.015,.56);
		end
		
		if DBMod.PartyFrames.Portrait then
		
			-- local Portrait = CreateFrame('PlayerModel', nil, self)
			-- Portrait:SetScript("OnShow", function(self) self:SetCamera(0) end)
			-- Portrait.type = "3D"
			self.Portrait = CreatePortrait(self);
			self.Portrait:SetSize(55, 55);
			self.Portrait:SetPoint("TOPLEFT",self,"TOPLEFT",15,-8);
			
			--self.artwork.ring = self.artwork:CreateTexture(nil,"BORDER");
			--self.artwork.ring:SetPoint("TOPLEFT",self,"TOPLEFT",15,-8);
		end
	end
	do -- setup status bars
		do -- cast bar
			if DBMod.PartyFrames.FrameStyle == "large" then
				local cast = CreateFrame("StatusBar",nil,self);
				cast:SetFrameStrata("BACKGROUND"); cast:SetFrameLevel(2);
				cast:SetSize(110, 16);
				cast:SetPoint("TOPRIGHT",self,"TOPRIGHT",-55,-17);
				
				cast.Text = cast:CreateFontString();
				spartan:FormatFont(cast.Text, 10, "Party")
				cast.Text:SetSize(100, 11);
				cast.Text:SetJustifyH("LEFT"); cast.Text:SetJustifyV("BOTTOM");
				cast.Text:SetPoint("RIGHT",cast,"RIGHT",-2,0);
				
				cast.Time = cast:CreateFontString();
				spartan:FormatFont(cast.Time, 10, "Party")
				cast.Time:SetSize(40, 11);
				cast.Time:SetJustifyH("LEFT"); cast.Time:SetJustifyV("BOTTOM");
				cast.Time:SetPoint("LEFT",cast,"RIGHT",2,0);
				
				self.Castbar = cast;
				self.Castbar.OnUpdate = OnCastbarUpdate;
				self.Castbar.PostCastStart = PostCastStart;
				self.Castbar.PostChannelStart = PostChannelStart;
				self.Castbar.PostCastStop = PostCastStop;
			end
		end
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			if DBMod.PartyFrames.FrameStyle == "large" then
				health:SetPoint("TOPRIGHT",self.Castbar,"BOTTOMRIGHT",0,-2);
				health:SetSize(110, 15);
			elseif DBMod.PartyFrames.FrameStyle == "medium" then
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-55,-19);
				health:SetSize(110, 15);
			elseif DBMod.PartyFrames.FrameStyle == "small" then
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-55,-19);
				health:SetSize(110, 27);
			elseif DBMod.PartyFrames.FrameStyle == "xsmall" then
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-55,-20);
				health:SetSize(110, 13);
			end
			
			health.value = health:CreateFontString();
			spartan:FormatFont(health.value, 10, "Party")
			if DBMod.PartyFrames.FrameStyle == "large" then
				health.value:SetSize(100, 11);
			else
				health.value:SetSize(100, 10);
			end
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("BOTTOM");
			health.value:SetPoint("RIGHT",health,"RIGHT",-2,0);
			self:Tag(health.value, TextFormat("health"))
			
			health.ratio = health:CreateFontString();
			spartan:FormatFont(health.ratio, 10, "Party")
			health.ratio:SetSize(40, 11);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("BOTTOM");
			health.ratio:SetPoint("LEFT",health,"RIGHT",2,0);
			self:Tag(health.ratio, '[perhp]%')
			
			self.Health = health;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			self.Health.colorHealth = true;
			self.Health.colorSmooth = true;
			
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
		if DBMod.PartyFrames.FrameStyle == "large" or DBMod.PartyFrames.FrameStyle == "medium" or DBMod.PartyFrames.display.mana == true then
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			
			if DBMod.PartyFrames.Portrait then power:SetSize(123, 14); else power:SetSize(self.Health:GetWidth(), 14); end
			
			
			if DBMod.PartyFrames.FrameStyle ~= "small" and DBMod.PartyFrames.FrameStyle ~= "xsmall" then
				power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,-2);
				power.value = power:CreateFontString();
				spartan:FormatFont(power.value, 10, "Party")
				if DBMod.PartyFrames.FrameStyle == "large" then
					power.value:SetSize(100, 11);
				else
					power.value:SetSize(100, 10);
				end
				power.value:SetJustifyH("LEFT"); power.value:SetJustifyV("BOTTOM");
				power.value:SetPoint("RIGHT",power,"RIGHT",-2,0);
				self:Tag(power.value, TextFormat("mana"))
				
				power.ratio = power:CreateFontString();
				spartan:FormatFont(power.ratio, 10, "Party")
				power.ratio:SetSize(40, 11);
				power.ratio:SetJustifyH("LEFT"); power.ratio:SetJustifyV("BOTTOM");
				power.ratio:SetPoint("LEFT",power,"RIGHT",2,0);
				self:Tag(power.ratio, '[perpp]%')
			else
				power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,0);
				power:SetHeight(3);
			end
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
		end
	end
	do -- setup text and icons	
		local ring = CreateFrame("Frame",nil,self);
		ring:SetFrameStrata("BACKGROUND");

		self.Name = ring:CreateFontString();
		spartan:FormatFont(self.Name, 11, "Party")
		self.Name:SetSize(140, 10);
		self.Name:SetJustifyH("LEFT"); self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("TOPRIGHT",self,"TOPRIGHT",-10,-6);
		if DBMod.PartyFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.SUI_ClassIcon = ring:CreateTexture(nil,"BORDER");
		self.SUI_ClassIcon:SetSize(20, 20);
		
		self.Leader = ring:CreateTexture(nil,"BORDER");
		self.Leader:SetSize(20, 20);
		
		self.MasterLooter = ring:CreateTexture(nil,"BORDER");
		self.MasterLooter:SetSize(18, 18);
		
		self.LFDRole = ring:CreateTexture(nil,"BORDER");
		self.LFDRole:SetSize(25, 25);
		self.LFDRole:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_role]];
		
		self.RaidIcon = ring:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(20, 20);
		
		if DBMod.PartyFrames.Portrait then
			ring.bg = ring:CreateTexture(nil,"BACKGROUND");
			ring.bg:SetPoint("TOPLEFT",self,"TOPLEFT",-2,4);
			ring.bg:SetTexture(base_ring);
			
			self.Level = ring:CreateFontString();
			spartan:FormatFont(self.Level, 10, "Party")
			self.Level:SetSize(40, 12);
			self.Level:SetJustifyH("CENTER"); self.Level:SetJustifyV("BOTTOM");
			self.Level:SetPoint("CENTER",self.Portrait,"CENTER",-27,27);
			self:Tag(self.Level, "[level]");
			
			self.PvP = ring:CreateTexture(nil,"BORDER");
			self.PvP:SetSize(50, 50);
			self.PvP:SetPoint("CENTER",self.Portrait,"BOTTOMLEFT",5,-10);
			
			self.StatusText = ring:CreateFontString();
			spartan:FormatFont(self.StatusText, 18, "Party")
			self.StatusText:SetPoint("CENTER",self.Portrait,"CENTER");
			self.StatusText:SetJustifyH("CENTER");
			self:Tag(self.StatusText, '[afkdnd]');
			
			ring:SetAllPoints(self.Portrait);
			ring:SetFrameLevel(5);
			self.RaidIcon:SetPoint("CENTER",self.Portrait,"CENTER");
			self.SUI_ClassIcon:SetPoint("CENTER",self.Portrait,"CENTER",23,24);
			self.Leader:SetPoint("CENTER",self.Portrait,"TOP",-1,6);
			self.MasterLooter:SetPoint("CENTER",self.Portrait,"LEFT",-10,0);
			self.LFDRole:SetPoint("CENTER",self.Portrait,"BOTTOM",0,-10);
		else
			ring:SetAllPoints(self); ring:SetFrameLevel(3);
			self.SUI_ClassIcon:SetPoint("CENTER",self,"TOPLEFT",5,-5);
			self.Leader:SetPoint("CENTER",self,"LEFT",0,0);
			self.MasterLooter:SetPoint("CENTER",self,"LEFT",0,-24);
			self.LFDRole:SetPoint("CENTER",self,"TOPRIGHT",-25,0);
			self.RaidIcon:SetPoint("CENTER",self,"TOPRIGHT",-15,-15);
		end
		
	end
	do -- setup buffs and debuffs
		self.Auras = CreateFrame("Frame",nil,self);
		self.Auras:SetSize(self:GetWidth(), 17);
		self.Auras:SetPoint("TOPRIGHT",self,"BOTTOMRIGHT",-3,-5);
		self.Auras:SetFrameStrata("BACKGROUND");
		self.Auras:SetFrameLevel(4);
		-- settings
		self.Auras.size = DBMod.PartyFrames.Auras.size;
		self.Auras.spacing = DBMod.PartyFrames.Auras.spacing;
		self.Auras.showType = DBMod.PartyFrames.Auras.showType;
		self.Auras.initialAnchor = "TOPLEFT";
		self.Auras.gap = true; -- adds an empty spacer between buffs and debuffs
		self.Auras.numBuffs = DBMod.PartyFrames.Auras.NumBuffs;
		self.Auras.numDebuffs = DBMod.PartyFrames.Auras.NumDebuffs;
		
		self.Auras.PostUpdate = PostUpdateAura;
	end
	do -- HoTs Display
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
			icon:SetPoint("TOPRIGHT",self,"TOPRIGHT", (-icon:GetWidth()*i)-2, -2)
			auras.icons[sid] = icon
			-- Set any other AuraWatch icon settings
		end
		self.AuraWatch = auras
	end
	do --Threat, SpellRange, and Ready Check
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		if not DBMod.PartyFrames.Portrait then
			local overlay = self:CreateTexture(nil, "OVERLAY")
			overlay:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights");
			overlay:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
			overlay:SetAllPoints(self)
			overlay:SetVertexColor(1, 0, 0)
			overlay:Hide();
			self.ThreatOverlay = overlay
		end

		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
			
		local ResurrectIcon = self:CreateTexture(nil, 'OVERLAY')
		ResurrectIcon:SetSize(25, 25)
		ResurrectIcon:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ResurrectIcon = ResurrectIcon

		local ReadyCheck = self:CreateTexture(nil, 'OVERLAY')
		ReadyCheck:SetSize(30, 30)
		ReadyCheck:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ReadyCheck = ReadyCheck
	end
	self.TextUpdate = PostUpdateText;
	return self;
end

local CreateSubFrame = function(self,unit)
	self:SetSize(150, 36);
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(0.9); self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetAllPoints(self);
		self.artwork.bg:SetTexture(base_plate2);
		self.artwork.bg:SetTexCoord(.3,1,.01,.55);
		
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(.95);
			health:SetSize(self:GetWidth()/1.70, self:GetHeight()/2.97);
			health:SetPoint("BOTTOMLEFT",self.artwork.bg,"BOTTOMLEFT",11,2);
			
			health.value = health:CreateFontString();
			spartan:FormatFont(health.value, 10, "Party")
			health.value:SetSize(self:GetWidth()/2, health:GetHeight()-2);
			health.value:SetJustifyH("LEFT"); health.value:SetJustifyV("BOTTOM");
			health.value:SetPoint("RIGHT",health,"RIGHT",0,1);
			self:Tag(health.value, '[curhpshort]/[maxhpshort]')
			
			health.ratio = health:CreateFontString();
			spartan:FormatFont(health.ratio, 10, "Party")
			health.ratio:SetSize(self:GetWidth()/1.85, health:GetHeight()-2);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("BOTTOM");
			health.ratio:SetPoint("LEFT",health,"RIGHT",4,0);
			self:Tag(health.ratio, '[perhp]%')
			
			self.Health = health;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			self.Health.colorHealth = true;
			self.Health.colorSmooth = true;
		end
	end
	do -- setup text and icons
		self.Name = self:CreateFontString();
		spartan:FormatFont(self.Name, 11, "Party")
		self.Name:SetSize(135, 12);
		self.Name:SetJustifyH("LEFT"); self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("TOPRIGHT",self.artwork.bg,"TOPRIGHT",0,-4);
		if DBMod.PartyFrames.showClass then
			self:Tag(self.Name, "[level][SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[level][name]");
		end
	end
	return self;
end

local CreateUnitFrame = function(self,unit)
	self.menu = menu;
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyDown");
	self.colors = colors;
	self:SetClampedToScreen(true)
	
	self:EnableMouse(enable)
	self:SetScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			party.mover:Show();
			DBMod.PartyFrames.moved = true;
			party:SetMovable(true);
			party:StartMoving();
		end
	end);
	self:SetScript("OnMouseUp",function(self,button)
		party.mover:Hide();
		party:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = party:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.PartyFrames.Anchors[k] = v
		end
	end);
	
	if (self:GetAttribute("unitsuffix") == "target") and DBMod.PartyFrames.display.target then
		return CreateSubFrame(self,unit);
	elseif (self:GetAttribute("unitsuffix") == "pet") and (DBMod.PartyFrames.FrameStyle == "large" or (not DBMod.PartyFrames.display.target)) and DBMod.PartyFrames.display.pet then
		return CreateSubFrame(self,unit);
	elseif (unit == "party") then
		return CreatePartyFrame(self,unit);
	end
end

SpartanoUF:RegisterStyle("Spartan_PartyFrames", CreateUnitFrame);