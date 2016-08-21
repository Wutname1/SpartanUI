local SUI = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PlayerFrames = SUI:NewModule("PlayerFrames");
----------------------------------------------------------------------------------------------------

function PlayerFrames:round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

function PlayerFrames:comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

do -- Boss graphic as an SpartanoUF module
	local Update = function(self,event,unit)
		if (self.unit ~= unit) then return; end
		if (not self.BossGraphic) then return; end
		local c = UnitClassification(unit);
		self.BossGraphic:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\elite_rare]];
		self.BossGraphic:SetTexCoord(1,0,0,1);
		self.BossGraphic:SetVertexColor(1,0.9,0,1);
	end
	local Enable = function(self)
		if (self.BossGraphic) then return true; end
	end
	local Disable = function(self) return; end
	SpartanoUF:AddElement('BossGraphic', Update,Enable,Disable);
end

function PlayerFrames:SetupStaticOptions()
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
	for a,unit in pairs(FramesList) do
		--Health Bar Color
		if DBMod.PlayerFrames.bars[unit].color == "reaction" then
			PlayerFrames[unit].Health.colorReaction = true;
		elseif DBMod.PlayerFrames.bars[unit].color == "happiness" then
			PlayerFrames[unit].Health.colorHappiness = true;
		elseif DBMod.PlayerFrames.bars[unit].color == "class" then
			PlayerFrames[unit].Health.colorClass = true;
		else
			PlayerFrames[unit].Health.colorSmooth = true;
		end
	end
end

function PlayerFrames:TextFormat(text)
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

