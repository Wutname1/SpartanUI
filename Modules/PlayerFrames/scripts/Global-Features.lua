local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local addon = spartan:NewModule("PlayerFrames");
----------------------------------------------------------------------------------------------------
do -- ClassIcon as an oUF module
	local ClassIconCoord = {
		WARRIOR = {			0.00, 0.25, 0.00, 0.25 },
		MAGE = {			0.25, 0.50, 0.00, 0.25 },
		ROGUE = {			0.50, 0.75, 0.00, 0.25 },
		DRUID = {			0.75, 1.00, 0.00, 0.25 },
		HUNTER = {			0.00, 0.25, 0.25, 0.50 },
		SHAMAN = {			0.25, 0.50, 0.25, 0.50 },
		PRIEST = {			0.50, 0.75, 0.25, 0.50 },
		WARLOCK = {			0.75, 1.00, 0.25, 0.50 },
		PALADIN = {			0.00, 0.25, 0.50, 0.75 },
		DEATHKNIGHT = {		0.25, 0.50, 0.50, 0.75 },
		MONK = {			0.50, 0.75, 0.50, 0.75 },
		DEFAULT = {			0.75, 1.00, 0.75, 1.00 },
	};
	local Update = function(self,event,unit)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			local _,class = UnitClass(self.unit);
			local coords = ClassIconCoord[class or "DEFAULT"];
			icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
			icon:Show();
		end
	end
	local Enable = function(self)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			self:RegisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Update);
			self:RegisterEvent("UNIT_PET", Update);
			icon:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\icon_class]]
			return true;
		end
	end
	local Disable = function(self)
		local icon = self.SUI_ClassIcon;
		if (icon) then
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Update);
			self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update);
			self:UnregisterEvent("UNIT_PET", Update);
		end
	end
	oUF:AddElement('SUI_ClassIcon',Update,Enable,Disable);
end

do -- SUI_RaidGroup as an oUF module
	local Update = function(self,event,unit)
		if IsInRaid() then
			self.SUI_RaidGroup:Show();
			self.SUI_RaidGroup.Text:Show();
		else
			self.SUI_RaidGroup:Hide();
			self.SUI_RaidGroup.Text:Hide();
		end
	end
	local Enable = function(self)
		if (self.SUI_RaidGroup) then
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Update);
			return true;
		end
	end
	local Disable = function(self)
		if (self.SUI_RaidGroup) then
			self:UnregisterEvent("GROUP_ROSTER_UPDATE", Update);
		end
	end
	oUF:AddElement('SUI_RaidGroup',Update,Enable,Disable);
end

do -- AFK / DND status text, as an oUF module
	oUF.Tags.Events['afkdnd'] = "PLAYER_FLAGS_CHANGED PLAYER_TARGET_CHANGED UNIT_TARGET";
	oUF.Tags.Methods['afkdnd'] = function (unit)
		if unit then
			return UnitIsAFK(unit) and "AFK" or UnitIsDND(unit) and "DND" or "";
		end
	end
end

do --Health Formatting Tags
-- Current Health Short, as an oUF module
	oUF.Tags.Events['curhpshort'] = "UNIT_HEALTH";
	oUF.Tags.Methods['curhpshort'] = function (unit)
		local tmp = UnitHealth(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 0).."M"; end
		if tmp >= 1000 then return addon:round(tmp/1000, 0).."K"; end
		return addon:comma_value(tmp);
	end
-- Current Health Dynamic, as an oUF module
	oUF.Tags.Events['curhpdynamic'] = "UNIT_HEALTH";
	oUF.Tags.Methods['curhpdynamic'] = function (unit)
		local tmp = UnitHealth(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Total Health Short, as an oUF module
	oUF.Tags.Events['maxhpshort'] = "UNIT_HEALTH";
	oUF.Tags.Methods['maxhpshort'] = function (unit)
		local tmp = UnitHealthMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 0).."M"; end
		if tmp >= 1000 then return addon:round(tmp/1000, 0).."K"; end
		return addon:comma_value(tmp);
	end
-- Total Health Dynamic, as an oUF module
	oUF.Tags.Events['maxhpdynamic'] = "UNIT_HEALTH";
	oUF.Tags.Methods['maxhpdynamic'] = function (unit)
		local tmp = UnitHealthMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Missing Health Dynamic, as an oUF module
	oUF.Tags.Events['missinghpdynamic'] = "UNIT_HEALTH";
	oUF.Tags.Methods['missinghpdynamic'] = function (unit)
		local tmp = UnitHealthMax(unit) - UnitHealth(unit)
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Current Health formatted, as an oUF module
	oUF.Tags.Events['curhpformatted'] = "UNIT_HEALTH";
	oUF.Tags.Methods['curhpformatted'] = function (unit) return addon:comma_value(UnitHealth(unit)); end
-- Total Health formatted, as an oUF module
	oUF.Tags.Events['maxhpformatted'] = "UNIT_HEALTH";
	oUF.Tags.Methods['maxhpformatted'] = function (unit) return addon:comma_value(UnitHealthMax(unit)); end
