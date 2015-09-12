local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local RaidFrames = spartan:GetModule("RaidFrames");
----------------------------------------------------------------------------------------------------
local colors = setmetatable({},{__index = SpartanoUF.colors});
for k,v in pairs(SpartanoUF.colors) do if not colors[k] then colors[k] = v end end
colors.health = {0/255,255/255,50/255};
local base_plate2 = [[Interface\AddOns\SpartanUI_RaidFrames\media\base_2_dual.blp]]
local base_plate3 = [[Interface\AddOns\SpartanUI_RaidFrames\media\base_3_single.blp]]
local base_ring = [[Interface\AddOns\SpartanUI_RaidFrames\media\base_ring1.blp]]

local threat = function(self,event,unit)
	local status
	unit = string.gsub(self.unit,"(.)",string.upper,1) or string.gsub(unit,"(.)",string.upper,1)
	if UnitExists(unit) then status = UnitThreatSituation(unit) else status = 0; end
	if self.Portrait and DBMod.RaidFrames.threat then
		if (not self.Portrait:IsObjectType("Texture")) then return; end
		if (status and status > 0) then
			local r,g,b = GetThreatStatusColor(status);
			self.Portrait:SetVertexColor(r,g,b);
		else
			self.Portrait:SetVertexColor(1,1,1);
		end
	elseif self.ThreatOverlay and DBMod.RaidFrames.threat then
		if ( status and status > 0 ) then
			self.ThreatOverlay:SetVertexColor(GetThreatStatusColor(status));
			self.ThreatOverlay:Show();
		else
			self.ThreatOverlay:Hide();
		end
	end
end