function PlayerFrames:Buffs(self,unit)
	--Make sure there is an anchor for buffs
	if not self.BuffAnchor then return self end
	local CurStyle = SUI.DBMod.PlayerFrames.Style
	
	-- Build buffs
	if DB.Styles[CurStyle].Frames[unit] then
		local Buffsize = DB.Styles[CurStyle].Frames[unit].Buffs.size
		local Debuffsize = DB.Styles[CurStyle].Frames[unit].Buffs.size
		
		--Buff Icons
		local Buffs = CreateFrame("Frame", nil, self)
		Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -55, 5)
		Buffs.size = Buffsize;
		Buffs["growth-y"] = "UP";
		Buffs.spacing = DB.Styles[CurStyle].Frames[unit].Buffs.spacing;
		Buffs.showType = DB.Styles[CurStyle].Frames[unit].Buffs.showType;
		Buffs.numBuffs = DB.Styles[CurStyle].Frames[unit].Buffs.Number;
		Buffs.onlyShowPlayer = DB.Styles[CurStyle].Frames[unit].Buffs.onlyShowPlayer;
		Buffs:SetSize(Buffsize * 4, Buffsize * Buffsize)
		Buffs.PostUpdate = PostUpdateAura;
		
		--Debuff Icons
		local Debuffs = CreateFrame("Frame", nil, self)
		Debuffs:SetPoint("BOTTOMRIGHT",self,"TOPRIGHT",-5,5)
		Debuffs.size = Debuffsize;
		Debuffs.initialAnchor = "BOTTOMRIGHT";
		Debuffs["growth-x"] = "LEFT";
		Debuffs["growth-y"] = "UP";
		Debuffs.spacing = DB.Styles[CurStyle].Frames[unit].Debuffs.spacing;
		Debuffs.showType = DB.Styles[CurStyle].Frames[unit].Debuffs.showType;
		Debuffs.numDebuffs = DB.Styles[CurStyle].Frames[unit].Debuffs.Number;
		Debuffs.onlyShowPlayer = DB.Styles[CurStyle].Frames[unit].Debuffs.onlyShowPlayer;
		Debuffs:SetSize(Debuffsize * 4, Debuffsize * Debuffsize)
		Debuffs.PostUpdate = PostUpdateAura;
		
		--Bars
		local AuraBars = CreateFrame("Frame", nil, self)
		AuraBars:SetHeight(1)
		AuraBars.auraBarTexture = Smoothv2
		AuraBars.PostUpdate = PostUpdateAura
		
		
		if DB.Styles[CurStyle].Frames[unit].Buffs.Mode == "bars" and DB.Styles[CurStyle].Frames[unit].Debuffs.Mode == "bars" then
			--Set Bars to do all
			AuraBars.ShowAll = true
			AuraBars:SetPoint("BOTTOMRIGHT",self.BuffAnchor,"TOPRIGHT", 0, 5)
			AuraBars:SetPoint("BOTTOMLEFT",self.BuffAnchor,"TOPLEFT", 0, 5)
			-- AuraBars.helpOrHarm = function(unit)
				-- return UnitIsFriend('player', unit) and 'HELPFUL' or 'HARMFUL'
			-- end
			AuraBars.filter = function(name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, spellID)
				--Only Show HOTS and DOTS
				if duration > 0 then
					return true
				end
			end
			self.AuraBars = AuraBars
		else
			if DB.Styles[CurStyle].Frames[unit].Buffs.Mode == "bars" then
				AuraBars:SetPoint("BOTTOMRIGHT",self.BuffAnchor,"TOPRIGHT", 0, 5)
				AuraBars:SetPoint("BOTTOMLEFT",self.BuffAnchor,"TOPLEFT", 0, 5)
				AuraBars.filter = function(name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable)
					if ((unitCaster == "player" and DB.Styles[CurStyle].Frames[unit].Buffs.onlyShowPlayer) or (not DB.Styles[CurStyle].Frames[unit].Buffs.onlyShowPlayer)) and not IsHarmfulSpell(name) then
						return true
					end
				end
				self.AuraBars = AuraBars
			else
				self.Buffs = Buffs
			end
			if DB.Styles[CurStyle].Frames[unit].Debuffs.Mode == "bars" then
				AuraBars:SetPoint("BOTTOMRIGHT",self.BuffAnchor,"TOPRIGHT", 0, 5)
				AuraBars:SetPoint("BOTTOMLEFT",self.BuffAnchor,"TOPLEFT", 0, 5)
				AuraBars.filter = function(name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable)
					if ((unitCaster == "player" and DB.Styles[CurStyle].Frames[unit].Debuffs.onlyShowPlayer) or (not DB.Styles[CurStyle].Frames[unit].Debuffs.onlyShowPlayer)) and IsHarmfulSpell(name) then
						return true
					end
				end
				self.AuraBars = AuraBars
			else
				self.Debuffs = Debuffs
			end
		end
		
		--Change options if needed
		if DB.Styles[CurStyle].Frames[unit].Buffs.Mode == "bars" then
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Buffs"].args["Number"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Buffs"].args["size"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Buffs"].args["spacing"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Buffs"].args["showType"].disabled=true
		end
		if DB.Styles[CurStyle].Frames[unit].Debuffs.Mode == "bars" then
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Debuffs"].args["Number"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Debuffs"].args["size"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Debuffs"].args["spacing"].disabled=true
			SUI.opt.args["PlayerFrames"].args["auras"].args[unit].args["Debuffs"].args["showType"].disabled=true
		end
	
		SUI.opt.args["PlayerFrames"].args["auras"].args[unit].disabled=false
	end
	return self
end

function PlayerFrames:UpdatePosition()
	local FramesList = {[1]="pet",[2]="target",[3]="targettarget",[4]="focus",[5]="focustarget",[6]="player"}
	
	for a,b in pairs(FramesList) do
		if DBMod.PlayerFrames[b] ~= nil and DBMod.PlayerFrames[b].moved then
			PlayerFrames[b]:SetMovable(true);
			PlayerFrames[b]:SetUserPlaced(false);
			local Anchors = {}
			for k,v in pairs(DBMod.PlayerFrames[b].Anchors) do
				Anchors[k] = v
			end
			PlayerFrames[b]:ClearAllPoints();
			PlayerFrames[b]:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		elseif DBMod.PlayerFrames[b] ~= nil then
			PlayerFrames[b]:SetMovable(false);
			PlayerFrames[b]:ClearAllPoints();
			if (DBMod.PlayerFrames.Style == "Classic") then
				PlayerFrames:PositionFrame_Classic(b);
			elseif (DBMod.PlayerFrames.Style == "plain") then
				PlayerFrames:PositionFrame_Plain(b);
			else
				SUI:GetModule("Style_" .. DBMod.PlayerFrames.Style):PositionFrame(b);
			end
		else
			print(b .. " Frame has not been spawned by your theme")
		end
	end
	

	-- for i = 1, MAX_BOSS_FRAMES do
	if DBMod.PlayerFrames.BossFrame.display then
		if DBMod.PlayerFrames.boss.moved then
			PlayerFrames.boss[1]:SetMovable(true);
			PlayerFrames.boss[1]:SetUserPlaced(false);
			local Anchors = {}
			for k,v in pairs(DBMod.PlayerFrames.boss.Anchors) do
				Anchors[k] = v
			end
			PlayerFrames.boss[1]:ClearAllPoints();
			PlayerFrames.boss[1]:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			PlayerFrames.boss[1]:SetPoint('TOPRIGHT', UIParent, 'RIGHT', -50, 60)
			PlayerFrames.boss[1]:SetMovable(false);
		end
	end
	-- end
end

function PlayerFrames:CreatePortrait(self)
	if DBMod.PlayerFrames.Portrait3D then			
		local Portrait = CreateFrame('PlayerModel', nil, self)
		Portrait:SetScript("OnShow", function(self) self:SetCamera(1) end)
		Portrait.type = "3D"
		-- Portrait.bg2 = Portrait:CreateTexture(nil,"BACKGROUND");
		-- Portrait.bg2:SetTexture(circle);
		-- Portrait.bg2:SetPoint("TOPLEFT",Portrait,"TOPLEFT",-10,10);
		-- Portrait.bg2:SetPoint("BOTTOMRIGHT",Portrait,"BOTTOMRIGHT",10,-10);
		Portrait:SetFrameLevel(1);
		return Portrait;
	else
		return self:CreateTexture(nil,"BORDER");
	end
end

function PlayerFrames:MakeMovable(self,unit)
	self:RegisterForClicks("AnyDown");
	self:EnableMouse(enable)
	self:SetClampedToScreen(true)
	
	if self.artwork then
		self.artwork:SetScript("OnEnter", function()
			UnitFrame_OnEnter(self, unit)
		end);
		self.artwork:SetScript("OnLeave", function()
			UnitFrame_OnLeave(self, unit)
		end);
	end
	
	self:SetScript("OnEnter", UnitFrame_OnEnter);
	self:SetScript("OnLeave", UnitFrame_OnLeave);
	return self
end

function PlayerFrames:FirstTime()
	DBMod.PlayerFrames.SetupDone = false
	local PageData = {
		SubTitle = "Player Frames style",
		Desc1 = "Please pick an art style from the options below.",
		Display = function()
			--Container
			SUI_Win.Artwork = CreateFrame("Frame", nil)
			SUI_Win.Artwork:SetParent(SUI_Win.content)
			SUI_Win.Artwork:SetAllPoints(SUI_Win.content)
			
			local RadioButtons = function(self)
				SUI_Win.Artwork.Classic.radio:SetValue(false)
				SUI_Win.Artwork.Transparent.radio:SetValue(false)
				SUI_Win.Artwork.Minimal.radio:SetValue(false)
				self.radio:SetValue(true)
			end
			
			local gui = LibStub("AceGUI-3.0")
			
			--Classic
			local control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI_Artwork\\Themes\\Classic\\Images\\base-center")
			control:SetImageSize(120, 60)
			control:SetPoint("TOP", SUI_Win.Artwork, "TOP", 0, -30)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()
			
			local radio = gui:Create("CheckBox")
			radio:SetLabel("Classic")
			radio:SetUserData("value", "Classic")
			radio:SetUserData("text", "Classic")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth()/1.4)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio:SetCallback("OnClick", RadioButton)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio
			
			SUI_Win.Artwork.Classic = control
			
			--Transparent
			local control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Transparent")
			control:SetImageSize(120, 60)
			control:SetPoint("TOPRIGHT", SUI_Win.Artwork.Classic.frame, "BOTTOMLEFT", 0, -60)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()
			
			local radio = gui:Create("CheckBox")
			radio:SetLabel("Transparent")
			radio:SetUserData("value", "Transparent")
			radio:SetUserData("text", "Transparent")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth()/1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio
			
			SUI_Win.Artwork.Transparent = control
			
			--Minimal
			local control = gui:Create("Icon")
			control:SetImage("interface\\addons\\SpartanUI\\media\\Style_Minimal")
			control:SetImageSize(120, 60)
			control:SetPoint("TOPLEFT", SUI_Win.Artwork.Classic.frame, "BOTTOMRIGHT", 0, -60)
			control:SetCallback("OnClick", RadioButtons)
			control.frame:SetParent(SUI_Win.Artwork)
			control.frame:Show()
			
			local radio = gui:Create("CheckBox")
			radio:SetLabel("Minimal")
			radio:SetUserData("value", "Minimal")
			radio:SetUserData("text", "Minimal")
			radio:SetType("radio")
			radio:SetDisabled(true)
			radio:SetWidth(control.frame:GetWidth()/1.15)
			radio:SetHeight(16)
			radio.frame:SetPoint("TOP", control.frame, "BOTTOM", 0, 0)
			radio.frame:SetParent(control.frame)
			radio.frame:Show()
			control.radio = radio
			
			SUI_Win.Artwork.Minimal = control
			
		end,
		Next = function()
			DBMod.Artwork.PlayerFrames = true
			
			if (SUI_Win.Artwork.Classic.radio:GetValue()) then DBMod.Artwork.Style = "Classic"; end
			if (SUI_Win.Artwork.Transparent.radio:GetValue()) then DBMod.Artwork.Style = "Transparent"; end
			if (SUI_Win.Artwork.Minimal.radio:GetValue()) then DBMod.Artwork.Style = "Minimal"; end
			
			DBMod.PlayerFrames.Style = DBMod.Artwork.Style;
			DBMod.PartyFrames.Style = DBMod.Artwork.Style;
			DBMod.RaidFrames.Style = DBMod.Artwork.Style;
			DBMod.Artwork.FirstLoad = true;
			
			--Reset Moved bars
			if DB.Styles[DBMod.Artwork.Style].MovedBars == nil then DB.Styles[DBMod.Artwork.Style].MovedBars = {} end
			local FrameList = {BT4Bar1, BT4Bar2, BT4Bar3, BT4Bar4, BT4Bar5, BT4Bar6, BT4BarBagBar, BT4BarExtraActionBar, BT4BarStanceBar, BT4BarPetBar, BT4BarMicroMenu}
			for k,v in ipairs(FrameList) do
				if DB.Styles[DBMod.Artwork.Style].MovedBars[v:GetName()] then
					DB.Styles[DBMod.Artwork.Style].MovedBars[v:GetName()] = false
				end
			end;
			
			SUI:GetModule("Style_"..DBMod.Artwork.Style):SetupProfile();
			
			SUI_Win.Artwork:Hide()
			SUI_Win.Artwork = nil
		end,
		RequireReload = true,
		Priority = 1,
		Skipable = true,
		NoReloadOnSkip = true,
		Skip = function() DBMod.PlayerFrames.SetupDone = true end
	}
	
	-- local SetupWindow = SUI:GetModule("SetupWindow")
	-- SetupWindow:AddPage(PageData)
	-- SetupWindow:DisplayPage()
	
	-- Temporary
	DBMod.PlayerFrames.SetupDone = true
end

function PlayerFrames:OnInitialize()
	if not DBMod.PlayerFrames.SetupDone then PlayerFrames:FirstTime() end
end