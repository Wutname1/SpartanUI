local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local PlayerFrames = spartan:NewModule("PlayerFrames");
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

do -- Remove Menu items that error
	for k,v in pairs(UnitPopupMenus) do
		if k ~= "RAID" and k ~= "RAID_PLAYER" then
			for button,name in pairs(UnitPopupMenus[k]) do
				if(name == 'SET_FOCUS') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'CLEAR_FOCUS') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'MOVE_PLAYER_FRAME') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'MOVE_TARGET_FRAME') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'LOCK_FOCUS_FRAME') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'UNLOCK_FOCUS_FRAME') then
					table.remove(UnitPopupMenus[k], button)
				elseif(name == 'PET_DISMISS') then
					table.remove(UnitPopupMenus[k], button)
				end
			end
		end
	end
	UnitPopupMenus["FOCUS"] = { "LOCK_FOCUS_FRAME", "UNLOCK_FOCUS_FRAME", "RAID_TARGET_ICON", "CANCEL" };
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
				spartan:GetModule("Style_" .. DBMod.PlayerFrames.Style):PositionFrame(b);
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