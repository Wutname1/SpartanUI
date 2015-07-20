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

do -- Remove SET_FOCUS & CLEAR_FOCUS errors
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