local SpawnUnitFrame = function(self,unit)
	self.menu = menu;
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	
	self:SetSize(140, 35) -- Setup initial Size
	do -- setup base artwork
		self.artwork = CreateFrame("Frame",nil,self);
		self.artwork:SetFrameStrata("BACKGROUND");
		self.artwork:SetFrameLevel(1); self.artwork:SetAllPoints(self);
		
		self.artwork.bg = self.artwork:CreateTexture(nil,"BACKGROUND");
		self.artwork.bg:SetAllPoints(self);
		self.artwork.bg:SetTexture(base_plate3);
		if DBMod.RaidFrames.FrameStyle == "large" then
			self:SetSize(165, 48);
			self.artwork.bg:SetTexCoord(.3,.95,0.015,.77);
		elseif DBMod.RaidFrames.FrameStyle == "medium" then
			self:SetSize(140, 35);
			self.artwork.bg:SetTexCoord(.3,.95,0.015,.56);
		elseif DBMod.RaidFrames.FrameStyle == "small" then
			self:SetSize(90, 30);
			self.artwork.bg:SetTexCoord(.3,.70,0.3,.7);
		end
	end
	do -- setup status bars
		do -- health bar
			local health = CreateFrame("StatusBar",nil,self);
			health:SetFrameStrata("BACKGROUND"); health:SetFrameLevel(2);
			health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			
			
			if DBMod.RaidFrames.FrameStyle == "large" then
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-55,-19);
				health:SetSize(110, 27);
			elseif DBMod.RaidFrames.FrameStyle == "medium" then
				health:SetSize(self:GetWidth()/1.5, 13);
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",-self:GetWidth()/3,-20);
			elseif DBMod.RaidFrames.FrameStyle == "small" then
				health:SetSize(self:GetWidth(), self:GetHeight());
				health:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,0);
			end
			
			health.value = health:CreateFontString();
			spartan:FormatFont(health.value, 10, "Raid")
			health.value:SetJustifyH("CENTER"); health.value:SetJustifyV("BOTTOM");
			self:Tag(health.value, RaidFrames:TextFormat("health"))
			
			health.ratio = health:CreateFontString();
			spartan:FormatFont(health.ratio, 10, "Raid")
			health.ratio:SetSize(35, 11);
			health.ratio:SetJustifyH("LEFT"); health.ratio:SetJustifyV("BOTTOM");
			self:Tag(health.ratio, '[perhp]%')
			
			if DBMod.RaidFrames.FrameStyle == "large" then
				health.ratio:SetPoint("LEFT",health,"RIGHT",6,0);
				health.value:SetPoint("RIGHT",health,"RIGHT",-2,0);
				health.value:SetSize(health:GetWidth()/1.1, 11);
			elseif DBMod.RaidFrames.FrameStyle == "medium" then
				health.ratio:SetPoint("LEFT",health,"RIGHT",6,0);
				health.value:SetPoint("RIGHT",health,"RIGHT",-2,0);
				health.value:SetSize(health:GetWidth()/1.5, 11);
			elseif DBMod.RaidFrames.FrameStyle == "small" then
				health.ratio:SetPoint("BOTTOMRIGHT",health,"BOTTOMRIGHT",0,2);
				health.value:SetPoint("RIGHT",health,"RIGHT",-2,0);
				health.value:SetSize(health:GetWidth()/1.5, 11);
				health.value:Hide();
			end

			local Background = health:CreateTexture(nil, 'BACKGROUND')
			Background:SetAllPoints(health)
			Background:SetTexture(1, 1, 1, .08)
			
			self.Health = health;
			self.Health.bg = Background;
			self.Health.frequentUpdates = true;
			self.Health.colorDisconnected = true;
			self.Health.colorClass = true;
			self.Health.colorHealth = true;
			self.Health.colorSmooth = true;
			
			-- Position and size
			local myBars = CreateFrame('StatusBar', nil, self.Health)
			myBars:SetPoint('TOPLEFT', self.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			myBars:SetPoint('BOTTOMLEFT', self.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			myBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			myBars:SetStatusBarColor(0, 1, 0.5, 0.45)

			local otherBars = CreateFrame('StatusBar', nil, myBars)
			otherBars:SetPoint('TOPLEFT', myBars:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
			otherBars:SetPoint('BOTTOMLEFT', myBars:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
			otherBars:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			otherBars:SetStatusBarColor(0, 0.5, 1, 0.35)

			myBars:SetSize(150, health:GetHeight())
			otherBars:SetSize(150, health:GetHeight())
			
			self.HealPrediction = {
				myBar = myBars,
				otherBar = otherBars,
				maxOverflow = 3,
			}
		end
		do -- power bar
			local power = CreateFrame("StatusBar",nil,self);
			power:SetFrameStrata("BACKGROUND"); power:SetFrameLevel(2);
			power:SetSize(self.Health:GetWidth(), 3);
			power:SetPoint("TOPRIGHT",self.Health,"BOTTOMRIGHT",0,0);
			
			self.Power = power;
			self.Power.colorPower = true;
			self.Power.frequentUpdates = true;
		end
	end
	do -- setup text and icons
		local layer5 = CreateFrame("Frame",nil,self);
		layer5:SetFrameLevel(5);
		
		self.LFDRole = layer5:CreateTexture(nil,"ARTWORK");
		self.LFDRole:SetSize(13, 13);
		self.LFDRole:SetPoint("TOPLEFT",self,"TOPLEFT",1,-4);
		
		self.Name = layer5:CreateFontString();
		spartan:FormatFont(self.Name, 11, "Raid")
		self.Name:SetSize(self:GetWidth()-30, 12);
		self.Name:SetJustifyH("LEFT"); self.Name:SetJustifyV("BOTTOM");
		self.Name:SetPoint("TOPLEFT",self.LFDRole,"TOPRIGHT",1,1);
		if DBMod.RaidFrames.showClass then
			self:Tag(self.Name, "[SUI_ColorClass][name]");
		else
			self:Tag(self.Name, "[name]");
		end
		
		self.Leader = layer5:CreateTexture(nil,"ARTWORK");
		self.Leader:SetSize(15, 15);
		self.Leader:SetPoint("CENTER",self,"TOP",0,0);
		
		self.RaidIcon = self:CreateTexture(nil,"ARTWORK");
		self.RaidIcon:SetSize(24, 24);
		self.RaidIcon:SetPoint("CENTER",self,"CENTER");
	end
	do -- setup debuffs
		self.Debuffs = CreateFrame("Frame",nil,self);
		self.Debuffs:SetWidth(17*11); self.Debuffs:SetHeight(17*1);
		self.Debuffs:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-6,2);
		self.Debuffs:SetFrameStrata("BACKGROUND");
		self.Debuffs:SetFrameLevel(4);
		-- settings
		self.Debuffs.size = DBMod.RaidFrames.Auras.size;
		self.Debuffs.spacing = DBMod.RaidFrames.Auras.spacing;
		self.Debuffs.showType = DBMod.RaidFrames.Auras.showType;
		self.Debuffs.initialAnchor = "BOTTOMRIGHT";
		self.Debuffs.num = 5;
		
		self.Debuffs.PostUpdate = RaidFrames:PostUpdateDebuffs(self,unit);
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
		-- auras.PostCreateIcon = myCustomIconSkinnerFunction
		-- Set any other AuraWatch settings
		auras.icons = {}
		for i, sid in pairs(spellIDs) do
			local icon = CreateFrame("Frame", nil, self)
			icon.spellID = sid
			-- set the dimensions and positions
			icon:SetSize(DBMod.RaidFrames.Auras.size, DBMod.RaidFrames.Auras.size)
			icon:SetPoint("TOPRIGHT",self,"TOPRIGHT", ((-icon:GetWidth()*i)+icon:GetWidth())-2, -2)
			auras.icons[sid] = icon
			-- Set any other AuraWatch icon settings
		end
		self.AuraWatch = auras
	end
	do -- Threat, SpellRange, and Ready Check
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 1/2,
		}
		
		local ResurrectIcon = self:CreateTexture(nil, 'OVERLAY')
		ResurrectIcon:SetSize(30, 30)
		ResurrectIcon:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ResurrectIcon = ResurrectIcon

		local ReadyCheck = self:CreateTexture(nil, 'OVERLAY')
		ReadyCheck:SetSize(30, 30)
		ReadyCheck:SetPoint("RIGHT",self,"CENTER",0,0)
		self.ReadyCheck = ReadyCheck
	   
		local overlay = self:CreateTexture(nil, "OVERLAY")
		overlay:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights");
		overlay:SetTexCoord(0.00781250, 0.55468750, 0.00781250, 0.27343750)
		overlay:SetAllPoints(self)
		overlay:SetVertexColor(1, 0, 0)
		overlay:Hide();
		self.ThreatOverlay = overlay
			
		self.Threat = CreateFrame("Frame",nil,self);
		self.Threat.Override = threat;
	end
	self.TextUpdate = RaidFrames:PostUpdateText(self,unit);
	return self;
end

local CreateUnitFrame = function(self,unit)
	self:HookScript("OnMouseDown",function(self,button)
		if button == "LeftButton" and IsAltKeyDown() then
			spartan.RaidFrames.mover:Show();
			DBMod.RaidFrames.moved = true;
			spartan.RaidFrames:SetMovable(true);
			spartan.RaidFrames:StartMoving();
		end
	end);
	self:HookScript("OnMouseUp",function(self,button)
		spartan.RaidFrames.mover:Hide();
		spartan.RaidFrames:StopMovingOrSizing();
		local Anchors = {}
		Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = spartan.RaidFrames:GetPoint()
		for k,v in pairs(Anchors) do
			DBMod.RaidFrames.Anchors[k] = v
		end
	end);
	
	self.colors = colors;
	self:SetClampedToScreen(true)
	return SpawnUnitFrame(self,unit);
end

SpartanoUF:RegisterStyle("Spartan_RaidFrames_Classic", CreateUnitFrame);

function RaidFrames:Classic()
	SpartanoUF:SetActiveStyle("Spartan_RaidFrames_Classic");
	local xoffset = 3
	local yOffset = -5
	local point = 'TOP'
	local columnAnchorPoint = 'LEFT'
	local groupingOrder = 'TANK,HEALER,DAMAGER,NONE'
	
	if DBMod.RaidFrames.mode == "GROUP" then
		groupingOrder = '1,2,3,4,5,6,7,8'
	end
	-- print(DBMod.RaidFrames.mode)
	-- print(groupingOrder)
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
	-- if DBMod.RaidFrames.mode == "GROUP" then
		-- raid = SpartanoUF:SpawnHeader("SUI_RaidFrameHeader", nil, 'raid',
			-- "showRaid", DBMod.RaidFrames.showRaid,
			-- "showParty", DBMod.RaidFrames.showParty,
			-- "showPlayer", DBMod.RaidFrames.showPlayer,
			-- "showSolo", DBMod.RaidFrames.showSolo,
			-- 'xoffset', 3,
			-- 'yOffset', -5,
			-- 'point', 'TOP',
			-- 'groupFilter', '1,2,3,4,5,6,7,8',
			-- 'groupBy', DBMod.RaidFrames.mode,
			-- 'groupingOrder', '1,2,3,4,5,6,7,8',
			-- 'sortMethod', 'name',
			-- 'maxColumns', DBMod.RaidFrames.maxColumns,
			-- 'unitsPerColumn', DBMod.RaidFrames.unitsPerColumn,
			-- 'columnSpacing', DBMod.RaidFrames.columnSpacing,
			-- 'columnAnchorPoint', 'LEFT'
		-- )
	-- else
		-- raid = SpartanoUF:SpawnHeader("SUI_RaidFrameHeader", nil, 'raid',
			-- 'showPlayer', true,
			-- 'showRaid', true,
			-- 'showParty', false,
			-- 'showSolo', true,
			-- 'xoffset', 3,
			-- 'yOffset', 0,
			-- 'point', 'LEFT',
			-- 'groupFilter', '1,2,3,4,5,6,7,8',
			-- 'groupBy', DBMod.RaidFrames.mode,
			-- 'groupingOrder', '1,2,3,4,5,6,7,8',
			-- 'sortMethod', 'name',
			-- 'maxColumns', DBMod.RaidFrames.maxColumns,
			-- 'unitsPerColumn', DBMod.RaidFrames.unitsPerColumn,
			-- 'columnSpacing', DBMod.RaidFrames.columnSpacing,
			-- 'columnAnchorPoint', 'TOP'
		-- )
	-- end
	raid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -40)
	
	raid:SetParent("SpartanUI");
	raid:SetClampedToScreen(false);
	
	
	return (raid)
end