-- Missing Health formatted, as an oUF module
	oUF.Tags.Events['missinghpformatted'] = "UNIT_HEALTH";
	oUF.Tags.Methods['missinghpformatted'] = function (unit) return addon:comma_value(UnitHealthMax(unit) - UnitHealth(unit)); end
end
do -- Mana Formatting Tags
-- Current Mana Dynamic, as an oUF module
	oUF.Tags.Events['curppdynamic'] = "UNIT_MAXPOWER UNIT_POWER";
	oUF.Tags.Methods['curppdynamic'] = function (unit)
		local tmp = UnitPower(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Total Mana Dynamic, as an oUF module
	oUF.Tags.Events['maxppdynamic'] = "UNIT_MAXPOWER UNIT_POWER";
	oUF.Tags.Methods['maxppdynamic'] = function (unit)
		local tmp = UnitPowerMax(unit);
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Missing Mana Dynamic, as an oUF module
	oUF.Tags.Events['missinghpdynamic'] = "UNIT_HEALTH";
	oUF.Tags.Methods['missinghpdynamic'] = function (unit)
		local tmp = UnitPowerMax(unit) - UnitPower(unit)
		if tmp >= 1000000 then return addon:round(tmp/1000000, 1).."M ";
		else return addon:comma_value(tmp); end
	end
-- Current Mana formatted, as an oUF module
	oUF.Tags.Events['curppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	oUF.Tags.Methods['curppformatted'] = function (unit) return addon:comma_value(UnitPower(unit)); end
-- Total Mana formatted, as an oUF module
	oUF.Tags.Events['maxppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	oUF.Tags.Methods['maxppformatted'] = function (unit) return addon:comma_value(UnitPowerMax(unit)); end
-- Total Mana formatted, as an oUF module
	oUF.Tags.Events['missingppformatted'] = "UNIT_MAXPOWER UNIT_POWER";
	oUF.Tags.Methods['missingppformatted'] = function (unit) return addon:comma_value(UnitPowerMax(unit) - UnitPower(unit)); end
end

do --Color name by Class
	local function hex(r, g, b)
		if r then
			if (type(r) == "table") then
				if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
			end
			return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
		end
	end
	
	oUF.Tags.Events["SUI_ColorClass"] = 'UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'
	oUF.Tags.Methods["SUI_ColorClass"] = function(u)
		local _, class = UnitClass(u)
		local reaction = UnitReaction(u, "player")
		
		if (u == "pet") then
			return hex(oUF.colors.class[class])
		elseif (UnitIsPlayer(u)) then
			return hex(oUF.colors.class[class])
		else
			return hex(1, 1, 1)
		end
	end
end

function addon:round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

function addon:comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

do -- Level Skull as an oUF module
	local Update = function(self,event,unit)
		if (self.unit ~= unit) then return; end
		if (not self.LevelSkull) then return; end
		local level = UnitLevel(unit);
		self.LevelSkull:SetTexture[[Interface\TargetingFrame\UI-TargetingFrame-Skull]]
		if level < 0 then
			self.LevelSkull:SetTexCoord(0,1,0,1);
			if self.Level then self.Level:SetText"" end
		else
			self.LevelSkull:SetTexCoord(0,0.01,0,0.01);
		end
	end
	local Enable = function(self)
		if (self.LevelSkull) then return true; end
	end
	local Disable = function(self) return; end
	oUF:AddElement('LevelSkull', Update,Enable,Disable);
end

do -- Rare / Elite dragon graphic as an oUF module
	local Update = function(self,event,unit)
		if (self.unit ~= unit) then return; end
		if (not self.RareElite) then return; end
		local c = UnitClassification(unit);
		self.RareElite:SetTexture[[Interface\AddOns\SpartanUI_PlayerFrames\media\elite_rare]];
		if c == "worldboss" or c == "elite" or c == "rareelite" then
			self.RareElite:SetTexCoord(0,1,0,1);
			self.RareElite:SetVertexColor(1,0.9,0,1);
		elseif c == "rare" then
			self.RareElite:SetTexCoord(0,1,0,1);
			self.RareElite:SetVertexColor(1,1,1,1);
		else
			self.RareElite:SetTexCoord(0,0.1,0,0.1);
		end
	end
	local Enable = function(self)
		if (self.RareElite) then return true; end
	end
	local Disable = function(self) return; end
	oUF:AddElement('RareElite', Update,Enable,Disable);
end

do -- Boss graphic as an oUF module
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
	oUF:AddElement('BossGraphic', Update,Enable,Disable);
end

do -- Remove SET_FOCUS CLEAR_FOCUS
	for k,v in pairs(UnitPopupMenus) do
		if k ~= "RAID" and k ~= "RAID_PLAYER" then
			for x,y in pairs(UnitPopupMenus[k]) do
				if y == "SET_FOCUS" then
					table.remove(UnitPopupMenus[k],x)
				elseif y == "CLEAR_FOCUS" then
					table.remove(UnitPopupMenus[k],x)
				end
			end
		end
	end
	UnitPopupMenus["FOCUS"] = { "RAID_TARGET_ICON", "CANCEL" };
end